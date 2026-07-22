extends Control
class_name DFMain

const DFWorld = preload("res://df_mode/df_world.gd")
const DFWorldGen = preload("res://df_mode/df_world_gen.gd")
const DFWorldHistory = preload("res://df_mode/df_world_history.gd")
const DFRenderer = preload("res://df_mode/df_renderer.gd")
const DFDesignation = preload("res://df_mode/df_designation.gd")
const DFLore = preload("res://df_mode/df_lore.gd")
const DFCombat = preload("res://df_mode/df_combat.gd")
const DFInvasion = preload("res://df_mode/df_invasion.gd")
const DFMilitary = preload("res://df_mode/df_military.gd")
const DFLegends = preload("res://df_mode/df_legends.gd")
const DFAudio = preload("res://df_mode/df_audio.gd")
const DFCaravan = preload("res://df_mode/df_caravan.gd")
const DFItem = preload("res://df_mode/df_item.gd")
const DFData = preload("res://df_mode/df_data.gd")
const DFDwarf = preload("res://df_mode/df_dwarf.gd")
const DFCreature = preload("res://df_mode/df_creature.gd")
const DFJob = preload("res://df_mode/df_job.gd")
const DFStockpile = preload("res://df_mode/df_stockpile.gd")
const DFWorkshop = preload("res://df_mode/df_workshop.gd")
const DFPathfinding = preload("res://df_mode/df_pathfinding.gd")
const DFDialogue = preload("res://df_mode/df_dialogue.gd")
const DFFastTravel = preload("res://df_mode/df_fast_travel.gd")
const DFQuestSystem = preload("res://df_mode/df_quest.gd")
const DFSaveLoad = preload("res://df_mode/df_save_load.gd")
const DFWorldSimulationScript = preload("res://df_mode/core/simulation/world_simulation.gd")
const WorldGenerationSettings = preload("res://world/world_generation_settings.gd")

var world = null
var world_simulation: DFWorldSimulation = null
var world_gen = null
var history_gen = null
var renderer: DFRenderer = null
var designation: DFDesignation = null

var paused: bool = false
var tick_interval: float = 0.1
var generation_seed: int = -1
var minimap_open: bool = false
var lore: DFLore = null
var legends: DFLegends = null
var caravan_system: DFCaravan = null
var caravan_menu_open: bool = false
var legends_mode: bool = false
var legends_category: int = 0
var _legends_select_mode: bool = false
var _chronicle_events_game: Array = []

var _time_accum: float = 0.0
var _game_minute: int = 0
var _game_hour: int = 6
var _game_day: int = 1
var _game_season: String = "Spring"
var _game_year: int = 63
const SEASON_LIST: Array = ["Spring", "Summer", "Autumn", "Winter"]
const SEASON_ENUM_MAP = {"Spring": DFWorld.Season.SPRING, "Summer": DFWorld.Season.SUMMER, "Autumn": DFWorld.Season.AUTUMN, "Winter": DFWorld.Season.WINTER}
# Todos los residentes continúan existiendo y pensando fuera de cámara. Se reparten
# entre varios ticks para evitar picos, sin convertirlos en estadísticas abstractas.
const SETTLEMENT_RESIDENT_TICK_BUCKETS: int = 4

const HOUSE_TEMPLATES = [
	# Casa 0: Cabaña Estándar Cuadrada (3x3)
	{
		"floors": [
			Vector2i(-1,-1), Vector2i(0,-1), Vector2i(1,-1),
			Vector2i(-1,0),  Vector2i(0,0),  Vector2i(1,0),
			Vector2i(-1,1),  Vector2i(0,1),  Vector2i(1,1)
		],
		"door": Vector2i(0, 2),
		"bed": Vector2i(0, -1)
	},
	# Casa 1: Casa de Campo Alargada (4x3)
	{
		"floors": [
			Vector2i(-2,-1), Vector2i(-1,-1), Vector2i(0,-1), Vector2i(1,-1),
			Vector2i(-2,0),  Vector2i(-1,0),  Vector2i(0,0),  Vector2i(1,0),
			Vector2i(-2,1),  Vector2i(-1,1),  Vector2i(0,1),  Vector2i(1,1)
		],
		"door": Vector2i(0, 2),
		"bed": Vector2i(-2, -1)
	},
	# Casa 2: Cabaña en L
	{
		"floors": [
			Vector2i(-1,-1), Vector2i(0,-1), Vector2i(1,-1),
			Vector2i(-1,0),  Vector2i(0,0),  Vector2i(1,0),
			Vector2i(-1,1),  Vector2i(0,1),  Vector2i(1,1),
			Vector2i(2,0),   Vector2i(2,1)
		],
		"door": Vector2i(0, 2),
		"bed": Vector2i(2, 1)
	},
	# Casa 3: Granero Vertical (3x4)
	{
		"floors": [
			Vector2i(-1,-2), Vector2i(0,-2), Vector2i(1,-2),
			Vector2i(-1,-1), Vector2i(0,-1), Vector2i(1,-1),
			Vector2i(-1,0),  Vector2i(0,0),  Vector2i(1,0),
			Vector2i(-1,1),  Vector2i(0,1),  Vector2i(1,1)
		],
		"door": Vector2i(0, 2),
		"bed": Vector2i(0, -2)
	},
	# Casa 4: Estudio Ancho (5x3)
	{
		"floors": [
			Vector2i(-2,-1), Vector2i(-1,-1), Vector2i(0,-1), Vector2i(1,-1), Vector2i(2,-1),
			Vector2i(-2,0),  Vector2i(-1,0),  Vector2i(0,0),  Vector2i(1,0),  Vector2i(2,0),
			Vector2i(-2,1),  Vector2i(-1,1),  Vector2i(0,1),  Vector2i(1,1),  Vector2i(2,1)
		],
		"door": Vector2i(0, 2),
		"bed": Vector2i(2, -1)
	},
	# Casa 5: Cabaña en T
	{
		"floors": [
			Vector2i(-2,-1), Vector2i(-1,-1), Vector2i(0,-1), Vector2i(1,-1), Vector2i(2,-1),
			Vector2i(0,0),   Vector2i(0,1)
		],
		"door": Vector2i(0, 2),
		"bed": Vector2i(-2, -1)
	},
	# Casa 6: Refugio Compacto Diagonal
	{
		"floors": [
			Vector2i(0,-1),  Vector2i(1,-1),  Vector2i(2,-1),
			Vector2i(-1,0),  Vector2i(0,0),   Vector2i(1,0),
			Vector2i(-2,1),  Vector2i(-1,1),  Vector2i(0,1)
		],
		"door": Vector2i(0, 2),
		"bed": Vector2i(2, -1)
	}
]

var camera_pos: Vector3i = Vector3i(64, 3, 64)
var _mouse_tile_pos: Vector3i = Vector3i(-1, -1, -1)
var settings_menu: Control = null
var possessed_dwarf: Object = null
var last_possessed_dwarf: Object = null
var follow_time: float = 0.0

# Repetición controlada para movimiento mantenido durante la posesión.
const HELD_MOVE_INITIAL_DELAY: float = 0.16
const HELD_MOVE_REPEAT_INTERVAL: float = 0.08
var _held_move_timer: float = 0.0
var _held_move_direction: Vector2i = Vector2i.ZERO

var world_name: String = ""
var world_history: Array = []
var current_history_page: int = 0

enum GameState {
	SETTINGS_MENU,
	GENERATING_WORLD,
	MODE_SELECT,
	EMBARK_MAP_SELECT,
	EMBARK_PREPARE,
	PLAYING,
	LOADING_PLAYING
}
var current_state: int = GameState.SETTINGS_MENU

var load_progress: float = 0.0
var load_status: String = ""
var load_step: int = 0
var load_play_now: bool = false

var setting_size: int = 3
var setting_history_options = [5, 50, 125, 250, 500]
var setting_history_idx = 2
var setting_civ_density: int = 1
var setting_beast_density: int = 1
var setting_selected_index: int = 0

var gen_year: int = 0
var gen_max_years: int = 125
var gen_historical_figures: int = 0
var gen_active_sites: int = 0
var gen_active_wars: int = 0
var gen_relics_created: int = 0
var gen_beasts_alive: int = 0
var gen_current_age: String = "Age of Myth"
var gen_rolling_events: Array = []
var gen_step: int = 0

var embark_cursor: Vector2i = Vector2i(0, 0)
var embark_flash_timer: float = 0.0

var embark_prepare_points: int = 100
var embark_prepare_selected_idx: int = 0
var embark_custom_skills: Dictionary = {
	"MINING": 1, "CARPENTRY": 1, "MASONRY": 1, "SMITHING": 1,
	"FARMING": 1, "WOODCUTTING": 1, "BREWING": 1
}
var embark_custom_items: Dictionary = {
	"Plump Helmet Seed": 10, "Plump Helmet": 15, "Dwarven Ale": 15,
	"Copper Pickaxe": 2, "Copper Woodcutter Axe": 1
}
var embark_prepare_step: int = 0

# === CONFIGURACIÓN DE ENANOS Y COLONIA (Editable desde Inspector o código) ===
## Nombres de los 7 enanos fundadores. Vacío = nombre aleatorio
var config_dwarf_names: Array = ["", "", "", "", "", "", ""]
## Profesiones de los 7 enanos fundadores (valores del enum DFDwarf.Profession)
var config_dwarf_professions: Array = []
## Arma equipada de cada enano ("pickaxe", "axe", "sword", "none")
var config_dwarf_weapons: Array = ["pickaxe", "axe", "none", "none", "none", "none", "none"]
## Prioridades de labores por enano (Dictionary vacío = por defecto segun profesión)
var config_dwarf_priorities: Array = [{}, {}, {}, {}, {}, {}, {}]

var _generation_phase: int = 0
var _generating: bool = false
var _biome_creature_index: Dictionary = {}
var _simulation_tick_clock: int = 0
var _absolute_simulation_tick: int = 0
var settlement_center: Vector3i = Vector3i(128, 3, 128)
var _autonomous_house_projects: Array = []
var _last_autonomy_plan_minute: int = -999999
var dialogue: DFDialogue = null
var dialogue_target_entity = null
var fast_travel: DFFastTravel = null
var quest_system: DFQuestSystem = null
var _world_gen_in_progress: bool = false
var _loading_in_progress: bool = false

func _ready() -> void:
	randomize()
	dialogue = DFDialogue.new(null, self)
	fast_travel = DFFastTravel.new(null, self)
	quest_system = DFQuestSystem.new(null, self)
	renderer = DFRenderer.new()
	renderer.name = "Renderer"
	renderer.anchor_left = 0.0
	renderer.anchor_top = 0.0
	renderer.anchor_right = 1.0
	renderer.anchor_bottom = 1.0
	renderer.offset_left = 0
	renderer.offset_top = 0
	renderer.offset_right = 0
	renderer.offset_bottom = 0
	renderer.show_sidebar = true
	renderer.sidebar_width = 32
	renderer.paused = true
	renderer.show_help = false
	add_child(renderer)

	var audio = DFAudio.new()
	audio.name = "DFAudio"
	add_child(audio)

	generation_seed = randi()
	var generation_defaults := load("res://world/world_generation_settings.tres") as WorldGenerationSettings
	if generation_defaults != null:
		setting_size = clampi(generation_defaults.default_world_size_index, 0, 3)
	add_message("========================================")
	add_message("  CREACION DE MUNDO BIGLI")
	add_message("  ~ Clon de Dwarf Fortress ~")
	add_message("========================================")
	add_message("  Semilla: %d" % generation_seed)
	
	settings_menu = preload("res://df_mode/df_settings_menu.gd").new()
	settings_menu.tutorial_requested.connect(_on_tutorial_requested)
	settings_menu.close_requested.connect(_on_settings_close)
	add_child(settings_menu)
	
	# La pantalla se dibuja sin postprocesado. Se eliminaron el overlay CRT,
	# las scanlines, la viñeta y el bloom que oscurecían el mapa.
	
	current_state = GameState.SETTINGS_MENU
	renderer.show_sidebar = false
	paused = true
	_generating = false

func _on_tutorial_requested() -> void:
	add_message("Tutorial no implementado aun.")

func _on_settings_close() -> void:
	settings_menu.visible = false
	paused = false
	renderer.paused = paused

func add_message(msg: String) -> void:
	if renderer != null and renderer.has_method("add_message"):
		renderer.add_message(msg)
	elif renderer != null:
		print("DF: " + msg)


## Lee una propiedad tanto de Dictionary como de Object/RefCounted.
## Object.get() acepta un solo argumento; este helper aplica el valor por defecto.
func _safe_get(source: Variant, property_name: StringName, default_value: Variant = null) -> Variant:
	if source == null:
		return default_value
	if source is Dictionary:
		return source.get(property_name, default_value)
	if source is Object:
		var value: Variant = source.get(property_name)
		return default_value if value == null else value
	return default_value

func _recipe_input_matches_item(input_definition: Dictionary, candidate_item: DFItem) -> bool:
	if candidate_item == null or candidate_item.is_decayed or candidate_item.carried_by_id >= 0:
		return false
	var item_name: String = candidate_item.name.to_lower()
	var item_type_name: String = candidate_item.item_type.to_lower()
	var material_name: String = candidate_item.material_name.to_lower()
	if bool(input_definition.get("fuel", false)):
		return (
			"carbón" in item_name or "carbon" in item_name or "coal" in item_name
			or "charcoal" in item_name or item_type_name in ["fuel", "charcoal", "coal"]
		)
	if input_definition.has("type"):
		var required_type: String = str(input_definition.get("type", "")).to_lower()
		if item_type_name != required_type and item_type_name != required_type + "s":
			return false
		var specific_values: Array = input_definition.get("specific", [])
		if specific_values.is_empty():
			return true
		for specific_value: Variant in specific_values:
			var specific_name: String = str(specific_value).to_lower()
			if specific_name == item_type_name or specific_name in item_name:
				return true
		return false
	if input_definition.has("material"):
		for material_value: Variant in input_definition.get("material", []):
			var allowed_name: String = str(material_value).to_lower()
			if allowed_name == item_type_name or allowed_name == material_name or allowed_name in item_name:
				return true
	return false

func _workshop_has_recipe_inputs(world_ref, workshop, recipe: Dictionary) -> bool:
	for input_value: Variant in recipe.get("inputs", []):
		if not (input_value is Dictionary):
			continue
		var input_definition: Dictionary = input_value
		var remaining: int = maxi(1, int(input_definition.get("count", 1)))
		for world_entry: Variant in world_ref.entities:
			if not (world_entry is DFItem):
				continue
			var candidate_item: DFItem = world_entry
			if candidate_item.tile_pos.distance_squared_to(workshop.tile_pos) > 2:
				continue
			if _recipe_input_matches_item(input_definition, candidate_item):
				remaining -= maxi(1, candidate_item.stack_size)
				if remaining <= 0:
					break
		if remaining > 0:
			return false
	return true

func _workshop_operator_is_present(world_ref, workshop) -> bool:
	for world_entry: Variant in world_ref.entities:
		if not (world_entry is DFDwarf):
			continue
		var dwarf: DFDwarf = world_entry
		if dwarf.id != workshop.dwarf_assigned or not dwarf.is_alive:
			continue
		var distance: int = (
			abs(dwarf.tile_pos.x - workshop.tile_pos.x)
			+ abs(dwarf.tile_pos.z - workshop.tile_pos.z)
			+ abs(dwarf.tile_pos.y - workshop.tile_pos.y) * 2
		)
		return distance <= 1
	return false

func _workshop_assignment_is_valid(world_ref, workshop: DFWorkshop) -> bool:
	if workshop == null or workshop.dwarf_assigned < 0:
		return false
	for world_entry: Variant in world_ref.entities:
		if not (world_entry is DFDwarf):
			continue
		var dwarf: DFDwarf = world_entry
		if dwarf.id != workshop.dwarf_assigned:
			continue
		return dwarf.is_alive and not dwarf.is_possessed and dwarf.operating_workshop == workshop
	return false

func _consume_recipe_inputs(world_ref, workshop, recipe: Dictionary) -> void:
	for input_value: Variant in recipe.get("inputs", []):
		if not (input_value is Dictionary):
			continue
		var input_definition: Dictionary = input_value
		var remaining: int = maxi(1, int(input_definition.get("count", 1)))
		for world_entry: Variant in world_ref.entities.duplicate():
			if remaining <= 0:
				break
			if not (world_entry is DFItem):
				continue
			var candidate_item: DFItem = world_entry
			if candidate_item.tile_pos.distance_squared_to(workshop.tile_pos) > 2:
				continue
			if not _recipe_input_matches_item(input_definition, candidate_item):
				continue
			var item_amount: int = maxi(1, candidate_item.stack_size)
			if item_amount > remaining:
				candidate_item.stack_size = item_amount - remaining
				remaining = 0
			else:
				remaining -= item_amount
				world_ref.entities.erase(candidate_item)

func _add_message_async(msg: String) -> void:
	add_message(msg)

func _place_dwarves_and_setup() -> void:
	world.world_name = world_name
	world.combat_system = DFCombat.new()
	world.invasion_system = DFInvasion.new(generation_seed)
	world.military_system = DFMilitary.new(generation_seed)

	# Encontrar punto de partida sólido en la superficie
	var center_raw = Vector3i(int(world.width / 2.0), 3, int(world.depth / 2.0))
	var center = _fix_surface(center_raw)

	# === FASE 1: EXCAVAR UN REFUGIO INICIAL (sala 7x5 en ladera) ===
	var shelter_cx = center.x - 4
	var shelter_cz = center.z - 3
	var shelter_built = false
	# Buscar colina cercana para excavar
	for try_r in range(1, 15):
		for try_dz in range(-try_r, try_r + 1):
			for try_dx in range(-try_r, try_r + 1):
				if abs(try_dx) != try_r and abs(try_dz) != try_r:
					continue
				var base = _fix_surface(Vector3i(
					clampi(center.x + try_dx, 4, world.width - 8),
					center.y,
					clampi(center.z + try_dz, 4, world.depth - 8)))
				var above = Vector3i(base.x, base.y + 1, base.z)
				if world.is_wall(above):
					shelter_cx = base.x
					shelter_cz = base.z
					shelter_built = true
					break
			if shelter_built:
				break
		if shelter_built:
			break

	if shelter_built:
		# Excavar sala 7x5 en la ladera
		for sz in range(5):
			for sx in range(7):
				var dig = Vector3i(shelter_cx + sx, center.y, shelter_cz + sz)
				if world.tiles.has(dig):
					world.set_tile(dig, DFWorld.TileType.CAVE_FLOOR)
		add_message("  *** Refugio excavado en la colina ***")
	else:
		# Construir una estructura abierta en la superficie (4 paredes + suelo)
		for sz2 in range(5):
			for sx2 in range(7):
				var fp = _fix_surface(Vector3i(
					clampi(center.x - 3 + sx2, 2, world.width - 3),
					center.y,
					clampi(center.z - 2 + sz2, 2, world.depth - 3)))
				# Borde = muro construido
				if sx2 == 0 or sx2 == 6 or sz2 == 0 or sz2 == 4:
					world.set_tile(fp, DFWorld.TileType.CONSTRUCTED_WALL)
				else:
					world.set_tile(fp, DFWorld.TileType.CONSTRUCTED_FLOOR)
		add_message("  *** Campamento inicial construido ***")

	# === FASE 2: SPAWN DE 14 ENANOS (espiral garantizada) ===
	var num_dwarves = 14
	var used_spawn_positions: Array = []
	for i in range(num_dwarves):
		var dname = world_gen.namegen.generate_dwarf_name()
		var dpos = _find_valid_spawn_spiral(center, used_spawn_positions)
		used_spawn_positions.append(dpos)
		var dwarf = DFDwarf.new(dpos, dname)
		# Inventario inicial: 2 comida + 2 bebida por enano
		_give_embark_inventory(dwarf, i)
		world.entities.append(dwarf)

	# === FASE 3: ALMACEN DE EMBARQUE ===
	# Zona de almacenamiento en el centro-sur del refugio
	var store_x = clampi((shelter_cx if shelter_built else center.x - 2), 2, world.width - 3)
	var store_z = clampi((shelter_cz if shelter_built else center.z), 2, world.depth - 3)

	# 30 alimentos variados
	var food_list = [
		["Plump Helmet", Color("#FF8844")], ["Sweet Pod", Color("#FF88CC")],
		["Cave Mushroom", Color("#AAAAAA")], ["Pig Tail", Color("#88FF88")],
		["Quarry Bush", Color("#88FFAA")], ["Prepared Meal", Color("#FFCC44")]
	]
	for fi in range(30):
		var fdata = food_list[fi % food_list.size()]
		var fpos = _fix_surface(Vector3i(
			clampi(store_x + (fi % 6), 2, world.width - 3),
			center.y,
			clampi(store_z + int(fi / 6), 2, world.depth - 3)))
		world._spawn_item(fpos, fdata[0], "food", 0, "%", fdata[1])

	# 30 bebidas variadas
	var drink_list = [
		["Dwarven Ale", Color("#FFCC00")], ["Cave Wine", Color("#AA44FF")],
		["Plump Helmet Wine", Color("#FF88AA")], ["Sweet Pod Rum", Color("#FF8800")],
		["Mushroom Brew", Color("#888888")]
	]
	for di in range(30):
		var ddata = drink_list[di % drink_list.size()]
		var dpos2 = _fix_surface(Vector3i(
			clampi(store_x + (di % 6), 2, world.width - 3),
			center.y,
			clampi(store_z - 1 - int(di / 6), 2, world.depth - 3)))
		world._spawn_item(dpos2, ddata[0], "drink", 0, "~", ddata[1])

	# 20 materiales de construcción (piedra y madera)
	for bi in range(20):
		var bpos = _fix_surface(Vector3i(
			clampi(center.x + (bi % 5) - 2, 2, world.width - 3),
			center.y,
			clampi(center.z + 4 + int(bi / 5), 2, world.depth - 3)))
		if bi < 12:
			world._spawn_item(bpos, "Roca de Granito", "stone", DFWorld.MatType.GRANITE, "*", Color("#888888"))
		else:
			world._spawn_item(bpos, "Tablón de Madera", "wood", DFWorld.MatType.WOOD, "/", Color("#8B6914"))

	# Semillas para granja (5 tipos)
	for si in range(5):
		var seed_types = [["Semillas de Plump Helmet", Color("#FF8844")], ["Semillas de Cave Wheat", Color("#FFFF88")],
			["Semillas de Sweet Pod", Color("#FF88CC")], ["Semillas de Pig Tail", Color("#88FF88")],
			["Semillas de Quarry Bush", Color("#88FFAA")]]
		var spos = _fix_surface(Vector3i(
			clampi(center.x - 2 + si, 2, world.width - 3),
			center.y,
			clampi(center.z + 5, 2, world.depth - 3)))
		world._spawn_item(spos, seed_types[si][0], "seed", 0, ".", seed_types[si][1])

	# Herramientas clave cerca del refugio
	var tool_pos = _fix_surface(Vector3i(clampi(center.x, 2, world.width - 3), center.y, clampi(center.z + 2, 2, world.depth - 3)))
	world._spawn_item(tool_pos, "Hacha de Cobre", "weapon", DFWorld.MatType.COPPER, "/", Color("#CC7733"))
	world._spawn_item(tool_pos, "Pico de Hierro", "weapon", DFWorld.MatType.IRON, "/", Color("#808080"))
	world._spawn_item(tool_pos, "Pala de Madera", "tool", DFWorld.MatType.WOOD, "\\", Color("#8B6914"))
	world._spawn_item(tool_pos, "Cuerda", "tool", 0, "~", Color("#CCBB88"))

	# Ropa básica (7 sets: uno por enano aprox)
	for ci in range(7):
		var cloth_pos = _fix_surface(Vector3i(
			clampi(center.x + ci - 3, 2, world.width - 3),
			center.y,
			clampi(center.z - 3, 2, world.depth - 3)))
		world._spawn_item(cloth_pos, "Camisa de Lino", "armor", 0, "[", Color("#DDDDBB"))
		world._spawn_item(cloth_pos, "Pantalón de Cuero", "armor", 0, "[", Color("#8B6914"))
		world._spawn_item(cloth_pos, "Botas de Cuero", "armor", 0, "[", Color("#7A5230"))

	add_message("  *** %d enanos + provisiones de embarque listas ***" % num_dwarves)

	caravan_system = DFCaravan.new(generation_seed)
	camera_pos = Vector3i(clampi(center.x, 0, world.width - 1), center.y, clampi(center.z, 0, world.depth - 1))
	designation = DFDesignation.new(world)
	renderer.set_world(world)
	renderer.designation = designation
	renderer.game_year = gen_max_years

## Busca posición de spawn usando espiral, evitando tiles usados.
func _find_valid_spawn_spiral(origin: Vector3i, used: Array) -> Vector3i:
	for radius in range(0, 25):
		for dz in range(-radius, radius + 1):
			for dx in range(-radius, radius + 1):
				if radius > 0 and abs(dx) != radius and abs(dz) != radius:
					continue
				var cx = clampi(origin.x + dx, 2, world.width - 3)
				var cz = clampi(origin.z + dz, 2, world.depth - 3)
				var candidate = _fix_surface(Vector3i(cx, origin.y, cz))
				if world.is_blocked(candidate) or world.is_water(candidate):
					continue
				var taken = false
				for up in used:
					if up == candidate:
						taken = true
						break
				if not taken and _has_open_adjacent_tile(world, candidate):
					return candidate
	return origin

## Da inventario inicial a un enano según su índice de embarque.
func _give_embark_inventory(dwarf: DFDwarf, idx: int) -> void:
	var food_names = ["Plump Helmet", "Sweet Pod", "Cave Mushroom", "Prepared Meal", "Pig Tail", "Quarry Bush"]
	var drink_names = ["Dwarven Ale", "Cave Wine", "Plump Helmet Wine", "Sweet Pod Rum", "Mushroom Brew"]
	# 2 comidas en el inventario
	for fi in range(2):
		var fi_item = DFItem.new(dwarf.tile_pos, food_names[(idx * 2 + fi) % food_names.size()], "food", 0, "%", Color("#FF8844"))
		fi_item.nutrition = 0.6
		fi_item.is_edible = true
		fi_item.carried_by_id = dwarf.id
		dwarf.inventory.append(fi_item)
	# 2 bebidas en el inventario
	for di in range(2):
		var di_item = DFItem.new(dwarf.tile_pos, drink_names[(idx * 2 + di) % drink_names.size()], "drink", 0, "~", Color("#FFCC00"))
		di_item.hydration = 0.5
		di_item.is_drink = true
		di_item.carried_by_id = dwarf.id
		dwarf.inventory.append(di_item)
	# Ropa básica (armor simbólica)
	dwarf.equipped_armor = "shirt"
	dwarf.armor_value = 0.5
	# Herramienta por profesión
	match dwarf.profession:
		DFDwarf.Profession.MINER: dwarf.equipped_weapon = "pickaxe"
		DFDwarf.Profession.WOODCUTTER: dwarf.equipped_weapon = "axe"
		DFDwarf.Profession.MILITARY: dwarf.equipped_weapon = "sword"; dwarf.is_military = true
		DFDwarf.Profession.HUNTER: dwarf.equipped_weapon = "crossbow"
		_: dwarf.equipped_weapon = "fist"

func _count_dwarf_consumables(dwarf: DFDwarf, kind: String) -> int:
	var count: int = 0
	for candidate in dwarf.inventory:
		if not candidate is DFItem:
			continue
		var item: DFItem = candidate
		if kind == "drink":
			if item.is_drink or item.item_type == "drink":
				count += 1
		elif item.is_food or item.item_type in ["food", "meat"] or (item.is_edible and not item.is_drink):
			count += 1
	return count

func _inventory_has_tool_tag(dwarf: DFDwarf, tag: String) -> bool:
	for candidate in dwarf.inventory:
		if candidate is DFItem and tag in candidate.tool_tags:
			return true
	return false

func _starting_tool_spec(dwarf: DFDwarf, configured_weapon: String) -> Dictionary:
	var configured: String = configured_weapon.to_lower()
	if configured == "pickaxe":
		return {"name": "Pico de Cobre", "type": "tool", "glyph": "p", "color": Color("#AACCFF"), "tag": "mining", "equipped": "pickaxe"}
	if configured == "axe":
		return {"name": "Hacha de Cobre", "type": "tool", "glyph": "/", "color": Color("#88CCFF"), "tag": "woodcutting", "equipped": "axe"}
	if configured == "sword":
		return {"name": "Espada de Hierro", "type": "weapon", "glyph": "!", "color": Color("#DDDDFF"), "tag": "combat", "equipped": "sword"}

	match dwarf.profession:
		DFDwarf.Profession.MINER:
			return {"name": "Pico de Cobre", "type": "tool", "glyph": "p", "color": Color("#AACCFF"), "tag": "mining", "equipped": "pickaxe"}
		DFDwarf.Profession.WOODCUTTER, DFDwarf.Profession.CARPENTER:
			return {"name": "Hacha de Cobre", "type": "tool", "glyph": "/", "color": Color("#88CCFF"), "tag": "woodcutting", "equipped": "axe"}
		DFDwarf.Profession.FARMER:
			return {"name": "Azada de Hierro", "type": "tool", "glyph": "/", "color": Color("#999999"), "tag": "farming", "equipped": "hoe"}
		DFDwarf.Profession.HUNTER:
			return {"name": "Ballesta de Madera", "type": "weapon", "glyph": "}", "color": Color("#CCAA66"), "tag": "hunting", "equipped": "crossbow"}
		DFDwarf.Profession.MILITARY:
			return {"name": "Espada de Hierro", "type": "weapon", "glyph": "!", "color": Color("#DDDDFF"), "tag": "combat", "equipped": "sword"}
		DFDwarf.Profession.DOCTOR, DFDwarf.Profession.CHIEF_MEDICAL_DWARF:
			return {"name": "Botiquín de Campaña", "type": "tool", "glyph": "+", "color": Color("#FFFFFF"), "tag": "medicine", "equipped": "medical kit"}
		_:
			return {}

func _ensure_dwarf_starting_kit(dwarf: DFDwarf, idx: int, configured_weapon: String = "") -> void:
	for candidate in dwarf.inventory:
		if candidate is DFItem:
			candidate.carried_by_id = dwarf.id
			candidate.release_reservation()

	var food_names: Array = ["Plump Helmet", "Sweet Pod", "Cave Mushroom", "Prepared Meal", "Pig Tail", "Quarry Bush"]
	var drink_names: Array = ["Dwarven Ale", "Cave Wine", "Plump Helmet Wine", "Sweet Pod Rum", "Mushroom Brew"]
	while _count_dwarf_consumables(dwarf, "food") < 2:
		var food_index: int = (idx + _count_dwarf_consumables(dwarf, "food")) % food_names.size()
		var food_item: DFItem = DFItem.new(dwarf.tile_pos, str(food_names[food_index]), "food", 0, "%", Color("#FF8844"))
		food_item.nutrition = 0.6
		food_item.carried_by_id = dwarf.id
		dwarf.inventory.append(food_item)
	while _count_dwarf_consumables(dwarf, "drink") < 2:
		var drink_index: int = (idx + _count_dwarf_consumables(dwarf, "drink")) % drink_names.size()
		var drink_item: DFItem = DFItem.new(dwarf.tile_pos, str(drink_names[drink_index]), "drink", 0, "~", Color("#FFCC00"))
		drink_item.hydration = 0.5
		drink_item.carried_by_id = dwarf.id
		dwarf.inventory.append(drink_item)

	var has_body_clothing: bool = false
	for clothing_candidate in dwarf.inventory:
		if clothing_candidate is DFItem and clothing_candidate.equipment_slot == "body":
			has_body_clothing = true
			break
	if not has_body_clothing:
		var shirt: DFItem = DFItem.new(dwarf.tile_pos, "Camisa de Lino", "armor", 0, "[", Color("#DDDDBB"))
		shirt.equipment_slot = "body"
		shirt.armor_slot = "body"
		shirt.carried_by_id = dwarf.id
		dwarf.inventory.append(shirt)

	var tool_spec: Dictionary = _starting_tool_spec(dwarf, configured_weapon)
	if not tool_spec.is_empty():
		var tool_tag: String = str(tool_spec.get("tag", ""))
		if tool_tag.is_empty() or not _inventory_has_tool_tag(dwarf, tool_tag):
			var raw_tool_color: Variant = tool_spec.get("color", Color.WHITE)
			var tool_color: Color = raw_tool_color if raw_tool_color is Color else Color.WHITE
			var tool_item: DFItem = DFItem.new(dwarf.tile_pos, str(tool_spec["name"]), str(tool_spec["type"]), 0, str(tool_spec["glyph"]), tool_color)
			if not tool_tag.is_empty() and not tool_tag in tool_item.tool_tags:
				tool_item.tool_tags.append(tool_tag)
			tool_item.carried_by_id = dwarf.id
			dwarf.inventory.append(tool_item)
		var equipped_name: String = str(tool_spec.get("equipped", ""))
		if dwarf.equipped_weapon == "fist" and not equipped_name.is_empty():
			dwarf.equipped_weapon = equipped_name

func _try_distribute_initial_item(item: DFItem, dwarves: Array) -> bool:
	var desired_kind: String = ""
	var target_count: int = 0
	if item.is_drink or item.item_type == "drink":
		desired_kind = "drink"
		target_count = 3
	elif item.is_food or item.item_type in ["food", "meat"]:
		desired_kind = "food"
		target_count = 3
	else:
		return false

	var best_dwarf: DFDwarf = null
	var best_count: int = target_count + 1
	for dwarf_candidate in dwarves:
		if not dwarf_candidate is DFDwarf or not dwarf_candidate.is_alive:
			continue
		var current_count: int = _count_dwarf_consumables(dwarf_candidate, desired_kind)
		if current_count < target_count and current_count < best_count:
			best_count = current_count
			best_dwarf = dwarf_candidate
	if best_dwarf == null:
		return false
	item.carried_by_id = best_dwarf.id
	item.release_reservation()
	best_dwarf.inventory.append(item)
	return true

func _apply_dwarf_profile(dwarf: DFDwarf, idx: int, quick_start: bool) -> void:
	var p = DFDwarf.PersonalityTrait
	var S = DFDwarf.Skill
	var profiles = [
		{
			"name_suffix": "Rocahendida",
			"gender": "Male", "age": 47,
			"worships": "Armok, Dios de la Sangre",
			"personality": { p.BRAVERY: 0.95, p.GREED: 0.7, p.VIOLENCE: 0.5, p.INDUSTRY: 0.85, p.LAZINESS: 0.1, p.SOCIABILITY: 0.4, p.CURIOSITY: 0.5, p.JEALOUSY: 0.3, p.COMPASSION: 0.4, p.PRIDE: 0.85, p.ANGER: 0.5, p.FEAR: 0.15, p.HONESTY: 0.8, p.CRUELTY: 0.3, p.FORGIVENESS: 0.5, p.PLAYFULNESS: 0.2, p.POLITENESS: 0.4, p.AMBITION: 0.9, p.STUBBORNNESS: 0.8, p.PATIENCE: 0.6, p.VANITY: 0.3 },
			"stats": { "strength": 13, "agility": 6, "toughness": 11 },
			"skills": { S.MINING: 5, S.MASONRY: 3, S.ORGANIZING: 3, S.LEADERSHIP: 2, S.ENGRAVING: 1, S.MILITARY_TACTICS: 2 },
			"equipment": { "weapon": "Pico de Acero", "armor": "Armadura de Cuero", "helmet": "Casco de Cobre", "shield": "" },
			"inventory": [],
			"leader": true,
			"thoughts": ["Lider? la expedici?n anterior a las Monta?as Fulgor", "Perdi? a tres compa?eros en un derrumbe y jur? no olvidarlos", "Forj? su primer pico a los 16 a?os en la forja de su clan"]
		},
		{
			"name_suffix": "Tronc?n",
			"gender": "Male", "age": 35,
			"worships": "M?nir, Dios de los Bosques",
			"personality": { p.BRAVERY: 0.6, p.GREED: 0.4, p.VIOLENCE: 0.3, p.INDUSTRY: 0.9, p.LAZINESS: 0.1, p.SOCIABILITY: 0.5, p.CURIOSITY: 0.3, p.JEALOUSY: 0.4, p.COMPASSION: 0.5, p.PRIDE: 0.6, p.ANGER: 0.65, p.FEAR: 0.3, p.HONESTY: 0.7, p.CRUELTY: 0.2, p.FORGIVENESS: 0.6, p.PLAYFULNESS: 0.3, p.POLITENESS: 0.3, p.AMBITION: 0.4, p.STUBBORNNESS: 0.7, p.PATIENCE: 0.5, p.VANITY: 0.2 },
			"stats": { "strength": 11, "agility": 7, "toughness": 9 },
			"skills": { S.WOODCUTTING: 5, S.CARPENTRY: 2, S.MECHANICS: 1 },
			"equipment": { "weapon": "Hacha de Bronce", "armor": "Chaleco de Cuero", "helmet": "", "shield": "" },
			"inventory": [],
			"leader": false,
			"thoughts": ["Tal? un ?rbol sagrado sin querer y fue maldecido por los druidas", "Gan? tres concursos de tala en la Fortaleza Roca?", "Construy? su propia caba?a de troncos con una sola mano después de un accidente"]
		},
		{
			"name_suffix": "Ojoprese",
			"gender": "Female", "age": 28,
			"worships": "Shibe?n, Diosa de la Caza",
			"personality": { p.BRAVERY: 0.85, p.GREED: 0.3, p.VIOLENCE: 0.7, p.INDUSTRY: 0.6, p.LAZINESS: 0.3, p.SOCIABILITY: 0.3, p.CURIOSITY: 0.75, p.JEALOUSY: 0.2, p.COMPASSION: 0.3, p.PRIDE: 0.7, p.ANGER: 0.5, p.FEAR: 0.1, p.HONESTY: 0.6, p.CRUELTY: 0.5, p.FORGIVENESS: 0.3, p.PLAYFULNESS: 0.4, p.POLITENESS: 0.2, p.AMBITION: 0.6, p.STUBBORNNESS: 0.6, p.PATIENCE: 0.7, p.VANITY: 0.5 },
			"stats": { "strength": 8, "agility": 11, "toughness": 7 },
			"skills": { S.MILITARY_TACTICS: 4, S.WOODCUTTING: 1, S.DANCE: 2, S.SIEGECRAFT: 1, S.LEADERSHIP: 1 },
			"equipment": { "weapon": "Ballesta de Hueso", "armor": "Armadura de Cuero", "helmet": "Capa de Lobo", "shield": "" },
			"inventory": ["Flecha de Hueso", "Flecha de Hueso", "Flecha de Hueso", "Flecha de Hueso", "Flecha de Hueso", "Cuchillo de Desuello"],
			"leader": false,
			"thoughts": ["Rastre? un gran jabal? durante tres d?as antes de abatirlo", "Sobrevivi? sola un invierno en los picos helados", "Tiene una cicatriz en el rostro por el ara?azo de un tigre"]
		},
		{
			"name_suffix": "Manosdulces",
			"gender": "Male", "age": 52,
			"worships": "K?b?n, Dios de la Artesan?a",
			"personality": { p.BRAVERY: 0.3, p.GREED: 0.3, p.VIOLENCE: 0.1, p.INDUSTRY: 0.75, p.LAZINESS: 0.2, p.SOCIABILITY: 0.7, p.CURIOSITY: 0.6, p.JEALOUSY: 0.3, p.COMPASSION: 0.65, p.PRIDE: 0.7, p.ANGER: 0.2, p.FEAR: 0.4, p.HONESTY: 0.8, p.CRUELTY: 0.0, p.FORGIVENESS: 0.85, p.PLAYFULNESS: 0.3, p.POLITENESS: 0.8, p.AMBITION: 0.4, p.STUBBORNNESS: 0.4, p.PATIENCE: 0.95, p.VANITY: 0.4 },
			"stats": { "strength": 7, "agility": 9, "toughness": 6 },
			"skills": { S.CARPENTRY: 5, S.MASONRY: 2, S.MECHANICS: 3, S.ENGRAVING: 2 },
			"equipment": { "weapon": "Martillo de Madera", "armor": "Delantal de Cuero", "helmet": "", "shield": "" },
			"inventory": ["Sierra de Hierro", "Cincel", "Lija", "Barniz de Pino"],
			"leader": false,
			"thoughts": ["Tall? el trono del rey enano de la Fortaleza Roca?", "Gan? el premio a la mejor silla tallada tres a?os seguidos", "Ense?? carpinter?a a veinte aprendices durante su vida"]
		},
		{
			"name_suffix": "Barbasemilla",
			"gender": "Female", "age": 39,
			"worships": "L?rbin, Dios de la Agricultura",
			"personality": { p.BRAVERY: 0.35, p.GREED: 0.2, p.VIOLENCE: 0.1, p.INDUSTRY: 0.65, p.LAZINESS: 0.2, p.SOCIABILITY: 0.6, p.CURIOSITY: 0.5, p.JEALOUSY: 0.2, p.COMPASSION: 0.9, p.PRIDE: 0.5, p.ANGER: 0.2, p.FEAR: 0.4, p.HONESTY: 0.85, p.CRUELTY: 0.0, p.FORGIVENESS: 0.9, p.PLAYFULNESS: 0.4, p.POLITENESS: 0.85, p.AMBITION: 0.3, p.STUBBORNNESS: 0.5, p.PATIENCE: 0.95, p.VANITY: 0.1 },
			"stats": { "strength": 8, "agility": 6, "toughness": 8 },
			"skills": { S.FARMING: 5, S.BREWING: 3, S.COOKING: 2, S.WOODCUTTING: 1 },
			"equipment": { "weapon": "Azada de Hierro", "armor": "Sombrero de Paja", "helmet": "", "shield": "" },
			"inventory": ["Semillas de Plump Helmet", "Semillas de Plump Helmet", "Semillas de Sweet Pod", "Regadera de Cobre"],
			"leader": false,
			"thoughts": ["Hizo florecer un jard?n en las profundidades m?s oscuras", "Desarroll? una variedad de Plump Helmet de crecimiento r?pido", "Aliment? a toda una fortaleza durante una hambruna con su cosecha"]
		},
		{
			"name_suffix": "Cazuelas",
			"gender": "Female", "age": 31,
			"worships": "V?nsh?n, Dios del Fuego y el H?bitat",
			"personality": { p.BRAVERY: 0.3, p.GREED: 0.2, p.VIOLENCE: 0.1, p.INDUSTRY: 0.7, p.LAZINESS: 0.2, p.SOCIABILITY: 0.9, p.CURIOSITY: 0.6, p.JEALOUSY: 0.1, p.COMPASSION: 0.75, p.PRIDE: 0.65, p.ANGER: 0.2, p.FEAR: 0.3, p.HONESTY: 0.7, p.CRUELTY: 0.0, p.FORGIVENESS: 0.8, p.PLAYFULNESS: 0.85, p.POLITENESS: 0.7, p.AMBITION: 0.5, p.STUBBORNNESS: 0.3, p.PATIENCE: 0.6, p.VANITY: 0.5 },
			"stats": { "strength": 6, "agility": 7, "toughness": 6 },
			"skills": { S.COOKING: 5, S.BREWING: 3, S.ORGANIZING: 2, S.MUSIC: 1 },
			"equipment": { "weapon": "Cuchillo de Hierro", "armor": "Delantal Ign?", "helmet": "Gorro de Cocinero", "shield": "" },
			"inventory": ["Olla de Cobre", "Sart?n", "Especias Varias", "Sal", "Harina de Trigo", "Mantequilla"],
			"leader": false,
			"thoughts": ["Gan? el concurso de estofado en la Gran Fiesta de la Cerveza", "Invent? una receta secreta de pastel de Plump Helmet", "Cocin? para el rey y recibi? una cuchara de oro como recompensa"]
		},
		{
			"name_suffix": "Manosalud",
			"gender": "Male", "age": 45,
			"worships": "Shor?n, Dios de la Curaci?n",
			"personality": { p.BRAVERY: 0.6, p.GREED: 0.1, p.VIOLENCE: 0.0, p.INDUSTRY: 0.6, p.LAZINESS: 0.2, p.SOCIABILITY: 0.6, p.CURIOSITY: 0.7, p.JEALOUSY: 0.1, p.COMPASSION: 1.0, p.PRIDE: 0.5, p.ANGER: 0.1, p.FEAR: 0.55, p.HONESTY: 0.95, p.CRUELTY: 0.0, p.FORGIVENESS: 0.9, p.PLAYFULNESS: 0.2, p.POLITENESS: 0.9, p.AMBITION: 0.3, p.STUBBORNNESS: 0.6, p.PATIENCE: 0.85, p.VANITY: 0.1 },
			"stats": { "strength": 5, "agility": 9, "toughness": 5 },
			"skills": { S.DIAGNOSE: 4, S.DRESSING_WOUNDS: 4, S.SURGERY: 3, S.BONE_SETTING: 3, S.ANATOMY: 3, S.ALCHEMY: 2 },
			"equipment": { "weapon": "Bistur? de Hierro", "armor": "T?nica Blanca", "helmet": "", "shield": "" },
			"inventory": ["Vendas de Lino", "Vendas de Lino", "Vendas de Lino", "Vendas de Lino", "Vendas de Lino", "Hilo de Sutura", "Hilo de Sutura", "Hilo de Sutura", "Poci?n Curativa", "Alcohol Medicinal"],
			"leader": false,
			"thoughts": ["Salv? a veinte enanos de una plaga de fiebre roja", "Perfeccion? la t?cnica de sutura con hilo de seda de ara?a", "Escribi? un tratado de anatom?a enana que usan los aprendices"]
		}
	]
	var profile = profiles[idx] if idx < profiles.size() else profiles[0]
	
	# Personalidad
	for trait_key in profile["personality"]:
		dwarf.personality[trait_key] = profile["personality"][trait_key]
	
	# Atributos f?sicos
	dwarf.strength = profile["stats"]["strength"]
	dwarf.agility = profile["stats"]["agility"]
	dwarf.toughness = profile["stats"]["toughness"]
	
	# G?nero y edad
	dwarf.gender = profile["gender"]
	dwarf.age = profile["age"]
	dwarf.worships = profile["worships"]
	
	# Habilidades
	for skill_key in profile["skills"]:
		dwarf.skills[skill_key] = profile["skills"][skill_key]
	if not quick_start:
		dwarf.skills[S.MINING] = max(dwarf.skills.get(S.MINING, 0), embark_custom_skills["MINING"])
		dwarf.skills[S.CARPENTRY] = max(dwarf.skills.get(S.CARPENTRY, 0), embark_custom_skills["CARPENTRY"])
		dwarf.skills[S.MASONRY] = max(dwarf.skills.get(S.MASONRY, 0), embark_custom_skills["MASONRY"])
		dwarf.skills[S.SMITHING] = max(dwarf.skills.get(S.SMITHING, 0), embark_custom_skills["SMITHING"])
		dwarf.skills[S.FARMING] = max(dwarf.skills.get(S.FARMING, 0), embark_custom_skills["FARMING"])
		dwarf.skills[S.WOODCUTTING] = max(dwarf.skills.get(S.WOODCUTTING, 0), embark_custom_skills["WOODCUTTING"])
		dwarf.skills[S.BREWING] = max(dwarf.skills.get(S.BREWING, 0), embark_custom_skills["BREWING"])
	else:
		for s in [S.MINING, S.CARPENTRY, S.MASONRY, S.FARMING]:
			dwarf.skills[s] = max(dwarf.skills.get(s, 0), 2)
	
	# La profesión histórica aleatoria se corrige según las habilidades reales del perfil.
	dwarf._update_profession()

	# Equipamiento
	var eq = profile["equipment"]
	if not eq["weapon"].is_empty():
		dwarf.equipped_weapon = eq["weapon"]
	if not eq["armor"].is_empty():
		dwarf.equipped_armor = eq["armor"]
	if not eq["helmet"].is_empty():
		dwarf.equipped_helmet = eq["helmet"]
	if not eq["shield"].is_empty():
		dwarf.equipped_shield = eq["shield"]
		dwarf.has_shield = true
	
	# Inventario personal
	for item_name in profile["inventory"]:
		var item_type = "food" if "Semilla" in item_name else "tool"
		var glyph = "." if "Semilla" in item_name else "'"
		var color = Color("#00FF88") if "Semilla" in item_name else Color("#CCBB88")
		if "Bistur?" in item_name or "Cuchillo" in item_name or "Hacha" in item_name or "Martillo" in item_name or "Sierra" in item_name or "Azada" in item_name or "Sart" in item_name or "Olla" in item_name:
			item_type = "weapon"
			glyph = "/"
			color = Color("#888888")
		elif "Venda" in item_name or "Hilo" in item_name or "Alcohol" in item_name or "Poci" in item_name:
			item_type = "medicine"
			glyph = "!"
			color = Color("#FFFFFF")
		elif "Capa" in item_name:
			item_type = "armor"
			glyph = "]"
			color = Color("#8B6914")
		var prof_item = DFItem.new(dwarf.tile_pos, item_name, item_type, 0, glyph, color)
		prof_item.carried_by_id = dwarf.id
		dwarf.inventory.append(prof_item)
	
	# Comida y bebida base (usar _give_embark_inventory para mantener variedad)
	var food_names = ["Plump Helmet", "Sweet Pod", "Cave Mushroom", "Prepared Meal", "Pig Tail", "Quarry Bush"]
	var drink_names = ["Dwarven Ale", "Cave Wine", "Plump Helmet Wine", "Sweet Pod Rum", "Mushroom Brew"]
	for fi in range(2):
		var fi_item = DFItem.new(dwarf.tile_pos, food_names[(idx * 2 + fi) % food_names.size()], "food", 0, "%", Color("#FF8844"))
		fi_item.nutrition = 0.6
		fi_item.is_edible = true
		fi_item.carried_by_id = dwarf.id
		dwarf.inventory.append(fi_item)
	for di in range(2):
		var di_item = DFItem.new(dwarf.tile_pos, drink_names[(idx * 2 + di) % drink_names.size()], "drink", 0, "~", Color("#FFCC00"))
		di_item.hydration = 0.5
		di_item.is_drink = true
		di_item.carried_by_id = dwarf.id
		dwarf.inventory.append(di_item)
	
	# L?der de la expedici?n
	if profile.get("leader", false):
		dwarf.appointed_position = "Capit?n de Expedici?n"
		dwarf.is_noble = true
		dwarf.noble_rank = 1
		dwarf.add_thought("Es el Capit?n de esta expedici?n. Todos conf?an en su liderazgo.", 0.1)
	
	# A?adir pensamientos de historia personal
	for thought_text in profile.get("thoughts", []):
		dwarf.add_thought(thought_text, 0.05)

func _regenerate_world() -> void:
	add_message("=== REGENERANDO MUNDO... ===")
	generation_seed = randi()
	gen_step = 0
	gen_year = 0
	_game_year = 1
	_game_day = 1
	_game_hour = 6
	_game_minute = 0
	_game_season = "Spring"
	_simulation_tick_clock = 0
	_absolute_simulation_tick = 0
	caravan_system = null
	_current_cycle_follow_index = 0
	current_state = GameState.GENERATING_WORLD
	add_message("Nueva semilla: %d" % generation_seed)

var _current_cycle_follow_index: int = 0

func _cycle_follow() -> void:
	if world == null:
		return
	var dwarves = []
	for e in world.entities:
		if e.get("creature_type") == "dwarf" and e.get("is_alive") != false:
			dwarves.append(e)
	if dwarves.is_empty():
		add_message("No hay enanos vivos para seguir.")
		return
	_current_cycle_follow_index = (_current_cycle_follow_index + 1) % dwarves.size()
	var target = dwarves[_current_cycle_follow_index]
	if target.has_method("get_id") or target.get("id") != null:
		var tid = target.id if target.get("id") != null else target.get_instance_id()
		renderer.follow_dwarf = tid
		camera_pos = target.tile_pos
		add_message("Siguiendo a %s (%d/%d)" % [target.name, _current_cycle_follow_index + 1, dwarves.size()])
	_exit_possession()

func _fix_surface(pos: Vector3i) -> Vector3i:
	if world != null:
		var h = world.get_surface_height(pos.x, pos.z)
		return Vector3i(pos.x, h, pos.z)
	return pos

func _has_open_adjacent_tile(world_ref, pos: Vector3i) -> bool:
	var dirs = [
		Vector3i(1, 0, 0),
		Vector3i(-1, 0, 0),
		Vector3i(0, 0, 1),
		Vector3i(0, 0, -1)
	]
	for d in dirs:
		var check = pos + d
		if check.x >= 0 and check.x < world_ref.width and check.z >= 0 and check.z < world_ref.depth:
			if not world_ref.is_blocked(check) and not world_ref.is_water(check):
				return true
	return false

func _populate_creatures_local() -> void:
	var data = DFData.new(generation_seed)
	DFWorld._init_plants_from_data()
	var creature_templates = data.creatures
	if creature_templates.is_empty():
		creature_templates = [{"name": "Fox", "tile": "f", "color": "#FF8800", "biomes": ["grassland", "temperate_forest", "taiga", "savanna"], "size": "small"}]
	
	_biome_creature_index.clear()
	for ct in creature_templates:
		for biome in ct.get("biomes", []):
			if not _biome_creature_index.has(biome):
				_biome_creature_index[biome] = []
			_biome_creature_index[biome].append(ct)
	
	var rng_local = RandomNumberGenerator.new()
	rng_local.seed = generation_seed + 9999
	
	for z in range(world.depth):
		for x in range(world.width):
			if rng_local.randf() > 0.015: continue
			var wx = int(float(x) / float(world.width) * world_gen.world_width)
			var wz = int(float(z) / float(world.depth) * world_gen.world_depth)
			if wx >= world_gen.biome_map[0].size() or wz >= world_gen.biome_map.size(): continue
			var creature_biome = world_gen.biome_map[wz][wx]
			var possible = _biome_creature_index.get(creature_biome, [])
			if possible.is_empty(): continue
			var chosen = possible[rng_local.randi() % possible.size()]
			var h = world.get_surface_height(x, z)
			if h < 1 or h > 8: continue
			var pos = Vector3i(x, h, z)
			if world.is_water(pos) or world.is_blocked(pos): continue
			var creature = DFCreature.new(pos, str(chosen.get("id", chosen["name"])).to_lower(), chosen.get("tile", chosen.get("glyph", "c")), Color(chosen.get("color", "#FFFFFF")), chosen.get("size", "medium"), chosen)
			world.entities.append(creature)

func _process(delta: float) -> void:
	if renderer == null:
		return
	if current_state == GameState.LOADING_PLAYING:
		if not _loading_in_progress:
			_run_loading_playing_loop(load_play_now)
		renderer.queue_redraw()
		return
	if current_state == GameState.GENERATING_WORLD:
		if not _world_gen_in_progress:
			_run_world_generation_loop()
		renderer.queue_redraw()
		return
	if current_state in [GameState.SETTINGS_MENU, GameState.MODE_SELECT, GameState.EMBARK_MAP_SELECT, GameState.EMBARK_PREPARE]:
		if current_state == GameState.EMBARK_MAP_SELECT:
			embark_flash_timer += delta
		renderer.queue_redraw()
		return
	if world == null:
		if legends_mode and legends != null:
			renderer._legend_text = legends.get_current_text()
			renderer._legend_page = legends.get_page_info()
			renderer._legend_mode = legends.current_mode
			if legends.current_mode == DFLegends.ViewMode.FIGURE_DETAIL:
				renderer._family_tree_data = legends.get_figure_detail_data(legends.selected_figure_id)
			else:
				renderer._family_tree_data = {}
			renderer.queue_redraw()
		return

	renderer.game_hour = _game_hour
	renderer.game_day = _game_day
	renderer.game_season = _game_season
	renderer.game_year = _game_year
	renderer._tick_count = _game_minute

	if world.has_method("get_weather_name"):
		renderer._weather_name = str(world.call("get_weather_name"))
	else:
		renderer._weather_name = "Despejado"
	if world.has_method("get_weather_color"):
		var weather_color: Variant = world.call("get_weather_color")
		renderer._weather_color = weather_color if weather_color is Color else Color.WHITE
	else:
		renderer._weather_color = Color.WHITE

	var temperature_value: Variant = world.get("ambient_temperature")
	renderer._temperature = float(temperature_value) if temperature_value != null else 20.0
	var season_value: Variant = world.get("current_season")
	if season_value != null:
		renderer._season_name = DFWorld.SEASON_NAMES.get(season_value, "Desconocida")
	else:
		renderer._season_name = _game_season
	var wind_value: Variant = world.get("wind_strength")
	renderer._wind_strength = float(wind_value) if wind_value != null else 0.0
	var daytime_value: Variant = world.get("is_daytime")
	renderer._is_daytime = bool(daytime_value) if daytime_value != null else true

	if world_gen != null:
		renderer._world_curse = world_gen.world_curse
		renderer._world_curse_desc = world_gen.world_curse_description
		var ht = renderer._highlighted_tile
		if ht.x >= 0:
			var wx = int(float(ht.x) / float(world.width) * world_gen.world_width)
			var wz = int(float(ht.z) / float(world.depth) * world_gen.world_depth)
			if wx >= 0 and wx < world_gen.world_width and wz >= 0 and wz < world_gen.world_depth:
				if world_gen.biome_map.size() > wz and world_gen.biome_map[wz].size() > wx:
					renderer._biome_at_cursor = world_gen.biome_map[wz][wx]
				if world_gen.aquifer_map.size() > wz and world_gen.aquifer_map[wz].size() > wx:
					renderer._aquifer_at_cursor = world_gen.aquifer_map[wz][wx]
				if world_gen.magma_map.size() > wz and world_gen.magma_map[wz].size() > wx:
					renderer._magma_at_cursor = world_gen.magma_map[wz][wx]
				var td: Dictionary = world.get_tile_data(ht)
				renderer._layer_at_cursor = td.get("layer", "")
			else:
				renderer._biome_at_cursor = ""
				renderer._layer_at_cursor = ""
				renderer._aquifer_at_cursor = false
				renderer._magma_at_cursor = false

	if designation != null:
		renderer._designation_mode_name = designation.get_mode_name()
		renderer._designation_mode_color = designation.get_mode_color()
		renderer._job_pending = designation.get_pending_count()
		renderer._job_active = designation.get_active_count()

	# El mundo debe continuar aunque el jugador posea o siga a un enano.
	if not paused:
		_time_accum += minf(delta, 0.1)
		while _time_accum >= tick_interval:
			_time_accum -= tick_interval
			_tick()

	# F solo sigue con la cámara. La posesión se inicia únicamente con P.
	follow_time = 0.0

	if current_state == GameState.PLAYING and not paused:
		_process_held_movement(delta)

	if possessed_dwarf != null:
		camera_pos = possessed_dwarf.tile_pos
	elif renderer.follow_dwarf >= 0:
		_follow_dwarf_camera()

	if legends_mode and legends != null:
		renderer._legend_text = legends.get_current_text()
		renderer._legend_page = legends.get_page_info()
		renderer._legend_mode = legends.current_mode
		if legends.current_mode == DFLegends.ViewMode.FIGURE_DETAIL:
			renderer._family_tree_data = legends.get_figure_detail_data(legends.selected_figure_id)
		else:
			renderer._family_tree_data = {}
	else:
		renderer._legend_text = ""
		renderer._legend_mode = 0
		renderer._family_tree_data = {}

	renderer.camera_pos = camera_pos
	if dialogue != null:
		renderer._dialogue_active = dialogue.is_active()
		renderer._dialogue_state = dialogue.state
		renderer._dialogue_topics = dialogue.topics
		renderer._dialogue_topic_selected = dialogue.topic_selected
		renderer._dialogue_response = dialogue.response_text
		renderer._dialogue_greeting = dialogue.get_greeting() if dialogue.is_active() else ""
		renderer._dialogue_target_name = str(_safe_get(dialogue.target_entity, "name", ""))
	if quest_system != null:
		renderer._quest_log_open = quest_system.is_open()
		renderer._quest_active_quests = quest_system.active_quests.duplicate()
		renderer._quest_completed_count = quest_system.get_completed_count()
		renderer._quest_active_count = quest_system.get_active_count()
		renderer._quest_notification = quest_system.get_current_notification()
		renderer._quest_selected = quest_system.quest_log_selected
	if fast_travel != null:
		renderer._fast_travel_active = fast_travel.active
		renderer._fast_travel_phase = fast_travel.phase
		renderer._fast_travel_distance = fast_travel.travel_distance
		renderer._fast_travel_progress = fast_travel.travel_progress
		renderer._fast_travel_current_message = fast_travel.current_message
		var dti = fast_travel.get_destination_tile_info()
		renderer._fast_travel_biome = dti.get("biome", "")
		renderer._fast_travel_dest_x = fast_travel.destination_x
		renderer._fast_travel_dest_z = fast_travel.destination_z
	# El renderer controla su propia frecuencia de refresco. Redibujar aquí y
	# también en DFRenderer._process duplicaba el trabajo gráfico de cada frame.
	if current_state == GameState.PLAYING and renderer != null:
		if fast_travel != null and fast_travel.phase == DFFastTravel.TravelPhase.TRAVELING:
			fast_travel.tick_travel(delta)
		renderer.tick_tutorial(delta)

func _format_region_count(region_count: int) -> String:
	if region_count >= 1000000:
		return "%.2f millones de" % (float(region_count) / 1000000.0)
	if region_count >= 1000:
		return "%.1f mil" % (float(region_count) / 1000.0)
	return str(region_count)

func _run_world_generation_loop() -> void:
	if _world_gen_in_progress:
		return
	_world_gen_in_progress = true
	
	add_message("  Iniciando generación del terreno...")
	load_status = "Iniciando generación del terreno..."
	load_progress = 0.05
	# Permite que Godot renderice la pantalla de carga limpia antes de la CPU pesada
	await get_tree().process_frame
	await get_tree().process_frame
	
	world_gen = DFWorldGen.new(generation_seed)
	var sizes: Array = [128, 256, 512, 1024]
	var selected_size: int = clampi(setting_size, 0, sizes.size() - 1)
	world_gen.world_width = int(sizes[selected_size])
	world_gen.world_depth = int(sizes[selected_size])
	world_gen.setting_civ_density = setting_civ_density
	world_gen.setting_beast_density = setting_beast_density
	var local_size: int = world_gen.config_local_map_size
	world = DFWorld.new(local_size, local_size, 16)
	load_status = "Generando %s regiones globales, clima e hidrología..." % _format_region_count(world_gen.world_width * world_gen.world_depth)
	load_progress = 0.08
	await get_tree().process_frame
	var generation_thread := Thread.new()
	var generation_callable: Callable = Callable(world_gen, "generate").bind(null, generation_seed, false)
	var thread_error: Error = generation_thread.start(generation_callable)
	if thread_error == OK:
		while generation_thread.is_alive():
			# No es un porcentaje exacto: mantiene visible que la generación nativa
			# continúa sin congelar la ventana durante el millón de regiones.
			load_progress = 0.08 + sin(float(Time.get_ticks_msec()) * 0.002) * 0.01
			await get_tree().process_frame
		generation_thread.wait_to_finish()
	else:
		world_gen.generate(null, generation_seed, false)
	world_name = world_gen.world_name
	if renderer != null:
		renderer.invalidate_world_minimap_cache()
	
	load_status = "Estableciendo cimientos de civilizaciones..."
	load_progress = 0.15
	await get_tree().process_frame
	
	history_gen = DFWorldHistory.new(generation_seed)
	history_gen._setup_initial_world(world_gen)
	history_gen._generate_religions()
	gen_max_years = setting_history_options[setting_history_idx]
	gen_year = 0
	gen_historical_figures = history_gen.historical_figures.size()
	gen_active_sites = history_gen.sites.size()
	gen_active_wars = history_gen.active_wars.size()
	gen_relics_created = history_gen.artifacts.size()
	gen_beasts_alive = history_gen.get_alive_megabeast_count()
	gen_current_age = history_gen.get_current_age_label()
	load_status = "Simulando %d años de historia abstracta..." % gen_max_years
	load_progress = 0.18
	
	while gen_year < gen_max_years:
		# Permitir detener por ENTER pulsado durante simulación
		if Input.is_key_pressed(KEY_ENTER):
			add_message("Simulación interrumpida por el usuario.")
			break
			
		gen_year += 1
		history_gen._simulate_year(gen_year, world_gen)
		load_progress = 0.18 + (float(gen_year) / maxf(1.0, float(gen_max_years))) * 0.70
		load_status = "Año %d de %d — %s" % [gen_year, gen_max_years, history_gen.get_current_age_label()]
		gen_historical_figures = history_gen.historical_figures.size()
		gen_active_sites = history_gen.sites.size()
		gen_active_wars = history_gen.active_wars.size()
		gen_relics_created = history_gen.artifacts.size()
		
		gen_beasts_alive = history_gen.get_alive_megabeast_count()
		gen_current_age = history_gen.get_current_age_label()
			
		gen_rolling_events = []
		var total_evs = history_gen.chronicle.events.size()
		var start_ev = max(0, total_evs - 8)
		for j in range(start_ev, total_evs):
			var hist_ev = history_gen.chronicle.events[j]
			gen_rolling_events.append("[%d]: %s" % [hist_ev.get("year", 0), hist_ev.get("text", "")])
			
		# Ceder control al motor para actualizar la pantalla sin bloquearse
		await get_tree().process_frame
		
	world_gen.civs = history_gen.civs
	world_gen.sites = history_gen.sites
	load_status = "Trazando caminos, ciudades y ruinas..."
	load_progress = 0.92
	await get_tree().process_frame
	world_gen.rebuild_civilized_world()
	load_progress = 1.0
	load_status = "Mundo gigante generado: %d sitios y %d civilizaciones." % [world_gen.sites.size(), world_gen.civs.size()]
	if renderer != null:
		renderer.invalidate_world_minimap_cache()
	world_history = []
	for chron_ev in history_gen.chronicle.events:
		world_history.append(chron_ev.get("text", "Event"))
		
	lore = DFLore.new(generation_seed, world_name)
	legends = DFLegends.new(generation_seed, world_name)
	legends.load_from_history(world_gen, history_gen)
	embark_cursor = Vector2i(world_gen.world_width / 2, world_gen.world_depth / 2)
	
	if has_meta("quick_start_pending") and get_meta("quick_start_pending") == true:
		remove_meta("quick_start_pending")
		_finalize_embark_and_land(true)
	else:
		current_state = GameState.MODE_SELECT
		
	_world_gen_in_progress = false

func _tick() -> void:
	if world == null:
		return
	var minute_ticked = false
	var dwarves_count = 0
	var mil_strength = 0.0
	var _fortress_wealth_calc = 0.0

	_absolute_simulation_tick += 1
	world.set_meta("simulation_tick_total", _absolute_simulation_tick)
	_simulation_tick_clock += 1
	if _simulation_tick_clock >= 25:
		_simulation_tick_clock = 0
		minute_ticked = true
		_game_minute += 1
		if _game_minute >= 60:
			_game_minute = 0
			_game_hour += 1
			if _game_hour >= 24:
				_game_hour = 0
				_game_day += 1
				if _game_day > 28:
					_game_day = 1
					var si = SEASON_LIST.find(_game_season)
					_game_season = SEASON_LIST[(si + 1) % 4]
					_game_year += 1

	if minute_ticked:
		for e in world.entities:
			var is_dwarf = e.get("creature_type") == "dwarf"
			if is_dwarf and e.get("is_alive") == true:
				dwarves_count += 1
				mil_strength += e.combat_skill
				_fortress_wealth_calc += 10.0
			elif e is DFItem:
				_fortress_wealth_calc += 1.0

	if minute_ticked:
		_maintain_autonomous_economy()

	if world.invasion_system != null and minute_ticked and _game_minute % 10 == 0:
		world.invasion_system.check_invasion(_game_minute, _game_season, dwarves_count, mil_strength)
		var inv_result = world.invasion_system.tick(world, world.entities, [])
		for enemy_data in inv_result.get("new_enemies", []):
			if not (enemy_data is Dictionary) or enemy_data.is_empty():
				continue
			var enemy = DFCreature.new(
				enemy_data.get("tile_pos", Vector3i.ZERO),
				str(enemy_data.get("name", "Invasor")),
				str(enemy_data.get("display_char", "?")),
				enemy_data.get("display_color", Color.RED),
				str(enemy_data.get("size", "medium"))
			)
			enemy.is_hostile = true
			enemy.set_meta("is_invader", true)
			enemy.set_meta("invasion_type", enemy_data.get("invasion_type", -1))
			enemy.set_meta("damage", enemy_data.get("damage", 1))
			enemy.set_meta("armor", enemy_data.get("armor", 0))
			world.entities.append(enemy)
		if inv_result["notification"] != "" and _game_minute % 60 == 0:
			add_message(inv_result["notification"])
		if inv_result["ended"]:
			if inv_result["victory"]:
				add_message("Invasion derrotada! La fortaleza sobrevive.")
			else:
				add_message("La invasion ha terminado.")

	if world.combat_system != null and _simulation_tick_clock % 3 == 0:
		for e3 in world.entities:
			var is_hostile = e3.get("is_hostile") == true
			if is_hostile and e3.get("is_alive") == true:
				var nearest_dwarf = null
				var nearest_dist = 20.0
				for e3b in world.entities:
					var is_dwarf3 = e3b.get("creature_type") == "dwarf"
					if is_dwarf3 and e3b.get("is_alive") == true:
						var d = abs(e3.tile_pos.x - e3b.tile_pos.x) + abs(e3.tile_pos.z - e3b.tile_pos.z)
						if d < nearest_dist:
							nearest_dist = d
							nearest_dwarf = e3b
				if nearest_dwarf != null and nearest_dist <= 2:
					var combat_result = world.combat_system.creature_attack(e3, nearest_dwarf)
					if combat_result["fatal"]:
						add_message("%s ha muerto!" % nearest_dwarf.name)
					elif combat_result["hit"]:
						add_message("%s hirio a %s" % [e3.name, nearest_dwarf.name])
				if nearest_dwarf != null and nearest_dist > 1 and randi() % 3 == 0:
					var dx = sign(nearest_dwarf.tile_pos.x - e3.tile_pos.x)
					var dz = sign(nearest_dwarf.tile_pos.z - e3.tile_pos.z)
					var new_pos = Vector3i(e3.tile_pos.x + dx, e3.tile_pos.y, e3.tile_pos.z + dz)
					if not world.is_blocked(new_pos) and not world.is_water(new_pos):
						e3.tile_pos = new_pos
				# Dwarf counter-attack: dwarves fight back against nearby hostiles
				if nearest_dwarf != null and nearest_dist <= 2 and randi() % 2 == 0:
					var dwarf_result = world.combat_system.creature_attack(nearest_dwarf, e3)
					if dwarf_result["fatal"]:
						add_message("%s ha matado a %s!" % [nearest_dwarf.name, e3.name])
						e3.is_alive = false
						# Spawn corpse item
						var corpse_name = "Cuerpo de " + e3.name
						var corpse_item = DFItem.new(e3.tile_pos, corpse_name, "corpse", 0, "%", Color("#884422"))
						corpse_item.nutrition = 0.8
						world.entities.append(corpse_item)
						if quest_system != null:
							var creature_name = e3.get("name")
							if creature_name != null:
								quest_system.report_kill(creature_name.to_lower())
							quest_system.report_explore(e3.tile_pos)
					elif dwarf_result["hit"]:
						add_message("%s hirio a %s" % [nearest_dwarf.name, e3.name])

	if _simulation_tick_clock % 5 == 0:
		for workshop_value: Variant in world.workshops:
			if not (workshop_value is DFWorkshop):
				continue
			var workshop: DFWorkshop = workshop_value
			# Recuperar automáticamente talleres cuyo operador murió, fue poseído,
			# entró en crisis o dejó de reconocer este taller como su proyecto activo.
			if workshop.dwarf_assigned >= 0 and not _workshop_assignment_is_valid(world, workshop):
				workshop.unassign_dwarf()
			if workshop.dwarf_assigned < 0 or workshop.production_queue.is_empty():
				continue
			var active_recipe_value: Variant = workshop.production_queue[0]
			if not (active_recipe_value is Dictionary):
				workshop.production_queue.pop_front()
				continue
			var active_recipe: Dictionary = active_recipe_value
			# La producción solo avanza con el operador presente y todos los insumos
			# entregados físicamente al taller.
			if not _workshop_operator_is_present(world, workshop):
				continue
			if not _workshop_has_recipe_inputs(world, workshop, active_recipe):
				continue
			var workshop_result: Dictionary = workshop.tick(1.0)
			if workshop_result.get("completed", false):
				var recipe: Dictionary = workshop_result.get("recipe", {})
				var quality_bonus: int = int(recipe.get("quality_bonus", 0))
				var quality_level: int = clampi(quality_bonus / 15, 0, 4)
				_consume_recipe_inputs(world, workshop, recipe)
				add_message("Taller completo: %s" % recipe.get("name", "Producto"))
				for output_value: Variant in recipe.get("outputs", []):
					if not (output_value is Dictionary):
						continue
					var output: Dictionary = output_value
					for _output_index: int in range(int(output.get("count", 1))):
						var output_name: String = str(output.get("name", "Item"))
						var output_type: String = str(output.get("type", "item"))
						var spawned: DFItem = world._spawn_item(workshop.tile_pos, output_name, output_type, 0, "*", workshop.get_display_color())
						if spawned != null:
							spawned.set_quality(quality_level)
							if "cama" in output_name.to_lower():
								spawned.is_bed = true

	if minute_ticked and _game_minute == 0 and _game_hour == 6 and _game_day == 1 and randi() % 3 == 0:
		var events_pool = [
			"Los enanos trabajan en las profundidades de %s." % world_name,
			"El viento susurra secretos entre los muros de la fortaleza.",
			"Se siente una presencia antigua en las cavernas profundas.",
			"Los ecos de los Cuarenta y Ocho resuenan en la memoria de la piedra.",
			"Un cuervo observa desde lo alto. Trae noticias de tierras lejanas.",
			"Las estrellas se alinean de forma extrana esta noche.",
		]
		var evt = events_pool[randi() % events_pool.size()]
		_chronicle_events_game.append(evt)
		if _chronicle_events_game.size() > 50:
			_chronicle_events_game.pop_front()

	for e4 in world.entities:
		if e4.get("is_alive") == false:
			continue
			
		# Follower AI: move towards possessed dwarf
		if e4.has_meta("is_follower") and e4.get_meta("is_follower") == true and possessed_dwarf != null:
			var target_pos = possessed_dwarf.tile_pos
			var dist_x = target_pos.x - e4.tile_pos.x
			var dist_z = target_pos.z - e4.tile_pos.z
			if abs(dist_x) > 1 or abs(dist_z) > 1:
				var move_x = signi(dist_x)
				var move_z = signi(dist_z)
				var new_follower_pos = e4.tile_pos + Vector3i(move_x, 0, move_z)
				if not world.is_blocked(new_follower_pos):
					e4.tile_pos = _fix_surface(new_follower_pos)
		
		var is_dwarf4: bool = e4.get("creature_type") == "dwarf"
		var is_settlement_resident: bool = e4 is DFDwarf and bool(e4.get("is_world_settlement_resident"))
		if is_dwarf4:
			# La existencia de la metadata no implica que el enano sea seguidor.
			# Antes, is_follower=false también vaciaba su cola de trabajos.
			var is_active_follower: bool = e4.has_meta("is_follower") and e4.get_meta("is_follower") == true
			var available_jobs: Array = [] if is_active_follower else (designation.job_queue if designation != null else [])
			e4.tick(world, available_jobs, minute_ticked)
			if e4.get("is_resting_medical") == true and designation != null:
				var has_medical_job = false
				for job_item in designation.job_queue:
					if job_item.job_type == DFJob.JobType.TEND_WOUNDS and job_item.has_meta("patient_id") and job_item.get_meta("patient_id") == e4.get_instance_id():
						has_medical_job = true
						break
				if not has_medical_job:
					var med_job = DFJob.new(DFJob.JobType.TEND_WOUNDS, e4.tile_pos)
					med_job.set_meta("patient_id", e4.get_instance_id())
					designation.job_queue.append(med_job)
					add_message("¡Trabajo de primeros auxilios creado para %s!" % e4.name)
			if e4.needs_display_update and designation != null:
				var job = e4.current_job
				if job != null and job.state == DFJob.JobState.COMPLETED:
					add_message("%s: %s completado" % [e4.name, job.get_description().to_lower()])

		elif is_settlement_resident:
			# Simulación temporal distribuida: cada residente ejecuta la misma IA y conserva
			# inventario, necesidades, emociones, relaciones, rutas y profesión aunque no
			# esté en cámara. Solo se reparten sus actualizaciones entre cuatro ticks.
			var resident_phase: int = posmod(int(e4.get("id")), SETTLEMENT_RESIDENT_TICK_BUCKETS)
			if minute_ticked or posmod(_absolute_simulation_tick, SETTLEMENT_RESIDENT_TICK_BUCKETS) == resident_phase:
				e4.tick(world, [], minute_ticked)

		# Capture strange mood messages from dwarf
		if is_dwarf4 and e4.get("mood") == DFDwarf.MoodState.STRANGE_MOOD and e4.get("strange_mood_phase") == DFDwarf.StrangeMoodPhase.SEEKING_WORKSHOP:
			if e4.get("strange_mood_workshop_pos") == Vector3i(-1, -1, -1):
				var mood_names = {0: "Poseído", 1: "Féerico", 2: "Macabro", 3: "Siniestro", 4: "Secreto"}
				var mt = int(_safe_get(e4, "strange_mood_type", 0))
				var mn = mood_names.get(mt, "Extraño")
				if _game_minute % 30 == 0:
					add_message("  [ %s ] %s busca desesperadamente un taller..." % [mn, e4.name])

	# --- APAGADO DE FOGATAS DE FORMA SISTÉMICA ---
	var campfires_to_remove = []
	for b in world.buildings:
		if b.type == 19: # 19 = BuildingType.CAMPFIRE
			var fuel = b.get_meta("fuel_ticks") if b.has_meta("fuel_ticks") else 40
			fuel -= 1
			if fuel <= 0:
				campfires_to_remove.append(b)
				# Dejar cenizas en el suelo
				world._spawn_item(b.tile_pos, "Cenizas de Fogata", "item", 0, "*", Color("#555555"))
			else:
				b.set_meta("fuel_ticks", fuel)
	for cb_bld in campfires_to_remove:
		world.buildings.erase(cb_bld)

	_recover_orphaned_jobs()
	_cleanup_completed_jobs()

	# TICK DE REPRODUCCION: cada minuto de juego
	if minute_ticked:
		for e5 in world.entities:
			var is_dwarf5 = e5.get("creature_type") == "dwarf"
			if is_dwarf5 and e5.get("is_alive") == true and e5.has_method("tick_reproduction"):
				e5.tick_reproduction(world)

	if _simulation_tick_clock % 4 == 0:
		for e6 in world.entities:
			# Los residentes humanos DFDwarf ya fueron procesados de forma ligera y
			# escalonada arriba. Aquí solo entran criaturas ecológicas normales.
			if e6 is DFDwarf:
				continue
			var is_creature6: bool = e6.get("creature_type") != null and e6.get("creature_type") != "dwarf" and e6.get("creature_type") != ""
			if is_creature6 and e6.get("is_alive") == true and e6.has_method("tick"):
				e6.tick(world, minute_ticked or _simulation_tick_clock % 20 == 0)

	if minute_ticked:
		for e_corpse in world.entities:
			if e_corpse.get("creature_type") != null and e_corpse.get("creature_type") != "dwarf" and e_corpse.get("creature_type") != "":
				if e_corpse.get("is_alive") == false and not bool(e_corpse.get_meta("_has_corpse", false)):
					e_corpse.set_meta("_has_corpse", true)
					var corpse_name_1258 = "Cuerpo de " + str(_safe_get(e_corpse, "name", "criatura"))
					var corpse_item_1259 = DFItem.new(e_corpse.tile_pos, corpse_name_1258, "corpse", 0, "%", Color("#884422"))
					corpse_item_1259.nutrition = 0.8
					corpse_item_1259.set_meta("creature_name", str(_safe_get(e_corpse, "name", "")))
					corpse_item_1259.set_meta("creature_size", str(_safe_get(e_corpse, "size_label", "medium")))
					world.entities.append(corpse_item_1259)

	if minute_ticked and _game_minute % 10 == 0:
		for e7 in world.entities:
			if e7 is DFItem and e7.has_method("tick_decay"):
				e7.tick_decay()

	if minute_ticked:
		if world_simulation != null:
			for simulation_message in world_simulation.tick(world, true):
				add_message(simulation_message)
		var season_val = SEASON_ENUM_MAP.get(_game_season, DFWorld.Season.SPRING)
		world.current_season = season_val
		world.game_year = _game_year
		if world.has_method("tick_weather"):
			world.tick_weather()
		if _game_hour == 6 and _game_minute == 0:
			world.is_daytime = true
		elif _game_hour == 18 and _game_minute == 0:
			world.is_daytime = false
		world.day_time = float(_game_hour + _game_minute / 60.0) / 24.0
		if world.has_method("tick_fluids") and _simulation_tick_clock % 10 == 0:
			world.tick_fluids()
		if caravan_system != null:
			var car_events = caravan_system.tick(minute_ticked, _game_minute, _game_hour, _game_day,
				_game_season, dwarves_count, _fortress_wealth_calc, world.width, world.depth, world.entities)
			for caravan_evt in car_events.get("events", []):
				add_message("[CARAVANA] " + caravan_evt)

	if world.invasion_system != null:
		renderer._invasion_status = world.invasion_system.get_invasion_status()
	if world.military_system != null:
		renderer._military_summary = world.military_system.get_military_summary()
	if world.combat_system != null:
		renderer._combat_log = world.combat_system.get_recent_log(3)
	if caravan_system != null:
		renderer._caravan_info = caravan_system.get_caravans_for_sidebar()

	if quest_system != null and minute_ticked:
		quest_system.tick(minute_ticked)

	for msg in world.messages:
		add_message(msg)
	world.messages.clear()

	# Check for historical figure/beast deaths to update chronicle DB
	for e_dead in world.entities:
		if e_dead.get("is_alive") == false:
			if e_dead.has_meta("beast_instance_id"):
				var b_id = e_dead.get_meta("beast_instance_id")
				e_dead.remove_meta("beast_instance_id")
				if history_gen != null:
					var hf_rec = history_gen._get_hf(b_id)
					if hf_rec != null:
						hf_rec.death_year = _game_year
						hf_rec.death_site_id = -2
						hf_rec.notable_deeds.append("Fue derrotada y decapitada por las fuerzas del jugador en el año %d" % _game_year)
						history_gen.chronicle.add_event(_game_year, "BEAST_DEATH", {
							"beast_name": hf_rec.name,
							"killer_name": "los campeones de la fortaleza",
							"site_name": "nuestras tierras"
						})
					for bi in history_gen.beast_instances:
						if bi.get("hf_id") == b_id:
							bi["alive"] = false
							bi["world_x"] = -1
							bi["world_z"] = -1
							break
					add_message("¡LA BESTIA LEGENDARIA '%s' HA CAÍDO! Su muerte se ha inscrito en los anales del tiempo." % e_dead.name)
			elif e_dead.has_meta("historical_figure_id"):
				var hf_id = e_dead.get_meta("historical_figure_id")
				e_dead.remove_meta("historical_figure_id")
				if history_gen != null:
					var dead_hf_rec = history_gen._get_hf(hf_id)
					if dead_hf_rec != null:
						dead_hf_rec.death_year = _game_year
						dead_hf_rec.notable_deeds.append("Murió combatiendo en nuestras tierras en el año %d" % _game_year)
						history_gen.chronicle.add_event(_game_year, "DEATH_BATTLE", {
							"victim_name": dead_hf_rec.name,
							"killer_name": "las defensas del fuerte",
							"battle_site": "las tierras de la fortaleza"
						})
					add_message("¡La figura histórica '%s' ha muerto! Las crónicas recordarán su fin." % e_dead.name)

func _recover_orphaned_jobs() -> void:
	if designation == null or world == null:
		return
	var alive_dwarf_ids: Dictionary = {}
	var active_job_owner_ids: Dictionary = {}
	for world_entry in world.entities:
		if world_entry is DFDwarf:
			var dwarf_entry: DFDwarf = world_entry
			if not dwarf_entry.is_alive:
				continue
			alive_dwarf_ids[dwarf_entry.id] = true
			if dwarf_entry.current_job != null:
				active_job_owner_ids[dwarf_entry.current_job.get_instance_id()] = dwarf_entry.id

	for queued_job in designation.job_queue:
		if queued_job.state not in [DFJob.JobState.ASSIGNED, DFJob.JobState.IN_PROGRESS]:
			continue
		var previous_worker_id: int = queued_job.assigned_dwarf_id
		var active_owner_id: int = int(active_job_owner_ids.get(queued_job.get_instance_id(), -1))
		var worker_is_alive: bool = alive_dwarf_ids.has(previous_worker_id)
		var correct_worker_still_owns_job: bool = active_owner_id == previous_worker_id
		if worker_is_alive and correct_worker_still_owns_job:
			continue

		# Liberar objetos que el trabajo huérfano dejó reservados. Sin esto, el
		# trabajo vuelve a la cola pero nadie puede tomar su material u objetivo.
		for reservation_key in ["target_item_id", "material_item_id"]:
			var reserved_item_id: int = int(queued_job.get_meta(reservation_key, -1))
			if reserved_item_id >= 0:
				for item_entry in world.entities:
					if item_entry is DFItem and item_entry.id == reserved_item_id:
						item_entry.release_reservation(previous_worker_id)
						break
			queued_job.set_meta(reservation_key, -1)
		queued_job.set_meta("carried_item_id", -1)
		queued_job.state = DFJob.JobState.UNASSIGNED
		queued_job.assigned_dwarf_id = -1
		queued_job.cancel_reason = ""

func _cleanup_completed_jobs() -> void:
	if designation == null:
		return
	var to_remove = []
	for j in designation.job_queue:
		if j.state == DFJob.JobState.COMPLETED or j.state == DFJob.JobState.CANCELLED:
			to_remove.append(j)
	for j2 in to_remove:
		designation.job_queue.erase(j2)

func _follow_dwarf_camera() -> void:
	if renderer.follow_dwarf < 0:
		return
	for e in world.entities:
		if e is DFItem:
			continue
		var is_alive = e.get("is_alive")
		if e.get("id") != null and e.id == renderer.follow_dwarf and (is_alive == null or is_alive == true):
			camera_pos = e.tile_pos
			return
	renderer.follow_dwarf = -1

func _possess_dwarf(id: int) -> void:
	for e in world.entities:
		var is_dwarf = e.get("creature_type") == "dwarf"
		var is_alive = e.get("is_alive")
		if is_dwarf and e.id == id and (is_alive == null or is_alive == true):
			possessed_dwarf = e
			last_possessed_dwarf = e
			possessed_dwarf.is_possessed = true
			add_message("! POSESION INICIADA ! (WASD para mover)")
			renderer.follow_dwarf = -1
			return
			
func _exit_possession() -> void:
	if possessed_dwarf != null:
		possessed_dwarf.is_possessed = false
		possessed_dwarf = null
		add_message("Posesion terminada. (L para volver)")
		follow_time = 0.0

func _try_move_possessed(direction: Vector2i) -> bool:
	if possessed_dwarf == null or world == null or direction == Vector2i.ZERO:
		return false
	var current_position: Vector3i = possessed_dwarf.tile_pos
	var next_x: int = current_position.x + direction.x
	var next_z: int = current_position.z + direction.y
	if next_x < 0 or next_x >= world.width or next_z < 0 or next_z >= world.depth:
		return false
	var target_position: Vector3i = _fix_surface(Vector3i(next_x, current_position.y, next_z))
	if world.is_blocked(target_position):
		return false
	possessed_dwarf.tile_pos = target_position
	camera_pos = target_position
	return true

func _get_held_move_direction() -> Vector2i:
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		return Vector2i(0, -1)
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		return Vector2i(0, 1)
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		return Vector2i(-1, 0)
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		return Vector2i(1, 0)
	return Vector2i.ZERO

func _process_held_movement(delta: float) -> void:
	if settings_menu.visible or world == null:
		_held_move_timer = 0.0
		_held_move_direction = Vector2i.ZERO
		return
	if fast_travel != null and fast_travel.active:
		return
	if dialogue != null and dialogue.is_active():
		return
	if quest_system != null and quest_system.is_open():
		return
	if legends_mode:
		return
	var direction: Vector2i = _get_held_move_direction()
	if direction == Vector2i.ZERO:
		_held_move_timer = 0.0
		_held_move_direction = Vector2i.ZERO
		return
	if direction != _held_move_direction:
		_held_move_direction = direction
		_held_move_timer = HELD_MOVE_INITIAL_DELAY
		return
	_held_move_timer -= delta
	if _held_move_timer > 0.0:
		return
	if possessed_dwarf != null:
		_try_move_possessed(direction)
	else:
		# En modo cámara, mantener WASD desplaza continuamente y deja de seguir.
		renderer.follow_dwarf = -1
		camera_pos.x = clampi(camera_pos.x + direction.x * 2, 0, world.width - 1)
		camera_pos.z = clampi(camera_pos.z + direction.y * 2, 0, world.depth - 1)
	_held_move_timer = HELD_MOVE_REPEAT_INTERVAL

func _handle_escape() -> void:
	# ESC actúa sobre una sola capa, de la más específica a la más general.
	if fast_travel != null and fast_travel.active:
		fast_travel.cancel()
		return
	if quest_system != null and quest_system.is_open():
		quest_system.close_quest_log()
		return
	if dialogue != null and dialogue.is_active():
		dialogue.close_dialogue()
		renderer._dialogue_active = false
		return
	if legends_mode:
		legends_mode = false
		_legends_select_mode = false
		renderer._legend_text = ""
		renderer._legend_mode = 0
		renderer._family_tree_data = {}
		add_message("Crónicas cerradas.")
		return
	if settings_menu.visible:
		_on_settings_close()
		return
	if possessed_dwarf != null:
		_exit_possession()
		return
	if renderer.follow_dwarf >= 0:
		renderer.follow_dwarf = -1
		add_message("Seguimiento terminado.")
		return
	settings_menu.visible = true
	paused = true
	renderer.paused = true

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var kc = event.keycode
		if current_state != GameState.PLAYING:
			_handle_menu_key(kc)
			return
		if kc == KEY_ESCAPE:
			_handle_escape()
			get_viewport().set_input_as_handled()
			return
		if settings_menu.visible:
			return
		_handle_key(event)
	elif event is InputEventMouseButton:
		_handle_mouse(event)

func _handle_menu_key(kc: int) -> void:
	match current_state:
		GameState.SETTINGS_MENU:
			match kc:
				KEY_UP: setting_selected_index = posmod(setting_selected_index - 1, 5)
				KEY_DOWN: setting_selected_index = posmod(setting_selected_index + 1, 5)
				KEY_LEFT, KEY_RIGHT:
					var step = 1 if kc == KEY_RIGHT else -1
					match setting_selected_index:
						0: generation_seed = -1 if generation_seed != -1 else randi()
						1: setting_size = posmod(setting_size + step, 4)
						2: setting_history_idx = posmod(setting_history_idx + step, 5)
						3: setting_civ_density = posmod(setting_civ_density + step, 3)
						4: setting_beast_density = posmod(setting_beast_density + step, 3)
				KEY_R: generation_seed = randi()
				KEY_Q:
					if generation_seed < 0: generation_seed = randi()
					current_state = GameState.GENERATING_WORLD
					gen_step = 0
					set_meta("quick_start_pending", true)
				KEY_ENTER:
					if generation_seed < 0: generation_seed = randi()
					current_state = GameState.GENERATING_WORLD
					gen_step = 0
		GameState.GENERATING_WORLD:
			if kc == KEY_ENTER:
				gen_max_years = gen_year
		GameState.MODE_SELECT:
			match kc:
				KEY_UP, KEY_DOWN: setting_selected_index = posmod(setting_selected_index + (1 if kc == KEY_DOWN else -1), 3)
				KEY_ENTER:
					if setting_selected_index == 0:
						current_state = GameState.EMBARK_MAP_SELECT
						setting_selected_index = 0
						embark_cursor = Vector2i(world_gen.world_width / 2, world_gen.world_depth / 2)
					elif setting_selected_index == 1:
						set_meta("adventure_mode_pending", true)
						add_message("=== MODO AVENTURA: generando expedición... ===")
						_finalize_embark_and_land(true)
					else:
						legends_mode = true
						add_message("=== MODO LEYENDAS: generando mundo... ===")
						_finalize_embark_and_land(true)
						legends.switch_mode(DFLegends.ViewMode.OVERVIEW)
		GameState.EMBARK_MAP_SELECT:
			var world_navigation_step: int = 16 if Input.is_key_pressed(KEY_SHIFT) else 1
			match kc:
				KEY_UP: embark_cursor.y = clampi(embark_cursor.y - world_navigation_step, 0, world_gen.world_depth - 1)
				KEY_DOWN: embark_cursor.y = clampi(embark_cursor.y + world_navigation_step, 0, world_gen.world_depth - 1)
				KEY_LEFT: embark_cursor.x = clampi(embark_cursor.x - world_navigation_step, 0, world_gen.world_width - 1)
				KEY_RIGHT: embark_cursor.x = clampi(embark_cursor.x + world_navigation_step, 0, world_gen.world_width - 1)
				KEY_ESCAPE: current_state = GameState.MODE_SELECT; setting_selected_index = 0
				KEY_ENTER: current_state = GameState.EMBARK_PREPARE; embark_prepare_step = 0; setting_selected_index = 0; embark_prepare_points = 100
		GameState.EMBARK_PREPARE:
			if embark_prepare_step == 0:
				match kc:
					KEY_UP, KEY_DOWN: setting_selected_index = posmod(setting_selected_index + (1 if kc == KEY_DOWN else -1), 2)
					KEY_ESCAPE: current_state = GameState.EMBARK_MAP_SELECT
					KEY_ENTER:
						if setting_selected_index == 0:
							_finalize_embark_and_land(true)
						else:
							embark_prepare_step = 1; setting_selected_index = 0
							for k in embark_custom_skills: embark_custom_skills[k] = 1
							embark_custom_items = {"Plump Helmet Seed": 10, "Plump Helmet": 15, "Dwarven Ale": 15, "Copper Pickaxe": 2, "Copper Woodcutter Axe": 1}
							embark_prepare_points = 100
			elif embark_prepare_step == 1:
				var skill_keys = embark_custom_skills.keys()
				var item_keys = embark_custom_items.keys()
				var total_opts = skill_keys.size() + item_keys.size()
				match kc:
					KEY_UP: setting_selected_index = posmod(setting_selected_index - 1, total_opts)
					KEY_DOWN: setting_selected_index = posmod(setting_selected_index + 1, total_opts)
					KEY_LEFT, KEY_RIGHT:
						var embark_step = 1 if kc == KEY_RIGHT else -1
						if setting_selected_index < skill_keys.size():
							var sname = skill_keys[setting_selected_index]
							var embark_val = embark_custom_skills[sname]
							if embark_step > 0 and embark_prepare_points >= 5 and embark_val < 5:
								embark_custom_skills[sname] = embark_val + 1; embark_prepare_points -= 5
							elif embark_step < 0 and embark_val > 0:
								embark_custom_skills[sname] = embark_val - 1; embark_prepare_points += 5
						else:
							var itname = item_keys[setting_selected_index - skill_keys.size()]
							var item_val = embark_custom_items[itname]
							var cost = 1
							if ("Ale" in itname) or ("Plump Helmet" in itname and not "Seed" in itname): cost = 2
							elif "Pickaxe" in itname or "Axe" in itname: cost = 15
							if embark_step > 0 and embark_prepare_points >= cost:
								embark_custom_items[itname] = item_val + 1; embark_prepare_points -= cost
							elif embark_step < 0 and item_val > 0:
								embark_custom_items[itname] = item_val - 1; embark_prepare_points += cost
					KEY_ESCAPE: embark_prepare_step = 0; setting_selected_index = 0
					KEY_ENTER: _finalize_embark_and_land(false)

func _finalize_embark_and_land(play_now: bool) -> void:
	load_progress = 0.0
	load_status = "Iniciando desembarco..."
	load_step = 0
	load_play_now = play_now
	current_state = GameState.LOADING_PLAYING
	if world == null:
		world = DFWorld.new(256, 256, 16)
	if dialogue != null:
		dialogue.world_ref = world
	if fast_travel != null:
		fast_travel.world_ref = world
	if quest_system != null:
		quest_system.world_ref = world

func _run_loading_playing_loop(play_now: bool) -> void:
	if _loading_in_progress:
		return
	_loading_in_progress = true
	
	current_state = GameState.LOADING_PLAYING
	load_play_now = play_now
	
	if world == null:
		world = DFWorld.new(256, 256, 16)
	if dialogue != null:
		dialogue.world_ref = world
	if fast_travel != null:
		fast_travel.world_ref = world
	if quest_system != null:
		quest_system.world_ref = world
		
	var local_center_surface := Vector3i(128, 3, 128)
	if dialogue == null:
		dialogue = DFDialogue.new(world, self)
		
	# Step 0
	load_status = "Preparando terreno local"
	load_progress = 0.1
	await get_tree().process_frame
	
	# Step 1
	load_status = "Generando relieve, biomas y asentamientos locales"
	await get_tree().process_frame
	# Una región local puede reutilizar el mismo objeto World. Limpiar antes de
	# materializar impide duplicar edificios, residentes y almacenes.
	world.entities.clear()
	world.buildings.clear()
	world.workshops.clear()
	world.stockpiles.clear()
	world.growing_crops.clear()
	world.set_meta("generated_world_sites", [])
	world.set_meta("active_world_region", [embark_cursor.x, embark_cursor.y])
	world_gen.generate_local_map(world, embark_cursor)
	# El centro debe calcularse después de crear el terreno. Antes podía quedar dentro del agua.
	local_center_surface = _find_safe_settlement_center(Vector2i(128, 128))
	settlement_center = local_center_surface
	world.set_meta("settlement_center", settlement_center)
	load_progress = 0.3
	await get_tree().process_frame
	
	# Step 2
	load_status = "Localizando ruinas y asentamientos históricos"
	await get_tree().process_frame
	_generate_historical_settlements()
	load_progress = 0.45
	await get_tree().process_frame
	
	# Step 3
	load_status = "Materializando artefactos y bestias"
	await get_tree().process_frame
	if history_gen != null:
		var spawned = history_gen.materialize_near_embark(world, world_gen, embark_cursor)
		add_message("  *** %d entidades históricas materializadas en el área ***" % spawned)
	
	# Step 4
	load_status = "Simulando historia local: %d años de colonia" % gen_max_years
	await get_tree().process_frame
	# Los habitantes históricos y residentes de aldeas ya fueron materializados.
	# No se borran aquí; los colonos del jugador se agregan a continuación.
	
	# === SIMULACIÓN DEMOGRÁFICA REAL POR AÑOS ===
	var survivors = _simulate_embark_demographics(gen_max_years)
	var num_dwarves = survivors.size()
	
	
	# Buscar enanos históricos vivos que proceden del mundo simulado
	var candidate_hfs = []
	if history_gen != null:
		for hf in history_gen.historical_figures:
			if hf.death_year == -1 and hf.race == "dwarf":
				candidate_hfs.append(hf)
	
	var used_dwarf_ids = []
	var used_spawn_positions: Array = []
	var embark_colonists: Array = []
	for i in range(num_dwarves):
		var surv = survivors[i]
		var dname = surv.name
		var hf_id = -1
		var hf_deeds = []
		var hf_birth = 0
		
		# Si hay un HF histórico para este enano, tomar sus datos
		if i < candidate_hfs.size():
			hf_id = candidate_hfs[i].id
			hf_deeds = candidate_hfs[i].notable_deeds
			hf_birth = candidate_hfs[i].birth_year
		
		# Spawnear en suelo seco alrededor del centro; la cama real se asigna al construir la cabaña.
		var dpos = _find_valid_spawn_spiral(local_center_surface, used_spawn_positions)
		used_spawn_positions.append(dpos)
		var dwarf = DFDwarf.new(dpos, dname)
		dwarf.profession = surv.profession
		dwarf.preferred_bed = Vector3i(-1, -1, -1)
		
		# La herramienta configurada se entrega al inventario después de aplicar el perfil.
		# Antes se generaba una copia en el suelo que nadie reclamaba.
		var weapon_str: String = str(surv.get("equipped_weapon", ""))
		
		# Aplicar prioridades de tareas
		var prio_dict = surv.get("priorities", {})
		for labor_key in prio_dict:
			if dwarf.has_method("set_labor_priority"):
				dwarf.set_labor_priority(labor_key, prio_dict[labor_key])
		
		# Sincronizar datos históricos garantizando ID único
		if hf_id != -1 and not hf_id in used_dwarf_ids:
			dwarf.id = hf_id
			used_dwarf_ids.append(hf_id)
			dwarf.set_meta("historical_figure_id", hf_id)
			var hf_age = gen_max_years - hf_birth
			dwarf.set_meta("age", hf_age)
			for deed in hf_deeds:
				dwarf.add_thought(deed, 0.05)
		else:
			var fallback_id = 1000 + i
			while fallback_id in used_dwarf_ids:
				fallback_id += 1
			dwarf.id = fallback_id
			used_dwarf_ids.append(fallback_id)
		
		# Aplicar perfil único y completar un kit físico real en el inventario.
		_apply_dwarf_profile(dwarf, i, load_play_now)
		_ensure_dwarf_starting_kit(dwarf, i, weapon_str)
		
		world.entities.append(dwarf)
		embark_colonists.append(dwarf)
		
	# Establecer relaciones y amistades iniciales
	for rel_i in range(embark_colonists.size()):
		for rel_j in range(embark_colonists.size()):
			if rel_i != rel_j:
				var other_id: int = embark_colonists[rel_j].id
				embark_colonists[rel_i].relationships[other_id] = 60 + (randi() % 40)
				if not other_id in embark_colonists[rel_i].friends:
					embark_colonists[rel_i].friends.append(other_id)
				
	load_progress = 0.7
	await get_tree().process_frame
	
	# Step 5
	load_status = "Descargando equipamiento del carro"
	await get_tree().process_frame
	var items_to_spawn = {}
	if load_play_now:
		items_to_spawn = {"Plump Helmet Seed": 15, "Plump Helmet": 20, "Dwarven Ale": 25, "Copper Pickaxe": 2, "Copper Woodcutter Axe": 1}
	else:
		items_to_spawn = embark_custom_items
	var embark_dwarves: Array = []
	for embark_entity in world.entities:
		if embark_entity is DFDwarf and embark_entity.is_alive and not embark_entity.is_world_settlement_resident:
			embark_dwarves.append(embark_entity)
	for it_name in items_to_spawn:
		var qty: int = int(items_to_spawn[it_name])
		var itype: String = "food" if "Helmet" in it_name and not "Seed" in it_name else "drink" if "Ale" in it_name else "seed" if "Seed" in it_name else "weapon"
		var glyph: String = "%" if itype == "food" else "~" if itype == "drink" else "." if itype == "seed" else "/" if it_name == "Copper Woodcutter Axe" else "p"
		var color: Color = Color("#FF8844") if itype == "food" else Color("#FFCC00") if itype == "drink" else Color("#00FF88") if itype == "seed" else Color("#88CCFF")
		for q in range(qty):
			var rx: int = local_center_surface.x + (randi() % 5) - 2
			var rz: int = local_center_surface.z + (randi() % 5) - 2
			var ipos: Vector3i = _fix_surface(Vector3i(rx, local_center_surface.y, rz))
			var embark_item: DFItem = DFItem.new(ipos, str(it_name), itype, 0, glyph, color)
			if not _try_distribute_initial_item(embark_item, embark_dwarves):
				world.entities.append(embark_item)
	load_progress = 0.85
	await get_tree().process_frame
	
	# Step 6
	load_status = "Poblando fauna y flora indómita"
	await get_tree().process_frame
	_populate_creatures_local()
	camera_pos = local_center_surface
	load_progress = 0.95
	await get_tree().process_frame
	
	# Step 7
	load_status = "Fundando asentamiento inicial"
	await get_tree().process_frame
	designation = DFDesignation.new(world)
	_build_initial_settlement(local_center_surface)
	_auto_designate_initial_jobs(local_center_surface)
	var simulation_database = load("res://df_mode/resources/world_database.tres")
	world_simulation = DFWorldSimulationScript.new(simulation_database)
	world_simulation.initialize(world)
	renderer.set_world(world)
	renderer.designation = designation
	renderer.game_year = gen_max_years
	caravan_system = DFCaravan.new(generation_seed)
	paused = false
	renderer.paused = false
	current_state = GameState.PLAYING
	renderer.show_sidebar = true
	var audio = get_node("DFAudio") as DFAudio
	if audio != null:
		audio.play_music("main_theme")
		var gx = int(float(settlement_center.x) / float(world.width) * world_gen.world_width)
		var gz = int(float(settlement_center.z) / float(world.depth) * world_gen.world_depth)
		var biome = "grassland"
		if world_gen.biome_map.size() > gz and world_gen.biome_map[gz].size() > gx:
			biome = world_gen.biome_map[gz][gx]
		audio.play_ambient(biome)
		
	if has_meta("adventure_mode_pending") and get_meta("adventure_mode_pending") == true:
		remove_meta("adventure_mode_pending")
		for ent in world.entities:
			if ent.get("creature_type") == "dwarf" and ent.get("is_alive") == true:
				_possess_dwarf(ent.id)
				break
		add_message("========================================")
		add_message("  *** MODO AVENTURA (ROGUELIKE) INICIADO! ***")
		add_message("  Controlas a tu héroe con WASD / Flechas.")
		add_message("  T: Hablar con NPCs  |  V: Viaje Rápido  |  Q: Salir")
		add_message("========================================")
	else:
		var alive_count = 0
		for ent in world.entities:
			if ent.get("creature_type") == "dwarf" and ent.get("is_alive") != false:
				alive_count += 1
		add_message("========================================")
		add_message("  NUEVO EMBARQUE EN %s!" % world_name.to_upper())
		add_message("  Colonia: %d supervivientes tras %d años de historia." % [alive_count, gen_max_years])
		add_message("  Presiona ESPACIO para pausar, 1-6 para designar.")
		add_message("========================================")
		
	load_progress = 1.0
	_loading_in_progress = false

func _build_initial_settlement(center: Vector3i) -> void:
	# Construye un asentamiento inicial hermoso con cabañas/dormitorios,
	# parcelas de cultivo, taller de herrería, y almacenes llenos.
	if world == null:
		return
	var rng = RandomNumberGenerator.new()
	rng.seed = generation_seed + 777
	var sy = center.y

	# --- Plaza central abierta (7x7) con soportes en las esquinas ---
	var hx: int = center.x
	var hz: int = center.z
	for dz in range(-3, 4):
		for dx in range(-3, 4):
			var plaza_x: int = hx + dx
			var plaza_z: int = hz + dz
			var plaza_y: int = world.get_surface_height(plaza_x, plaza_z)
			var p := Vector3i(plaza_x, plaza_y, plaza_z)
			if plaza_y != sy or world.is_water(p) or world.is_blocked(p):
				continue
			var is_corner = (abs(dx) == 3 and abs(dz) == 3)
			var is_edge_mid = ((abs(dx) == 3 and abs(dz) == 0) or (abs(dz) == 3 and abs(dx) == 0))
			if is_corner:
				world.set_tile(p, DFWorld.TileType.CONSTRUCTED_WALL)
				world.set_material(p, DFWorld.MatType.WOOD)
			elif is_edge_mid or (abs(dx) <= 2 and abs(dz) <= 2):
				world.set_tile(p, DFWorld.TileType.CONSTRUCTED_FLOOR)
				world.set_material(p, DFWorld.MatType.WOOD)
			else:
				world.set_tile(p, DFWorld.TileType.PATH)
				world.set_material(p, DFWorld.MatType.SOIL)
	
	# Camino de entrada/salida en los 4 puntos cardinales
	var exits = [Vector2i(0, -4), Vector2i(0, 4), Vector2i(-4, 0), Vector2i(4, 0)]
	for ex in exits:
		var exit_x: int = hx + ex.x
		var exit_z: int = hz + ex.y
		var exit_y: int = world.get_surface_height(exit_x, exit_z)
		var ep := Vector3i(exit_x, exit_y, exit_z)
		if exit_y == sy and not world.is_water(ep) and not world.is_blocked(ep):
			world.set_tile(ep, DFWorld.TileType.PATH)
			world.set_material(ep, DFWorld.MatType.SOIL)

	# --- Habitaciones Privadas (Generadas dinámicamente en espiral según la población) ---
	# Determinar cuántas cabañas construir basado en la cantidad de entidades activas (enanos)
	var alive_dwarf_count = 0
	for ent in world.entities:
		if ent.get("creature_type") == "dwarf" and ent.get("is_alive") != false:
			alive_dwarf_count += 1
	var cabin_count = maxi(7, alive_dwarf_count)
	var cabin_offsets = _get_spiral_offsets(cabin_count)
	var settlement_dwarves: Array = []
	for resident in world.entities:
		if resident.get("creature_type") == "dwarf" and resident.get("is_alive") != false:
			settlement_dwarves.append(resident)
	var used_house_origins: Array = []
	
	for i in range(cabin_count):
		var offset = cabin_offsets[i] if i < cabin_offsets.size() else Vector2i(0, 0)
		var desired_bpos = Vector3i(hx + offset.x, sy, hz + offset.y)
		var template = HOUSE_TEMPLATES[i % HOUSE_TEMPLATES.size()]
		var bpos = _find_safe_house_origin(desired_bpos, template, used_house_origins)
		if bpos.x < 0:
			continue
		used_house_origins.append(bpos)
		
		# 1. Construir Suelos
		for fl in template.floors:
			var wp = bpos + Vector3i(fl.x, 0, fl.y)
			if wp.x < 1 or wp.x >= world.width - 1 or wp.z < 1 or wp.z >= world.depth - 1: continue
			world.set_tile(wp, DFWorld.TileType.CONSTRUCTED_FLOOR)
			world.set_material(wp, DFWorld.MatType.WOOD)
			
		# 2. Generar Muros inteligentes en el contorno
		var wall_neighbors = [
			Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
			Vector2i(-1, 0),                   Vector2i(1, 0),
			Vector2i(-1, 1),  Vector2i(0, 1),  Vector2i(1, 1)
		]
		for fl2 in template.floors:
			for n in wall_neighbors:
				var check_fl = fl2 + n
				if not check_fl in template.floors:
					var wp2 = bpos + Vector3i(check_fl.x, 0, check_fl.y)
					if wp2.x < 1 or wp2.x >= world.width - 1 or wp2.z < 1 or wp2.z >= world.depth - 1: continue
					
					if check_fl != template.door:
						world.set_tile(wp2, DFWorld.TileType.CONSTRUCTED_WALL)
						world.set_material(wp2, DFWorld.MatType.WOOD)
					else:
						# La puerta se deja libre como suelo
						world.set_tile(wp2, DFWorld.TileType.CONSTRUCTED_FLOOR)
						world.set_material(wp2, DFWorld.MatType.WOOD)
						
		# 3. Registrar Edificio de Dormitorio y colocar Cama
		var bed_offset_pos = bpos + Vector3i(template.bed.x, 0, template.bed.y)
		var bed = DFBuilding.new(DFBuilding.BuildingType.BEDROOM, bed_offset_pos)
		world.buildings.append(bed)
		
		var bed_item = world._spawn_item(bed_offset_pos, "Cama de Madera", "furniture", 0, "b", Color("#8B6914"))
		if bed_item != null:
			bed_item.is_bed = true
		if i < settlement_dwarves.size():
			var resident = settlement_dwarves[i]
			resident.preferred_bed = bed_offset_pos
			if world.is_water(resident.tile_pos) or world.is_blocked(resident.tile_pos):
				resident.tile_pos = bed_offset_pos
			
		var door_offset_pos = bpos + Vector3i(template.door.x, 0, template.door.y)
		world._spawn_item(door_offset_pos, "Puerta de Madera", "door", 0, "p", Color("#8B5A2B"))

	# --- Parcelas de cultivo (3 parcelas de 4x4 alrededor de la plaza) ---
	# Cada casilla usa su altura real; una parcela nunca reemplaza agua ni queda flotando.
	var farm_offsets = [Vector2i(-10, -5), Vector2i(7, -5), Vector2i(-5, 9)]
	for fo in farm_offsets:
		for farm_dz in range(4):
			for farm_dx in range(4):
				var farm_x: int = hx + fo.x + farm_dx
				var farm_z: int = hz + fo.y + farm_dz
				if farm_x < 2 or farm_x >= world.width - 2 or farm_z < 2 or farm_z >= world.depth - 2:
					continue
				var farm_y: int = world.get_surface_height(farm_x, farm_z)
				var farm_fp := Vector3i(farm_x, farm_y, farm_z)
				if world.is_water(farm_fp) or world.is_blocked(farm_fp) or abs(farm_y - sy) > 1:
					continue
				world.set_tile(farm_fp, DFWorld.TileType.FARM_SOIL)
				world.set_material(farm_fp, DFWorld.MatType.SOIL)
				world.tile_data[farm_fp] = world.tile_data.get(farm_fp, {})
				world.tile_data[farm_fp]["farm_quality"] = 1.0

	# Plantillas compactas para colocar servicios completos únicamente en suelo seco y plano.
	var utility_floors: Array = []
	for utility_z in range(-1, 2):
		for utility_x in range(-1, 2):
			utility_floors.append(Vector2i(utility_x, utility_z))
	var utility_template := {"floors": utility_floors, "door": Vector2i(0, -2), "bed": Vector2i.ZERO}

	# --- Taller de herrería (3x3) abierto ---
	var ws_pos := _find_safe_house_origin(Vector3i(hx - 8, sy, hz + 6), utility_template, used_house_origins)
	if ws_pos.x >= 0:
		used_house_origins.append(ws_pos)
		for ws_dz in range(-1, 2):
			for ws_dx in range(-1, 2):
				var ws_wp := Vector3i(ws_pos.x + ws_dx, ws_pos.y, ws_pos.z + ws_dz)
				world.set_tile(ws_wp, DFWorld.TileType.CONSTRUCTED_FLOOR)
				world.set_material(ws_wp, DFWorld.MatType.STONE)

	# --- Gran almacén físico: 20x20 interiores, paredes, suelo y estanterías ---
	var warehouse_built: bool = _build_large_initial_warehouse(Vector3i(hx, sy, hz), rng)
	if not warehouse_built:
		add_message("ADVERTENCIA: no se encontró una zona plana para el almacén 20x20.")

	# --- Templo religioso completo (3x3), también validado como una sola pieza ---
	var temple_pos := _find_safe_house_origin(Vector3i(hx, sy, hz + 12), utility_template, used_house_origins)
	if temple_pos.x >= 0:
		used_house_origins.append(temple_pos)
		for temple_dz in range(-1, 2):
			for temple_dx in range(-1, 2):
				var temple_tile := Vector3i(temple_pos.x + temple_dx, temple_pos.y, temple_pos.z + temple_dz)
				var is_temple_wall: bool = abs(temple_dx) == 1 or abs(temple_dz) == 1
				var is_temple_door := temple_dx == 0 and temple_dz == -1
				if is_temple_wall and not is_temple_door:
					world.set_tile(temple_tile, DFWorld.TileType.CONSTRUCTED_WALL)
				else:
					world.set_tile(temple_tile, DFWorld.TileType.CONSTRUCTED_FLOOR)
				world.set_material(temple_tile, DFWorld.MatType.STONE)
		var temple_building := DFBuilding.new(DFBuilding.BuildingType.TEMPLE, temple_pos)
		world.buildings.append(temple_building)

	add_message("  Asentamiento inicial construido (cabañas, granjas, taller, almacenes llenos y templo).")

func _warehouse_area_is_clear(center_pos: Vector3i) -> bool:
	# 22x22 exteriores: 20x20 interiores y un muro perimetral.
	for local_z: int in range(-11, 11):
		for local_x: int in range(-11, 11):
			var world_x: int = center_pos.x + local_x
			var world_z: int = center_pos.z + local_z
			if world_x < 2 or world_x >= world.width - 2 or world_z < 2 or world_z >= world.depth - 2:
				return false
			var surface_y: int = world.get_surface_height(world_x, world_z)
			if surface_y != center_pos.y:
				return false
			var world_pos: Vector3i = Vector3i(world_x, surface_y, world_z)
			if world.is_water(world_pos):
				return false
			var tile_type: int = world.get_tile(world_pos)
			if tile_type in [
				DFWorld.TileType.WALL,
				DFWorld.TileType.CAVE_WALL,
				DFWorld.TileType.MAGMA,
				DFWorld.TileType.CONSTRUCTED_WALL,
				DFWorld.TileType.CONSTRUCTED_FLOOR,
				DFWorld.TileType.FARM_SOIL,
				DFWorld.TileType.PATH
			]:
				return false
	return true

func _warehouse_door_data(center_pos: Vector3i, settlement_pos: Vector3i) -> Dictionary:
	var delta_x: int = settlement_pos.x - center_pos.x
	var delta_z: int = settlement_pos.z - center_pos.z
	var doors: Array[Vector2i] = []
	var approach: Vector2i = Vector2i.ZERO
	if abs(delta_x) > abs(delta_z):
		if delta_x < 0:
			doors.append(Vector2i(-11, -1))
			doors.append(Vector2i(-11, 0))
			approach = Vector2i(-12, 0)
		else:
			doors.append(Vector2i(10, -1))
			doors.append(Vector2i(10, 0))
			approach = Vector2i(11, 0)
	else:
		if delta_z < 0:
			doors.append(Vector2i(-1, -11))
			doors.append(Vector2i(0, -11))
			approach = Vector2i(0, -12)
		else:
			doors.append(Vector2i(-1, 10))
			doors.append(Vector2i(0, 10))
			approach = Vector2i(0, 11)
	return {"doors": doors, "approach": approach}

func _warehouse_has_land_access(center_pos: Vector3i, settlement_pos: Vector3i) -> bool:
	var door_data: Dictionary = _warehouse_door_data(center_pos, settlement_pos)
	var approach_value: Variant = door_data.get("approach", Vector2i.ZERO)
	if not (approach_value is Vector2i):
		return false
	var approach_offset: Vector2i = approach_value
	var approach_x: int = center_pos.x + approach_offset.x
	var approach_z: int = center_pos.z + approach_offset.y
	if approach_x < 2 or approach_x >= world.width - 2 or approach_z < 2 or approach_z >= world.depth - 2:
		return false
	var approach_y: int = world.get_surface_height(approach_x, approach_z)
	if approach_y != center_pos.y:
		return false
	var approach_pos: Vector3i = Vector3i(approach_x, approach_y, approach_z)
	if world.is_water(approach_pos) or world.is_blocked(approach_pos) or not world.is_floor(approach_pos):
		return false

	var route: Array = world.find_path(settlement_pos, approach_pos, true)
	if route.is_empty():
		return false

	# La ruta externa no puede atravesar el futuro edificio, porque sus muros
	# cortarían el camino después de terminar la generación.
	for step_value: Variant in route:
		var step: Vector3i = step_value
		var inside_future_footprint: bool = (
			step.x >= center_pos.x - 11 and step.x <= center_pos.x + 10
			and step.z >= center_pos.z - 11 and step.z <= center_pos.z + 10
		)
		if inside_future_footprint:
			return false
	return true

func _build_warehouse_access_road(settlement_pos: Vector3i, warehouse_center: Vector3i) -> void:
	var door_data: Dictionary = _warehouse_door_data(warehouse_center, settlement_pos)
	var approach_value: Variant = door_data.get("approach", Vector2i.ZERO)
	if not (approach_value is Vector2i):
		return
	var approach_offset: Vector2i = approach_value
	var approach_pos: Vector3i = warehouse_center + Vector3i(
		approach_offset.x, 0, approach_offset.y
	)
	var route: Array = world.find_path(settlement_pos, approach_pos, true)
	for step_value: Variant in route:
		var step: Vector3i = step_value
		if world.is_water(step) or world.is_wall(step):
			continue
		var current_tile: int = world.get_tile(step)
		if current_tile in [DFWorld.TileType.CONSTRUCTED_FLOOR, DFWorld.TileType.FARM_SOIL]:
			continue
		world.set_tile(step, DFWorld.TileType.PATH)
		world.set_material(step, DFWorld.MatType.SOIL)

func _find_large_warehouse_center(settlement_pos: Vector3i) -> Vector3i:
	var preferred_offsets: Array[Vector2i] = [
		Vector2i(30, 0), Vector2i(-30, 0), Vector2i(0, 30), Vector2i(0, -30),
		Vector2i(24, 24), Vector2i(-24, 24), Vector2i(24, -24), Vector2i(-24, -24)
	]
	for preferred_offset: Vector2i in preferred_offsets:
		var preferred_x: int = settlement_pos.x + preferred_offset.x
		var preferred_z: int = settlement_pos.z + preferred_offset.y
		for radius: int in range(0, 61, 2):
			for offset_z: int in range(-radius, radius + 1, 2):
				for offset_x: int in range(-radius, radius + 1, 2):
					if radius > 0 and abs(offset_x) != radius and abs(offset_z) != radius:
						continue
					var candidate_x: int = preferred_x + offset_x
					var candidate_z: int = preferred_z + offset_z
					if candidate_x < 13 or candidate_x >= world.width - 13 or candidate_z < 13 or candidate_z >= world.depth - 13:
						continue
					var candidate_y: int = world.get_surface_height(candidate_x, candidate_z)
					var candidate: Vector3i = Vector3i(candidate_x, candidate_y, candidate_z)
					if _warehouse_area_is_clear(candidate) and _warehouse_has_land_access(candidate, settlement_pos):
						return candidate
	return Vector3i(-1, -1, -1)

func _build_large_initial_warehouse(settlement_pos: Vector3i, _rng: RandomNumberGenerator) -> bool:
	var warehouse_center: Vector3i = _find_large_warehouse_center(settlement_pos)
	if warehouse_center.x < 0:
		return false

	var door_data: Dictionary = _warehouse_door_data(warehouse_center, settlement_pos)
	var door_offsets: Array = door_data.get("doors", [])
	var stockpile_tiles: Array = []
	var shelf_tiles: Array = []
	for local_z: int in range(-11, 11):
		for local_x: int in range(-11, 11):
			var tile_position: Vector3i = warehouse_center + Vector3i(local_x, 0, local_z)
			var perimeter: bool = local_x == -11 or local_x == 10 or local_z == -11 or local_z == 10
			var doorway: bool = door_offsets.has(Vector2i(local_x, local_z))
			if perimeter and not doorway:
				world.set_tile(tile_position, DFWorld.TileType.CONSTRUCTED_WALL)
				world.set_material(tile_position, DFWorld.MatType.STONE)
			else:
				world.set_tile(tile_position, DFWorld.TileType.CONSTRUCTED_FLOOR)
				world.set_material(tile_position, DFWorld.MatType.WOOD)
				if not perimeter:
					stockpile_tiles.append(tile_position)

	# Dos puertas anchas orientadas hacia la colonia para evitar almacenes
	# visualmente correctos pero separados por agua o muros.
	for door_offset_value: Variant in door_offsets:
		if not (door_offset_value is Vector2i):
			continue
		var door_offset: Vector2i = door_offset_value
		var door_position: Vector3i = warehouse_center + Vector3i(
			door_offset.x, 0, door_offset.y
		)
		world._spawn_item(door_position, "Puerta del Gran Almacén", "door", 0, "p", Color("#A06A3A"))

	# Estanterías en filas con pasillos de dos casillas. Son edificios visibles y
	# también puntos preferentes para apilar comida y bebida.
	for shelf_z: int in range(-8, 9, 4):
		for shelf_x: int in range(-8, 9, 2):
			if shelf_x in [-1, 0, 1]:
				continue
			var shelf_position: Vector3i = warehouse_center + Vector3i(shelf_x, 0, shelf_z)
			var shelf: DFBuilding = DFBuilding.new(DFBuilding.BuildingType.FOOD_STORE, shelf_position)
			world.buildings.append(shelf)
			shelf_tiles.append(shelf_position)

	var stockpile: DFStockpile = DFStockpile.new(stockpile_tiles)
	stockpile.accepts_categories = [
		"food", "drink", "meat", "fish", "seed", "plant",
		"wood", "stone", "ore", "bar", "cloth", "thread",
		"tool", "weapon", "armor", "item"
	]
	stockpile.display_color = Color(0.55, 0.42, 0.12, 0.12)
	world.stockpiles.append(stockpile)
	var warehouse_building: DFBuilding = DFBuilding.new(DFBuilding.BuildingType.STOCKPILE, warehouse_center)
	warehouse_building.size = Vector3i(20, 0, 20)
	world.buildings.append(warehouse_building)
	world.set_meta("warehouse_center", warehouse_center)
	world.set_meta("warehouse_interior_size", Vector2i(20, 20))
	if not door_offsets.is_empty():
		var first_door_value: Variant = door_offsets[0]
		if first_door_value is Vector2i:
			var first_door_offset: Vector2i = first_door_value
			world.set_meta(
				"warehouse_door_position",
				warehouse_center + Vector3i(first_door_offset.x, 0, first_door_offset.y)
			)
	_build_warehouse_access_road(settlement_pos, warehouse_center)

	var resource_definitions: Array = [
		["Tronco de Madera", "wood", "═", Color("#8B5A2B")],
		["Bloque de Piedra", "stone", "*", Color("#888888")],
		["Lingote de Cobre", "bar", "-", Color("#D2691E")],
		["Semillas de Plump Helmet", "seed", ".", Color("#00FF88")],
		["Provisiones", "food", "%", Color("#FF8844")],
		["Dwarven Ale", "drink", "~", Color("#FFCC00")]
	]
	var resource_tiles: Array = shelf_tiles if not shelf_tiles.is_empty() else stockpile_tiles
	var initial_resources: int = mini(36, resource_tiles.size())
	for resource_index: int in range(initial_resources):
		var resource_data: Array = resource_definitions[resource_index % resource_definitions.size()]
		var resource_position: Vector3i = resource_tiles[resource_index]
		var resource_color_value: Variant = resource_data[3]
		var resource_color: Color = resource_color_value if resource_color_value is Color else Color.WHITE
		var spawned_item: DFItem = world._spawn_item(
			resource_position,
			str(resource_data[0]),
			str(resource_data[1]),
			0,
			str(resource_data[2]),
			resource_color
		)
		if spawned_item != null:
			spawned_item.is_in_stockpile = true
			if str(resource_data[1]) in ["food", "drink"]:
				spawned_item.is_inside_container = true

	add_message("Gran almacén construido: 20x20 interiores, muros, dos puertas y %d estanterías." % shelf_tiles.size())
	return true

func _find_safe_settlement_center(preferred: Vector2i) -> Vector3i:
	if world == null:
		return Vector3i(preferred.x, 3, preferred.y)
	var best := Vector3i(-1, -1, -1)
	var best_score := 999999999.0
	for radius in range(0, 81, 3):
		for dz in range(-radius, radius + 1, 3):
			for dx in range(-radius, radius + 1, 3):
				if radius > 0 and abs(dx) != radius and abs(dz) != radius:
					continue
				var x: int = clampi(preferred.x + dx, 18, world.width - 19)
				var z: int = clampi(preferred.y + dz, 18, world.depth - 19)
				var y: int = world.get_surface_height(x, z)
				var center_pos := Vector3i(x, y, z)
				if world.is_water(center_pos) or world.is_blocked(center_pos):
					continue
				var water_count := 0
				var blocked_count := 0
				var height_error := 0
				for sz in range(-12, 13, 3):
					for sx in range(-12, 13, 3):
						var px: int = x + sx
						var pz: int = z + sz
						var py: int = world.get_surface_height(px, pz)
						var check := Vector3i(px, py, pz)
						if world.is_water(check):
							water_count += 1
						elif world.is_blocked(check):
							blocked_count += 1
						height_error += abs(py - y)
				var score := float(water_count * 500 + blocked_count * 20 + height_error * 18 + abs(dx) + abs(dz))
				if score < best_score:
					best_score = score
					best = center_pos
				if water_count == 0 and blocked_count == 0 and height_error <= 4:
					return center_pos
	return best if best.x >= 0 else _fix_surface(Vector3i(preferred.x, 3, preferred.y))

func _house_footprint_positions(origin: Vector3i, template: Dictionary) -> Array:
	var positions: Array = []
	for floor_offset_value: Variant in template.floors:
		var floor_offset: Vector2i = floor_offset_value
		positions.append(origin + Vector3i(floor_offset.x, 0, floor_offset.y))
	var neighbors: Array[Vector2i] = [Vector2i(-1,-1), Vector2i(0,-1), Vector2i(1,-1), Vector2i(-1,0), Vector2i(1,0), Vector2i(-1,1), Vector2i(0,1), Vector2i(1,1)]
	for wall_source_offset_value: Variant in template.floors:
		var wall_source_offset: Vector2i = wall_source_offset_value
		for neighbor_offset: Vector2i in neighbors:
			var edge: Vector2i = wall_source_offset + neighbor_offset
			if edge not in template.floors:
				var footprint_position: Vector3i = origin + Vector3i(edge.x, 0, edge.y)
				if footprint_position not in positions:
					positions.append(footprint_position)
	return positions

func _is_valid_house_origin(origin: Vector3i, template: Dictionary, used_origins: Array) -> bool:
	for previous in used_origins:
		if abs(previous.x - origin.x) + abs(previous.z - origin.z) < 7:
			return false
	for p in _house_footprint_positions(origin, template):
		if p.x < 2 or p.x >= world.width - 2 or p.z < 2 or p.z >= world.depth - 2:
			return false
		var surface_y: int = world.get_surface_height(p.x, p.z)
		var surface_pos := Vector3i(p.x, surface_y, p.z)
		if surface_y != origin.y or world.is_water(surface_pos):
			return false
	return true

func _find_safe_house_origin(desired: Vector3i, template: Dictionary, used_origins: Array) -> Vector3i:
	for radius in range(0, 15):
		for dz in range(-radius, radius + 1):
			for dx in range(-radius, radius + 1):
				if radius > 0 and abs(dx) != radius and abs(dz) != radius:
					continue
				var x: int = clampi(desired.x + dx, 3, world.width - 4)
				var z: int = clampi(desired.z + dz, 3, world.depth - 4)
				var y: int = world.get_surface_height(x, z)
				var candidate := Vector3i(x, y, z)
				if _is_valid_house_origin(candidate, template, used_origins):
					return candidate
	return Vector3i(-1, -1, -1)

func _count_open_jobs(job_type: int) -> int:
	if designation == null:
		return 0
	var count := 0
	for job in designation.job_queue:
		if job.job_type == job_type and job.state in [DFJob.JobState.UNASSIGNED, DFJob.JobState.ASSIGNED, DFJob.JobState.IN_PROGRESS]:
			count += 1
	return count

func _queue_job_once(job_type: int, pos: Vector3i, priority: int) -> bool:
	if designation == null or designation.has_job_at(pos, job_type):
		return false
	var job := DFJob.new(job_type, pos, priority)
	designation.job_queue.append(job)
	return true

func _queue_house_construction_job(job_type: int, pos: Vector3i, priority: int = 7) -> bool:
	if not _queue_job_once(job_type, pos, priority):
		return false
	var job_value: Variant = designation.job_queue.back()
	if job_value is DFJob:
		var house_job: DFJob = job_value
		house_job.set_meta("required_material_type", "plank")
		house_job.set_meta("colony_project", "housing")
	return true

func _find_workshop_by_type(workshop_type: int) -> DFWorkshop:
	if world == null:
		return null
	for workshop_value: Variant in world.workshops:
		if workshop_value is DFWorkshop:
			var workshop: DFWorkshop = workshop_value
			if workshop.workshop_type == workshop_type:
				return workshop
	return null

func _find_pending_workshop_building(building_type: int) -> DFBuilding:
	if world == null:
		return null
	for building_value: Variant in world.buildings:
		if building_value is DFBuilding:
			var building: DFBuilding = building_value
			if building.type == building_type and not building.is_constructed:
				return building
	return null

func _autonomous_workshop_site_is_clear(position: Vector3i) -> bool:
	if world == null:
		return false
	for local_z: int in range(-1, 2):
		for local_x: int in range(-1, 2):
			var tile_position: Vector3i = position + Vector3i(local_x, 0, local_z)
			if tile_position.x < 2 or tile_position.x >= world.width - 2 or tile_position.z < 2 or tile_position.z >= world.depth - 2:
				return false
			if world.get_surface_height(tile_position.x, tile_position.z) != position.y:
				return false
			if world.is_water(tile_position) or world.is_blocked(tile_position):
				return false
			if world.get_tile(tile_position) == DFWorld.TileType.FARM_SOIL:
				return false
			for stockpile_value: Variant in world.stockpiles:
				if stockpile_value.has_tile(tile_position):
					return false
			for building_value: Variant in world.buildings:
				if building_value is DFBuilding and building_value.is_inside(tile_position):
					return false
	return true

func _find_autonomous_workshop_site() -> Vector3i:
	if world == null:
		return Vector3i(-1, -1, -1)
	for radius: int in range(8, 33):
		for local_z: int in range(-radius, radius + 1):
			for local_x: int in range(-radius, radius + 1):
				if abs(local_x) != radius and abs(local_z) != radius:
					continue
				var world_x: int = settlement_center.x + local_x
				var world_z: int = settlement_center.z + local_z
				if world_x < 2 or world_x >= world.width - 2 or world_z < 2 or world_z >= world.depth - 2:
					continue
				var world_y: int = world.get_surface_height(world_x, world_z)
				var candidate: Vector3i = Vector3i(world_x, world_y, world_z)
				if abs(world_y - settlement_center.y) > 1 or not _autonomous_workshop_site_is_clear(candidate):
					continue
				var route: Array = DFPathfinding.find_path(world, settlement_center, candidate, true)
				if not route.is_empty():
					return candidate
	return Vector3i(-1, -1, -1)

func _ensure_carpentry_workshop() -> DFWorkshop:
	var existing: DFWorkshop = _find_workshop_by_type(DFWorkshop.WorkshopType.CARPENTRY)
	if existing != null:
		return existing
	var pending_building: DFBuilding = _find_pending_workshop_building(DFBuilding.BuildingType.CARPENTRY)
	if pending_building != null:
		if designation != null and not designation.has_job_at(pending_building.tile_pos, DFJob.JobType.BUILD_WORKSHOP):
			var continued_job: DFJob = DFJob.new(DFJob.JobType.BUILD_WORKSHOP, pending_building.tile_pos, 9)
			continued_job.result_tile_type = DFBuilding.BuildingType.CARPENTRY
			continued_job.set_meta("required_material_type", "wood")
			continued_job.set_meta("colony_project", "carpentry_chain")
			designation.job_queue.append(continued_job)
		return null
	if designation == null:
		return null
	var workshop_position: Vector3i = _find_autonomous_workshop_site()
	if workshop_position.x < 0:
		return null
	var building: DFBuilding = DFBuilding.new(DFBuilding.BuildingType.CARPENTRY, workshop_position)
	building.is_constructed = false
	world.buildings.append(building)
	var build_job: DFJob = DFJob.new(DFJob.JobType.BUILD_WORKSHOP, workshop_position, 9)
	build_job.result_tile_type = DFBuilding.BuildingType.CARPENTRY
	build_job.set_meta("required_material_type", "wood")
	build_job.set_meta("colony_project", "carpentry_chain")
	designation.job_queue.append(build_job)
	add_message("La colonia inició el proyecto persistente de una carpintería.")
	return null

func _queue_workshop_recipe_once(workshop: DFWorkshop, recipe_id: String) -> bool:
	for queued_value: Variant in workshop.production_queue:
		if queued_value is Dictionary and str(queued_value.get("id", "")) == recipe_id:
			return false
	if workshop.queue_recipe(recipe_id):
		var recipe_name: String = recipe_id.replace("_", " ").capitalize()
		for recipe_value: Variant in workshop.get_recipes():
			if recipe_value is Dictionary and str(recipe_value.get("id", "")) == recipe_id:
				recipe_name = str(recipe_value.get("name", recipe_name))
				break
		add_message("Proyecto de carpintería: %s." % recipe_name)
		return true
	return false

func _count_item_type_everywhere(item_type: String) -> int:
	var count: int = 0
	if world == null:
		return count
	for world_value: Variant in world.entities:
		if world_value is DFItem:
			var item: DFItem = world_value
			if item.item_type == item_type and not item.is_decayed:
				count += maxi(1, item.stack_size)
		elif world_value is DFDwarf:
			var dwarf: DFDwarf = world_value
			for inventory_value: Variant in dwarf.inventory:
				if inventory_value is DFItem:
					var inventory_item: DFItem = inventory_value
					if inventory_item.item_type == item_type and not inventory_item.is_decayed:
						count += maxi(1, inventory_item.stack_size)
	return count

func _count_beds_everywhere() -> int:
	var count: int = 0
	if world == null:
		return count
	for world_value: Variant in world.entities:
		if world_value is DFItem:
			var item: DFItem = world_value
			if item.is_bed or "cama" in item.name.to_lower():
				count += maxi(1, item.stack_size)
		elif world_value is DFDwarf:
			var dwarf: DFDwarf = world_value
			for inventory_value: Variant in dwarf.inventory:
				if inventory_value is DFItem:
					var inventory_item: DFItem = inventory_value
					if inventory_item.is_bed or "cama" in inventory_item.name.to_lower():
						count += maxi(1, inventory_item.stack_size)
	return count

func _count_house_jobs_waiting_for_planks() -> int:
	if designation == null:
		return 0
	var count: int = 0
	for job_value: Variant in designation.job_queue:
		if not (job_value is DFJob):
			continue
		var job: DFJob = job_value
		if job.state not in [DFJob.JobState.UNASSIGNED, DFJob.JobState.ASSIGNED, DFJob.JobState.IN_PROGRESS]:
			continue
		if job.job_type in [DFJob.JobType.BUILD_WALL, DFJob.JobType.BUILD_FLOOR] and str(job.get_meta("required_material_type", "")) == "plank":
			count += 1
	return count

func _maintain_carpentry_chain(alive_dwarves: int, raw_wood_count: int) -> void:
	var carpentry: DFWorkshop = _ensure_carpentry_workshop()
	if carpentry == null:
		return
	# Incluir madera transportada en inventarios. Sin esto, el director podía ver
	# cero madera justo mientras un aldeano la llevaba y dejaba el taller sin cola.
	var available_wood_count: int = maxi(raw_wood_count, _count_item_type_everywhere("wood"))
	var plank_count: int = _count_item_type_everywhere("plank")
	var plank_demand: int = _count_house_jobs_waiting_for_planks()
	var target_planks: int = maxi(12, plank_demand + 6)
	if plank_count < target_planks and available_wood_count > 0:
		_queue_workshop_recipe_once(carpentry, "wood_planks")
	var bed_count: int = _count_beds_everywhere()
	if bed_count < alive_dwarves + 2 and available_wood_count >= 3:
		_queue_workshop_recipe_once(carpentry, "bed")

func _maintain_autonomous_economy() -> void:
	if designation == null or world == null:
		return
	var absolute_minute := ((_game_year * 4 * 28 + SEASON_LIST.find(_game_season) * 28 + _game_day) * 24 + _game_hour) * 60 + _game_minute
	if absolute_minute - _last_autonomy_plan_minute < 2:
		return
	_last_autonomy_plan_minute = absolute_minute
	var center := settlement_center
	var wood_count: int = 0
	var stone_count: int = 0
	var food_count: int = 0
	var drink_count: int = 0
	var alive_dwarves: int = 0
	for entity in world.entities:
		if entity is DFItem:
			var item_amount: int = maxi(1, int(entity.stack_size))
			match entity.item_type:
				"wood": wood_count += item_amount
				"stone": stone_count += item_amount
				"food", "meat", "fish": food_count += item_amount
				"drink": drink_count += item_amount
		elif entity.get("creature_type") == "dwarf" and entity.get("is_alive") == true:
			alive_dwarves += 1

	# Primera cadena económica persistente: madera -> carpintería -> tablas/camas.
	_maintain_carpentry_chain(alive_dwarves, wood_count)

	# Mantener una reserva continua de madera.
	var chop_target := 8 if wood_count < 25 else 3
	var chop_missing := maxi(0, chop_target - _count_open_jobs(DFJob.JobType.CHOP_TREE))
	if chop_missing > 0:
		for tree_radius in range(3, 51):
			for tree_dz in range(-tree_radius, tree_radius + 1):
				for tree_dx in range(-tree_radius, tree_radius + 1):
					if chop_missing <= 0:
						break
					if abs(tree_dx) != tree_radius and abs(tree_dz) != tree_radius:
						continue
					var tree_x: int = center.x + tree_dx
					var tree_z: int = center.z + tree_dz
					if tree_x < 1 or tree_x >= world.width - 1 or tree_z < 1 or tree_z >= world.depth - 1:
						continue
					var tree_y: int = world.get_surface_height(tree_x, tree_z)
					var tree_pos := Vector3i(tree_x, tree_y, tree_z)
					if world.get_tile(tree_pos) == DFWorld.TileType.TREE and _queue_job_once(DFJob.JobType.CHOP_TREE, tree_pos, 8 if wood_count < 12 else 6):
						chop_missing -= 1
				if chop_missing <= 0:
					break
			if chop_missing <= 0:
				break

	# Mantener piedra y abrir espacio de expansión. Solo se excava roca natural.
	var dig_target := 6 if stone_count < 25 else 2
	var dig_missing := maxi(0, dig_target - _count_open_jobs(DFJob.JobType.DIG))
	if dig_missing > 0:
		for dig_radius in range(2, 36):
			for dig_dz in range(-dig_radius, dig_radius + 1):
				for dig_dx in range(-dig_radius, dig_radius + 1):
					if dig_missing <= 0:
						break
					if abs(dig_dx) != dig_radius and abs(dig_dz) != dig_radius:
						continue
					var dig_x := center.x + dig_dx
					var dig_z := center.z + dig_dz
					if dig_x < 2 or dig_x >= world.width - 2 or dig_z < 2 or dig_z >= world.depth - 2:
						continue
					# Excavar en el mismo nivel de la colonia permite llegar a la roca horizontalmente.
					var dig_pos_auto := Vector3i(dig_x, center.y, dig_z)
					var dig_tile: int = world.get_tile(dig_pos_auto)
					if dig_tile in [DFWorld.TileType.WALL, DFWorld.TileType.CAVE_WALL]:
						if _queue_job_once(DFJob.JobType.DIG, dig_pos_auto, 7 if stone_count < 12 else 5):
							dig_missing -= 1
				if dig_missing <= 0:
					break
			if dig_missing <= 0:
				break

	# Plantar automáticamente las parcelas vacías.
	var plant_missing := maxi(0, 10 - _count_open_jobs(DFJob.JobType.FARM_PLANT))
	for farm_scan_z in range(maxi(1, center.z - 30), mini(world.depth - 1, center.z + 31)):
		for farm_scan_x in range(maxi(1, center.x - 30), mini(world.width - 1, center.x + 31)):
			if plant_missing <= 0:
				break
			var farm_scan_y: int = world.get_surface_height(farm_scan_x, farm_scan_z)
			var farm_scan_pos := Vector3i(farm_scan_x, farm_scan_y, farm_scan_z)
			if world.get_tile(farm_scan_pos) == DFWorld.TileType.FARM_SOIL and not world.growing_crops.has(farm_scan_pos):
				if _queue_job_once(DFJob.JobType.FARM_PLANT, farm_scan_pos, 8 if food_count < alive_dwarves * 3 else 5):
					plant_missing -= 1
		if plant_missing <= 0:
			break

	# Recolectar recursos concretos. Cada trabajo apunta a un objeto real; no usa
	# posiciones ficticias cerca de la plaza.
	_queue_resource_collection_jobs("wood", DFJob.JobType.COLLECT_WOOD, 5, 8)
	_queue_resource_collection_jobs("stone", DFJob.JobType.COLLECT_STONE, 5, 8)
	_queue_harvest_jobs(8)
	_queue_colony_production_jobs(alive_dwarves, food_count, drink_count)

	# Caza moderada cuando la reserva alimentaria baja.
	if food_count < alive_dwarves * 3 and _count_open_jobs(DFJob.JobType.HUNT) < 2:
		for prey in world.entities:
			if prey is DFCreature and prey.get("is_alive") == true and prey.get("is_hostile") != true:
				var d: int = abs(prey.tile_pos.x - center.x) + abs(prey.tile_pos.z - center.z)
				if d <= 55 and _queue_job_once(DFJob.JobType.HUNT, prey.tile_pos, 6):
					designation.job_queue.back().set_meta("creature_id", prey.id)
					if _count_open_jobs(DFJob.JobType.HUNT) >= 2:
						break

	_queue_training_jobs(alive_dwarves)
	_finish_autonomous_house_projects()
	if _game_hour == 6 and _game_minute == 0:
		_queue_house_expansion_if_needed(alive_dwarves)

func _job_targets_item(job_type: int, item_id: int) -> bool:
	if designation == null:
		return false
	for queued_job in designation.job_queue:
		if queued_job.job_type != job_type:
			continue
		if queued_job.state not in [DFJob.JobState.UNASSIGNED, DFJob.JobState.ASSIGNED, DFJob.JobState.IN_PROGRESS]:
			continue
		if int(queued_job.get_meta("target_item_id", -1)) == item_id:
			return true
	return false

func _queue_resource_collection_jobs(item_type: String, job_type: int, max_jobs: int, priority: int) -> void:
	if designation == null or world == null:
		return
	var open_jobs: int = _count_open_jobs(job_type)
	if open_jobs >= max_jobs:
		return
	var candidates: Array[DFItem] = []
	for entity in world.entities:
		if not (entity is DFItem):
			continue
		var item: DFItem = entity
		if item.item_type != item_type or item.is_in_stockpile or item.is_inside_container or item.carried_by_id >= 0:
			continue
		if _job_targets_item(job_type, item.id):
			continue
		candidates.append(item)

	# Seleccionar siempre el candidato restante más cercano sin usar una lambda
	# tipada. Esto evita inferencias Variant que el proyecto convierte en errores.
	while open_jobs < max_jobs and not candidates.is_empty():
		var nearest_index: int = 0
		var nearest_distance: int = 2147483647
		for candidate_index: int in range(candidates.size()):
			var candidate_item: DFItem = candidates[candidate_index]
			var candidate_distance: int = abs(candidate_item.tile_pos.x - settlement_center.x) + abs(candidate_item.tile_pos.z - settlement_center.z)
			if candidate_distance < nearest_distance:
				nearest_distance = candidate_distance
				nearest_index = candidate_index
		var selected_item: DFItem = candidates[nearest_index]
		candidates.remove_at(nearest_index)
		var collect_job: DFJob = DFJob.new(job_type, selected_item.tile_pos, priority)
		collect_job.set_meta("target_item_id", selected_item.id)
		designation.job_queue.append(collect_job)
		open_jobs += 1

func _queue_harvest_jobs(max_jobs: int) -> void:
	if designation == null or world == null:
		return
	var open_jobs: int = _count_open_jobs(DFJob.JobType.FARM_HARVEST)
	if open_jobs >= max_jobs:
		return
	for crop_position_value: Variant in world.growing_crops.keys():
		if open_jobs >= max_jobs:
			break
		if not (crop_position_value is Vector3i):
			continue
		var crop_position: Vector3i = crop_position_value
		if not world.is_grown_crop(crop_position):
			continue
		if _queue_job_once(DFJob.JobType.FARM_HARVEST, crop_position, 9):
			open_jobs += 1

func _has_loose_item_type(item_types: Array[String]) -> bool:
	for entity in world.entities:
		if entity is DFItem:
			var item: DFItem = entity
			if item.item_type in item_types and not item.is_decayed and item.carried_by_id < 0:
				return true
	return false

func _queue_colony_production_jobs(alive_dwarves: int, food_count: int, drink_count: int) -> void:
	if designation == null or alive_dwarves <= 0:
		return
	if food_count < alive_dwarves * 4 and _count_open_jobs(DFJob.JobType.COOK_FOOD) < 2:
		if _has_loose_item_type(["food", "meat", "fish"]):
			var cook_position: Vector3i = settlement_center + Vector3i(1, 0, 0)
			_queue_job_once(DFJob.JobType.COOK_FOOD, cook_position, 8)
	if drink_count < alive_dwarves * 3 and food_count > alive_dwarves * 2 and _count_open_jobs(DFJob.JobType.BREW_DRINK) < 2:
		if _has_loose_item_type(["food", "plant"]):
			var brew_position: Vector3i = settlement_center + Vector3i(-1, 0, 0)
			_queue_job_once(DFJob.JobType.BREW_DRINK, brew_position, 7)
	var open_store_jobs: int = _count_open_jobs(DFJob.JobType.STORE_IN_CONTAINER)
	if open_store_jobs < 2:
		var simulation_tick: int = int(world.get_meta("simulation_tick_total", 0))
		for entity_value: Variant in world.entities:
			if open_store_jobs >= 2:
				break
			if not (entity_value is DFItem):
				continue
			var loose_food: DFItem = entity_value
			if loose_food.item_type not in ["food", "drink", "meat", "fish"]:
				continue
			if loose_food.is_in_stockpile or loose_food.is_inside_container or loose_food.carried_by_id >= 0 or loose_food.is_decayed:
				continue
			if simulation_tick < int(loose_food.get_meta("storage_blocked_until", 0)):
				continue
			if _job_targets_item(DFJob.JobType.STORE_IN_CONTAINER, loose_food.id):
				continue
			var store_job: DFJob = DFJob.new(DFJob.JobType.STORE_IN_CONTAINER, loose_food.tile_pos, 8)
			store_job.set_meta("target_item_id", loose_food.id)
			store_job.set_meta("colony_project", "food_storage")
			designation.job_queue.append(store_job)
			open_store_jobs += 1

func _count_all_open_jobs() -> int:
	if designation == null:
		return 0
	var count: int = 0
	for job in designation.job_queue:
		if job.state in [DFJob.JobState.UNASSIGNED, DFJob.JobState.ASSIGNED, DFJob.JobState.IN_PROGRESS]:
			count += 1
	return count

func _queue_training_jobs(alive_dwarves: int) -> void:
	if designation == null or alive_dwarves <= 0:
		return
	var missing_jobs: int = maxi(0, alive_dwarves - _count_all_open_jobs())
	for training_index: int in range(missing_jobs):
		var column: int = training_index % 7
		var row: int = floori(float(training_index) / 7.0)
		var training_position: Vector3i = settlement_center + Vector3i(column - 3, 0, 3 + row)
		if not world.is_blocked(training_position) and not world.is_water(training_position):
			_queue_job_once(DFJob.JobType.TRAIN, training_position, 2)

func _queue_house_expansion_if_needed(alive_dwarves: int) -> void:
	var bedroom_count := 0
	for building in world.buildings:
		if building.type == DFBuilding.BuildingType.BEDROOM:
			bedroom_count += 1
	# Mantener dos viviendas libres hace visible y útil la primera cadena
	# económica incluso antes de que llegue el primer migrante: la colonia
	# produce tablas, construye una casa, fabrica una cama y la instala.
	var desired_bedroom_count: int = alive_dwarves + 2
	if bedroom_count + _autonomous_house_projects.size() >= desired_bedroom_count:
		return
	var template: Dictionary = HOUSE_TEMPLATES[0]
	var ring := 14 + bedroom_count * 2
	var angle_index := bedroom_count % 8
	var directions = [Vector2i(1,0), Vector2i(1,1), Vector2i(0,1), Vector2i(-1,1), Vector2i(-1,0), Vector2i(-1,-1), Vector2i(0,-1), Vector2i(1,-1)]
	var desired2: Vector2i = Vector2i(settlement_center.x, settlement_center.z) + directions[angle_index] * ring
	var used: Array = []
	for project in _autonomous_house_projects:
		used.append(project["origin"])
	var origin := _find_safe_house_origin(Vector3i(desired2.x, settlement_center.y, desired2.y), template, used)
	if origin.x < 0:
		return
	var floors: Array = []
	var walls: Array = []
	for floor_offset_value: Variant in template.floors:
		var floor_offset: Vector2i = floor_offset_value
		var floor_position: Vector3i = origin + Vector3i(floor_offset.x, 0, floor_offset.y)
		floors.append(floor_position)
		_queue_house_construction_job(DFJob.JobType.BUILD_FLOOR, floor_position, 7)
	var neighbors: Array[Vector2i] = [Vector2i(-1,-1), Vector2i(0,-1), Vector2i(1,-1), Vector2i(-1,0), Vector2i(1,0), Vector2i(-1,1), Vector2i(0,1), Vector2i(1,1)]
	for wall_source_offset_value: Variant in template.floors:
		var wall_source_offset: Vector2i = wall_source_offset_value
		for neighbor_offset: Vector2i in neighbors:
			var edge: Vector2i = wall_source_offset + neighbor_offset
			if edge in template.floors:
				continue
			var wall_position: Vector3i = origin + Vector3i(edge.x, 0, edge.y)
			if edge == template.door:
				if wall_position not in floors:
					floors.append(wall_position)
					_queue_house_construction_job(DFJob.JobType.BUILD_FLOOR, wall_position, 7)
			elif wall_position not in walls:
				walls.append(wall_position)
				_queue_house_construction_job(DFJob.JobType.BUILD_WALL, wall_position, 7)
	_autonomous_house_projects.append({"origin": origin, "floors": floors, "walls": walls, "bed": origin + Vector3i(template.bed.x, 0, template.bed.y), "door": origin + Vector3i(template.door.x, 0, template.door.y), "bed_item_id": -1})
	add_message("La colonia planificó una nueva vivienda.")

func _find_world_item_by_id(item_id: int) -> DFItem:
	if world == null or item_id < 0:
		return null
	for entity_value: Variant in world.entities:
		if entity_value is DFItem:
			var item: DFItem = entity_value
			if item.id == item_id:
				return item
	return null

func _find_bed_at_position(position: Vector3i) -> DFItem:
	if world == null:
		return null
	for entity_value: Variant in world.entities:
		if entity_value is DFItem:
			var item: DFItem = entity_value
			if item.tile_pos == position and (item.is_bed or "cama" in item.name.to_lower()):
				return item
	return null

func _bed_is_already_installed(item: DFItem) -> bool:
	if item == null:
		return false
	for building_value: Variant in world.buildings:
		if building_value is DFBuilding:
			var building: DFBuilding = building_value
			if building.type == DFBuilding.BuildingType.BEDROOM and building.tile_pos == item.tile_pos:
				return true
	return false

func _find_available_loose_bed() -> DFItem:
	if world == null:
		return null
	for entity_value: Variant in world.entities:
		if not (entity_value is DFItem):
			continue
		var item: DFItem = entity_value
		if not (item.is_bed or "cama" in item.name.to_lower()):
			continue
		if item.is_decayed or item.carried_by_id >= 0 or item.reserved_by_id >= 0:
			continue
		if _bed_is_already_installed(item) or _job_targets_item(DFJob.JobType.HAUL_ITEM, item.id):
			continue
		return item
	return null

func _queue_bed_delivery(project: Dictionary, bed_position: Vector3i) -> bool:
	if designation == null:
		return false
	var bed_item_id: int = int(project.get("bed_item_id", -1))
	var bed_item: DFItem = _find_world_item_by_id(bed_item_id)
	if bed_item == null and bed_item_id >= 0 and _job_targets_item(DFJob.JobType.HAUL_ITEM, bed_item_id):
		return true
	if bed_item == null:
		bed_item = _find_available_loose_bed()
		if bed_item == null:
			project["bed_item_id"] = -1
			return false
		project["bed_item_id"] = bed_item.id
	if _job_targets_item(DFJob.JobType.HAUL_ITEM, bed_item.id):
		return true
	var haul_job: DFJob = DFJob.new(DFJob.JobType.HAUL_ITEM, bed_item.tile_pos, 9)
	haul_job.set_meta("target_item_id", bed_item.id)
	haul_job.set_meta("drop_position", bed_position)
	haul_job.set_meta("mark_as_bed", true)
	haul_job.set_meta("colony_project", "housing")
	designation.job_queue.append(haul_job)
	return true

func _finish_autonomous_house_projects() -> void:
	if designation == null or world == null:
		return

	for project_value in _autonomous_house_projects.duplicate():
		if not project_value is Dictionary:
			_autonomous_house_projects.erase(project_value)
			continue

		var project: Dictionary = project_value
		var complete: bool = true

		# Un trabajo de construcción puede cancelarse por una ruta bloqueada,
		# muerte o pataleta. Si la baldosa aún falta y ya no existe un trabajo,
		# se vuelve a poner en cola para que el proyecto no quede congelado.
		for floor_value in project.get("floors", []):
			var floor_pos: Vector3i = floor_value
			if world.get_tile(floor_pos) == DFWorld.TileType.CONSTRUCTED_FLOOR:
				continue
			complete = false
			if not designation.has_job_at(floor_pos, DFJob.JobType.BUILD_FLOOR):
				_queue_house_construction_job(DFJob.JobType.BUILD_FLOOR, floor_pos, 7)

		for wall_value in project.get("walls", []):
			var wall_pos: Vector3i = wall_value
			if world.get_tile(wall_pos) == DFWorld.TileType.CONSTRUCTED_WALL:
				continue
			complete = false
			if not designation.has_job_at(wall_pos, DFJob.JobType.BUILD_WALL):
				_queue_house_construction_job(DFJob.JobType.BUILD_WALL, wall_pos, 7)

		if not complete:
			continue

		var bed_pos: Vector3i = project.get("bed", Vector3i(-1, -1, -1))
		var door_pos: Vector3i = project.get("door", Vector3i(-1, -1, -1))
		if bed_pos.x < 0 or door_pos.x < 0:
			_autonomous_house_projects.erase(project)
			continue

		# La casa no obtiene una cama gratis. Debe esperar una cama fabricada en la
		# carpintería y transportada físicamente hasta el dormitorio.
		var installed_bed: DFItem = _find_bed_at_position(bed_pos)
		if installed_bed == null:
			_queue_bed_delivery(project, bed_pos)
			continue
		installed_bed.is_bed = true
		installed_bed.is_in_stockpile = false
		installed_bed.is_inside_container = false

		var bedroom_exists: bool = false
		for building_value: Variant in world.buildings:
			if building_value is DFBuilding:
				var existing_building: DFBuilding = building_value
				if existing_building.type == DFBuilding.BuildingType.BEDROOM and existing_building.tile_pos == bed_pos:
					bedroom_exists = true
					break
		if not bedroom_exists:
			var bedroom: DFBuilding = DFBuilding.new(DFBuilding.BuildingType.BEDROOM, bed_pos)
			world.buildings.append(bedroom)

		var door_exists: bool = false
		for door_value: Variant in world.entities:
			if door_value is DFItem:
				var door_item: DFItem = door_value
				if door_item.tile_pos == door_pos and door_item.item_type == "door":
					door_exists = true
					break
		if not door_exists:
			world._spawn_item(door_pos, "Puerta de Madera", "door", 0, "p", Color("#8B5A2B"))

		for dwarf_value in world.entities:
			if not dwarf_value is DFDwarf:
				continue
			var dwarf: DFDwarf = dwarf_value
			if dwarf.is_alive and dwarf.preferred_bed.x < 0:
				dwarf.preferred_bed = bed_pos
				break

		_autonomous_house_projects.erase(project)
		add_message("Los enanos terminaron una nueva vivienda.")

func _auto_designate_initial_jobs(center: Vector3i) -> void:
	# Genera trabajos iniciales: talar arboles, cavar refugio, construir puerta
	if designation == null or world == null:
		return
	var trees_designated = 0
	var dug_tiles = 0
	var built_tiles = 0
	var haul_jobs = 0
	var search_radius = 25
	var sy = center.y
	var total_jobs_before = designation.job_queue.size()
	
	add_message("  Buscando recursos naturales cerca del asentamiento...")
	
	# 1. Buscar arboles en MULTIPLES niveles de altura (Y-1 a Y+2)
	var cx = center.x
	var cz = center.z
	for tree_y in range(-1, 3):
		for tree_dz in range(-search_radius, search_radius + 1):
			for tree_dx in range(-search_radius, search_radius + 1):
				if trees_designated >= 10:
					break
				var tree_pos = Vector3i(cx + tree_dx, sy + tree_y, cz + tree_dz)
				if tree_pos.x < 1 or tree_pos.x >= world.width - 1 or tree_pos.z < 1 or tree_pos.z >= world.depth - 1:
					continue
				if world.get_tile(tree_pos) == DFWorld.TileType.TREE:
					var tree_job = DFJob.new(DFJob.JobType.CHOP_TREE, tree_pos)
					designation.job_queue.append(tree_job)
					trees_designated += 1
			if trees_designated >= 10:
				break
		if trees_designated >= 10:
			break
	
	# 2. Buscar paredes naturales para excavar refugio (Y-2 a Y+1)
	for dig_y in range(-2, 2):
		for dig_dz in range(-search_radius, search_radius + 1):
			for dig_dx in range(-search_radius, search_radius + 1):
				if dug_tiles >= 12:
					break
				var dig_pos = Vector3i(cx + dig_dx, sy + dig_y, cz + dig_dz)
				if dig_pos.x < 2 or dig_pos.x >= world.width - 2 or dig_pos.z < 2 or dig_pos.z >= world.depth - 2:
					continue
				if world.is_wall(dig_pos) and not designation.has_job_at(dig_pos):
					var priority = 8 if dug_tiles < 6 else 6
					var dig_job = DFJob.new(DFJob.JobType.DIG, dig_pos, priority)
					designation.job_queue.append(dig_job)
					dug_tiles += 1
			if dug_tiles >= 12:
				break
		if dug_tiles >= 12:
			break
	
	# 2b. GARANTIA: Si no se encontraron suficientes paredes naturales,
	# cavar un sotano debajo del asentamiento (Y-1, 4x4)
	var guaranteed_dig = 0
	if dug_tiles < 6:
		var dig_below = sy - 1
		if dig_below >= 1:
			for gd_dz in range(-2, 3):
				for gd_dx in range(-2, 3):
					if guaranteed_dig >= 10:
						break
					var gd_pos = Vector3i(cx + gd_dx, dig_below, cz + gd_dz)
					if gd_pos.x < 2 or gd_pos.x >= world.width - 2 or gd_pos.z < 2 or gd_pos.z >= world.depth - 2:
						continue
					if world.is_wall(gd_pos) and not designation.has_job_at(gd_pos):
						var gd_job = DFJob.new(DFJob.JobType.DIG, gd_pos, 5)
						designation.job_queue.append(gd_job)
						guaranteed_dig += 1
				if guaranteed_dig >= 10:
					break
	
	# 3. Construir puerta/entrada si hay materiales (BUILD_WALL cerca del centro)
	for bw_dz in range(-3, 4):
		for bw_dx in range(-3, 4):
			if built_tiles >= 3:
				break
			var bw_pos = Vector3i(cx + bw_dx, sy, cz + bw_dz)
			if bw_pos.x < 2 or bw_pos.x >= world.width - 2 or bw_pos.z < 2 or bw_pos.z >= world.depth - 2:
				continue
			if world.get_tile(bw_pos) == DFWorld.TileType.FLOOR or world.get_tile(bw_pos) == DFWorld.TileType.GRASS:
				if not designation.has_job_at(bw_pos):
					var bw_job = DFJob.new(DFJob.JobType.BUILD_WALL, bw_pos, 7)
					designation.job_queue.append(bw_job)
					built_tiles += 1
		if built_tiles >= 3:
			break
	
	# 4. Trabajos de recogida de materiales (hauling)
	var haul_count = min(8, trees_designated + dug_tiles + guaranteed_dig + 4)
	for i in range(haul_count):
		var rx = cx + (randi() % 20) - 10
		var rz = cz + (randi() % 20) - 10
		var haul_pos = Vector3i(clampi(rx, 2, world.width - 2), sy, clampi(rz, 2, world.depth - 2))
		var job_type = DFJob.JobType.COLLECT_WOOD if randi() % 2 == 0 else DFJob.JobType.COLLECT_STONE
		var haul_job = DFJob.new(job_type, haul_pos, 3)
		designation.job_queue.append(haul_job)
		haul_jobs += 1
	
	# 5. Cazar criaturas cercanas (s?lo si hay un cazador disponible)
	var has_hunter = false
	for e_hunter_check in world.entities:
		if e_hunter_check.get("creature_type") == "dwarf" and e_hunter_check.get("is_alive") == true:
			if e_hunter_check.get("profession") == DFDwarf.Profession.HUNTER:
				has_hunter = true
				break
	var hunt_jobs_created = 0
	var hunted_positions = []
	if has_hunter:
		for e_hunt in world.entities:
			if hunt_jobs_created >= 4:
				break
			if e_hunt.get("creature_type") != null and e_hunt.get("creature_type") != "dwarf" and e_hunt.get("is_alive") == true:
				var hx = e_hunt.tile_pos.x
				var hz = e_hunt.tile_pos.z
				var hdist = abs(hx - cx) + abs(hz - cz)
				if hdist <= search_radius * 2:
					var already_targeted = false
					for hp in hunted_positions:
						if abs(hp.x - hx) + abs(hp.z - hz) < 5:
							already_targeted = true
							break
					if not already_targeted:
						var hunt_job = DFJob.new(DFJob.JobType.HUNT, e_hunt.tile_pos, 6)
						hunt_job.set_meta("creature_id", e_hunt.id)
						designation.job_queue.append(hunt_job)
						hunted_positions.append(e_hunt.tile_pos)
						hunt_jobs_created += 1

	# 6. Pescar en orillas de agua cercana (s?lo tiles de orilla, no agua profunda)
	var fish_jobs_created = 0
	var fished_positions = []
	for fish_dz in range(-search_radius, search_radius + 1):
		for fish_dx in range(-search_radius, search_radius + 1):
			if fish_jobs_created >= 4:
				break
			var fish_pos = Vector3i(cx + fish_dx, sy, cz + fish_dz)
			if fish_pos.x < 1 or fish_pos.x >= world.width - 1 or fish_pos.z < 1 or fish_pos.z >= world.depth - 1:
				continue
			if world.is_water(fish_pos):
				var is_edge = false
				for edge_dz in range(-1, 2):
					for edge_dx in range(-1, 2):
						if edge_dx == 0 and edge_dz == 0: continue
						var edge_pos = Vector3i(fish_pos.x + edge_dx, fish_pos.y, fish_pos.z + edge_dz)
						if edge_pos.x >= 0 and edge_pos.x < world.width and edge_pos.z >= 0 and edge_pos.z < world.depth:
							if not world.is_water(edge_pos):
								is_edge = true
								break
					if is_edge: break
				if not is_edge: continue
				var already_fished = false
				for fp in fished_positions:
					if abs(fp.x - fish_pos.x) + abs(fp.z - fish_pos.z) < 6:
						already_fished = true
						break
				if not already_fished and not designation.has_job_at(fish_pos):
					var fish_job = DFJob.new(DFJob.JobType.FISH, fish_pos, 6)
					designation.job_queue.append(fish_job)
					fished_positions.append(fish_pos)
					fish_jobs_created += 1
		if fish_jobs_created >= 4:
			break

	# 7. Trabajos de artesan?a seg?n materiales disponibles en ?rea central
	var craft_jobs_created = 0
	var craft_defs = [
		{ "type": DFJob.JobType.COOK_FOOD, "mat": "food", "max": 2 },
		{ "type": DFJob.JobType.BREW_DRINK, "mat": "drink", "max": 2 },
		{ "type": DFJob.JobType.SMELT_ORE, "mat": "ore", "max": 1 },
		{ "type": DFJob.JobType.MAKE_CHARCOAL, "mat": "wood", "max": 2 },
		{ "type": DFJob.JobType.PROCESS_PLANT, "mat": "plant", "max": 1 },
		{ "type": DFJob.JobType.TAN_HIDE, "mat": "hide", "max": 1 },
		{ "type": DFJob.JobType.SPIN_THREAD, "mat": "fiber", "max": 1 }
	]
	for cd in craft_defs:
		var has_mat = false
		for e_cm in world.entities:
			if e_cm is DFItem and e_cm.item_type == cd["mat"]:
				var d_cm = abs(e_cm.tile_pos.x - cx) + abs(e_cm.tile_pos.z - cz)
				if d_cm <= search_radius:
					has_mat = true
					break
		var already_queued = false
		for qj in designation.job_queue:
			if qj.job_type == cd["type"] and qj.state == DFJob.JobState.UNASSIGNED:
				already_queued = true
				break
		if has_mat and not already_queued:
			var cj = DFJob.new(cd["type"], Vector3i(cx, sy, cz), 5)
			designation.job_queue.append(cj)
			craft_jobs_created += 1
	# Tambi?n revisar inventarios de los enanos para oficios con materiales
	if craft_jobs_created < 2:
		var dwarf_inv_types = {}
		for e_dwarf in world.entities:
			if e_dwarf.get("creature_type") == "dwarf" and e_dwarf.get("is_alive") == true:
				var inv: Array = _safe_get(e_dwarf, "inventory", [])
				for inv_item in inv:
					if inv_item is DFItem:
						dwarf_inv_types[inv_item.item_type] = true
		for cd2 in craft_defs:
			if dwarf_inv_types.has(cd2["mat"]):
				var already_q2 = false
				for qj2 in designation.job_queue:
					if qj2.job_type == cd2["type"] and qj2.state == DFJob.JobState.UNASSIGNED:
						already_q2 = true
						break
				if not already_q2:
					var cj2 = DFJob.new(cd2["type"], Vector3i(cx, sy, cz), 5)
					designation.job_queue.append(cj2)
					craft_jobs_created += 1
					if craft_jobs_created >= 4:
						break

	# 8. Guardar una provisión concreta. El trabajo siempre conserva el ID del
	# objeto para evitar que varios aldeanos recorran la colonia buscando lo mismo.
	var initial_store_target: DFItem = null
	for e_fs: Variant in world.entities:
		if not (e_fs is DFItem):
			continue
		var provision: DFItem = e_fs
		if provision.item_type not in ["food", "drink", "meat", "fish"]:
			continue
		if provision.is_inside_container or provision.is_in_stockpile or provision.is_decayed or provision.carried_by_id >= 0:
			continue
		if _job_targets_item(DFJob.JobType.STORE_IN_CONTAINER, provision.id):
			continue
		initial_store_target = provision
		break
	if initial_store_target != null:
		var store_job: DFJob = DFJob.new(DFJob.JobType.STORE_IN_CONTAINER, initial_store_target.tile_pos, 7)
		store_job.set_meta("target_item_id", initial_store_target.id)
		store_job.set_meta("colony_project", "food_storage")
		designation.job_queue.append(store_job)
		craft_jobs_created += 1

	var total_added = designation.job_queue.size() - total_jobs_before
	add_message("  Trabajos auto-generados: " + str(trees_designated) + " talar, " + str(dug_tiles) + " cavar, " + str(built_tiles) + " construir, " + str(haul_jobs) + " recolectar, " + str(hunt_jobs_created) + " cazar, " + str(fish_jobs_created) + " pescar, " + str(craft_jobs_created) + " artesan?a. Total: " + str(total_added) + " trabajos.")
	if total_added == 0:
		add_message("  ADVERTENCIA: No se encontraron recursos cerca. Expande el radio de busqueda manualmente.")
func _generate_historical_settlements() -> void:
	if world_gen == null or world == null:
		return
	var rng = RandomNumberGenerator.new()
	rng.seed = generation_seed
	var half_win = 3.0
	for site in world_gen.sites:
		var dx = site.get("x", 0) - embark_cursor.x
		var dz = site.get("z", 0) - embark_cursor.y
		if abs(dx) <= half_win and abs(dz) <= half_win:
			var lx = clampi(int(128.0 + dx * 42.67), 25, 230)
			var lz = clampi(int(128.0 + dz * 42.67), 25, 230)
			var pop = site.get("population", 60)
			var num_houses = clampi(int(pop / 15.0), 1, 4)
			add_message("Ruinas del asentamiento '%s' encontradas en el area" % site.get("name", "Asentamiento"))
			for h in range(num_houses):
				var ox = rng.randi_range(-25, 25)
				var oz = rng.randi_range(-25, 25)
				var cx = clampi(lx + ox, 15, 240)
				var cz = clampi(lz + oz, 15, 240)
				var hw = rng.randi_range(5, 8)
				var hd = rng.randi_range(5, 8)
				var ruin_floors: Array = []
				for ruin_dz in range(-int(hd / 2.0), int(hd / 2.0) + 1):
					for ruin_dx in range(-int(hw / 2.0), int(hw / 2.0) + 1):
						ruin_floors.append(Vector2i(ruin_dx, ruin_dz))
				var ruin_template := {"floors": ruin_floors, "door": Vector2i(0, int(hd / 2.0)), "bed": Vector2i.ZERO}
				var ruin_origin = _find_safe_house_origin(Vector3i(cx, world.get_surface_height(cx, cz), cz), ruin_template, [])
				if ruin_origin.x < 0 or abs(ruin_origin.x - settlement_center.x) + abs(ruin_origin.z - settlement_center.z) < 24:
					continue
				cx = ruin_origin.x
				cz = ruin_origin.z
				var sy = ruin_origin.y
				for dz_h in range(-int(hd/2), int(hd/2) + 1):
					for dx_h in range(-int(hw/2), int(hw/2) + 1):
						var px = cx + dx_h
						var pz = cz + dz_h
						if px < 2 or px >= world.width - 2 or pz < 2 or pz >= world.depth - 2:
							continue
						var p = Vector3i(px, sy, pz)
						world.set_tile(p, DFWorld.TileType.CONSTRUCTED_FLOOR)
						world.set_material(p, DFWorld.MatType.WOOD if rng.randf() < 0.5 else DFWorld.MatType.STONE)
						for check_y in range(sy + 1, sy + 3):
							world.set_tile(Vector3i(px, check_y, pz), DFWorld.TileType.FLOOR)
							world.set_material(Vector3i(px, check_y, pz), DFWorld.MatType.CONSTRUCTION)
						var is_border = (dx_h == -int(hw/2) or dx_h == int(hw/2) or dz_h == -int(hd/2) or dz_h == int(hd/2))
						if is_border:
							if dz_h == int(hd/2) and dx_h == 0: continue
							world.set_tile(p, DFWorld.TileType.CONSTRUCTED_WALL)
							world.set_material(p, DFWorld.MatType.WOOD if rng.randf() < 0.5 else DFWorld.MatType.STONE)
				if rng.randf() < 0.7:
					var chest_pos = Vector3i(cx, sy, cz)
					world._spawn_item(chest_pos, "Cofre de la Ruina", "tool", DFWorld.MatType.IRON, "[", Color("#B0C4DE"))
					var placed_artifact = false
					if history_gen != null and history_gen.artifact_instances.size() > 0:
						var site_id = site.get("id", -1)
						var site_arts = []
						for ai in history_gen.artifact_instances:
							if ai.get("site_id", -1) == site_id:
								site_arts.append(ai)
						for chosen in site_arts:
							var art_pos = _fix_surface(Vector3i(cx + rng.randi_range(-1, 1), sy, cz + rng.randi_range(-1, 1)))
							var art_item = DFItem.new(art_pos, chosen["name"], "weapon", 0, chosen["glyph"], chosen["color"])
							art_item.is_artifact = true
							art_item.artifact_name = chosen["name"]
							art_item.artifact_creation_year = chosen["year"]
							art_item.quality = DFItem.QualityLevel.ARTIFACT
							art_item.base_value = 1500 + rng.randi_range(500, 8000)
							art_item.total_value = art_item.base_value
							art_item.artifact_lore = "Reliquia legendaria de %s. Forjado en el año %d por %s." % [site.get("name", "Anurkar"), chosen["year"], chosen.get("creator_name", "un artesano olvidado")]
							art_item.set_meta("is_artifact", true)
							art_item.set_meta("artifact_lore", art_item.artifact_lore)
							world.entities.append(art_item)
							placed_artifact = true
							add_message("¡Reliquia histórica '%s' engendrada en el cofre!" % chosen["name"])
					
					# Spawn beast bones if a megabeast died here
					if history_gen != null:
						var target_site_id = site.get("id", -1)
						for bi in history_gen.beast_instances:
							var hf_rec = history_gen._get_hf(bi.get("hf_id", -1))
							if hf_rec != null and hf_rec.death_year != -1 and hf_rec.death_site_id == target_site_id:
								var bones_pos = _fix_surface(Vector3i(cx + rng.randi_range(-2, 2), sy, cz + rng.randi_range(-2, 2)))
								var bones_item = DFItem.new(bones_pos, "Huesos de " + bi.get("name", "la Bestia"), "stone", DFWorld.MatType.LIMESTONE, "*", Color("#F5F5DC"))
								bones_item.set_meta("is_beast_bones", true)
								bones_item.set_meta("beast_name", bi.get("name"))
								bones_item.set_meta("beast_desc", "Huesos legendarios de la megabestia '%s', derrotada en este sitio en el año %d." % [bi.get("name"), hf_rec.death_year])
								world.entities.append(bones_item)
								add_message("¡Huesos de la megabestia '%s' encontrados en la ruina!" % bi.get("name"))
								break
					
					# Spawn living historical figures associated with this site
					if history_gen != null:
						var alive_site_id = site.get("id", -1)
						for hf in history_gen.historical_figures:
							if hf.death_year == -1 and hf.race != "megabeast":
								var is_assoc = hf.site_id == alive_site_id
								var civ_rec = history_gen._get_civ(hf.civ_id)
								if not civ_rec.is_empty() and civ_rec.get("ruler_id") == hf.id and civ_rec.get("capital_x") == site.get("x") and civ_rec.get("capital_z") == site.get("z"):
									is_assoc = true
								
								if is_assoc:
									var npc_pos = _fix_surface(Vector3i(cx + rng.randi_range(-3, 3), sy, cz + rng.randi_range(-3, 3)))
									if hf.race == "dwarf":
										var dwarf_name = hf.name
										var dwarf = DFDwarf.new(npc_pos, dwarf_name)
										dwarf.profession = hf.profession
										dwarf.combat_skill = int(hf.combat_power)
										dwarf.set_meta("historical_figure_id", hf.id)
										world.entities.append(dwarf)
										add_message("¡El héroe histórico '%s' ha spawnado aquí!" % hf.name)
									else:
										var ct = "human" if hf.race == "human" else "elf" if hf.race == "elf" else "goblin"
										var glyph = "h" if hf.race == "human" else "e" if hf.race == "elf" else "g"
										var color = Color.GOLD if hf.is_ruler else Color.CORNFLOWER_BLUE
										var npc = DFCreature.new(npc_pos, hf.name, glyph, color, "medium")
										npc.set_meta("creature_type", ct)
										npc.set_meta("historical_figure_id", hf.id)
										npc.combat_skill = int(hf.combat_power)
										world.entities.append(npc)
										add_message("¡La figura histórica '%s' (%s) ha spawnado aquí!" % [hf.name, hf.profession])

					if not placed_artifact:
						var items = [["Madera antigua", "wood", DFWorld.MatType.WOOD, "=", Color("#8B5A2B")],["Carne Seca", "food", DFWorld.MatType.WOOD, "%", Color("#FF8844")],["Vino del Pasado", "drink", DFWorld.MatType.WOOD, "~", Color("#FFCC00")],["Pico Oxidado", "weapon", DFWorld.MatType.IRON, "p", Color("#88CCFF")]]
						var selected_item = items[rng.randi() % items.size()]
						var item_pos = _fix_surface(Vector3i(cx + rng.randi_range(-1, 1), sy, cz + rng.randi_range(-1, 1)))
						world._spawn_item(item_pos, selected_item[0], selected_item[1], selected_item[2], selected_item[3], selected_item[4])
				if rng.randf() < 0.5:
					var fx = clampi(cx + rng.randi_range(6, 12) * (1 if rng.randf() < 0.5 else -1), 10, 245)
					var fz = clampi(cz + rng.randi_range(6, 12) * (1 if rng.randf() < 0.5 else -1), 10, 245)
					var f_size = rng.randi_range(3, 5)
					for fdx in range(f_size):
						for fdz in range(f_size):
							var fpx = fx + fdx; var fpz = fz + fdz
							var fp = _fix_surface(Vector3i(fpx, 3, fpz))
							if fpx >= 2 and fpx < world.width - 2 and fpz >= 2 and fpz < world.depth - 2:
								world.set_tile(fp, DFWorld.TileType.FARM_SOIL)
								world.set_material(fp, DFWorld.MatType.SOIL)
								if rng.randf() < 0.4:
									world.tile_data[fp] = world.tile_data.get(fp, {})
									world.tile_data[fp]["crop_type"] = "plump_helmet"
									world.tile_data[fp]["growth"] = 0.2 + rng.randf() * 0.7

func _advance_time(minutes: int) -> void:
	_game_minute += minutes
	while _game_minute >= 60:
		_game_minute -= 60
		_game_hour += 1
		if _game_hour >= 24:
			_game_hour = 0
			_game_day += 1
			if _game_day > 28:
				_game_day = 1
				var si = SEASON_LIST.find(_game_season)
				_game_season = SEASON_LIST[(si + 1) % 4]
				_game_year += 1

func _handle_key(event: InputEvent) -> void:
	if event is InputEventKey:
		var kc = event.keycode
		# Si el viaje rápido está activo, interceptar y controlar
		if fast_travel != null and fast_travel.active:
			match fast_travel.phase:
				DFFastTravel.TravelPhase.SELECTING:
					match kc:
						KEY_UP, KEY_W: fast_travel.move_destination(0, -1)
						KEY_DOWN, KEY_S: fast_travel.move_destination(0, 1)
						KEY_LEFT, KEY_A: fast_travel.move_destination(-1, 0)
						KEY_RIGHT, KEY_D: fast_travel.move_destination(1, 0)
						KEY_ENTER: fast_travel.start_travel()
						KEY_ESCAPE, KEY_V: fast_travel.cancel()
				DFFastTravel.TravelPhase.ENCOUNTER, DFFastTravel.TravelPhase.COMPLETE:
					if kc in [KEY_ENTER, KEY_SPACE, KEY_ESCAPE]:
						fast_travel.resume_travel()
			renderer.queue_redraw()
			return

		# Si el quest log esta abierto, flechas para navegar
		if quest_system != null and quest_system.is_open():
			match kc:
				KEY_UP: quest_system.scroll_up()
				KEY_DOWN: quest_system.scroll_down()
				KEY_J:
					quest_system.close_quest_log()
				KEY_ESCAPE:
					quest_system.close_quest_log()
			return
		# Si el dialogo esta activo, las teclas controlan el menu
		if dialogue != null and dialogue.is_active():
			match kc:
				KEY_UP:
					if dialogue.state == DFDialogue.DialogueState.TOPIC_SELECT:
						dialogue.previous_topic()
				KEY_DOWN:
					if dialogue.state == DFDialogue.DialogueState.TOPIC_SELECT:
						dialogue.next_topic()
				KEY_ENTER:
					if dialogue.state == DFDialogue.DialogueState.TOPIC_SELECT:
						dialogue.select_topic(dialogue.topic_selected)
				KEY_T:
					if dialogue.state == DFDialogue.DialogueState.SHOW_RESPONSE:
						dialogue.back_to_topics()
					else:
						dialogue.close_dialogue()
						renderer._dialogue_active = false
			return
		if legends_mode and legends != null:
			match kc:
				KEY_PAGEUP:
					legends.prev_page()
				KEY_PAGEDOWN:
					legends.next_page()
				KEY_0:
					if legends.current_mode == DFLegends.ViewMode.FIGURE_DETAIL:
						legends.switch_mode(DFLegends.ViewMode.FIGURES)
						_legends_select_mode = false
					else:
						_legends_select_mode = true
						add_message("[0] Seleccion: pulsa numero de la figura")
				KEY_1:
					if _legends_select_mode and legends.current_mode == DFLegends.ViewMode.FIGURES:
						_finish_legends_select(1)
					else:
						legends.switch_mode(DFLegends.ViewMode.OVERVIEW)
						_legends_select_mode = false
				KEY_2:
					if _legends_select_mode and legends.current_mode == DFLegends.ViewMode.FIGURES:
						_finish_legends_select(2)
					else:
						legends.switch_mode(DFLegends.ViewMode.CHRONOLOGY)
						_legends_select_mode = false
				KEY_3:
					if _legends_select_mode and legends.current_mode == DFLegends.ViewMode.FIGURES:
						_finish_legends_select(3)
					else:
						legends.switch_mode(DFLegends.ViewMode.CIVILIZATIONS)
						_legends_select_mode = false
				KEY_4:
					if _legends_select_mode and legends.current_mode == DFLegends.ViewMode.FIGURES:
						_finish_legends_select(4)
					else:
						legends.switch_mode(DFLegends.ViewMode.FIGURES)
						_legends_select_mode = false
				KEY_5:
					if _legends_select_mode and legends.current_mode == DFLegends.ViewMode.FIGURES:
						_finish_legends_select(5)
					else:
						legends.switch_mode(DFLegends.ViewMode.BEASTS)
						_legends_select_mode = false
				KEY_6:
					if _legends_select_mode and legends.current_mode == DFLegends.ViewMode.FIGURES:
						_finish_legends_select(6)
					else:
						legends.switch_mode(DFLegends.ViewMode.ARTIFACTS)
						_legends_select_mode = false
				KEY_7:
					if _legends_select_mode and legends.current_mode == DFLegends.ViewMode.FIGURES:
						_finish_legends_select(7)
					else:
						legends.switch_mode(DFLegends.ViewMode.SITES)
						_legends_select_mode = false
				KEY_8:
					if _legends_select_mode and legends.current_mode == DFLegends.ViewMode.FIGURES:
						_finish_legends_select(8)
					else:
						legends.switch_mode(DFLegends.ViewMode.WARS)
						_legends_select_mode = false
				KEY_9:
					if _legends_select_mode and legends.current_mode == DFLegends.ViewMode.FIGURES:
						_finish_legends_select(9)
					else:
						legends.switch_mode(DFLegends.ViewMode.FAMILIES)
						_legends_select_mode = false
				KEY_L, KEY_ESCAPE:
					legends_mode = false
					_legends_select_mode = false
					renderer._legend_text = ""
					renderer._legend_mode = 0
					renderer._family_tree_data = {}
					add_message("Cronicas cerradas.")
			return
		match kc:
			KEY_UP, KEY_W:
				if possessed_dwarf != null:
					_try_move_possessed(Vector2i(0, -1))
					_held_move_direction = Vector2i(0, -1)
					_held_move_timer = HELD_MOVE_INITIAL_DELAY
				else:
					camera_pos.z = clampi(camera_pos.z - 2, 0, world.depth - 1)
					renderer.follow_dwarf = -1
					_held_move_direction = Vector2i(0, -1)
					_held_move_timer = HELD_MOVE_INITIAL_DELAY
			KEY_DOWN, KEY_S:
				if possessed_dwarf != null:
					_try_move_possessed(Vector2i(0, 1))
					_held_move_direction = Vector2i(0, 1)
					_held_move_timer = HELD_MOVE_INITIAL_DELAY
				else:
					camera_pos.z = clampi(camera_pos.z + 2, 0, world.depth - 1)
					renderer.follow_dwarf = -1
					_held_move_direction = Vector2i(0, 1)
					_held_move_timer = HELD_MOVE_INITIAL_DELAY
			KEY_LEFT, KEY_A:
				if possessed_dwarf != null:
					_try_move_possessed(Vector2i(-1, 0))
					_held_move_direction = Vector2i(-1, 0)
					_held_move_timer = HELD_MOVE_INITIAL_DELAY
				else:
					camera_pos.x = clampi(camera_pos.x - 2, 0, world.width - 1)
					renderer.follow_dwarf = -1
					_held_move_direction = Vector2i(-1, 0)
					_held_move_timer = HELD_MOVE_INITIAL_DELAY
			KEY_RIGHT, KEY_D:
				if possessed_dwarf != null:
					_try_move_possessed(Vector2i(1, 0))
					_held_move_direction = Vector2i(1, 0)
					_held_move_timer = HELD_MOVE_INITIAL_DELAY
				else:
					camera_pos.x = clampi(camera_pos.x + 2, 0, world.width - 1)
					renderer.follow_dwarf = -1
					_held_move_direction = Vector2i(1, 0)
					_held_move_timer = HELD_MOVE_INITIAL_DELAY
			KEY_SPACE:
				paused = not paused
				renderer.paused = paused
			KEY_H, KEY_QUESTION:
				renderer.show_help = not renderer.show_help
				renderer.queue_redraw()
			KEY_1:
				if designation != null:
					designation.set_mode(DFDesignation.DesignationMode.DIG)
			KEY_2:
				if designation != null:
					designation.set_mode(DFDesignation.DesignationMode.CHOP)
			KEY_3:
				if designation != null:
					designation.set_mode(DFDesignation.DesignationMode.SMOOTH)
			KEY_4:
				if designation != null:
					designation.set_mode(DFDesignation.DesignationMode.BUILD_WALL)
			KEY_5:
				if designation != null:
					designation.set_mode(DFDesignation.DesignationMode.BUILD_FLOOR)
			KEY_6:
				if designation != null:
					designation.set_mode(DFDesignation.DesignationMode.DECONSTRUCT)
			KEY_F:
				_cycle_follow()
			KEY_P:
				_possess_dwarf(renderer.follow_dwarf)
			KEY_V:
				if possessed_dwarf != null and fast_travel != null:
					fast_travel.start_fast_travel(camera_pos.x, camera_pos.z)
					add_message("=== VIAJE RÁPIDO === (Elige destino con WASD, ENTER para viajar)")
			KEY_L:
				legends_mode = not legends_mode
				if legends_mode and legends != null:
					legends.switch_mode(DFLegends.ViewMode.OVERVIEW)
					add_message("[L] Cronicas abiertas. PgUp/PgDn para navegar.")
				else:
					add_message("[L] Cronicas cerradas - viendo el mundo.")
			KEY_G:
				_regenerate_world()
			KEY_C, KEY_KP_ADD:
				camera_pos.y = clampi(camera_pos.y + 1, 1, 15)
			KEY_X, KEY_KP_SUBTRACT:
				camera_pos.y = clampi(camera_pos.y - 1, 1, 15)
			KEY_Q:
				if possessed_dwarf != null:
					_exit_possession()
			KEY_J:
				if quest_system != null:
					quest_system.toggle_quest_log()
					if quest_system.is_open():
						add_message("=== MISIONES (J para cerrar) ===")
			KEY_F5:
				if DFSaveLoad.save_game_slot(self, 0):
					add_message("Juego guardado en slot 0.")
				else:
					add_message("ERROR: No se pudo guardar la partida.")
			KEY_F6:
				if DFSaveLoad.save_game_slot(self, 1):
					add_message("Juego guardado en slot 1.")
				else:
					add_message("ERROR: No se pudo guardar la partida.")
			KEY_F7:
				if DFSaveLoad.save_game_slot(self, 2):
					add_message("Juego guardado en slot 2.")
				else:
					add_message("ERROR: No se pudo guardar la partida.")
			KEY_F9:
				paused = true
				renderer.paused = true
				if DFSaveLoad.load_game_slot(self, 0):
					add_message("Partida cargada desde slot 0.")
					paused = false
					renderer.paused = false
				else:
					add_message("ERROR: No se pudo cargar la partida.")
					paused = false
					renderer.paused = false
			KEY_F10:
				paused = true
				renderer.paused = true
				if DFSaveLoad.load_game_slot(self, 1):
					add_message("Partida cargada desde slot 1.")
					paused = false
					renderer.paused = false
				else:
					add_message("ERROR: No se pudo cargar la partida.")
					paused = false
					renderer.paused = false
			KEY_F11:
				paused = true
				renderer.paused = true
				if DFSaveLoad.load_game_slot(self, 2):
					add_message("Partida cargada desde slot 2.")
					paused = false
					renderer.paused = false
				else:
					add_message("ERROR: No se pudo cargar la partida.")
					paused = false
					renderer.paused = false
			KEY_T:
				if dialogue != null:
					if dialogue.is_active():
						if dialogue.state == DFDialogue.DialogueState.SHOW_RESPONSE:
							dialogue.back_to_topics()
						else:
							dialogue.close_dialogue()
							renderer._dialogue_active = false
					else:
						# Find entity near cursor to talk to
						var ht = renderer._highlighted_tile
						if ht.x >= 0:
							for e2 in world.entities:
								if e2.get("creature_type") in ["dwarf", "human", "elf", "goblin"] or (e2.get("is_hostile") != true and e2.get("is_alive") == true):
									var dist = abs(e2.tile_pos.x - ht.x) + abs(e2.tile_pos.z - ht.z)
									if dist <= 2 and e2.tile_pos.y == ht.y:
										if e2.get("is_hostile") != true:
											dialogue.start_dialogue(e2)
											add_message("Hablando con %s..." % str(_safe_get(e2, "name", "alguien")))
										break
					
func _finish_legends_select(num: int) -> void:
	_legends_select_mode = false
	if legends == null or history_gen == null:
		return
	if legends.current_mode != DFLegends.ViewMode.FIGURES:
		return
	var non_beasts = []
	for hf in history_gen.historical_figures:
		if hf.race != "megabeast":
			non_beasts.append(hf)
	var page_start = legends.current_page * 5
	var idx = page_start + num - 1
	if idx >= 0 and idx < non_beasts.size():
		var selected_hf = non_beasts[idx]
		legends.select_figure(selected_hf.id)
		add_message("Viendo detalle de: %s" % selected_hf.name)
	else:
		add_message("Numero de figura invalido.")

func _handle_mouse(event: InputEventMouseButton) -> void:
	if not event.is_pressed():
		return
	var bt = event.button_index
	var pos = event.position
	
	match current_state:
		GameState.SETTINGS_MENU:
			if bt == MOUSE_BUTTON_LEFT:
				# Check if clicked inside the Quick Start Box
				var center_x = renderer.size.x / 2
				var line_h = renderer._char_size.y
				var logo_y = 30 + int(line_h * 1.1) * 6 + 4 + int(line_h * 0.9)
				var qs_y = logo_y + int(line_h * 1.2) + 14
				var qs_w = 380
				var qs_h = 64
				var qs_x = center_x - qs_w / 2
				if pos.x >= qs_x and pos.x <= qs_x + qs_w and pos.y >= qs_y and pos.y <= qs_y + qs_h:
					_handle_menu_key(KEY_Q)
					return
				
				# Check if clicked inside the Configuration Box
				var cfg_y = qs_y + qs_h + 18 + int(line_h * 1.4)
				var box_w = 520
				var box_h = 145
				var box_x = center_x - box_w / 2
				if pos.x >= box_x and pos.x <= box_x + box_w and pos.y >= cfg_y and pos.y <= cfg_y + box_h:
					var relative_y = pos.y - cfg_y - 10
					var clicked_row = int(relative_y / (line_h * 1.25))
					if clicked_row >= 0 and clicked_row < 5:
						setting_selected_index = clicked_row
						# If they clicked on the right side of the row, cycle the value!
						if pos.x > center_x + 50:
							_handle_menu_key(KEY_RIGHT)
						else:
							renderer.queue_redraw()
						return
				
				# Check if clicked help bar "Crear Mundo"
				var foot_y = cfg_y + box_h + 8 + 38 + 20
				var help_x = center_x - 300
				var cm_x = help_x + 360
				if pos.x >= cm_x and pos.x <= cm_x + 110 and pos.y >= foot_y - 10 and pos.y <= foot_y + 16:
					_handle_menu_key(KEY_ENTER)
					return
					
		GameState.MODE_SELECT:
			if bt == MOUSE_BUTTON_LEFT:
				var center_x_mode = renderer.size.x / 2
				var line_h_mode = renderer._char_size.y
				var box_w_mode = 460
				var box_h_mode = 265
				var box_x_mode = center_x_mode - box_w_mode / 2
				var box_y_mode = (renderer.size.y - box_h_mode) / 2 - 30
				var options_start_y = box_y_mode + 35 + int(line_h_mode * 2.2)
				
				if pos.x >= box_x_mode + 20 and pos.x <= box_x_mode + box_w_mode - 20:
					var relative_y_mode = pos.y - options_start_y
					var clicked_idx = int(relative_y_mode / (line_h_mode * 2.0))
					if clicked_idx >= 0 and clicked_idx < 3:
						if setting_selected_index == clicked_idx:
							_handle_menu_key(KEY_ENTER)
						else:
							setting_selected_index = clicked_idx
							renderer.queue_redraw()
						return

		GameState.EMBARK_MAP_SELECT:
			if bt == MOUSE_BUTTON_LEFT:
				# Find click in map grid
				var map_grid_w = 40
				var map_grid_h = 25
				var panel_w = 380
				var spacing = 24
				var total_w = (map_grid_w * renderer._char_size.x) + spacing + panel_w
				var start_x = int((renderer.size.x - total_w) / 2)
				var start_y = int((renderer.size.y - map_grid_h * renderer._char_size.y) / 2 + 10)
				
				var map_w = world_gen.world_width
				var map_h = world_gen.world_depth
				var offset_x = embark_cursor.x - map_grid_w / 2
				var offset_y = embark_cursor.y - map_grid_h / 2
				
				var click_gx = int((pos.x - start_x) / renderer._char_size.x)
				var click_gz = int((pos.y - start_y) / renderer._char_size.y)
				
				if click_gx >= 0 and click_gx < map_grid_w and click_gz >= 0 and click_gz < map_grid_h:
					var target_wx = offset_x + click_gx
					var target_wz = offset_y + click_gz
					embark_cursor.x = clampi(target_wx, 0, map_w - 1)
					embark_cursor.y = clampi(target_wz, 0, map_h - 1)
					renderer.queue_redraw()
					return
				
				# Check click in Mini-map
				var panel_x = start_x + map_grid_w * renderer._char_size.x + spacing
				var minimap_size: int = 120
				var minimap_x: int = panel_x + int((panel_w - minimap_size) / 2)
				var minimap_y: int = start_y + int(map_grid_h * renderer._char_size.y) - minimap_size - 8
				
				if pos.x >= minimap_x and pos.x <= minimap_x + minimap_size and pos.y >= minimap_y and pos.y <= minimap_y + minimap_size:
					var relative_mx = pos.x - minimap_x
					var relative_my = pos.y - minimap_y
					var target_wx = int(relative_mx / float(minimap_size) * map_w)
					var target_wz = int(relative_my / float(minimap_size) * map_h)
					embark_cursor.x = clampi(target_wx, 0, map_w - 1)
					embark_cursor.y = clampi(target_wz, 0, map_h - 1)
					renderer.queue_redraw()
					return
				
				# Check if clicked confirm / back footer
				var foot_y_map = start_y + map_grid_h * renderer._char_size.y + 24
				if pos.y >= foot_y_map - 12 and pos.y <= foot_y_map + 12:
					if pos.x < renderer.size.x / 2:
						_handle_menu_key(KEY_ESCAPE)
					else:
						_handle_menu_key(KEY_ENTER)
					return
		
		GameState.EMBARK_PREPARE:
			if bt == MOUSE_BUTTON_LEFT:
				var center_x_prep = renderer.size.x / 2
				var line_h_prep = renderer._char_size.y
				if embark_prepare_step == 0:
					var box_w_prep = 440
					var box_h_prep = 240
					var box_x_prep = center_x_prep - box_w_prep / 2
					var box_y_prep = (renderer.size.y - box_h_prep) / 2
					var y_start = box_y_prep + 35 + int(line_h_prep * 2.2)
					
					if pos.x >= box_x_prep + 20 and pos.x <= box_x_prep + box_w_prep - 20:
						var relative_y_prep = pos.y - y_start
						var clicked_idx_prep = int(relative_y_prep / (line_h_prep * 2.0))
						if clicked_idx_prep >= 0 and clicked_idx_prep < 2:
							if setting_selected_index == clicked_idx_prep:
								_handle_menu_key(KEY_ENTER)
							else:
								setting_selected_index = clicked_idx_prep
								renderer.queue_redraw()
							return
				elif embark_prepare_step == 1:
					var box2_w = 780
					var box2_h = 440
					var box2_x = center_x_prep - box2_w / 2
					var box2_y = (renderer.size.y - box2_h) / 2 + 15
					var col_w = box2_w / 2 - 40
					var y_start_prep2 = box2_y + 70 + int(line_h_prep * 1.3)
					
					var skill_keys = embark_custom_skills.keys()
					var item_keys = embark_custom_items.keys()
					
					if pos.x >= box2_x + 20 and pos.x <= box2_x + 20 + col_w:
						var relative_y_prep_skills = pos.y - y_start_prep2
						var clicked_idx_prep_skills = int(relative_y_prep_skills / (line_h_prep * 1.4))
						if clicked_idx_prep_skills >= 0 and clicked_idx_prep_skills < skill_keys.size():
							if setting_selected_index == clicked_idx_prep_skills:
								var col_center = box2_x + 20 + col_w / 2
								if pos.x > col_center:
									_handle_menu_key(KEY_RIGHT)
								else:
									_handle_menu_key(KEY_LEFT)
							else:
								setting_selected_index = clicked_idx_prep_skills
								renderer.queue_redraw()
							return
					elif pos.x >= box2_x + box2_w / 2 + 10 and pos.x <= box2_x + box2_w / 2 + 10 + col_w:
						var relative_y_prep_items = pos.y - y_start_prep2
						var clicked_idx_prep_items = int(relative_y_prep_items / (line_h_prep * 1.4))
						if clicked_idx_prep_items >= 0 and clicked_idx_prep_items < item_keys.size():
							var target_idx = clicked_idx_prep_items + skill_keys.size()
							if setting_selected_index == target_idx:
								var col_center_items = box2_x + box2_w / 2 + 10 + col_w / 2
								if pos.x > col_center_items:
									_handle_menu_key(KEY_RIGHT)
								else:
									_handle_menu_key(KEY_LEFT)
							else:
								setting_selected_index = target_idx
								renderer.queue_redraw()
							return
					var instruct_y = box2_y + box2_h - 35
					if pos.y >= instruct_y - 12 and pos.y <= instruct_y + 12:
						if pos.x > center_x_prep + 80:
							_handle_menu_key(KEY_ENTER)
						elif pos.x < center_x_prep - 80:
							_handle_menu_key(KEY_ESCAPE)
						return
		GameState.PLAYING:
			if bt == MOUSE_BUTTON_LEFT and designation != null:
				var tile = renderer._highlighted_tile
				if tile.x >= 0:
					designation.apply(world, tile)
			if bt == MOUSE_BUTTON_RIGHT and designation != null:
				designation.cancel_last()

func _queue_recipe_by_index(index: int) -> void:
	var ht = renderer._highlighted_tile
	if ht.x < 0:
		return
	for w in world.workshops:
		var dx = ht.x - w.tile_pos.x
		var dz = ht.z - w.tile_pos.z
		if abs(dx) <= 1 and abs(dz) <= 1 and ht.y == w.tile_pos.y:
			var recipes = w.get_recipes()
			if index < recipes.size():
				var rec = recipes[index]
				if w.queue_recipe(rec["id"]):
					add_message("Encolado: %s en %s" % [rec["name"], w.name])
				else:
					add_message("Error al encolar receta.")
			else:
				add_message("Indice de receta invalido.")
			break

func _get_spiral_offsets(count: int) -> Array:
	var offsets = []
	var step = 12 # Spacing of 12 tiles between cabins
	var ring = 1
	while offsets.size() < count:
		# Top edge
		for tx in range(-ring, ring + 1):
			offsets.append(Vector2i(tx * step, -ring * step))
		# Right edge
		for tz in range(-ring + 1, ring + 1):
			offsets.append(Vector2i(ring * step, tz * step))
		# Bottom edge
		for tx in range(ring - 1, -ring - 1, -1):
			offsets.append(Vector2i(tx * step, ring * step))
		# Left edge
		for tz in range(ring - 1, -ring, -1):
			offsets.append(Vector2i(-ring * step, tz * step))
		ring += 1
	return offsets

func _simulate_embark_demographics(years: int) -> Array:
	var rng = RandomNumberGenerator.new()
	rng.seed = generation_seed + 1234
	
	# Initial 7 dwarves profile setup
	var list_dwarves = []
	for i in range(7):
		var dname = ""
		if i < config_dwarf_names.size() and config_dwarf_names[i] != "":
			dname = config_dwarf_names[i]
		else:
			dname = world_gen.namegen.generate_dwarf_name() if world_gen and world_gen.namegen else "Enano Fundador %d" % (i + 1)
			
		var is_male = i % 2 == 0
		var age = rng.randi_range(20, 45)
		var prof = DFDwarf.Profession.CRAFTSMAN
		if i < config_dwarf_professions.size():
			prof = config_dwarf_professions[i]
		else:
			# Standard starting professions
			var base_profs = [
				DFDwarf.Profession.MINER,
				DFDwarf.Profession.WOODCUTTER,
				DFDwarf.Profession.HUNTER,
				DFDwarf.Profession.CARPENTER,
				DFDwarf.Profession.FARMER,
				DFDwarf.Profession.COOK,
				DFDwarf.Profession.DOCTOR
			]
			prof = base_profs[i]
			
		list_dwarves.append({
			"name": dname,
			"gender_male": is_male,
			"age": age,
			"spouse": null,
			"alive": true,
			"profession": prof,
			"generation": 0,
			"equipped_weapon": config_dwarf_weapons[i] if i < config_dwarf_weapons.size() else "",
			"priorities": config_dwarf_priorities[i] if i < config_dwarf_priorities.size() else {}
		})
		
	# Simulation years
	for y in range(years):
		# 1. Aging and mortality
		for d in list_dwarves:
			if not d.alive: continue
			d.age += 1
			# Natural death checks
			var death_chance = 0.008 # 0.8% annual accident chance
			if d.age > 65:
				death_chance += (d.age - 65) * 0.05
			if rng.randf() < death_chance:
				d.alive = false
				
		# 2. Marriage
		var single_males = []
		var single_females = []
		for d in list_dwarves:
			if d.alive and d.age >= 18 and d.spouse == null:
				if d.gender_male:
					single_males.append(d)
				else:
					single_females.append(d)
		
		# Match couples
		single_males.shuffle()
		single_females.shuffle()
		var p_count = mini(single_males.size(), single_females.size())
		for i in range(p_count):
			if rng.randf() < 0.20: # 20% marriage chance per year
				single_males[i].spouse = single_females[i].name
				single_females[i].spouse = single_males[i].name
				
		# 3. Births
		var newborns = []
		for d in list_dwarves:
			# Female, alive, married, of child-bearing age
			if d.alive and not d.gender_male and d.spouse != null and d.age >= 18 and d.age <= 45:
				if rng.randf() < 0.25: # 25% birth chance per married female
					newborns.append({
						"name": world_gen.namegen.generate_dwarf_name() if world_gen and world_gen.namegen else "Hijo de " + d.name.split(" ")[0],
						"gender_male": rng.randf() < 0.5,
						"age": 0,
						"spouse": null,
						"alive": true,
						"profession": DFDwarf.Profession.CRAFTSMAN,
						"generation": d.generation + 1,
						"equipped_weapon": "",
						"priorities": {}
					})
		list_dwarves.append_array(newborns)
		
		# 4. Critical Population Immigration
		var alive_count = 0
		for d in list_dwarves:
			if d.alive: alive_count += 1
		if alive_count < 3:
			# Immigrants join
			var imm_count = rng.randi_range(2, 4)
			for i in range(imm_count):
				list_dwarves.append({
					"name": world_gen.namegen.generate_dwarf_name() if world_gen and world_gen.namegen else "Refugiado",
					"gender_male": rng.randf() < 0.5,
					"age": rng.randi_range(18, 30),
					"spouse": null,
					"alive": true,
					"profession": rng.randi_range(0, 7),
					"generation": 0,
					"equipped_weapon": "",
					"priorities": {}
				})
				
	# Filter survivors
	var survivors = []
	for d in list_dwarves:
		if d.alive:
			survivors.append(d)
			
	# Limit survivors to a reasonable maximum (e.g. 50) to avoid crowding, but usually it stabilizes around 7-30
	if survivors.size() > 50:
		survivors = survivors.slice(0, 50)
		
	return survivors
