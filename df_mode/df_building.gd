extends RefCounted
class_name DFBuilding

# Tipos de edificio
enum BuildingType {
	NONE,
	SMELTER,      # Fundicion
	WORKSHOP,     # Taller generico
	KITCHEN,      # Cocina
	STILL,        # Destileria
	MASONRY,      # Albanileria
	CARPENTRY,    # Carpinteria
	FORGE,        # Forja
	LOOM,         # Telar
	TANNER,       # Curtiembre
	JEWELER,      # Joyeria
	CRAFT_SHOP,   # Artesania
	BEDROOM,      # Dormitorio
	STOCKPILE,    # Almacen
	DINING_HALL,  # Comedor
	BARRACK,      # Barracas
	TEMPLE,       # Templo
	TRAP,         # Trampa
	BRIDGE,       # Puente levadizo
	CAMPFIRE,     # Fogata
	FOOD_STORE,   # Estante/Barrel/Caja que preserva comida
	POTTERY,      # Alfareria
	GRAVE,        # Tumba / Lapida
	PRISON,       # Celda de prision
	CHAIN,        # Cadena / Grillo para prisionero
	COURTROOM,    # Sala de justicia
}

const BUILDING_NAMES = {
	BuildingType.SMELTER: "Fundicion",
	BuildingType.WORKSHOP: "Taller",
	BuildingType.KITCHEN: "Cocina",
	BuildingType.STILL: "Destileria",
	BuildingType.MASONRY: "Albanileria",
	BuildingType.CARPENTRY: "Carpinteria",
	BuildingType.FORGE: "Forja",
	BuildingType.LOOM: "Telar",
	BuildingType.TANNER: "Curtiembre",
	BuildingType.JEWELER: "Joyero",
	BuildingType.CRAFT_SHOP: "Artesania",
	BuildingType.BEDROOM: "Dormitorio",
	BuildingType.STOCKPILE: "Gran Almacen",
	BuildingType.DINING_HALL: "Comedor",
	BuildingType.BARRACK: "Barracas",
	BuildingType.TEMPLE: "Templo",
	BuildingType.CAMPFIRE: "Fogata",
	BuildingType.FOOD_STORE: "Almacen de Comida",
	BuildingType.POTTERY: "Alfareria",
	BuildingType.GRAVE: "Tumba",
	BuildingType.PRISON: "Celda",
	BuildingType.CHAIN: "Cadena",
	BuildingType.COURTROOM: "Juzgado",
}

const BUILDING_GLYPHS = {
	BuildingType.SMELTER: char(0x2642),
	BuildingType.WORKSHOP: char(0x263A),
	BuildingType.KITCHEN: char(0x2660),
	BuildingType.STILL: char(0x2663),
	BuildingType.MASONRY: char(0x2666),
	BuildingType.CARPENTRY: char(0x266B),
	BuildingType.FORGE: char(0x263C),
	BuildingType.LOOM: char(0x2660),
	BuildingType.TANNER: char(0x2660),
	BuildingType.JEWELER: char(0x2666),
	BuildingType.CRAFT_SHOP: char(0x266B),
	BuildingType.BEDROOM: char(0x263A),
	BuildingType.STOCKPILE: char(0x25A4),
	BuildingType.DINING_HALL: char(0x266B),
	BuildingType.BARRACK: char(0x263B),
	BuildingType.TEMPLE: char(0x263C),
	BuildingType.CAMPFIRE: char(0x00A4),
	BuildingType.FOOD_STORE: char(0x2593),
	BuildingType.POTTERY: "P",
	BuildingType.GRAVE: char(0x2020),
	BuildingType.PRISON: char(0x25A2),
	BuildingType.CHAIN: char(0x00A7),
	BuildingType.COURTROOM: char(0x2696),
}

const BUILDING_COLORS = {
	BuildingType.SMELTER: Color("#FF8800"),
	BuildingType.WORKSHOP: Color("#AAAAAA"),
	BuildingType.KITCHEN: Color("#44FF44"),
	BuildingType.STILL: Color("#FFCC00"),
	BuildingType.MASONRY: Color("#AAAAAA"),
	BuildingType.CARPENTRY: Color("#8B6914"),
	BuildingType.FORGE: Color("#FF4400"),
	BuildingType.LOOM: Color("#88AAAA"),
	BuildingType.TANNER: Color("#886644"),
	BuildingType.JEWELER: Color("#44FFFF"),
	BuildingType.CRAFT_SHOP: Color("#FF88FF"),
	BuildingType.BEDROOM: Color("#88AAFF"),
	BuildingType.STOCKPILE: Color("#E0B060"),
	BuildingType.DINING_HALL: Color("#D4AF37"),
	BuildingType.BARRACK: Color("#FF6666"),
	BuildingType.TEMPLE: Color("#FFFFFF"),
	BuildingType.CAMPFIRE: Color("#FF5500"),
	BuildingType.FOOD_STORE: Color("#BB8844"),
	BuildingType.POTTERY: Color("#CC8844"),
	BuildingType.GRAVE: Color("#CCCCCC"),
	BuildingType.PRISON: Color("#888888"),
	BuildingType.CHAIN: Color("#AAAAAA"),
	BuildingType.COURTROOM: Color("#D4AF37"),
}

# Dimensiones (ancho, profundidad)
const BUILDING_SIZES = {
	BuildingType.SMELTER: Vector3i(3, 0, 3),
	BuildingType.WORKSHOP: Vector3i(3, 0, 3),
	BuildingType.FORGE: Vector3i(3, 0, 3),
	BuildingType.KITCHEN: Vector3i(3, 0, 2),
	BuildingType.BEDROOM: Vector3i(1, 0, 1),
	BuildingType.STOCKPILE: Vector3i(20, 0, 20),
	BuildingType.DINING_HALL: Vector3i(5, 0, 5),
	BuildingType.BARRACK: Vector3i(4, 0, 4),
	BuildingType.TEMPLE: Vector3i(5, 0, 5),
	BuildingType.CAMPFIRE: Vector3i(1, 0, 1),
	BuildingType.FOOD_STORE: Vector3i(1, 0, 1),
	BuildingType.GRAVE: Vector3i(1, 0, 1),
	BuildingType.PRISON: Vector3i(1, 0, 1),
	BuildingType.CHAIN: Vector3i(1, 0, 1),
	BuildingType.COURTROOM: Vector3i(3, 0, 3),
}

var type: int = BuildingType.WORKSHOP
var tile_pos: Vector3i
var size: Vector3i = Vector3i(3, 0, 3)
var is_constructed: bool = false
var name: String = ""

func _init(b_type: int, pos: Vector3i, constructed: bool = false):
	type = b_type
	tile_pos = pos
	size = BUILDING_SIZES.get(b_type, Vector3i(3, 0, 3))
	name = BUILDING_NAMES.get(b_type, "Edificio")
	is_constructed = constructed

func is_inside(pos: Vector3i) -> bool:
	if pos.y != tile_pos.y:
		return false
	var dx: int = pos.x - tile_pos.x
	var dz: int = pos.z - tile_pos.z
	if type == BuildingType.STOCKPILE:
		return dx >= -10 and dx <= 9 and dz >= -10 and dz <= 9
	return dx >= 0 and dx < size.x and dz >= 0 and dz < size.z

func get_display_char() -> String:
	if not is_constructed:
		return "?"
	return BUILDING_GLYPHS.get(type, "?")

func get_display_color() -> Color:
	if not is_constructed:
		return Color(0.5, 0.5, 0.5, 0.5)
	return BUILDING_COLORS.get(type, Color.WHITE)
