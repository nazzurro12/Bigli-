extends Node

var _game_main = null
var _phase = "INIT"
var _tick_count = 0
var _ticks_to_wait = 200
var _initial_positions = {}
var _test_passed = false
var _errors = []
var _world_generated = false
var _phase_started_ms: int = 0

const GENERATION_TIMEOUT_MS := 180000
const LOADING_TIMEOUT_MS := 180000

func _ready():
	print("[TEST] === TEST DE INTEGRACION DF MODE ===")
	print("[TEST] Cargando escena principal...")
	var main_scene = load("res://df_mode/df_main.tscn")
	if main_scene == null:
		_error("No se pudo cargar la escena principal")
		get_tree().quit(1)
		return
	_game_main = main_scene.instantiate()
	add_child(_game_main)
	_phase_started_ms = Time.get_ticks_msec()
	print("[TEST] Escena cargada. Esperando inicializacion...")
	_phase = "WAITING_SETTINGS"

func _process(_delta):
	if _game_main == null:
		return
	
	var state = _game_main.current_state if "current_state" in _game_main else -1
	
	if _phase == "WAITING_SETTINGS":
		if state == 0:
			print("[TEST] Estado: SETTINGS_MENU (0). Iniciando Quick Start...")
			_game_main.current_state = 1
			_game_main.set_meta("quick_start_pending", true)
			_game_main.generation_seed = 424242
			_game_main.setting_size = 0
			_game_main.setting_history_idx = 0
			var test_generation_settings = load("res://world/world_generation_settings.tres")
			test_generation_settings.local_map_size = 64
			_phase = "GENERATING"
			_tick_count = 0
			_phase_started_ms = Time.get_ticks_msec()
			print("[TEST] Quick Start enviado! Esperando generacion del mundo...")
	
	elif _phase == "GENERATING":
		if state == 5 or state == 6:
			print("[TEST] Mundo generado! Estado: " + ("PLAYING(5)" if state == 5 else "LOADING_PLAYING(6)"))
			_world_generated = true
			if state == 5:
				_snapshot_positions()
				_tick_count = 0
				_phase = "TICKING"
				print("[TEST] Iniciando monitoreo de " + str(_ticks_to_wait) + " ticks...")
			else:
				_phase = "WAITING_LOAD"
				_tick_count = 0
				_phase_started_ms = Time.get_ticks_msec()
		
		_tick_count += 1
		if Time.get_ticks_msec() - _phase_started_ms > GENERATION_TIMEOUT_MS:
			_error("Timeout esperando generacion del mundo (estado=" + str(state) + ")")
			_finish_test()
	
	elif _phase == "WAITING_LOAD":
		if state == 5:
			print("[TEST] Juego listo! (LOADING_PLAYING completo)")
			if "tick_interval" in _game_main:
				_game_main.tick_interval = 0.05
				print("[TEST] Ajustado tick_interval a 0.001 para acelerar simulacion")
			_snapshot_positions()
			_tick_count = 0
			_phase = "TICKING"
			print("[TEST] Iniciando monitoreo de " + str(_ticks_to_wait) + " ticks...")
		elif state != 6 and state != 5:
			_error("Estado inesperado durante carga: " + str(state))
			_finish_test()
		_tick_count += 1
		if Time.get_ticks_msec() - _phase_started_ms > LOADING_TIMEOUT_MS:
			_error("Timeout esperando LOADING_PLAYING -> PLAYING")
			_finish_test()
	
	elif _phase == "TICKING":
		_tick_count += 1
		if _tick_count >= _ticks_to_wait:
			print("[TEST] " + str(_ticks_to_wait) + " ticks completados!")
			_check_results()
			_finish_test()

func _snapshot_positions():
	print("[TEST] Capturando posiciones iniciales de enanos...")
	var world = _game_main.world if "world" in _game_main else null
	if world == null:
		print("[TEST] WARNING: world no disponible aun")
		return
	
	var dwarf_count = 0
	for e in world.entities:
		var is_dwarf = e.has_method("get") and e.get("creature_type") == "dwarf"
		var is_alive = e.get("is_alive") if e.has_method("get") else false
		if is_dwarf and is_alive == true:
			var pos = e.tile_pos
			var name_str = e.name if "name" in e else "dwarf_" + str(e.id)
			_initial_positions[e.id] = pos
			dwarf_count += 1
			print("[TEST]   Enano #" + str(e.id) + " " + name_str + " en (" + str(pos.x) + "," + str(pos.y) + "," + str(pos.z) + ")")
	
	print("[TEST] Total enanos vivos: " + str(dwarf_count))
	if dwarf_count == 0:
		_error("No se encontraron enanos vivos!")

func _check_results():
	print("[TEST] === VERIFICANDO RESULTADOS ===")
	
	if _world_generated:
		print("[TEST] OK: Mundo generado correctamente")
	else:
		_error("El mundo NO se genero")
	
	var world = _game_main.world
	var total_moved = 0
	var total_checked = 0
	
	for e in world.entities:
		var is_dwarf = e.has_method("get") and e.get("creature_type") == "dwarf"
		var is_alive = e.get("is_alive") if e.has_method("get") else false
		if is_dwarf and is_alive == true:
			var initial = _initial_positions.get(e.id)
			if initial != null:
				total_checked += 1
				var final_pos = e.tile_pos
				var moved = initial != final_pos
				var name_str = e.name if "name" in e else "dwarf_" + str(e.id)
				if moved:
					total_moved += 1
					print("[TEST]   Enano " + name_str + " se MOVIO: (" + str(initial.x) + "," + str(initial.z) + ") -> (" + str(final_pos.x) + "," + str(final_pos.z) + ")")
				else:
					print("[TEST]   Enano " + name_str + " NO se movio: se quedo en (" + str(initial.x) + "," + str(initial.z) + ")")
	
	print("[TEST] Enanos que se movieron: " + str(total_moved) + "/" + str(total_checked))
	
	if total_moved > 0:
		print("[TEST] OK: " + str(total_moved) + " enano(s) se movieron exitosamente!")
		_test_passed = true
	else:
		_error("NINGUN enano se movio. Los enanos estan estaticos.")
	
	if _errors.size() > 0:
		print("[TEST] " + str(_errors.size()) + " error(es) encontrados:")
		for e in _errors:
			print("[TEST]   - " + e)
	else:
		print("[TEST] OK: Sin errores de validacion")

func _error(msg):
	print("[TEST] ERROR: " + msg)
	_errors.append(msg)

func _finish_test():
	print("[TEST] === RESULTADO FINAL ===")
	if _test_passed and _errors.size() == 0:
		print("[TEST] TEST SUPERADO! ")
		get_tree().quit(0)
	else:
		print("[TEST] TEST FALLIDO! " + str(_errors.size()) + " errores")
		get_tree().quit(1)
