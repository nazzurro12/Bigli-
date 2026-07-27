extends Node

const DFJob = preload("res://df_mode/df_job.gd")
const DFSaveLoad = preload("res://df_mode/df_save_load.gd")

const SETTINGS_MENU := 0
const GENERATING_WORLD := 1
const PLAYING := 5
const LOADING_PLAYING := 6
const MAX_GENERATION_FRAMES := 18000
const MAX_SIMULATION_FRAMES := 2400
const TEST_SAVE_SLOT := 99

var _game_main: Node = null
var _phase := "WAITING_SETTINGS"
var _phase_frames := 0
var _errors: Array[String] = []
var _initial_positions: Dictionary = {}
var _observed_job_states: Dictionary = {}
var _peak_jobs := 0
var _saw_assigned_job := false
var _saw_in_progress_job := false
var _saw_finished_job := false
var _saw_dwarf_with_job := false
var _saw_dwarf_move := false


func _ready() -> void:
	print("[TEST JOBS] Iniciando prueba del bucle jugable...")
	var main_scene: PackedScene = load("res://df_mode/df_main.tscn")
	if main_scene == null:
		_fail("No se pudo cargar df_main.tscn")
		return
	_game_main = main_scene.instantiate()
	add_child(_game_main)


func _process(_delta: float) -> void:
	if _game_main == null:
		return
	_phase_frames += 1
	var state: int = int(_game_main.current_state)

	match _phase:
		"WAITING_SETTINGS":
			if state == SETTINGS_MENU:
				_game_main.generation_seed = 424242
				_game_main.setting_size = 0
				_game_main.setting_history_idx = 0
				var test_generation_settings = load("res://world/world_generation_settings.tres")
				test_generation_settings.local_map_size = 64
				_game_main.set_meta("quick_start_pending", true)
				_game_main.current_state = GENERATING_WORLD
				_change_phase("GENERATING")
			elif _phase_frames > 300:
				_fail("La escena no llegó al menú inicial")

		"GENERATING":
			if state == PLAYING:
				_begin_simulation_check()
			elif state not in [GENERATING_WORLD, LOADING_PLAYING]:
				_fail("Estado inesperado durante la generación: %d" % state)
			elif _phase_frames > MAX_GENERATION_FRAMES:
				_fail("Timeout generando y cargando el mundo")

		"SIMULATING":
			_observe_job_cycle()
			if _cycle_is_proven():
				_run_save_load_round_trip()
			elif _phase_frames > MAX_SIMULATION_FRAMES:
				_fail("El ciclo de trabajos no avanzó dentro del tiempo límite")


func _begin_simulation_check() -> void:
	if _game_main.world == null:
		_fail("El juego llegó a PLAYING sin mundo")
		return
	if _game_main.designation == null:
		_fail("El juego llegó a PLAYING sin sistema de designaciones")
		return
	if _game_main.world.dwarves.is_empty():
		_fail("El desembarco no creó enanos")
		return

	# Acelera la prueba sin saltarse la lógica real de _tick().
	_game_main.tick_interval = 0.01
	for dwarf in _game_main.world.dwarves:
		if dwarf.is_alive:
			_initial_positions[dwarf.id] = dwarf.tile_pos
	_change_phase("SIMULATING")
	_observe_job_cycle()


func _observe_job_cycle() -> void:
	var jobs: Array = _game_main.designation.job_queue
	_peak_jobs = maxi(_peak_jobs, jobs.size())
	var queued_ids: Dictionary = {}

	for job in jobs:
		var job_id: int = job.get_instance_id()
		queued_ids[job_id] = true
		_observed_job_states[job_id] = job.state
		match job.state:
			DFJob.JobState.ASSIGNED:
				_saw_assigned_job = true
			DFJob.JobState.IN_PROGRESS:
				_saw_assigned_job = true
				_saw_in_progress_job = true
			DFJob.JobState.COMPLETED, DFJob.JobState.CANCELLED:
				_saw_finished_job = true

	# df_main elimina trabajos completados al final del tick. Conservar los
	# estados vistos permite reconocer que uno que estaba activo salió de la cola.
	for observed_id: Variant in _observed_job_states.keys():
		if queued_ids.has(observed_id):
			continue
		var previous_state: int = int(_observed_job_states[observed_id])
		if previous_state in [DFJob.JobState.ASSIGNED, DFJob.JobState.IN_PROGRESS]:
			_saw_finished_job = true

	for dwarf in _game_main.world.dwarves:
		if not dwarf.is_alive:
			continue
		if dwarf.current_job != null:
			_saw_dwarf_with_job = true
			if dwarf.current_job.state == DFJob.JobState.IN_PROGRESS:
				_saw_in_progress_job = true
			elif dwarf.current_job.state == DFJob.JobState.COMPLETED:
				_saw_finished_job = true
		var start_position: Variant = _initial_positions.get(dwarf.id)
		if start_position != null and dwarf.tile_pos != start_position:
			_saw_dwarf_move = true

func _cycle_is_proven() -> bool:
	return (
		_peak_jobs > 0
		and _saw_dwarf_with_job
		and _saw_assigned_job
		and _saw_in_progress_job
		and _saw_finished_job
		and _saw_dwarf_move
	)


func _run_save_load_round_trip() -> void:
	_change_phase("VERIFYING_SAVE")
	var world = _game_main.world
	var dwarf = world.dwarves[0]
	world.combat_system.combat_log.append("[TEST] registro persistente")
	world.invasion_system.threat_level = 3
	world.invasion_system.fortress_kills = 17
	if world.military_system.squads.is_empty():
		var test_squad = world.military_system.create_squad("Guardia de Persistencia")
		world.military_system.assign_dwarf_to_squad(dwarf.id, test_squad.id)
	world.military_system.set_alert(1)
	if _game_main.quest_system.active_quests.is_empty():
		var test_quest = _game_main.quest_system.generate_quest()
		test_quest.current_count = mini(1, test_quest.target_count)
		_game_main.quest_system.active_quests.append(test_quest)
	_game_main.quest_system.generation_cooldown = 321
	_game_main.caravan_system.total_trades = 7
	_game_main.caravan_system.total_wealth_traded = 4321.5
	_game_main.caravan_system.relations["human"] = 42.5
	_game_main.world_simulation.elapsed_minutes = 777
	_game_main.world_simulation.set_relation("dwarves", "humans", 37)
	_game_main.world_simulation.record("[TEST] decisión regional persistente")
	_game_main.world_simulation.settlement.last_decision = "Mantener las reservas."
	_game_main.world_simulation.regional_states["128:128"] = {
		"x": 128, "z": 128, "discovered": true, "visited": true, "population": 7,
	}
	_game_main.world_simulation.regional_routes["128:128>129:128"] = {
		"from": [128, 128], "to": [129, 128], "traffic": 2, "level": 1,
	}
	_game_main.world_simulation.regional_journeys.append({
		"dwarf_id": dwarf.id,
		"dwarf_name": dwarf.name,
		"origin": [128, 128],
		"target": [129, 128],
		"stage": "outbound",
		"remaining_minutes": 240,
		"started_minute": 720,
	})
	var tracked_quest = _game_main.quest_system.active_quests[0]
	var expected_building_sizes: Array = world.buildings.map(
		func(building): return [building.type, building.tile_pos, building.size]
	)
	var expected_stockpile_tiles: Array = []
	for stockpile in world.stockpiles:
		expected_stockpile_tiles.append(stockpile.tiles.duplicate())
	var expected_container_links: Dictionary = {}
	for item in world.items:
		if item.is_inside_container:
			expected_container_links[item.id] = item.container_id
	var expected := {
		"minute": _game_main._game_minute,
		"hour": _game_main._game_hour,
		"day": _game_main._game_day,
		"entity_count": world.entities.size(),
		"dwarf_count": world.dwarves.size(),
		"item_count": world.items.size(),
		"dwarf_id": dwarf.id,
		"inventory_ids": dwarf.inventory.map(func(item): return item.id),
		"building_sizes": expected_building_sizes,
		"stockpile_tiles": expected_stockpile_tiles,
		"container_links": expected_container_links,
		"combat_log": world.combat_system.combat_log.duplicate(),
		"invasion_threat": world.invasion_system.threat_level,
		"fortress_kills": world.invasion_system.fortress_kills,
		"military_summary": world.military_system.get_military_summary(),
		"quest_id": tracked_quest.id,
		"quest_progress": tracked_quest.current_count,
		"quest_cooldown": _game_main.quest_system.generation_cooldown,
		"caravan_trades": _game_main.caravan_system.total_trades,
		"caravan_wealth": _game_main.caravan_system.total_wealth_traded,
		"human_relation": _game_main.caravan_system.relations["human"],
		"regional_minutes": _game_main.world_simulation.elapsed_minutes,
		"regional_relation": _game_main.world_simulation.get_relation("dwarves", "humans"),
		"regional_history": _game_main.world_simulation.history.duplicate(true),
		"settlement_decision": _game_main.world_simulation.settlement.last_decision,
		"regional_states": _game_main.world_simulation.regional_states.duplicate(true),
		"regional_routes": _game_main.world_simulation.regional_routes.duplicate(true),
		"regional_journeys": _game_main.world_simulation.regional_journeys.duplicate(true),
	}
	if not DFSaveLoad.save_game_slot(_game_main, TEST_SAVE_SLOT):
		_fail("No se pudo crear el guardado de prueba")
		return

	# Corromper valores en memoria demuestra que load no se limita a devolver true.
	_game_main._game_minute = -1
	_game_main._game_hour = -1
	world.dwarves.clear()
	world.items.clear()
	world.combat_system = null
	world.invasion_system = null
	world.military_system = null
	_game_main.quest_system = null
	_game_main.caravan_system = null
	_game_main.world_simulation = null

	if not DFSaveLoad.load_game_slot(_game_main, TEST_SAVE_SLOT):
		DFSaveLoad.delete_save(TEST_SAVE_SLOT)
		_fail("No se pudo recargar el guardado de prueba")
		return
	DFSaveLoad.delete_save(TEST_SAVE_SLOT)

	_expect(_game_main._game_minute == expected.minute, "No se restauró el minuto")
	_expect(_game_main._game_hour == expected.hour, "No se restauró la hora")
	_expect(_game_main._game_day == expected.day, "No se restauró el día")
	_expect(world.entities.size() == expected.entity_count, "Cambió la cantidad de entidades")
	_expect(world.dwarves.size() == expected.dwarf_count, "No se reconstruyó el índice de enanos")
	_expect(world.items.size() == expected.item_count, "No se reconstruyó el índice de objetos")
	_expect(world.combat_system != null, "El combate quedó desactivado al cargar")
	_expect(world.invasion_system != null, "Las invasiones quedaron desactivadas al cargar")
	_expect(world.military_system != null, "El ejército quedó desactivado al cargar")
	_expect(world.combat_system.combat_log == expected.combat_log, "Se perdió el registro de combate")
	_expect(
		world.invasion_system.threat_level == expected.invasion_threat,
		"Se reinició el nivel de amenaza"
	)
	_expect(
		world.invasion_system.fortress_kills == expected.fortress_kills,
		"Se reinició el historial defensivo"
	)
	_expect(
		world.military_system.get_military_summary() == expected.military_summary,
		"Se perdieron escuadras o alertas militares"
	)
	_expect(_game_main.quest_system != null, "El sistema de misiones no se reconstruyó")
	_expect(_game_main.caravan_system != null, "El sistema de caravanas no se reconstruyó")
	_expect(_game_main.world_simulation != null, "La simulación regional no se reconstruyó")
	if _game_main.quest_system != null:
		_expect(not _game_main.quest_system.active_quests.is_empty(), "Se perdieron las misiones activas")
		if not _game_main.quest_system.active_quests.is_empty():
			var loaded_quest = _game_main.quest_system.active_quests[0]
			_expect(loaded_quest.id == expected.quest_id, "Cambió la identidad de la misión")
			_expect(loaded_quest.current_count == expected.quest_progress, "Se perdió el progreso de la misión")
		_expect(
			_game_main.quest_system.generation_cooldown == expected.quest_cooldown,
			"Se reinició el temporizador de misiones"
		)
	if _game_main.caravan_system != null:
		_expect(_game_main.caravan_system.total_trades == expected.caravan_trades, "Se perdió el historial comercial")
		_expect(
			is_equal_approx(_game_main.caravan_system.total_wealth_traded, expected.caravan_wealth),
			"Se perdió la riqueza comerciada"
		)
		_expect(
			is_equal_approx(_game_main.caravan_system.relations.get("human", 0.0), expected.human_relation),
			"Se reiniciaron las relaciones comerciales"
		)
	if _game_main.world_simulation != null:
		_expect(
			_game_main.world_simulation.elapsed_minutes == expected.regional_minutes,
			"Se reinició el reloj de simulación regional"
		)
		_expect(
			_game_main.world_simulation.get_relation("dwarves", "humans") == expected.regional_relation,
			"Se reiniciaron las relaciones entre facciones"
		)
		_expect(
			_game_main.world_simulation.history == expected.regional_history,
			"Se perdió la crónica de decisiones regionales"
		)
		_expect(
			_game_main.world_simulation.settlement.last_decision == expected.settlement_decision,
			"Se perdió la última decisión del asentamiento"
		)
		_expect(
			_game_main.world_simulation.regional_states == expected.regional_states,
			"Se perdieron las regiones descubiertas"
		)
		_expect(
			_game_main.world_simulation.regional_routes == expected.regional_routes,
			"Se perdió la evolución de caminos regionales"
		)
		_expect(
			_game_main.world_simulation.regional_journeys == expected.regional_journeys,
			"Se perdieron los viajes regionales activos"
		)
	_expect(
		world.buildings.map(func(building): return [building.type, building.tile_pos, building.size])
		== expected.building_sizes,
		"Cambió el tamaño o la posición de un edificio"
	)
	var loaded_stockpile_tiles: Array = []
	for stockpile in world.stockpiles:
		loaded_stockpile_tiles.append(stockpile.tiles.duplicate())
	_expect(loaded_stockpile_tiles == expected.stockpile_tiles, "Cambió el área de un almacén")
	var loaded_container_links: Dictionary = {}
	for item in world.items:
		if item.is_inside_container:
			loaded_container_links[item.id] = item.container_id
	_expect(loaded_container_links == expected.container_links, "Cambió el contenido de contenedores")

	var loaded_dwarf = world.get_dwarf_by_id(expected.dwarf_id)
	_expect(loaded_dwarf != null, "No se recuperó el enano comprobado")
	if loaded_dwarf != null:
		var loaded_inventory_ids: Array = loaded_dwarf.inventory.map(func(item): return item.id)
		loaded_inventory_ids.sort()
		var expected_inventory_ids: Array = expected.inventory_ids
		expected_inventory_ids.sort()
		_expect(
			loaded_inventory_ids == expected_inventory_ids,
			"El inventario del enano cambió tras cargar"
		)
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)


func _change_phase(next_phase: String) -> void:
	_phase = next_phase
	_phase_frames = 0


func _fail(message: String) -> void:
	_errors.append(message)
	_finish()


func _finish() -> void:
	print("[TEST JOBS] Máximo de trabajos observados: %d" % _peak_jobs)
	print("[TEST JOBS] Enano aceptó trabajo: %s" % _saw_dwarf_with_job)
	print("[TEST JOBS] Trabajo asignado: %s" % _saw_assigned_job)
	print("[TEST JOBS] Trabajo en progreso: %s" % _saw_in_progress_job)
	print("[TEST JOBS] Trabajo finalizado: %s" % _saw_finished_job)
	print("[TEST JOBS] Movimiento observado: %s" % _saw_dwarf_move)
	print("[TEST JOBS] Guardado/carga: %s" % (_phase == "VERIFYING_SAVE" and _errors.is_empty()))
	if _errors.is_empty() and _cycle_is_proven():
		print("[TEST JOBS] SUPERADO: el bucle generar -> asignar -> trabajar -> terminar funciona")
		get_tree().quit(0)
		return
	for error in _errors:
		print("[TEST JOBS] ERROR: %s" % error)
	get_tree().quit(1)
