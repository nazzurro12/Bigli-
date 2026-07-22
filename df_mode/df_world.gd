extends RefCounted
class_name DFWorld

const DFWorkshop = preload("res://df_mode/df_workshop.gd")
const DFItem = preload("res://df_mode/df_item.gd")
const DFCreature = preload("res://df_mode/df_creature.gd")
const DFDwarf = preload("res://df_mode/df_dwarf.gd")
const DFPathfinding = preload("res://df_mode/df_pathfinding.gd")


enum TileType {
	FLOOR, WALL, WATER_DEEP, WATER_SHALLOW, TREE, RAMP,
	STAIRS_UP, STAIRS_DOWN, STAIRS_UPDOWN, CAVE_FLOOR, CAVE_WALL,
	MAGMA, BRIDGE, GRASS, DIRT, SAND, SNOW, ICE, STONE_FLOOR,
	SOIL, FARM_SOIL, MURKY_POOL, BROOK, FORTIFICATION,
	CONSTRUCTED_WALL, CONSTRUCTED_FLOOR, PATH
}

enum MatType {
	STONE, GRANITE, LIMESTONE, SANDSTONE, DIORITE, OBSIDIAN,
	MARBLE, GABBRO, SOIL, CLAY, SAND, COAL, IRON, GOLD, SILVER,
	COPPER, TIN, PLATINUM, WOOD, WATER, MAGMA, CONSTRUCTION
}

enum WeatherType {
	CLEAR, CLOUDY, RAIN, HEAVY_RAIN, STORM, SNOW, BLIZZARD,
	FOG, DRIZZLE, HAIL, WINDY, DUST_STORM
}

enum Season { SPRING, SUMMER, AUTUMN, WINTER }
enum DisasterType { NONE, CAVE_IN, FLOOD, FIRE, EARTHQUAKE, MAGMA_FLOOD, TORNADO }

const TILE_CHARS = {
	TileType.FLOOR: ".", TileType.WALL: "#", TileType.WATER_DEEP: "~",
	TileType.WATER_SHALLOW: "=", TileType.TREE: "\u25A3", TileType.RAMP: "\u25B2",
	TileType.STAIRS_UP: "<", TileType.STAIRS_DOWN: ">",
	TileType.STAIRS_UPDOWN: "\u25A1", TileType.CAVE_FLOOR: ".",
	TileType.CAVE_WALL: "#", TileType.MAGMA: "\u2588", TileType.BRIDGE: "=",
	TileType.GRASS: "\"", TileType.DIRT: ".", TileType.SAND: "\u2022",
	TileType.SNOW: "\u2219", TileType.ICE: "\u2591", TileType.STONE_FLOOR: "\u2591",
	TileType.SOIL: "\u2591", TileType.FARM_SOIL: "\u2592",
	TileType.MURKY_POOL: "o", TileType.BROOK: "\u2581",
	TileType.FORTIFICATION: "%", TileType.CONSTRUCTED_WALL: "\u2588",
	TileType.CONSTRUCTED_FLOOR: "\u2593", TileType.PATH: "\u2591"
}

const TILE_COLORS = {
	TileType.FLOOR: Color("#808080"), TileType.WALL: Color("#A0A0A0"),
	TileType.WATER_DEEP: Color("#0000AA"), TileType.WATER_SHALLOW: Color("#4444FF"),
	TileType.TREE: Color("#008000"), TileType.RAMP: Color("#8B4513"),
	TileType.STAIRS_UP: Color("#FFFFFF"), TileType.STAIRS_DOWN: Color("#FFFFFF"),
	TileType.STAIRS_UPDOWN: Color("#FFFFFF"), TileType.CAVE_FLOOR: Color("#505050"),
	TileType.CAVE_WALL: Color("#606060"), TileType.MAGMA: Color("#FF4400"),
	TileType.BRIDGE: Color("#8B7355"), TileType.GRASS: Color("#00AA00"),
	TileType.DIRT: Color("#8B6914"), TileType.SAND: Color("#DDCC55"),
	TileType.SNOW: Color("#FFFFFF"), TileType.ICE: Color("#CCFFFF"),
	TileType.STONE_FLOOR: Color("#707070"), TileType.SOIL: Color("#6B4226"),
	TileType.FARM_SOIL: Color("#5C3A1E"), TileType.MURKY_POOL: Color("#005500"),
	TileType.BROOK: Color("#4444FF"), TileType.FORTIFICATION: Color("#888888"),
	TileType.CONSTRUCTED_WALL: Color("#B0B0B0"),
	TileType.CONSTRUCTED_FLOOR: Color("#887755"), TileType.PATH: Color("#9B7944")
}

static var PLANT_TYPES = {
	"plump_helmet": {"name": "Plump Helmet", "glyph": "\u2219", "color": Color("#FF88AA"), "grow_time": 120, "food_yield": 3, "drink_yield": 5, "season": [0,1,2,3], "temperature_min": 0.2, "temperature_max": 1.0},
	"pig_tail": {"name": "Pig Tail", "glyph": "\u2219", "color": Color("#88FF88"), "grow_time": 150, "food_yield": 1, "drink_yield": 0, "season": [0,1,2,3], "temperature_min": 0.3, "temperature_max": 1.0},
	"cave_wheat": {"name": "Cave Wheat", "glyph": "\u2219", "color": Color("#FFFF88"), "grow_time": 180, "food_yield": 2, "drink_yield": 5, "season": [0,1,2,3], "temperature_min": 0.1, "temperature_max": 1.0},
	"sweet_pod": {"name": "Sweet Pod", "glyph": "\u2219", "color": Color("#FF88FF"), "grow_time": 200, "food_yield": 2, "drink_yield": 4, "season": [0,1,2,3], "temperature_min": 0.2, "temperature_max": 1.0},
	"quarry_bush": {"name": "Quarry Bush", "glyph": "\u2219", "color": Color("#88FFAA"), "grow_time": 250, "food_yield": 4, "drink_yield": 0, "season": [0,1,2,3], "temperature_min": 0.3, "temperature_max": 1.0},
	"cave_spineberry": {"name": "Spineberry", "glyph": "\u2219", "color": Color("#AA88FF"), "grow_time": 160, "food_yield": 2, "drink_yield": 2, "season": [0,1,2,3], "temperature_min": 0.0, "temperature_max": 0.6},
	"underground_glowcap": {"name": "Glowcap", "glyph": "\u2219", "color": Color("#88FFAA"), "grow_time": 300, "food_yield": 1, "drink_yield": 0, "season": [0,1,2,3], "temperature_min": 0.0, "temperature_max": 0.4}
}

static func _init_plants_from_data() -> void:
	var data = DFData.instance
	if data == null:
		return
	# Merge real crops from DFPlants data into PLANT_TYPES
	var real_crops = {
		"rice": {"name": "Rice", "glyph": "r", "color": Color("#EEDDAA"), "grow_time": 200, "food_yield": 3, "drink_yield": 4, "season": [0,1], "temperature_min": 0.5, "temperature_max": 1.0},
		"barley": {"name": "Barley", "glyph": "b", "color": Color("#DDCC88"), "grow_time": 160, "food_yield": 2, "drink_yield": 5, "season": [0,1,2], "temperature_min": 0.2, "temperature_max": 0.8},
		"maize": {"name": "Maize", "glyph": "m", "color": Color("#FFDD44"), "grow_time": 250, "food_yield": 4, "drink_yield": 2, "season": [1,2], "temperature_min": 0.5, "temperature_max": 1.0},
		"soft_wheat": {"name": "Soft Wheat", "glyph": "w", "color": Color("#EEDDBB"), "grow_time": 180, "food_yield": 3, "drink_yield": 5, "season": [0,1,2,3], "temperature_min": 0.2, "temperature_max": 0.9},
		"hard_wheat": {"name": "Hard Wheat", "glyph": "w", "color": Color("#DDCCAA"), "grow_time": 200, "food_yield": 2, "drink_yield": 4, "season": [0,2], "temperature_min": 0.1, "temperature_max": 0.7},
		"rye": {"name": "Rye", "glyph": "r", "color": Color("#CCBB99"), "grow_time": 170, "food_yield": 2, "drink_yield": 4, "season": [2,3], "temperature_min": 0.0, "temperature_max": 0.5},
		"oats": {"name": "Oats", "glyph": "o", "color": Color("#BBAA77"), "grow_time": 150, "food_yield": 2, "drink_yield": 2, "season": [0,2], "temperature_min": 0.1, "temperature_max": 0.6},
		"buckwheat": {"name": "Buckwheat", "glyph": "b", "color": Color("#AA9966"), "grow_time": 130, "food_yield": 2, "drink_yield": 3, "season": [1,2], "temperature_min": 0.2, "temperature_max": 0.8},
		"cotton": {"name": "Cotton", "glyph": "c", "color": Color("#FFFFFF"), "grow_time": 220, "food_yield": 0, "drink_yield": 0, "season": [1,2], "temperature_min": 0.5, "temperature_max": 1.0, "fiber_yield": 4},
		"flax": {"name": "Flax", "glyph": "f", "color": Color("#AADDFF"), "grow_time": 180, "food_yield": 0, "drink_yield": 0, "season": [0,1], "temperature_min": 0.3, "temperature_max": 0.8, "fiber_yield": 3},
		"hemp": {"name": "Hemp", "glyph": "h", "color": Color("#88CC88"), "grow_time": 200, "food_yield": 0, "drink_yield": 0, "season": [1,2], "temperature_min": 0.4, "temperature_max": 0.9, "fiber_yield": 5},
		"grapes": {"name": "Grapes", "glyph": "g", "color": Color("#8833AA"), "grow_time": 300, "food_yield": 2, "drink_yield": 8, "season": [1,2], "temperature_min": 0.4, "temperature_max": 0.9},
	}
	for key in real_crops:
		if not PLANT_TYPES.has(key):
			PLANT_TYPES[key] = real_crops[key]

const MATERIAL_COLORS = {
	MatType.STONE: Color("#808080"), MatType.GRANITE: Color("#888888"),
	MatType.LIMESTONE: Color("#C4B8A0"), MatType.SANDSTONE: Color("#D4C8A0"),
	MatType.DIORITE: Color("#707070"), MatType.OBSIDIAN: Color("#202020"),
	MatType.MARBLE: Color("#E0D8C8"), MatType.GABBRO: Color("#505050"),
	MatType.COAL: Color("#222222"), MatType.IRON: Color("#CC6633"),
	MatType.GOLD: Color("#FFCC00"), MatType.SILVER: Color("#C0C0C0"),
	MatType.COPPER: Color("#CC7733"), MatType.TIN: Color("#AA8866"),
	MatType.PLATINUM: Color("#DDDDCC"), MatType.WOOD: Color("#8B6914"),
	MatType.CONSTRUCTION: Color("#B0A090"), MatType.WATER: Color("#4444FF"),
	MatType.MAGMA: Color("#FF4400"), MatType.SAND: Color("#DDCC55"),
	MatType.CLAY: Color("#6B4226"), MatType.SOIL: Color("#6B4226")
}

const WEATHER_NAMES = {
	WeatherType.CLEAR: "Despejado", WeatherType.CLOUDY: "Nublado",
	WeatherType.RAIN: "Lluvia", WeatherType.HEAVY_RAIN: "Lluvia Fuerte",
	WeatherType.STORM: "Tormenta", WeatherType.SNOW: "Nieve",
	WeatherType.BLIZZARD: "Ventisca", WeatherType.FOG: "Niebla",
	WeatherType.DRIZZLE: "Llovizna", WeatherType.HAIL: "Granizo",
	WeatherType.WINDY: "Ventoso", WeatherType.DUST_STORM: "Tormenta de Polvo"
}

const SEASON_NAMES = { Season.SPRING: "Primavera", Season.SUMMER: "Verano", Season.AUTUMN: "Otoño", Season.WINTER: "Invierno" }

const WEATHER_COLORS = {
	WeatherType.CLEAR: Color("#87CEEB"), WeatherType.CLOUDY: Color("#A0A0A0"),
	WeatherType.RAIN: Color("#6666AA"), WeatherType.HEAVY_RAIN: Color("#444488"),
	WeatherType.STORM: Color("#333366"), WeatherType.SNOW: Color("#EEEEEE"),
	WeatherType.BLIZZARD: Color("#CCCCDD"), WeatherType.FOG: Color("#B0B0B0"),
	WeatherType.DRIZZLE: Color("#7777AA"), WeatherType.HAIL: Color("#AAAAAA"),
	WeatherType.WINDY: Color("#88AACC"), WeatherType.DUST_STORM: Color("#886644")
}

const BIOME_NAMES = {
	"ocean_deep": "Océano Profundo", "ocean_shallow": "Océano Somero",
	"beach": "Playa", "desert": "Desierto", "grassland": "Pradera",
	"swamp": "Pantano", "badlands": "Páramo", "savanna": "Sabana",
	"temperate_forest": "Bosque Templado", "dense_temperate_forest": "Bosque Denso",
	"rainforest": "Selva", "taiga": "Taiga", "pine_forest": "Bosque de Pinos",
	"mountain_forest": "Bosque Montañoso", "tundra": "Tundra",
	"alpine_meadow": "Prado Alpino", "glacier": "Glaciar"
}

var width: int = 128
var depth: int = 128
var height: int = 16
var elevation: Array = []
var tiles: Dictionary = {}
var materials: Dictionary = {}
var tile_data: Dictionary = {}
var entities: Array = []
var stockpiles: Array = []
var rivers: Array = []
var revealed: Dictionary = {}
var buildings: Array = []
var world_version: int = 0

var world_name: String = ""
var game_year: int = 63
var growing_crops: Dictionary = {}

var workshops: Array = []
var invasion_system = null
var military_system = null
var combat_system = null

# ---- WEATHER / CLIMATE SYSTEM ----
var current_weather: int = WeatherType.CLEAR
var weather_duration: int = 0
var weather_transition: int = 0
var wind_direction: Vector2 = Vector2(1, 0)
var wind_strength: float = 0.5
var fog_density: float = 0.0
var cloud_cover: float = 0.0
var lightning_flash: bool = false
var lightning_timer: int = 0
var ambient_temperature: float = 0.5
var ground_temperature: float = 0.5
var humidity: float = 0.5
var precipitation_intensity: float = 0.0

# ---- SEASON / TIME SYSTEM ----
var current_season: int = Season.SPRING
var season_day: int = 0
var season_length: int = 28
var year_day: int = 0
var year_length: int = 112
var day_time: float = 0.5
var is_daytime: bool = true
var dawn_timer: int = 0
var dusk_timer: int = 0

# ---- DISASTER SYSTEM ----
var active_disaster: int = DisasterType.NONE
var disaster_timer: int = 0
var disaster_pos: Vector3i = Vector3i(-1, -1, -1)
var disaster_intensity: float = 0.0
var disaster_radius: int = 0
var earthquake_tiles_remaining: int = 0
var cavein_queue: Array = []
var fire_tiles: Dictionary = {}
var flood_tiles: Array = []

# ---- FLUID SIMULATION ----
var fluid_levels: Dictionary = {}
var fluid_flow_map: Dictionary = {}
var evaporation_rate: float = 0.01
var fluid_update_interval: int = 10
var fluid_tick_counter: int = 0
var messages: Array = []

func add_message(msg: String) -> void:
	messages.append(msg)

# ---- TREE / NATURE SYSTEM ----
var tree_data: Dictionary = {}
var tree_growth_timer: int = 0
var tree_growth_interval: int = 50
var grass_growth_timer: int = 0
var leaf_litter: Dictionary = {}

# ---- ENVIRONMENTAL EFFECTS ----
var light_level: float = 1.0
var outdoor_exposure: Dictionary = {}
var erosion_timer: int = 0

# splatters maps Vector3i -> Dictionary[substance_id:String -> volume:float]
# Known substances: "blood", "beer", "vomit", "pathogen", "poison", "water", "mud", "alcohol", "pus"
var splatters: Dictionary = {}

# ---- MATERIAL POROSITY for fluid absorption ----
const POROSITY_MAP = {
	TileType.SOIL: 0.8, TileType.DIRT: 0.7, TileType.SAND: 0.9,
	TileType.GRASS: 0.6, TileType.FARM_SOIL: 0.7, TileType.CAVE_FLOOR: 0.3,
	TileType.STONE_FLOOR: 0.05, TileType.FLOOR: 0.1, TileType.CONSTRUCTED_FLOOR: 0.05,
	TileType.BRIDGE: 0.1, TileType.PATH: 0.3, TileType.SNOW: 0.9, TileType.ICE: 0.0
}

func get_material_porosity_at(pos: Vector3i) -> float:
	var mat_enum = get_material(pos)
	var mat_id = DFMaterialProperties.enum_to_id(mat_enum)
	var props = DFMaterialProperties.compute_by_id(mat_id)
	return props.get("porosity", POROSITY_MAP.get(get_tile(pos), 0.1))

func get_material_flammability_at(pos: Vector3i) -> float:
	var mat_enum = get_material(pos)
	var mat_id = DFMaterialProperties.enum_to_id(mat_enum)
	var props = DFMaterialProperties.compute_by_id(mat_id)
	return props.get("flammability", 0.0)

func get_material_melting_point_at(pos: Vector3i) -> float:
	var mat_enum = get_material(pos)
	var mat_id = DFMaterialProperties.enum_to_id(mat_enum)
	var props = DFMaterialProperties.compute_by_id(mat_id)
	return props.get("melting_point", 0.0)

func get_material_density_at(pos: Vector3i) -> float:
	var mat_enum = get_material(pos)
	var mat_id = DFMaterialProperties.enum_to_id(mat_enum)
	var props = DFMaterialProperties.compute_by_id(mat_id)
	return props.get("density", 2.5)
const SUBSTANCE_COLORS = {
	"beer": Color("#DAA520"), "blood": Color("#CC0000"), "vomit": Color("#8B8B00"),
	"water": Color("#4488FF"), "mud": Color("#8B6914"), "poison": Color("#AA00AA"),
	"pathogen": Color("#00AA44"), "alcohol": Color("#DAA520"), "pus": Color("#88AA44"),
	"miasma": Color("#8A2BE2") # Purple gas
}
const SUBSTANCE_NAMES = {
	"beer": "Cerveza", "blood": "Sangre", "vomit": "Vómito",
	"water": "Agua", "mud": "Lodo", "poison": "Veneno",
	"pathogen": "Patógeno", "alcohol": "Alcohol", "pus": "Pus",
	"miasma": "Miasma"
}

func _init(w: int = 128, d: int = 128, h: int = 16):
	width = w; depth = d; height = h
	rivers = []
	buildings = []
	entities = []
	stockpiles = []
	workshops = []

# ---- TILE QUERIES ----
func get_tile(pos: Vector3i) -> int:
	return tiles.get(pos, TileType.CAVE_WALL if pos.y <= 0 else TileType.FLOOR if pos.y == 0 else TileType.CAVE_FLOOR)

func set_tile(pos: Vector3i, tile_type: int) -> void:
	tiles[pos] = tile_type
	world_version += 1
	DFPathfinding.bump_world_version()

func get_material(pos: Vector3i) -> int:
	return materials.get(pos, MatType.STONE)

func set_material(pos: Vector3i, mat: int) -> void:
	materials[pos] = mat

func get_tile_data(pos: Vector3i) -> Dictionary:
	return tile_data.get(pos, {})

func set_tile_data(pos: Vector3i, data: Dictionary) -> void:
	tile_data[pos] = data
	world_version += 1
	DFPathfinding.bump_world_version()

func is_revealed(pos: Vector3i) -> bool:
	return revealed.get(pos, false)

func set_revealed(pos: Vector3i, val: bool) -> void:
	if val: revealed[pos] = true
	else: revealed.erase(pos)

func is_blocked(pos: Vector3i) -> bool:
	var t = get_tile(pos)
	return t in [TileType.WALL, TileType.CAVE_WALL, TileType.TREE, TileType.CONSTRUCTED_WALL, TileType.FORTIFICATION] or \
		(t in [TileType.WATER_DEEP] and pos.y >= 0) or \
		(t in [TileType.MAGMA] and pos.y >= 0)

func is_wall(pos: Vector3i) -> bool:
	var t = get_tile(pos)
	return t in [TileType.WALL, TileType.CAVE_WALL, TileType.CONSTRUCTED_WALL, TileType.FORTIFICATION]

func is_floor(pos: Vector3i) -> bool:
	var t = get_tile(pos)
	return t in [TileType.FLOOR, TileType.CAVE_FLOOR, TileType.GRASS, TileType.DIRT,
		TileType.SAND, TileType.STONE_FLOOR, TileType.SOIL, TileType.FARM_SOIL,
		TileType.BRIDGE, TileType.SNOW, TileType.ICE, TileType.CONSTRUCTED_FLOOR, TileType.PATH]

func is_open_space(pos: Vector3i) -> bool:
	return not tiles.has(pos)

func is_water(pos: Vector3i) -> bool:
	return get_tile(pos) in [TileType.WATER_DEEP, TileType.WATER_SHALLOW, TileType.BROOK, TileType.MURKY_POOL]

func is_liquid(pos: Vector3i) -> bool:
	var t = get_tile(pos)
	return t in [TileType.WATER_DEEP, TileType.WATER_SHALLOW, TileType.BROOK, TileType.MURKY_POOL, TileType.MAGMA]

func find_path(from: Vector3i, to: Vector3i, use_dwarf_rules: bool = true) -> Array:
	return DFPathfinding.find_path(self, from, to, use_dwarf_rules)

func has_path(from: Vector3i, to: Vector3i, use_dwarf_rules: bool = true) -> bool:
	return not find_path(from, to, use_dwarf_rules).is_empty()

func is_stair(pos: Vector3i) -> bool:
	var t = get_tile(pos)
	return t in [TileType.STAIRS_UP, TileType.STAIRS_DOWN, TileType.STAIRS_UPDOWN, TileType.RAMP]

func is_outdoor(pos: Vector3i) -> bool:
	var y = pos.y
	var surf = get_surface_height(pos.x, pos.z) if pos.x >= 0 and pos.x < width and pos.z >= 0 and pos.z < depth else 0
	return y >= surf - 1

func is_subterranean(pos: Vector3i) -> bool:
	return not is_outdoor(pos)

# ---- ELEVATION ----
func get_surface_height(x: int, z: int) -> int:
	if x < 0 or x >= width or z < 0 or z >= depth: return 0
	if z >= elevation.size() or z < 0: return 0
	if x >= elevation[z].size() or x < 0: return 0
	return elevation[z][x]

# ---- ENTITY HELPERS ----
func get_entity_at(pos: Vector3i):
	for e in entities:
		var is_alive = e.get("is_alive")
		if e.tile_pos == pos and (is_alive == null or is_alive == true):
			return e
	return null

func get_dwarf_by_id(dwarf_id: int):
	for e in entities:
		if e is DFDwarf and e.id == dwarf_id:
			return e
	return null

func get_hostile_entities_at(pos: Vector3i, exclude_id: int = -1) -> Array:
	var result = []
	for e in entities:
		var is_hostile = e.get("is_hostile") == true
		var is_alive = e.get("is_alive")
		if e.tile_pos == pos and (is_alive == null or is_alive == true) and is_hostile and e.id != exclude_id:
			result.append(e)
	return result

func get_creatures_at(pos: Vector3i, creature_type: String = "") -> Array:
	var result = []
	for e in entities:
		if e.tile_pos != pos: continue
		var is_alive = e.get("is_alive")
		if is_alive != null and is_alive == false: continue
		if creature_type != "" and e.get("creature_type") != creature_type: continue
		if e.get("creature_type") != null:
			result.append(e)
	return result

func get_items_at(pos: Vector3i) -> Array:
	var result = []
	for e in entities:
		if e is DFItem and e.tile_pos == pos:
			result.append(e)
	return result

func count_entities_of_type(ctype: String) -> int:
	var count = 0
	for e in entities:
		if e.get("creature_type") == ctype:
			var a = e.get("is_alive")
			if a == null or a == true:
				count += 1
	return count

# ---- WORKSHOPS ----
func get_workshop_at(pos: Vector3i):
	for w in workshops:
		if w.tile_pos == pos:
			return w
	return null

func create_workshop(type: int, pos: Vector3i):
	var workshop = DFWorkshop.new(type, pos)
	workshops.append(workshop)
	set_tile(pos, TileType.CONSTRUCTED_FLOOR)
	return workshop

# ---- DIG / CHOP / BUILD ----
func dig_tile(pos: Vector3i) -> bool:
	var t = get_tile(pos)
	if t == TileType.WALL or t == TileType.CAVE_WALL:
		var mat = get_material(pos)
		var above_pos = Vector3i(pos.x, pos.y + 1, pos.z)
		var above_t = get_tile(above_pos)
		if above_t in [TileType.FLOOR, TileType.CAVE_FLOOR, TileType.GRASS, TileType.DIRT, TileType.SAND, TileType.SOIL]:
			set_tile(pos, TileType.RAMP)
		else:
			set_tile(pos, TileType.STONE_FLOOR if t == TileType.WALL else TileType.CAVE_FLOOR)
		set_material(pos, mat)
		set_revealed(pos, true)
		_check_cavein(pos)
		var item_type = "stone"
		var item_name = "Escombro de Roca"
		if mat == MatType.IRON: item_type = "iron_ore"; item_name = "Mena de Hierro"
		elif mat == MatType.COAL: item_type = "coal_ore"; item_name = "Carbon"
		elif mat == MatType.GOLD: item_type = "gold_ore"; item_name = "Mena de Oro"
		elif mat == MatType.COPPER: item_type = "copper_ore"; item_name = "Mena de Cobre"
		elif mat == MatType.SILVER: item_type = "silver_ore"; item_name = "Mena de Plata"
		elif mat == MatType.TIN: item_type = "tin_ore"; item_name = "Mena de Estaño"
		elif mat == MatType.PLATINUM: item_type = "platinum_ore"; item_name = "Mena de Platino"
		_spawn_item(pos, item_name, item_type, mat, "*", get_tile_color(pos))
		return true
	return false

func chop_tree(pos: Vector3i, chopper_pos: Vector3i = Vector3i(-999, -999, -999)) -> bool:
	if get_tile(pos) == TileType.TREE:
		set_tile(pos, TileType.GRASS)
		set_material(pos, MatType.SOIL)
		tree_data.erase(pos)
		tile_data.erase(pos)
		
		# Determine spawn position 1 tile away from both chopper and tree
		var spawn_pos = _find_wood_spawn_pos(pos, chopper_pos)
		
		# Spawn exactly 1 log of 2 meters
		_spawn_item(spawn_pos, "Tronco de 2 metros", "wood", MatType.WOOD, "=", Color("#8B5A2B"))
		
		return true
	return false

func _find_wood_spawn_pos(tree_pos: Vector3i, chopper_pos: Vector3i) -> Vector3i:
	var candidates = []
	for dx in [-1, 0, 1]:
		for dz in [-1, 0, 1]:
			if dx == 0 and dz == 0:
				continue
			var p1 = tree_pos + Vector3i(dx, 0, dz)
			# Check boundaries
			if p1.x < 0 or p1.x >= width or p1.z < 0 or p1.z >= depth:
				continue
			# Check if it's the chopper's pos
			if p1 == chopper_pos:
				continue
			# Check if adjacent to chopper
			if chopper_pos != Vector3i(-999, -999, -999):
				if abs(p1.x - chopper_pos.x) > 1 or abs(p1.z - chopper_pos.z) > 1:
					continue
			# Check if not blocked
			if not is_blocked(p1):
				candidates.append(p1)
	
	if candidates.size() > 0:
		return candidates[randi() % candidates.size()]
		
	# Fallback to any tile adjacent to tree that is not blocked and not chopper_pos
	candidates.clear()
	for fdx in [-1, 0, 1]:
		for fdz in [-1, 0, 1]:
			if fdx == 0 and fdz == 0:
				continue
			var p2 = tree_pos + Vector3i(fdx, 0, fdz)
			if p2.x < 0 or p2.x >= width or p2.z < 0 or p2.z >= depth:
				continue
			if p2 == chopper_pos:
				continue
			if not is_blocked(p2):
				candidates.append(p2)
				
	if candidates.size() > 0:
		return candidates[randi() % candidates.size()]
		
	# Fallback to tree_pos itself
	return tree_pos

func _spawn_item(pos: Vector3i, iname: String, itype: String, mat: int, glyph: String, color: Color) -> DFItem:
	var item = DFItem.new(pos, iname, itype, mat, glyph, color)
	entities.append(item)
	return item

# ---- CONSTRUCTION ----
func build_wall(pos: Vector3i, mat_id: int = MatType.CONSTRUCTION) -> bool:
	if is_floor(pos) or is_open_space(pos):
		var old_t = get_tile(pos)
		set_tile(pos, TileType.CONSTRUCTED_WALL)
		set_material(pos, mat_id)
		set_revealed(pos, true)
		var above = Vector3i(pos.x, pos.y + 1, pos.z)
		set_revealed(above, true)
		tile_data[pos] = tile_data.get(pos, {})
		tile_data[pos]["constructed_material"] = mat_id
		if old_t == TileType.GRASS:
			tile_data[pos]["built_on_grass"] = true
		return true
	return false

func build_floor(pos: Vector3i, mat_id: int = MatType.CONSTRUCTION) -> bool:
	if is_open_space(pos) or is_wall(pos):
		set_tile(pos, TileType.CONSTRUCTED_FLOOR)
		set_material(pos, mat_id)
		set_revealed(pos, true)
		tile_data[pos] = tile_data.get(pos, {})
		tile_data[pos]["constructed_material"] = mat_id
		return true
	return false

func build_stairs_up(pos: Vector3i) -> bool:
	if is_wall(pos) or is_floor(pos):
		set_tile(pos, TileType.STAIRS_UP)
		set_revealed(pos, true)
		var above = Vector3i(pos.x, pos.y + 1, pos.z)
		set_tile(above, TileType.STAIRS_DOWN)
		set_revealed(above, true)
		return true
	return false

func build_stairs_down(pos: Vector3i) -> bool:
	if is_wall(pos) or is_floor(pos):
		set_tile(pos, TileType.STAIRS_DOWN)
		set_revealed(pos, true)
		var below = Vector3i(pos.x, pos.y - 1, pos.z)
		if not tiles.has(below) or get_tile(below) == TileType.CAVE_WALL:
			set_tile(below, TileType.CAVE_FLOOR)
			set_revealed(below, true)
		set_tile(below, TileType.STAIRS_UP)
		set_revealed(below, true)
		return true
	return false

func build_bridge(pos: Vector3i, mat_id: int = MatType.CONSTRUCTION) -> bool:
	if is_water(pos) or is_open_space(pos):
		set_tile(pos, TileType.BRIDGE)
		set_material(pos, mat_id)
		set_revealed(pos, true)
		return true
	return false

func smooth_tile(pos: Vector3i) -> bool:
	var t = get_tile(pos)
	if t == TileType.STONE_FLOOR or t == TileType.CAVE_FLOOR:
		tile_data[pos] = tile_data.get(pos, {})
		tile_data[pos]["smoothed"] = true
		return true
	return false

func carve_fortification(pos: Vector3i) -> bool:
	var t = get_tile(pos)
	if t in [TileType.WALL, TileType.CAVE_WALL, TileType.CONSTRUCTED_WALL, TileType.STONE_FLOOR]:
		var mat = get_material(pos)
		set_tile(pos, TileType.FORTIFICATION)
		set_material(pos, mat)
		return true
	return false

# ---- FARMING ----
func make_farm_plot(pos: Vector3i) -> bool:
	var t = get_tile(pos)
	if t in [TileType.SOIL, TileType.DIRT, TileType.GRASS, TileType.FLOOR, TileType.CAVE_FLOOR]:
		set_tile(pos, TileType.FARM_SOIL)
		set_revealed(pos, true)
		tile_data[pos] = tile_data.get(pos, {})
		tile_data[pos]["farm_quality"] = 1.0
		return true
	return false

func plant_crop(pos: Vector3i, plant_type: String) -> bool:
	if get_tile(pos) != TileType.FARM_SOIL: return false
	if growing_crops.has(pos): return false
	var pdata = PLANT_TYPES.get(plant_type)
	if pdata == null: return false
	var td = tile_data.get(pos, {})
	var season_ok = current_season in pdata["season"]
	var temp_ok = ambient_temperature >= pdata["temperature_min"] and ambient_temperature <= pdata["temperature_max"]
	var growth_mod = 0.5
	if season_ok: growth_mod += 0.3
	if temp_ok: growth_mod += 0.2
	growing_crops[pos] = {"type": plant_type, "timer": 0, "max_time": int(pdata.grow_time / growth_mod), "growth_stage": 0}
	return true

func tick_plants() -> void:
	var ready_to_harvest = []
	for pos in growing_crops.keys():
		var crop = growing_crops[pos]
		crop["timer"] += 1
		var stage_count = 4
		var new_stage = int(crop["timer"] * stage_count / crop["max_time"])
		if new_stage != crop["growth_stage"]:
			crop["growth_stage"] = new_stage
			tile_data[pos] = tile_data.get(pos, {})
			tile_data[pos]["growth"] = new_stage
		if crop["timer"] >= crop["max_time"]:
			ready_to_harvest.append(pos)
	for harvest_pos in ready_to_harvest:
		var harvest_crop = growing_crops[harvest_pos]
		var pdata = PLANT_TYPES.get(harvest_crop["type"])
		if pdata != null:
			var item_name = pdata["name"]
			var yield_mod = 1.0
			var td = tile_data.get(harvest_pos, {})
			if td.get("farm_quality", 1.0) > 1.5: yield_mod = 1.5
			elif td.get("farm_quality", 1.0) < 0.5: yield_mod = 0.5
			for fi in range(int(pdata["food_yield"] * yield_mod)):
				_spawn_item(harvest_pos, item_name, "food", 0, "%", Color("#FF8844"))
			if pdata["drink_yield"] > 0:
				var drink_count = int(pdata["drink_yield"] * yield_mod)
				for di in range(drink_count):
					_spawn_item(harvest_pos, "Dwarven Ale", "drink", 0, "~", Color("#FFCC00"))
		growing_crops.erase(harvest_pos)
		tile_data[harvest_pos] = tile_data.get(harvest_pos, {})
		tile_data[harvest_pos]["harvested"] = true

func is_grown_crop(pos: Vector3i) -> bool:
	return growing_crops.has(pos) and growing_crops[pos]["timer"] >= growing_crops[pos]["max_time"]

# ---- WEATHER SYSTEM ----
func tick_weather() -> void:
	weather_duration -= 1
	if weather_duration <= 0:
		_change_weather()
	if lightning_timer > 0: lightning_timer -= 1
	else: lightning_flash = false
	if current_weather == WeatherType.STORM and randi() % 50 == 0:
		lightning_flash = true
		lightning_timer = 2
		_apply_lightning_strike()
	var temp_drift = randf_range(-0.01, 0.01)
	ambient_temperature = clampf(ambient_temperature + temp_drift, 0.0, 1.0)
	humidity = clampf(humidity + randf_range(-0.005, 0.01), 0.0, 1.0)
	cloud_cover = clampf(cloud_cover + randf_range(-0.02, 0.02), 0.0, 1.0)
	_apply_weather_effects()

func _change_weather() -> void:
	var weather_weights = {}
	for wt in WeatherType.values():
		weather_weights[wt] = 1.0
	weather_weights[WeatherType.CLEAR] = 25.0
	weather_weights[WeatherType.CLOUDY] = 20.0
	weather_weights[WeatherType.RAIN] = 10.0
	weather_weights[WeatherType.DRIZZLE] = 8.0
	weather_weights[WeatherType.FOG] = 5.0
	weather_weights[WeatherType.WINDY] = 5.0
	if ambient_temperature < 0.3:
		weather_weights[WeatherType.SNOW] = 12.0
		weather_weights[WeatherType.BLIZZARD] = 3.0
		weather_weights[WeatherType.RAIN] = 2.0
	if ambient_temperature > 0.7 and humidity < 0.3:
		weather_weights[WeatherType.DUST_STORM] = 2.0
	if humidity > 0.7:
		weather_weights[WeatherType.RAIN] = 15.0
		weather_weights[WeatherType.HEAVY_RAIN] = 8.0
		weather_weights[WeatherType.STORM] = 5.0
	if current_season == Season.WINTER:
		weather_weights[WeatherType.CLEAR] = 10.0
		weather_weights[WeatherType.SNOW] = 18.0
		weather_weights[WeatherType.RAIN] = 2.0
	elif current_season == Season.SUMMER:
		weather_weights[WeatherType.RAIN] = 12.0
		weather_weights[WeatherType.HEAVY_RAIN] = 8.0
		weather_weights[WeatherType.STORM] = 6.0
	var total = 0.0
	for w in weather_weights.values(): total += w
	var roll = randf() * total
	var cumulative = 0.0
	for wt2 in WeatherType.values():
		cumulative += weather_weights.get(wt2, 1.0)
		if roll <= cumulative:
			current_weather = wt2
			break
	weather_duration = randi_range(20, 120)
	weather_transition = 5
	precipitation_intensity = 0.0
	if current_weather in [WeatherType.RAIN, WeatherType.HEAVY_RAIN, WeatherType.STORM]:
		precipitation_intensity = randf_range(0.3, 1.0)
	elif current_weather in [WeatherType.SNOW, WeatherType.BLIZZARD]:
		precipitation_intensity = randf_range(0.4, 1.0)
	elif current_weather == WeatherType.DRIZZLE:
		precipitation_intensity = 0.1 + randf() * 0.2
	elif current_weather == WeatherType.FOG:
		fog_density = randf_range(0.3, 0.8)
		precipitation_intensity = 0.0
	else:
		precipitation_intensity = 0.0
		fog_density = 0.0
	if current_weather == WeatherType.WINDY:
		wind_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		wind_strength = randf_range(0.5, 1.0)
	else:
		wind_strength *= 0.8 + randf() * 0.4

func _apply_weather_effects() -> void:
	if current_weather in [WeatherType.RAIN, WeatherType.HEAVY_RAIN, WeatherType.STORM]:
		_apply_rain()
		_rain_wash_splatters()
	elif current_weather in [WeatherType.SNOW, WeatherType.BLIZZARD]:
		_apply_snow()
	if current_weather == WeatherType.DUST_STORM:
		_apply_dust_storm()
	if current_weather == WeatherType.WINDY or current_weather == WeatherType.STORM:
		_wind_spread_pathogens()
	_wind_evaporate_splatters()

func _apply_rain() -> void:
	for z in range(depth):
		for x in range(width):
			var pos = Vector3i(x, get_surface_height(x, z), z)
			if get_tile(pos) not in [TileType.GRASS, TileType.DIRT, TileType.SOIL, TileType.SAND, TileType.SNOW]:
				continue
			if randi() % 100 < int(precipitation_intensity * 15):
				var td = tile_data.get(pos, {})
				td["wetness"] = td.get("wetness", 0.0) + precipitation_intensity * 0.1
				tile_data[pos] = td
				if td["wetness"] >= 1.0 and get_tile(pos) == TileType.GRASS:
					if randi() % 200 == 0:
						_spawn_item(pos, "Agua Estancada", "water", MatType.WATER, "~", Color("#4444FF"))
	var water_tiles_to_add = int(precipitation_intensity * 2)
	for i in range(water_tiles_to_add):
		var rx = randi() % width; var rz = randi() % depth
		var rh = get_surface_height(rx, rz)
		var rp = Vector3i(rx, rh, rz)
		if get_tile(rp) == TileType.MURKY_POOL:
			_increase_fluid_level(rp, precipitation_intensity)

func _apply_snow() -> void:
	for z in range(depth):
		for x in range(width):
			if randi() % 30 < int(precipitation_intensity * 10):
				var pos = Vector3i(x, get_surface_height(x, z), z)
				if get_tile(pos) in [TileType.GRASS, TileType.DIRT, TileType.SOIL, TileType.SAND, TileType.FLOOR]:
					var td = tile_data.get(pos, {})
					td["snow_cover"] = minf(td.get("snow_cover", 0.0) + 0.1, 1.0)
					tile_data[pos] = td
					if td["snow_cover"] >= 0.8:
						set_tile(pos, TileType.SNOW)
						set_material(pos, MatType.WATER)

func _apply_dust_storm() -> void:
	for z in range(depth):
		for x in range(width):
			if randi() % 50 == 0:
				var pos = Vector3i(x, get_surface_height(x, z), z)
				if get_tile(pos) == TileType.GRASS:
					set_tile(pos, TileType.DIRT)

func _apply_lightning_strike() -> void:
	var lx = randi() % width; var lz = randi() % depth
	var ly = get_surface_height(lx, lz)
	var target = Vector3i(lx, ly, lz)
	for e in entities:
		var alive = e.get("is_alive")
		if e.tile_pos == target and (alive == null or alive == true):
			if combat_system != null:
				var target_name = e.get("name")
				if target_name == null:
					target_name = "algo"
				combat_system._add_log("¡Un rayo golpea a %s!" % target_name)
			if e.has_method("add_thought"):
				e.add_thought("¡Fue golpeado por un rayo!", -0.4)
			if e.get("health") != null:
				e.health = max(0.0, e.health - 0.5)
	if get_tile(target) in [TileType.GRASS, TileType.DIRT, TileType.SOIL, TileType.TREE]:
		if randi() % 3 == 0:
			_start_fire(target)

func _rain_wash_splatters() -> void:
	var intensity = precipitation_intensity
	if intensity <= 0: return
	var to_remove = []
	for pos in splatters.keys():
		if pos.y < get_surface_height(pos.x, pos.z) - 1: continue
		if randi() % 100 < int(intensity * 30):
			var puddle: Dictionary = splatters[pos]
			for s in puddle.keys():
				puddle[s] = maxf(0.0, puddle[s] - intensity * 0.03)
				if puddle[s] <= 0.0: puddle.erase(s)
			if puddle.is_empty(): to_remove.append(pos)
	for erase_pos in to_remove: splatters.erase(erase_pos)

func _wind_spread_pathogens() -> void:
	var spread = false
	for pos in splatters.keys():
		var puddle: Dictionary = splatters[pos]
		if puddle.has("pathogen") and puddle["pathogen"] > 0.01:
			var dx = randi() % 3 - 1 + int(wind_direction.x * 2)
			var dz = randi() % 3 - 1 + int(wind_direction.y * 2)
			var new_pos = Vector3i(pos.x + dx, pos.y, pos.z + dz)
			if new_pos.x >= 0 and new_pos.x < width and new_pos.z >= 0 and new_pos.z < depth:
				add_splatter_substance(new_pos, "pathogen", puddle["pathogen"] * 0.02)
				spread = true
	if spread and combat_system != null:
		if randi() % 10 == 0:
			combat_system._add_log("El viento propaga partículas infecciosas.")

func _wind_evaporate_splatters() -> void:
	for pos in splatters.keys():
		var puddle: Dictionary = splatters[pos]
		for s in puddle.keys():
			if s == "vomit" or s == "water" or s == "beer":
				var evap = 0.005 + wind_strength * 0.01
				puddle[s] = maxf(0.0, puddle[s] - evap)
				if puddle[s] <= 0.0: puddle.erase(s)
		if puddle.is_empty(): splatters.erase(pos)

func tick_item_decay_global() -> void:
	for e in entities:
		if e is DFItem:
			e.tick_decay()

func tick_corpse_rotting() -> void:
	for e in entities:
		if e is DFItem and e.get("is_corpse") == true:
			e.tick_decay()
			# Miasma emission from decomposing corpses
			var miasma_chance = 0.12 if not is_outdoor(e.tile_pos) else 0.02
			if randf() < miasma_chance:
				add_splatter_substance(e.tile_pos, "miasma", 0.08)
		if e.has_method("get_body") and e.body != null:
			var body_obj = e.body
			if e.get("is_alive") == false and body_obj.blood_level > 0:
				body_obj.blood_level = maxf(0.0, body_obj.blood_level - 0.1)
				if body_obj.blood_level < 0.5 and randi() % 10 == 0:
					add_splatter_substance(e.tile_pos, "blood", 0.01)

func is_raining() -> bool:
	return current_weather in [WeatherType.RAIN, WeatherType.HEAVY_RAIN, WeatherType.STORM, WeatherType.DRIZZLE]

func get_wind_strength_label() -> String:
	if wind_strength < 0.2: return "Calma"
	elif wind_strength < 0.4: return "Brisa"
	elif wind_strength < 0.6: return "Ventoso"
	elif wind_strength < 0.8: return "Fuerte"
	else: return "Tormenta"
	return WEATHER_NAMES.get(current_weather, "Desconocido")

func get_weather_name() -> String:
	return WEATHER_NAMES.get(current_weather, "Desconocido")

func get_game_year() -> int:
	return game_year

func get_weather_color() -> Color:
	return WEATHER_COLORS.get(current_weather, Color.WHITE)

# ---- FLUID SIMULATION ----
func _increase_fluid_level(pos: Vector3i, amount: float) -> void:
	var current = fluid_levels.get(pos, 0.0)
	fluid_levels[pos] = minf(current + amount, 7.0)

func _decrease_fluid_level(pos: Vector3i, amount: float) -> void:
	var current = fluid_levels.get(pos, 0.0)
	fluid_levels[pos] = maxf(current - amount, 0.0)
	if fluid_levels[pos] <= 0:
		fluid_levels.erase(pos)

func get_fluid_level(pos: Vector3i) -> float:
	return fluid_levels.get(pos, 0.0)

func tick_fluids() -> void:
	fluid_tick_counter += 1
	if fluid_tick_counter < fluid_update_interval: return
	fluid_tick_counter = 0
	var flow_changes = {}
	for pos in fluid_levels.keys():
		var level = fluid_levels[pos]
		if level <= 0: continue
		var lowest_dir = Vector3i(0, -1, 0)
		var lowest_level = fluid_levels.get(pos + Vector3i(0, -1, 0), -1.0)
		var dirs = [Vector3i(0, -1, 0), Vector3i(-1, 0, 0), Vector3i(1, 0, 0), Vector3i(0, 0, -1), Vector3i(0, 0, 1)]
		for d in dirs:
			var n = pos + d
			if is_blocked(n) and get_tile(n) not in [TileType.WATER_DEEP, TileType.WATER_SHALLOW, TileType.MAGMA]:
				continue
			var nl = fluid_levels.get(n, -1.0)
			if nl < lowest_level:
				lowest_level = nl
				lowest_dir = d
		if lowest_level < level and lowest_dir != Vector3i(0, 0, 0):
			var transfer = (level - lowest_level) * 0.5
			transfer = maxf(0.1, minf(transfer, level * 0.5))
			if not flow_changes.has(pos): flow_changes[pos] = 0.0
			if not flow_changes.has(pos + lowest_dir): flow_changes[pos + lowest_dir] = 0.0
			flow_changes[pos] -= transfer
			flow_changes[pos + lowest_dir] += transfer
	for flow_pos in flow_changes.keys():
		var delta = flow_changes[flow_pos]
		var current = fluid_levels.get(flow_pos, 0.0)
		var new_level = current + delta
		if new_level <= 0:
			fluid_levels.erase(flow_pos)
			if get_tile(flow_pos) in [TileType.WATER_DEEP, TileType.WATER_SHALLOW, TileType.MURKY_POOL]:
				if get_tile(flow_pos) == TileType.MURKY_POOL:
					set_tile(flow_pos, TileType.GRASS)
		else:
			fluid_levels[flow_pos] = minf(new_level, 7.0)
			if new_level > 3 and get_tile(flow_pos) != TileType.MAGMA:
				set_tile(flow_pos, TileType.WATER_SHALLOW)
			if new_level > 5:
				set_tile(flow_pos, TileType.WATER_DEEP)
	_evaporate_fluids()
	_check_fluid_flooding()
	tick_splatters()

func _evaporate_fluids() -> void:
	var to_remove = []
	for pos in fluid_levels.keys():
		if is_outdoor(pos) and ambient_temperature > 0.4:
			var evap = evaporation_rate * (1.0 + ambient_temperature * 2.0)
			var current = fluid_levels[pos]
			var new_level = current - evap
			if new_level <= 0:
				to_remove.append(pos)
				if get_tile(pos) in [TileType.WATER_DEEP, TileType.WATER_SHALLOW]:
					set_tile(pos, TileType.GRASS)
			else:
				fluid_levels[pos] = new_level
	for pos2 in to_remove:
		fluid_levels.erase(pos2)

func _check_fluid_flooding() -> void:
	for pos in fluid_levels.keys():
		if fluid_levels[pos] >= 6.0:
			for d in [Vector3i(-1, 0, 0), Vector3i(1, 0, 0), Vector3i(0, 0, -1), Vector3i(0, 0, 1)]:
				var n = pos + d
				if not fluid_levels.has(n) and not is_blocked(n):
					fluid_levels[n] = 0.5

# ---- FIRE SYSTEM ----
var fire_spread_counter: int = 0

func _start_fire(pos: Vector3i) -> void:
	fire_tiles[pos] = {"intensity": 1.0, "fuel": 1.0}

func tick_fires() -> void:
	fire_spread_counter += 1
	var to_remove = []
	var to_add = []
	for pos in fire_tiles.keys():
		var fire = fire_tiles[pos]
		fire["intensity"] += 0.1
		fire["fuel"] -= 0.05
		if fire["fuel"] <= 0:
			to_remove.append(pos)
			var t = get_tile(pos)
			if t == TileType.TREE:
				set_tile(pos, TileType.GRASS)
				_spawn_item(pos, "Cenizas", "ash", MatType.SOIL, ".", Color("#444444"))
			continue
		var t2 = get_tile(pos)
		if t2 == TileType.TREE: fire["intensity"] += 0.5
		if t2 in [TileType.GRASS, TileType.DIRT, TileType.SOIL, TileType.SNOW]:
			fire["intensity"] -= 0.3
		if fire["intensity"] <= 0:
			to_remove.append(pos)
			continue
		if is_water(pos) or get_tile(pos) == TileType.MAGMA:
			to_remove.append(pos)
			continue
		if fire_spread_counter % 5 == 0:
			for d in [Vector3i(-1, 0, 0), Vector3i(1, 0, 0), Vector3i(0, 0, -1), Vector3i(0, 0, 1)]:
				var n = pos + d
				var flam = get_material_flammability_at(n)
				if flam > 0.3:
					if randi() % 3 == 0:
						to_add.append(n)
		if randi() % 10 == 0 and t2 == TileType.TREE:
			combat_system._add_log("Un árbol arde en llamas cerca de la fortaleza.")
	for erase_pos in to_remove:
		fire_tiles.erase(erase_pos)
		tile_data[erase_pos] = tile_data.get(erase_pos, {})
		tile_data[erase_pos]["burnt"] = true
	for add_pos in to_add:
		_start_fire(add_pos)

func is_burning(pos: Vector3i) -> bool:
	return fire_tiles.has(pos)

# ---- CAVE-IN SYSTEM ----
func _check_cavein(pos: Vector3i) -> void:
	var above = Vector3i(pos.x, pos.y + 1, pos.z)
	var t = get_tile(above)
	if t in [TileType.WALL, TileType.CAVE_WALL, TileType.CONSTRUCTED_WALL, TileType.STONE_FLOOR, TileType.CAVE_FLOOR]:
		var support_count = 0
		for dx in [-1, 0, 1]:
			for dz in [-1, 0, 1]:
				var np = Vector3i(pos.x + dx, pos.y + 1, pos.z + dz)
				if dx == 0 and dz == 0: continue
				var nt = get_tile(np)
				if nt in [TileType.WALL, TileType.CAVE_WALL, TileType.CONSTRUCTED_WALL, TileType.FORTIFICATION]:
					support_count += 1
		if support_count < 1:
			cavein_queue.append(above)

func tick_caveins() -> void:
	if cavein_queue.is_empty(): return
	var pos = cavein_queue.pop_front()
	var t = get_tile(pos)
	if t in [TileType.WALL, TileType.CAVE_WALL, TileType.CONSTRUCTED_WALL, TileType.STONE_FLOOR, TileType.CAVE_FLOOR]:
		set_tile(pos, TileType.STONE_FLOOR)
		_spawn_item(pos, "Escombro de Roca", "stone", MatType.STONE, "*", Color("#808080"))
		for e in entities:
			# Los escombros se crean como DFItem en esta misma casilla.
			# Solo las entidades vivas que realmente tengan salud reciben daño.
			if e == null or e.get("tile_pos") != pos:
				continue
			var health_value: Variant = e.get("health")
			if health_value == null:
				continue
			var alive: Variant = e.get("is_alive")
			if alive == false:
				continue
			e.set("health", maxf(0.0, float(health_value) - 0.8))
			if e.has_method("add_thought"):
				e.add_thought("¡Quedó atrapado en un derrumbe!", -0.5)
		if randi() % 3 == 0:
			var above = Vector3i(pos.x, pos.y + 1, pos.z)
			if tiles.has(above):
				cavein_queue.append(above)

# ---- NATURAL DISASTERS ----
func trigger_disaster(type: int, pos: Vector3i, intensity: float = 0.5) -> void:
	active_disaster = type
	disaster_pos = pos
	disaster_intensity = intensity
	disaster_radius = 3 + int(intensity * 7)
	disaster_timer = 20 + int(intensity * 40)
	match type:
		DisasterType.EARTHQUAKE:
			earthquake_tiles_remaining = disaster_radius * 4
		DisasterType.FLOOD:
			for i in range(disaster_radius):
				flood_tiles.append(Vector3i(pos.x + randi() % disaster_radius - disaster_radius/2, pos.y, pos.z + randi() % disaster_radius - disaster_radius/2))

func tick_disasters() -> void:
	if active_disaster == DisasterType.NONE: return
	disaster_timer -= 1
	match active_disaster:
		DisasterType.EARTHQUAKE:
			if earthquake_tiles_remaining > 0:
				var rx = disaster_pos.x + randi() % disaster_radius - disaster_radius/2
				var rz = disaster_pos.z + randi() % disaster_radius - disaster_radius/2
				var ry = disaster_pos.y
				var rp = Vector3i(clampi(rx, 0, width-1), clampi(ry, 0, height-1), clampi(rz, 0, depth-1))
				var rt = get_tile(rp)
				if rt in [TileType.WALL, TileType.CAVE_WALL, TileType.CONSTRUCTED_WALL, TileType.FLOOR, TileType.STONE_FLOOR]:
					set_tile(rp, TileType.STONE_FLOOR if rt in [TileType.WALL, TileType.CAVE_WALL] else TileType.CAVE_FLOOR)
					_spawn_item(rp, "Escombro Derrumbe", "stone", MatType.STONE, "*", Color("#808080"))
				earthquake_tiles_remaining -= 1
		DisasterType.FLOOD:
			if not flood_tiles.is_empty():
				var fp = flood_tiles.pop_front()
				var ft = get_tile(fp)
				if ft in [TileType.GRASS, TileType.DIRT, TileType.SOIL, TileType.SAND, TileType.FLOOR]:
					set_tile(fp, TileType.WATER_SHALLOW)
					fluid_levels[fp] = 3.0
		DisasterType.FIRE:
			for fi in range(5):
				var fx = disaster_pos.x + randi() % disaster_radius - disaster_radius/2
				var fz = disaster_pos.z + randi() % disaster_radius - disaster_radius/2
				var fy = get_surface_height(clampi(fx, 0, width-1), clampi(fz, 0, depth-1)) if fx >= 0 and fx < width and fz >= 0 and fz < depth else disaster_pos.y
				var fp2 = Vector3i(clampi(fx, 0, width-1), fy, clampi(fz, 0, depth-1))
				var ft2 = get_tile(fp2)
				if ft2 in [TileType.TREE, TileType.GRASS, TileType.DIRT]:
					_start_fire(fp2)
	if disaster_timer <= 0:
		active_disaster = DisasterType.NONE

# ---- TEMPERATURE / SEASON ----
func tick_temperature() -> void:
	var season_temp = 0.5
	match current_season:
		Season.SPRING: season_temp = 0.45
		Season.SUMMER: season_temp = 0.7
		Season.AUTUMN: season_temp = 0.4
		Season.WINTER: season_temp = 0.2
	var day_cycle = sin(day_time * PI * 2) * 0.15 + 0.5
	var weather_mod = 0.0
	if current_weather in [WeatherType.CLOUDY, WeatherType.RAIN, WeatherType.HEAVY_RAIN, WeatherType.STORM]:
		weather_mod = -0.05
	elif current_weather == WeatherType.CLEAR:
		weather_mod = 0.05
	elif current_weather in [WeatherType.SNOW, WeatherType.BLIZZARD]:
		weather_mod = -0.15
	ambient_temperature = clampf(ambient_temperature + (season_temp + day_cycle * 0.3 + weather_mod - ambient_temperature) * 0.01, 0.0, 1.0)
	ground_temperature = clampf(ground_temperature + (ambient_temperature - ground_temperature) * 0.005, 0.0, 1.0)
	_apply_temperature_effects()

func _apply_temperature_effects() -> void:
	if ambient_temperature < 0.25:
		for z in range(depth):
			for x in range(width):
				if randi() % 100 == 0:
					var pos = Vector3i(x, get_surface_height(x, z), z)
					var t = get_tile(pos)
					if t in [TileType.WATER_SHALLOW, TileType.MURKY_POOL]:
						set_tile(pos, TileType.ICE)
						set_material(pos, MatType.WATER)
	elif ambient_temperature > 0.6:
		for z2 in range(depth):
			for x2 in range(width):
				if randi() % 100 == 0:
					var pos2 = Vector3i(x2, get_surface_height(x2, z2), z2)
					var t2 = get_tile(pos2)
					if t2 == TileType.ICE:
						set_tile(pos2, TileType.WATER_SHALLOW)
						fluid_levels[pos2] = fluid_levels.get(pos2, 0.0) + 1.0
					if t2 == TileType.SNOW:
						var td = tile_data.get(pos2, {})
						var snow = td.get("snow_cover", 0.1)
						snow -= 0.1
						if snow <= 0: set_tile(pos2, TileType.GRASS)
						else: td["snow_cover"] = snow
						tile_data[pos2] = td

# ---- DAY/NIGHT CYCLE ----
func tick_daynight() -> void:
	day_time = fmod(day_time + 0.002, 1.0)
	is_daytime = day_time > 0.25 and day_time < 0.75
	light_level = 1.0
	if not is_daytime:
		light_level = 0.2 + sin((day_time - 0.75) * PI * 2) * 0.3
		if light_level < 0: light_level = 0.05
	light_level = clampf(light_level, 0.05, 1.0)
	if current_weather in [WeatherType.HEAVY_RAIN, WeatherType.STORM, WeatherType.BLIZZARD]:
		light_level *= 0.6
	elif current_weather == WeatherType.CLOUDY:
		light_level *= 0.85
	if not is_daytime and current_season == Season.WINTER:
		ambient_temperature -= 0.002

# ---- TREE / NATURE GROWTH ----
func tick_nature() -> void:
	tree_growth_timer += 1
	if tree_growth_timer >= tree_growth_interval:
		tree_growth_timer = 0
		_try_grow_trees()
		_try_grow_grass()

func _try_grow_trees() -> void:
	for z in range(depth):
		for x in range(width):
			var pos = Vector3i(x, get_surface_height(x, z), z)
			var t = get_tile(pos)
			if t == TileType.TREE:
				var td = tile_data.get(pos, {})
				var age = td.get("tree_age", 0) + 1
				td["tree_age"] = age
				tile_data[pos] = td
				tree_data[pos] = {"age": age, "stage": mini(int(age / 50), 3)}
			elif t == TileType.GRASS and pos.y >= 0:
				var veg_chance = 0.001
				match current_season:
					Season.SPRING: veg_chance = 0.003
					Season.SUMMER: veg_chance = 0.002
					Season.AUTUMN: veg_chance = 0.001
					Season.WINTER: veg_chance = 0.0001
				if current_weather == WeatherType.RAIN or current_weather == WeatherType.DRIZZLE:
					veg_chance *= 2.0
				if randf() < veg_chance:
					if _check_tree_spacing(x, pos.y, z, 3):
						set_tile(pos, TileType.TREE)
						tile_data[pos] = {"tree_age": 0}

func _check_tree_spacing(x: int, y: int, z: int, min_dist: int) -> bool:
	for dz in range(-min_dist, min_dist + 1):
		for dx in range(-min_dist, min_dist + 1):
			if dx == 0 and dz == 0: continue
			var tx = x + dx; var tz = z + dz
			if tx >= 0 and tx < width and tz >= 0 and tz < depth:
				if get_tile(Vector3i(tx, y, tz)) == TileType.TREE:
					return false
	return true

func _try_grow_grass() -> void:
	if current_season == Season.WINTER: return
	for z in range(depth):
		for x in range(width):
			if randi() % 200 == 0:
				var pos = Vector3i(x, get_surface_height(x, z), z)
				var t = get_tile(pos)
				if t == TileType.DIRT and randi() % 3 == 0:
					set_tile(pos, TileType.GRASS)
		if current_season == Season.AUTUMN and randi() % 300 == 0:
			var ax = randi() % width
			var pos2 = Vector3i(ax, get_surface_height(ax, z), z)
			if get_tile(pos2) == TileType.TREE:
				var fall_pos = Vector3i(pos2.x + randi() % 3 - 1, pos2.y, pos2.z + randi() % 3 - 1)
				if fall_pos.x >= 0 and fall_pos.x < width and fall_pos.z >= 0 and fall_pos.z < depth:
					if get_tile(fall_pos) in [TileType.GRASS, TileType.DIRT]:
						leaf_litter[fall_pos] = leaf_litter.get(fall_pos, 0) + 1

# ---- MAIN TICK ----
func tick(minute_ticked: bool = false) -> void:
	if minute_ticked:
		tick_daynight()
		tick_temperature()
		tick_weather()
		tick_plants()
		tick_nature()
		tick_caveins()
		tick_fires()
		tick_disasters()
		tick_fluids()

# ---- RENDERING HELPERS ----
func get_tile_name(pos: Vector3i) -> String:
	var t = get_tile(pos)
	var names = {
		TileType.FLOOR: "Floor", TileType.WALL: "Wall", TileType.WATER_DEEP: "Deep Water",
		TileType.WATER_SHALLOW: "Shallow Water", TileType.TREE: "Tree", TileType.RAMP: "Ramp",
		TileType.STAIRS_UP: "Up Stairs", TileType.STAIRS_DOWN: "Down Stairs",
		TileType.STAIRS_UPDOWN: "Up/Down Stairs", TileType.CAVE_FLOOR: "Cave Floor",
		TileType.CAVE_WALL: "Cave Wall", TileType.MAGMA: "Magma", TileType.BRIDGE: "Bridge",
		TileType.GRASS: "Grass", TileType.DIRT: "Dirt", TileType.SAND: "Sand",
		TileType.SNOW: "Snow", TileType.ICE: "Ice", TileType.STONE_FLOOR: "Stone Floor",
		TileType.SOIL: "Soil", TileType.FARM_SOIL: "Farm Soil", TileType.MURKY_POOL: "Murky Pool",
		TileType.BROOK: "Brook", TileType.FORTIFICATION: "Fortification",
		TileType.CONSTRUCTED_WALL: "Constructed Wall",
		TileType.CONSTRUCTED_FLOOR: "Constructed Floor", TileType.PATH: "Path"
	}
	var name = names.get(t, "Void")
	var td = tile_data.get(pos, {})
	if td.get("smoothed", false): name += " (smoothed)"
	if td.get("burnt", false): name += " (burnt)"
	if td.get("magma_pipe", false): name += " (magma pipe)"
	var fl = fluid_levels.get(pos, 0.0)
	if fl > 0: name += " [water: %d]" % int(fl)
	if fire_tiles.has(pos): name += " [ON FIRE]"
	return name

func get_tile_char(pos: Vector3i) -> String:
	var t = get_tile(pos)
	if fire_tiles.has(pos): return "\u2588"
	return TILE_CHARS.get(t, " ")

func get_tile_color(pos: Vector3i) -> Color:
	var t = get_tile(pos)
	if fire_tiles.has(pos): return Color("#FF4400")
	if t in [TileType.WALL, TileType.CAVE_WALL, TileType.STONE_FLOOR] or t == TileType.FLOOR:
		var mat = get_material(pos)
		return MATERIAL_COLORS.get(mat, TILE_COLORS.get(t, Color.WHITE))
	var td = tile_data.get(pos, {})
	if td.get("smoothed", false):
		return TILE_COLORS.get(t, Color.WHITE).lightened(0.2)
	if td.get("burnt", false):
		return TILE_COLORS.get(t, Color.WHITE).darkened(0.4)
	if td.get("wetness", 0.0) > 0.5:
		return TILE_COLORS.get(t, Color.WHITE).darkened(0.1)
	return TILE_COLORS.get(t, Color.WHITE)

func get_tile_bg_color(pos: Vector3i) -> Color:
	var t = get_tile(pos)
	if t == TileType.WATER_DEEP: return Color(0, 0, 0.2, 1)
	if t == TileType.WATER_SHALLOW: return Color(0, 0, 0.3, 1)
	if t == TileType.MAGMA: return Color(0.3, 0.1, 0, 1)
	if fire_tiles.has(pos): return Color(0.3, 0.05, 0, 1)
	if not is_daytime and is_outdoor(pos):
		return Color(0, 0, 0.1, 0.3)
	return Color.BLACK

func add_splatter_substance(pos: Vector3i, substance: String, amount: float) -> void:
	if amount <= 0.0: return
	if not splatters.has(pos):
		splatters[pos] = {}
	var puddle: Dictionary = splatters[pos]
	puddle[substance] = puddle.get(substance, 0.0) + amount
	var total = 0.0
	for v in puddle.values(): total += v
	if total > 5.0:
		var excess = total - 5.0
		for s in puddle.keys():
			var ratio = puddle[s] / total
			puddle[s] -= excess * ratio
			if puddle[s] <= 0.0: puddle.erase(s)

func get_splatters_at(pos: Vector3i) -> Dictionary:
	return splatters.get(pos, {}).duplicate()

func tick_splatters() -> void:
	var to_remove: Array = []
	var keys = splatters.keys()
	for pos in keys:
		var puddle: Dictionary = splatters[pos]
		var tile_mat: int = get_tile(pos)
		var porosity: float = POROSITY_MAP.get(tile_mat, 0.1)
		# Outdoor evaporation is boosted by ambient temperature
		var evap_rate: float = 0.002
		if is_outdoor(pos) and ambient_temperature > 0.5:
			evap_rate = 0.005 * (1.0 + ambient_temperature)
		
		# Organic decomposition into miasma
		if puddle.has("blood") or puddle.has("vomit"):
			var rot_chance = 0.05 if not is_outdoor(pos) else 0.01
			if randf() < rot_chance:
				var emit_vol = 0.05
				if puddle.has("blood"): puddle["blood"] = maxf(0.0, puddle["blood"] - 0.005)
				if puddle.has("vomit"): puddle["vomit"] = maxf(0.0, puddle["vomit"] - 0.01)
				# 50% emit locally, 50% emit adjacent
				var target_pos = pos
				if randf() < 0.5:
					var dirs = [Vector3i(1,0,0), Vector3i(-1,0,0), Vector3i(0,0,1), Vector3i(0,0,-1)]
					var rd = dirs[randi() % dirs.size()]
					var check_p = pos + rd
					if check_p.x >= 0 and check_p.x < width and check_p.z >= 0 and check_p.z < depth and not is_blocked(check_p):
						target_pos = check_p
				add_splatter_substance(target_pos, "miasma", emit_vol)

		# Miasma gas dispersion
		if puddle.has("miasma") and puddle["miasma"] > 0.04 and randf() < 0.35:
			var spread_dirs = [Vector3i(1,0,0), Vector3i(-1,0,0), Vector3i(0,0,1), Vector3i(0,0,-1)]
			var spread_rd = spread_dirs[randi() % spread_dirs.size()]
			var spread_p = pos + spread_rd
			if spread_p.x >= 0 and spread_p.x < width and spread_p.z >= 0 and spread_p.z < depth and not is_blocked(spread_p):
				var spread_amt = puddle["miasma"] * 0.15
				puddle["miasma"] -= spread_amt
				add_splatter_substance(spread_p, "miasma", spread_amt)

		var subs_to_erase: Array = []
		for substance in puddle.keys():
			var vol: float = puddle[substance]
			var decay: float = evap_rate + porosity * 0.04
			if substance == "miasma":
				# Miasma is a gas; decays and disperses extremely fast
				decay = 0.035 if not is_outdoor(pos) else 0.09
			vol -= decay
			if vol <= 0.0:
				subs_to_erase.append(substance)
			else:
				puddle[substance] = vol
		for sub in subs_to_erase:
			puddle.erase(sub)
		if puddle.is_empty():
			to_remove.append(pos)
	for erase_splat_pos in to_remove:
		splatters.erase(erase_splat_pos)

func transfer_fluid_to_parts(pos: Vector3i, body) -> void:
	if not body or body.is_dead: return
	var puddle = splatters.get(pos)
	if puddle == null or puddle.is_empty(): return
	for part in body.parts:
		if part.can_stand and not part.is_severed:
			for substance in puddle.keys():
				var vol = puddle[substance]
				if vol <= 0.0: continue
				var transfer = minf(vol, 0.01)
				puddle[substance] = vol - transfer
				part.coatings[substance] = part.coatings.get(substance, 0.0) + transfer
	var to_remove2 = []
	for sub2 in puddle.keys():
		if puddle[sub2] <= 0.0:
			to_remove2.append(sub2)
	for s2 in to_remove2:
		puddle.erase(s2)
	if puddle.is_empty():
		splatters.erase(pos)

func apply_step_coatings(pos: Vector3i, standing_parts: Array) -> void:
	var puddle = splatters.get(pos)
	if puddle == null or puddle.is_empty(): return
	for part in standing_parts:
		if part.is_severed: continue
		for substance in puddle.keys():
			var vol = puddle[substance]
			if vol <= 0.0: continue
			var transfer = minf(vol, 0.005)
			puddle[substance] = vol - transfer
			part.coatings[substance] = part.coatings.get(substance, 0.0) + transfer
	for sub3 in puddle.keys():
		if puddle[sub3] <= 0.0:
			puddle.erase(sub3)
	if puddle.is_empty():
		splatters.erase(pos)

func deposit_footprint(pos: Vector3i, standing_parts: Array) -> void:
	for part in standing_parts:
		if part.is_severed or part.coatings.is_empty(): continue
		for substance in part.coatings.keys():
			var vol = part.coatings[substance]
			if vol <= 0.0: continue
			var drop = vol * 0.05
			part.coatings[substance] = vol - drop
			if part.coatings[substance] <= 0.0:
				part.coatings.erase(substance)
			add_splatter_substance(pos, substance, drop)

## Legacy compatibility shim: add_splatter(pos, type) still works.
## Deposits a small fixed volume (0.05 L equivalent) for backwards compat.
func add_splatter(pos: Vector3i, type: String) -> void:
	add_splatter_substance(pos, type, 0.05)

## Return the substance with the largest volume at a tile (used by renderer).
func get_dominant_substance(pos: Vector3i) -> String:
	if not splatters.has(pos):
		return ""
	var best := ""
	var best_vol := 0.0
	for sub in splatters[pos]:
		if splatters[pos][sub] > best_vol:
			best_vol = splatters[pos][sub]
			best = sub
	return best

## Remove up to max_amount of a substance from a tile and return what was taken.
## Used for item contamination, creature absorption, and step-coating transfer.
func absorb_from_tile(pos: Vector3i, substance: String, max_amount: float) -> float:
	if not splatters.has(pos):
		return 0.0
	if not splatters[pos].has(substance):
		return 0.0
	var available: float = splatters[pos][substance]
	var take: float = minf(max_amount, available)
	splatters[pos][substance] -= take
	if splatters[pos][substance] <= 0.0:
		splatters[pos].erase(substance)
	if splatters[pos].is_empty():
		splatters.erase(pos)
	return take
