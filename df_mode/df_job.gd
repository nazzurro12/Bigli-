extends RefCounted
class_name DFJob
# Carga diferida para romper dependencia circular con df_dwarf.gd
static var DFDwarf = load("res://df_mode/df_dwarf.gd")

enum JobType {
	DIG, CHOP_TREE, BUILD_WALL, BUILD_FLOOR, BUILD_STAIRS_UP, BUILD_STAIRS_DOWN,
	SMOOTH, CARVE_FORTIFICATION, COLLECT_STONE, COLLECT_WOOD,
	DUMP_ITEM, STORE_ITEM, CONSTRUCT_BUILDING, FARM_PLANT,
	FARM_HARVEST, FISH, HUNT, BUILD_WORKSHOP, WORKSHOP_REACTION,
	FIGHT, PATROL, TRAIN, WORK_IN_WORKSHOP, HAUL_WEAPON, HAUL_ARMOR,
	HAUL_FOOD, HAUL_STONE, HAUL_WOOD, HAUL_ITEM, PULL_LEVER,
	BUILD_BRIDGE, BUILD_ROAD, CLEAN, FEED_WAR_ANIMAL,
	TEND_WOUNDS, DIAGNOSE, SURGERY, RECOVER,
	MANAGE_NOBLE, TRADE_CARAVAN, RECORD_KEEPING,
	STONE_DETAILING, ENGRAVING, CUT_GEMS, ENCRUST,
	BREW_DRINK, COOK_FOOD, PROCESS_PLANT,
	SPIN_THREAD, WEAVE_CLOTH, DYING_CLOTH,
	TAN_HIDE, LEATHER_WORK, MAKE_CHARCOAL,
	SMELT_ORE, EXTRACT_STRAND, MILL_FLOUR,
	LAY_NEST_BOX, COLLECT_EGGS, SHEAR_CREATURE,
	MILK_CREATURE, MAKE_CHEESE, MAKE_LYE, MAKE_POTASH,
	MAKE_PEARLASH, POTTERY, GLAZING, GLASS_MAKING,
	BOOK_BINDING, SCROLL_WRITING, STORE_IN_CONTAINER, DECONSTRUCT
}

enum JobState { UNASSIGNED, ASSIGNED, IN_PROGRESS, COMPLETED, CANCELLED, SUSPENDED }

enum LaborCategory {
	MINING, WOODCRAFT, STONECRAFT, FARMING, FISHING, HUNTING,
	COOKING, BREWING, MEDICINE, SMITHING, CRAFTS, ENGINEERING,
	HAULING, MILITARY, NOBLE, ADMIN, TRADE, ART, ALCHEMY
}

static var _labor_skill_map: Dictionary = {}

static func get_labor_skill_map() -> Dictionary:
	if _labor_skill_map.is_empty():
		_labor_skill_map = {
			LaborCategory.MINING: [DFDwarf.Skill.MINING],
			LaborCategory.WOODCRAFT: [DFDwarf.Skill.CARPENTRY, DFDwarf.Skill.WOODCUTTING],
			LaborCategory.STONECRAFT: [DFDwarf.Skill.MASONRY, DFDwarf.Skill.ENGRAVING],
			LaborCategory.FARMING: [DFDwarf.Skill.FARMING],
			LaborCategory.FISHING: [DFDwarf.Skill.FISHING],
			LaborCategory.HUNTING: [DFDwarf.Skill.MILITARY_TACTICS, DFDwarf.Skill.WOODCUTTING],
			LaborCategory.COOKING: [DFDwarf.Skill.COOKING],
			LaborCategory.BREWING: [DFDwarf.Skill.BREWING],
			LaborCategory.MEDICINE: [DFDwarf.Skill.DOCTORING, DFDwarf.Skill.DIAGNOSE, DFDwarf.Skill.SURGERY, DFDwarf.Skill.BONE_SETTING, DFDwarf.Skill.DRESSING_WOUNDS],
			LaborCategory.SMITHING: [DFDwarf.Skill.SMITHING],
			LaborCategory.CRAFTS: [DFDwarf.Skill.MECHANICS, DFDwarf.Skill.ALCHEMY],
			LaborCategory.ENGINEERING: [DFDwarf.Skill.MECHANICS, DFDwarf.Skill.SIEGECRAFT],
			LaborCategory.HAULING: [],
			LaborCategory.MILITARY: [DFDwarf.Skill.MILITARY_TACTICS, DFDwarf.Skill.SIEGECRAFT],
			LaborCategory.NOBLE: [DFDwarf.Skill.ORGANIZING, DFDwarf.Skill.DIPLOMACY, DFDwarf.Skill.LEADERSHIP],
			LaborCategory.ADMIN: [DFDwarf.Skill.ORGANIZING],
			LaborCategory.TRADE: [DFDwarf.Skill.TRADING],
			LaborCategory.ART: [DFDwarf.Skill.MUSIC, DFDwarf.Skill.POETRY, DFDwarf.Skill.DANCE, DFDwarf.Skill.WRITING],
			LaborCategory.ALCHEMY: [DFDwarf.Skill.ALCHEMY]
		}
	return _labor_skill_map

const JOB_LABOR_MAP = {
	JobType.DIG: LaborCategory.MINING, JobType.COLLECT_STONE: LaborCategory.HAULING,
	JobType.CHOP_TREE: LaborCategory.WOODCRAFT, JobType.COLLECT_WOOD: LaborCategory.HAULING,
	JobType.BUILD_WALL: LaborCategory.STONECRAFT, JobType.BUILD_FLOOR: LaborCategory.STONECRAFT,
	JobType.BUILD_STAIRS_UP: LaborCategory.MINING, JobType.BUILD_STAIRS_DOWN: LaborCategory.MINING,
	JobType.SMOOTH: LaborCategory.STONECRAFT, JobType.CARVE_FORTIFICATION: LaborCategory.STONECRAFT,
	JobType.FARM_PLANT: LaborCategory.FARMING, JobType.FARM_HARVEST: LaborCategory.FARMING,
	JobType.FISH: LaborCategory.FISHING, JobType.HUNT: LaborCategory.HUNTING,
	JobType.WORKSHOP_REACTION: LaborCategory.SMITHING, JobType.WORK_IN_WORKSHOP: LaborCategory.CRAFTS,
	JobType.FIGHT: LaborCategory.MILITARY, JobType.PATROL: LaborCategory.MILITARY,
	JobType.TRAIN: LaborCategory.MILITARY,
	JobType.HAUL_WEAPON: LaborCategory.HAULING, JobType.HAUL_ARMOR: LaborCategory.HAULING,
	JobType.HAUL_FOOD: LaborCategory.HAULING, JobType.HAUL_STONE: LaborCategory.HAULING,
	JobType.HAUL_WOOD: LaborCategory.HAULING, JobType.HAUL_ITEM: LaborCategory.HAULING,
	JobType.STORE_ITEM: LaborCategory.HAULING, JobType.DUMP_ITEM: LaborCategory.HAULING,
	JobType.STORE_IN_CONTAINER: LaborCategory.HAULING,
	JobType.TEND_WOUNDS: LaborCategory.MEDICINE, JobType.DIAGNOSE: LaborCategory.MEDICINE,
	JobType.SURGERY: LaborCategory.MEDICINE, JobType.RECOVER: LaborCategory.MEDICINE,
	JobType.BREW_DRINK: LaborCategory.BREWING, JobType.COOK_FOOD: LaborCategory.COOKING,
	JobType.MANAGE_NOBLE: LaborCategory.NOBLE, JobType.TRADE_CARAVAN: LaborCategory.TRADE,
	JobType.STONE_DETAILING: LaborCategory.STONECRAFT, JobType.ENGRAVING: LaborCategory.ART,
	JobType.CUT_GEMS: LaborCategory.CRAFTS, JobType.ENCRUST: LaborCategory.CRAFTS,
	JobType.SMELT_ORE: LaborCategory.SMITHING, JobType.MAKE_CHARCOAL: LaborCategory.SMITHING,
	JobType.TAN_HIDE: LaborCategory.CRAFTS, JobType.LEATHER_WORK: LaborCategory.CRAFTS,
	JobType.PROCESS_PLANT: LaborCategory.FARMING, JobType.SPIN_THREAD: LaborCategory.CRAFTS,
	JobType.WEAVE_CLOTH: LaborCategory.CRAFTS, JobType.COLLECT_EGGS: LaborCategory.FARMING,
	JobType.SHEAR_CREATURE: LaborCategory.FARMING, JobType.MILK_CREATURE: LaborCategory.FARMING,
	JobType.MAKE_CHEESE: LaborCategory.COOKING, JobType.POTTERY: LaborCategory.CRAFTS,
	JobType.GLASS_MAKING: LaborCategory.CRAFTS,
	JobType.BUILD_BRIDGE: LaborCategory.ENGINEERING, JobType.BUILD_ROAD: LaborCategory.HAULING,
	JobType.PULL_LEVER: LaborCategory.ENGINEERING, JobType.CLEAN: LaborCategory.HAULING,
	JobType.FEED_WAR_ANIMAL: LaborCategory.MILITARY,
	JobType.BUILD_WORKSHOP: LaborCategory.STONECRAFT, JobType.CONSTRUCT_BUILDING: LaborCategory.ENGINEERING,
	JobType.DECONSTRUCT: LaborCategory.STONECRAFT
}

const LABOR_NAMES = {
	LaborCategory.MINING: "Minería", LaborCategory.WOODCRAFT: "Carpintería",
	LaborCategory.STONECRAFT: "Albañilería", LaborCategory.FARMING: "Agricultura",
	LaborCategory.FISHING: "Pesca", LaborCategory.HUNTING: "Caza",
	LaborCategory.COOKING: "Cocina", LaborCategory.BREWING: "Cervecería",
	LaborCategory.MEDICINE: "Medicina", LaborCategory.SMITHING: "Herrería",
	LaborCategory.CRAFTS: "Artesanía", LaborCategory.ENGINEERING: "Ingeniería",
	LaborCategory.HAULING: "Transporte", LaborCategory.MILITARY: "Militar",
	LaborCategory.NOBLE: "Noble", LaborCategory.ADMIN: "Administración",
	LaborCategory.TRADE: "Comercio", LaborCategory.ART: "Arte",
	LaborCategory.ALCHEMY: "Alquimia"
}

const JOB_PRIORITY_DEFAULT = 5
const JOB_PRIORITY_MIN = 1
const JOB_PRIORITY_MAX = 10

enum JobUrgency {
	LOW = 1, NORMAL = 5, HIGH = 8, CRITICAL = 10, EMERGENCY = 15
}

# ---- JOB FIELDS ----
var job_type: int
var tile_pos: Vector3i
var state: int = JobState.UNASSIGNED
var assigned_dwarf_id: int = -1
var priority: int = 5
var work_remaining: float = 1.0
var labor: int = LaborCategory.HAULING

var result_tile_type: int = -1
var result_material: int = -1

# ---- WORK ORDER SYSTEM ----
var work_order_id: int = -1
var is_repeatable: bool = false
var repeat_count: int = 0
var max_repeat: int = -1
var linked_order_id: int = -1

# ---- DEPENDENCY CHAIN ----
var prerequisite_job_ids: Array = []
var dependent_job_ids: Array = []
var required_items: Dictionary = {}
var required_skill: int = -1
var required_skill_level: int = 0

# ---- QUALITY / RESULT ----
var expected_quality: float = 0.5
var skill_xp_reward: int = 5
var item_produced: String = ""
var item_count_produced: int = 1
var reaction_id: String = ""

# ---- TIMING ----
var created_tick: int = 0
var assigned_tick: int = -1
var started_tick: int = -1
var completed_tick: int = -1
var cancel_reason: String = ""

func _init(type: int, pos: Vector3i, prio: int = 5):
	job_type = type
	tile_pos = pos
	priority = clampi(prio, JOB_PRIORITY_MIN, JOB_PRIORITY_MAX)
	labor = JOB_LABOR_MAP.get(type, LaborCategory.HAULING)
	created_tick = 0

func get_description() -> String:
	return get_description_spanish()

func get_description_spanish() -> String:
	var names = {
		JobType.DIG: "Excavar", JobType.CHOP_TREE: "Talar",
		JobType.BUILD_WALL: "Construir Muro", JobType.BUILD_FLOOR: "Construir Suelo",
		JobType.BUILD_STAIRS_UP: "Escalera Arriba", JobType.BUILD_STAIRS_DOWN: "Escalera Abajo",
		JobType.SMOOTH: "Alisar Piedra", JobType.CARVE_FORTIFICATION: "Fortificar",
		JobType.COLLECT_STONE: "Recoger Piedra", JobType.COLLECT_WOOD: "Recoger Madera",
		JobType.DUMP_ITEM: "Tirar Objeto", JobType.STORE_ITEM: "Almacenar",
		JobType.CONSTRUCT_BUILDING: "Construir Edificio", JobType.FARM_PLANT: "Sembrar",
		JobType.FARM_HARVEST: "Cosechar", JobType.FISH: "Pescar",
		JobType.HUNT: "Cazar", JobType.BUILD_WORKSHOP: "Construir Taller",
		JobType.WORKSHOP_REACTION: "Producir en Taller", JobType.FIGHT: "Combatir",
		JobType.PATROL: "Patrullar", JobType.TRAIN: "Entrenar",
		JobType.WORK_IN_WORKSHOP: "Trabajar", JobType.HAUL_WEAPON: "Transportar Armas",
		JobType.HAUL_ARMOR: "Transportar Armaduras", JobType.HAUL_FOOD: "Transportar Comida",
		JobType.HAUL_STONE: "Transportar Piedra", JobType.HAUL_WOOD: "Transportar Madera",
		JobType.HAUL_ITEM: "Transportar Objetos", JobType.PULL_LEVER: "Accionar Palanca",
		JobType.BUILD_BRIDGE: "Construir Puente", JobType.BUILD_ROAD: "Construir Camino",
		JobType.CLEAN: "Limpiar", JobType.FEED_WAR_ANIMAL: "Alimentar Animal",
		JobType.TEND_WOUNDS: "Vendar Heridas", JobType.DIAGNOSE: "Diagnosticar",
		JobType.SURGERY: "Cirugía", JobType.RECOVER: "Recuperar",
		JobType.MANAGE_NOBLE: "Gestionar Nobleza", JobType.TRADE_CARAVAN: "Comerciar Caravana",
		JobType.RECORD_KEEPING: "Registros", JobType.STONE_DETAILING: "Detallar Piedra",
		JobType.ENGRAVING: "Grabar", JobType.CUT_GEMS: "Cortar Gemas",
		JobType.ENCRUST: "Engastar", JobType.BREW_DRINK: "Cervecear",
		JobType.COOK_FOOD: "Cocinar", JobType.PROCESS_PLANT: "Procesar Planta",
		JobType.SPIN_THREAD: "Hilar", JobType.WEAVE_CLOTH: "Tejer",
		JobType.TAN_HIDE: "Curtir Piel", JobType.LEATHER_WORK: "Marroquinería",
		JobType.SMELT_ORE: "Fundir Metal", JobType.MAKE_CHARCOAL: "Hacer Carbón",
		JobType.MAKE_CHEESE: "Hacer Queso", JobType.POTTERY: "Alfarería",
		JobType.GLASS_MAKING: "Vidriería", JobType.COLLECT_EGGS: "Recoger Huevos",
		JobType.SHEAR_CREATURE: "Esquilar", JobType.MILK_CREATURE: "Ordeñar",
		JobType.EXTRACT_STRAND: "Extraer Fibra", JobType.MILL_FLOUR: "Moler Harina",
		JobType.DYING_CLOTH: "Teñir Tela", JobType.MAKE_LYE: "Hacer Lejía",
		JobType.MAKE_POTASH: "Hacer Potasa", JobType.MAKE_PEARLASH: "Hacer Sosa",
		JobType.BOOK_BINDING: "Encuadernar", JobType.SCROLL_WRITING: "Escribir Pergamino",
		JobType.STORE_IN_CONTAINER: "Guardar en Almacén de Comida",
		JobType.DECONSTRUCT: "Desmantelar"
	}
	return names.get(job_type, "Desconocido")

func get_labor_name() -> String:
	return LABOR_NAMES.get(labor, "Desconocido")

func get_required_skill() -> int:
	match job_type:
		JobType.DIG: return DFDwarf.Skill.MINING
		JobType.SMOOTH: return DFDwarf.Skill.MASONRY
		JobType.CARVE_FORTIFICATION: return DFDwarf.Skill.MASONRY
		JobType.BUILD_WALL: return DFDwarf.Skill.MASONRY
		JobType.BUILD_FLOOR: return DFDwarf.Skill.MASONRY
		JobType.CHOP_TREE: return DFDwarf.Skill.WOODCUTTING
		JobType.COLLECT_WOOD: return DFDwarf.Skill.WOODCUTTING
		JobType.COLLECT_STONE: return DFDwarf.Skill.MINING
		JobType.CONSTRUCT_BUILDING: return DFDwarf.Skill.CARPENTRY
		JobType.BUILD_WORKSHOP: return DFDwarf.Skill.CARPENTRY
		JobType.WORK_IN_WORKSHOP: return DFDwarf.Skill.MASONRY
		JobType.WORKSHOP_REACTION: return DFDwarf.Skill.SMITHING
		JobType.FARM_PLANT: return DFDwarf.Skill.FARMING
		JobType.FARM_HARVEST: return DFDwarf.Skill.FARMING
		JobType.FISH: return DFDwarf.Skill.FISHING
		JobType.HUNT: return DFDwarf.Skill.MILITARY_TACTICS
		JobType.FIGHT: return DFDwarf.Skill.MILITARY_TACTICS
		JobType.PATROL: return DFDwarf.Skill.MILITARY_TACTICS
		JobType.TRAIN: return DFDwarf.Skill.MILITARY_TACTICS
		JobType.BREW_DRINK: return DFDwarf.Skill.BREWING
		JobType.COOK_FOOD: return DFDwarf.Skill.COOKING
		JobType.SMELT_ORE: return DFDwarf.Skill.SMITHING
		JobType.MAKE_CHARCOAL: return DFDwarf.Skill.SMITHING
		JobType.TEND_WOUNDS: return DFDwarf.Skill.DRESSING_WOUNDS
		JobType.DIAGNOSE: return DFDwarf.Skill.DIAGNOSE
		JobType.SURGERY: return DFDwarf.Skill.SURGERY
		JobType.CUT_GEMS: return DFDwarf.Skill.MECHANICS
		JobType.ENCRUST: return DFDwarf.Skill.MECHANICS
		JobType.TAN_HIDE: return DFDwarf.Skill.COOKING
		JobType.LEATHER_WORK: return DFDwarf.Skill.MECHANICS
		JobType.PROCESS_PLANT: return DFDwarf.Skill.FARMING
		JobType.SPIN_THREAD: return DFDwarf.Skill.FARMING
		JobType.WEAVE_CLOTH: return DFDwarf.Skill.MECHANICS
		JobType.ENGRAVING: return DFDwarf.Skill.ENGRAVING
		JobType.STONE_DETAILING: return DFDwarf.Skill.MASONRY
		JobType.COLLECT_EGGS: return DFDwarf.Skill.FARMING
		JobType.SHEAR_CREATURE: return DFDwarf.Skill.FARMING
		JobType.MILK_CREATURE: return DFDwarf.Skill.FARMING
		JobType.MAKE_CHEESE: return DFDwarf.Skill.COOKING
		JobType.POTTERY: return DFDwarf.Skill.MECHANICS
		JobType.GLASS_MAKING: return DFDwarf.Skill.ALCHEMY
		JobType.BUILD_BRIDGE: return DFDwarf.Skill.CARPENTRY
		JobType.PULL_LEVER: return DFDwarf.Skill.MECHANICS
		JobType.CLEAN: return DFDwarf.Skill.COOKING
		JobType.FEED_WAR_ANIMAL: return DFDwarf.Skill.MILITARY_TACTICS
		JobType.MANAGE_NOBLE: return DFDwarf.Skill.ORGANIZING
		JobType.TRADE_CARAVAN: return DFDwarf.Skill.TRADING
		JobType.RECORD_KEEPING: return DFDwarf.Skill.ORGANIZING
		JobType.EXTRACT_STRAND: return DFDwarf.Skill.FARMING
		JobType.MILL_FLOUR: return DFDwarf.Skill.COOKING
		JobType.DYING_CLOTH: return DFDwarf.Skill.ALCHEMY
		JobType.MAKE_LYE: return DFDwarf.Skill.ALCHEMY
		JobType.MAKE_POTASH: return DFDwarf.Skill.ALCHEMY
		JobType.MAKE_PEARLASH: return DFDwarf.Skill.ALCHEMY
		JobType.BOOK_BINDING: return DFDwarf.Skill.MECHANICS
		JobType.SCROLL_WRITING: return DFDwarf.Skill.WRITING
		JobType.RECOVER: return DFDwarf.Skill.DRESSING_WOUNDS
		_: return DFDwarf.Skill.MINING

func get_labor_category() -> int:
	return labor

func set_labor_category(cat: int) -> void:
	labor = cat

func get_effective_priority(dwarf_skill: int = 0) -> int:
	var effective = priority
	var skill_bonus = dwarf_skill - required_skill_level
	if skill_bonus > 0:
		effective += skill_bonus
	else:
		effective += skill_bonus
	return clampi(effective, JOB_PRIORITY_MIN, JOB_PRIORITY_MAX)

func get_work_time(dwarf_skill: int = 0) -> float:
	var base = 1.0
	var skill_factor = 1.0 + dwarf_skill * 0.15
	var quality_factor = 1.0 + expected_quality * 0.5
	var effective = base * quality_factor / skill_factor
	if effective < 0.1: effective = 0.1
	work_remaining = effective
	return effective

func add_prerequisite(job_id: int) -> void:
	if not job_id in prerequisite_job_ids:
		prerequisite_job_ids.append(job_id)

func add_dependent(job_id: int) -> void:
	if not job_id in dependent_job_ids:
		dependent_job_ids.append(job_id)

func add_required_item(item_type: String, amount: int) -> void:
	required_items[item_type] = required_items.get(item_type, 0) + amount

func has_met_prerequisites(completed_job_ids: Array) -> bool:
	for pid in prerequisite_job_ids:
		if not pid in completed_job_ids:
			return false
	return true

func get_priority_color() -> Color:
	match priority:
		1, 2: return Color("#88FF88")
		3, 4: return Color("#AAFFAA")
		5, 6: return Color("#FFFFFF")
		7, 8: return Color("#FFAA44")
		9: return Color("#FF6644")
		10: return Color("#FF2200")
		_: return Color("#FFFFFF")

func get_priority_label() -> String:
	match priority:
		1: return "Mínima"
		2: return "Muy Baja"
		3: return "Baja"
		4: return "Moderada"
		5: return "Normal"
		6: return "Elevada"
		7: return "Alta"
		8: return "Muy Alta"
		9: return "Urgente"
		10: return "Crítica"
		_: return "%d" % priority

# ---- WORK ORDER SYSTEM ----
func create_work_order(order_id: int, repeat: bool = false, max_repeat_count: int = -1) -> void:
	work_order_id = order_id
	is_repeatable = repeat
	max_repeat = max_repeat_count
	if is_repeatable:
		repeat_count = 0

func try_repeat() -> bool:
	if not is_repeatable: return false
	if max_repeat > 0 and repeat_count >= max_repeat: return false
	repeat_count += 1
	state = JobState.UNASSIGNED
	assigned_dwarf_id = -1
	work_remaining = 1.0
	return true

func get_job_summary() -> String:
	var s = get_description_spanish()
	var p = get_priority_label()
	var st = ["Sin asignar", "Asignado", "En progreso", "Completado", "Cancelado", "Suspendido"]
	return "%s [%s] (%s)" % [s, st[state], p]

func can_dwarf_perform(dwarf) -> bool:
	var skill_id = get_required_skill()
	var dwarf_skill = dwarf.get_skill_level(skill_id) if dwarf.has_method("get_skill_level") else 0
	if required_skill_level > 0 and dwarf_skill < required_skill_level:
		return false
	return true

# ---- DISPLAY ----
func get_display_char() -> String:
	match job_type:
		JobType.DIG: return "d"
		JobType.CHOP_TREE: return "c"
		JobType.BUILD_WALL: return "#"
		JobType.BUILD_FLOOR: return "."
		JobType.BUILD_STAIRS_UP: return "<"
		JobType.BUILD_STAIRS_DOWN: return ">"
		JobType.SMOOTH: return "s"
		JobType.HAUL_FOOD: return "f"
		JobType.HAUL_STONE: return "r"
		JobType.HAUL_WOOD: return "w"
		JobType.HAUL_ITEM: return "i"
		JobType.CLEAN: return "c"
		JobType.BUILD_WORKSHOP: return "W"
		JobType.STORE_IN_CONTAINER: return "S"
		JobType.DECONSTRUCT: return "x"
		_: return "?"

func get_display_color() -> Color:
	match job_type:
		JobType.DIG: return Color("#FFAA00")
		JobType.CHOP_TREE: return Color("#00FF44")
		JobType.BUILD_WALL: return Color("#AAAAAA")
		JobType.BUILD_FLOOR: return Color("#886644")
		JobType.BUILD_STAIRS_UP: return Color("#FFFFFF")
		JobType.BUILD_STAIRS_DOWN: return Color("#FFFFFF")
		JobType.SMOOTH: return Color("#88AAFF")
		JobType.BUILD_WORKSHOP: return Color("#FFA500")
		JobType.WORKSHOP_REACTION: return Color("#FFD700")
		JobType.FIGHT: return Color("#FF0000")
		JobType.PATROL: return Color("#8844FF")
		JobType.TRAIN: return Color("#FF8800")
		JobType.HAUL_FOOD: return Color("#FF8844")
		JobType.HAUL_STONE: return Color("#AAAAAA")
		JobType.HAUL_WOOD: return Color("#8B6914")
		JobType.HAUL_ITEM: return Color("#CCCCCC")
		JobType.BREW_DRINK: return Color("#FFCC00")
		JobType.COOK_FOOD: return Color("#FF8844")
		JobType.TEND_WOUNDS: return Color("#FF88AA")
		JobType.SURGERY: return Color("#FF4444")
		JobType.STORE_IN_CONTAINER: return Color("#BB8844")
		JobType.DECONSTRUCT: return Color("#FF3333")
		_: return get_priority_color()
