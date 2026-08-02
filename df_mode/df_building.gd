extends RefCounted
class_name DFBuilding

# Tipos de edificio
enum BuildingType {
	NONE,
	SMELTER,      # Fundición
	WORKSHOP,     # Taller genérico
	KITCHEN,      # Cocina
	STILL,        # Destilería
	MASONRY,      # Albañilería
	CARPENTRY,    # Carpintería
	FORGE,        # Forja
	LOOM,         # Telar
	TANNER,       # Curtiembre
	JEWELER,      # Joyería
	CRAFT_SHOP,   # Artesanía
	BEDROOM,      # Dormitorio
	STOCKPILE,    # Almacén
	DINING_HALL,  # Comedor
	BARRACK,      # Barracas
	TEMPLE,       # Templo
	TRAP,         # Trampa
	BRIDGE,       # Puente levadizo
	CAMPFIRE,     # Fogata
	FOOD_STORE,   # Estante/Barrel/Caja que preserva comida
	LATRINE,
	WATER_WELL,
	PRISON,
	CHAIN
}
const BUILDING_NAMES = {
	BuildingType.SMELTER: "Fundición",
	BuildingType.WORKSHOP: "Taller",
	BuildingType.KITCHEN: "Cocina",
	BuildingType.STILL: "Destilería",
	BuildingType.MASONRY: "Albañilería",
	BuildingType.CARPENTRY: "Carpintería",
	BuildingType.FORGE: "Forja",
	BuildingType.LOOM: "Telar",
	BuildingType.TANNER: "Curtiembre",
	BuildingType.JEWELER: "Joyero",
	BuildingType.CRAFT_SHOP: "Artesanía",
	BuildingType.BEDROOM: "Dormitorio",
	BuildingType.STOCKPILE: "Gran Almacén",
	BuildingType.DINING_HALL: "Comedor",
	BuildingType.BARRACK: "Barracas",
	BuildingType.TEMPLE: "Templo",
	BuildingType.CAMPFIRE: "Fogata",
	BuildingType.FOOD_STORE: "Almacén de Comida",
	BuildingType.LATRINE: "Letrina",
	BuildingType.WATER_WELL: "Pozo Comunal",
}

const BUILDING_GLYPHS = {
	BuildingType.SMELTER: "S",
	BuildingType.WORKSHOP: "T",
	BuildingType.KITCHEN: "K",
	BuildingType.STILL: "D",
	BuildingType.MASONRY: "M",
	BuildingType.CARPENTRY: "C",
	BuildingType.FORGE: "F",
	BuildingType.LOOM: "L",
	BuildingType.TANNER: "P",
	BuildingType.JEWELER: "J",
	BuildingType.CRAFT_SHOP: "A",
	BuildingType.BEDROOM: "B",
	BuildingType.STOCKPILE: "X",
	BuildingType.DINING_HALL: "Q",
	BuildingType.BARRACK: "R",
	BuildingType.TEMPLE: "T",
	BuildingType.CAMPFIRE: "*",
	BuildingType.FOOD_STORE: "O",
	BuildingType.LATRINE: "L",
	BuildingType.WATER_WELL: "W",
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
	BuildingType.LATRINE: Color("#8B7355"),
	BuildingType.WATER_WELL: Color("#4FA3D1"),
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
	BuildingType.LATRINE: Vector3i(1, 0, 1),
	BuildingType.WATER_WELL: Vector3i(1, 0, 1),
}

var type: int = BuildingType.WORKSHOP
var tile_pos: Vector3i
var size: Vector3i = Vector3i(3, 0, 3)
var is_constructed: bool = true  # Ya construido por defecto
var name: String = ""
var sanitation_load: float = 0.0
var sanitation_capacity: float = 20.0
var water_volume: float = 0.0
var water_capacity: float = 80.0
var water_contamination: float = 0.0

func has_sanitation_capacity(amount: float = 0.0) -> bool:
	return type == BuildingType.LATRINE and sanitation_load + amount <= sanitation_capacity

func add_sanitation_waste(amount: float) -> bool:
	if not has_sanitation_capacity(amount):
		return false
	sanitation_load += maxf(0.0, amount)
	return true

func remove_sanitation_waste(max_amount: float) -> float:
	if type != BuildingType.LATRINE or max_amount <= 0.0:
		return 0.0
	var removed: float = minf(sanitation_load, max_amount)
	sanitation_load = maxf(0.0, sanitation_load - removed)
	return removed

func get_sanitation_fill_ratio() -> float:
	return sanitation_load / maxf(0.01, sanitation_capacity)

func draw_water(liters: float) -> Dictionary:
	if type != BuildingType.WATER_WELL or liters <= 0.0 or water_volume <= 0.0:
		return {"amount": 0.0, "contamination": water_contamination}
	var amount: float = minf(liters, water_volume)
	water_volume -= amount
	return {"amount": amount, "contamination": water_contamination}

func recharge_water(amount: float, local_contamination: float) -> void:
	if type != BuildingType.WATER_WELL:
		return
	water_volume = minf(water_capacity, water_volume + maxf(0.0, amount))
	water_contamination = lerpf(
		water_contamination,
		clampf(local_contamination, 0.0, 1.0),
		0.08
	)

func _init(b_type: int, pos: Vector3i):
	type = b_type
	tile_pos = pos
	size = BUILDING_SIZES.get(b_type, Vector3i(3, 0, 3))
	name = BUILDING_NAMES.get(b_type, "Edificio")
	is_constructed = true

func is_inside(pos: Vector3i) -> bool:
	if pos.y != tile_pos.y:
		return false
	var dx: int = pos.x - tile_pos.x
	var dz: int = pos.z - tile_pos.z
	if type == BuildingType.STOCKPILE:
		# El gran almacén se registra por su centro: interior -10..9 en ambos ejes.
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
