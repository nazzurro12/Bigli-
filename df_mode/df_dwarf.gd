extends RefCounted
class_name DFDwarf

# Carga diferida para romper dependencia circular con df_job.gd

enum Skill {
	MINING, CARPENTRY, MASONRY, SMITHING, COOKING, BREWING, FARMING, FISHING,
	WOODCUTTING, ENGRAVING, MECHANICS, DOCTORING, ORGANIZING, MILITARY_TACTICS,
	SIEGECRAFT, TRADING, DIPLOMACY, LEADERSHIP, MUSIC, POETRY, DANCE,
	WRITING, READING, ALCHEMY, ANATOMY, BONE_SETTING, SURGERY,
	DIAGNOSE, DRESSING_WOUNDS, CRUTCH_WALKING, CRAFTSMAN
}

enum PersonalityTrait {
	BRAVERY, GREED, VIOLENCE, INDUSTRY, LAZINESS, SOCIABILITY,
	CURIOSITY, JEALOUSY, COMPASSION, PRIDE, ANGER, FEAR,
	HONESTY, CRUELTY, FORGIVENESS, PLAYFULNESS, POLITENESS,
	AMBITION, STUBBORNNESS, PATIENCE, VANITY
}

enum Emotion {
	HAPPY, SAD, ANGRY, FEARFUL, SURPRISED, DISGUSTED, PROUD,
	ASHAMED, JEALOUS, LOVESTRUCK, CONTENT, FRUSTRATED, HOPEFUL,
	GRIEVING, EUPHORIC, NOSTALGIC, BORED, EXCITED, GRATEFUL,
	LONELY, WORRIED, DETERMINED, CONFUSED, EMBARRASSED
}

enum Need {
	FOOD, DRINK, SLEEP, SHELTER, COMFORT, SECURITY, SOCIAL,
	ESTEEM, WORK, RELIGION, ART, NATURE, ORDER, PERSONAL_SPACE,
	FAMILY, LUXURY, INTELLECT, ADVENTURE
}

enum MoodState {
	NORMAL, HAPPY, UNHAPPY, MISERABLE, TANTRUM, MELANCHOLY,
	BESERK, STRANGE_MOOD, FELL_MOOD, MACABRE_MOOD, SECRETIVE_MOOD
}

enum Profession {
	MINER, CARPENTER, MASON, SMITH, COOK, BREWER, FARMER, FISHER,
	WOODCUTTER, ENGRAVER, MECHANIC, DOCTOR, ADMINISTRATOR, MILITARY,
	NOBLE, CRAFTSMAN, JEWELER, ALCHEMIST, SCRIBE, TRADER, HUNTER,
	ARCHITECT, CHIEF_MEDICAL_DWARF, BROKER, MANAGER, SHERIFF,
	HAMMERER, EXPEDITION_LEADER, MONARCH, CAPTAIN_OF_GUARD,
	CHAMPION, DUNGEON_MASTER, MAYOR, DUKE, COUNT, KING
}

const PROFESSION_NAMES = {
	Profession.MINER: "Minero",
	Profession.CARPENTER: "Carpintero",
	Profession.MASON: "Albañil",
	Profession.SMITH: "Herrero",
	Profession.COOK: "Cocinero",
	Profession.BREWER: "Cervecero",
	Profession.FARMER: "Granjero",
	Profession.FISHER: "Pescador",
	Profession.WOODCUTTER: "Leñador",
	Profession.ENGRAVER: "Grabador",
	Profession.MECHANIC: "Mecánico",
	Profession.DOCTOR: "Médico",
	Profession.ADMINISTRATOR: "Administrador",
	Profession.MILITARY: "Militar",
	Profession.NOBLE: "Noble",
	Profession.CRAFTSMAN: "Artesano",
	Profession.JEWELER: "Joyero",
	Profession.ALCHEMIST: "Alquimista",
	Profession.SCRIBE: "Escriba",
	Profession.TRADER: "Comerciante",
	Profession.HUNTER: "Cazador",
	Profession.ARCHITECT: "Arquitecto"
}

var home_z: int = 0
var is_possessed: bool = false
var body: Object = null
var name: String = "Urist"

# Propiedades opcionales aplicadas por CreatureDefinition.
# Los valores vacíos conservan la apariencia normal de los enanos.
var glyph: String = ""
var display_color: Color = Color(0.0, 0.0, 0.0, 0.0)
var size_label: String = "medium"
var intelligence: float = 1.0
var sight_range: int = 8
var is_hostile: bool = false

var tile_pos: Vector3i
var id: int
static var _id_counter: int = 1

## Lee una propiedad de Dictionary u Object sin llamar Object.get() con dos argumentos.
static func _safe_get(source: Variant, property_name: StringName, default_value: Variant = null) -> Variant:
	if source == null:
		return default_value
	if source is Dictionary:
		return source.get(property_name, default_value)
	if source is Object:
		var value: Variant = source.get(property_name)
		return default_value if value == null else value
	return default_value

const HUNGER_ACTION_THRESHOLD: float = 0.35
const THIRST_ACTION_THRESHOLD: float = 0.35
const PERSONAL_FOOD_TARGET: int = 2
const PERSONAL_DRINK_TARGET: int = 2
const ITEM_RESERVATION_TICKS: int = 180
const ITEM_UNREACHABLE_TICKS: int = 120
const MAX_ITEM_SEARCH_DISTANCE: int = 40
const MAX_PATH_CANDIDATES: int = 8
const MAX_STOCKPILE_PATH_CANDIDATES: int = 8
# Un recurso raro nunca puede bloquear indefinidamente a una persona o taller.
# Tras varios intentos se busca un sustituto, se pausa la receta o se cancela.
const IMPOSSIBLE_RESOURCE_REPLAN_TICKS: int = 180
const WORKSHOP_INPUT_WAIT_TICKS: int = 240
const WORKSHOP_INPUT_RETRY_DELAY_TICKS: int = 600
const MAX_WORKSHOP_INPUT_RETRIES: int = 3

const WORK_START_HOUR: int = 6
const RECREATION_START_HOUR: int = 14
const SLEEP_START_HOUR: int = 22
const SEVERE_STRESS_THRESHOLD: float = 0.85
const BREAKDOWN_REQUIRED_MINUTES: int = 360
const BREAKDOWN_COOLDOWN_MINUTES: int = 720

static var _static_namegen = null

var hunger: float = 0.0
var thirst: float = 0.0
var fatigue: float = 0.0
var happiness: float = 0.8
var health: float = 1.0
var inventory: Array = []

# Estado persistente para comida, bebida y transporte. Mantener el objetivo entre
# ticks evita que el enano cambie de objeto cada frame y que varios persigan lo mismo.
var _ai_tick_counter: int = 0
var survival_target_item_id: int = -1
var survival_target_kind: String = ""
var supply_target_item_id: int = -1
var supply_target_kind: String = ""
var haul_target_item_id: int = -1
var hauling_item_id: int = -1
var haul_destination: Vector3i = Vector3i(-1, -1, -1)
# Suministro persistente para talleres. Un operador conserva el mismo material
# hasta entregarlo; no cambia de tronco cada tick.
var workshop_supply_target_item_id: int = -1
var workshop_supply_carried_item_id: int = -1
var workshop_missing_input_signature: String = ""
var workshop_missing_input_ticks: int = 0
var unreachable_item_until: Dictionary = {}

var thoughts: Array = []
var minutes_since_alcohol: int = 0

var skills: Dictionary = {}
var current_task: String = "idle"
var task_progress: float = 0.0
var task_target: Vector3i = Vector3i(-1, -1, -1)
var current_job = null
# Vigilancia de trabajos: evita estados IN_PROGRESS eternos cuando desaparece
# el objetivo, falta un recurso o una ruta deja de existir.
const MAX_JOB_STALLED_TICKS: int = 360
var job_stalled_ticks: int = 0
var job_last_tile_pos: Vector3i = Vector3i(-1, -1, -1)
var job_last_progress: float = 0.0
var hunting_target = null
var is_alive: bool = true
var gender: String = "Male"
var age: int = 20
var birth_year: int = 43
var caste: String = "dwarf"

# Identidad persistente para habitantes de asentamientos mundiales. Estos NPC
# conservan casa, familia y lugar de trabajo, y no toman trabajos de la colonia
# del jugador.
var is_world_settlement_resident: bool = false
var settlement_site_id: int = -1
var settlement_family_id: int = -1
var home_structure_id: int = -1
var work_structure_id: int = -1
var civilization_id: int = -1
var religion_id: int = -1
var settlement_home_position: Vector3i = Vector3i(-1, -1, -1)
var settlement_work_position: Vector3i = Vector3i(-1, -1, -1)
var settlement_leisure_position: Vector3i = Vector3i(-1, -1, -1)
var settlement_work_label: String = "Trabajando"
var settlement_path_target: Vector3i = Vector3i(-9999, -9999, -9999)

var path: Array = []
var path_index: int = 0
var last_pos: Vector3i = Vector3i(-1, -1, -1)
var stuck_counter: int = 0
var move_tick_counter: int = 0
var speed: float = 1.0
var has_moved_this_tick: bool = false
var needs_display_update: bool = true

var strength: float = 5.0 + randi() % 8
var agility: float = 5.0 + randi() % 8
var toughness: float = 5.0 + randi() % 8
var combat_skill: float = 1.0
var weapon_skill: float = 1.0
var shield_skill: float = 0.0
var dodge_skill: float = 1.0
var armor_value: float = 0.0

# Alias compatible con CreatureDefinition. El combate continúa usando armor_value.
var armor: float:
	get:
		return armor_value
	set(value):
		armor_value = value

var equipped_weapon: String = "fist"
var equipped_armor: String = "shirt"
var equipped_shield: String = ""
var equipped_helmet: String = ""
var has_shield: bool = false
var is_military: bool = false
var squad_id: int = -1
var creature_type: String = "dwarf"
var operating_workshop: Object = null

var combat_cooldown: int = 0
var combat_stance: int = 0
var fatigue_level: float = 0.0
var target_entity_id: int = -1
var kill_count: int = 0

var wounds: Array = []
var scars: Array = []
var wounds_head: float = 0.0
var wounds_upper_body: float = 0.0
var wounds_lower_body: float = 0.0
var wounds_arm_l: float = 0.0
var wounds_arm_r: float = 0.0
var wounds_leg_l: float = 0.0
var wounds_leg_r: float = 0.0

var stats_tracker: Dictionary = {
	"kills": 0, "deaths": 0, "damage_dealt": 0.0, "damage_taken": 0.0,
	"battles_fought": 0, "battles_won": 0, "distance_traveled": 0,
	"items_crafted": 0, "trees_cut": 0, "ore_mined": 0, "fish_caught": 0,
	"food_cooked": 0, "drink_brewed": 0, "injuries_sustained": 0,
	"infections_survived": 0, "times_unconscious": 0
}

var personality: Dictionary = {}
var emotions: Array = []
var current_emotion: int = Emotion.CONTENT
var emotion_intensity: float = 0.5
var stress: float = 0.0
var trauma: Array = []

var relationships: Dictionary = {}
var family: Dictionary = { "mother": -1, "father": -1, "spouse": -1, "children": [] }
var friends: Array = []
var rivals: Array = []

var preferences: Dictionary = {}
var memories: Array = []
var recent_events: Array = []

var prayer_counter: int = 0
var meditation_counter: int = 0
var artistic_inspiration: float = 0.0
var creative_works: Array = []

var needs: Dictionary = {}
var mood: int = MoodState.NORMAL
var mood_counter: int = 0
var tantrum_destruction: int = 0
var severe_stress_minutes: int = 0
var breakdown_cooldown_minutes: int = 0

var profession: int = Profession.MINER
var appointed_position: String = ""
var is_noble: bool = false
var noble_rank: int = -1
var demands: Array = []
var mandates: Array = []

var sleep_timer: float = 0.0
var is_sleeping: bool = false
var is_resting_medical: bool = false
var sleep_quality: float = 1.0
var preferred_bed: Vector3i = Vector3i(-1, -1, -1)
var worships: String = "Piedra Primigenia"
var study_target_id: int = -1
var preferred_study_skill: int = -1
var study_session_ticks: int = 0
var productive_idle_ticks: int = 0
var gift_cooldown: int = 0
var room_quality: float = 0.0

var social_timer: float = 0.0
var last_social_interaction: int = 0
var loneliness: float = 0.0

var prayer_timer: float = 0.0
var favored_deity: String = ""
var religious_fervor: float = 0.5

# ---- STRANGE MOOD SYSTEM ----
var strange_mood_type: int = MoodState.STRANGE_MOOD
var strange_mood_phase: int = 0
var strange_mood_workshop_pos: Vector3i = Vector3i(-1, -1, -1)
var strange_mood_workshop_ref = null
var strange_mood_materials_needed: Dictionary = {}
var strange_mood_materials_gathered: Dictionary = {}
var strange_mood_work_progress: float = 0.0
var strange_mood_artifact_type: String = ""
var strange_mood_artifact_name: String = ""
var strange_mood_artifact_material: int = 0
var strange_mood_build_materials_needed: int = 3
var strange_mood_build_materials_delivered: int = 0
var strange_mood_build_target_item_id: int = -1
var strange_mood_build_carried_item_id: int = -1
var strange_mood_artifact_target_item_id: int = -1
var strange_mood_artifact_carried_item_id: int = -1
var strange_mood_missing_material: String = ""
var strange_mood_missing_ticks: int = 0

enum StrangeMoodPhase {
	IDLE,
	SEEKING_WORKSHOP,
	CLAIMED_WORKSHOP,
	GATHERING_MATERIALS,
	WORKING,
	COMPLETING
}

enum StrangeMoodType {
	POSSESSED = 0,
	FEY = 1,
	MACABRE = 2,
	FELL = 3,
	SECRETIVE = 4
}

var preferred_food: String = ""
var preferred_drink: String = "Dwarven Ale"
var preferred_color: Color = Color.BLUE
var preferred_stone: String = "granite"

var learning_counter: float = 0.0
var knowledge: Dictionary = {}

var pain_threshold: float = 50.0
var current_pain: float = 0.0
var is_in_pain: bool = false
var bleeding_rate: float = 0.0
var is_bleeding: bool = false
var infection_chance: float = 0.0
var has_infection: bool = false
var rest_timer: float = 0.0

var nausea: float = 0.0
var is_vomiting: bool = false
var dizziness: float = 0.0
var is_stunned: bool = false
var stun_timer: int = 0

var noise_made: float = 0.0
var stealth_skill: float = 1.0

var territory_home: Vector3i = Vector3i(-1, -1, -1)
var owned_items: Array = []
var claimed_bed: Vector3i = Vector3i(-1, -1, -1)
var claimed_container: Vector3i = Vector3i(-1, -1, -1)
var labor_settings: Dictionary = {}

var is_on_break: bool = false
var break_timer: float = 0.0
var socialized_recently: bool = false

## --- GENETICS & BODY COMPOSITION ---
var genome: RefCounted = null  # DFGenetics.Genome, set on spawn
var body_mass_kg: float = 70.0  # base dwarf mass in kg (modified by genome.size_multiplier)

## --- REPRODUCTION ---
var is_pregnant: bool = false
var pregnancy_progress: float = 0.0
var partner_id: int = -1
var marriage_counter: int = 0
var is_child: bool = false
var mother_id: int = -1
var father_id: int = -1

func _init(pos: Vector3i, dwarf_name: String = ""):
	tile_pos = pos
	id = _id_counter
	_id_counter += 1
	body = DFAnatomy.Body.new("humanoid")
	genome = DFGenetics.Genome.new(1.0, 1.0, 1.0, 1.0).mutate(0.05, 0.1)
	body_mass_kg = 70.0 * genome.size_multiplier
	if dwarf_name == "":
		if _static_namegen == null:
			_static_namegen = preload("res://df_mode/df_namegen.gd").new(randi())
		name = _static_namegen.generate_dwarf_name()
	else:
		name = dwarf_name
	gender = "Male" if randi() % 2 == 0 else "Female"
	_init_personality()
	_init_skills()
	_init_preferences()
	_init_needs()
	age = 20 + randi() % 40
	birth_year = 63 - age

func _init_personality() -> void:
	var all_traits = PersonalityTrait.values()
	for t in all_traits:
		personality[t] = randf_range(0.0, 1.0)

func _init_skills() -> void:
	var all_skills = Skill.values()
	for s in all_skills:
		skills[s] = randi() % 3
	profession = Profession.values()[randi() % Profession.values().size()]

func _init_preferences() -> void:
	var foods = ["Plump Helmet", "Sweet Pod", "Cave Wheat", "Quarry Bush", "Pig Tail",
		"Prepared Meal", "Stew", "Roast", "Biscuits"]
	var drinks = ["Dwarven Ale", "Cave Wine", "Beer", "Mead", "Vodka"]
	var stones = ["granite", "limestone", "sandstone", "marble", "obsidian", "gabbro",
		"diorite", "rhyolite", "basalt"]
	var colors = [Color.RED, Color.BLUE, Color.GREEN, Color.YELLOW, Color.PURPLE,
		Color.ORANGE, Color.CYAN, Color.WHITE, Color.BLACK, Color.GRAY]
	preferred_food = foods[randi() % foods.size()]
	preferred_drink = drinks[randi() % drinks.size()]
	preferred_stone = stones[randi() % stones.size()]
	preferred_color = colors[randi() % colors.size()]

func _init_needs() -> void:
	needs = {
		Need.FOOD: 0.0, Need.DRINK: 0.0, Need.SLEEP: 0.0, Need.SHELTER: 0.0,
		Need.COMFORT: 0.0, Need.SECURITY: 0.0, Need.SOCIAL: 0.0, Need.ESTEEM: 0.0,
		Need.WORK: 0.0, Need.RELIGION: 0.0, Need.ART: 0.0, Need.NATURE: 0.0,
		Need.ORDER: 0.0, Need.PERSONAL_SPACE: 0.0, Need.FAMILY: 0.0,
		Need.LUXURY: 0.0, Need.INTELLECT: 0.0, Need.ADVENTURE: 0.0
	}

func get_skill_level(skill: int) -> int:
	return skills.get(skill, 0)

func add_skill_xp(skill: int, amount: int) -> void:
	var current = skills.get(skill, 0)
	if randi() % 100 < amount:
		skills[skill] = current + 1
		_update_profession()

func _update_profession() -> void:
	var best = _get_best_skill()
	var prof_map = {
		Skill.MINING: Profession.MINER, Skill.CARPENTRY: Profession.CARPENTER,
		Skill.MASONRY: Profession.MASON, Skill.SMITHING: Profession.SMITH,
		Skill.COOKING: Profession.COOK, Skill.BREWING: Profession.BREWER,
		Skill.FARMING: Profession.FARMER, Skill.FISHING: Profession.FISHER,
		Skill.WOODCUTTING: Profession.WOODCUTTER, Skill.ENGRAVING: Profession.ENGRAVER,
		Skill.MECHANICS: Profession.MECHANIC,
		Skill.DOCTORING: Profession.DOCTOR, Skill.DIAGNOSE: Profession.DOCTOR,
		Skill.SURGERY: Profession.CHIEF_MEDICAL_DWARF,
		Skill.DRESSING_WOUNDS: Profession.DOCTOR,
		Skill.ORGANIZING: Profession.ADMINISTRATOR,
		Skill.MILITARY_TACTICS: Profession.MILITARY, Skill.SIEGECRAFT: Profession.MILITARY,
		Skill.TRADING: Profession.TRADER, Skill.DIPLOMACY: Profession.BROKER,
		Skill.LEADERSHIP: Profession.MANAGER,
		Skill.MUSIC: Profession.CRAFTSMAN, Skill.POETRY: Profession.CRAFTSMAN,
		Skill.DANCE: Profession.CRAFTSMAN, Skill.WRITING: Profession.SCRIBE,
		Skill.ALCHEMY: Profession.ALCHEMIST
	}
	var new_prof = prof_map.get(best, Profession.CRAFTSMAN)
	if skills.get(best, 0) >= 3 and new_prof != profession:
		profession = new_prof

func get_trait(trait_id: int) -> float:
	return personality.get(trait_id, 0.5)

func get_personality_description() -> String:
	var desc = ""
	var bravery = get_trait(PersonalityTrait.BRAVERY)
	var greed = get_trait(PersonalityTrait.GREED)
	var sociability = get_trait(PersonalityTrait.SOCIABILITY)
	var compassion = get_trait(PersonalityTrait.COMPASSION)
	var anger = get_trait(PersonalityTrait.ANGER)
	var industry = get_trait(PersonalityTrait.INDUSTRY)

	if bravery > 0.7: desc += "Valiente. "
	elif bravery < 0.3: desc += "Cobarde. "
	if greed > 0.7: desc += "Avaro. "
	if sociability > 0.7: desc += "Sociable. "
	elif sociability < 0.3: desc += "Solitario/a. "
	if compassion > 0.7: desc += "Compasivo/a. "
	elif compassion < 0.3: desc += "Cruel. "
	if anger > 0.7: desc += "Iracundo. "
	if industry > 0.7: desc += "Trabajador/a. "
	elif industry < 0.3: desc += "Vago/a. "
	if desc.is_empty(): desc += "Equilibrado/a."
	return desc.strip_edges()

func add_thought(text: String, happiness_mod: float) -> void:
	thoughts.append(text)
	if thoughts.size() > 12:
		thoughts.pop_front()
	happiness = clampf(happiness + happiness_mod, 0.0, 1.0)

func add_memory(category: String, text: String, intensity: float = 0.5) -> void:
	var memory = {
		"category": category,
		"text": text,
		"intensity": intensity,
		"turn": _get_turn_count(),
		"emotion": current_emotion
	}
	memories.append(memory)
	if memories.size() > 100:
		memories.pop_front()

func _get_turn_count() -> int:
	return Time.get_ticks_msec()

func has_relationship_with(other_id: int) -> bool:
	return relationships.has(other_id)

func get_relationship_value(other_id: int) -> float:
	return relationships.get(other_id, 0.0)

func modify_relationship(other_id: int, delta: float) -> void:
	var current = relationships.get(other_id, 0.0)
	relationships[other_id] = clampf(current + delta, -1.0, 1.0)

func update_emotions() -> void:
	var vital_need_ids: Array[int] = [Need.FOOD, Need.DRINK, Need.SLEEP, Need.SHELTER, Need.SECURITY]
	var secondary_need_ids: Array[int] = [Need.COMFORT, Need.SOCIAL, Need.ESTEEM, Need.WORK, Need.RELIGION, Need.ART, Need.NATURE, Need.ORDER, Need.PERSONAL_SPACE, Need.FAMILY, Need.LUXURY, Need.INTELLECT, Need.ADVENTURE]
	var vital_penalty: float = 0.0
	for need_id: int in vital_need_ids:
		var need_value: float = float(needs.get(need_id, 0.0))
		if need_value > 0.65:
			vital_penalty += (need_value - 0.65) * 0.35
	vital_penalty = minf(vital_penalty, 0.45)
	var secondary_total: float = 0.0
	for secondary_need_id: int in secondary_need_ids:
		secondary_total += float(needs.get(secondary_need_id, 0.0))
	var secondary_average: float = secondary_total / float(maxi(1, secondary_need_ids.size()))
	var secondary_penalty: float = minf(0.15, secondary_average * 0.15)
	var total_unhappiness: float = clampf(stress * 0.35 + vital_penalty + secondary_penalty + (1.0 - happiness) * 0.35, 0.0, 1.0)
	emotion_intensity = total_unhappiness
	if total_unhappiness >= 0.75:
		current_emotion = Emotion.ANGRY
	elif total_unhappiness >= 0.50:
		current_emotion = Emotion.SAD
	elif total_unhappiness <= 0.20 and happiness >= 0.70:
		current_emotion = Emotion.HAPPY
	else:
		current_emotion = Emotion.CONTENT

func _get_game_hour(world) -> int:
	var main_node: Variant = world.get_parent() if world != null and world.has_method("get_parent") else null
	if main_node != null:
		var raw_hour: Variant = main_node.get("_game_hour")
		if raw_hour != null:
			return int(raw_hour) % 24
	var day_time_value: Variant = world.get("day_time") if world != null else null
	if day_time_value != null:
		return int(float(day_time_value) * 24.0) % 24
	return 12

func _is_work_shift(hour: int) -> bool:
	return hour >= WORK_START_HOUR and hour < RECREATION_START_HOUR

func _is_recreation_shift(hour: int) -> bool:
	return hour >= RECREATION_START_HOUR and hour < SLEEP_START_HOUR

func _is_sleep_shift(hour: int) -> bool:
	return hour >= SLEEP_START_HOUR or hour < WORK_START_HOUR

func get_schedule_name(hour: int) -> String:
	if _is_work_shift(hour): return "Trabajo"
	if _is_recreation_shift(hour): return "Ocio"
	return "Sueño"

func get_schedule_end_hour(hour: int) -> int:
	if _is_work_shift(hour): return RECREATION_START_HOUR
	if _is_recreation_shift(hour): return SLEEP_START_HOUR
	return WORK_START_HOUR

func _tick_breakdown_risk(world) -> void:
	if breakdown_cooldown_minutes > 0:
		breakdown_cooldown_minutes -= 1
	if mood not in [MoodState.NORMAL, MoodState.HAPPY, MoodState.UNHAPPY, MoodState.MISERABLE]:
		return
	if stress >= SEVERE_STRESS_THRESHOLD and happiness <= 0.35:
		severe_stress_minutes += 1
	else:
		severe_stress_minutes = maxi(0, severe_stress_minutes - 4)
	if severe_stress_minutes < BREAKDOWN_REQUIRED_MINUTES or breakdown_cooldown_minutes > 0:
		return
	if current_job != null:
		_abandon_current_job(world, true, "El trabajo volvió a la cola por una crisis emocional.")
	if operating_workshop != null:
		_release_operating_workshop(world, true)
	var crisis_roll: float = randf()
	if crisis_roll < 0.01:
		mood = MoodState.BESERK
		mood_counter = 60
	elif crisis_roll < 0.26:
		mood = MoodState.MELANCHOLY
		mood_counter = 120
	else:
		mood = MoodState.TANTRUM
		mood_counter = 60
	severe_stress_minutes = 0

func _finish_breakdown() -> void:
	mood = MoodState.NORMAL
	mood_counter = 0
	breakdown_cooldown_minutes = BREAKDOWN_COOLDOWN_MINUTES
	stress = minf(stress, 0.55)
	happiness = maxf(happiness, 0.45)
	current_task = "idle"
	add_thought("Se recuperó de una crisis emocional y necesita estabilidad.", 0.05)


func update_stress(delta: float) -> void:
	# El sistema anterior sumaba estrés por cada necesidad secundaria alta, por lo
	# que doce necesidades podían llenar la barra en minutos. Ahora las vitales
	# cuentan individualmente y las secundarias aportan un máximo pequeño.
	var stress_change: float = 0.0
	var vital_ids: Array[int] = [Need.FOOD, Need.DRINK, Need.SLEEP, Need.SHELTER, Need.SECURITY]
	var secondary_ids: Array[int] = [Need.COMFORT, Need.SOCIAL, Need.ESTEEM, Need.WORK, Need.RELIGION, Need.ART, Need.NATURE, Need.ORDER, Need.PERSONAL_SPACE, Need.FAMILY, Need.LUXURY, Need.INTELLECT, Need.ADVENTURE]
	for vital_id: int in vital_ids:
		var vital_value: float = float(needs.get(vital_id, 0.0))
		if vital_value > 0.80:
			stress_change += (vital_value - 0.80) * 0.025
		elif vital_value < 0.25:
			stress_change -= 0.0005

	var secondary_pressure: float = 0.0
	for secondary_id: int in secondary_ids:
		secondary_pressure += maxf(0.0, float(needs.get(secondary_id, 0.0)) - 0.80)
	stress_change += minf(0.003, secondary_pressure * 0.001)

	if get_trait(PersonalityTrait.VIOLENCE) > 0.6 and kill_count > 0:
		stress_change -= 0.0005 * float(mini(kill_count, 10))
	if get_trait(PersonalityTrait.FEAR) > 0.6:
		stress_change += 0.0005
	if mood in [MoodState.STRANGE_MOOD, MoodState.FELL_MOOD]:
		stress_change += 0.003
	stress_change -= room_quality * 0.0005
	stress = clampf(stress + stress_change * delta, 0.0, 1.0)

func update_needs(delta: float) -> void:
	needs[Need.FOOD] = minf(1.0, needs[Need.FOOD] + 0.0002 * delta * 60)
	needs[Need.DRINK] = minf(1.0, needs[Need.DRINK] + 0.0003 * delta * 60)
	needs[Need.SLEEP] = minf(1.0, needs[Need.SLEEP] + 0.0004 * delta * 60)
	needs[Need.COMFORT] = minf(1.0, needs[Need.COMFORT] + 0.0001 * delta * 60)
	# Estas necesidades antes nunca aumentaban; por eso estudiar no estaba ligado a una necesidad real.
	needs[Need.WORK] = minf(1.0, needs[Need.WORK] + 0.00022 * delta * 60)
	needs[Need.INTELLECT] = minf(1.0, needs[Need.INTELLECT] + 0.000055 * delta * 60)
	needs[Need.NATURE] = minf(1.0, needs[Need.NATURE] + 0.000035 * delta * 60)
	needs[Need.ADVENTURE] = minf(1.0, needs[Need.ADVENTURE] + 0.000025 * delta * 60)

	if relationships.size() > 0:
		needs[Need.SOCIAL] = minf(1.0, needs[Need.SOCIAL] + 0.0001 * delta * 60)
	if is_military:
		needs[Need.SECURITY] = minf(1.0, needs[Need.SECURITY] + 0.0002 * delta * 60)
	if is_noble:
		needs[Need.ESTEEM] = minf(1.0, needs[Need.ESTEEM] + 0.0003 * delta * 60)
	if religious_fervor > 0.6:
		needs[Need.RELIGION] = minf(1.0, needs[Need.RELIGION] + 0.0002 * delta * 60)

	needs[Need.SECURITY] = minf(1.0, needs[Need.SECURITY] + 0.0001 * delta * 60)
	needs[Need.ORDER] = minf(1.0, needs[Need.ORDER] + 0.00005 * delta * 60)

func get_most_pressing_need() -> int:
	var highest = Need.FOOD
	var highest_val = -1.0
	for n in needs:
		var v = needs[n]
		if v > highest_val:
			highest_val = v
			highest = n
	return highest

func get_need_name(need: int) -> String:
	var names = {
		Need.FOOD: "Comida", Need.DRINK: "Bebida", Need.SLEEP: "Sueño",
		Need.SHELTER: "Refugio", Need.COMFORT: "Confort", Need.SECURITY: "Seguridad",
		Need.SOCIAL: "Social", Need.ESTEEM: "Estima", Need.WORK: "Trabajo",
		Need.RELIGION: "Religión", Need.ART: "Arte", Need.NATURE: "Naturaleza",
		Need.ORDER: "Orden", Need.PERSONAL_SPACE: "Espacio Personal",
		Need.FAMILY: "Familia", Need.LUXURY: "Lujo", Need.INTELLECT: "Intelecto",
		Need.ADVENTURE: "Aventura"
	}
	return names.get(need, "Desconocido")

func get_emotion_name(emotion: int) -> String:
	var names = {
		Emotion.HAPPY: "Feliz", Emotion.SAD: "Triste", Emotion.ANGRY: "Enojado",
		Emotion.FEARFUL: "Asustado", Emotion.SURPRISED: "Sorprendido",
		Emotion.DISGUSTED: "Disgustado", Emotion.PROUD: "Orgulloso",
		Emotion.ASHAMED: "Avergonzado", Emotion.JEALOUS: "Celoso",
		Emotion.LOVESTRUCK: "Enamorado", Emotion.CONTENT: "Contento",
		Emotion.FRUSTRATED: "Frustrado", Emotion.HOPEFUL: "Esperanzado",
		Emotion.GRIEVING: "Afligido", Emotion.EUPHORIC: "Eufórico",
		Emotion.NOSTALGIC: "Nostálgico", Emotion.BORED: "Aburrido",
		Emotion.EXCITED: "Emocionado", Emotion.GRATEFUL: "Agradecido",
		Emotion.LONELY: "Solitario", Emotion.WORRIED: "Preocupado",
		Emotion.DETERMINED: "Determinado", Emotion.CONFUSED: "Confundido",
		Emotion.EMBARRASSED: "Avergonzado"
	}
	return names.get(emotion, "Normal")

func get_mood_name() -> String:
	var names = {
		MoodState.NORMAL: "Normal", MoodState.HAPPY: "Feliz",
		MoodState.UNHAPPY: "Infeliz", MoodState.MISERABLE: "Miserable",
		MoodState.TANTRUM: "¡PATALETA!", MoodState.MELANCHOLY: "Melancólico",
		MoodState.BESERK: "¡BESERK!",
		MoodState.STRANGE_MOOD: "¡MODO EXTRAÑO!",
		MoodState.FELL_MOOD: "¡MODO SINIESTRO!",
		MoodState.MACABRE_MOOD: "Modo Macabro",
		MoodState.SECRETIVE_MOOD: "Modo Secreto"
	}
	return names.get(mood, "Normal")

func get_mood_color() -> Color:
	match mood:
		MoodState.NORMAL: return Color("#88CCFF")
		MoodState.HAPPY: return Color("#44FF44")
		MoodState.UNHAPPY: return Color("#FFAA00")
		MoodState.MISERABLE: return Color("#FF4444")
		MoodState.TANTRUM: return Color("#FF2200")
		MoodState.MELANCHOLY: return Color("#8844FF")
		MoodState.BESERK: return Color("#FF0000")
		MoodState.STRANGE_MOOD: return Color("#FFFF00")
		MoodState.FELL_MOOD: return Color("#440000")
		MoodState.MACABRE_MOOD: return Color("#880044")
		MoodState.SECRETIVE_MOOD: return Color("#444488")
		_: return Color("#88CCFF")

func get_description() -> String:
	var desc = "%s, %s %s" % [name, PROFESSION_NAMES.get(profession, "Ciudadano"), gender]
	if is_noble:
		desc += ", Noble (%s)" % appointed_position
	if is_military:
		desc += ", Militar"
	return desc

func get_full_description() -> String:
	var desc = get_description()
	desc += "\nEdad: %d | Salud: %.0f%%" % [age, health * 100]
	desc += "\nEstado de Ánimo: %s" % get_mood_name()
	desc += "\nEmoción: %s (%.0f%%)" % [get_emotion_name(current_emotion), emotion_intensity * 100]
	desc += "\nEstrés: %.0f%% | Felicidad: %.0f%%" % [stress * 100, happiness * 100]
	desc += "\nPersonalidad: %s" % get_personality_description()
	return desc

func get_skill_description() -> String:
	var best = _get_best_skill()
	var skill_name = Skill.keys()[best].to_lower().capitalize()
	var level = skills[best]
	var level_name = ""
	match level:
		0: level_name = "Novato"
		1: level_name = "Aprendiz"
		2: level_name = "Principiante"
		3: level_name = "Competente"
		4: level_name = "Experimentado"
		5: level_name = "Experto"
		6: level_name = "Maestro"
		7: level_name = "Gran Maestro"
		8: level_name = "Legendario"
		_: level_name = "Nivel %d" % level
	return "%s: %s (%d)" % [skill_name, level_name, level]

func get_relationship_summary() -> String:
	var text = ""
	if friends.size() > 0:
		text += "Amigos: %d\n" % friends.size()
	if rivals.size() > 0:
		text += "Rivales: %d\n" % rivals.size()
	if family.spouse >= 0:
		text += "Casado/a\n"
	if family.children.size() > 0:
		text += "Hijos: %d\n" % family.children.size()
	var total_rels = relationships.size()
	if total_rels > 0:
		var avg = 0.0
		for v in relationships.values():
			avg += v
		avg /= total_rels
		text += "Relaciones totales: %d (Promedio: %.0f%%)" % [total_rels, avg * 50.0 + 50.0]
	else:
		text += "Sin relaciones sociales."
	return text

func update_pain_and_bleeding(delta: float) -> void:
	if bleeding_rate > 0:
		health -= bleeding_rate * delta * 0.01
		bleeding_rate *= (1.0 - delta * 0.01)
		if bleeding_rate < 0.01:
			bleeding_rate = 0.0
			is_bleeding = false

	if has_infection:
		var infection_damage = 0.1 * delta
		health -= infection_damage * 0.01
		needs[Need.SLEEP] = minf(1.0, needs[Need.SLEEP] + infection_damage * 0.1)
		stress += infection_damage * 0.05

	if current_pain > pain_threshold:
		is_in_pain = true
		speed *= 0.5
		if randi() % 100 < int(current_pain * 0.1):
			is_stunned = true
			stun_timer = 1
	else:
		is_in_pain = false

	current_pain = maxf(0.0, current_pain - delta * 0.5)

	if health <= 0.0:
		is_alive = false
		current_task = "dead"

func inflict_pain(amount: float) -> void:
	current_pain += amount
	if current_pain > 30 and randi() % 3 == 0:
		add_thought("Siente un dolor agónico.", -0.08)
		stress += 0.05

func apply_bleeding(rate: float) -> void:
	bleeding_rate += rate
	is_bleeding = true

func apply_infection_risk(amount: float) -> void:
	if randi() % 100 < int(amount):
		has_infection = true
		add_thought("La herida se ha infectado. Duele y huele mal.", -0.1)

func rest_and_recover(delta: float) -> void:
	if is_sleeping:
		var recovery_rate = 0.001 * delta * 60 * (1.0 + sleep_quality * 0.5)
		health = minf(1.0, health + recovery_rate)
		if bleeding_rate > 0:
			bleeding_rate *= (1.0 - delta * 0.05)
			if bleeding_rate < 0.01:
				bleeding_rate = 0.0
				is_bleeding = false
		if has_infection:
			infection_chance -= 0.01 * delta * 60
			if infection_chance <= 0:
				has_infection = false
				stats_tracker["infections_survived"] += 1
				add_thought("Su cuerpo venció la infección.", 0.05)
		rest_timer += delta
		if rest_timer > 100:
			add_thought("Descansó y se siente mejor.", 0.03)
			rest_timer = 0
		# Heal wounds slowly over time during rest
		for w in wounds:
			if not w.get("healed", false):
				w["damage"] -= delta * 0.01
				if w["damage"] <= 2.0:
					w["healed"] = true
					w["healed_turn"] = _get_turn_count()
					add_thought("Una herida en su cuerpo sanó.", 0.02)
					scars.append({"part": w["part"], "original_severity": w["severity"], "turn": w["turn"]})
		# Recover stat penalties from wounds
		var sum_healed = 0
		for w_699 in wounds:
			if w_699.get("healed", false):
				sum_healed += 1
		if sum_healed > 0 and sum_healed >= wounds.size() * 0.5:
			agility = minf(agility + delta * 0.01, 13.0)
			weapon_skill = minf(weapon_skill + delta * 0.01, 5.0)
			speed = minf(speed + delta * 0.01, 1.0)

func take_damage(damage: float, body_part: int, is_critical: bool) -> bool:
	stats_tracker["damage_taken"] += damage
	stats_tracker["injuries_sustained"] += 1

	var effective_damage = damage * (1.0 - toughness / 100.0)
	health -= effective_damage / 100.0
	inflict_pain(effective_damage * 0.5)

	if effective_damage > 3:
		apply_bleeding(effective_damage * 0.01)
		apply_infection_risk(effective_damage * 0.3)

	var consciousness_check = current_pain + effective_damage * 2.0
	if consciousness_check > 80.0 and randi() % 100 < int(consciousness_check * 0.3):
		is_stunned = true
		stun_timer = 2 + randi() % 3
		stats_tracker["times_unconscious"] += 1
		add_thought("El dolor es insoportable. Pierde el conocimiento.", -0.15)
		_add_log_if_possible("%s cayó inconsciente por el dolor." % name)

	if health <= 0.0:
		health = 0.0
		is_alive = false
		current_task = "dead"
		return true

	var severity = "superficial"
	if effective_damage > 5: severity = "leve"
	if effective_damage > 12: severity = "moderada"
	if effective_damage > 20: severity = "grave"
	if effective_damage > 35: severity = "mortal"

	var wound = {"part": body_part, "damage": effective_damage, "severity": severity, "turn": _get_turn_count(), "healed": false}
	wounds.append(wound)

	match body_part:
		0: wounds_head += effective_damage * 0.15
		2: wounds_upper_body += effective_damage * 0.08
		3: wounds_lower_body += effective_damage * 0.08
		4, 5: agility = maxf(1.0, agility - effective_damage * 0.03)
		6, 7: weapon_skill = maxf(0.0, weapon_skill - effective_damage * 0.05)
		8, 9: speed = maxf(0.3, speed - effective_damage * 0.03)

	if body_part == 0 and effective_damage > 15:
		is_alive = false
		current_task = "dead"
		return true

	if effective_damage > 10:
		var injury_text = ""
		match body_part:
			0: injury_text = "%s sufrió una herida %s en la cabeza." % [name, severity]
			2: injury_text = "%s sufrió una herida %s en el torso." % [name, severity]
			4, 5: injury_text = "%s sufrió una herida %s en el brazo." % [name, severity]
			8, 9: injury_text = "%s sufrió una herida %s en la pierna." % [name, severity]
			_: injury_text = "%s sufrió una herida %s." % [name, severity]
		if not injury_text.is_empty():
			add_memory("injury", injury_text, effective_damage / 30.0)

	return false

func _add_log_if_possible(msg: String) -> void:
	if DFCombat and is_instance_valid(DFCombat):
		pass

func get_combat_attack_stats() -> Dictionary:
	var wep_data = DFCombat.get_weapon_base_damage(equipped_weapon)
	return {
		"strength": strength * (0.5 + health * 0.5),
		"agility": agility * (0.5 + health * 0.5),
		"attack_skill": combat_skill,
		"weapon_skill_level": weapon_skill,
		"can_parry": weapon_skill > 2.0,
		"stance": combat_stance,
		"speed": speed * (1.0 - fatigue_level * 0.3),
		"fatigue": fatigue_level,
		"weapon_data": wep_data
	}

func get_combat_defense_stats() -> Dictionary:
	var final_armor = armor_value
	for item in inventory:
		if item is DFItem and item.is_armor:
			final_armor = maxf(final_armor, item.get_effective_armor_protection())
	if equipped_shield != "":
		var shield_armor = DFCombat.get_armor_protection(equipped_shield)
		final_armor = maxf(final_armor, shield_armor)
	var wep_data = DFCombat.get_weapon_base_damage(equipped_weapon)
	return {
		"agility": agility * (0.5 + health * 0.5),
		"defense_skill": dodge_skill * (0.5 + health * 0.5),
		"armor_value": final_armor,
		"has_shield": has_shield,
		"shield_skill": shield_skill,
		"can_parry": weapon_skill > 2.0,
		"fatigue": fatigue_level,
		"weapon_reach": wep_data.get("reach", DFCombat.REACH_TINY)
	}

func get_entity_name() -> String:
	return name

func equip_weapon(wep_name: String) -> void:
	equipped_weapon = wep_name
	if wep_name != "fist":
		current_task = "Equipado: %s" % DFCombat.get_weapon_base_damage(wep_name).get("name", wep_name)

func equip_armor(armor_name: String) -> void:
	equipped_armor = armor_name
	armor_value = DFCombat.get_armor_protection(armor_name)

func equip_shield(sh_name: String) -> void:
	equipped_shield = sh_name
	has_shield = sh_name != ""
	shield_skill = skills.get(DFDwarf.Skill.MASONRY, 0) * 0.5 + 1.0

func get_weapon_skill_for_current() -> int:
	var wep = DFCombat.get_weapon_base_damage(equipped_weapon)
	return wep.get("skill", DFCombat.WeaponSkill.SCRATCH)

func get_equipment_string() -> String:
	var parts = []
	if equipped_weapon != "fist":
		parts.append(DFCombat.get_weapon_base_damage(equipped_weapon).get("name", equipped_weapon))
	if equipped_shield != "":
		parts.append("Escudo")
	if equipped_armor != "shirt":
		parts.append("Armadura")
	if parts.is_empty():
		return "Sin equipo"
	return ", ".join(parts)

func tick(world, jobs: Array, minute_ticked: bool = false) -> void:
	_ai_tick_counter += 1
	if minute_ticked:
		_cleanup_unreachable_item_cache()
	if not is_alive:
		if current_job != null:
			_abandon_current_job(world, true, "El trabajo volvió a la cola porque el enano ya no está disponible.")
		_release_operating_workshop(world, true)
		_release_all_item_reservations(world)
		return


	# Las tareas autónomas son descripciones de un tick. Sin este reinicio, "Estudiando"
	# permanecía para siempre y bloqueaba socialización, inspección y nuevas decisiones.
	if current_job == null and operating_workshop == null and not is_sleeping and not is_resting_medical and mood == MoodState.NORMAL:
		current_task = "idle"
	if gift_cooldown > 0 and minute_ticked:
		gift_cooldown -= 1
	has_moved_this_tick = false
	needs_display_update = false
	var delta_game_minute: float = 1.0
	var game_hour: int = _get_game_hour(world)
	var is_work_time: bool = _is_work_shift(game_hour)
	var is_recreation_time: bool = _is_recreation_shift(game_hour)
	var is_sleep_time: bool = _is_sleep_shift(game_hour)

	if minute_ticked:
		hunger += 0.00024
		thirst += 0.00036
		fatigue += 0.0005
		minutes_since_alcohol += 1
		update_needs(delta_game_minute)
		update_stress(delta_game_minute)
		if is_work_time:
			needs[Need.WORK] = maxf(0.0, float(needs.get(Need.WORK, 0.0)) - 0.004)
		elif is_recreation_time:
			stress = maxf(0.0, stress - 0.002)
			needs[Need.SOCIAL] = maxf(0.0, float(needs.get(Need.SOCIAL, 0.0)) - 0.001)
			needs[Need.NATURE] = maxf(0.0, float(needs.get(Need.NATURE, 0.0)) - 0.001)
		elif is_sleep_time:
			stress = maxf(0.0, stress - 0.004)
		update_emotions()
		_tick_breakdown_risk(world)
		update_pain_and_bleeding(delta_game_minute)
		tick_metabolism(world)
		
		# --- EXPOSICIÓN A MIASMA ---
		var tile_subs = world.get_splatters_at(tile_pos)
		if tile_subs.has("miasma") and tile_subs["miasma"] > 0.01:
			stress = minf(1.0, stress + 0.05)
			if randf() < 0.06:
				body.nausea = minf(1.0, body.nausea + 0.3)
				add_thought("Sufrió asco y náuseas por la miasma pestilente.", -0.06)
			else:
				add_thought("Siente asco por la miasma pestilente que inunda el lugar.", -0.03)

		# Apply step coatings when on a tile with splatters
		var standing: Array = []
		for bp in body.parts:
			if bp.can_stand:
				standing.append(bp)
		if not standing.is_empty():
			world.apply_step_coatings(tile_pos, standing)
			world.deposit_footprint(tile_pos, standing)

	# --- SISTEMA DE REPOSO MÉDICO ---
	var is_injured_or_sick = health < 0.70 or has_infection or is_bleeding
	if is_injured_or_sick and not is_sleeping and not is_possessed:
		is_resting_medical = true
		current_task = "Descanso Médico"
		
		# Buscar cama si no tiene
		if preferred_bed.x < 0:
			var bed_pos = _find_unclaimed_bed(world)
			if bed_pos.x >= 0:
				_claim_bed(world, bed_pos)
				
		# Desplazarse a la cama
		if preferred_bed.x >= 0:
			var dist_to_bed = abs(tile_pos.x - preferred_bed.x) + abs(tile_pos.z - preferred_bed.z)
			if dist_to_bed > 0:
				_move_toward(world, preferred_bed)
				return
		
		# Reposar en cama
		rest_and_recover(1.0)
		return

	if is_resting_medical and not is_injured_or_sick:
		is_resting_medical = false
		if current_task == "Descanso Médico":
			current_task = "idle"

	if minutes_since_alcohol > 1440:
		if minutes_since_alcohol % 60 == 0 and randi() % 5 == 0:
			add_thought("Sintió flojera y desgana por falta de alcohol.", -0.03)
		speed = 0.5
	else:
		speed = 1.0

	# Fatigue recovery
	if fatigue_level > 0.0:
		if is_sleeping:
			fatigue_level = maxf(0.0, fatigue_level - 0.05)
		else:
			fatigue_level = maxf(0.0, fatigue_level - 0.01)

	# Natural healing from rest
	if is_sleeping:
		rest_and_recover(minf(1.0, delta_game_minute))

	if current_emotion != Emotion.CONTENT and randi() % 20 == 0:
		add_thought("Reflexiona sobre su vida en la fortaleza.", 0.01)

	if randi() % 100 < 5 and memories.size() > 5:
		var mem = memories[randi() % memories.size()]
		var mem_feeling = 0.02 if mem.get("intensity", 0.5) > 0.5 else -0.02
		add_thought("Recuerda: " + mem.get("text", "algo del pasado"), mem_feeling)

	if hunger > 1.0 or thirst > 1.0:
		# Muerte por inanicion: se acelera cuanto mas tiempo pasa sin comer/beber
		var starvation_rate = 0.08 + (hunger - 1.0) * 0.1 + (thirst - 1.0) * 0.1
		health -= starvation_rate
		if randi() % 10 == 0:
			if hunger > 1.5:
				add_thought("El hambre lo consume. Sus fuerzas se agotan.", -0.08)
			elif thirst > 1.5:
				add_thought("La sed lo atormenta. Necesita agua desesperadamente.", -0.08)
			else:
				add_thought("Sintió una terrible debilidad por la inanición.", -0.05)
	if health <= 0.0:
		if current_job != null:
			_abandon_current_job(world, true, "El trabajo volvió a la cola tras la muerte del trabajador.")
		_release_operating_workshop(world, true)
		is_alive = false
		_release_all_item_reservations(world)
		current_task = "dead"
		# Mensaje de muerte
		if hunger > 1.0:
			world.messages.append("! %s ha muerto de hambre!" % name)
		elif thirst > 1.0:
			world.messages.append("! %s ha muerto de sed!" % name)
		else:
			world.messages.append("! %s ha muerto por desnutricion!" % name)
		return

	# STRANGE MOOD TRIGGER CHECK
	if mood == MoodState.NORMAL and minute_ticked:
		_check_strange_mood_trigger(world)

	if fatigue > 1.0:
		happiness -= 0.01
		if randi() % 30 == 0:
			add_thought("Sintió agotamiento extremo por falta de descanso.", -0.04)

	if mood == MoodState.TANTRUM:
		current_task = "¡PATALETA! (Desahogándose)"
		if minute_ticked:
			mood_counter -= 1
			if mood_counter <= 0:
				_finish_breakdown()
		return

	if mood == MoodState.BESERK:
		current_task = "¡BESERK! (Fuera de control)"
		if minute_ticked:
			mood_counter -= 1
			if mood_counter <= 0:
				_finish_breakdown()
		return

	if mood == MoodState.MELANCHOLY:
		current_task = "Melancólico (recuperándose)"
		if minute_ticked:
			mood_counter -= 1
			if mood_counter <= 0:
				_finish_breakdown()
		return

	if mood == MoodState.STRANGE_MOOD or mood == MoodState.FELL_MOOD or mood == MoodState.MACABRE_MOOD or mood == MoodState.SECRETIVE_MOOD:
		_process_strange_mood(world)
		return


	if is_sleeping:
		if not is_sleep_time:
			is_sleeping = false
			current_task = "Preparándose para trabajar"
		else:
			current_task = "Durmiendo"
			if minute_ticked:
				fatigue = maxf(0.0, fatigue - 0.003)
				needs[Need.SLEEP] = maxf(0.0, float(needs.get(Need.SLEEP, 0.0)) - 0.004)
				rest_and_recover(1.0)
			return

	# --- HORARIO DIARIO FIJO ---
	# 22:00-06:00 sueño, 06:00-14:00 trabajo, 14:00-22:00 ocio.
	var is_meal_time: bool = game_hour in [6, 14, 21]

	# PRIORIDAD 1: Necesidades de supervivencia críticas
	if hunger > 0.85 or thirst > 0.85:
		if _satisfy_needs(world):
			update_emotions()
			return
	# PRIORIDAD 2: Descanso nocturno obligatorio (22:00-06:00).
	if is_sleep_time:
		if _try_sleep(world, true):
			update_emotions()
			return

	# PRIORIDAD 3: Almuerzo y cena comunitaria
	if is_meal_time and (hunger > 0.35 or thirst > 0.35):
		if _satisfy_needs(world):
			update_emotions()
			return

	# Los residentes históricos conservan la simulación completa de necesidades,
	# emociones, memoria, heridas y relaciones. Después ejecutan su rutina local.
	# No dependen de estar visibles en cámara: DFMain los actualiza por turnos.
	if is_world_settlement_resident:
		_tick_world_settlement_resident(world, game_hour, minute_ticked)
		update_emotions()
		return


	# PRIORIDAD 4: Un trabajo asignado se ejecuta únicamente de 06:00 a 14:00.
	if current_job != null and is_work_time:
		_work_on_job(world)
		update_emotions()
		return

	# PRIORIDAD 5: Depositar producción y materiales antes de aceptar otra tarea.
	if is_work_time and current_job == null and operating_workshop == null:
		if _try_store_surplus_inventory(world):
			update_emotions()
			return

	# PRIORIDAD 6: Atender la cola de producción de los talleres. El operador
	# también transporta sus propios insumos antes de fabricar.
	if is_work_time and current_job == null and operating_workshop == null:
		_check_workshops(world)
	if operating_workshop != null and is_work_time:
		_operate_workshop(world)
		update_emotions()
		return

	# PRIORIDAD 7: Buscar el trabajo general de mayor prioridad.
	if is_work_time and current_job == null and operating_workshop == null:
		if not jobs.is_empty():
			_pick_up_job(world, jobs)
			if current_job != null:
				_work_on_job(world)
				update_emotions()
				return

	# PRIORIDAD 8: Recreación, acicalado y religión (14:00-22:00).
	if is_recreation_time:
		# Higiene e inspección también son actividades de ocio. Una actividad elegida
		# termina la decisión del tick para que current_task no cambie varias veces.
		if randf() < 0.12:
			current_task = "idle"
			tick_hygiene(world)
			if current_task != "idle":
				update_emotions()
				return
		if randf() < 0.10:
			current_task = "idle"
			tick_inspect(world)
			if current_task != "idle":
				update_emotions()
				return

		# Acicalado
		var bp_dirty_count = 0
		for bp_1104 in body.parts:
			if not bp_1104.coatings.is_empty():
				bp_dirty_count += 1
		if bp_dirty_count > 0 and randf() < 0.3:
			tick_grooming()
			current_task = "Acicalándose"
			update_emotions()
			return

		# Oración en el Templo (religión e ideales)
		if randf() < 0.2:
			var temple_pos = _find_nearby_building_type(world, 22) # 22 = TEMPLE
			if temple_pos.x >= 0:
				var dist = abs(tile_pos.x - temple_pos.x) + abs(tile_pos.z - temple_pos.z)
				if dist > 1:
					_move_toward(world, temple_pos)
					current_task = "Yendo al Templo a orar"
				else:
					current_task = "Orando a la %s" % worships
					if randf() < 0.05:
						add_thought("Sintió paz espiritual tras orar a la deidad.", 0.03)
						happiness = minf(1.0, happiness + 0.01)
				update_emotions()
				return

		# Socializar en la taberna / plaza
		if randf() < 0.4:
			if _try_socialize(world):
				current_task = "Socializando en la taberna"
				update_emotions()
				return

		if randf() < 0.25:
			var leisure_skill: int = randi() % 7
			add_skill_xp(leisure_skill, 1)
			needs[Need.INTELLECT] = maxf(0.0, float(needs.get(Need.INTELLECT, 0.0)) - 0.04)
			current_task = "Estudiando durante su tiempo libre"
		else:
			current_task = "Paseando durante su tiempo libre"
			_idle_wander(world)
		update_emotions()
		return

	if is_work_time and current_job == null and operating_workshop == null:
		tick_autonomous_survival(world, false)
		update_emotions()
		return

	update_emotions()


func _tick_world_settlement_resident(world: Object, game_hour: int, minute_ticked: bool) -> void:
	if world == null:
		current_task = "Esperando que cargue su asentamiento"
		return

	if _is_work_shift(game_hour):
		var work_target: Vector3i = settlement_work_position
		if work_target.x < 0:
			work_target = territory_home
		if work_target.x >= 0:
			var work_distance: int = abs(tile_pos.x - work_target.x) + abs(tile_pos.z - work_target.z) + abs(tile_pos.y - work_target.y) * 2
			if work_distance > 1:
				current_task = "Yendo a su trabajo: %s" % settlement_work_label
				_move_settlement_resident_toward(world, work_target)
				return
		current_task = settlement_work_label
		if minute_ticked:
			var practiced_skill: int = _settlement_profession_skill()
			if practiced_skill >= 0:
				add_skill_xp(practiced_skill, 1)
			needs[Need.WORK] = maxf(0.0, float(needs.get(Need.WORK, 0.0)) - 0.01)
		return

	if _is_recreation_shift(game_hour):
		var leisure_target: Vector3i = settlement_leisure_position
		if leisure_target.x < 0:
			leisure_target = territory_home
		if leisure_target.x >= 0:
			var leisure_distance: int = abs(tile_pos.x - leisure_target.x) + abs(tile_pos.z - leisure_target.z) + abs(tile_pos.y - leisure_target.y) * 2
			if leisure_distance > 2:
				current_task = "Yendo a la plaza de su aldea"
				_move_settlement_resident_toward(world, leisure_target)
				return
		current_task = "Conversando con sus vecinos"
		if minute_ticked:
			needs[Need.SOCIAL] = maxf(0.0, float(needs.get(Need.SOCIAL, 0.0)) - 0.01)
			stress = maxf(0.0, stress - 0.003)
		return

	var home_target: Vector3i = settlement_home_position
	if home_target.x < 0:
		home_target = preferred_bed
	if home_target.x >= 0:
		var home_distance: int = abs(tile_pos.x - home_target.x) + abs(tile_pos.z - home_target.z) + abs(tile_pos.y - home_target.y) * 2
		if home_distance > 1:
			current_task = "Regresando a su casa"
			_move_settlement_resident_toward(world, home_target)
			return
	current_task = "Descansando en su hogar"

func _move_settlement_resident_toward(world: Object, target: Vector3i) -> void:
	if world == null or target.x < 0:
		return
	if tile_pos == target:
		return

	# La ruta se calcula una sola vez por destino/turno y después se reutiliza.
	# Estos residentes pueden compartir una casilla de paso; evitar el escaneo
	# O(n²) de colisiones es esencial cuando una aldea tiene muchas familias.
	if settlement_path_target != target or path.is_empty() or path_index >= path.size():
		settlement_path_target = target
		path = DFPathfinding.find_path(world, tile_pos, target, true)
		path_index = 0
		if path.is_empty():
			return

	var next_step: Vector3i = path[path_index]
	if world.is_blocked(next_step) and next_step != target:
		path.clear()
		path_index = 0
		return
	tile_pos = next_step
	path_index += 1
	has_moved_this_tick = true

func _settlement_profession_skill() -> int:
	match profession:
		Profession.CARPENTER: return Skill.CARPENTRY
		Profession.MASON: return Skill.MASONRY
		Profession.COOK: return Skill.COOKING
		Profession.BREWER: return Skill.BREWING
		Profession.FARMER: return Skill.FARMING
		Profession.FISHER: return Skill.FISHING
		Profession.WOODCUTTER: return Skill.WOODCUTTING
		Profession.SMITH: return Skill.SMITHING
		Profession.TRADER: return Skill.TRADING
		Profession.DOCTOR: return Skill.DOCTORING
		Profession.CRAFTSMAN: return Skill.CRAFTSMAN
		_: return Skill.ORGANIZING

func _find_nearby_master_for_skill(world, skill_id: int):
	var my_level = get_skill_level(skill_id)
	var best_master = null
	var best_level = my_level
	var nearest_dist = 15.0
	for e in world.entities:
		var is_dwarf = e.get("creature_type") == "dwarf"
		var is_alive_check = e.get("is_alive")
		if is_dwarf and e != self and (is_alive_check == null or is_alive_check == true):
			var lvl = e.get_skill_level(skill_id) if e.has_method("get_skill_level") else 0
			if lvl > best_level:
				var d = abs(e.tile_pos.x - tile_pos.x) + abs(e.tile_pos.z - tile_pos.z)
				if d < nearest_dist:
					nearest_dist = d
					best_master = e
	return best_master

func _find_nearby_building_type(world, b_type: int) -> Vector3i:
	var nearest_pos = Vector3i(-1, -1, -1)
	var nearest_dist = 30.0
	if world.buildings != null:
		for b in world.buildings:
			var bt = b.get("type") if "type" in b else 0
			if bt == b_type:
				var bpos = b.get("tile_pos") if "tile_pos" in b else Vector3i.ZERO
				var d = abs(tile_pos.x - bpos.x) + abs(tile_pos.z - bpos.z)
				if d < nearest_dist:
					nearest_dist = d
					nearest_pos = bpos
	return nearest_pos


func _try_socialize(world) -> bool:
	var target = null
	for e in world.entities:
		var is_dwarf = e.get("creature_type") == "dwarf"
		var is_alive_check = e.get("is_alive")
		if is_dwarf and e != self and (is_alive_check == null or is_alive_check == true):
			var d = abs(e.tile_pos.x - tile_pos.x) + abs(e.tile_pos.z - tile_pos.z)
			if d <= 2:
				target = e
				break

	if target != null:
		var relation = get_relationship_value(target.id)
		var social_text = ""
		var social_mod = 0.0
		if relation > 0.3:
			social_text = "%s charla amistosamente con %s." % [name, target.name]
			social_mod = 0.04
			modify_relationship(target.id, 0.02)
		elif relation < -0.3:
			social_text = "%s ignora fríamente a %s." % [name, target.name]
			social_mod = -0.01
		else:
			social_text = "%s conversa con %s sobre el trabajo en la fortaleza." % [name, target.name]
			social_mod = 0.02
			modify_relationship(target.id, 0.01)

		add_thought(social_text, social_mod)
		needs[Need.SOCIAL] = maxf(0.0, needs[Need.SOCIAL] - 0.2)
		current_task = "Socializando"
		last_social_interaction = _get_turn_count()
		return true
	return false

func _try_create_art(world) -> void:
	var art_types = ["poema", "canción", "escultura", "grabado"]
	var chosen = art_types[randi() % art_types.size()]
	var art_name = "%s sobre %s" % [chosen, world.world_name]
	creative_works.append({
		"type": chosen,
		"name": art_name,
		"quality": randf_range(0.3, 0.9) + artistic_inspiration * 0.2,
		"year": 63
	})
	var quality_desc = "mediocre" if artistic_inspiration < 0.5 else "notable" if artistic_inspiration < 0.8 else "obra maestra"
	add_thought("Creó un %s %s titulado '%s'." % [chosen, quality_desc, art_name], 0.08)
	artistic_inspiration = 0.0
	happiness = minf(1.0, happiness + 0.05)
	current_task = "Creando arte"

func _pick_up_items(world) -> void:
	if inventory.size() >= 5:
		return
	if world.stockpiles.is_empty():
		return

	# First, pick up any items on our current tile (if not already stored in a stockpile)
	var items_to_remove = []
	for ent in world.entities:
		if ent is DFItem and ent.tile_pos == tile_pos:
			if ent.is_food or ent.is_drink:
				continue
			# Check if already in a stockpile
			var already_in_sp = false
			for sp in world.stockpiles:
				if sp.has_tile(tile_pos):
					already_in_sp = true
					break
			if already_in_sp:
				continue
				
			# Limitar capacidad de carga: solo 1 objeto pesado (madera o piedra) a la vez
			var is_heavy = (ent.item_type == "stone" or ent.item_type == "wood")
			if is_heavy:
				var has_heavy = false
				for inv_item in inventory:
					if inv_item.item_type == "stone" or inv_item.item_type == "wood":
						has_heavy = true
						break
				if has_heavy:
					continue # No puede llevar más rocas/troncos pesados
					
			inventory.append(ent)
			items_to_remove.append(ent)
			current_task = "Recolectando " + ent.name
			needs_display_update = true
			if inventory.size() >= 5:
				break

	for item in items_to_remove:
		world.entities.erase(item)

	if not items_to_remove.is_empty():
		return

	# If we are idle and have stockpiles with free space, find the nearest loose item to haul
	if world.stockpiles.is_empty():
		return

	var has_free_space = false
	for sp_fs in world.stockpiles:
		var fp = sp_fs.get_free_tile(world)
		if fp.y != -1:
			has_free_space = true
			break
	if not has_free_space:
		return

	var best_item = null
	var best_dist = 999999
	for ent_h in world.entities:
		if ent_h is DFItem:
			var _decayed = ent_h.get("is_decayed")
			if _decayed == null or _decayed:
				continue
			if ent_h.is_food or ent_h.is_drink:
				continue
			# Check if already in a stockpile
			var in_sp = false
			for sp_h in world.stockpiles:
				if sp_h.has_tile(ent_h.tile_pos):
					in_sp = true
					break
			if in_sp:
				continue

			var d = abs(ent_h.tile_pos.x - tile_pos.x) + abs(ent_h.tile_pos.z - tile_pos.z) + abs(ent_h.tile_pos.y - tile_pos.y) * 2
			if d < best_dist:
				best_dist = d
				best_item = ent_h

	if best_item != null:
		current_task = "Buscando item para almacenar"
		_move_toward(world, best_item.tile_pos)

func _store_items(world: Object) -> void:
	if inventory.is_empty():
		return

	if world.stockpiles.is_empty():
		current_task = "idle"
		return

	var is_on_food_store = false
	for b in world.buildings:
		if b.type == DFBuilding.BuildingType.FOOD_STORE and b.tile_pos == tile_pos:
			is_on_food_store = true
			break

	for sp in world.stockpiles:
		if sp.has_tile(tile_pos) and not sp._has_item_at(world, tile_pos):
			var item = inventory.pop_back()
			item.tile_pos = tile_pos
			item.is_in_stockpile = true
			if is_on_food_store:
				item.is_inside_container = true
			world.entities.append(item)
			current_task = "idle"
			needs_display_update = true
			return

	var best_pos = Vector3i(-1, -1, -1)
	var best_dist = 999999
	for sp_1340 in world.stockpiles:
		var free_pos = sp_1340.get_free_tile(world)
		if free_pos.y != -1:
			var d = abs(free_pos.x - tile_pos.x) + abs(free_pos.z - tile_pos.z) + abs(free_pos.y - tile_pos.y) * 2
			if d < best_dist:
				best_dist = d
				best_pos = free_pos

	if best_pos.y != -1:
		current_task = "Almacenando"
		_move_toward(world, best_pos)
		if tile_pos == best_pos:
			var item_1352 = inventory.pop_back()
			item_1352.tile_pos = tile_pos
			item_1352.is_in_stockpile = true
			var is_on_fs = false
			for b_1356 in world.buildings:
				if b_1356.type == DFBuilding.BuildingType.FOOD_STORE and b_1356.tile_pos == tile_pos:
					is_on_fs = true
					break
			if is_on_fs:
				item_1352.is_inside_container = true
			world.entities.append(item_1352)
			current_task = "idle"
			needs_display_update = true
	else:
		current_task = "idle"

func _drop_active_job_carried_item(world) -> void:
	if current_job == null or not current_job.has_meta("carried_item_id"):
		return
	var carried_job_item_id: int = int(current_job.get_meta("carried_item_id", -1))
	var carried_job_item: DFItem = _get_inventory_item_by_id(carried_job_item_id)
	if carried_job_item == null:
		current_job.set_meta("carried_item_id", -1)
		return
	# Una provisión cuya ruta se canceló no debe volver a ser asignada en el
	# siguiente ciclo del director. El enfriamiento rompe el bucle visible
	# Guardar -> soltar -> volver a Guardar sobre el mismo objeto.
	if current_job.job_type == DFJob.JobType.STORE_IN_CONTAINER:
		carried_job_item.set_meta("storage_blocked_until", _get_world_tick(world) + 600)
	inventory.erase(carried_job_item)
	carried_job_item.tile_pos = tile_pos
	carried_job_item.carried_by_id = -1
	carried_job_item.is_in_stockpile = false
	carried_job_item.is_inside_container = false
	carried_job_item.release_reservation(id)
	if not world.entities.has(carried_job_item):
		world.entities.append(carried_job_item)
	current_job.set_meta("carried_item_id", -1)

func _release_job_item_reservations(world) -> void:
	if current_job == null:
		return
	var reservation_keys: Array[String] = ["target_item_id", "material_item_id"]
	for reservation_key in reservation_keys:
		if not current_job.has_meta(reservation_key):
			continue
		var reserved_item_id: int = int(current_job.get_meta(reservation_key, -1))
		var reserved_item: DFItem = _get_world_item_by_id(world, reserved_item_id)
		if reserved_item != null:
			reserved_item.release_reservation(id)
		current_job.set_meta(reservation_key, -1)
	if current_job.has_meta("carried_item_id"):
		var carried_job_item_id: int = int(current_job.get_meta("carried_item_id", -1))
		var carried_job_item: DFItem = _get_inventory_item_by_id(carried_job_item_id)
		if carried_job_item != null:
			carried_job_item.release_reservation(id)
		current_job.set_meta("carried_item_id", -1)

func _reset_job_runtime_state() -> void:
	task_progress = 0.0
	job_stalled_ticks = 0
	job_last_tile_pos = tile_pos
	job_last_progress = 0.0
	path.clear()
	path_index = 0
	stuck_counter = 0

## Cambia el estado solo si el trabajo sigue activo. Algunas funciones de movimiento
## pueden cancelar el trabajo al detectar una ruta imposible durante el mismo tick.
func _set_current_job_state(new_state: int) -> bool:
	if current_job == null:
		return false
	current_job.state = new_state
	return true

func _abandon_current_job(world, requeue: bool, reason: String = "") -> void:
	if current_job != null:
		# Si una ruta de almacenamiento fue cancelada por ser imposible, marcar
		# también la provisión que aún permanecía en el mundo. Las interrupciones
		# temporales que vuelven a la cola (sueño, crisis recuperable) no la bloquean.
		if not requeue and current_job.job_type == DFJob.JobType.STORE_IN_CONTAINER:
			var blocked_target_id: int = int(current_job.get_meta("target_item_id", -1))
			var blocked_target: DFItem = _get_world_item_by_id(world, blocked_target_id)
			if blocked_target != null:
				blocked_target.set_meta("storage_blocked_until", _get_world_tick(world) + 600)
		# Cualquier objeto ligado al trabajo debe volver al mundo antes de limpiar
		# la metadata. Esto evita provisiones, camas o materiales atrapados para
		# siempre dentro del inventario de un trabajador que abandonó la tarea.
		_drop_active_job_carried_item(world)
		_release_job_item_reservations(world)
		current_job.assigned_dwarf_id = -1
		if requeue:
			_set_current_job_state(DFJob.JobState.UNASSIGNED)
		else:
			_set_current_job_state(DFJob.JobState.CANCELLED)
			current_job.cancel_reason = reason
	current_job = null
	_reset_job_runtime_state()
	current_task = "idle"
	needs_display_update = true
	if not reason.is_empty():
		add_thought(reason, 0.0)

func _tick_job_watchdog(world) -> bool:
	if current_job == null:
		return false
	var moved: bool = tile_pos != job_last_tile_pos
	var progressed: bool = task_progress > job_last_progress + 0.0001
	if moved or progressed:
		job_stalled_ticks = 0
		job_last_tile_pos = tile_pos
		job_last_progress = task_progress
	else:
		job_stalled_ticks += 1
	if job_stalled_ticks <= MAX_JOB_STALLED_TICKS:
		return false
	var should_requeue: bool = current_job != null and current_job.job_type == DFJob.JobType.BUILD_WORKSHOP
	_abandon_current_job(world, should_requeue, "El proyecto de taller volvió a la cola para que otro aldeano continúe desde el progreso existente." if should_requeue else "Abandonó un trabajo imposible o atascado y buscó otra tarea.")
	return true

func assign_job(job) -> void:
	current_job = job
	current_task = job.get_description()
	preferred_study_skill = -1
	study_session_ticks = 0
	productive_idle_ticks = 0
	needs[Need.WORK] = maxf(0.0, needs.get(Need.WORK, 0.0) - 0.12)
	_reset_job_runtime_state()
	job.state = DFJob.JobState.ASSIGNED
	job.assigned_dwarf_id = id

func _work_on_job(world) -> void:
	if is_possessed:
		return
	if current_job == null:
		_idle_wander(world)
		return
	if current_job.state == DFJob.JobState.CANCELLED:
		_abandon_current_job(world, false, current_job.cancel_reason)
		return
	if _tick_job_watchdog(world):
		return
	if current_job.state == DFJob.JobState.IN_PROGRESS:
		current_task = current_job.get_description()
		_execute_job(world)
		return

	# Estos trabajos administran su propio objetivo y navegación. No deben pasar por
	# el movimiento genérico hacia job.tile_pos: pesca apunta al agua, caza a una
	# criatura móvil y los trabajos de transporte usan una posición administrativa.
	var self_directed_job_types: Array[int] = [
		DFJob.JobType.COLLECT_WOOD,
		DFJob.JobType.COLLECT_STONE,
		DFJob.JobType.FISH,
		DFJob.JobType.HUNT,
		DFJob.JobType.STORE_IN_CONTAINER,
		DFJob.JobType.HAUL_ITEM,
		DFJob.JobType.BUILD_WORKSHOP
	]
	if current_job.job_type in self_directed_job_types:
		_set_current_job_state(DFJob.JobState.IN_PROGRESS)
		_execute_job(world)
		return

	if current_job.job_type in [DFJob.JobType.BUILD_WALL, DFJob.JobType.BUILD_FLOOR]:
		var required_material_type: String = str(current_job.get_meta("required_material_type", ""))
		var allowed_material_types: Array[String] = ["stone", "wood", "plank"]
		if not required_material_type.is_empty():
			allowed_material_types = [required_material_type]
		var has_material: bool = false
		for inventory_entry: Variant in inventory:
			if inventory_entry is DFItem:
				var inventory_material: DFItem = inventory_entry
				if inventory_material.item_type in allowed_material_types:
					has_material = true
					break

		if not has_material:
			var best_item: DFItem = null
			var reserved_material_id: int = int(current_job.get_meta("material_item_id", -1))
			best_item = _get_world_item_by_id(world, reserved_material_id)
			if best_item == null or best_item.item_type not in allowed_material_types or not _item_available_for_self(world, best_item):
				if best_item != null:
					best_item.release_reservation(id)
				best_item = null
				var best_dist: int = 999999
				for world_entry: Variant in world.entities:
					if not (world_entry is DFItem):
						continue
					var material_item: DFItem = world_entry
					if material_item.item_type not in allowed_material_types:
						continue
					if material_item.is_inside_container or not _item_available_for_self(world, material_item):
						continue
					var material_distance: int = _item_distance(material_item)
					if material_distance < best_dist:
						best_dist = material_distance
						best_item = material_item
				if best_item != null:
					best_item.reserve_for(id, _get_world_tick(world) + ITEM_RESERVATION_TICKS)
					current_job.set_meta("material_item_id", best_item.id)
					path.clear()
					path_index = 0

			if best_item == null:
				current_task = "Esperando %s para construir" % (required_material_type if not required_material_type.is_empty() else "material")
				return

			best_item.reserve_for(id, _get_world_tick(world) + ITEM_RESERVATION_TICKS)
			current_task = "Buscando material: " + best_item.name
			var dist_to_item: int = _item_distance(best_item)
			if dist_to_item <= 1 and best_item.tile_pos.y == tile_pos.y:
				if not world.entities.has(best_item):
					best_item.release_reservation(id)
					current_job.set_meta("material_item_id", -1)
					return
				world.entities.erase(best_item)
				best_item.carried_by_id = id
				best_item.release_reservation(id)
				current_job.set_meta("material_item_id", -1)
				inventory.append(best_item)
				needs_display_update = true
				current_task = current_job.get_description()
			else:
				_move_toward(world, best_item.tile_pos)
			return

	var dist = abs(tile_pos.x - current_job.tile_pos.x) + abs(tile_pos.z - current_job.tile_pos.z)

	if dist <= 1 and tile_pos.y == current_job.tile_pos.y:
		_set_current_job_state(DFJob.JobState.IN_PROGRESS)
		task_progress += 0.1 + get_skill_level(current_job.get_required_skill()) * 0.05
		
		# Incrementar fatiga por trabajo físico
		if current_job.job_type == DFJob.JobType.CHOP_TREE:
			fatigue_level = minf(1.0, fatigue_level + 0.02)
			fatigue = minf(1.0, fatigue + 0.004)
		elif current_job.job_type == DFJob.JobType.DIG:
			fatigue_level = minf(1.0, fatigue_level + 0.015)
			fatigue = minf(1.0, fatigue + 0.003)
		elif current_job.job_type == DFJob.JobType.COLLECT_WOOD:
			fatigue_level = minf(1.0, fatigue_level + 0.01)
			fatigue = minf(1.0, fatigue + 0.002)

		if task_progress >= 1.0:
			_execute_job(world)
	else:
		_move_toward(world, current_job.tile_pos)

func move_manual(world, dir: Vector3i) -> Array:
	var logs = []
	var target = tile_pos + dir
	if target.x >= 0 and target.x < world.width and target.z >= 0 and target.z < world.depth:
		var ent = world.get_entity_at(target)
		var ent_alive = ent.get("is_alive") if ent != null else null
		if ent != null and ent != self and (ent_alive == null or ent_alive == true) and not (ent.get("creature_type") == "dwarf" and self.get("creature_type") == "dwarf"):
			if world.combat_system != null:
				var wep = DFCombat.get_weapon_base_damage(equipped_weapon)
				var dmg = wep.get("damage", 5.0)
				var skill = wep.get("skill", DFCombat.WeaponSkill.SCRATCH)
				var dtype = wep.get("type", DFCombat.DamageType.BLUNT)
				var res = world.combat_system.resolve_attack(self, ent, dmg, skill, dtype)
				if res.has("message"):
					logs.append(res["message"])
			return logs

		if world.is_wall(target):
			world.dig_tile(target)
		elif not world.is_blocked(target):
			tile_pos = target
			path.clear()
			path_index = 0
			has_moved_this_tick = true
	return logs

## Processes substances in the digestive tract: alcohol, toxins, pathogens.
## body_mass is in kg. Called once per game minute.
func tick_metabolism(world: RefCounted) -> void:
	var bm: float = body_mass_kg * (genome.size_multiplier if genome else 1.0)
	var met_rate: float = genome.metabolic_rate if genome else 1.0
	var alc_tol: float = genome.alcohol_tolerance if genome else 1.0

	# -- Digestion: food and water slowly absorbed over time --
	var food_stored: float = body.ingested_substances.get("food", 0.0)
	if food_stored > 0.0:
		var digest = 0.002 * met_rate
		var absorbed = minf(food_stored, digest)
		hunger = maxf(0.0, hunger - absorbed * 10.0)
		body.ingested_substances["food"] = food_stored - absorbed
		if body.ingested_substances["food"] <= 0.0:
			body.ingested_substances.erase("food")
	var water_stored: float = body.ingested_substances.get("water", 0.0)
	if water_stored > 0.0:
		var absorb_water = minf(water_stored, 0.003 * met_rate)
		thirst = maxf(0.0, thirst - absorb_water * 10.0)
		body.ingested_substances["water"] = water_stored - absorb_water
		if body.ingested_substances["water"] <= 0.0:
			body.ingested_substances.erase("water")

	var alc: float = body.ingested_substances.get("beer", 0.0)
	if alc > 0.0:
		# Blood alcohol concentration (BAC) = alcohol_volume / body_mass_kg
		var bac: float = alc / bm
		body.ebriety = clampf(bac / (0.1 * alc_tol), 0.0, 4.0)
		# Metabolize alcohol over time
		var burned: float = 0.004 * met_rate
		body.ingested_substances["beer"] = maxf(0.0, alc - burned)
		if body.ingested_substances["beer"] <= 0.0:
			body.ingested_substances.erase("beer")
		# Nausea from high ebriety
		if body.ebriety > 1.5:
			body.nausea = minf(1.0, body.nausea + 0.02)
	else:
		body.ebriety = maxf(0.0, body.ebriety - 0.01)

	var poison: float = body.ingested_substances.get("poison", 0.0)
	if poison > 0.0:
		var damage_per_tick: float = poison * 0.5 / bm
		for part in body.parts:
			if part.has_organ and part.is_vital:
				part.organ_damage = minf(1.0, part.organ_damage + damage_per_tick)
				break
		body.nausea = minf(1.0, body.nausea + 0.03)
		body.ingested_substances["poison"] = maxf(0.0, poison - 0.002 * met_rate)
		if body.ingested_substances["poison"] <= 0.0:
			body.ingested_substances.erase("poison")

	var pathogen: float = body.ingested_substances.get("pathogen", 0.0)
	if pathogen > 0.0:
		var path_resist: float = genome.pathogen_resistance if genome else 1.0
		if not has_infection and randf() < (0.01 * pathogen / path_resist):
			has_infection = true
		body.ingested_substances["pathogen"] = maxf(0.0, pathogen - 0.01)
		if body.ingested_substances["pathogen"] <= 0.0:
			body.ingested_substances.erase("pathogen")

	# Nausea -> vomiting
	if body.nausea >= 0.9 and not body.is_vomiting:
		body.is_vomiting = true
		# Eject all ingested substances onto the floor
		var vomit_sub_amount: float = 0.0
		for sub in body.ingested_substances.keys():
			vomit_sub_amount += body.ingested_substances[sub]
			# Transfer substance content into the vomit splatter
			world.add_splatter_substance(tile_pos, sub, body.ingested_substances[sub] * 0.5)
		body.ingested_substances.clear()
		# Deposit vomit puddle
		world.add_splatter_substance(tile_pos, "vomit", 0.08 + vomit_sub_amount * 0.3)
		body.nausea = 0.0
		body.ebriety = maxf(0.0, body.ebriety - 0.5)
		body.is_vomiting = false

	# Disease coughing: spread pathogen particles
	if has_infection and randf() < 0.03:
		var dirs = [Vector3i(1,0,0), Vector3i(-1,0,0), Vector3i(0,0,1), Vector3i(0,0,-1), Vector3i(0,0,0)]
		for d in dirs:
			world.add_splatter_substance(tile_pos + d, "pathogen", 0.005)


## Grooming: lick/clean limbs coated in substances, ingesting them.
## Chance to groom scales with how dirty the limbs are.
func tick_grooming() -> void:
	var standing_parts: Array = []
	for bp in body.parts:
		if bp.can_stand and not bp.coatings.is_empty():
			standing_parts.append(bp)

	# Dwarves groom less often than animals; base chance is low
	var groom_chance: float = 0.05 + 0.2 * float(standing_parts.size())
	if randf() > groom_chance:
		return

	for bp_1566 in standing_parts:
		for sub in bp_1566.coatings.keys():
			var amount: float = bp_1566.coatings[sub]
			if amount > 0.0:
				# Transfer coating from limb into digestive system
				body.ingested_substances[sub] = body.ingested_substances.get(sub, 0.0) + amount
		bp_1566.coatings.clear()

# ---- HYGIENE ----
func tick_hygiene(world) -> void:
	if has_moved_this_tick: return
	if randi() % 20 != 0: return
	var dirty = false
	for bp in body.parts:
		if not bp.coatings.is_empty():
			dirty = true
			break
	if not dirty:
		# Check if standing on a splatter — clean it up
		if current_task == "idle" or current_task.begins_with("Limpiando"):
			var subs = world.get_splatters_at(tile_pos)
			if not subs.is_empty():
				var to_clean = ["vomit", "blood", "mud"]
				for s in to_clean:
					if subs.get(s, 0.0) > 0.0:
						var cleaned = minf(subs[s], 0.02)
						world.add_splatter_substance(tile_pos, s, -cleaned)
						current_task = "Limpiando el suelo"
						needs_display_update = true
						add_thought("Limpió un poco de suciedad del suelo.", 0.02)
						return
	# Wash self if in water
	if world.is_water(tile_pos) or world.is_water(Vector3i(tile_pos.x, tile_pos.y - 1, tile_pos.z)):
		for bp_1599 in body.parts:
			if not bp_1599.coatings.is_empty():
				bp_1599.coatings.clear()
				current_task = "Lavándose"
				needs_display_update = true
				add_thought("Se lavó la suciedad en el agua.", 0.03)
				return

# ---- SOCIAL ----
func tick_social(world) -> void:
	if current_task != "idle": return
	if randi() % 30 != 0: return
	for e in world.entities:
		if e == self: continue
		var is_dwarf = e.get("creature_type") == "dwarf"
		var e_alive = e.get("is_alive")
		if not is_dwarf or e_alive == false: continue
		var dist = abs(e.tile_pos.x - tile_pos.x) + abs(e.tile_pos.z - tile_pos.z)
		if dist <= 1 and e.tile_pos.y == tile_pos.y:
			current_task = "Socializando"
			needs_display_update = true
			needs[Need.SOCIAL] = maxf(0.0, needs[Need.SOCIAL] - 0.2)
			# Share thoughts — both parties exchange a random memory
			var my_mem = _pick_random_memory()
			var their_mem = _pick_other_random_memory(e)
			if my_mem != "":
				add_thought("Compartió con alguien: %s" % my_mem, 0.03)
				e.add_thought("Escuchó de %s: %s" % [name, my_mem], 0.02)
			if their_mem != "":
				add_thought("Escuchó de %s: %s" % [e.name, their_mem], 0.02)
				e.add_thought("Compartió con %s: %s" % [name, their_mem], 0.03)
			# Gossip: spread stress
			var target_stress = e.get("stress")
			if target_stress == null:
				target_stress = 0.5
			var stress_diff = stress - target_stress
			if abs(stress_diff) > 0.2:
				var transfer = stress_diff * 0.1
				stress = clampf(stress - transfer, 0.0, 1.0)
				e.stress = clampf(e.stress + transfer, 0.0, 1.0)
			# Regalos espontáneos: solo objetos no esenciales y con enfriamiento largo.
			if gift_cooldown <= 0 and not inventory.is_empty() and randf() < 0.15:
				for gift in inventory.duplicate():
					if gift is DFItem and gift.item_type not in ["food", "drink", "weapon", "tool", "medicine", "seed"]:
						inventory.erase(gift)
						e.inventory.append(gift)
						gift_cooldown = 720
						current_task = "Regalando %s a %s" % [gift.name, e.name]
						add_thought("Le regaló %s a %s." % [gift.name, e.name], 0.06)
						e.add_thought("Recibió %s como regalo de %s." % [gift.name, name], 0.08)
						break
			return

func _pick_random_memory() -> String:
	if memories.is_empty(): return ""
	return memories[randi() % memories.size()].get("text", "")

func _pick_other_random_memory(other) -> String:
	var other_memories = other.get("memories")
	if other_memories == null or other_memories.is_empty(): return ""
	return other_memories[randi() % other_memories.size()].get("text", "")

# ---- INSPECT ----
func tick_inspect(world) -> void:
	if current_task != "idle": return
	if randi() % 40 != 0: return
	for e in world.entities:
		if e == self: continue
		if e is DFItem:
			var dist = abs(e.tile_pos.x - tile_pos.x) + abs(e.tile_pos.z - tile_pos.z) + abs(e.tile_pos.y - tile_pos.y) * 2
			if dist <= 2:
				var item_quality = e.get("quality")
				if item_quality == null:
					item_quality = 0
				if item_quality >= DFItem.QualityLevel.MASTERWORK:
					current_task = "Admirando %s" % e.get_full_name()
					needs_display_update = true
					add_thought("Quedó maravillado por %s." % e.get_full_name(), 0.08)
					return
				var is_corpse_val = e.get("is_corpse")
				if is_corpse_val == null: is_corpse_val = false
				if is_corpse_val:
					current_task = "Mirando un cadáver"
					needs_display_update = true
					add_thought("Vio un cadáver y se sintió deprimido.", -0.06)
					return
func _satisfy_needs(world) -> bool:
	var need_kind: String = _get_urgent_consumable_kind()
	if need_kind.is_empty():
		_release_survival_target(world)
		return false

	if _consume_inventory_for_need(need_kind):
		_release_survival_target(world)
		return true

	var target: DFItem = _get_world_item_by_id(world, survival_target_item_id)
	if target == null or survival_target_kind != need_kind or not _item_matches_consumable_kind(target, need_kind) or not _item_available_for_self(world, target):
		_release_survival_target(world)
		target = _find_reachable_consumable(world, need_kind, MAX_ITEM_SEARCH_DISTANCE)
		if target != null:
			_reserve_survival_target(world, target, need_kind)

	if target == null:
		return _drink_from_splatters(world) if need_kind == "drink" else false

	# Renovar la reserva mientras el enano sigue caminando hacia el objeto.
	target.reserve_for(id, _get_world_tick(world) + ITEM_RESERVATION_TICKS)
	var distance_to_item: int = _item_distance(target)
	if distance_to_item <= 1 and target.tile_pos.y == tile_pos.y:
		if world.entities.has(target):
			world.entities.erase(target)
		target.carried_by_id = id
		target.is_in_stockpile = false
		target.is_inside_container = false
		target.release_reservation(id)
		inventory.append(target)
		_clear_survival_target_state()
		path.clear()
		path_index = 0
		return _consume_inventory_for_need(need_kind)

	current_task = "Buscando comida" if need_kind == "food" else "Buscando bebida"
	_move_toward(world, target.tile_pos)
	return true

func _get_urgent_consumable_kind() -> String:
	var needs_food: bool = hunger > HUNGER_ACTION_THRESHOLD
	var needs_drink: bool = thirst > THIRST_ACTION_THRESHOLD
	if needs_food and needs_drink:
		var food_pressure: float = hunger / HUNGER_ACTION_THRESHOLD
		var drink_pressure: float = thirst / THIRST_ACTION_THRESHOLD
		return "food" if food_pressure >= drink_pressure else "drink"
	if needs_food:
		return "food"
	if needs_drink:
		return "drink"
	return ""

func _consume_inventory_for_need(kind: String) -> bool:
	for index in range(inventory.size() - 1, -1, -1):
		var candidate: Variant = inventory[index]
		if not candidate is DFItem:
			continue
		var item: DFItem = candidate
		if item.is_decayed or not _item_matches_consumable_kind(item, kind):
			continue

		inventory.remove_at(index)
		item.carried_by_id = -1
		item.release_reservation(id)
		needs_display_update = true

		if kind == "food":
			var food_value: float = maxf(0.05, item.nutrition)
			hunger = maxf(0.0, hunger - food_value)
			needs[Need.FOOD] = maxf(0.0, float(needs.get(Need.FOOD, 0.0)) - food_value)
			body.ingested_substances["food"] = body.ingested_substances.get("food", 0.0) + food_value * 0.15
			current_task = "Comiendo " + item.name
			if item.name == preferred_food:
				add_thought("Disfrutó de su comida favorita: %s." % item.name, 0.06)
			else:
				add_thought("Comió %s para recuperar fuerzas." % item.name, 0.04)
		else:
			var drink_value: float = maxf(0.05, item.hydration if item.hydration > 0.0 else item.nutrition)
			thirst = maxf(0.0, thirst - drink_value)
			needs[Need.DRINK] = maxf(0.0, float(needs.get(Need.DRINK, 0.0)) - drink_value)
			body.ingested_substances["water"] = body.ingested_substances.get("water", 0.0) + drink_value * 0.15
			current_task = "Bebiendo " + item.name
			if "Ale" in item.name or "Cerveza" in item.name or "Vino" in item.name:
				minutes_since_alcohol = 0
				body.ingested_substances["beer"] = body.ingested_substances.get("beer", 0.0) + drink_value * 0.1
				stress *= 0.9
			if item.name == preferred_drink:
				add_thought("Bebió su bebida favorita: %s." % item.name, 0.08)
			else:
				add_thought("Bebió %s para saciar la sed." % item.name, 0.04)
		return true
	return false

func _item_matches_consumable_kind(item: DFItem, kind: String) -> bool:
	if kind == "drink":
		return item.is_drink or item.item_type == "drink"
	return item.is_food or item.item_type in ["food", "meat"] or (item.is_edible and not item.is_drink)

func _item_distance(item: DFItem) -> int:
	return abs(item.tile_pos.x - tile_pos.x) + abs(item.tile_pos.z - tile_pos.z) + abs(item.tile_pos.y - tile_pos.y) * 2

func _get_world_tick(world) -> int:
	var tick_value: Variant = world.get_meta("simulation_tick_total", _ai_tick_counter)
	return int(tick_value)

func _get_world_item_by_id(world, item_id: int) -> DFItem:
	if item_id < 0:
		return null
	for entity in world.entities:
		if entity is DFItem and entity.id == item_id:
			return entity
	return null

func _get_inventory_item_by_id(item_id: int) -> DFItem:
	if item_id < 0:
		return null
	for candidate in inventory:
		if candidate is DFItem and candidate.id == item_id:
			return candidate
	return null

func _has_living_dwarf_id(world, dwarf_id: int) -> bool:
	for entity in world.entities:
		if entity.get("creature_type") == "dwarf" and entity.get("is_alive") == true and int(entity.get("id")) == dwarf_id:
			return true
	return false

func _item_available_for_self(world, item: DFItem) -> bool:
	if item.carried_by_id >= 0 and item.carried_by_id != id:
		return false
	var current_tick: int = _get_world_tick(world)
	if item.reserved_by_id >= 0 and item.reserved_by_id != id:
		if item.reservation_expiry_tick > 0 and current_tick >= item.reservation_expiry_tick:
			item.release_reservation()
		elif not _has_living_dwarf_id(world, item.reserved_by_id):
			item.release_reservation()
		else:
			return false
	return true

func _is_item_temporarily_unreachable(item_id: int) -> bool:
	if not unreachable_item_until.has(item_id):
		return false
	return _ai_tick_counter < int(unreachable_item_until[item_id])

func _mark_item_unreachable(item_id: int) -> void:
	unreachable_item_until[item_id] = _ai_tick_counter + ITEM_UNREACHABLE_TICKS

func _cleanup_unreachable_item_cache() -> void:
	for item_id in unreachable_item_until.keys():
		if _ai_tick_counter >= int(unreachable_item_until[item_id]):
			unreachable_item_until.erase(item_id)

func _find_reachable_consumable(world, kind: String, max_distance: int) -> DFItem:
	var attempted_ids: Dictionary = {}
	for _attempt in range(MAX_PATH_CANDIDATES):
		var nearest: DFItem = null
		var nearest_distance: int = max_distance + 1
		for entity in world.entities:
			if not entity is DFItem:
				continue
			var item: DFItem = entity
			if attempted_ids.has(item.id) or item.is_decayed or _is_item_temporarily_unreachable(item.id):
				continue
			if not _item_matches_consumable_kind(item, kind) or not _item_available_for_self(world, item):
				continue
			var distance: int = _item_distance(item)
			if distance <= max_distance and distance < nearest_distance:
				nearest = item
				nearest_distance = distance
		if nearest == null:
			return null
		attempted_ids[nearest.id] = true
		if nearest_distance <= 1:
			return nearest
		var candidate_path: Array = DFPathfinding.find_path(world, tile_pos, nearest.tile_pos, true)
		if not candidate_path.is_empty():
			return nearest
		_mark_item_unreachable(nearest.id)
	return null

func _reserve_survival_target(world, item: DFItem, kind: String) -> void:
	_release_survival_target(world)
	var expiry_tick: int = _get_world_tick(world) + ITEM_RESERVATION_TICKS
	item.reserve_for(id, expiry_tick)
	survival_target_item_id = item.id
	survival_target_kind = kind
	path.clear()
	path_index = 0

func _clear_survival_target_state() -> void:
	survival_target_item_id = -1
	survival_target_kind = ""

func _release_survival_target(world) -> void:
	var item: DFItem = _get_world_item_by_id(world, survival_target_item_id)
	if item != null:
		item.release_reservation(id)
	_clear_survival_target_state()

func _drink_from_splatters(world) -> bool:
	var here = world.get_splatters_at(tile_pos)
	var drinkable = ["beer", "water", "mud"]
	for s in drinkable:
		var amount = here.get(s, 0.0)
		if amount > 0.01:
			var sip = minf(amount, 0.02)
			body.ingested_substances[s] = body.ingested_substances.get(s, 0.0) + sip
			world.add_splatter_substance(tile_pos, s, -sip)
			thirst = maxf(0.0, thirst - 0.1)
			hunger = maxf(0.0, hunger - 0.03)
			if s == "beer":
				minutes_since_alcohol = 0
				stress *= 0.95
				add_thought("Bebió un poco de cerveza del suelo. No es lo ideal, pero sirve.", 0.02)
			else:
				add_thought("Bebió del suelo para saciar la sed.", -0.01)
			current_task = "Bebiendo del suelo"
			needs_display_update = true
			return true
	return false

func _try_sleep(world, force_sleep: bool = false) -> bool:
	if not force_sleep and fatigue <= 0.82:
		return false

	# Buscar y reclamar cama si no tiene una
	if preferred_bed.x < 0:
		var bed_pos = _find_unclaimed_bed(world)
		if bed_pos.x >= 0:
			_claim_bed(world, bed_pos)

	# Durante el bloque nocturno siempre intenta llegar a su cama.
	if preferred_bed.x >= 0 and (force_sleep or fatigue < 0.96):
		var dist_to_bed = abs(tile_pos.x - preferred_bed.x) + abs(tile_pos.z - preferred_bed.z)
		if dist_to_bed > 0:
			current_task = "Yendo a dormir"
			_move_toward(world, preferred_bed)
			return true

	is_sleeping = true
	current_task = "Durmiendo"
	fatigue = maxf(0.0, fatigue - 0.02)
	needs_display_update = true
	return true

func _idle_wander(world) -> void:
	# 80% de probabilidad: moverse siempre que no haya nada urgente
	if randf() < 0.80:
		var wander_radius = 8
		# Si lleva tiempo stuck, forzar dirección cardinal aleatoria
		if stuck_counter > 2:
			var dirs = [Vector3i(1,0,0), Vector3i(-1,0,0), Vector3i(0,0,1), Vector3i(0,0,-1)]
			dirs.shuffle()
			for escape_dir in dirs:
				var escape = tile_pos + escape_dir * 3
				escape = Vector3i(
					clampi(escape.x, 2, world.width - 3),
					_fix_surface_y(world, escape.x, escape.z),
					clampi(escape.z, 2, world.depth - 3))
				if not world.is_wall(escape) and not world.is_open_space(escape) and not world.is_water(escape):
					_move_toward(world, escape)
					stuck_counter = 0
					return
		# Objetivo random en el radio
		var ox = (randi() % (wander_radius * 2 + 1)) - wander_radius
		var oz = (randi() % (wander_radius * 2 + 1)) - wander_radius
		var target = Vector3i(
			clampi(tile_pos.x + ox, 2, world.width - 3),
			tile_pos.y,
			clampi(tile_pos.z + oz, 2, world.depth - 3))
		target.y = _fix_surface_y(world, target.x, target.z)
		if not world.is_wall(target) and not world.is_open_space(target) and not world.is_water(target):
			_move_toward(world, target)
			return
	# Buscar algo interesante cerca (items, tiles especiales, otros enanos)
	var interesting = _find_nearby_interesting_tile(world, 12)
	if interesting.x >= 0:
		_move_toward(world, interesting)
		return
	# Continuar ruta existente si la hay
	if path.size() > 0 and path_index < path.size():
		_move_toward(world, path.back())

func _find_unclaimed_bed(world):
	if world == null or world.entities == null:
		return null
	var best = null
	var best_dist = 99999
	for e in world.entities:
		if e is DFItem and e.get("is_bed") == true and not _is_bed_claimed(world, e.tile_pos):
			var d = abs(e.tile_pos.x - tile_pos.x) + abs(e.tile_pos.z - tile_pos.z)
			if d < best_dist:
				best_dist = d
				best = e.tile_pos
	return best

func _is_bed_claimed(world, bed_pos: Vector3i) -> bool:
	if world == null:
		return false
	for e in world.entities:
		if e.get("creature_type") == "dwarf" and e.get("is_alive") == true and e.preferred_bed == bed_pos:
			return true
	return false

func _claim_bed(world, bed_pos: Vector3i) -> void:
	preferred_bed = bed_pos
	claimed_bed = bed_pos
	add_thought("Reclamo una cama para dormir.", 0.03)

func _find_nearby_shelter(world) -> Vector3i:
	if world == null:
		return Vector3i(-1, -1, -1)
	var search_radius = 15
	var best = null
	var best_dist = 99999
	for dz in range(-search_radius, search_radius + 1):
		for dx in range(-search_radius, search_radius + 1):
			var pos = Vector3i(tile_pos.x + dx, tile_pos.y, tile_pos.z + dz)
			if pos.x < 0 or pos.x >= world.width or pos.z < 0 or pos.z >= world.depth:
				continue
			if world.is_wall(pos) or world.is_water(pos):
				continue
			if _is_indoor_tile(world, pos):
				var d = abs(dx) + abs(dz)
				if d < best_dist:
					best_dist = d
					best = pos
	if best != null:
		return best
	for check_y in range(tile_pos.y - 1, max(0, tile_pos.y - 5), -1):
		for dz_1915 in range(-search_radius, search_radius + 1):
			for dx_1916 in range(-search_radius, search_radius + 1):
				var pos_1917 = Vector3i(tile_pos.x + dx_1916, check_y, tile_pos.z + dz_1915)
				if pos_1917.x < 0 or pos_1917.x >= world.width or pos_1917.z < 0 or pos_1917.z >= world.depth:
					continue
				if world.is_wall(pos_1917) or world.is_water(pos_1917):
					continue
				if _is_indoor_tile(world, pos_1917):
					var d_1923 = abs(dx_1916) + abs(dz_1915) + abs(check_y - tile_pos.y) * 2
					if d_1923 < best_dist:
						best_dist = d_1923
						best = pos_1917
	return best if best != null else Vector3i(-1, -1, -1)

func _is_indoor_tile(world, pos: Vector3i) -> bool:
	if world == null:
		return false
	var above = Vector3i(pos.x, pos.y + 1, pos.z)
	if above.y < world.depth and world.is_wall(above):
		return true
	if world.buildings != null:
		for b in world.buildings:
			if b.is_constructed and b.has_method("is_inside") and b.is_inside(above):
				return true
	return false

func _fix_surface_y(world, x: int, z: int) -> int:
	# Obtiene la altura de la superficie en (x, z) con fallback
	if world != null and world.has_method("get_surface_height"):
		return world.get_surface_height(x, z)
	return tile_pos.y

func _find_nearby_interesting_tile(world, radius: int) -> Vector3i:
	# Busca tiles interesantes alrededor del enano:
	# items en el suelo, cultivos maduros, talleres, arboles
	if world == null:
		return Vector3i(-1, -1, -1)
	var candidates = []
	var sy = tile_pos.y
	
	# Buscar items en el suelo
	for e in world.entities:
		if e is DFItem:
			var dx = abs(e.tile_pos.x - tile_pos.x)
			var dz = abs(e.tile_pos.z - tile_pos.z)
			if dx <= radius and dz <= radius and dx + dz > 0:
				candidates.append({"pos": e.tile_pos, "priority": 2})
	
	# Buscar cultivos maduros
	for dz_1964 in range(-radius, radius + 1):
		for dx_1965 in range(-radius, radius + 1):
			var pos = Vector3i(tile_pos.x + dx_1965, sy, tile_pos.z + dz_1964)
			if pos.x < 0 or pos.x >= world.width or pos.z < 0 or pos.z >= world.depth:
				continue
			var tile_data = world.get_tile_data(pos)
			if tile_data.get("crop_type", "") != "" and tile_data.get("growth", 0) >= 0.7:
				candidates.append({"pos": pos, "priority": 1})
	
	# Buscar talleres
	for w in world.workshops:
		var dx_1975 = abs(w.tile_pos.x - tile_pos.x)
		var dz_1976 = abs(w.tile_pos.z - tile_pos.z)
		if dx_1975 <= radius and dz_1976 <= radius and dx_1975 + dz_1976 > 0:
			candidates.append({"pos": w.tile_pos, "priority": 0})
	
	# Seguir a otro enano ya no es el destino idle por defecto. Solo ocurre cuando
	# la necesidad social es realmente alta y de forma poco frecuente.
	if float(needs.get(Need.SOCIAL, 0.0)) > 0.75 and randf() < 0.12:
		for social_dwarf in world.entities:
			var is_social_dwarf: bool = social_dwarf.get("creature_type") == "dwarf" and social_dwarf != self
			if is_social_dwarf and social_dwarf.get("is_alive") == true:
				var social_dx: int = abs(social_dwarf.tile_pos.x - tile_pos.x)
				var social_dz: int = abs(social_dwarf.tile_pos.z - tile_pos.z)
				if social_dx <= radius and social_dz <= radius and social_dx + social_dz > 0:
					candidates.append({"pos": social_dwarf.tile_pos, "priority": -2})
	
	# Elegir el mejor candidato: mayor prioridad, menor distancia
	var best: Vector3i = Vector3i(-1, -1, -1)
	var best_score = -9999
	for c in candidates:
		var dist = abs(c.pos.x - tile_pos.x) + abs(c.pos.z - tile_pos.z)
		var score = c.priority * 10 - dist
		if score > best_score:
			best_score = score
			best = c.pos
	
	return best if best.x >= 0 else Vector3i(-1, -1, -1)

func _execute_job(world) -> void:
	if current_job == null:
		return

	# Un objetivo puede desaparecer mientras el enano viaja (por otro sistema,
	# derrumbe, crecimiento o carga). No dejar el trabajo eternamente IN_PROGRESS.
	if current_job.job_type == DFJob.JobType.CHOP_TREE:
		if world.get_tile(current_job.tile_pos) != DFWorld.TileType.TREE:
			_finish_obsolete_job(world, "El árbol objetivo ya no existe")
			return
	elif current_job.job_type == DFJob.JobType.DIG:
		var dig_target_tile: int = world.get_tile(current_job.tile_pos)
		if dig_target_tile not in [DFWorld.TileType.WALL, DFWorld.TileType.CAVE_WALL]:
			_finish_obsolete_job(world, "La roca objetivo ya fue retirada")
			return

	var success = false
	var job_skill = current_job.get_required_skill()

	match current_job.job_type:
		DFJob.JobType.COLLECT_WOOD:
			success = _execute_collect_job(world, "wood")
		DFJob.JobType.COLLECT_STONE:
			success = _execute_collect_job(world, "stone")
		DFJob.JobType.DIG:
			success = world.dig_tile(current_job.tile_pos)
		DFJob.JobType.CHOP_TREE:
			success = world.chop_tree(current_job.tile_pos, tile_pos)
		DFJob.JobType.BUILD_WALL:
			var required_wall_material: String = str(current_job.get_meta("required_material_type", ""))
			var wall_material_id: int = 11
			for inventory_index: int in range(inventory.size()):
				var inventory_value: Variant = inventory[inventory_index]
				if not (inventory_value is DFItem):
					continue
				var construction_item: DFItem = inventory_value
				var accepted: bool = construction_item.item_type in ["stone", "wood", "plank"]
				if not required_wall_material.is_empty():
					accepted = construction_item.item_type == required_wall_material
				if accepted:
					wall_material_id = construction_item.material
					inventory.remove_at(inventory_index)
					break
			success = world.build_wall(current_job.tile_pos, wall_material_id)
		DFJob.JobType.BUILD_FLOOR:
			var required_floor_material: String = str(current_job.get_meta("required_material_type", ""))
			var floor_material_id: int = 11
			for floor_inventory_index: int in range(inventory.size()):
				var floor_inventory_value: Variant = inventory[floor_inventory_index]
				if not (floor_inventory_value is DFItem):
					continue
				var floor_construction_item: DFItem = floor_inventory_value
				var floor_material_accepted: bool = floor_construction_item.item_type in ["stone", "wood", "plank"]
				if not required_floor_material.is_empty():
					floor_material_accepted = floor_construction_item.item_type == required_floor_material
				if floor_material_accepted:
					floor_material_id = floor_construction_item.material
					inventory.remove_at(floor_inventory_index)
					break
			success = world.build_floor(current_job.tile_pos, floor_material_id)
		DFJob.JobType.BUILD_WORKSHOP:
			success = _execute_build_workshop_job(world)
		DFJob.JobType.WORKSHOP_REACTION:
			var reaction_id = current_job.reaction_id
			if reaction_id == "": reaction_id = "smelt_iron"
			var recipe = DFReactions.get_reaction(reaction_id)
			if recipe.size() > 0:
				for out_key in recipe.outputs.keys():
					var amount = recipe.outputs[out_key]
					var out_name = out_key.replace("_", " ").capitalize()
					for i_2054 in range(amount):
						world._spawn_item(current_job.tile_pos, out_name, out_key, 0, "-", Color.SILVER)
				success = true
		DFJob.JobType.BUILD_STAIRS_UP:
			success = world.build_stairs_up(current_job.tile_pos)
		DFJob.JobType.BUILD_STAIRS_DOWN:
			success = world.build_stairs_down(current_job.tile_pos)
		DFJob.JobType.SMOOTH:
			success = world.smooth_tile(current_job.tile_pos)
		DFJob.JobType.FARM_PLANT:
			var plant_type = "plump_helmet"
			if current_job.result_tile_type >= 0:
				var plant_names = world.PLANT_TYPES.keys()
				if current_job.result_tile_type < plant_names.size():
					plant_type = plant_names[current_job.result_tile_type]
			success = world.plant_crop(current_job.tile_pos, plant_type)
		DFJob.JobType.COOK_FOOD:
			success = _execute_cook_job(world)
		DFJob.JobType.TRAIN:
			var training_skill: int = _primary_work_skill()
			current_task = "Entrenando " + _work_skill_label(training_skill)
			add_skill_xp(training_skill, 8)
			needs[Need.WORK] = maxf(0.0, float(needs.get(Need.WORK, 0.0)) - 0.08)
			success = true
		DFJob.JobType.BREW_DRINK:
			success = _execute_brew_job(world)
		DFJob.JobType.PROCESS_PLANT:
			success = _execute_process_plant_job(world)
		DFJob.JobType.SMELT_ORE:
			success = _execute_smelt_job(world)
		DFJob.JobType.MAKE_CHARCOAL:
			success = _execute_make_charcoal_job(world)
		DFJob.JobType.TAN_HIDE:
			success = _execute_tan_hide_job(world)
		DFJob.JobType.SPIN_THREAD:
			success = _execute_spin_thread_job(world)
		DFJob.JobType.FISH:
			success = _execute_fish_job(world)
		DFJob.JobType.HUNT:
			success = _execute_hunt_job(world)
		DFJob.JobType.STORE_IN_CONTAINER:
			success = _execute_store_in_container_job(world)
		DFJob.JobType.HAUL_ITEM:
			success = _execute_haul_item_job(world)
		DFJob.JobType.FARM_HARVEST:
			if world.is_grown_crop(current_job.tile_pos):
				var crop = world.growing_crops.get(current_job.tile_pos)
				if crop != null:
					var pdata = world.PLANT_TYPES.get(crop["type"])
					if pdata != null:
						var item_name = pdata.name
						for i_2097 in range(pdata.food_yield):
							world._spawn_item(current_job.tile_pos, item_name, "food", 0, "%", Color("#FF8844"))
						if pdata.drink_yield > 0:
							world._spawn_item(current_job.tile_pos, "Dwarven Ale", "drink", 0, "~", Color("#FFCC00"))
					world.growing_crops.erase(current_job.tile_pos)
					success = true
		DFJob.JobType.TEND_WOUNDS:
			var patient_id = current_job.get_meta("patient_id") if current_job.has_meta("patient_id") else -1
			var patient = null
			for ent in world.entities:
				if ent.get_instance_id() == patient_id:
					patient = ent
					break
			if patient != null and patient.get("is_alive") == true:
				# 1. Bandaging / stitching bleeding wounds
				var has_thread = false
				for i_2113 in range(inventory.size()):
					var item_n = inventory[i_2113].name.to_lower()
					if "cuerda" in item_n or "lino" in item_n or "tela" in item_n:
						inventory.remove_at(i_2113)
						has_thread = true
						break
				
				var wounds_treated = 0
				for wound in patient.wounds:
					if not wound.get("healed", false):
						wound["healed"] = true
						wounds_treated += 1
				
				if patient.is_bleeding:
					patient.bleeding_rate = 0.0
					patient.is_bleeding = false
					wounds_treated += 1
				
				# 2. Disinfecting infections using alcohol/beer
				if patient.has_infection:
					# Check if doctor has beer/alcohol in inventory
					var has_alcohol = false
					for i_2135 in range(inventory.size()):
						if inventory[i_2135].item_type == "drink":
							inventory.remove_at(i_2135)
							has_alcohol = true
							break
					patient.has_infection = false
					patient.infection_chance = 0.0
					# Disinfection hurts! Pain spike + nausea (might vomit)
					patient.inflict_pain(15.0)
					patient.body.nausea = minf(1.0, patient.body.nausea + 0.4)
					if patient.body.nausea >= 0.8:
						# Spawn a vomit splatter on the bed!
						world.add_splatter_substance(patient.tile_pos, "vomit", 0.08)
						patient.add_thought("Sintió náuseas insoportables por el alcohol vertido en sus heridas.", -0.06)
					patient.add_thought("Aulló de dolor cuando el doctor desinfectó sus heridas.", -0.05)
					wounds_treated += 1
				
				# Restore health partially
				patient.health = minf(1.0, patient.health + 0.15 + get_skill_level(DFDwarf.Skill.DOCTORING) * 0.05)
				patient.needs_display_update = true
				
				# Clear medical rest if fully healed
				var still_needs_attention = patient.health < 0.9 or patient.has_infection
				for wound_2158 in patient.wounds:
					if not wound_2158.get("healed", false):
						still_needs_attention = true
						break
				if not still_needs_attention:
					patient.is_resting_medical = false
					patient.current_task = "idle"
					patient.add_thought("Se siente recuperado gracias al tratamiento médico.", 0.08)
				
				success = true
				add_skill_xp(DFDwarf.Skill.DOCTORING, 15)
				add_thought("Trató las heridas de un compañero con éxito.", 0.05)
			else:
				success = false
		_:
			if current_job != null:
				_set_current_job_state(DFJob.JobState.CANCELLED)
				current_job.cancel_reason = "Este tipo de trabajo todavía no tiene una ejecución implementada."
			success = false

	if success:
		add_skill_xp(job_skill, 5)
		needs[Need.WORK] = maxf(0.0, needs.get(Need.WORK, 0.0) - 0.28)
		productive_idle_ticks = 0
		if current_job != null:
			_release_job_item_reservations(world)
			_set_current_job_state(DFJob.JobState.COMPLETED)
			current_job.assigned_dwarf_id = -1
		current_job = null
		_reset_job_runtime_state()
		needs_display_update = true
		add_thought("Completó satisfactoriamente un trabajo.", 0.03)
		current_task = "idle"
	elif current_job != null:
		if current_job.state != DFJob.JobState.IN_PROGRESS:
			_abandon_current_job(world, false, current_job.cancel_reason)

func _finish_obsolete_job(world, reason: String) -> void:
	if current_job != null:
		_release_job_item_reservations(world)
		_set_current_job_state(DFJob.JobState.COMPLETED)
		current_job.assigned_dwarf_id = -1
	current_job = null
	_reset_job_runtime_state()
	current_task = "idle"
	needs_display_update = true
	if not reason.is_empty():
		add_thought(reason + ". Buscó otra tarea.", 0.0)


func _profession_matches_job(job_type: int) -> bool:
	match job_type:
		DFJob.JobType.DIG:
			return profession == Profession.MINER
		DFJob.JobType.CHOP_TREE:
			return profession in [Profession.WOODCUTTER, Profession.CARPENTER]
		DFJob.JobType.FARM_PLANT, DFJob.JobType.FARM_HARVEST, DFJob.JobType.PROCESS_PLANT:
			return profession == Profession.FARMER
		DFJob.JobType.HUNT:
			return profession in [Profession.HUNTER, Profession.MILITARY]
		DFJob.JobType.FISH:
			return profession in [Profession.FISHER, Profession.COOK, Profession.FARMER, Profession.HUNTER]
		DFJob.JobType.COOK_FOOD:
			return profession == Profession.COOK
		DFJob.JobType.BREW_DRINK:
			return profession in [Profession.BREWER, Profession.COOK]
		DFJob.JobType.SMELT_ORE, DFJob.JobType.MAKE_CHARCOAL:
			return profession in [Profession.SMITH, Profession.WOODCUTTER]
		DFJob.JobType.TEND_WOUNDS, DFJob.JobType.DIAGNOSE, DFJob.JobType.SURGERY:
			return profession in [Profession.DOCTOR, Profession.CHIEF_MEDICAL_DWARF]
		_:
			return false

func _can_attempt_job(job_type: int) -> bool:
	# Oficios peligrosos conservan requisitos. Las labores civiles permiten aprender trabajando.
	if job_type == DFJob.JobType.HUNT:
		return _has_tool_for_job(job_type) and (profession in [Profession.HUNTER, Profession.MILITARY] or get_skill_level(Skill.MILITARY_TACTICS) > 0)
	if job_type == DFJob.JobType.SURGERY:
		return profession in [Profession.DOCTOR, Profession.CHIEF_MEDICAL_DWARF] or get_skill_level(Skill.SURGERY) > 1
	if job_type in [DFJob.JobType.DIG, DFJob.JobType.CHOP_TREE]:
		return _has_tool_for_job(job_type)
	return true

func _pick_up_job(world, jobs: Array) -> void:
	var best_job: DFJob = null
	var best_score := -999999

	for j in jobs:
		if j == null or j.state != DFJob.JobState.UNASSIGNED:
			continue
		if not _can_attempt_job(j.job_type):
			# Buscar la herramienta antes de descartar minería o tala.
			if j.job_type in [DFJob.JobType.DIG, DFJob.JobType.CHOP_TREE, DFJob.JobType.HUNT]:
				var target_tool: DFItem = _find_nearest_tool_on_ground(world, j.job_type)
				if target_tool != null:
					var dist_to_tool: int = abs(tile_pos.x - target_tool.tile_pos.x) + abs(tile_pos.z - target_tool.tile_pos.z)
					if dist_to_tool <= 1:
						target_tool.release_reservation(id)
						target_tool.carried_by_id = id
						inventory.append(target_tool)
						world.entities.erase(target_tool)
						current_task = "Recogiendo herramienta: " + target_tool.name
					else:
						target_tool.reserve_for(id, _get_world_tick(world) + ITEM_RESERVATION_TICKS)
						current_task = "Buscando herramienta: " + target_tool.name
						_move_toward(world, target_tool.tile_pos)
					return
			continue

		var dist: int = abs(tile_pos.x - j.tile_pos.x) + abs(tile_pos.z - j.tile_pos.z) + abs(tile_pos.y - j.tile_pos.y) * 2
		var skill_level := get_skill_level(j.get_required_skill())
		var urgency_bonus := int(j.priority) * 24
		var profession_bonus := 45 if _profession_matches_job(j.job_type) else 0
		var work_need_bonus := int(needs.get(Need.WORK, 0.0) * 35.0)
		var score := urgency_bonus + profession_bonus + skill_level * 7 + work_need_bonus - dist
		if score > best_score:
			best_score = score
			best_job = j

	if best_job != null:
		assign_job(best_job)

func _move_toward(world, target: Vector3i) -> void:
	var effective_speed = speed * (1.0 - fatigue_level * 0.2)
	effective_speed = maxf(0.3, effective_speed)
	# Only move every N ticks: faster dwarves = more frequent moves
	if move_tick_counter > 0:
		move_tick_counter -= 1
		return
	move_tick_counter = ceil(2.0 / effective_speed)

	if tile_pos == last_pos:
		stuck_counter += 1
	else:
		stuck_counter = 0
	last_pos = tile_pos
	if stuck_counter > 5:
		if current_job != null:
			if current_job.job_type == DFJob.JobType.BUILD_WORKSHOP:
				current_task = "Recalculando ruta para continuar el taller"
				path.clear()
				path_index = 0
				stuck_counter = 0
				return
			_abandon_current_job(world, false, "Canceló un trabajo porque no encontró una ruta válida.")
			return
		current_task = "idle"
		path.clear()
		path_index = 0
		stuck_counter = 0
		return

	if path_index >= path.size() or path.is_empty():
		path = DFPathfinding.find_path(world, tile_pos, target, true)
		path_index = 0
		if path.is_empty():
			# No cancelar el trabajo al primer fallo de pathfinding.
			# stuck_counter (>5) se encargara si el enano lleva mucho tiempo atascado.
			return

	# Path smoothing: skip unnecessary intermediate steps
	while path_index < path.size() - 1:
		var next_next = path[path_index + 1]
		var dx = next_next.x - tile_pos.x
		var dz = next_next.z - tile_pos.z
		if abs(dx) <= 1 and abs(dz) <= 1:
			if not world.is_blocked(next_next) or next_next == target:
				path_index += 1
			else:
				break
		else:
			break

	var next_step = path[path_index]
	if world.is_blocked(next_step) and next_step != target:
		path = DFPathfinding.find_path(world, tile_pos, target, true)
		path_index = 0
		if path.is_empty():
			return

	if next_step != tile_pos:
		# Entity collision avoidance: check if another entity is on the target tile
		var blocked_by_entity = false
		for e in world.entities:
			if e == self: continue
			if e is DFItem: continue
			var is_alive_check = e.get("is_alive")
			if is_alive_check == null: is_alive_check = true
			if is_alive_check == false: continue
			if e.tile_pos == next_step:
				blocked_by_entity = true
				break
		if blocked_by_entity:
			# Try to find adjacent free tile instead
			var dirs = [Vector3i(-1, 0, 0), Vector3i(1, 0, 0), Vector3i(0, 0, -1), Vector3i(0, 0, 1),
				Vector3i(-1, 0, -1), Vector3i(1, 0, 1), Vector3i(-1, 0, 1), Vector3i(1, 0, -1)]
			var found_alt = false
			dirs.shuffle()
			for d in dirs:
				var alt = tile_pos + d
				if alt.x < 0 or alt.x >= world.width or alt.z < 0 or alt.z >= world.depth:
					continue
				if world.is_blocked(alt): continue
				var alt_blocked = false
				for e_2341 in world.entities:
					if e_2341 == self: continue
					if e_2341 is DFItem: continue
					var is_alive_check2 = e_2341.get("is_alive")
					if is_alive_check2 == null: is_alive_check2 = true
					if is_alive_check2 == false: continue
					if e_2341.tile_pos == alt:
						alt_blocked = true
						break
				if not alt_blocked:
					tile_pos = alt
					found_alt = true
					break
			if not found_alt:
				return
		else:
			tile_pos = next_step
			# Fatigue from movement
			fatigue_level = minf(1.0, fatigue_level + 0.002)
		path_index += 1
		has_moved_this_tick = true
		stats_tracker["distance_traveled"] += 1

func get_display_char() -> String:
	if current_job != null and task_progress > 0:
		return "W"
	if is_sleeping:
		return "z"
	if mood == MoodState.BESERK or mood == MoodState.TANTRUM:
		return "Y"
	if not glyph.is_empty():
		return glyph
	return "d" if gender == "Male" else "w"

func get_display_color() -> Color:
	if not is_alive:
		return Color("#444444")
	if mood == MoodState.BESERK:
		return Color("#FF0000")
	if mood == MoodState.TANTRUM:
		return Color("#FF4400")
	if mood == MoodState.MELANCHOLY:
		return Color("#8844FF")
	if mood == MoodState.STRANGE_MOOD:
		return Color("#FFFF00")
	if mood == MoodState.FELL_MOOD:
		return Color("#440000")
	if mood == MoodState.MACABRE_MOOD:
		return Color("#880044")
	if mood == MoodState.SECRETIVE_MOOD:
		return Color("#444488")
	if health < 0.3:
		return Color("#FF4444")
	if hunger > 0.8 or thirst > 0.8:
		return Color("#FFAA00")
	# Un color con alfa mayor que cero fue asignado por CreatureDefinition.
	if display_color.a > 0.0:
		return display_color
	return Color("#88CCFF") if gender == "Male" else Color("#FF88CC")

func get_needs_string() -> String:
	var hunger_pct = int(hunger * 100)
	var thirst_pct = int(thirst * 100)
	var health_pct = int(health * 100)
	var fatigue_pct = int(fatigue * 100)
	var result = "H:%d%% S:%d%% " % [hunger_pct, thirst_pct]
	if is_pregnant:
		result += "EMBARAZADA! "
	if health_pct < 30:
		result += "MORIBUNDO!"
	elif health_pct < 60:
		result += "Herido grave"
	elif hunger_pct > 80 or thirst_pct > 80:
		result += "INANICION!"
	elif fatigue_pct > 80:
		result += "Agotado"
	else:
		result += "Salud:%d%%" % health_pct
	return result

## ===== REPRODUCCION =====
func tick_reproduction(world) -> void:
	if not is_alive:
		return
	if is_child:
		tick_child_growth(world)
		return
	if age < 12:
		return
	if family.spouse >= 0:
		marriage_counter += 1
	if is_pregnant:
		pregnancy_progress += 0.01
		if pregnancy_progress >= 1.0:
			_give_birth(world)
		return
	if family.spouse < 0:
		_try_find_partner(world)
		return
	if family.spouse >= 0 and not is_pregnant:
		_try_conceive(world)
		return

func _check_personality_compatibility(other) -> bool:
	var pvals = PersonalityTrait.values()
	var pidx = 0
	while pidx < pvals.size():
		var t = pvals[pidx]
		var d = abs(personality.get(t, 0.5) - other.personality.get(t, 0.5))
		if d > 0.8:
			return false
		pidx += 1
	return true

func _try_find_partner(world) -> void:
	var best_candidate = null
	var best_relation = 0.6
	for e in world.entities:
		if e == self: continue
		var is_dwarf = e.get("creature_type") == "dwarf"
		if not is_dwarf: continue
		var is_alive_check = e.get("is_alive")
		if is_alive_check == null or is_alive_check == false: continue
		if e.gender == gender: continue
		if e.age < 12: continue
		if e.family.spouse >= 0: continue
		if e.mood == MoodState.TANTRUM or e.mood == MoodState.BESERK: continue
		if e.hunger > 0.9 or e.thirst > 0.9: continue
		if e.is_child: continue
		var rel = get_relationship_value(e.id)
		var rel_mutual = e.get_relationship_value(id)
		var avg_rel = (rel + rel_mutual) * 0.5
		var compatibility = avg_rel
		if e.preferred_food == preferred_food:
			compatibility += 0.05
		if e.preferred_drink == preferred_drink:
			compatibility += 0.05
		if e.profession == profession:
			compatibility += 0.05
		compatibility += (happiness + e.happiness) * 0.05
		if compatibility > best_relation:
			var personality_match = true
			personality_match = _check_personality_compatibility(e)
			if not personality_match:
				compatibility *= 0.5
			if compatibility > best_relation:
				best_relation = compatibility
				best_candidate = e
	if best_candidate != null and best_relation > 0.6 and randi() % 100 < int(best_relation * 30):
		_marry(best_candidate)
		add_thought("Se caso con %s! Es el comienzo de una nueva familia." % best_candidate.name, 0.15)
		best_candidate.add_thought("Se caso con %s! La vida en la fortaleza tiene nuevo sentido." % name, 0.15)

func _marry(partner) -> void:
	family.spouse = partner.id
	partner.family.spouse = id
	marriage_counter = 0
	partner.marriage_counter = 0
	needs[Need.FAMILY] = 0.0
	partner.needs[Need.FAMILY] = 0.0
	if preferred_bed.x < 0 and partner.preferred_bed.x >= 0:
		preferred_bed = partner.preferred_bed
	elif partner.preferred_bed.x < 0 and preferred_bed.x >= 0:
		partner.preferred_bed = preferred_bed

func _try_conceive(world) -> void:
	if gender != "Female":
		return
	var husband = null
	for e in world.entities:
		if e.id == family.spouse:
			husband = e
			break
	if husband == null or husband.is_alive == false:
		return
	var dist = abs(tile_pos.x - husband.tile_pos.x) + abs(tile_pos.z - husband.tile_pos.z)
	if dist > 3:
		return
	if health < 0.5 or husband.health < 0.5:
		return
	if hunger > 0.7 or thirst > 0.7:
		return
	var chance = 0.001
	if preferred_bed.x >= 0:
		var bed_dist = abs(tile_pos.x - preferred_bed.x) + abs(tile_pos.z - preferred_bed.z)
		if bed_dist <= 2:
			chance += 0.002
	chance += room_quality * 0.001
	chance += happiness * 0.001
	var rel = get_relationship_value(husband.id)
	chance += maxf(0, rel) * 0.001
	if randf() < chance:
		is_pregnant = true
		pregnancy_progress = 0.0
		partner_id = husband.id
		add_thought("Esta embarazada de %s! La familia crecera." % husband.name, 0.2)
		husband.add_thought("%s esta embarazada! Sera padre." % name, 0.2)

func _give_birth(world) -> void:
	if world == null:
		return
	var baby_name = ""
	var child = DFDwarf.new(tile_pos, baby_name)
	child.is_child = true
	child.is_alive = true
	child.age = 0
	child.birth_year = _game_year_from_world(world)
	child.mother_id = id
	child.father_id = partner_id
	child.family.mother = id
	child.family.father = partner_id
	var father = null
	for e in world.entities:
		if e.id == partner_id:
			father = e
			break
	for s in Skill.values():
		var parent_avg = skills.get(s, 0)
		if father != null:
			parent_avg = (parent_avg + father.skills.get(s, 0)) / 2.0
		child.skills[s] = max(0, int(parent_avg) + randi() % 3 - 1)
	child._init_personality()
	for t in PersonalityTrait.values():
		var parent_val = personality.get(t, 0.5)
		if father != null:
			parent_val = (parent_val + father.personality.get(t, 0.5)) * 0.5
		child.personality[t] = clampf(parent_val + randf_range(-0.1, 0.1), 0.0, 1.0)
	if genome != null:
		var father_genome = null
		if father != null and father.genome != null:
			father_genome = father.genome
		if father_genome != null:
			var avg_size = (genome.size_multiplier + father_genome.size_multiplier) * 0.5
			var avg_met = (genome.metabolic_rate + father_genome.metabolic_rate) * 0.5
			var avg_alc = (genome.alcohol_tolerance + father_genome.alcohol_tolerance) * 0.5
			var avg_path = (genome.pathogen_resistance + father_genome.pathogen_resistance) * 0.5
			child.genome = DFGenetics.Genome.new(avg_size, avg_met, avg_alc, avg_path).mutate(0.1, 0.2)
			child.body_mass_kg = 20.0
	world.entities.append(child)
	family.children.append(child.id)
	if father != null:
		father.family.children.append(child.id)
	is_pregnant = false
	pregnancy_progress = 0.0
	add_thought("Dio a luz a %s! La fortaleza tiene un nuevo miembro." % child.name, 0.2)
	if father != null:
		father.add_thought("Su hijo %s ha nacido! Un nuevo enano para la fortaleza." % child.name, 0.2)
	needs[Need.FAMILY] = 0.0

func _game_year_from_world(world) -> int:
	if world.has_method("get_game_year"):
		return world.get_game_year()
	return 63

func tick_child_growth(world) -> void:
	if not is_child:
		return
	age += 1
	var mother = _get_parent_from_world(world, mother_id)
	var father = _get_parent_from_world(world, father_id)
	for s in Skill.values():
		if randi() % 100 < 2:
			var parent_skill = 0
			if mother != null:
				parent_skill = max(parent_skill, mother.skills.get(s, 0))
			if father != null:
				parent_skill = max(parent_skill, father.skills.get(s, 0))
			if parent_skill > skills.get(s, 0):
				skills[s] = skills.get(s, 0) + 1
	if age >= 12:
		is_child = false
		body_mass_kg = 70.0 * (genome.size_multiplier if genome != null else 1.0)
		add_thought("Ha crecido! Ahora es un adulto enano listo para trabajar.", 0.15)
		current_task = "Creciendo"
		if mother != null:
			mother.add_thought("Su hijo %s ha crecido y es adulto." % name, 0.1)
		if father != null:
			father.add_thought("Su hijo %s ha alcanzado la mayoria de edad." % name, 0.1)

func _get_parent_from_world(world, parent_id: int):
	if world == null:
		return null
	for e in world.entities:
		var is_dwarf = e.get("creature_type") == "dwarf"
		if is_dwarf and e.id == parent_id and e.get("is_alive") == true:
			return e
	return null

func get_family_string() -> String:
	var text = "Familia de %s:\n" % name
	if family.spouse >= 0:
		text += "Conyuge: ID %d\n" % family.spouse
	if family.mother >= 0:
		text += "Madre: ID %d\n" % family.mother
	if family.father >= 0:
		text += "Padre: ID %d\n" % family.father
	if family.children.size() > 0:
		text += "Hijos: %d\n" % family.children.size()
	if is_child:
		text += "Edad: %d (Nino/a)\n" % age
	if is_pregnant:
		text += "EMBARAZADA (%.0f%%)\n" % (pregnancy_progress * 100)
	return text

func get_happiness_string() -> String:
	if happiness > 0.8: return "Extático/a"
	elif happiness > 0.6: return "Feliz"
	elif happiness > 0.4: return "Contento/a"
	elif happiness > 0.2: return "Infeliz"
	else: return "Miserable"

func get_profession_title() -> String:
	return PROFESSION_NAMES.get(profession, "Aldeano")

func get_task_string() -> String:
	# El HUD consulta esta función varias veces por frame. El texto anterior era
	# aleatorio y simulaba cambios de estado que nunca habían ocurrido.
	if not is_alive:
		return "Muerto"
	if current_job != null:
		return current_job.get_description()
	if is_sleeping:
		return "Durmiendo"
	if is_resting_medical:
		return "Descanso médico"
	match mood:
		MoodState.TANTRUM:
			return "Pataleta"
		MoodState.BESERK:
			return "Berserker"
		MoodState.MELANCHOLY:
			return "Melancólico"
		MoodState.STRANGE_MOOD:
			return "Inspirado"
		MoodState.FELL_MOOD:
			return "Estado siniestro"
		MoodState.MACABRE_MOOD:
			return "Estado macabro"
		MoodState.SECRETIVE_MOOD:
			return "Estado secreto"
	if current_task == "idle" or current_task.is_empty():
		return "Ocioso"
	return current_task.capitalize()

func get_name_and_skill() -> String:
	var prof_name = PROFESSION_NAMES.get(profession, "Aldeano")
	var level = skills.get(_get_best_skill(), 0)
	return "%s (%s %d)" % [name, prof_name, level]

func get_health_bar() -> String:
	var bars = int(health * 10)
	var result = ""
	for i in range(10):
		if i < bars: result += "\u2588"
		else: result += "\u2591"
	return result

func _get_best_skill() -> int:
	var best = Skill.MINING
	var best_val = -1
	for s in skills:
		if skills[s] > best_val:
			best_val = skills[s]
			best = s
	return best

func get_body() -> Object:
	return body

func _workshop_skill_for_type(workshop_type: int) -> int:
	match workshop_type:
		DFWorkshop.WorkshopType.CARPENTRY: return Skill.CARPENTRY
		DFWorkshop.WorkshopType.MASONRY: return Skill.MASONRY
		DFWorkshop.WorkshopType.KITCHEN: return Skill.COOKING
		DFWorkshop.WorkshopType.STILL: return Skill.BREWING
		DFWorkshop.WorkshopType.FORGE, DFWorkshop.WorkshopType.SMELTER, DFWorkshop.WorkshopType.KILN:
			return Skill.SMITHING
		DFWorkshop.WorkshopType.LOOM, DFWorkshop.WorkshopType.TANNER, DFWorkshop.WorkshopType.CRAFT_SHOP, DFWorkshop.WorkshopType.JEWELER:
			return Skill.ORGANIZING
		_: return Skill.ORGANIZING

func _workshop_input_matches_item(input_definition: Dictionary, item: DFItem) -> bool:
	if item == null or item.is_decayed:
		return false
	var item_name: String = item.name.to_lower()
	var item_type_name: String = item.item_type.to_lower()
	var material_name: String = item.material_name.to_lower()
	if bool(input_definition.get("fuel", false)):
		return (
			"carbón" in item_name or "carbon" in item_name or "coal" in item_name
			or "charcoal" in item_name or item_type_name in ["fuel", "charcoal", "coal"]
		)
	if input_definition.has("type"):
		var required_type: String = str(input_definition.get("type", "")).to_lower()
		var type_matches: bool = item_type_name == required_type or item_type_name == required_type + "s"
		if required_type == "bone":
			type_matches = type_matches or "hueso" in item_name or "bone" in item_name
		elif required_type == "skull":
			type_matches = type_matches or "cráneo" in item_name or "craneo" in item_name or "calavera" in item_name or "skull" in item_name
		elif required_type == "crafting" and item_type_name in ["bone", "skull"]:
			type_matches = true
		if not type_matches:
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
		var allowed_materials: Array = input_definition.get("material", [])
		for material_value: Variant in allowed_materials:
			var allowed_name: String = str(material_value).to_lower()
			if allowed_name == item_type_name or allowed_name == material_name or allowed_name in item_name:
				return true
	return false

func _count_workshop_input_nearby(world, workshop: DFWorkshop, input_definition: Dictionary) -> int:
	var count: int = 0
	for world_value: Variant in world.entities:
		if not (world_value is DFItem):
			continue
		var item: DFItem = world_value
		if item.tile_pos.distance_squared_to(workshop.tile_pos) > 2:
			continue
		if _workshop_input_matches_item(input_definition, item):
			count += maxi(1, item.stack_size)
	return count

func _get_missing_workshop_input(world, workshop: DFWorkshop, recipe: Dictionary) -> Dictionary:
	for input_value: Variant in recipe.get("inputs", []):
		if not (input_value is Dictionary):
			continue
		var input_definition: Dictionary = input_value
		# Los ingredientes opcionales mejoran una receta, pero nunca deben
		# bloquear su producción ni dejar un aldeano esperando eternamente.
		if bool(input_definition.get("optional", false)):
			continue
		var required_count: int = maxi(1, int(input_definition.get("count", 1)))
		if _count_workshop_input_nearby(world, workshop, input_definition) < required_count:
			return input_definition
	return {}

func _workshop_input_label(input_definition: Dictionary) -> String:
	if bool(input_definition.get("fuel", false)):
		return "combustible"
	var labels: Dictionary = {
		"wood": "madera", "stone": "piedra", "bone": "huesos",
		"skull": "cráneo", "corpse": "cadáver", "hide": "piel",
		"food": "comida", "drink": "bebida", "meat": "carne",
		"metal_bar": "lingote", "gem": "gema", "cloth": "tela",
		"thread": "hilo", "fuel": "combustible", "crafting": "material artesanal"
	}
	if input_definition.has("type"):
		var required_type: String = str(input_definition.get("type", "material")).to_lower()
		return str(labels.get(required_type, required_type.replace("_", " ")))
	var materials: Array = input_definition.get("material", [])
	if not materials.is_empty():
		var material_id: String = str(materials[0]).to_lower()
		return str(labels.get(material_id, material_id.replace("_", " ")))
	return "material"

func _reset_workshop_missing_input_wait() -> void:
	workshop_missing_input_signature = ""
	workshop_missing_input_ticks = 0

func _defer_or_cancel_impossible_workshop_recipe(world, workshop: DFWorkshop, recipe: Dictionary, missing_input: Dictionary) -> void:
	var missing_label: String = _workshop_input_label(missing_input)
	var retry_count: int = int(recipe.get("_missing_input_retries", 0)) + 1
	recipe["_missing_input_retries"] = retry_count
	if retry_count >= MAX_WORKSHOP_INPUT_RETRIES:
		if not workshop.production_queue.is_empty() and workshop.production_queue[0] == recipe:
			workshop.production_queue.pop_front()
		world.messages.append("%s canceló '%s': no existe una fuente disponible de %s." % [name, str(recipe.get("name", "receta")), missing_label])
		current_task = "Canceló una receta imposible"
	else:
		recipe["_blocked_until_tick"] = _get_world_tick(world) + WORKSHOP_INPUT_RETRY_DELAY_TICKS
		recipe["_blocked_reason"] = missing_label
		world.messages.append("%s pausó '%s': faltan %s. Se volverá a revisar más tarde." % [name, str(recipe.get("name", "receta")), missing_label])
		current_task = "Pausó una receta sin materiales"
	_reset_workshop_missing_input_wait()
	_release_operating_workshop(world, true)

func _release_workshop_supply(world, drop_carried: bool = false) -> void:
	var target_item: DFItem = _get_world_item_by_id(world, workshop_supply_target_item_id)
	if target_item != null:
		target_item.release_reservation(id)
	workshop_supply_target_item_id = -1
	var carried_item: DFItem = _get_inventory_item_by_id(workshop_supply_carried_item_id)
	if carried_item != null:
		carried_item.release_reservation(id)
		if drop_carried:
			inventory.erase(carried_item)
			carried_item.carried_by_id = -1
			carried_item.is_in_stockpile = false
			carried_item.is_inside_container = false
			carried_item.tile_pos = tile_pos
			if not world.entities.has(carried_item):
				world.entities.append(carried_item)
	workshop_supply_carried_item_id = -1

func _release_operating_workshop(world, drop_supply: bool = true) -> void:
	if operating_workshop is DFWorkshop:
		var workshop: DFWorkshop = operating_workshop
		if workshop.dwarf_assigned == id:
			workshop.unassign_dwarf()
	_release_workshop_supply(world, drop_supply)
	operating_workshop = null

func _find_reachable_workshop_supply(world, input_definition: Dictionary, workshop: DFWorkshop) -> DFItem:
	var attempted_ids: Dictionary = {}
	for _attempt: int in range(MAX_PATH_CANDIDATES):
		var nearest_item: DFItem = null
		var nearest_distance: int = MAX_ITEM_SEARCH_DISTANCE * 2
		for world_value: Variant in world.entities:
			if not (world_value is DFItem):
				continue
			var candidate: DFItem = world_value
			if attempted_ids.has(candidate.id) or candidate.tile_pos.distance_squared_to(workshop.tile_pos) <= 2:
				continue
			if not _workshop_input_matches_item(input_definition, candidate):
				continue
			if not _item_available_for_self(world, candidate):
				continue
			var candidate_distance: int = _item_distance(candidate)
			if candidate_distance < nearest_distance:
				nearest_distance = candidate_distance
				nearest_item = candidate
		if nearest_item == null:
			return null
		attempted_ids[nearest_item.id] = true
		var reachable: bool = nearest_distance <= 1
		if not reachable:
			var route: Array = DFPathfinding.find_path(world, tile_pos, nearest_item.tile_pos, true)
			reachable = not route.is_empty()
		if reachable:
			return nearest_item
		_mark_item_unreachable(nearest_item.id)
	return null

func _try_supply_operating_workshop(world) -> bool:
	if not (operating_workshop is DFWorkshop):
		_release_workshop_supply(world)
		return false
	var workshop: DFWorkshop = operating_workshop
	if workshop.production_queue.is_empty():
		_release_workshop_supply(world)
		return false
	var recipe_value: Variant = workshop.production_queue[0]
	if not (recipe_value is Dictionary):
		_release_workshop_supply(world)
		return false
	var recipe: Dictionary = recipe_value
	var missing_input: Dictionary = _get_missing_workshop_input(world, workshop, recipe)
	if missing_input.is_empty():
		_reset_workshop_missing_input_wait()
		_release_workshop_supply(world)
		return false

	var carried_item: DFItem = _get_inventory_item_by_id(workshop_supply_carried_item_id)
	if carried_item != null and not _workshop_input_matches_item(missing_input, carried_item):
		_release_workshop_supply(world, true)
		carried_item = null
	if carried_item != null:
		var workshop_distance: int = (
			abs(tile_pos.x - workshop.tile_pos.x)
			+ abs(tile_pos.z - workshop.tile_pos.z)
			+ abs(tile_pos.y - workshop.tile_pos.y) * 2
		)
		if workshop_distance > 1:
			current_task = "Llevando %s a %s" % [carried_item.name, workshop.name]
			_move_toward(world, workshop.tile_pos)
			return true
		inventory.erase(carried_item)
		carried_item.carried_by_id = -1
		carried_item.release_reservation(id)
		carried_item.tile_pos = workshop.tile_pos
		carried_item.is_in_stockpile = false
		carried_item.is_inside_container = false
		world.entities.append(carried_item)
		workshop_supply_carried_item_id = -1
		current_task = "Entregando %s en %s" % [carried_item.name, workshop.name]
		needs_display_update = true
		path.clear()
		path_index = 0
		return true

	var target_item: DFItem = _get_world_item_by_id(world, workshop_supply_target_item_id)
	if target_item == null or not _workshop_input_matches_item(missing_input, target_item) or not _item_available_for_self(world, target_item):
		if target_item != null:
			target_item.release_reservation(id)
		workshop_supply_target_item_id = -1
		target_item = _find_reachable_workshop_supply(world, missing_input, workshop)
		if target_item == null:
			var missing_signature: String = _workshop_input_label(missing_input)
			if workshop_missing_input_signature != missing_signature:
				workshop_missing_input_signature = missing_signature
				workshop_missing_input_ticks = 0
			workshop_missing_input_ticks += 1
			if workshop_missing_input_ticks >= WORKSHOP_INPUT_WAIT_TICKS:
				_defer_or_cancel_impossible_workshop_recipe(world, workshop, recipe, missing_input)
				return true
			current_task = "Esperando %s para %s (%d/%d)" % [missing_signature, workshop.name, workshop_missing_input_ticks, WORKSHOP_INPUT_WAIT_TICKS]
			return true
		_reset_workshop_missing_input_wait()
		target_item.reserve_for(id, _get_world_tick(world) + ITEM_RESERVATION_TICKS)
		workshop_supply_target_item_id = target_item.id
		path.clear()
		path_index = 0

	target_item.reserve_for(id, _get_world_tick(world) + ITEM_RESERVATION_TICKS)
	var target_distance: int = _item_distance(target_item)
	if target_distance > 1 or target_item.tile_pos.y != tile_pos.y:
		current_task = "Recogiendo %s para %s" % [target_item.name, workshop.name]
		_move_toward(world, target_item.tile_pos)
		return true
	if not world.entities.has(target_item):
		target_item.release_reservation(id)
		workshop_supply_target_item_id = -1
		return true
	world.entities.erase(target_item)
	target_item.carried_by_id = id
	target_item.is_in_stockpile = false
	target_item.is_inside_container = false
	target_item.release_reservation(id)
	inventory.append(target_item)
	workshop_supply_target_item_id = -1
	workshop_supply_carried_item_id = target_item.id
	current_task = "Llevando %s a %s" % [target_item.name, workshop.name]
	needs_display_update = true
	path.clear()
	path_index = 0
	return true

func _operate_workshop(world) -> void:
	if is_possessed:
		return
	if not (operating_workshop is DFWorkshop):
		operating_workshop = null
		_release_workshop_supply(world)
		return
	var workshop: DFWorkshop = operating_workshop

	if workshop.production_queue.is_empty():
		_release_workshop_supply(world)
		workshop.unassign_dwarf()
		operating_workshop = null
		current_task = "idle"
		return

	var dist: int = (
		abs(tile_pos.x - workshop.tile_pos.x)
		+ abs(tile_pos.z - workshop.tile_pos.z)
		+ abs(tile_pos.y - workshop.tile_pos.y) * 2
	)
	# Antes de fabricar, el propio operador concreta la logística del taller:
	# reserva el insumo, lo recoge y lo entrega físicamente.
	if _try_supply_operating_workshop(world):
		return
	if dist <= 1:
		current_task = "Operando " + workshop.name
		var workshop_skill: int = _workshop_skill_for_type(workshop.workshop_type)
		add_skill_xp(workshop_skill, 1)
		workshop.operator_skill = get_skill_level(workshop_skill)
	else:
		current_task = "Yendo a " + workshop.name
		_move_toward(world, workshop.tile_pos)

func _check_workshops(world) -> void:
	if is_possessed or operating_workshop != null:
		return
	var best_workshop: DFWorkshop = null
	var best_score: int = -2147483648
	for workshop_value: Variant in world.workshops:
		if not (workshop_value is DFWorkshop):
			continue
		var workshop: DFWorkshop = workshop_value
		if workshop.dwarf_assigned >= 0 or workshop.production_queue.is_empty():
			continue
		var queued_recipe_value: Variant = workshop.production_queue[0]
		if queued_recipe_value is Dictionary:
			var queued_recipe: Dictionary = queued_recipe_value
			var blocked_until_tick: int = int(queued_recipe.get("_blocked_until_tick", 0))
			if blocked_until_tick > _get_world_tick(world):
				continue
			if blocked_until_tick > 0:
				queued_recipe.erase("_blocked_until_tick")
				queued_recipe.erase("_blocked_reason")
		var distance: int = (
			abs(tile_pos.x - workshop.tile_pos.x)
			+ abs(tile_pos.z - workshop.tile_pos.z)
			+ abs(tile_pos.y - workshop.tile_pos.y) * 2
		)
		var skill_id: int = _workshop_skill_for_type(workshop.workshop_type)
		var score: int = get_skill_level(skill_id) * 20 - distance
		if profession == Profession.CARPENTER and workshop.workshop_type == DFWorkshop.WorkshopType.CARPENTRY:
			score += 80
		elif profession == Profession.MASON and workshop.workshop_type == DFWorkshop.WorkshopType.MASONRY:
			score += 80
		elif profession == Profession.COOK and workshop.workshop_type == DFWorkshop.WorkshopType.KITCHEN:
			score += 80
		elif profession == Profession.BREWER and workshop.workshop_type == DFWorkshop.WorkshopType.STILL:
			score += 80
		elif profession == Profession.SMITH and workshop.workshop_type in [DFWorkshop.WorkshopType.FORGE, DFWorkshop.WorkshopType.SMELTER, DFWorkshop.WorkshopType.KILN]:
			score += 80
		if score > best_score:
			best_score = score
			best_workshop = workshop

	if best_workshop != null:
		operating_workshop = best_workshop
		var workshop_skill: int = _workshop_skill_for_type(best_workshop.workshop_type)
		best_workshop.assign_dwarf(id, get_skill_level(workshop_skill))
		current_task = "Yendo a " + best_workshop.name

func _consume_inventory_material(kw: String) -> void:
	for item in inventory:
		if kw in item.name.lower():
			inventory.erase(item)
			return

func _count_inventory_consumables(kind: String) -> int:
	var count: int = 0
	for candidate in inventory:
		if candidate is DFItem and _item_matches_consumable_kind(candidate, kind):
			count += maxi(1, candidate.stack_size)
	return count

func _try_collect_personal_supplies(world) -> bool:
	var desired_kind: String = ""
	if _count_inventory_consumables("food") < PERSONAL_FOOD_TARGET:
		desired_kind = "food"
	elif _count_inventory_consumables("drink") < PERSONAL_DRINK_TARGET:
		desired_kind = "drink"
	else:
		_release_supply_target(world)
		return false

	var target: DFItem = _get_world_item_by_id(world, supply_target_item_id)
	if target == null or supply_target_kind != desired_kind or not _item_matches_consumable_kind(target, desired_kind) or not _item_available_for_self(world, target):
		_release_supply_target(world)
		target = _find_reachable_consumable(world, desired_kind, MAX_ITEM_SEARCH_DISTANCE)
		if target == null:
			return false
		target.reserve_for(id, _get_world_tick(world) + ITEM_RESERVATION_TICKS)
		supply_target_item_id = target.id
		supply_target_kind = desired_kind
		path.clear()
		path_index = 0

	target.reserve_for(id, _get_world_tick(world) + ITEM_RESERVATION_TICKS)
	var distance: int = _item_distance(target)
	if distance <= 1 and target.tile_pos.y == tile_pos.y:
		var current_amount: int = _count_inventory_consumables(desired_kind)
		var desired_amount: int = PERSONAL_DRINK_TARGET if desired_kind == "drink" else PERSONAL_FOOD_TARGET
		var amount_needed: int = maxi(1, desired_amount - current_amount)
		var picked_item: DFItem = target
		if target.stack_size > amount_needed:
			var split_value: Variant = target.split_stack(amount_needed)
			if split_value is DFItem:
				picked_item = split_value
			target.release_reservation(id)
		else:
			if world.entities.has(target):
				world.entities.erase(target)
		picked_item.carried_by_id = id
		picked_item.is_in_stockpile = false
		picked_item.is_inside_container = false
		picked_item.release_reservation(id)
		inventory.append(picked_item)
		_clear_supply_target_state()
		current_task = "Añadiendo a su mochila: " + picked_item.name
		needs_display_update = true
		return true

	current_task = "Recogiendo provisiones: " + target.name
	_move_toward(world, target.tile_pos)
	return true

func _clear_supply_target_state() -> void:
	supply_target_item_id = -1
	supply_target_kind = ""

func _release_supply_target(world) -> void:
	var item: DFItem = _get_world_item_by_id(world, supply_target_item_id)
	if item != null:
		item.release_reservation(id)
	_clear_supply_target_state()


func _can_use_stockpile(stockpile_value: Variant) -> bool:
	if stockpile_value == null:
		return false
	var is_foreign_value: bool = bool(_safe_get(stockpile_value, "is_foreign", false))
	if not is_foreign_value:
		return true
	return is_world_settlement_resident and int(_safe_get(stockpile_value, "owner_site_id", -1)) == settlement_site_id

func _find_free_stockpile_tile(world, preferred_item_type: String = "") -> Vector3i:
	var best_position: Vector3i = Vector3i(-1, -1, -1)
	var best_distance: int = 999999
	for stockpile_value: Variant in world.stockpiles:
		if not _can_use_stockpile(stockpile_value):
			continue
		var candidates: Array = []
		if stockpile_value.has_method("get_candidate_tiles"):
			candidates = stockpile_value.get_candidate_tiles(
				world, preferred_item_type, MAX_STOCKPILE_PATH_CANDIDATES
			)
		else:
			var fallback_candidate: Vector3i = stockpile_value.get_free_tile(world, preferred_item_type)
			if fallback_candidate.y >= 0:
				candidates.append(fallback_candidate)

		for candidate_value: Variant in candidates:
			var candidate: Vector3i = candidate_value
			var distance: int = (
				abs(candidate.x - tile_pos.x)
				+ abs(candidate.z - tile_pos.z)
				+ abs(candidate.y - tile_pos.y) * 2
			)
			if distance >= best_distance:
				continue
			var reachable: bool = tile_pos == candidate
			if not reachable:
				var route: Array = DFPathfinding.find_path(world, tile_pos, candidate, true)
				reachable = not route.is_empty()
			if reachable:
				best_distance = distance
				best_position = candidate
	return best_position

func _is_haulable_loose_item(item: DFItem) -> bool:
	if item.is_bed or item.is_corpse or item.item_type in ["furniture", "door", "corpse"]:
		return false
	# Las reservas impiden que dos enanos persigan el mismo recurso. Madera y
	# piedra también pueden transportarse como mantenimiento si ningún trabajo las reservó.
	if item.is_in_stockpile or item.is_inside_container or item.carried_by_id >= 0:
		return false
	return true

func _try_idle_haul(world) -> bool:
	var carried_item: DFItem = _get_inventory_item_by_id(hauling_item_id)
	if carried_item != null:
		if haul_destination.y < 0:
			haul_destination = _find_free_stockpile_tile(world, carried_item.item_type)
		if haul_destination.y < 0:
			carried_item.tile_pos = tile_pos
			carried_item.carried_by_id = -1
			carried_item.release_reservation(id)
			inventory.erase(carried_item)
			world.entities.append(carried_item)
			_reset_haul_state()
			return false
		var distance_to_destination: int = (
			abs(tile_pos.x - haul_destination.x)
			+ abs(tile_pos.z - haul_destination.z)
			+ abs(tile_pos.y - haul_destination.y) * 2
		)
		# Los objetos se colocan desde una casilla adyacente. Esto permite usar
		# estanterías visibles sin obligar al aldeano a ocupar exactamente su tile.
		if distance_to_destination <= 1:
			inventory.erase(carried_item)
			carried_item.tile_pos = haul_destination
			carried_item.carried_by_id = -1
			carried_item.is_in_stockpile = true
			carried_item.is_inside_container = _is_food_store_tile(world, haul_destination) and carried_item.item_type in ["food", "drink", "meat", "fish"]
			carried_item.release_reservation(id)
			if not world.entities.has(carried_item):
				world.entities.append(carried_item)
			current_task = "Almacenando " + carried_item.name
			needs_display_update = true
			_reset_haul_state()
			return true
		if path.is_empty():
			var delivery_route: Array = DFPathfinding.find_path(world, tile_pos, haul_destination, true)
			if delivery_route.is_empty():
				carried_item.set_meta("storage_blocked_until", _get_world_tick(world) + 600)
				inventory.erase(carried_item)
				carried_item.tile_pos = tile_pos
				carried_item.carried_by_id = -1
				carried_item.is_in_stockpile = false
				carried_item.is_inside_container = false
				carried_item.release_reservation(id)
				if not world.entities.has(carried_item):
					world.entities.append(carried_item)
				_reset_haul_state()
				current_task = "No hay ruta al almacén"
				return false
			path = delivery_route
			path_index = 0
		current_task = "Llevando " + carried_item.name + " al almacén"
		_move_toward(world, haul_destination)
		return true

	var target: DFItem = _get_world_item_by_id(world, haul_target_item_id)
	if target != null:
		if not _is_haulable_loose_item(target) or not _item_available_for_self(world, target):
			_reset_haul_target(world)
			return false
		if haul_destination.y < 0:
			haul_destination = _find_free_stockpile_tile(world, target.item_type)
		if haul_destination.y < 0:
			_mark_item_unreachable(target.id)
			_reset_haul_target(world)
			current_task = "No hay almacén accesible"
			return false
		target.reserve_for(id, _get_world_tick(world) + ITEM_RESERVATION_TICKS)
		var distance_to_target: int = _item_distance(target)
		if distance_to_target <= 1 and target.tile_pos.y == tile_pos.y:
			if world.entities.has(target):
				world.entities.erase(target)
			target.carried_by_id = id
			inventory.append(target)
			hauling_item_id = target.id
			haul_target_item_id = -1
			# El destino ya fue validado antes de recoger el objeto.
			path.clear()
			path_index = 0
			current_task = "Llevando " + target.name + " al almacén"
			return true
		current_task = "Yendo a recoger " + target.name
		_move_toward(world, target.tile_pos)
		return true

	if world.stockpiles.is_empty():
		return false

	var attempted_ids: Dictionary = {}
	for _attempt in range(MAX_PATH_CANDIDATES):
		var nearest: DFItem = null
		var nearest_distance: int = MAX_ITEM_SEARCH_DISTANCE + 1
		for entity in world.entities:
			if not entity is DFItem:
				continue
			var item: DFItem = entity
			if attempted_ids.has(item.id) or _is_item_temporarily_unreachable(item.id):
				continue
			if not _is_haulable_loose_item(item) or not _item_available_for_self(world, item):
				continue
			var distance: int = _item_distance(item)
			if distance <= MAX_ITEM_SEARCH_DISTANCE and distance < nearest_distance:
				nearest = item
				nearest_distance = distance
		if nearest == null:
			return false
		attempted_ids[nearest.id] = true
		var reachable: bool = nearest_distance <= 1
		if not reachable:
			var candidate_path: Array = DFPathfinding.find_path(world, tile_pos, nearest.tile_pos, true)
			reachable = not candidate_path.is_empty()
		if reachable:
			var reachable_destination: Vector3i = _find_free_stockpile_tile(world, nearest.item_type)
			if reachable_destination.y < 0:
				_mark_item_unreachable(nearest.id)
				continue
			nearest.reserve_for(id, _get_world_tick(world) + ITEM_RESERVATION_TICKS)
			haul_target_item_id = nearest.id
			haul_destination = reachable_destination
			path.clear()
			path_index = 0
			current_task = "Yendo a recoger " + nearest.name
			return true
		_mark_item_unreachable(nearest.id)
	return false

func _reset_haul_target(world) -> void:
	var target: DFItem = _get_world_item_by_id(world, haul_target_item_id)
	if target != null:
		target.release_reservation(id)
	haul_target_item_id = -1
	haul_destination = Vector3i(-1, -1, -1)

func _reset_haul_state() -> void:
	haul_target_item_id = -1
	hauling_item_id = -1
	haul_destination = Vector3i(-1, -1, -1)
	path.clear()
	path_index = 0

func _release_all_item_reservations(world) -> void:
	_release_survival_target(world)
	_release_supply_target(world)
	_release_operating_workshop(world, true)
	var carried_item: DFItem = _get_inventory_item_by_id(hauling_item_id)
	if carried_item != null:
		carried_item.release_reservation(id)
	_reset_haul_target(world)
	_reset_haul_state()

func _find_surplus_inventory_item() -> DFItem:
	var food_seen: int = 0
	var drink_seen: int = 0
	for inventory_value in inventory:
		if not (inventory_value is DFItem):
			continue
		var item: DFItem = inventory_value
		if item.is_tool or item.is_weapon or item.is_armor or item.item_type in ["tool", "weapon", "armor", "clothing", "furniture", "door"]:
			continue
		if item.item_type in ["wood", "stone", "bar", "ore", "plant", "meat", "fish", "hide", "thread", "cloth"]:
			return item
		if item.item_type == "food":
			food_seen += maxi(1, item.stack_size)
			if food_seen > PERSONAL_FOOD_TARGET:
				return item
		elif item.item_type == "drink":
			drink_seen += maxi(1, item.stack_size)
			if drink_seen > PERSONAL_DRINK_TARGET:
				return item
	return null

func _try_store_surplus_inventory(world) -> bool:
	if hauling_item_id >= 0:
		return _try_idle_haul(world)
	var surplus_item: DFItem = _find_surplus_inventory_item()
	if surplus_item == null:
		return false
	var destination: Vector3i = _find_free_stockpile_tile(world, surplus_item.item_type)
	if destination.y < 0:
		return false
	hauling_item_id = surplus_item.id
	haul_destination = destination
	surplus_item.carried_by_id = id
	current_task = "Llevando " + surplus_item.name + " al almacén"
	return _try_idle_haul(world)

func _primary_work_skill() -> int:
	match profession:
		Profession.MINER: return Skill.MINING
		Profession.WOODCUTTER: return Skill.WOODCUTTING
		Profession.CARPENTER: return Skill.CARPENTRY
		Profession.MASON: return Skill.MASONRY
		Profession.FARMER: return Skill.FARMING
		Profession.COOK: return Skill.COOKING
		Profession.BREWER: return Skill.BREWING
		Profession.HUNTER, Profession.MILITARY: return Skill.MILITARY_TACTICS
		Profession.DOCTOR, Profession.CHIEF_MEDICAL_DWARF: return Skill.DOCTORING
		Profession.SMITH: return Skill.SMITHING
		_: return Skill.ORGANIZING

func _work_skill_label(skill_id: int) -> String:
	match skill_id:
		Skill.MINING: return "minería"
		Skill.WOODCUTTING: return "tala"
		Skill.CARPENTRY: return "carpintería"
		Skill.MASONRY: return "albañilería"
		Skill.FARMING: return "agricultura"
		Skill.COOKING: return "cocina"
		Skill.BREWING: return "cervecería"
		Skill.MILITARY_TACTICS: return "caza y combate"
		Skill.DOCTORING: return "medicina"
		Skill.SMITHING: return "herrería"
		_: return "organización"

func _perform_productive_fallback(world) -> void:
	# El turno laboral nunca termina en un estado pasivo. Si no existen labores
	# urgentes, el aldeano organiza, inspecciona y practica su oficio.
	if _try_idle_haul(world):
		return
	var practice_skill: int = _primary_work_skill()
	if _ai_tick_counter % 25 == 0:
		add_skill_xp(practice_skill, 1)
		needs[Need.WORK] = maxf(0.0, float(needs.get(Need.WORK, 0.0)) - 0.015)
	current_task = "Practicando %s y revisando la colonia" % _work_skill_label(practice_skill)
	if _ai_tick_counter % 4 == 0:
		_idle_wander(world)

func tick_autonomous_survival(world, allow_leisure: bool = true) -> void:
	# Terminar primero un transporte ya iniciado. De lo contrario el enano puede
	# recoger un objeto y abandonar la entrega al cambiar de decisión en el tick siguiente.
	if haul_target_item_id >= 0 or hauling_item_id >= 0:
		if _try_idle_haul(world):
			return

	# Antes de ocio o estudio, cada enano completa su reserva personal.
	if _try_collect_personal_supplies(world):
		return
	if _tick_hunting_behavior(world):
		return
	# Evaluar refugio
	var day_time_val = world.get("day_time")
	var game_hour = float(day_time_val) * 24.0 if day_time_val != null else 12.0
	var night_time = game_hour < 6 or game_hour > 18
	var weather_name_val = world.get("weather_name")
	var weather_name = str(weather_name_val) if weather_name_val != null else ""
	var bad_weather = "lluvia" in weather_name.to_lower() or "tormenta" in weather_name.to_lower() or "nieve" in weather_name.to_lower() or "ventisca" in weather_name.to_lower()
	var is_outdoor = true  
	if is_outdoor and (night_time or bad_weather):
		needs[Need.SHELTER] = min(needs.get(Need.SHELTER, 0.0) + 0.01, 1.0)
	else:
		needs[Need.SHELTER] = max(needs.get(Need.SHELTER, 0.0) - 0.02, 0.0)
	
	# Buscar comida activamente si hay algo de hambre (umbral mas bajo)
	if hunger > 0.2 and inventory.is_empty():
		var nearest_food = null
		var nearest_dist = 99999
		# Buscar en stockpiles primero (comida almacenada)
		if not world.stockpiles.is_empty():
			for sp in world.stockpiles:
				for stock_tile in sp.tiles:
					for e in world.entities:
						if e is DFItem and e.tile_pos == stock_tile and e.get("item_type") in ["food", "drink", "seed"]:
							var d = abs(e.tile_pos.x - tile_pos.x) + abs(e.tile_pos.z - tile_pos.z)
							if d < nearest_dist:
								nearest_dist = d
								nearest_food = e
		for e_2770 in world.entities:
			if e_2770 is DFItem and e_2770.get("item_type") in ["food", "drink", "seed"]:
				var d_2772 = abs(e_2770.tile_pos.x - tile_pos.x) + abs(e_2770.tile_pos.z - tile_pos.z)
				if d_2772 < nearest_dist:
					nearest_dist = d_2772
					nearest_food = e_2770
		if nearest_food == null:
			for dz in range(-12, 13):
				for dx in range(-12, 13):
					var pos = Vector3i(tile_pos.x + dx, tile_pos.y, tile_pos.z + dz)
					if pos.x < 0 or pos.x >= world.width or pos.z < 0 or pos.z >= world.depth:
						continue
					var td = world.get_tile_data(pos)
					if td.get("crop_type", "") != "" and td.get("growth", 0) >= 0.7:
						var d_2784 = abs(dx) + abs(dz)
						if d_2784 < nearest_dist:
							nearest_dist = d_2784
							nearest_food = pos
		if nearest_food != null:
			current_task = "Buscando alimento silvestre"
			if nearest_food is DFItem:
				var dist = abs(nearest_food.tile_pos.x - tile_pos.x) + abs(nearest_food.tile_pos.z - tile_pos.z)
				if dist <= 1:
					world.entities.erase(nearest_food)
					hunger = 0.0
					add_thought("Me siento mejor tras comer.", 0.1)
					current_task = "idle"
					return
				else:
					_move_toward(world, nearest_food.tile_pos)
					return
			else:
				var dist_2802 = abs(nearest_food.x - tile_pos.x) + abs(nearest_food.z - tile_pos.z)
				if dist_2802 <= 1:
					var key = nearest_food
					if world.tile_data.has(key):
						world.tile_data[key]["crop_type"] = ""
						world.tile_data[key]["growth"] = 0.0
						world.tile_data[key]["harvestable"] = false
						hunger = 0.0
						add_thought("Coseche y comi alimentos del bosque.", 0.15)
						current_task = "idle"
						return
				else:
					_move_toward(world, nearest_food)
					return

	# --- COMPORTAMIENTOS AUTÓNOMOS DE TRABAJO Y SUPERVIVENCIA ---
	
	# La tala y la minería se ejecutan exclusivamente mediante DFJob.
	# Antes se realizaban también aquí de forma directa, lo que permitía que un
	# enano destruyera el objetivo reservado por otro y dejara su trabajo atascado
	# permanentemente en IN_PROGRESS.

	# 3. Encender fogata y cocinar con varillas (si hay recursos y no hay fogata activa)
	var has_campfire = false
	for bld in world.buildings:
		if bld.type == 19: # 19 = BuildingType.CAMPFIRE
			has_campfire = true
			break
			
	var can_manage_campfire: bool = _is_primary_campfire_worker(world)
	if not has_campfire and can_manage_campfire:
		# Solo un cocinero/cervecero gestiona la fogata. Antes todos los enanos
		# perseguían la misma leña y comida sin reservas.
		# Comprobar si tenemos comida y leña en el inventario
		var has_inv_fuel = false
		var has_inv_food = false
		var fuel_inv_item = null
		var food_inv_item = null
		
		for inv_item_2875 in inventory:
			if inv_item_2875.item_type == "wood" or inv_item_2875.item_type == "bar":
				has_inv_fuel = true
				fuel_inv_item = inv_item_2875
			elif inv_item_2875.item_type == "food" and not "Caliente" in inv_item_2875.name:
				has_inv_food = true
				food_inv_item = inv_item_2875
				
		if has_inv_fuel and has_inv_food:
			# Ir al centro de la colonia a cocinar
			var plaza_center: Vector3i = world.get_meta("settlement_center", Vector3i(128, tile_pos.y, 128))
			var plaza_pos = Vector3i(plaza_center.x, world.get_surface_height(plaza_center.x, plaza_center.z), plaza_center.z)
			var dist_plaza = abs(tile_pos.x - plaza_pos.x) + abs(tile_pos.z - plaza_pos.z)
			if dist_plaza > 2:
				current_task = "Yendo a la plaza a cocinar"
				_move_toward(world, plaza_pos)
				return
			else:
				# Crear fogata
				var camp_bld = DFBuilding.new(19, tile_pos) # 19 = CAMPFIRE
				world.buildings.append(camp_bld)
				# Quitar de inventario
				inventory.erase(fuel_inv_item)
				inventory.erase(food_inv_item)
				# Spawnear comida cocinada caliente o carne
				var cooked_name = "Carne Cocinada Caliente" if "Carne Cruda" in food_inv_item.name else "Plump Helmet Caliente"
				world._spawn_item(tile_pos, cooked_name, "food", 0, "%", Color("#FF5500"))
				add_thought("Encendi una fogata y prepare comida caliente sobre varillas.", 0.25)
				current_task = "Cocinando comida"
				return
		else:
			# Buscar recursos en el suelo/almacén para traerlos
			if not has_inv_fuel:
				var target_fuel = _find_nearest_item_matching_type(world, "wood")
				if target_fuel == null:
					target_fuel = _find_nearest_item_matching_type(world, "bar")
				if target_fuel != null:
					current_task = "Recogiendo lena para fogata"
					var dist_fuel = abs(tile_pos.x - target_fuel.tile_pos.x) + abs(tile_pos.z - target_fuel.tile_pos.z)
					if dist_fuel <= 1:
						inventory.append(target_fuel)
						world.entities.erase(target_fuel)
					else:
						_move_toward(world, target_fuel.tile_pos)
					return
			if not has_inv_food:
				var target_food = _find_nearest_item_matching_type(world, "food")
				if target_food != null and not "Caliente" in target_food.name:
					current_task = "Recogiendo comida para cocinar"
					var dist_food = abs(tile_pos.x - target_food.tile_pos.x) + abs(tile_pos.z - target_food.tile_pos.z)
					if dist_food <= 1:
						inventory.append(target_food)
						world.entities.erase(target_food)
					else:
						_move_toward(world, target_food.tile_pos)
					return

	# Transportar objetos sueltos solo cuando no apareció una tarea productiva anterior.
	if _try_idle_haul(world):
		return

	if not allow_leisure:
		_perform_productive_fallback(world)
		return

	# El estudio es una actividad secundaria y limitada.
	var is_sleep_time_survival: bool = game_hour >= 22.0 or game_hour < 6.0
	productive_idle_ticks += 1
	var intellect_need: float = float(needs.get(Need.INTELLECT, 0.0))
	var curiosity: float = get_trait(PersonalityTrait.CURIOSITY)
	var can_start_study: bool = not is_sleep_time_survival and productive_idle_ticks >= 20 and intellect_need >= 0.55 and randf() < (0.05 + curiosity * 0.08)
	if study_session_ticks > 0 or can_start_study:
		if study_session_ticks <= 0:
			study_session_ticks = 12 + randi() % 18
			preferred_study_skill = randi() % 7
		study_session_ticks -= 1
		var master = _find_nearby_master_for_skill(world, preferred_study_skill)
		if master != null:
			var dist_to_master = abs(tile_pos.x - master.tile_pos.x) + abs(tile_pos.z - master.tile_pos.z)
			if dist_to_master > 1:
				_move_toward(world, master.tile_pos)
				current_task = "Yendo a aprender de %s" % master.name
			else:
				current_task = "Estudiando de %s" % master.name
				add_skill_xp(preferred_study_skill, 3)
		else:
			current_task = "Estudiando por cuenta propia"
			add_skill_xp(preferred_study_skill, 1)
		needs[Need.INTELLECT] = maxf(0.0, intellect_need - 0.035)
		if study_session_ticks <= 0:
			preferred_study_skill = -1
			productive_idle_ticks = 0
		return

	# Si no se puede hacer nada de lo anterior, merodear libremente
	_idle_wander(world)


func _is_primary_campfire_worker(world) -> bool:
	if profession not in [Profession.COOK, Profession.BREWER]:
		return false
	var selected_id: int = id
	for entity in world.entities:
		if not (entity is DFDwarf):
			continue
		var other: DFDwarf = entity
		if not other.is_alive or other.profession not in [Profession.COOK, Profession.BREWER]:
			continue
		if other.id < selected_id:
			selected_id = other.id
	return id == selected_id


func _text_has_any(value: String, aliases: Array) -> bool:
	var normalized := value.to_lower()
	for alias in aliases:
		if str(alias).to_lower() in normalized:
			return true
	return false

func _tool_aliases_for_job(job_type: int) -> Array:
	match job_type:
		DFJob.JobType.DIG:
			return ["pickaxe", "pick", "pico", "piqueta"]
		DFJob.JobType.CHOP_TREE:
			return ["woodcutter axe", "axe", "hacha"]
		DFJob.JobType.HUNT:
			return ["crossbow", "bow", "spear", "sword", "axe", "knife", "dagger", "mace", "ballesta", "arco", "lanza", "espada", "hacha", "cuchillo", "daga", "maza"]
		_:
			return []

func _has_tool_for_job(job_type: int) -> bool:
	if job_type == DFJob.JobType.FISH:
		return true
	var aliases := _tool_aliases_for_job(job_type)
	if aliases.is_empty():
		return true
	if _text_has_any(equipped_weapon, aliases):
		return true
	for item in inventory:
		if item is DFItem and _text_has_any(item.name, aliases):
			return true
	return false

func _find_nearest_tool_on_ground(world, job_type: int) -> DFItem:
	var aliases: Array = _tool_aliases_for_job(job_type)
	var nearest_item: DFItem = null
	var nearest_dist: int = 999999
	for e in world.entities:
		if e is DFItem and _text_has_any(e.name, aliases):
			if _is_item_temporarily_unreachable(e.id) or not _item_available_for_self(world, e):
				continue
			var d: int = abs(tile_pos.x - e.tile_pos.x) + abs(tile_pos.z - e.tile_pos.z) + abs(tile_pos.y - e.tile_pos.y) * 2
			if d < nearest_dist:
				nearest_dist = d
				nearest_item = e
	return nearest_item

func _find_nearest_item_on_ground_matching(world, item_substring: String):
	var nearest_item = null
	var nearest_dist := 999999
	var query := item_substring.to_lower()
	for e in world.entities:
		if e is DFItem and query in e.name.to_lower():
			var d: int = abs(tile_pos.x - e.tile_pos.x) + abs(tile_pos.z - e.tile_pos.z)
			if d < nearest_dist:
				nearest_dist = d
				nearest_item = e
	return nearest_item


func _find_nearest_tree(world) -> Vector3i:
	var nearest = Vector3i(-1, -1, -1)
	var nearest_dist = 15.0
	for dz in range(-15, 16):
		for dx in range(-15, 16):
			var check_pos = tile_pos + Vector3i(dx, 0, dz)
			if check_pos.x < 0 or check_pos.x >= world.width or check_pos.z < 0 or check_pos.z >= world.depth: continue
			var tile_type = world.get_tile(check_pos)
			if tile_type == DFWorld.TileType.TREE:
				var d = abs(dx) + abs(dz)
				if d < nearest_dist:
					nearest_dist = d
					nearest = check_pos
	return nearest

func _find_nearest_mineable_wall(world) -> Vector3i:
	var nearest = Vector3i(-1, -1, -1)
	var nearest_dist = 15.0
	for dz in range(-15, 16):
		for dx in range(-15, 16):
			var check_pos = tile_pos + Vector3i(dx, 0, dz)
			if check_pos.x < 0 or check_pos.x >= world.width or check_pos.z < 0 or check_pos.z >= world.depth: continue
			var tile_type = world.get_tile(check_pos)
			if tile_type == DFWorld.TileType.WALL or tile_type == DFWorld.TileType.CAVE_WALL:
				var d = abs(dx) + abs(dz)
				if d < nearest_dist:
					nearest_dist = d
					nearest = check_pos
	return nearest

func _find_nearest_item_matching_type(world, it_type: String):
	var nearest = null
	var nearest_dist = 9999.0
	for e in world.entities:
		if e is DFItem and e.get("item_type") == it_type:
			var d = abs(tile_pos.x - e.tile_pos.x) + abs(tile_pos.z - e.tile_pos.z)
			if d < nearest_dist:
				nearest_dist = d
				nearest = e
	return nearest

# ---- STRANGE MOOD SYSTEM ----
func _check_strange_mood_trigger(world) -> void:
	var skill_total = 0
	var highest_skill = 0
	for s in Skill.values():
		var lvl = skills.get(s, 0)
		skill_total += lvl
		if lvl > highest_skill:
			highest_skill = lvl

	var avg_skill = float(skill_total) / float(Skill.values().size())
	var trigger_chance = 0.0

	if highest_skill >= 4:
		trigger_chance += 0.00008
	if avg_skill >= 2.0:
		trigger_chance += 0.00004
	if artistic_inspiration > 0.7:
		trigger_chance += 0.0001
	if stress > 0.6:
		trigger_chance += 0.00006
	if is_military and kill_count > 5:
		trigger_chance += 0.00008

	trigger_chance *= (1.0 + float(highest_skill) * 0.2)

	if trigger_chance <= 0.0:
		return

	if randf() < trigger_chance:
		_trigger_strange_mood(world)

func _trigger_strange_mood(world) -> void:
	var roll = randf()
	var mood_type: int
	if roll < 0.35:
		mood_type = StrangeMoodType.FEY
	elif roll < 0.60:
		mood_type = StrangeMoodType.POSSESSED
	elif roll < 0.78:
		mood_type = StrangeMoodType.MACABRE
	elif roll < 0.92:
		mood_type = StrangeMoodType.FELL
	else:
		mood_type = StrangeMoodType.SECRETIVE

	var mood_map = {
		StrangeMoodType.FEY: MoodState.STRANGE_MOOD,
		StrangeMoodType.POSSESSED: MoodState.STRANGE_MOOD,
		StrangeMoodType.MACABRE: MoodState.MACABRE_MOOD,
		StrangeMoodType.FELL: MoodState.FELL_MOOD,
		StrangeMoodType.SECRETIVE: MoodState.SECRETIVE_MOOD
	}
	mood = mood_map.get(mood_type, MoodState.STRANGE_MOOD)
	strange_mood_type = mood_type
	strange_mood_phase = StrangeMoodPhase.SEEKING_WORKSHOP
	strange_mood_workshop_pos = Vector3i(-1, -1, -1)
	strange_mood_workshop_ref = null
	strange_mood_materials_needed = {}
	strange_mood_materials_gathered = {}
	strange_mood_work_progress = 0.0
	strange_mood_artifact_material = randi() % 11
	strange_mood_build_materials_needed = 3
	strange_mood_build_materials_delivered = 0
	strange_mood_build_target_item_id = -1
	strange_mood_build_carried_item_id = -1
	strange_mood_artifact_target_item_id = -1
	strange_mood_artifact_carried_item_id = -1
	strange_mood_missing_material = ""
	strange_mood_missing_ticks = 0

	if current_job != null:
		_abandon_current_job(world, true, "Abandonó temporalmente su trabajo por un estado de ánimo extraño.")
	if operating_workshop != null:
		_release_operating_workshop(world, true)

	var mood_names = {
		StrangeMoodType.FEY: "¡INSPIRACIÓN FÉERICA!",
		StrangeMoodType.POSSESSED: "¡POSESIONADO!",
		StrangeMoodType.MACABRE: "¡MODO MACABRO!",
		StrangeMoodType.FELL: "¡MODO SINIESTRO!",
		StrangeMoodType.SECRETIVE: "¡IMPULSO SECRETO!"
	}
	var mood_descs = {
		StrangeMoodType.FEY: "%s tiene una visión extraordinaria. ¡Debe crear una obra maestra!",
		StrangeMoodType.POSSESSED: "%s ha sido poseído por un espíritu artístico. Busca un taller urgentemente.",
		StrangeMoodType.MACABRE: "%s tiene visiones macabras de muerte y gloria. Busca crear algo... siniestro.",
		StrangeMoodType.FELL: "%s siente un impulso oscuro. Algo terrible va a crear.",
		StrangeMoodType.SECRETIVE: "%s se siente misteriosamente inspirado. Necesita privacidad para crear."
	}

	current_task = mood_names.get(mood_type, "¡MODO EXTRAÑO!")
	var msg = mood_descs.get(mood_type, "%s entra en un mood extraño.") % name
	world.messages.append("¡¡ " + msg + " !!")
	artistic_inspiration = 1.0
	mood_counter = 200 + randi() % 300

	_generate_mood_requirements(world)
	add_thought("Siente una inspiración abrumadora.", 0.1)

func _generate_mood_requirements(world) -> void:
	var common_materials: Array[String] = ["GRANITE", "LIMESTONE", "IRON", "GOLD", "SILVER", "COPPER", "WOOD", "OBSIDIAN", "MARBLE", "BONE", "SKULL"]
	var art_types: Array[String] = ["weapon", "armor", "furniture", "toy", "instrument", "craft"]
	var mood_mat_prefs: Dictionary = {
		StrangeMoodType.FEY: ["GOLD", "SILVER", "MARBLE", "OBSIDIAN"],
		StrangeMoodType.POSSESSED: common_materials,
		StrangeMoodType.MACABRE: ["BONE", "SKULL", "WOOD", "OBSIDIAN"],
		StrangeMoodType.FELL: ["BONE", "SKULL", "IRON", "OBSIDIAN"],
		StrangeMoodType.SECRETIVE: ["WOOD", "COPPER", "IRON", "GRANITE"]
	}
	var type_prefs: Dictionary = {
		StrangeMoodType.FEY: ["weapon", "armor", "instrument", "craft"],
		StrangeMoodType.POSSESSED: art_types,
		StrangeMoodType.MACABRE: ["weapon", "armor", "furniture", "craft"],
		StrangeMoodType.FELL: ["weapon", "armor", "craft"],
		StrangeMoodType.SECRETIVE: ["furniture", "toy", "craft", "instrument"]
	}

	var prefs: Array[String] = []
	var raw_prefs: Variant = mood_mat_prefs.get(strange_mood_type, common_materials)
	for preference_value: Variant in raw_prefs:
		prefs.append(str(preference_value).to_upper())
	var available_materials: Array[String] = []
	for preferred_material: String in prefs:
		if _count_available_mood_material(world, preferred_material) > 0:
			available_materials.append(preferred_material)
	# Un mood no puede exigir algo que el mundo actual no contiene. Si sus
	# preferencias raras no existen, usa materiales comunes realmente presentes.
	if available_materials.is_empty():
		for common_material: String in common_materials:
			if _count_available_mood_material(world, common_material) > 0:
				available_materials.append(common_material)
	available_materials.shuffle()

	var type_pref_list: Array[String] = []
	var raw_type_prefs: Variant = type_prefs.get(strange_mood_type, art_types)
	for type_value: Variant in raw_type_prefs:
		type_pref_list.append(str(type_value))
	strange_mood_artifact_type = type_pref_list[randi() % type_pref_list.size()]
	strange_mood_materials_needed.clear()
	if available_materials.is_empty():
		# En un embarque sin ningún material utilizable, el creador improvisa.
		# Esto mantiene el evento vivo sin congelarlo para siempre.
		strange_mood_artifact_material = _artifact_material_index("WOOD")
		world.messages.append("%s no encontró materiales especiales y decidió improvisar su obra." % name)
	else:
		var material_type_count: int = mini(1 + randi() % 3, available_materials.size())
		for material_index: int in range(material_type_count):
			var material_id: String = available_materials[material_index]
			var available_count: int = _count_available_mood_material(world, material_id)
			var requested_count: int = mini(1 + randi() % 2, available_count)
			if requested_count > 0:
				strange_mood_materials_needed[material_id] = requested_count
		if not strange_mood_materials_needed.is_empty():
			var first_material: String = str(strange_mood_materials_needed.keys()[0])
			strange_mood_artifact_material = _artifact_material_index(first_material)

	var artifact_prefixes: Array[String] = ["Aethel", "Baron", "Crystal", "Dawn", "Ebony", "Frost", "Glimmer", "Iron", "Kings", "Lunar", "Mithril", "Night", "Onyx", "Phoenix", "Quartz", "Royal", "Shadow", "Silver", "Thunder", "Ursa", "Valor", "Wyrm", "Xen", "Zephyr"]
	var artifact_suffixes: Array[String] = ["Heart", "Blade", "Crown", "Dream", "Eye", "Flame", "Gift", "Hammer", "Hope", "Justice", "Key", "Light", "Memory", "Oath", "Peace", "Quest", "Reign", "Shield", "Song", "Star", "Tears", "Union", "Vision", "Wings"]
	strange_mood_artifact_name = "%s %s" % [artifact_prefixes[randi() % artifact_prefixes.size()], artifact_suffixes[randi() % artifact_suffixes.size()]]

func _artifact_material_index(material_id: String) -> int:
	var artifact_materials: Array[String] = ["GRANITE", "LIMESTONE", "IRON", "GOLD", "SILVER", "COPPER", "WOOD", "OBSIDIAN", "MARBLE", "BONE", "STEEL"]
	var found_index: int = artifact_materials.find(material_id.to_upper())
	return found_index if found_index >= 0 else 0

func _mood_material_aliases(material_id: String) -> Array[String]:
	var aliases_by_material: Dictionary = {
		"GRANITE": ["granite", "granito"],
		"LIMESTONE": ["limestone", "caliza", "piedra caliza"],
		"IRON": ["iron", "hierro"],
		"GOLD": ["gold", "oro"],
		"SILVER": ["silver", "plata"],
		"COPPER": ["copper", "cobre"],
		"WOOD": ["wood", "madera", "tronco", "tabla"],
		"OBSIDIAN": ["obsidian", "obsidiana"],
		"MARBLE": ["marble", "mármol", "marmol"],
		"BONE": ["bone", "bones", "hueso", "huesos", "marfil"],
		"SKULL": ["skull", "cráneo", "craneo", "calavera"],
		"STEEL": ["steel", "acero"],
		"STONE": ["stone", "piedra", "granito", "caliza", "mármol", "marmol"]
	}
	var result: Array[String] = []
	var raw_aliases: Variant = aliases_by_material.get(material_id.to_upper(), [material_id.to_lower()])
	for alias_value: Variant in raw_aliases:
		result.append(str(alias_value).to_lower())
	return result

func _mood_material_label(material_id: String) -> String:
	var labels: Dictionary = {
		"GRANITE": "granito", "LIMESTONE": "piedra caliza", "IRON": "hierro",
		"GOLD": "oro", "SILVER": "plata", "COPPER": "cobre", "WOOD": "madera",
		"OBSIDIAN": "obsidiana", "MARBLE": "mármol", "BONE": "huesos",
		"SKULL": "cráneos", "STEEL": "acero", "STONE": "piedra"
	}
	return str(labels.get(material_id.to_upper(), material_id.to_lower()))

func _count_available_mood_material(world, material_id: String) -> int:
	var count: int = 0
	for inventory_value: Variant in inventory:
		if inventory_value is DFItem:
			var inventory_item: DFItem = inventory_value
			if _mood_item_matches(inventory_item, material_id):
				count += maxi(1, inventory_item.stack_size)
	for world_value: Variant in world.entities:
		if not (world_value is DFItem):
			continue
		var world_item: DFItem = world_value
		if _mood_item_matches(world_item, material_id) and _item_available_for_self(world, world_item):
			count += maxi(1, world_item.stack_size)
	return count

func _replace_unavailable_mood_material(world, missing_material: String) -> void:
	var needed_count: int = int(strange_mood_materials_needed.get(missing_material, 0))
	var gathered_count: int = int(strange_mood_materials_gathered.get(missing_material, 0))
	var remaining_count: int = maxi(0, needed_count - gathered_count)
	strange_mood_materials_needed[missing_material] = gathered_count
	var candidates: Array[String] = ["WOOD", "GRANITE", "LIMESTONE", "IRON", "COPPER", "SILVER", "GOLD", "OBSIDIAN", "MARBLE", "BONE", "SKULL"]
	for candidate_material: String in candidates:
		if remaining_count <= 0:
			break
		if candidate_material == missing_material:
			continue
		var available_count: int = _count_available_mood_material(world, candidate_material)
		if available_count <= 0:
			continue
		var allocated_count: int = mini(remaining_count, available_count)
		strange_mood_materials_needed[candidate_material] = int(strange_mood_materials_needed.get(candidate_material, 0)) + allocated_count
		remaining_count -= allocated_count
		world.messages.append("%s sustituyó %s por %s para no abandonar su obra." % [name, _mood_material_label(missing_material), _mood_material_label(candidate_material)])
	if remaining_count > 0:
		world.messages.append("%s improvisó la parte que requería %s; ese recurso no existe en la colonia." % [name, _mood_material_label(missing_material)])
	var target_item: DFItem = _get_world_item_by_id(world, strange_mood_artifact_target_item_id)
	if target_item != null:
		target_item.release_reservation(id)
	strange_mood_artifact_target_item_id = -1
	strange_mood_missing_material = ""
	strange_mood_missing_ticks = 0
	path.clear()
	path_index = 0

func _process_strange_mood(world) -> void:
	if not is_alive:
		mood = MoodState.NORMAL
		return

	if current_job != null:
		_abandon_current_job(world, true, "Abandonó temporalmente su trabajo por un estado de ánimo extraño.")
	if operating_workshop != null:
		_release_operating_workshop(world, true)
	# Una obra maestra no se abandona por un contador que vence mientras el enano
	# camina, reúne materiales o construye su taller. Solo la muerte la interrumpe.
	mood_counter = maxi(mood_counter, 600)

	if mood_counter <= 0:
		var mood_names_desc = {
			StrangeMoodType.FEY: "perdió la inspiración y se siente vacío",
			StrangeMoodType.POSSESSED: "fue liberado del espíritu, pero no logró crear nada",
			StrangeMoodType.MACABRE: "salió de su trance macabro sin completar su obra",
			StrangeMoodType.FELL: "el impulso oscuro se desvaneció, dejándolo agotado",
			StrangeMoodType.SECRETIVE: "salió de su escondite, pero no recuerda lo que quería crear"
		}
		var desc = mood_names_desc.get(strange_mood_type, "falló en crear algo")
		world.messages.append("%s %s." % [name, desc])
		add_thought("Falló en completar su obra. Se siente frustrado.", -0.15)
		stress += 0.2
		mood = MoodState.NORMAL
		strange_mood_phase = StrangeMoodPhase.IDLE
		return

	match strange_mood_phase:
		StrangeMoodPhase.SEEKING_WORKSHOP:
			current_task = "Buscando taller para su obra..."
			_seek_workshop_for_mood(world)

		StrangeMoodPhase.CLAIMED_WORKSHOP:
			current_task = "Reuniendo materiales para su obra maestra"
			_gather_mood_materials(world)

		StrangeMoodPhase.GATHERING_MATERIALS:
			current_task = "Reuniendo materiales para su obra maestra"
			_gather_mood_materials(world)

		StrangeMoodPhase.WORKING:
			current_task = "Trabajando en su obra maestra"
			_work_on_artifact(world)

		StrangeMoodPhase.COMPLETING:
			_complete_strange_mood(world)

func _seek_workshop_for_mood(world) -> void:
	var nearest_workshop = null
	var nearest_dist = 9999
	for w in world.workshops:
		var d = abs(tile_pos.x - w.tile_pos.x) + abs(tile_pos.z - w.tile_pos.z)
		if d < nearest_dist:
			nearest_dist = d
			nearest_workshop = w

	if nearest_workshop != null:
		var dist = abs(tile_pos.x - nearest_workshop.tile_pos.x) + abs(tile_pos.z - nearest_workshop.tile_pos.z)
		if dist <= 1 and tile_pos.y == nearest_workshop.tile_pos.y:
			strange_mood_workshop_pos = nearest_workshop.tile_pos
			strange_mood_workshop_ref = nearest_workshop
			strange_mood_phase = StrangeMoodPhase.CLAIMED_WORKSHOP
			current_task = "Ha reclamado el taller!"
			world.messages.append("%s ha reclamado %s para su obra!" % [name, nearest_workshop.name])
		else:
			current_task = "Yendo al taller"
			_move_toward(world, nearest_workshop.tile_pos)
	else:
		_construct_improvised_workshop(world)

func _construct_improvised_workshop(world) -> void:
	# Elegir una sola ubicación y conservarla durante todo el proyecto.
	if strange_mood_workshop_pos.x < 0 or world.is_water(strange_mood_workshop_pos) or world.is_blocked(strange_mood_workshop_pos):
		strange_mood_workshop_pos = _find_nearby_open_tile(world)
		path.clear()
		path_index = 0
	if strange_mood_workshop_pos.x < 0:
		current_task = "Buscando terreno para su taller"
		return

	# Entregar tres unidades reales de madera/piedra en el lugar del taller.
	if strange_mood_build_materials_delivered < strange_mood_build_materials_needed:
		var carried_material: DFItem = _get_inventory_item_by_id(strange_mood_build_carried_item_id)
		if carried_material == null:
			for inv_value in inventory:
				if inv_value is DFItem:
					var inv_material: DFItem = inv_value
					if inv_material.item_type in ["wood", "stone"]:
						carried_material = inv_material
						strange_mood_build_carried_item_id = inv_material.id
						break

		if carried_material != null:
			var distance_to_site: int = abs(tile_pos.x - strange_mood_workshop_pos.x) + abs(tile_pos.z - strange_mood_workshop_pos.z) + abs(tile_pos.y - strange_mood_workshop_pos.y) * 2
			if distance_to_site > 1:
				current_task = "Llevando material al taller (%d/%d)" % [strange_mood_build_materials_delivered, strange_mood_build_materials_needed]
				_move_toward(world, strange_mood_workshop_pos)
				return
			inventory.erase(carried_material)
			carried_material.release_reservation(id)
			strange_mood_build_carried_item_id = -1
			strange_mood_build_materials_delivered += 1
			current_task = "Entregó material al taller (%d/%d)" % [strange_mood_build_materials_delivered, strange_mood_build_materials_needed]
			needs_display_update = true
			path.clear()
			path_index = 0
			return

		var target_material: DFItem = _get_world_item_by_id(world, strange_mood_build_target_item_id)
		if target_material == null or target_material.item_type not in ["wood", "stone"] or not _item_available_for_self(world, target_material):
			if target_material != null:
				target_material.release_reservation(id)
			target_material = null
			var best_distance: int = 999999
			for world_value in world.entities:
				if not (world_value is DFItem):
					continue
				var candidate: DFItem = world_value
				if candidate.item_type not in ["wood", "stone"] or not _item_available_for_self(world, candidate):
					continue
				var candidate_distance: int = _item_distance(candidate)
				if candidate_distance < best_distance:
					best_distance = candidate_distance
					target_material = candidate
			if target_material != null:
				target_material.reserve_for(id, _get_world_tick(world) + ITEM_RESERVATION_TICKS)
				strange_mood_build_target_item_id = target_material.id
				path.clear()
				path_index = 0

		if target_material == null:
			current_task = "Esperando madera o piedra para construir su taller"
			return

		target_material.reserve_for(id, _get_world_tick(world) + ITEM_RESERVATION_TICKS)
		var distance_to_material: int = _item_distance(target_material)
		if distance_to_material > 1 or target_material.tile_pos.y != tile_pos.y:
			current_task = "Buscando %s para su taller" % target_material.name
			_move_toward(world, target_material.tile_pos)
			return
		if not world.entities.has(target_material):
			target_material.release_reservation(id)
			strange_mood_build_target_item_id = -1
			return
		world.entities.erase(target_material)
		target_material.carried_by_id = id
		target_material.is_in_stockpile = false
		target_material.is_inside_container = false
		target_material.release_reservation(id)
		inventory.append(target_material)
		strange_mood_build_carried_item_id = target_material.id
		strange_mood_build_target_item_id = -1
		current_task = "Recogió %s para construir su taller" % target_material.name
		needs_display_update = true
		path.clear()
		path_index = 0
		return

	var site_distance: int = abs(tile_pos.x - strange_mood_workshop_pos.x) + abs(tile_pos.z - strange_mood_workshop_pos.z) + abs(tile_pos.y - strange_mood_workshop_pos.y) * 2
	if site_distance > 1:
		current_task = "Yendo a construir su taller"
		_move_toward(world, strange_mood_workshop_pos)
		return
	var improvised: DFWorkshop = DFWorkshop.new(DFWorkshop.WorkshopType.CRAFT_SHOP, strange_mood_workshop_pos)
	improvised.name = "Taller improvisado de " + name
	world.workshops.append(improvised)
	strange_mood_workshop_ref = improvised
	strange_mood_phase = StrangeMoodPhase.CLAIMED_WORKSHOP
	current_task = "Terminó su taller improvisado"
	world.messages.append("%s terminó un taller improvisado con materiales reales." % name)

func _find_nearby_open_tile(world) -> Vector3i:
	for radius in range(2, 9):
		for dz in range(-radius, radius + 1):
			for dx in range(-radius, radius + 1):
				if abs(dx) != radius and abs(dz) != radius:
					continue
				var pos: Vector3i = Vector3i(tile_pos.x + dx, tile_pos.y, tile_pos.z + dz)
				if pos.x < 1 or pos.x >= world.width - 1 or pos.z < 1 or pos.z >= world.depth - 1:
					continue
				if world.is_blocked(pos) or world.is_water(pos):
					continue
				var occupied: bool = false
				for building_value in world.buildings:
					if building_value.tile_pos == pos:
						occupied = true
						break
				if occupied:
					continue
				for workshop_value in world.workshops:
					if workshop_value.tile_pos == pos:
						occupied = true
						break
				if not occupied:
					return pos
	return Vector3i(-1, -1, -1)

func _gather_mood_materials(world) -> void:
	if strange_mood_materials_needed.is_empty():
		strange_mood_phase = StrangeMoodPhase.WORKING
		return

	var needed_material: String = ""
	for material_key in strange_mood_materials_needed:
		var needed_count: int = int(strange_mood_materials_needed[material_key])
		var gathered_count: int = int(strange_mood_materials_gathered.get(material_key, 0))
		if gathered_count < needed_count:
			needed_material = str(material_key)
			break
	if needed_material.is_empty():
		strange_mood_phase = StrangeMoodPhase.WORKING
		world.messages.append("%s tiene todos los materiales. ¡Comienza a trabajar!" % name)
		return

	var carried_artifact_material: DFItem = _get_inventory_item_by_id(strange_mood_artifact_carried_item_id)
	if carried_artifact_material == null:
		for inventory_value: Variant in inventory:
			if inventory_value is DFItem:
				var inventory_material: DFItem = inventory_value
				if _mood_item_matches(inventory_material, needed_material):
					carried_artifact_material = inventory_material
					strange_mood_artifact_carried_item_id = inventory_material.id
					break
	if carried_artifact_material != null:
		var workshop_distance: int = abs(tile_pos.x - strange_mood_workshop_pos.x) + abs(tile_pos.z - strange_mood_workshop_pos.z) + abs(tile_pos.y - strange_mood_workshop_pos.y) * 2
		if workshop_distance > 1:
			current_task = "Llevando %s al taller" % carried_artifact_material.name
			_move_toward(world, strange_mood_workshop_pos)
			return
		inventory.erase(carried_artifact_material)
		carried_artifact_material.release_reservation(id)
		strange_mood_artifact_carried_item_id = -1
		strange_mood_materials_gathered[needed_material] = int(strange_mood_materials_gathered.get(needed_material, 0)) + 1
		current_task = "Depositó %s en su taller" % carried_artifact_material.name
		needs_display_update = true
		return

	var target_material: DFItem = _get_world_item_by_id(world, strange_mood_artifact_target_item_id)
	if target_material == null or not _mood_item_matches(target_material, needed_material) or not _item_available_for_self(world, target_material):
		if target_material != null:
			target_material.release_reservation(id)
		target_material = _find_material_on_ground(world, needed_material) as DFItem
		if target_material != null:
			target_material.reserve_for(id, _get_world_tick(world) + ITEM_RESERVATION_TICKS)
			strange_mood_artifact_target_item_id = target_material.id
			path.clear()
			path_index = 0

	if target_material == null:
		if strange_mood_missing_material != needed_material:
			strange_mood_missing_material = needed_material
			strange_mood_missing_ticks = 0
		strange_mood_missing_ticks += 1
		if strange_mood_missing_ticks >= IMPOSSIBLE_RESOURCE_REPLAN_TICKS:
			_replace_unavailable_mood_material(world, needed_material)
			current_task = "Adaptando su obra a los materiales disponibles"
			return
		current_task = "Esperando %s para su obra (%d/%d)" % [_mood_material_label(needed_material), strange_mood_missing_ticks, IMPOSSIBLE_RESOURCE_REPLAN_TICKS]
		return

	strange_mood_missing_material = ""
	strange_mood_missing_ticks = 0
	target_material.reserve_for(id, _get_world_tick(world) + ITEM_RESERVATION_TICKS)
	var target_distance: int = _item_distance(target_material)
	if target_distance > 1 or target_material.tile_pos.y != tile_pos.y:
		current_task = "Buscando %s" % needed_material
		_move_toward(world, target_material.tile_pos)
		return
	if not world.entities.has(target_material):
		target_material.release_reservation(id)
		strange_mood_artifact_target_item_id = -1
		return
	world.entities.erase(target_material)
	target_material.carried_by_id = id
	target_material.is_in_stockpile = false
	target_material.is_inside_container = false
	target_material.release_reservation(id)
	inventory.append(target_material)
	strange_mood_artifact_carried_item_id = target_material.id
	strange_mood_artifact_target_item_id = -1
	current_task = "Recogió %s para su obra" % target_material.name
	needs_display_update = true
	path.clear()
	path_index = 0

func _mood_item_matches(item: DFItem, material_id: String) -> bool:
	if item == null or item.is_decayed:
		return false
	var item_name_lower: String = item.name.to_lower()
	var item_type_lower: String = item.item_type.to_lower()
	var material_name_lower: String = str(_safe_get(item, "material_name", "")).to_lower()
	for alias_name: String in _mood_material_aliases(material_id):
		if alias_name == item_type_lower or alias_name == material_name_lower or alias_name in item_name_lower:
			return true
	return false

func _find_material_on_ground(world, mat_id: String) -> Object:
	var found: DFItem = null
	var best_dist: int = 999999
	for world_value in world.entities:
		if not (world_value is DFItem):
			continue
		var item: DFItem = world_value
		if not _mood_item_matches(item, mat_id) or not _item_available_for_self(world, item):
			continue
		var distance: int = _item_distance(item)
		if distance < best_dist:
			best_dist = distance
			found = item
	return found

func _work_on_artifact(world) -> void:
	if strange_mood_workshop_pos.x >= 0:
		var distance_to_workshop: int = abs(tile_pos.x - strange_mood_workshop_pos.x) + abs(tile_pos.z - strange_mood_workshop_pos.z) + abs(tile_pos.y - strange_mood_workshop_pos.y) * 2
		if distance_to_workshop > 1:
			current_task = "Regresando a su taller para crear la obra"
			_move_toward(world, strange_mood_workshop_pos)
			return
	strange_mood_work_progress += 0.05 + get_skill_level(Skill.CRAFTSMAN) * 0.01
	artistic_inspiration = maxf(0.0, artistic_inspiration - 0.005)
	add_skill_xp(Skill.CRAFTSMAN, 3)

	if randi() % 20 == 0:
		var progress_pct = int(strange_mood_work_progress * 100)
		world.messages.append("%s trabaja incansablemente en '%s'... (%d%%)" % [name, strange_mood_artifact_name, progress_pct])

	if strange_mood_work_progress >= 1.0:
		strange_mood_phase = StrangeMoodPhase.COMPLETING
		current_task = "¡Terminando su obra maestra!"

func _complete_strange_mood(world) -> void:
	var artifact_material_names = ["GRANITE", "LIMESTONE", "IRON", "GOLD", "SILVER", "COPPER", "WOOD", "OBSIDIAN", "MARBLE", "BONE", "STEEL"]
	var mat_name = artifact_material_names[strange_mood_artifact_material % artifact_material_names.size()]

	var artifact_item = DFItem.new(tile_pos, strange_mood_artifact_name, strange_mood_artifact_type, 0, "\u2605", Color("#FF44FF"))
	artifact_item.is_artifact = true
	artifact_item.quality = DFItem.QualityLevel.ARTIFACT
	artifact_item.artifact_name = strange_mood_artifact_name
	artifact_item.artifact_creation_year = world.get("game_year") if world != null and "game_year" in world else 63
	artifact_item.base_value *= 100.0
	artifact_item.total_value = artifact_item.base_value
	artifact_item.artifact_lore = "Creado por %s en el año %d durante un %s. Forjado con %s y materiales nobles, se dice que '%s' posee un poder inexplicable." % [
		name,
		artifact_item.artifact_creation_year,
		_get_strange_mood_name(),
		mat_name.to_lower(),
		strange_mood_artifact_name
	]

	var mood_happiness = {
		StrangeMoodType.FEY: 0.25,
		StrangeMoodType.POSSESSED: 0.2,
		StrangeMoodType.MACABRE: 0.15,
		StrangeMoodType.FELL: 0.1,
		StrangeMoodType.SECRETIVE: 0.2
	}
	var happy_bonus = mood_happiness.get(strange_mood_type, 0.15)

	world.entities.append(artifact_item)
	world.messages.append("¡¡ %s ha creado '%s' !!" % [name, strange_mood_artifact_name])
	add_thought("¡Ha creado el artefacto '%s'! Su nombre será recordado por siempre." % strange_mood_artifact_name, happy_bonus)
	artistic_inspiration = 0.0
	mood = MoodState.NORMAL
	strange_mood_phase = StrangeMoodPhase.IDLE
	stress = 0.0
	happiness = minf(1.0, happiness + happy_bonus)

	if strange_mood_type == StrangeMoodType.FELL:
		world.messages.append("Un escalofrío recorre la fortaleza. El artefacto '%s' tiene un aura oscura..." % strange_mood_artifact_name)

	for e in world.entities:
		if e.get("creature_type") == "dwarf" and e.get("is_alive") == true and e != self:
			e.add_thought("Se maravilla ante la creación de %s: '%s'." % [name, strange_mood_artifact_name], 0.05)

func _get_strange_mood_name() -> String:
	var names = {
		StrangeMoodType.FEY: "éxtasis féerico",
		StrangeMoodType.POSSESSED: "posesión espiritual",
		StrangeMoodType.MACABRE: "trance macabro",
		StrangeMoodType.FELL: "arrebato siniestro",
		StrangeMoodType.SECRETIVE: "inspiración secreta"
	}
	return names.get(strange_mood_type, "mood extraño")

func _execute_hunt_job(world) -> bool:
	if current_job == null:
		return false
	var target_creature_id: int = int(current_job.get_meta("creature_id", -1))
	var target: DFCreature = null
	for world_entry in world.entities:
		if world_entry is DFCreature:
			var creature_entry: DFCreature = world_entry
			if creature_entry.id == target_creature_id and creature_entry.is_alive:
				target = creature_entry
				break
	if target == null:
		hunting_target = null
		current_task = "La presa ya no está disponible"
		return true

	hunting_target = target
	var distance_to_target: int = abs(tile_pos.x - target.tile_pos.x) + abs(tile_pos.z - target.tile_pos.z) + abs(tile_pos.y - target.tile_pos.y) * 2
	if distance_to_target > 1:
		current_task = "Persiguiendo " + target.name
		_move_toward(world, target.tile_pos)
		if current_job != null:
			_set_current_job_state(DFJob.JobState.IN_PROGRESS)
		return false

	current_task = "Atacando " + target.name
	if world.combat_system != null:
		world.combat_system.resolve_attack(self, target, 12.0, Skill.MILITARY_TACTICS, DFCombat.DamageType.SLASH)
	else:
		var target_health_value: Variant = target.get("health")
		if target_health_value != null:
			target.health = maxf(0.0, float(target_health_value) - 0.25)
			if target.health <= 0.0:
				target.is_alive = false
	fatigue_level = minf(1.0, fatigue_level + 0.03)
	fatigue = minf(1.0, fatigue + 0.005)
	needs_display_update = true
	if not target.is_alive or target.health <= 0.0:
		if not bool(target.get_meta("_hunt_products_created", false)):
			target.set_meta("_hunt_products_created", true)
			var meat_count: int = 2 + randi() % 3
			for meat_index: int in range(meat_count):
				var meat_item: DFItem = world._spawn_item(target.tile_pos, "Carne Cruda de " + target.name, "meat", 0, "%", Color("#AA5544"))
				if meat_item != null:
					meat_item.is_meat = true
					meat_item.is_edible = true
			world._spawn_item(target.tile_pos, "Piel de " + target.name, "hide", 0, "[", Color("#8B6A45"))
			world._spawn_item(target.tile_pos, "Huesos de " + target.name, "bone", 0, "=", Color("#DDD8C4"))
			# Las presas medianas o grandes pueden dejar un cráneo utilizable.
			if randi() % 2 == 0:
				world._spawn_item(target.tile_pos, "Cráneo de " + target.name, "skull", 0, "o", Color("#EEE8D5"))
		current_task = "Presa abatida; dejó carne, piel y huesos para recoger"
		return true
	return false

func _execute_fish_job(world) -> bool:
	if current_job == null:
		return false
	var water_position: Vector3i = current_job.tile_pos
	if not world.is_water(water_position):
		_set_current_job_state(DFJob.JobState.CANCELLED)
		current_job.cancel_reason = "El punto de pesca dejó de ser agua."
		current_task = "Punto de pesca inválido"
		return false
	var shore_position: Vector3i = _find_adjacent_land_tile(world, water_position)
	if shore_position.x < 0:
		_set_current_job_state(DFJob.JobState.CANCELLED)
		current_job.cancel_reason = "No existe una orilla transitable junto al punto de pesca."
		current_task = "No encontró una orilla"
		return false
	if tile_pos != shore_position:
		current_task = "Yendo a la orilla para pescar"
		_move_toward(world, shore_position)
		if current_job != null:
			_set_current_job_state(DFJob.JobState.IN_PROGRESS)
		return false

	current_task = "Pescando"
	var fish_skill: int = get_skill_level(Skill.FISHING)
	var catch_chance: float = 0.12 + float(fish_skill) * 0.04
	if randf() >= catch_chance:
		return false
	var fish_variants: Array[String] = ["Trucha", "Salmón", "Carpa", "Perca", "Bagre", "Anguila"]
	if fish_skill >= 4:
		fish_variants.append_array(["Esturión", "Pez Luna"])
	var fish_name: String = fish_variants[randi() % fish_variants.size()]
	var fish_size: int = 1 + (1 if fish_skill >= 2 else 0) + (1 if fish_skill >= 4 else 0)
	for fish_index in range(fish_size):
		var fish_item: DFItem = world._spawn_item(tile_pos, fish_name + " Crudo", "food", 0, "%", Color("#4488CC"))
		if fish_item != null:
			fish_item.nutrition = 0.5 + float(fish_skill) * 0.03
			fish_item.is_edible = true
	stats_tracker["fish_caught"] = stats_tracker.get("fish_caught", 0) + fish_size
	add_thought("Atrapó " + str(fish_size) + " " + fish_name + " fresco(s).", 0.06 + float(fish_skill) * 0.005)
	needs_display_update = true
	return true

func _find_adjacent_land_tile(world, water_pos: Vector3i) -> Vector3i:
	for adjacent_z in range(-1, 2):
		for adjacent_x in range(-1, 2):
			if adjacent_x == 0 and adjacent_z == 0:
				continue
			var world_x: int = water_pos.x + adjacent_x
			var world_z: int = water_pos.z + adjacent_z
			if world_x < 0 or world_x >= world.width or world_z < 0 or world_z >= world.depth:
				continue
			var surface_y: int = world.get_surface_height(world_x, world_z)
			var adjacent_position: Vector3i = Vector3i(world_x, surface_y, world_z)
			if not world.is_water(adjacent_position) and not world.is_blocked(adjacent_position):
				return adjacent_position
	return Vector3i(-1, -1, -1)

func _find_best_item_slot(world, type_filter: String, name_keyword: String = "", max_dist: int = 5) -> Array:
	var best_item = null
	var best_dist = 999999
	var best_source = ""
	var best_inv_idx = -1
	for i in range(inventory.size()):
		var item = inventory[i]
		if item.is_decayed:
			continue
		if item.item_type == type_filter:
			if not name_keyword.is_empty() and not (name_keyword.to_lower() in item.name.to_lower()):
				continue
			if inventory.size() > 1 or (inventory.size() == 1 and not item.is_edible and not item.is_drink):
				best_item = item
				best_dist = 0
				best_source = "inventory"
				best_inv_idx = i
				break
	if best_item == null:
		for e in world.entities:
			if e is DFItem and e.item_type == type_filter:
				if e.is_decayed:
					continue
				if not name_keyword.is_empty() and not (name_keyword.to_lower() in e.name.to_lower()):
					continue
				var d = abs(tile_pos.x - e.tile_pos.x) + abs(tile_pos.z - e.tile_pos.z)
				if d <= max_dist and d < best_dist:
					best_item = e
					best_dist = d
					best_source = "ground"
	if best_source == "ground":
		var to_erase = best_item
		world.entities.erase(to_erase)
		return [true, best_item]
	elif best_source == "inventory":
		var to_remove = best_item
		inventory.remove_at(best_inv_idx)
		return [true, best_item]
	return [false, null]

func _move_to_workshop(world, ws_type: int) -> bool:
	var ws_pos: Vector3i = Vector3i(-1, -1, -1)
	var nearest_dist: int = 30
	if world != null and world.workshops != null:
		for workshop_value: Variant in world.workshops:
			if not workshop_value is DFWorkshop:
				continue
			var workshop: DFWorkshop = workshop_value as DFWorkshop
			if workshop.workshop_type != ws_type:
				continue
			var distance_to_workshop: int = abs(tile_pos.x - workshop.tile_pos.x) + abs(tile_pos.z - workshop.tile_pos.z)
			if distance_to_workshop < nearest_dist:
				nearest_dist = distance_to_workshop
				ws_pos = workshop.tile_pos
	if ws_pos.x >= 0:
		var remaining_distance: int = abs(tile_pos.x - ws_pos.x) + abs(tile_pos.z - ws_pos.z)
		if remaining_distance > 1:
			current_task = "Yendo al taller"
			_move_toward(world, ws_pos)
			return true
	return false

func _execute_cook_job(world) -> bool:
	if _move_to_workshop(world, DFWorkshop.WorkshopType.KITCHEN):
		if current_job != null: _set_current_job_state(DFJob.JobState.IN_PROGRESS)
		return false
	var res = _find_best_item_slot(world, "food", "crudo")
	if not res[0]:
		res = _find_best_item_slot(world, "food")
	if not res[0]:
		return false
	var cook_skill = get_skill_level(Skill.COOKING)
	var nutrition = 0.7 + cook_skill * 0.05
	var meal_name = "Comida Preparada"
	if cook_skill >= 4: meal_name = "Fest?n Delicioso"
	elif cook_skill >= 2: meal_name = "Guiso Sabroso"
	var meal = world._spawn_item(tile_pos, meal_name, "food", 0, "%", Color("#FFAA33"))
	meal.nutrition = minf(1.0, nutrition)
	meal.is_edible = true
	world.entities.erase(meal)
	meal.carried_by_id = id
	inventory.append(meal)
	stats_tracker["food_cooked"] = stats_tracker.get("food_cooked", 0) + 1
	add_thought("Cocin? " + meal_name + " con maestr?a.", 0.08 + cook_skill * 0.01)
	needs_display_update = true
	return true

func _execute_brew_job(world) -> bool:
	if _move_to_workshop(world, DFWorkshop.WorkshopType.STILL):
		if current_job != null: _set_current_job_state(DFJob.JobState.IN_PROGRESS)
		return false
	var res = _find_best_item_slot(world, "food")
	if not res[0]:
		res = _find_best_item_slot(world, "plant")
	if not res[0]:
		return false
	var brew_skill = get_skill_level(Skill.BREWING)
	var drink_names_pool = ["Dwarven Ale", "Cave Wine", "Plump Helmet Wine", "Sweet Pod Rum", "Mushroom Brew"]
	if brew_skill >= 3: drink_names_pool.append_array(["Nectar de Hielo", "Brandy de Cueva"])
	var drink_name = drink_names_pool[randi() % drink_names_pool.size()]
	var drink = world._spawn_item(tile_pos, drink_name, "drink", 0, "~", Color("#FFCC00"))
	drink.nutrition = 0.5 + brew_skill * 0.04
	drink.is_drink = true
	world.entities.erase(drink)
	drink.carried_by_id = id
	inventory.append(drink)
	add_thought("Cervece? " + drink_name + " de primera calidad.", 0.07 + brew_skill * 0.005)
	needs_display_update = true
	return true

func _execute_smelt_job(world) -> bool:
	if _move_to_workshop(world, DFWorkshop.WorkshopType.SMELTER):
		if current_job != null: _set_current_job_state(DFJob.JobState.IN_PROGRESS)
		return false
	var res = _find_best_item_slot(world, "ore")
	if not res[0]:
		return false
	var ore_item = res[1]
	var bar_name = "Barra de Metal"
	var ore_name = ore_item.name.to_lower()
	if "hierro" in ore_name or "iron" in ore_name: bar_name = "Barra de Hierro"
	elif "cobre" in ore_name or "copper" in ore_name: bar_name = "Barra de Cobre"
	elif "oro" in ore_name or "gold" in ore_name: bar_name = "Barra de Oro"
	elif "plata" in ore_name or "silver" in ore_name: bar_name = "Barra de Plata"
	elif "esta" in ore_name or "tin" in ore_name: bar_name = "Barra de Esta?o"
	elif "platino" in ore_name or "platinum" in ore_name: bar_name = "Barra de Platino"
	elif "acero" in ore_name or "steel" in ore_name: bar_name = "Barra de Acero"
	var smelt_skill = get_skill_level(Skill.SMITHING)
	var bar_count = 1 + (1 if smelt_skill >= 3 else 0) + (1 if smelt_skill >= 5 else 0)
	for b_i in range(bar_count):
		var bar = world._spawn_item(tile_pos, bar_name, "bar", 0, "=", Color("#AAAAAA"))
		bar.nutrition = 0.0
		world.entities.erase(bar)
		bar.carried_by_id = id
		inventory.append(bar)
	add_thought("Fundi? " + str(bar_count) + " " + bar_name + "(s).", 0.06)
	needs_display_update = true
	return true

func _execute_make_charcoal_job(world) -> bool:
	if _move_to_workshop(world, DFWorkshop.WorkshopType.KILN):
		if current_job != null: _set_current_job_state(DFJob.JobState.IN_PROGRESS)
		return false
	var res = _find_best_item_slot(world, "wood")
	if not res[0]:
		return false
	var fuel_skill = get_skill_level(Skill.SMITHING)
	var coal_count = 1 + (1 if fuel_skill >= 2 else 0)
	for c_i in range(coal_count):
		var coal = world._spawn_item(tile_pos, "Carb?n Vegetal", "fuel", 0, "@", Color("#333333"))
		coal.is_edible = false
		world.entities.erase(coal)
		coal.carried_by_id = id
		inventory.append(coal)
	add_thought("Produjo " + str(coal_count) + " carb?n(es) vegetal(es).", 0.04)
	needs_display_update = true
	return true

func _execute_process_plant_job(world) -> bool:
	if _move_to_workshop(world, DFWorkshop.WorkshopType.LOOM):
		if current_job != null: _set_current_job_state(DFJob.JobState.IN_PROGRESS)
		return false
	var res = _find_best_item_slot(world, "food")
	if not res[0]:
		res = _find_best_item_slot(world, "plant")
	if not res[0]:
		return false
	var process_skill = get_skill_level(Skill.FARMING)
	var fiber_count = 1 + (1 if process_skill >= 3 else 0)
	for f_i in range(fiber_count):
		var fiber = world._spawn_item(tile_pos, "Fibra Vegetal", "fiber", 0, ",", Color("#88BB44"))
		fiber.nutrition = 0.0
		world.entities.erase(fiber)
		fiber.carried_by_id = id
		inventory.append(fiber)
	add_thought("Proces? plantas en " + str(fiber_count) + " fibra(s).", 0.04)
	needs_display_update = true
	return true

func _execute_spin_thread_job(world) -> bool:
	if _move_to_workshop(world, DFWorkshop.WorkshopType.LOOM):
		if current_job != null: _set_current_job_state(DFJob.JobState.IN_PROGRESS)
		return false
	var res = _find_best_item_slot(world, "fiber", "", 2)
	if not res[0]:
		res = _find_best_item_slot(world, "plant", "", 2)
	if not res[0]:
		return false
	var spin_skill = get_skill_level(Skill.FARMING)
	var thread_count = 1 + (1 if spin_skill >= 2 else 0)
	for t_i in range(thread_count):
		var thread = world._spawn_item(tile_pos, "Hilo de Fibra", "thread", 0, "~", Color("#DDDDAA"))
		world.entities.erase(thread)
		thread.carried_by_id = id
		inventory.append(thread)
	add_thought("Hil? " + str(thread_count) + " hilo(s) de fibra.", 0.04)
	needs_display_update = true
	return true

func _execute_tan_hide_job(world) -> bool:
	if _move_to_workshop(world, DFWorkshop.WorkshopType.TANNER):
		if current_job != null: _set_current_job_state(DFJob.JobState.IN_PROGRESS)
		return false
	var res = _find_best_item_slot(world, "hide")
	if not res[0]:
		res = _find_best_item_slot(world, "corpse")
	if not res[0]:
		return false
	var tan_skill = get_skill_level(Skill.COOKING)
	var leather_count = 1 + (1 if tan_skill >= 3 else 0)
	for l_i in range(leather_count):
		var leather = world._spawn_item(tile_pos, "Cuero Curtido", "leather", 0, "#", Color("#AA7744"))
		world.entities.erase(leather)
		leather.carried_by_id = id
		inventory.append(leather)
	add_thought("Curti? " + str(leather_count) + " cuero(s).", 0.05)
	needs_display_update = true
	return true

func _building_type_to_workshop_type(building_type: int) -> int:
	match building_type:
		DFBuilding.BuildingType.MASONRY: return DFWorkshop.WorkshopType.MASONRY
		DFBuilding.BuildingType.CARPENTRY: return DFWorkshop.WorkshopType.CARPENTRY
		DFBuilding.BuildingType.FORGE: return DFWorkshop.WorkshopType.FORGE
		DFBuilding.BuildingType.SMELTER: return DFWorkshop.WorkshopType.SMELTER
		DFBuilding.BuildingType.KITCHEN: return DFWorkshop.WorkshopType.KITCHEN
		DFBuilding.BuildingType.STILL: return DFWorkshop.WorkshopType.STILL
		DFBuilding.BuildingType.LOOM: return DFWorkshop.WorkshopType.LOOM
		DFBuilding.BuildingType.TANNER: return DFWorkshop.WorkshopType.TANNER
		DFBuilding.BuildingType.CRAFT_SHOP: return DFWorkshop.WorkshopType.CRAFT_SHOP
		DFBuilding.BuildingType.JEWELER: return DFWorkshop.WorkshopType.JEWELER
		_: return DFWorkshop.WorkshopType.CARPENTRY

func _find_unconstructed_workshop_building(world, position: Vector3i) -> DFBuilding:
	for building_value in world.buildings:
		if building_value.tile_pos == position and not building_value.is_constructed:
			return building_value
	return null

func _execute_build_workshop_job(world) -> bool:
	if current_job == null:
		return false
	var job_ref: DFJob = current_job
	var building: DFBuilding = _find_unconstructed_workshop_building(world, job_ref.tile_pos)
	if building == null:
		if world.get_workshop_at(job_ref.tile_pos) != null:
			return true
		job_ref.cancel_reason = "El proyecto de taller ya no existe."
		_set_current_job_state(DFJob.JobState.CANCELLED)
		return false

	var materials_required: int = 3
	var required_material_type: String = str(job_ref.get_meta("required_material_type", ""))
	var allowed_material_types: Array[String] = ["wood", "stone"]
	if not required_material_type.is_empty():
		allowed_material_types = [required_material_type]
	var delivered: int = int(job_ref.get_meta("materials_delivered", 0))
	if delivered < materials_required:
		var carried_material: DFItem = null
		var carried_id: int = int(job_ref.get_meta("carried_item_id", -1))
		carried_material = _get_inventory_item_by_id(carried_id)
		if carried_material == null:
			for inventory_value in inventory:
				if inventory_value is DFItem:
					var inventory_material: DFItem = inventory_value
					if inventory_material.item_type in allowed_material_types:
						carried_material = inventory_material
						job_ref.set_meta("carried_item_id", inventory_material.id)
						break

		if carried_material != null:
			var site_distance: int = abs(tile_pos.x - job_ref.tile_pos.x) + abs(tile_pos.z - job_ref.tile_pos.z) + abs(tile_pos.y - job_ref.tile_pos.y) * 2
			if site_distance > 1:
				current_task = "Llevando material al taller (%d/%d)" % [delivered, materials_required]
				_move_toward(world, job_ref.tile_pos)
				_set_current_job_state(DFJob.JobState.IN_PROGRESS)
				return false
			if carried_material.stack_size > 1:
				carried_material.stack_size -= 1
				job_ref.set_meta("carried_item_id", carried_material.id)
			else:
				inventory.erase(carried_material)
				carried_material.release_reservation(id)
				job_ref.set_meta("carried_item_id", -1)
			delivered += 1
			job_ref.set_meta("materials_delivered", delivered)
			task_progress = 0.0
			current_task = "Entregó material al taller (%d/%d)" % [delivered, materials_required]
			needs_display_update = true
			return false

		var target_material_id: int = int(job_ref.get_meta("material_item_id", -1))
		var target_material: DFItem = _get_world_item_by_id(world, target_material_id)
		if target_material == null or target_material.item_type not in allowed_material_types or not _item_available_for_self(world, target_material):
			if target_material != null:
				target_material.release_reservation(id)
			target_material = null
			var best_distance: int = 999999
			for world_value in world.entities:
				if not (world_value is DFItem):
					continue
				var candidate: DFItem = world_value
				if candidate.item_type not in allowed_material_types or not _item_available_for_self(world, candidate):
					continue
				var candidate_distance: int = _item_distance(candidate)
				if candidate_distance < best_distance:
					best_distance = candidate_distance
					target_material = candidate
			if target_material != null:
				target_material.reserve_for(id, _get_world_tick(world) + ITEM_RESERVATION_TICKS)
				job_ref.set_meta("material_item_id", target_material.id)
				path.clear()
				path_index = 0

		if target_material == null:
			current_task = "Esperando %s para el taller" % (required_material_type if not required_material_type.is_empty() else "madera o piedra")
			_set_current_job_state(DFJob.JobState.IN_PROGRESS)
			return false

		target_material.reserve_for(id, _get_world_tick(world) + ITEM_RESERVATION_TICKS)
		var material_distance: int = _item_distance(target_material)
		if material_distance > 1 or target_material.tile_pos.y != tile_pos.y:
			current_task = "Yendo a recoger material para el taller"
			_move_toward(world, target_material.tile_pos)
			_set_current_job_state(DFJob.JobState.IN_PROGRESS)
			return false
		if not world.entities.has(target_material):
			target_material.release_reservation(id)
			job_ref.set_meta("material_item_id", -1)
			return false
		world.entities.erase(target_material)
		target_material.carried_by_id = id
		target_material.is_in_stockpile = false
		target_material.is_inside_container = false
		target_material.release_reservation(id)
		inventory.append(target_material)
		job_ref.set_meta("material_item_id", -1)
		job_ref.set_meta("carried_item_id", target_material.id)
		current_task = "Llevando %s al taller" % target_material.name
		needs_display_update = true
		path.clear()
		path_index = 0
		return false

	var build_distance: int = abs(tile_pos.x - job_ref.tile_pos.x) + abs(tile_pos.z - job_ref.tile_pos.z) + abs(tile_pos.y - job_ref.tile_pos.y) * 2
	if build_distance > 1:
		current_task = "Yendo a construir el taller"
		_move_toward(world, job_ref.tile_pos)
		_set_current_job_state(DFJob.JobState.IN_PROGRESS)
		return false
	task_progress += 0.08 + float(get_skill_level(Skill.CARPENTRY)) * 0.02
	current_task = "Construyendo taller (%d%%)" % mini(100, int(task_progress * 100.0))
	_set_current_job_state(DFJob.JobState.IN_PROGRESS)
	if task_progress < 1.0:
		return false
	building.is_constructed = true
	var workshop_type: int = _building_type_to_workshop_type(building.type)
	world.create_workshop(workshop_type, building.tile_pos)
	world.messages.append("%s terminó %s y ya puede producir objetos." % [name, building.name])
	return true

func _execute_haul_item_job(world) -> bool:
	if current_job == null:
		return false
	var job_ref: DFJob = current_job
	var carried_item_id: int = int(job_ref.get_meta("carried_item_id", -1))
	var carried_item: DFItem = _get_inventory_item_by_id(carried_item_id)
	var drop_value: Variant = job_ref.get_meta("drop_position", Vector3i(-1, -1, -1))
	var drop_position: Vector3i = drop_value if drop_value is Vector3i else Vector3i(-1, -1, -1)

	if carried_item != null:
		if drop_position.y < 0:
			carried_item.tile_pos = tile_pos
			carried_item.carried_by_id = -1
			carried_item.release_reservation(id)
			inventory.erase(carried_item)
			world.entities.append(carried_item)
			job_ref.cancel_reason = "El transporte perdió su destino."
			_set_current_job_state(DFJob.JobState.CANCELLED)
			return false
		var destination_distance: int = (
			abs(tile_pos.x - drop_position.x)
			+ abs(tile_pos.z - drop_position.z)
			+ abs(tile_pos.y - drop_position.y) * 2
		)
		if destination_distance > 1:
			current_task = "Llevando %s a su destino" % carried_item.name
			_move_toward(world, drop_position)
			_set_current_job_state(DFJob.JobState.IN_PROGRESS)
			return false
		inventory.erase(carried_item)
		carried_item.tile_pos = drop_position
		carried_item.carried_by_id = -1
		carried_item.is_in_stockpile = false
		carried_item.is_inside_container = false
		carried_item.release_reservation(id)
		if bool(job_ref.get_meta("mark_as_bed", false)):
			carried_item.is_bed = true
		world.entities.append(carried_item)
		job_ref.set_meta("carried_item_id", -1)
		current_task = "Entregó " + carried_item.name
		needs_display_update = true
		return true

	var target_item_id: int = int(job_ref.get_meta("target_item_id", -1))
	var target_item: DFItem = _get_world_item_by_id(world, target_item_id)
	if target_item == null:
		# El objeto puede haber sido transportado por otro trabajo; cerrar esta tarea
		# en vez de dejarla eternamente en progreso.
		return true
	if not _item_available_for_self(world, target_item):
		current_task = "Esperando acceso a " + target_item.name
		_set_current_job_state(DFJob.JobState.IN_PROGRESS)
		return false
	target_item.reserve_for(id, _get_world_tick(world) + ITEM_RESERVATION_TICKS)
	var target_distance: int = _item_distance(target_item)
	if target_distance > 1 or target_item.tile_pos.y != tile_pos.y:
		current_task = "Yendo a recoger " + target_item.name
		_move_toward(world, target_item.tile_pos)
		_set_current_job_state(DFJob.JobState.IN_PROGRESS)
		return false
	if not world.entities.has(target_item):
		target_item.release_reservation(id)
		return false
	world.entities.erase(target_item)
	target_item.carried_by_id = id
	target_item.is_in_stockpile = false
	target_item.is_inside_container = false
	target_item.release_reservation(id)
	inventory.append(target_item)
	job_ref.set_meta("carried_item_id", target_item.id)
	current_task = "Llevando " + target_item.name
	needs_display_update = true
	path.clear()
	path_index = 0
	return false

func _execute_store_in_container_job(world) -> bool:
	if current_job == null:
		return false
	var job_ref: DFJob = current_job
	var valid_food_types: Array[String] = ["food", "drink", "meat", "fish"]

	# FASE 2: el objeto ya está en el inventario. El destino fue elegido antes
	# de recogerlo y se conserva durante todo el trayecto.
	var carried_food_id: int = int(job_ref.get_meta("carried_item_id", -1))
	var carried_food: DFItem = _get_inventory_item_by_id(carried_food_id)
	if carried_food != null:
		if carried_food.item_type not in valid_food_types:
			_drop_active_job_carried_item(world)
			job_ref.cancel_reason = "El objeto transportado ya no era una provisión válida."
			_set_current_job_state(DFJob.JobState.CANCELLED)
			return false

		var saved_drop_value: Variant = job_ref.get_meta("drop_position", Vector3i(-1, -1, -1))
		var store_position: Vector3i = saved_drop_value if saved_drop_value is Vector3i else Vector3i(-1, -1, -1)
		if store_position.y < 0:
			store_position = _find_free_stockpile_tile(world, carried_food.item_type)
			if store_position.y >= 0:
				job_ref.set_meta("drop_position", store_position)

		if store_position.y < 0:
			carried_food.set_meta("storage_blocked_until", _get_world_tick(world) + 600)
			_drop_active_job_carried_item(world)
			current_task = "No hay almacén accesible"
			return true

		var distance_to_store: int = (
			abs(tile_pos.x - store_position.x)
			+ abs(tile_pos.z - store_position.z)
			+ abs(tile_pos.y - store_position.y) * 2
		)
		if distance_to_store > 1:
			current_task = "Llevando %s al almacén" % carried_food.name
			_move_toward(world, store_position)
			_set_current_job_state(DFJob.JobState.IN_PROGRESS)
			return false

		inventory.erase(carried_food)
		carried_food.tile_pos = store_position
		carried_food.carried_by_id = -1
		carried_food.is_in_stockpile = true
		carried_food.is_inside_container = _is_food_store_tile(world, store_position)
		carried_food.release_reservation(id)
		carried_food.set_meta("storage_blocked_until", 0)
		if not world.entities.has(carried_food):
			world.entities.append(carried_food)
		job_ref.set_meta("carried_item_id", -1)
		job_ref.set_meta("drop_position", Vector3i(-1, -1, -1))
		add_thought("Guardó %s en el almacén." % carried_food.name, 0.04)
		current_task = "Almacenó " + carried_food.name
		needs_display_update = true
		return true

	# FASE 1: cada trabajo pertenece a una provisión concreta. Si esa provisión
	# desapareció, fue consumida o ya fue guardada por otro aldeano, el trabajo
	# termina como obsoleto en vez de adoptar otro objetivo y entrar en un loop.
	var target_food_id: int = int(job_ref.get_meta("target_item_id", -1))
	if target_food_id < 0:
		current_task = "La provisión objetivo ya no existe"
		return true
	var target_food: DFItem = _get_world_item_by_id(world, target_food_id)
	if target_food == null:
		current_task = "La provisión ya fue retirada"
		return true
	if (
		target_food.item_type not in valid_food_types
		or target_food.is_inside_container
		or target_food.is_in_stockpile
		or target_food.is_decayed
	):
		target_food.release_reservation(id)
		return true

	if not _item_available_for_self(world, target_food):
		var wait_ticks: int = int(job_ref.get_meta("reservation_wait_ticks", 0)) + 1
		job_ref.set_meta("reservation_wait_ticks", wait_ticks)
		current_task = "Esperando acceso a " + target_food.name
		if wait_ticks > ITEM_RESERVATION_TICKS:
			return true
		_set_current_job_state(DFJob.JobState.IN_PROGRESS)
		return false
	job_ref.set_meta("reservation_wait_ticks", 0)
	target_food.reserve_for(id, _get_world_tick(world) + ITEM_RESERVATION_TICKS)

	var planned_drop_value: Variant = job_ref.get_meta("drop_position", Vector3i(-1, -1, -1))
	var planned_drop: Vector3i = planned_drop_value if planned_drop_value is Vector3i else Vector3i(-1, -1, -1)
	if planned_drop.y < 0:
		planned_drop = _find_free_stockpile_tile(world, target_food.item_type)
		if planned_drop.y < 0:
			target_food.set_meta("storage_blocked_until", _get_world_tick(world) + 600)
			target_food.release_reservation(id)
			current_task = "No hay almacén accesible"
			return true
		job_ref.set_meta("drop_position", planned_drop)

	var distance_to_food: int = _item_distance(target_food)
	if distance_to_food > 1 or target_food.tile_pos.y != tile_pos.y:
		current_task = "Yendo a recoger " + target_food.name
		_move_toward(world, target_food.tile_pos)
		_set_current_job_state(DFJob.JobState.IN_PROGRESS)
		return false
	if not world.entities.has(target_food):
		target_food.release_reservation(id)
		return true

	world.entities.erase(target_food)
	target_food.carried_by_id = id
	target_food.is_inside_container = false
	target_food.is_in_stockpile = false
	target_food.release_reservation(id)
	inventory.append(target_food)
	job_ref.set_meta("target_item_id", -1)
	job_ref.set_meta("carried_item_id", target_food.id)
	current_task = "Llevando %s al almacén" % target_food.name
	needs_display_update = true
	path.clear()
	path_index = 0
	return false

func _execute_collect_job(world, item_type_to_collect: String) -> bool:
	var carried_item: DFItem = null
	for candidate in inventory:
		if candidate is DFItem and candidate.item_type == item_type_to_collect:
			var inventory_item: DFItem = candidate
			if inventory_item.carried_by_id in [-1, id]:
				carried_item = inventory_item
				break

	# 1. Reservar y recoger una unidad suelta.
	if carried_item == null:
		var target_item: DFItem = null
		var target_id: int = -1
		if current_job != null:
			target_id = int(current_job.get_meta("target_item_id", -1))
		target_item = _get_world_item_by_id(world, target_id)

		if target_item == null or target_item.item_type != item_type_to_collect or not _item_available_for_self(world, target_item):
			if target_item != null:
				target_item.release_reservation(id)
			target_item = null
			var best_distance: int = 999999
			for entity in world.entities:
				if not (entity is DFItem):
					continue
				var loose_item: DFItem = entity
				if loose_item.item_type != item_type_to_collect or loose_item.is_inside_container or loose_item.is_in_stockpile:
					continue
				if not _item_available_for_self(world, loose_item):
					continue
				var distance: int = _item_distance(loose_item)
				if distance < best_distance:
					best_distance = distance
					target_item = loose_item
			if target_item == null:
				if current_job != null:
					_set_current_job_state(DFJob.JobState.CANCELLED)
				current_task = "idle"
				return false
			target_item.reserve_for(id, _get_world_tick(world) + ITEM_RESERVATION_TICKS)
			if current_job != null:
				current_job.set_meta("target_item_id", target_item.id)
			path.clear()
			path_index = 0

		target_item.reserve_for(id, _get_world_tick(world) + ITEM_RESERVATION_TICKS)
		var distance_to_item: int = _item_distance(target_item)
		if distance_to_item > 1 or target_item.tile_pos.y != tile_pos.y:
			current_task = "Yendo a recoger " + target_item.name
			_move_toward(world, target_item.tile_pos)
			if current_job != null:
				_set_current_job_state(DFJob.JobState.IN_PROGRESS)
			return false

		if not world.entities.has(target_item):
			target_item.release_reservation(id)
			if current_job != null:
				current_job.set_meta("target_item_id", -1)
			return false

		var planned_drop: Vector3i = _find_free_stockpile_tile(world, item_type_to_collect)
		var planned_exterior_drop: bool = false
		if planned_drop.y < 0 and item_type_to_collect == "wood":
			planned_drop = _find_house_exterior_storage_pos(world)
			planned_exterior_drop = planned_drop.y >= 0
		if planned_drop.y < 0:
			target_item.release_reservation(id)
			if current_job != null:
				current_job.set_meta("target_item_id", -1)
				_set_current_job_state(DFJob.JobState.CANCELLED)
			current_task = "No hay almacén accesible"
			return false

		world.entities.erase(target_item)
		target_item.carried_by_id = id
		target_item.is_in_stockpile = false
		target_item.is_inside_container = false
		target_item.release_reservation(id)
		inventory.append(target_item)
		if current_job != null:
			current_job.set_meta("target_item_id", -1)
			current_job.set_meta("drop_position", planned_drop)
			current_job.set_meta("exterior_drop", planned_exterior_drop)
		current_task = "Llevando " + target_item.name + " al almacén"
		needs_display_update = true
		path.clear()
		path_index = 0
		return false

	# 2. Depositar la unidad transportada usando el destino reservado al recogerla.
	var target_drop_position: Vector3i = Vector3i(-1, -1, -1)
	var exterior_drop: bool = false
	if current_job != null:
		var saved_drop_value: Variant = current_job.get_meta(
			"drop_position", Vector3i(-1, -1, -1)
		)
		if saved_drop_value is Vector3i:
			target_drop_position = saved_drop_value
		exterior_drop = bool(current_job.get_meta("exterior_drop", false))
	if target_drop_position.y < 0:
		target_drop_position = _find_free_stockpile_tile(world, item_type_to_collect)
		if target_drop_position.y < 0 and item_type_to_collect == "wood":
			target_drop_position = _find_house_exterior_storage_pos(world)
			exterior_drop = target_drop_position.y >= 0
		if current_job != null and target_drop_position.y >= 0:
			current_job.set_meta("drop_position", target_drop_position)
			current_job.set_meta("exterior_drop", exterior_drop)

	if target_drop_position.y < 0:
		carried_item.tile_pos = tile_pos
		carried_item.carried_by_id = -1
		carried_item.release_reservation(id)
		inventory.erase(carried_item)
		world.entities.append(carried_item)
		current_task = "idle"
		return true

	var distance_to_drop: int = abs(tile_pos.x - target_drop_position.x) + abs(tile_pos.z - target_drop_position.z) + abs(tile_pos.y - target_drop_position.y) * 2
	if distance_to_drop > 1:
		current_task = "Llevando " + carried_item.name + (" al exterior" if exterior_drop else " al almacén")
		_move_toward(world, target_drop_position)
		if current_job != null:
			_set_current_job_state(DFJob.JobState.IN_PROGRESS)
		return false

	carried_item.tile_pos = target_drop_position
	carried_item.carried_by_id = -1
	carried_item.is_in_stockpile = not exterior_drop
	carried_item.is_inside_container = not exterior_drop and _is_food_store_tile(world, target_drop_position) and carried_item.item_type in ["food", "drink", "meat", "fish"]
	carried_item.release_reservation(id)
	inventory.erase(carried_item)
	world.entities.append(carried_item)
	if current_job != null:
		current_job.set_meta("drop_position", Vector3i(-1, -1, -1))
		current_job.set_meta("exterior_drop", false)
	current_task = "idle"
	needs_display_update = true
	return true

func _is_food_store_tile(world, position: Vector3i) -> bool:
	for building_value in world.buildings:
		if not (building_value is DFBuilding):
			continue
		var building: DFBuilding = building_value
		if building.tile_pos == position and building.type == DFBuilding.BuildingType.FOOD_STORE:
			return true
	return false

func _find_house_exterior_storage_pos(world) -> Vector3i:
	# Recopilar todas las posiciones de puertas
	var door_positions = []
	for ent in world.entities:
		if ent is DFItem and ent.item_type == "door":
			door_positions.append(ent.tile_pos)

	var best_pos = Vector3i(-1, -1, -1)
	var best_dist = 999999

	for b in world.buildings:
		if b.type == DFBuilding.BuildingType.BEDROOM:
			var bpos = b.tile_pos
			# Buscar en un radio de 4 celdas alrededor del dormitorio
			for dx in range(-4, 5):
				for dz in range(-4, 5):
					if dx == 0 and dz == 0:
						continue
					var p = bpos + Vector3i(dx, 0, dz)
					if p.x < 1 or p.x >= world.width - 1 or p.z < 1 or p.z >= world.depth - 1:
						continue
					
					# Debe ser transitable y no bloqueado
					if world.is_blocked(p):
						continue
					
					# Debe ser adyacente a un muro construido
					var near_wall = false
					for ndx in [-1, 0, 1]:
						for ndz in [-1, 0, 1]:
							if ndx == 0 and ndz == 0:
								continue
							var np = p + Vector3i(ndx, 0, ndz)
							if world.is_wall(np):
								near_wall = true
								break
						if near_wall:
							break
					
					if not near_wall:
						continue
					
					# No debe ser un piso construido (dentro de la casa)
					if world.get_tile(p) == DFWorld.TileType.CONSTRUCTED_FLOOR:
						continue
						
					# No debe obstruir ninguna entrada (distancia > 1 de cualquier puerta)
					var blocks_door = false
					for dp in door_positions:
						if abs(p.x - dp.x) <= 1 and abs(p.z - dp.z) <= 1:
							blocks_door = true
							break
					if blocks_door:
						continue
						
					# No debe tener ya un objeto tirado en esa posición
					var has_item = false
					for ent_check in world.entities:
						if ent_check is DFItem and ent_check.tile_pos == p:
							has_item = true
							break
					if has_item:
						continue
						
					# Elegir la posición más cercana al enano
					var d = abs(p.x - tile_pos.x) + abs(p.z - tile_pos.z)
					if d < best_dist:
						best_dist = d
						best_pos = p

	return best_pos

func _tick_hunting_behavior(world) -> bool:
	if profession != Profession.HUNTER:
		return false
		
	# 1. Si tenemos carne cruda en el inventario, nuestro objetivo prioritario es cocinarla
	var has_raw_meat = false
	var raw_meat_item = null
	for item1 in inventory:
		if item1 is DFItem and item1.item_type == "food" and "Carne Cruda" in item1.name:
			has_raw_meat = true
			raw_meat_item = item1
			break
			
	if has_raw_meat:
		# Buscamos si ya hay una fogata construida en la zona
		var campfire = null
		for bld in world.buildings:
			if bld.type == 19: # 19 = BuildingType.CAMPFIRE
				campfire = bld
				break
				
		if campfire != null:
			var d_camp = abs(tile_pos.x - campfire.tile_pos.x) + abs(tile_pos.z - campfire.tile_pos.z)
			if d_camp > 1:
				current_task = "Yendo a cocinar carne"
				_move_toward(world, campfire.tile_pos)
				return true
			else:
				# Cocinar la carne
				inventory.erase(raw_meat_item)
				# Generar carne cocinada
				var cooked_name = "Carne Cocinada Caliente"
				var cooked_item = world._spawn_item(tile_pos, cooked_name, "food", 0, "%", Color("#FF5500"))
				cooked_item.nutrition = 0.9
				cooked_item.is_edible = true
				add_thought("Cociné carne fresca de caza en la fogata.", 0.25)
				current_task = "Cocinando"
				needs_display_update = true
				return true
		else:
			# Si no hay fogata, necesitamos leña (wood) para hacer una
			var has_wood = false
			var wood_item = null
			for item2 in inventory:
				if item2.item_type == "wood":
					has_wood = true
					wood_item = item2
					break
			if has_wood:
				# Ir al centro de la colonia a crear la fogata
				var plaza_center: Vector3i = world.get_meta("settlement_center", Vector3i(128, tile_pos.y, 128))
				var plaza_pos = Vector3i(plaza_center.x, world.get_surface_height(plaza_center.x, plaza_center.z), plaza_center.z)
				var d_plaza = abs(tile_pos.x - plaza_pos.x) + abs(tile_pos.z - plaza_pos.z)
				if d_plaza > 2:
					current_task = "Yendo a la plaza a cocinar"
					_move_toward(world, plaza_pos)
					return true
				else:
					# Crear fogata
					var camp_bld = DFBuilding.new(19, tile_pos) # 19 = CAMPFIRE
					world.buildings.append(camp_bld)
					inventory.erase(wood_item)
					inventory.erase(raw_meat_item)
					var cooked_item_plaza = world._spawn_item(tile_pos, "Carne Cocinada Caliente", "food", 0, "%", Color("#FF5500"))
					cooked_item_plaza.nutrition = 0.9
					cooked_item_plaza.is_edible = true
					add_thought("Encendí una fogata y cociné carne de caza.", 0.25)
					current_task = "Cocinando"
					needs_display_update = true
					return true
			else:
				# Buscar leña en el suelo
				var target_fuel = _find_nearest_item_matching_type(world, "wood")
				if target_fuel != null:
					current_task = "Buscando leña para cocinar"
					var d_fuel = abs(tile_pos.x - target_fuel.tile_pos.x) + abs(tile_pos.z - target_fuel.tile_pos.z)
					if d_fuel <= 1:
						inventory.append(target_fuel)
						world.entities.erase(target_fuel)
					else:
						_move_toward(world, target_fuel.tile_pos)
					return true
				else:
					# Si no hay leña en ningún lado, depositarla en el exterior de casas
					var ext_storage = _find_house_exterior_storage_pos(world)
					if ext_storage != Vector3i(-1, -1, -1):
						var d_ext = abs(tile_pos.x - ext_storage.x) + abs(tile_pos.z - ext_storage.z)
						if d_ext <= 1:
							raw_meat_item.tile_pos = ext_storage
							world.entities.append(raw_meat_item)
							inventory.erase(raw_meat_item)
							current_task = "idle"
						else:
							current_task = "Llevando carne cruda"
							_move_toward(world, ext_storage)
						return true

	# 2. Si no tenemos carne cruda, buscar presa
	# Validar target actual
	if hunting_target != null:
		var target_exists = false
		for ent1 in world.entities:
			if ent1 == hunting_target:
				target_exists = true
				break
		if not target_exists or not hunting_target.get("is_alive"):
			# El target murió o desapareció, buscar si dejó un cadáver en su lugar para degollarlo
			if hunting_target != null:
				var corpse_found = null
				for ent2 in world.entities:
					if ent2 is DFItem and ent2.item_type == "corpse" and ent2.tile_pos == hunting_target.tile_pos:
						corpse_found = ent2
						break
				if corpse_found != null:
					# Ir a degollar el cadáver
					var d_corp = abs(tile_pos.x - corpse_found.tile_pos.x) + abs(tile_pos.z - corpse_found.tile_pos.z)
					if d_corp > 1:
						current_task = "Yendo a degollar presa"
						_move_toward(world, corpse_found.tile_pos)
						return true
					else:
						# Degollar (quitar carne)
						var c_name = hunting_target.name
						world.entities.erase(corpse_found)
						var raw_meat = world._spawn_item(tile_pos, "Carne Cruda de " + c_name, "food", 0, "%", Color("#FF5533"))
						raw_meat.nutrition = 0.5
						raw_meat.is_edible = true
						world.entities.erase(raw_meat)
						raw_meat.carried_by_id = id
						inventory.append(raw_meat)
						add_thought("Cacé y degollé a " + c_name + " para obtener carne cruda.", 0.15)
						current_task = "Cazando"
						hunting_target = null
						needs_display_update = true
						return true
			hunting_target = null

	if hunting_target == null:
		# Buscar criatura viva más cercana (rango 30)
		var best_prey = null
		var best_d = 99999
		for ent3 in world.entities:
			var c_type = ent3.get("creature_type")
			var alive = ent3.get("is_alive")
			if ent3 != self and c_type != null and c_type != "dwarf" and c_type != "" and alive == true:
				var d_prey = abs(ent3.tile_pos.x - tile_pos.x) + abs(ent3.tile_pos.z - tile_pos.z)
				if d_prey < best_d and d_prey <= 30:
					best_d = d_prey
					best_prey = ent3
		if best_prey != null:
			hunting_target = best_prey

	# 3. Perseguir e ir a cazar
	if hunting_target != null:
		var dist_to_target = abs(tile_pos.x - hunting_target.tile_pos.x) + abs(tile_pos.z - hunting_target.tile_pos.z)
		if dist_to_target > 1:
			current_task = "Persiguiendo " + hunting_target.name
			_move_toward(world, hunting_target.tile_pos)
			return true
		else:
			# Atacar!
			current_task = "Atacando " + hunting_target.name
			if world.combat_system != null:
				var res = world.combat_system.resolve_attack(self, hunting_target, 12.0, Skill.MILITARY_TACTICS, DFCombat.DamageType.SLASH)
				# Incrementar fatiga del cazador
				fatigue_level = minf(1.0, fatigue_level + 0.03)
				fatigue = minf(1.0, fatigue + 0.005)
				needs_display_update = true
			else:
				# Fallback por si acaso
				hunting_target.health = maxf(0.0, hunting_target.health - 0.25)
				if hunting_target.health <= 0.0:
					hunting_target.is_alive = false
			return true
			
	return false
