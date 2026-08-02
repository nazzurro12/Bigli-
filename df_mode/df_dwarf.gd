extends RefCounted
class_name DFDwarf

# Carga diferida para romper dependencia circular con df_job.gd
const DFActorActionExecutor = preload("res://core/actions/df_actor_action_executor.gd")
const DFAutonomousPlan = preload("res://core/ai/df_autonomous_plan.gd")

# Reparte únicamente los cálculos de rutas nuevas. Una ruta ya calculada continúa
# moviéndose cada tick, por lo que esto reduce picos sin robotizar el movimiento.
const PATH_REQUEST_BUCKETS: int = 4

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
# Indica si el habitante fue materializado desde un asentamiento del mapa mundial.
# Los habitantes normales de la colonia conservan el valor false.
var is_world_settlement_resident: bool = false
var is_possessed: bool = false
var body: Object = null
var name: String = "Urist"
var tile_pos: Vector3i
var id: int
static var _id_counter: int = 1
static var _static_namegen = null

var hunger: float = 0.0
var thirst: float = 0.0
var fatigue: float = 0.0
var happiness: float = 0.8
var health: float = 1.0
var inventory: Array = []
var thoughts: Array = []
var minutes_since_alcohol: int = 0
var simulation_minute: int = 0

var skills: Dictionary = {}
var current_task: String = "idle"
var task_progress: float = 0.0
var task_target: Vector3i = Vector3i(-1, -1, -1)
var current_job = null

# ---- AUTONOMÍA PERSISTENTE ----
var autonomous_goal: String = ""
var autonomous_reason: String = ""
var autonomous_plan: Dictionary = {}
var autonomous_plan_history: Array = []
var autonomous_plan_cooldown: int = 0
var autonomous_target: Vector3i = Vector3i(-1, -1, -1)
var hunting_target = null
var is_alive: bool = true
var gender: String = "Male"
var age: int = 20
var birth_year: int = 43
var caste: String = "dwarf"

var path: Array = []
var path_index: int = 0
var last_pos: Vector3i = Vector3i(-1, -1, -1)
var stuck_counter: int = 0
var path_replan_count: int = 0
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
var crisis_pressure: float = 0.0
var last_crisis_evaluation_minute: int = -1
var crisis_reason: String = ""
var berserk_bonus_applied: bool = false
const CRISIS_GRACE_MINUTES: int = 1440
const CRISIS_PRESSURE_REQUIRED: float = 360.0

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
var room_quality: float = 0.0

var social_timer: float = 0.0
var last_social_interaction: int = 0
var loneliness: float = 0.0
var social_beliefs: Array = []
var social_reputation: Dictionary = {}
var last_belief_decay_day: int = -1
var conversations_held: int = 0
const MAX_SOCIAL_BELIEFS: int = 24
const BELIEF_FORGET_DAYS: int = 30

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
enum DiseasePhase { HEALTHY, INCUBATING, SYMPTOMATIC, RECOVERING }
var disease_phase: int = DiseasePhase.HEALTHY
var disease_progress: float = 0.0
var disease_severity: float = 0.0
var pathogen_exposure: float = 0.0
var immune_strength: float = 0.5
var acquired_immunity: float = 0.0
var recovery_streak: int = 0
var fever: float = 0.0

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
var meals_today: int = 0
var water_liters_today: float = 0.0
var daily_protein: float = 0.0
var daily_carbohydrates: float = 0.0
var daily_fat: float = 0.0
var daily_fiber: float = 0.0
var daily_micronutrients: float = 0.0
var nutrition_quality: float = 0.75
var bladder_fill: float = 0.0
var bowel_fill: float = 0.0
var physical_condition: float = 0.5
var education_level: float = 0.0
var chronic_health: float = 1.0
var last_physiology_day: int = -1
var physiology_status: String = "Estable"

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
	education_level = minf(1.0, education_level + float(maxi(0, amount)) * 0.0005)
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
	_learn_social_belief(category, id, text, intensity, id, true)

func _get_turn_count() -> int:
	return simulation_minute

func has_relationship_with(other_id: int) -> bool:
	return relationships.has(other_id)

func get_relationship_value(other_id: int) -> float:
	return _normalized_relationship_value(relationships.get(other_id, 0.0))

func modify_relationship(other_id: int, delta: float) -> void:
	var current = get_relationship_value(other_id)
	var updated: float = clampf(current + delta, -1.0, 1.0)
	relationships[other_id] = updated
	if updated >= 0.55:
		if not friends.has(other_id):
			friends.append(other_id)
		rivals.erase(other_id)
	elif updated <= -0.45:
		if not rivals.has(other_id):
			rivals.append(other_id)
		friends.erase(other_id)
	else:
		friends.erase(other_id)
		rivals.erase(other_id)

func _normalized_relationship_value(raw_value) -> float:
	var value: float = float(raw_value)
	# Las primeras partidas guardaban afinidad como 60..99 aunque el resto del
	# sistema usa -1..1. Se migra al leer sin romper partidas antiguas.
	if value > 1.0:
		return clampf((value - 50.0) / 50.0, -1.0, 1.0)
	return clampf(value, -1.0, 1.0)

func update_emotions() -> void:
	var stress_factor = stress
	var need_penalty = 0.0
	var critical_needs = 0
	for n in needs.values():
		if n > 0.7:
			need_penalty += n * 0.1
		if n > 0.85:
			critical_needs += 1

	var total_unhappiness = stress_factor * 0.3 + need_penalty + (1.0 - happiness) * 0.5

	if total_unhappiness > 0.8:
		current_emotion = Emotion.ANGRY
		emotion_intensity = total_unhappiness
	elif total_unhappiness > 0.5:
		current_emotion = Emotion.SAD
		emotion_intensity = total_unhappiness
	elif total_unhappiness < 0.2 and happiness > 0.7:
		current_emotion = Emotion.HAPPY
		emotion_intensity = 1.0 - total_unhappiness
	else:
		current_emotion = Emotion.CONTENT
		emotion_intensity = 0.5

	# Las crisis son consecuencias de privaciones graves sostenidas, no una
	# lotería ejecutada varias veces por segundo.
	if simulation_minute == last_crisis_evaluation_minute:
		return
	last_crisis_evaluation_minute = simulation_minute
	var severe_distress = stress >= 0.80 and happiness <= 0.30 and critical_needs >= 2
	if severe_distress:
		crisis_pressure = minf(CRISIS_PRESSURE_REQUIRED * 2.0, crisis_pressure + 1.0)
		crisis_reason = "estrés extremo y %d necesidades críticas" % critical_needs
	else:
		crisis_pressure = maxf(0.0, crisis_pressure - 2.0)
		if crisis_pressure <= 0.0:
			crisis_reason = ""

	if (
		mood == MoodState.NORMAL
		and simulation_minute >= CRISIS_GRACE_MINUTES
		and crisis_pressure >= CRISIS_PRESSURE_REQUIRED
	):
		var violent_disposition = get_trait(PersonalityTrait.VIOLENCE)
		var anger_disposition = get_trait(PersonalityTrait.ANGER)
		var can_go_berserk = violent_disposition >= 0.85 and anger_disposition >= 0.80 and stress >= 0.95
		mood = MoodState.BESERK if can_go_berserk and randf() < 0.08 else MoodState.TANTRUM
		mood_counter = 120
		crisis_pressure = CRISIS_PRESSURE_REQUIRED * 0.5
	elif (
		mood == MoodState.NORMAL
		and simulation_minute >= CRISIS_GRACE_MINUTES
		and total_unhappiness > 0.65
		and crisis_pressure >= CRISIS_PRESSURE_REQUIRED * 0.75
	):
		mood = MoodState.MELANCHOLY
		mood_counter = 180
		crisis_pressure *= 0.5

	if stress < 0.1 and crisis_pressure <= 0.0 and mood in [
		MoodState.TANTRUM, MoodState.BESERK, MoodState.MELANCHOLY
	]:
		mood = MoodState.NORMAL
		mood_counter = 0

func update_stress(delta: float) -> void:
	var stress_change = 0.0
	var has_violent_trait = get_trait(PersonalityTrait.VIOLENCE) > 0.6
	var has_anxious_trait = get_trait(PersonalityTrait.FEAR) > 0.6

	for n_key in needs:
		var n_val = needs[n_key]
		if n_val > 0.8:
			stress_change += n_val * 0.02
		elif n_val < 0.2:
			stress_change -= 0.005

	if has_violent_trait and kill_count > 0:
		stress_change -= 0.01 * min(kill_count, 10)
	if has_anxious_trait:
		stress_change += 0.01

	if mood == MoodState.STRANGE_MOOD or mood == MoodState.FELL_MOOD:
		stress_change += 0.05

	var room_bonus = room_quality * 0.01
	stress_change -= room_bonus

	stress = clampf(stress + stress_change * delta, 0.0, 1.0)

func update_needs(delta: float) -> void:
	needs[Need.FOOD] = minf(1.0, needs[Need.FOOD] + 0.0002 * delta * 60)
	needs[Need.DRINK] = minf(1.0, needs[Need.DRINK] + 0.0003 * delta * 60)
	needs[Need.SLEEP] = minf(1.0, needs[Need.SLEEP] + 0.0004 * delta * 60)
	needs[Need.COMFORT] = minf(1.0, needs[Need.COMFORT] + 0.0001 * delta * 60)

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
	desc += "\nFisiología: %s | Nutrición: %.0f%%" % [physiology_status, nutrition_quality * 100]
	desc += "\nHoy: %d comidas | %.2f L de agua" % [meals_today, water_liters_today]
	desc += "\nCondición: %.0f%% | Carga: %.1f/%.1f" % [
		physical_condition * 100, get_carried_weight(), get_carrying_capacity()
	]
	desc += "\nSalud sistémica: %s | Inmunidad: %.0f%% | Exposición: %.0f%%" % [
		get_disease_status(), immune_strength * 100.0, pathogen_exposure * 100.0
	]
	desc += "\nVida social: %d conversaciones | %d creencias activas" % [
		conversations_held, social_beliefs.size()
	]
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
	pathogen_exposure = minf(2.0, pathogen_exposure + maxf(0.0, amount) * 0.01)
	infection_chance = pathogen_exposure

func rest_and_recover(delta: float) -> void:
	if is_sleeping:
		var recovery_rate = 0.001 * delta * 60 * (1.0 + sleep_quality * 0.5)
		health = minf(1.0, health + recovery_rate)
		if bleeding_rate > 0:
			bleeding_rate *= (1.0 - delta * 0.05)
			if bleeding_rate < 0.01:
				bleeding_rate = 0.0
				is_bleeding = false
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
	if not is_alive:
		return
	simulation_minute = int(world.get_meta("simulation_minute", simulation_minute))
	has_moved_this_tick = false
	needs_display_update = false
	var delta_game_minute: float = 1.0

	if minute_ticked:
		hunger += 0.00024
		thirst += 0.00036
		fatigue += 0.0005
		minutes_since_alcohol += 1
		update_needs(delta_game_minute)
		update_stress(delta_game_minute)
		update_pain_and_bleeding(delta_game_minute)
		tick_metabolism(world)
		tick_humanoid_physiology(world)
		tick_health_cycle(world)
		tick_grooming()
		tick_hygiene(world)
		tick_social(world)
		tick_inspect(world)
		
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
	var is_injured_or_sick = health < 0.70 or disease_severity >= 0.35 or is_bleeding
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
		is_sleeping = true
		fatigue = maxf(fatigue, 0.35)
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
		is_alive = false
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
		if randi() % 5 == 0:
			current_task = "¡PATALETA! (Destruyendo cosas)"
			current_job = null
			for other in world.dwarves:
				if other is DFDwarf and other != self and other.is_alive:
					var d = abs(other.tile_pos.x - tile_pos.x) + abs(other.tile_pos.z - tile_pos.z)
					if d <= 1:
						if world.combat_system != null:
							var msg = "¡%s golpeó a %s en la cara en un ataque de rabia!" % [name, other.name]
							world.combat_system._add_log(msg)
							other.happiness = clampf(other.happiness - 0.05, 0.0, 1.0)
						break
		if minute_ticked:
			mood_counter -= 1
		if mood_counter <= 0:
			mood = MoodState.NORMAL
			add_thought("Se calmó tras desahogar su frustración.", 0.05)
		return

	if mood == MoodState.BESERK:
		if not berserk_bonus_applied:
			combat_skill += 0.5
			strength += 1.0
			berserk_bonus_applied = true
		speed *= 1.5
		current_task = "¡BESERK! (Atacando todo)"
		if minute_ticked:
			mood_counter -= 1
		if mood_counter <= 0:
			mood = MoodState.NORMAL
			if berserk_bonus_applied:
				combat_skill = maxf(1.0, combat_skill - 0.5)
				strength = maxf(5.0, strength - 1.0)
				berserk_bonus_applied = false
			add_thought("La furia berserker se disipó. Está agotado.", -0.05)
		return

	if mood == MoodState.MELANCHOLY:
		if randi() % 10 == 0:
			add_thought("Se siente vacío y sin propósito.", -0.05)
			current_task = "Melancólico (meditando)"
		if minute_ticked:
			mood_counter -= 1
		if mood_counter <= 0:
			mood = MoodState.NORMAL
		return

	if mood == MoodState.STRANGE_MOOD or mood == MoodState.FELL_MOOD or mood == MoodState.MACABRE_MOOD or mood == MoodState.SECRETIVE_MOOD:
		_process_strange_mood(world)
		return

	if current_task == "¡PATALETA! (Destruyendo cosas)":
		if randi() % 5 == 0:
			_idle_wander(world)
		if minute_ticked and randi() % 100 < 5:
			current_task = "idle"
			add_thought("Se calmó tras desahogar su frustración.", 0.05)
		return

	if is_sleeping:
		current_task = "Durmiendo"
		fatigue -= 0.02
		rest_and_recover(1.0)
		if fatigue < 0.1:
			is_sleeping = false
			current_task = "idle"
			if preferred_bed.x < 0:
				add_thought("Durmió en el piso de piedra por falta de camas.", -0.02)
			else:
				sleep_quality = 0.3 + room_quality * 0.5
				if sleep_quality > 0.7:
					add_thought("Durmió plácidamente en su cama.", 0.04)
		return

	# Mientras está poseído, conserva metabolismo, emociones y heridas, pero no toma decisiones de IA.
	if is_possessed:
		current_task = "Controlado por el jugador"
		update_emotions()
		return

	# --- SISTEMA DE COMPORTAMIENTO DIARIO, RELIGIÓN Y APRENDIZAJE ---
	# DFWorld no pertenece al árbol de escenas: la hora se comparte como metadata
	# autoritativa desde DFMain para que dormir, trabajar y recrearse coincidan.
	var hour: int = int(world.get_meta("game_hour", 12))

	var is_sleep_time = (hour >= 22 or hour < 6)
	var is_recreation_time = (hour >= 14 and hour < 22)
	var is_meal_time = (hour == 12 or hour == 6 or hour == 18)

	# PRIORIDAD 1: Necesidades de supervivencia críticas
	if bladder_fill >= 0.75 or bowel_fill >= 0.75:
		if _try_relieve_waste(world):
			update_emotions()
			return
	if hunger > 0.85 or thirst > 0.85:
		if _satisfy_needs(world):
			update_emotions()
			return
	if fatigue > 0.90:
		if _try_sleep(world):
			update_emotions()
			return

	# PRIORIDAD 2: Descanso nocturno programado
	if is_sleep_time:
		if fatigue > 0.3 or current_job == null:
			if _try_sleep(world, true):
				update_emotions()
				return

	# PRIORIDAD 3: Almuerzo y cena comunitaria
	if is_meal_time and (hunger > 0.35 or thirst > 0.35):
		if _satisfy_needs(world):
			update_emotions()
			return

	# PRIORIDAD 4: Realizar trabajo activo asignado
	if current_job != null:
		_work_on_job(world)
		if current_job == null and operating_workshop == null:
			if not is_sleep_time and not is_recreation_time:
				if not jobs.is_empty():
					_pick_up_job(world, jobs)
					if current_job != null:
						_work_on_job(world)
						update_emotions()
						return
		else:
			update_emotions()
			return

	# PRIORIDAD 5: Buscar trabajo disponible en horas laborales
	if not is_sleep_time and not is_recreation_time and current_job == null and operating_workshop == null:
		if not jobs.is_empty():
			_pick_up_job(world, jobs)
			if current_job != null:
				_work_on_job(world)
				update_emotions()
				return

	# PRIORIDAD 6: Operar taller activo
	if operating_workshop != null:
		_operate_workshop(world)
		update_emotions()
		return

	# PRIORIDAD 7: Recreación, Acicalado y Religión (18:00 - 22:00)
	if is_recreation_time:
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

	# PRIORIDAD 8: (Movida al final de supervivencia autónoma para dar prioridad a trabajos)
	pass

	# PRIORIDAD 9: metas persistentes antes del comportamiento de supervivencia genérico.
	if current_job == null and operating_workshop == null:
		if _tick_persistent_autonomy(world, minute_ticked):
			update_emotions()
			return
		# Las necesidades críticas y los trabajos siguen respondiendo cada tick,
		# pero las búsquedas ambientales costosas se reparten entre habitantes.
		# Si ya existe una ruta, el movimiento continúa sin volver a decidir.
		var simulation_tick: int = int(world.get_meta("simulation_tick_total", 0))
		var autonomous_decision_due: bool = posmod(simulation_tick + id, 12) == 0
		if autonomous_decision_due:
			tick_autonomous_survival(world)
		elif not path.is_empty() and path_index < path.size():
			_move_toward(world, path.back())

	update_emotions()

func get_autonomous_status() -> Dictionary:
	return {
		"goal": autonomous_goal,
		"reason": autonomous_reason,
		"plan": autonomous_plan.duplicate(true),
		"summary": DFAutonomousPlan.summary(autonomous_plan),
	}

func _tick_persistent_autonomy(world, minute_ticked: bool) -> bool:
	if autonomous_plan_cooldown > 0 and minute_ticked:
		autonomous_plan_cooldown -= 1

	if autonomous_plan.is_empty() and minute_ticked and autonomous_plan_cooldown <= 0:
		_create_autonomous_plan(world)

	if autonomous_plan.is_empty():
		return false

	if DFAutonomousPlan.is_complete(autonomous_plan):
		autonomous_plan_history.append({
			"goal": autonomous_goal,
			"reason": autonomous_reason,
			"completed_at": Time.get_ticks_msec(),
		})
		if autonomous_plan_history.size() > 12:
			autonomous_plan_history.pop_front()
		add_thought("Completó su meta: %s." % autonomous_goal, 0.06)
		autonomous_plan = {}
		autonomous_goal = ""
		autonomous_reason = ""
		autonomous_target = Vector3i(-1, -1, -1)
		autonomous_plan_cooldown = 10
		return true

	if DFAutonomousPlan.is_failed(autonomous_plan):
		var failed_reason: String = str(autonomous_plan.get("last_failure", "No pudo continuar"))
		autonomous_plan_history.append({
			"goal": autonomous_goal,
			"reason": autonomous_reason,
			"failed": true,
			"failure": failed_reason,
			"completed_at": Time.get_ticks_msec(),
		})
		if autonomous_plan_history.size() > 12:
			autonomous_plan_history.pop_front()
		current_task = "Reconsiderando: %s" % failed_reason
		autonomous_plan = {}
		autonomous_goal = ""
		autonomous_reason = ""
		autonomous_target = Vector3i(-1, -1, -1)
		path.clear()
		path_index = 0
		autonomous_plan_cooldown = 15
		return true

	return _execute_autonomous_plan_step(world)

func _create_autonomous_plan(world) -> void:
	var has_pickaxe: bool = _has_tool_named(["pickaxe", "pico"])
	var has_axe: bool = _has_tool_named(["axe", "hacha"])

	if has_pickaxe and profession == Profession.MINER:
		var entrance: Vector3i = _find_nearest_stairs_down(world, 24)
		var needs_stairs: bool = entrance.x < 0
		if needs_stairs:
			entrance = _choose_mine_entrance(world)
		if entrance.x >= 0:
			autonomous_goal = "Abrir y explotar una mina comunitaria"
			autonomous_reason = "La comunidad necesita piedra, carbón y metales para sus herramientas."
			var mining_steps: Array = [
				{"action": "move_to", "label": "Ir a la entrada de la mina", "target": entrance},
			]
			if needs_stairs:
				mining_steps.append({"action": "stairs_down", "label": "Construir escalera descendente", "target": entrance})
			mining_steps.append({"action": "climb_down", "label": "Bajar al nivel subterráneo", "target": entrance})
			mining_steps.append({"action": "find_ore", "label": "Localizar una veta mineral"})
			mining_steps.append({"action": "move_adjacent", "label": "Acercarse a la veta"})
			mining_steps.append({"action": "mine", "label": "Extraer mineral"})
			mining_steps.append({"action": "pick_up_ore", "label": "Recoger el mineral extraído"})
			autonomous_plan = DFAutonomousPlan.create(autonomous_goal, autonomous_reason, mining_steps, entrance)
			autonomous_target = entrance
			return

	if has_axe:
		var tree: Vector3i = _find_nearest_tree(world)
		if tree.x >= 0:
			autonomous_goal = "Conseguir madera útil para la comunidad"
			autonomous_reason = "La madera permite fabricar camas, talleres y nuevas viviendas."
			var wood_steps: Array = [
				{"action": "move_adjacent", "label": "Ir hasta un árbol", "target": tree},
				{"action": "chop", "label": "Talar el árbol", "target": tree},
				{"action": "pick_up_wood", "label": "Recoger el tronco"},
			]
			autonomous_plan = DFAutonomousPlan.create(autonomous_goal, autonomous_reason, wood_steps, tree)
			autonomous_target = tree

func _execute_autonomous_plan_step(world) -> bool:
	var step: Dictionary = DFAutonomousPlan.current_step(autonomous_plan)
	if step.is_empty():
		autonomous_plan["state"] = "completed"
		return true

	var action: String = str(step.get("action", ""))
	var target: Vector3i = step.get("target", autonomous_plan.get("target", autonomous_target))
	current_task = DFAutonomousPlan.summary(autonomous_plan)

	match action:
		"move_to":
			if tile_pos == target:
				DFAutonomousPlan.advance(autonomous_plan)
			else:
				var before_move: Vector3i = tile_pos
				_move_toward(world, target)
				_record_plan_movement_result(before_move)
			return true
		"move_adjacent":
			if _plan_distance(tile_pos, target) <= 1:
				DFAutonomousPlan.advance(autonomous_plan)
			else:
				var before_adjacent_move: Vector3i = tile_pos
				_move_toward(world, target)
				_record_plan_movement_result(before_adjacent_move)
			return true
		"stairs_down":
			var tile_type: int = world.get_tile(target)
			if tile_type in [world.TileType.STAIRS_DOWN, world.TileType.STAIRS_UPDOWN]:
				DFAutonomousPlan.advance(autonomous_plan)
				return true
			var stairs_result: Dictionary = DFActorActionExecutor.execute(self, world, DFActorActionExecutor.ActionType.BUILD_STAIRS_DOWN, target)
			if bool(stairs_result.get("success", false)):
				DFAutonomousPlan.advance(autonomous_plan)
			else:
				DFAutonomousPlan.fail_step(autonomous_plan, str(stairs_result.get("message", "No pudo construir la escalera")))
			return true
		"climb_down":
			if tile_pos.x != target.x or tile_pos.z != target.z:
				_move_toward(world, target)
				return true
			var descend_result: Dictionary = DFActorActionExecutor.execute(self, world, DFActorActionExecutor.ActionType.CLIMB_DOWN, tile_pos)
			if bool(descend_result.get("success", false)):
				DFAutonomousPlan.advance(autonomous_plan)
			else:
				DFAutonomousPlan.fail_step(autonomous_plan, str(descend_result.get("message", "No pudo bajar")))
			return true
		"find_ore":
			var ore_target: Vector3i = _find_nearest_ore_wall(world, 18)
			if ore_target.x < 0:
				ore_target = _find_nearest_mineable_wall(world)
			if ore_target.x >= 0:
				autonomous_target = ore_target
				autonomous_plan["target"] = ore_target
				DFAutonomousPlan.advance(autonomous_plan)
			else:
				DFAutonomousPlan.fail_step(autonomous_plan, "No encontró roca excavable")
				autonomous_plan_cooldown = 5
			return true
		"mine":
			var mine_target: Vector3i = autonomous_plan.get("target", autonomous_target)
			var mine_result: Dictionary = DFActorActionExecutor.execute(self, world, DFActorActionExecutor.ActionType.MINE, mine_target)
			if bool(mine_result.get("success", false)):
				DFAutonomousPlan.advance(autonomous_plan)
			else:
				DFAutonomousPlan.fail_step(autonomous_plan, str(mine_result.get("message", "No pudo extraer")))
			return true
		"chop":
			var chop_result: Dictionary = DFActorActionExecutor.execute(self, world, DFActorActionExecutor.ActionType.CHOP_TREE, target)
			if bool(chop_result.get("success", false)):
				DFAutonomousPlan.advance(autonomous_plan)
			else:
				DFAutonomousPlan.fail_step(autonomous_plan, str(chop_result.get("message", "No pudo talar")))
			return true
		"pick_up_wood":
			var wood_pickup_state: int = _pick_up_nearby_item_by_types(world, ["wood", "plank"])
			if wood_pickup_state == 2:
				DFAutonomousPlan.advance(autonomous_plan)
			elif wood_pickup_state == 0:
				DFAutonomousPlan.fail_step(autonomous_plan, "No encontró el tronco talado")
			return true
		"pick_up_ore":
			var ore_pickup_state: int = _pick_up_nearby_item_by_types(world, ["iron_ore", "coal_ore", "gold_ore", "copper_ore", "silver_ore", "tin_ore", "platinum_ore", "stone"])
			if ore_pickup_state == 2:
				DFAutonomousPlan.advance(autonomous_plan)
			elif ore_pickup_state == 0:
				DFAutonomousPlan.fail_step(autonomous_plan, "No encontró el mineral extraído")
			return true

	DFAutonomousPlan.fail_step(autonomous_plan, "Paso de plan desconocido: %s" % action)
	autonomous_plan["state"] = "completed"
	return true

func _record_plan_movement_result(before_move: Vector3i) -> void:
	if autonomous_plan.is_empty():
		return
	var step: Dictionary = DFAutonomousPlan.current_step(autonomous_plan)
	if tile_pos != before_move:
		step["blocked_attempts"] = 0
		return
	var blocked_attempts: int = int(step.get("blocked_attempts", 0)) + 1
	step["blocked_attempts"] = blocked_attempts
	if blocked_attempts >= 8:
		DFAutonomousPlan.fail_step(autonomous_plan, "No existe una ruta practicable al objetivo")
		step["blocked_attempts"] = 0

func _has_tool_named(tokens: Array) -> bool:
	var weapon_lower: String = equipped_weapon.to_lower()
	for token in tokens:
		if str(token).to_lower() in weapon_lower:
			return true
	for item in inventory:
		var item_name: String = str(item.name).to_lower() if "name" in item else ""
		var item_type: String = str(item.item_type).to_lower() if "item_type" in item else ""
		for inventory_token in tokens:
			var lowered: String = str(inventory_token).to_lower()
			if lowered in item_name or lowered in item_type:
				return true
	return false

func _choose_mine_entrance(world) -> Vector3i:
	var origin: Vector3i = tile_pos
	var best: Vector3i = Vector3i(-1, -1, -1)
	var best_score: int = 999999
	for radius in range(0, 13):
		for dz in range(-radius, radius + 1):
			for dx in range(-radius, radius + 1):
				if abs(dx) != radius and abs(dz) != radius:
					continue
				var x: int = origin.x + dx
				var z: int = origin.z + dz
				if x < 1 or x >= world.width - 1 or z < 1 or z >= world.depth - 1:
					continue
				var y: int = world.get_surface_height(x, z)
				var candidate := Vector3i(x, y, z)
				if not world.is_floor(candidate) or world.is_water(candidate):
					continue
				var score: int = abs(dx) + abs(dz)
				if score < best_score:
					best = candidate
					best_score = score
		if best.x >= 0:
			break
	return best

func _find_nearest_stairs_down(world, radius: int) -> Vector3i:
	var best: Vector3i = Vector3i(-1, -1, -1)
	var best_distance: int = 999999
	for dz in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			var x: int = tile_pos.x + dx
			var z: int = tile_pos.z + dz
			if x < 0 or x >= world.width or z < 0 or z >= world.depth:
				continue
			var y: int = world.get_surface_height(x, z)
			var candidate := Vector3i(x, y, z)
			if world.get_tile(candidate) not in [world.TileType.STAIRS_DOWN, world.TileType.STAIRS_UPDOWN]:
				continue
			var distance: int = abs(dx) + abs(dz)
			if distance < best_distance:
				best_distance = distance
				best = candidate
	return best

func _find_nearest_ore_wall(world, radius: int) -> Vector3i:
	var ore_materials: Array = [world.MatType.COAL, world.MatType.IRON, world.MatType.GOLD, world.MatType.SILVER, world.MatType.COPPER, world.MatType.TIN, world.MatType.PLATINUM]
	var best: Vector3i = Vector3i(-1, -1, -1)
	var best_distance: int = 999999
	for dz in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			var candidate := Vector3i(tile_pos.x + dx, tile_pos.y, tile_pos.z + dz)
			if candidate.x < 0 or candidate.x >= world.width or candidate.z < 0 or candidate.z >= world.depth:
				continue
			if not world.is_wall(candidate):
				continue
			if world.get_material(candidate) not in ore_materials:
				continue
			var distance: int = abs(dx) + abs(dz)
			if distance < best_distance:
				best_distance = distance
				best = candidate
	return best

func _pick_up_nearby_item_by_types(world, accepted_types: Array) -> int:
	var best_item: Variant = null
	var best_distance: int = 999999
	for entity in world.items:
		if not "item_type" in entity or not "tile_pos" in entity:
			continue
		if str(entity.item_type) not in accepted_types:
			continue
		var distance: int = _plan_distance(tile_pos, entity.tile_pos)
		if distance < best_distance:
			best_distance = distance
			best_item = entity
	if best_item == null:
		return 0
	if best_distance > 1:
		_move_toward(world, best_item.tile_pos)
		return 1
	var result: Dictionary = DFActorActionExecutor.execute(self, world, DFActorActionExecutor.ActionType.PICK_UP, best_item.tile_pos)
	return 2 if bool(result.get("success", false)) else 0

func _plan_distance(a: Vector3i, b: Vector3i) -> int:
	return abs(a.x - b.x) + abs(a.z - b.z) + abs(a.y - b.y)

func _find_nearby_master_for_skill(world, skill_id: int):
	var my_level = get_skill_level(skill_id)
	var best_master = null
	var best_level = my_level
	var nearest_dist = 15.0
	for e in world.dwarves:
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
	for e in world.dwarves:
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
	for ent in world.get_items_at(tile_pos):
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
		world.remove_entity(item)

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
	for ent_h in world.items:
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

	for sp in world.stockpiles:
		if sp.has_tile(tile_pos) and sp._tile_has_capacity(world, tile_pos):
			var item = inventory.pop_back()
			item.tile_pos = tile_pos
			item.is_in_stockpile = true
			item.carried_by_id = -1
			_put_item_in_container_at(world, item, tile_pos)
			world.add_entity(item)
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
			item_1352.carried_by_id = -1
			_put_item_in_container_at(world, item_1352, tile_pos)
			world.add_entity(item_1352)
			current_task = "idle"
			needs_display_update = true
	else:
		current_task = "idle"

func assign_job(job) -> void:
	current_job = job
	current_task = job.get_description()
	task_progress = 0.0
	job.state = DFJob.JobState.ASSIGNED
	job.assigned_dwarf_id = id

func _job_requires_physical_progress(job_type: int) -> bool:
	return job_type in [
		DFJob.JobType.DIG,
		DFJob.JobType.CHOP_TREE,
		DFJob.JobType.BUILD_WALL,
		DFJob.JobType.BUILD_FLOOR,
		DFJob.JobType.BUILD_WORKSHOP,
		DFJob.JobType.BUILD_STAIRS_UP,
		DFJob.JobType.BUILD_STAIRS_DOWN,
		DFJob.JobType.SMOOTH,
	]

func _cancel_current_job(reason: String) -> void:
	if current_job == null:
		return
	current_job.cancel_reason = reason
	current_job.state = DFJob.JobState.CANCELLED
	current_job.assigned_dwarf_id = -1
	current_job = null
	task_progress = 0.0
	current_task = "Trabajo cancelado: %s" % reason
	needs_display_update = true

func _work_on_job(world) -> void:
	if is_possessed:
		return
	if current_job == null:
		_idle_wander(world)
		return
	if current_job.state == DFJob.JobState.CANCELLED:
		current_job = null
		current_task = "idle"
		return
	if current_job.state == DFJob.JobState.IN_PROGRESS and not _job_requires_physical_progress(current_job.job_type):
		# Transporte, almacenamiento y talleres son máquinas de estados: deben
		# continuar su siguiente etapa cada tick. Los trabajos físicos, en cambio,
		# pasan por la barra de progreso antes de modificar el mundo.
		current_task = current_job.get_description()
		_execute_job(world)
		return

	if current_job.job_type == DFJob.JobType.BUILD_WALL or current_job.job_type == DFJob.JobType.BUILD_FLOOR or current_job.job_type == DFJob.JobType.BUILD_WORKSHOP:
		var has_material = false
		for item in inventory:
			if item.item_type == "stone" or item.item_type == "wood":
				has_material = true
				break

		if not has_material:
			var best_item = null
			var best_dist = 999999
			for ent in world.items:
				if ent.item_type != "stone" and ent.item_type != "wood":
					continue
				if ent.is_decayed or ent.is_inside_container or ent.carried_by_id >= 0:
					continue
				if ent.is_reserved_for_other(id, simulation_minute):
					continue
				var d: int = abs(ent.tile_pos.x - tile_pos.x) + abs(ent.tile_pos.z - tile_pos.z) + abs(ent.tile_pos.y - tile_pos.y) * 2
				if d < best_dist:
					best_dist = d
					best_item = ent

			if best_item != null:
				best_item.reserve_for(id, simulation_minute + 30)
				current_task = "Llevando material para %s" % current_job.get_description().to_lower()
				var dist_to_item: int = abs(tile_pos.x - best_item.tile_pos.x) + abs(tile_pos.z - best_item.tile_pos.z) + abs(tile_pos.y - best_item.tile_pos.y) * 2
				if dist_to_item <= 1:
					best_item.release_reservation(id)
					best_item.carried_by_id = id
					world.remove_entity(best_item)
					inventory.append(best_item)
					needs_display_update = true
					current_task = current_job.get_description()
				else:
					_move_toward(world, best_item.tile_pos)
			else:
				_cancel_current_job("no hay piedra o madera accesible")
			return

	var dist = abs(tile_pos.x - current_job.tile_pos.x) + abs(tile_pos.z - current_job.tile_pos.z)

	if dist <= 1 and tile_pos.y == current_job.tile_pos.y:
		current_job.state = DFJob.JobState.IN_PROGRESS
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
		bowel_fill = minf(1.25, bowel_fill + absorbed * 0.35)
		body.ingested_substances["food"] = food_stored - absorbed
		if body.ingested_substances["food"] <= 0.0:
			body.ingested_substances.erase("food")
	var water_stored: float = body.ingested_substances.get("water", 0.0)
	if water_stored > 0.0:
		var absorb_water = minf(water_stored, 0.003 * met_rate)
		thirst = maxf(0.0, thirst - absorb_water * 10.0)
		bladder_fill = minf(1.25, bladder_fill + absorb_water * 0.65)
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
		pathogen_exposure = minf(2.0, pathogen_exposure + 0.01 * pathogen / maxf(0.25, path_resist))
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

func record_consumption(item: DFItem) -> void:
	if item == null:
		return
	if item.is_edible:
		meals_today += 1
		daily_protein += item.protein_value
		daily_carbohydrates += item.carbohydrate_value
		daily_fat += item.fat_value
		daily_fiber += item.fiber_value
		daily_micronutrients += item.micronutrient_value
	if item.is_drink:
		water_liters_today += maxf(0.0, item.hydration)

## Salud sistémica evaluada una vez por minuto simulado. Evita búsquedas entre
## entidades: el contagio usa la capa ambiental de patógenos ya indexada por tile.
func tick_health_cycle(world: Object) -> void:
	if body == null:
		return

	# Migración transparente de partidas que solo guardaban has_infection.
	if has_infection and disease_phase == DiseasePhase.HEALTHY:
		disease_phase = DiseasePhase.SYMPTOMATIC
		disease_progress = 0.35
		disease_severity = maxf(0.25, infection_chance)

	var tile_substances: Dictionary = world.get_splatters_at(tile_pos)
	var environmental_pathogen: float = float(tile_substances.get("pathogen", 0.0))
	var miasma_load: float = float(tile_substances.get("miasma", 0.0))
	var ingested_pathogen: float = float(body.ingested_substances.get("pathogen", 0.0))
	var genetic_resistance: float = genome.pathogen_resistance if genome != null else 1.0
	var resilience: float = maxf(0.25, genetic_resistance * (0.45 + chronic_health * 0.35 + nutrition_quality * 0.20))
	var exposure_gain: float = (environmental_pathogen * 0.018 + miasma_load * 0.004 + ingested_pathogen * 0.025) / resilience
	pathogen_exposure = clampf(pathogen_exposure + exposure_gain - 0.0007, 0.0, 2.0)
	infection_chance = pathogen_exposure

	var rest_support: float = 0.0
	if is_sleeping:
		rest_support += 0.45 + sleep_quality * 0.25
	if is_resting_medical:
		rest_support += 0.20
	var hydration_support: float = clampf(1.0 - thirst, 0.0, 1.0)
	immune_strength = clampf(
		0.15
		+ chronic_health * 0.25
		+ nutrition_quality * 0.25
		+ hydration_support * 0.15
		+ rest_support * 0.20,
		0.10,
		1.25
	)

	if acquired_immunity > 0.0:
		acquired_immunity = maxf(0.0, acquired_immunity - 1.0 / 10080.0)

	match disease_phase:
		DiseasePhase.HEALTHY:
			has_infection = false
			body.disease_type = ""
			disease_severity = 0.0
			fever = maxf(0.0, fever - 0.01)
			# Una sola evaluación por hora y habitante reduce coste y oscilaciones.
			if pathogen_exposure >= 0.12 and simulation_minute % 60 == id % 60:
				var infection_risk: float = clampf(
					(pathogen_exposure - acquired_immunity * 0.55) / maxf(0.25, immune_strength),
					0.0,
					0.85
				)
				if randf() < infection_risk:
					disease_phase = DiseasePhase.INCUBATING
					disease_progress = 0.0
					body.disease_type = "environmental_infection"
					add_thought("Nota un malestar después de exponerse a un ambiente insalubre.", -0.03)
		DiseasePhase.INCUBATING:
			has_infection = true
			body.disease_type = "environmental_infection"
			disease_progress += 1.0 / 360.0
			disease_severity = lerpf(0.05, 0.30, disease_progress)
			if disease_progress >= 1.0:
				disease_phase = DiseasePhase.SYMPTOMATIC
				disease_progress = 0.0
				add_thought("Se siente enfermo y necesita descanso, agua y comida adecuada.", -0.08)
		DiseasePhase.SYMPTOMATIC:
			has_infection = true
			body.disease_type = "environmental_infection"
			var vulnerability: float = clampf(
				(1.0 - immune_strength) * 0.55 + pathogen_exposure * 0.20 + stress * 0.10,
				0.0,
				0.85
			)
			var target_severity: float = clampf(0.28 + vulnerability - rest_support * 0.20, 0.15, 0.95)
			disease_severity = move_toward(disease_severity, target_severity, 0.0025)
			fever = move_toward(fever, disease_severity, 0.006)
			fatigue = minf(1.25, fatigue + disease_severity * 0.0007)
			if disease_severity > 0.70:
				health = maxf(0.05, health - (disease_severity - 0.70) * 0.00012)
			if is_sleeping and nutrition_quality >= 0.45 and thirst < 0.70:
				recovery_streak += 1
			else:
				recovery_streak = maxi(0, recovery_streak - 1)
			if recovery_streak >= 240 or (immune_strength >= 0.85 and recovery_streak >= 120):
				disease_phase = DiseasePhase.RECOVERING
				disease_progress = 0.0
				add_thought("Su estado empieza a mejorar tras descansar y alimentarse.", 0.04)
			if disease_severity >= 0.30 and simulation_minute % 20 == id % 20:
				world.add_splatter_substance(tile_pos, "pathogen", 0.003 * disease_severity)
		DiseasePhase.RECOVERING:
			has_infection = true
			body.disease_type = "recovering_infection"
			disease_progress += immune_strength / 720.0
			disease_severity = maxf(0.0, disease_severity - 0.0015 * immune_strength)
			fever = maxf(0.0, fever - 0.003)
			if disease_progress >= 1.0 or disease_severity <= 0.02:
				disease_phase = DiseasePhase.HEALTHY
				disease_progress = 0.0
				disease_severity = 0.0
				pathogen_exposure *= 0.20
				infection_chance = pathogen_exposure
				acquired_immunity = 1.0
				recovery_streak = 0
				has_infection = false
				body.disease_type = ""
				stats_tracker["infections_survived"] = stats_tracker.get("infections_survived", 0) + 1
				add_thought("Se recuperó de la enfermedad y desarrolló resistencia temporal.", 0.08)

func get_disease_status() -> String:
	match disease_phase:
		DiseasePhase.INCUBATING:
			return "Incubando"
		DiseasePhase.SYMPTOMATIC:
			if disease_severity >= 0.70:
				return "Enfermedad grave"
			if disease_severity >= 0.40:
				return "Enfermedad moderada"
			return "Enfermedad leve"
		DiseasePhase.RECOVERING:
			return "Recuperándose"
	return "Sano"

func tick_humanoid_physiology(world: Object) -> void:
	var day_index: int = floori(float(simulation_minute) / 1440.0)
	if last_physiology_day < 0:
		last_physiology_day = day_index
	elif day_index != last_physiology_day:
		_evaluate_daily_health()
		last_physiology_day = day_index
		meals_today = 0
		water_liters_today = 0.0
		daily_protein = 0.0
		daily_carbohydrates = 0.0
		daily_fat = 0.0
		daily_fiber = 0.0
		daily_micronutrients = 0.0

	var carried_ratio: float = get_carried_weight() / maxf(1.0, get_carrying_capacity())
	if carried_ratio > 0.30 and has_moved_this_tick:
		physical_condition = minf(1.0, physical_condition + 0.00004)
		fatigue = minf(1.25, fatigue + carried_ratio * 0.0002)
	elif is_sleeping:
		physical_condition = maxf(0.0, physical_condition - 0.000002)

	if bladder_fill >= 1.0 or bowel_fill >= 1.0:
		_try_relieve_waste(world)
	elif bladder_fill > 0.85 or bowel_fill > 0.85:
		stress = minf(1.0, stress + 0.0005)
		physiology_status = "Necesita aliviarse"
	elif nutrition_quality < 0.4:
		physiology_status = "Malnutrición"
	elif physical_condition < 0.25:
		physiology_status = "Condición física baja"
	else:
		physiology_status = "Estable"

func _evaluate_daily_health() -> void:
	var meal_score: float = clampf(float(meals_today) / 3.0, 0.0, 1.0)
	var water_score: float = clampf(water_liters_today / 1.0, 0.0, 1.0)
	var macro_score: float = (
		clampf(daily_protein / 0.65, 0.0, 1.0)
		+ clampf(daily_carbohydrates / 0.90, 0.0, 1.0)
		+ clampf(daily_fat / 0.25, 0.0, 1.0)
	) / 3.0
	var micro_score: float = (
		clampf(daily_fiber / 0.45, 0.0, 1.0)
		+ clampf(daily_micronutrients / 0.45, 0.0, 1.0)
	) / 2.0
	var day_quality: float = meal_score * 0.30 + water_score * 0.25 + macro_score * 0.25 + micro_score * 0.20
	nutrition_quality = lerpf(nutrition_quality, day_quality, 0.20)
	if day_quality < 0.35:
		chronic_health = maxf(0.20, chronic_health - 0.004)
		toughness = maxf(1.0, toughness - 0.002)
		stress = minf(1.0, stress + 0.02)
	elif day_quality >= 0.75:
		chronic_health = minf(1.0, chronic_health + 0.002)
	health = minf(health, chronic_health)

func get_carried_weight() -> float:
	var total_weight: float = 0.0
	for carried_item in inventory:
		if carried_item is DFItem:
			total_weight += carried_item.get_item_volume() * maxi(1, carried_item.stack_size)
	return total_weight

func get_carrying_capacity() -> float:
	var age_factor: float = 1.0
	if age < 16:
		age_factor = 0.55
	elif age > 55:
		age_factor = maxf(0.55, 1.0 - float(age - 55) * 0.012)
	return maxf(5.0, (strength * 2.2 + body_mass_kg * 0.12) * (0.55 + physical_condition * 0.75) * age_factor * chronic_health)

func _try_relieve_waste(world: Object) -> bool:
	if bladder_fill < 0.75 and bowel_fill < 0.75:
		return false
	var nearest_latrine = null
	var nearest_distance: int = 2147483647
	for building in world.buildings:
		if building.type != DFBuilding.BuildingType.LATRINE:
			continue
		if not building.has_sanitation_capacity(0.12):
			continue
		var distance: int = abs(building.tile_pos.x - tile_pos.x) + abs(building.tile_pos.z - tile_pos.z)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_latrine = building
	var emergency: bool = bladder_fill >= 1.0 or bowel_fill >= 1.0
	if nearest_latrine != null and nearest_distance > 0 and not emergency:
		current_task = "Yendo a la letrina"
		_move_toward(world, nearest_latrine.tile_pos)
		return true
	var waste_amount: float = 0.03 + maxf(bladder_fill, bowel_fill) * 0.05
	var used_latrine: bool = nearest_latrine != null and nearest_distance == 0
	if bladder_fill >= bowel_fill:
		bladder_fill = 0.0
		current_task = "Aliviando la vejiga"
	else:
		bowel_fill = 0.0
		current_task = "Aliviando el intestino"
	if used_latrine:
		if not nearest_latrine.add_sanitation_waste(waste_amount):
			world.add_splatter_substance(tile_pos, "feces", waste_amount)
			world.add_splatter_substance(tile_pos, "pathogen", waste_amount * 0.10)
	else:
		var waste_type: String = "urine" if current_task == "Aliviando la vejiga" else "feces"
		world.add_splatter_substance(tile_pos, waste_type, waste_amount)
		if waste_type == "feces":
			world.add_splatter_substance(tile_pos, "pathogen", waste_amount * 0.08)
	stress = maxf(0.0, stress - 0.02)
	needs_display_update = true
	return true


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
	_decay_social_beliefs()
	if current_task != "idle": return
	if randi() % 30 != 0: return
	for e in world.dwarves:
		if e == self: continue
		var is_dwarf = e.get("creature_type") == "dwarf"
		var e_alive = e.get("is_alive")
		if not is_dwarf or e_alive == false: continue
		var dist = abs(e.tile_pos.x - tile_pos.x) + abs(e.tile_pos.z - tile_pos.z)
		if dist <= 1 and e.tile_pos.y == tile_pos.y:
			current_task = "Socializando"
			needs_display_update = true
			needs[Need.SOCIAL] = maxf(0.0, needs[Need.SOCIAL] - 0.2)
			last_social_interaction = simulation_minute
			conversations_held += 1
			_exchange_social_belief(e)
			var affinity: float = get_relationship_value(e.id)
			var compatibility: float = _social_compatibility_with(e)
			var interaction_delta: float = lerpf(-0.015, 0.025, compatibility)
			modify_relationship(e.id, interaction_delta)
			e.modify_relationship(id, interaction_delta * 0.8)
			# El estado emocional se contagia, pero la confianza amortigua el
			# efecto: una conversación ya no copia estrés sin contexto.
			var target_stress = e.get("stress")
			if target_stress == null:
				target_stress = 0.5
			var stress_diff = stress - target_stress
			if abs(stress_diff) > 0.2:
				var transfer = stress_diff * (0.035 + maxf(0.0, affinity) * 0.045)
				stress = clampf(stress - transfer, 0.0, 1.0)
				e.stress = clampf(e.stress + transfer, 0.0, 1.0)
			return

func _exchange_social_belief(other) -> void:
	var belief: Dictionary = _pick_salient_belief()
	if belief.is_empty() and not memories.is_empty():
		var memory: Dictionary = memories.back()
		_learn_social_belief(
			str(memory.get("category", "vida")),
			id,
			str(memory.get("text", "")),
			float(memory.get("intensity", 0.5)),
			id,
			true
		)
		belief = _pick_salient_belief()
	if belief.is_empty():
		add_thought("Conversó tranquilamente con %s." % other.name, 0.02)
		return
	add_thought("Contó a %s: %s" % [other.name, belief.get("claim", "")], 0.02)
	other._receive_social_belief(belief, self)

func _receive_social_belief(belief: Dictionary, speaker) -> void:
	var trust: float = get_relationship_value(speaker.id)
	var speaker_honesty: float = speaker.get_trait(PersonalityTrait.HONESTY)
	var confidence: float = float(belief.get("confidence", 0.5))
	var accepted_confidence: float = confidence * (0.35 + speaker_honesty * 0.25 + (trust + 1.0) * 0.20)
	accepted_confidence = clampf(accepted_confidence, 0.05, 0.95)
	var changed: bool = _learn_social_belief(
		str(belief.get("category", "rumor")),
		int(belief.get("subject_id", speaker.id)),
		str(belief.get("claim", "")),
		accepted_confidence,
		speaker.id,
		false
	)
	if changed:
		add_thought("Escuchó de %s: %s" % [speaker.name, belief.get("claim", "")], 0.01)
		var reputation: float = float(social_reputation.get(speaker.id, 0.0))
		social_reputation[speaker.id] = clampf(
			reputation + (accepted_confidence - 0.45) * 0.05, -1.0, 1.0
		)

func _learn_social_belief(
	category: String,
	subject_id: int,
	claim: String,
	confidence: float,
	source_id: int,
	witnessed: bool
) -> bool:
	if claim.strip_edges().is_empty():
		return false
	var normalized_claim: String = claim.strip_edges().to_lower()
	var belief_key: String = "%s|%d|%s" % [category, subject_id, normalized_claim]
	for existing in social_beliefs:
		if str(existing.get("key", "")) == belief_key:
			existing["confidence"] = clampf(
				maxf(float(existing.get("confidence", 0.0)), confidence) + (0.04 if witnessed else 0.01),
				0.0,
				1.0
			)
			existing["last_heard_minute"] = simulation_minute
			var sources: Array = existing.get("sources", [])
			if not sources.has(source_id):
				sources.append(source_id)
			existing["sources"] = sources.slice(maxi(0, sources.size() - 4))
			return false
		# Dos afirmaciones diferentes sobre el mismo asunto generan duda real.
		if str(existing.get("category", "")) == category and int(existing.get("subject_id", -1)) == subject_id:
			existing["confidence"] = maxf(0.05, float(existing.get("confidence", 0.5)) - confidence * 0.20)
	var belief := {
		"key": belief_key,
		"category": category,
		"subject_id": subject_id,
		"claim": claim.strip_edges(),
		"confidence": clampf(confidence + (0.20 if witnessed else 0.0), 0.05, 1.0),
		"witnessed": witnessed,
		"sources": [source_id],
		"created_minute": simulation_minute,
		"last_heard_minute": simulation_minute
	}
	social_beliefs.append(belief)
	_prune_social_beliefs()
	return true

func _pick_salient_belief() -> Dictionary:
	var selected: Dictionary = {}
	var best_score: float = 0.0
	for belief in social_beliefs:
		var age_days: float = float(simulation_minute - int(belief.get("last_heard_minute", 0))) / 1440.0
		var score: float = float(belief.get("confidence", 0.0)) - age_days * 0.01
		if bool(belief.get("witnessed", false)):
			score += 0.12
		if score > best_score:
			best_score = score
			selected = belief
	return selected

func _decay_social_beliefs() -> void:
	var day: int = simulation_minute / 1440
	if day == last_belief_decay_day or simulation_minute % 60 != id % 60:
		return
	last_belief_decay_day = day
	for belief in social_beliefs:
		var confidence: float = float(belief.get("confidence", 0.0))
		belief["confidence"] = maxf(0.0, confidence - (0.008 if bool(belief.get("witnessed", false)) else 0.025))
	_prune_social_beliefs()

func _prune_social_beliefs() -> void:
	var oldest_allowed: int = simulation_minute - BELIEF_FORGET_DAYS * 1440
	var retained: Array = []
	for belief in social_beliefs:
		if float(belief.get("confidence", 0.0)) >= 0.08 and int(belief.get("last_heard_minute", 0)) >= oldest_allowed:
			retained.append(belief)
	retained.sort_custom(func(a, b): return float(a.get("confidence", 0.0)) > float(b.get("confidence", 0.0)))
	social_beliefs = retained.slice(0, mini(MAX_SOCIAL_BELIEFS, retained.size()))

func _social_compatibility_with(other) -> float:
	var similarity: float = 0.0
	var compared_traits: Array = [
		PersonalityTrait.SOCIABILITY,
		PersonalityTrait.HONESTY,
		PersonalityTrait.COMPASSION,
		PersonalityTrait.POLITENESS
	]
	for trait_id in compared_traits:
		similarity += 1.0 - absf(get_trait(trait_id) - other.get_trait(trait_id))
	similarity /= float(compared_traits.size())
	return clampf(similarity * 0.65 + (get_relationship_value(other.id) + 1.0) * 0.175, 0.0, 1.0)

# ---- INSPECT ----
func tick_inspect(world) -> void:
	if current_task != "idle": return
	if randi() % 40 != 0: return
	for e in world.items:
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
	var ate = false
	var drank = false

	# Umbral mas bajo cuando el hambre/sed son criticas
	var food_threshold = 0.4
	var drink_threshold = 0.4
	if hunger > 0.8:
		food_threshold = 0.0  # Come aunque no tenga casi hambre, cualquier cosa
	if thirst > 0.8:
		drink_threshold = 0.0  # Bebe aunque no tenga casi sed

	for i in range(inventory.size() - 1, -1, -1):
		var item = inventory[i]
		if item.is_decayed:
			continue
		if hunger > food_threshold and item.is_edible:
			body.ingested_substances["food"] = body.ingested_substances.get("food", 0.0) + item.nutrition * 0.5
			needs[Need.FOOD] = maxf(0.0, needs[Need.FOOD] - item.nutrition * 0.5)
			hunger = maxf(0.0, hunger - item.nutrition)
			record_consumption(item)
			inventory.remove_at(i)
			ate = true
			current_task = "Comiendo"
			needs_display_update = true
			if item.name == preferred_food:
				add_thought("Disfrutó de su comida favorita: %s." % item.name, 0.06)
			else:
				add_thought("Comió para sobrevivir.", 0.04 if hunger < 0.8 else 0.01)
			break
		elif thirst > drink_threshold and item.is_drink:
			body.ingested_substances["water"] = body.ingested_substances.get("water", 0.0) + item.hydration
			needs[Need.DRINK] = maxf(0.0, needs[Need.DRINK] - item.hydration)
			thirst = maxf(0.0, thirst - maxf(0.35, item.hydration))
			record_consumption(item)
			inventory.remove_at(i)
			drank = true
			current_task = "Bebiendo"
			needs_display_update = true

			if "Ale" in item.name or "Cerveza" in item.name or "Vino" in item.name:
				minutes_since_alcohol = 0
				stress *= 0.9
				if item.name == preferred_drink:
					add_thought("Bebió su alcohol favorito: %s. ¡Excelente!" % item.name, 0.10)
				else:
					add_thought("Se sintió reconfortado al beber buen alcohol enano.", 0.08)
			else:
				add_thought("Bebió agua (preferiría alcohol).", -0.01)
			break

	if ate or drank:
		return true

	if thirst > drink_threshold and _drink_from_water_well(world):
		return true

	if _drink_from_splatters(world):
		return true

	# Busqueda mas agresiva: buscar en todo el mapa cuando es critico
	var target_food: DFItem = null
	var target_drink: DFItem = null
	var best_dist = 99999
	var max_search_radius = 30 if (hunger > 0.8 or thirst > 0.8) else 15

	# Buscar comida en stockpiles (items almacenados)
	if not world.stockpiles.is_empty():
		for sp in world.stockpiles:
			for stock_tile in sp.tiles:
				var d = abs(stock_tile.x - tile_pos.x) + abs(stock_tile.z - tile_pos.z) + abs(stock_tile.y - tile_pos.y) * 2
				if d > max_search_radius:
					continue
				# Buscar items en este tile del stockpile
				for ent in world.get_items_at(stock_tile):
					if ent.is_decayed:
						continue
					if d < best_dist:
						if hunger > 0.5 and ent.is_edible:
							best_dist = d
							target_food = ent
						elif thirst > 0.5 and ent.is_drink and target_food == null:
							best_dist = d
							target_drink = ent

	# Buscar en el suelo (siempre, independientemente de stockpiles)
	for ent_1754 in world.items:
		if ent_1754 is DFItem:
			if ent_1754.is_decayed:
				continue
			var d_1758 = abs(ent_1754.tile_pos.x - tile_pos.x) + abs(ent_1754.tile_pos.z - tile_pos.z) + abs(ent_1754.tile_pos.y - tile_pos.y) * 2
			if d_1758 > max_search_radius:
				continue
			if d_1758 < best_dist:
				if hunger > 0.5 and ent_1754.is_edible:
					best_dist = d_1758
					target_food = ent_1754
				elif thirst > 0.5 and ent_1754.is_drink and target_food == null:
					best_dist = d_1758
					target_drink = ent_1754

	var target = target_food if target_food != null else target_drink
	if target != null:
		var dist = abs(tile_pos.x - target.tile_pos.x) + abs(tile_pos.z - target.tile_pos.z) + abs(tile_pos.y - target.tile_pos.y) * 2
		if dist <= 1:
			inventory.append(target)
			target.carried_by_id = id
			target.is_in_stockpile = false
			target.is_inside_container = false
			target.container_id = -1
			world.remove_entity(target)
			needs_display_update = true
			return false
		else:
			current_task = "Buscando comida"
			_move_toward(world, target.tile_pos)
			return true

	return false

func _drink_from_water_well(world: Object) -> bool:
	var nearest_well = null
	var nearest_distance: int = 2147483647
	for building_value: Variant in world.buildings:
		if not (building_value is DFBuilding):
			continue
		var well: DFBuilding = building_value
		if well.type != DFBuilding.BuildingType.WATER_WELL or well.water_volume < 0.10:
			continue
		var distance: int = abs(well.tile_pos.x - tile_pos.x) + abs(well.tile_pos.z - tile_pos.z)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_well = well
	if nearest_well == null:
		return false
	if nearest_distance > 0:
		current_task = "Yendo al pozo"
		_move_toward(world, nearest_well.tile_pos)
		return true
	var serving: Dictionary = nearest_well.draw_water(0.35)
	var amount: float = float(serving.get("amount", 0.0))
	if amount <= 0.0:
		return false
	var contamination: float = float(serving.get("contamination", 0.0))
	body.ingested_substances["water"] = body.ingested_substances.get("water", 0.0) + amount
	water_liters_today += amount
	thirst = maxf(0.0, thirst - amount * 1.40)
	needs[Need.DRINK] = maxf(0.0, needs[Need.DRINK] - amount)
	if contamination > 0.0:
		body.ingested_substances["pathogen"] = body.ingested_substances.get("pathogen", 0.0) + contamination * amount
		pathogen_exposure = minf(2.0, pathogen_exposure + contamination * 0.04)
	current_task = "Bebiendo del pozo"
	needs_display_update = true
	if contamination >= 0.20:
		add_thought("El agua del pozo tenía olor y sabor desagradables.", -0.05)
	else:
		add_thought("Bebió agua fresca del pozo comunal.", 0.03)
	return true

func _drink_from_splatters(world) -> bool:
	var here = world.get_splatters_at(tile_pos)
	var drinkable = ["beer", "water", "mud"]
	for s in drinkable:
		var amount = here.get(s, 0.0)
		if amount > 0.01:
			var sip = minf(amount, 0.02)
			body.ingested_substances[s] = body.ingested_substances.get(s, 0.0) + sip
			world.absorb_from_tile(tile_pos, s, sip)
			var water_contamination: float = world.get_water_contamination(tile_pos)
			if s != "beer" and water_contamination > 0.0:
				body.ingested_substances["pathogen"] = body.ingested_substances.get("pathogen", 0.0) + water_contamination * sip
				pathogen_exposure = minf(2.0, pathogen_exposure + water_contamination * 0.02)
			thirst = maxf(0.0, thirst - 0.1)
			hunger = maxf(0.0, hunger - 0.03)
			if s == "beer":
				minutes_since_alcohol = 0
				stress *= 0.95
				add_thought("Bebió un poco de cerveza del suelo. No es lo ideal, pero sirve.", 0.02)
			else:
				if water_contamination >= 0.20:
					add_thought("Bebió agua de aspecto insalubre por necesidad.", -0.04)
				else:
					add_thought("Bebió del suelo para saciar la sed.", -0.01)
			current_task = "Bebiendo del suelo"
			needs_display_update = true
			return true
	return false

func _try_sleep(world, scheduled: bool = false) -> bool:
	if not scheduled and fatigue <= 0.82:
		return false

	# Buscar y reclamar cama si no tiene una
	if preferred_bed.x < 0:
		var bed_pos = _find_unclaimed_bed(world)
		if bed_pos.x >= 0:
			_claim_bed(world, bed_pos)

	# Durante el horario nocturno siempre intenta llegar a su cama. Solo una
	# emergencia de agotamiento permite quedarse dormido antes de alcanzarla.
	if preferred_bed.x >= 0 and (scheduled or fatigue < 0.96):
		var dist_to_bed = abs(tile_pos.x - preferred_bed.x) + abs(tile_pos.z - preferred_bed.z)
		if dist_to_bed > 1 or tile_pos.y != preferred_bed.y:
			current_task = "Yendo a su cama"
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

func _find_unclaimed_bed(world) -> Vector3i:
	var best := Vector3i(-1, -1, -1)
	if world == null:
		return best
	var best_dist: int = 99999
	for item_value in world.items:
		if not item_value.is_bed or item_value.is_decayed or _is_bed_claimed(world, item_value.tile_pos):
			continue
		var distance: int = abs(item_value.tile_pos.x - tile_pos.x) + abs(item_value.tile_pos.z - tile_pos.z)
		if distance < best_dist:
			best_dist = distance
			best = item_value.tile_pos
	return best

func _is_bed_claimed(world, bed_pos: Vector3i) -> bool:
	if world == null:
		return false
	for dwarf_value in world.dwarves:
		if dwarf_value.is_alive and dwarf_value.preferred_bed == bed_pos:
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
	for e in world.items:
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
	
	# Buscar otros enanos y caminar hacia ellos (efecto manada)
	for e_1981 in world.dwarves:
		var is_dwarf = e_1981.get("creature_type") == "dwarf" and e_1981 != self
		if is_dwarf and e_1981.get("is_alive") == true:
			var dx_1984 = abs(e_1981.tile_pos.x - tile_pos.x)
			var dz_1985 = abs(e_1981.tile_pos.z - tile_pos.z)
			if dx_1984 <= radius and dz_1985 <= radius and dx_1984 + dz_1985 > 0:
				candidates.append({"pos": e_1981.tile_pos, "priority": -1})
	
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
			var wall_was_complete: bool = world.get_tile(current_job.tile_pos) == DFWorld.TileType.CONSTRUCTED_WALL
			var mat_id = 11
			var wall_material_index: int = -1
			for i in range(inventory.size()):
				if inventory[i].item_type == "stone" or inventory[i].item_type == "wood":
					mat_id = inventory[i].material
					wall_material_index = i
					break
			success = world.build_wall(current_job.tile_pos, mat_id)
			if success and not wall_was_complete and wall_material_index >= 0:
				inventory.remove_at(wall_material_index)
		DFJob.JobType.BUILD_FLOOR:
			var floor_was_complete: bool = world.get_tile(current_job.tile_pos) == DFWorld.TileType.CONSTRUCTED_FLOOR
			var mat_id_2026 = 11
			var floor_material_index: int = -1
			for i_2027 in range(inventory.size()):
				if inventory[i_2027].item_type == "stone" or inventory[i_2027].item_type == "wood":
					mat_id_2026 = inventory[i_2027].material
					floor_material_index = i_2027
					break
			success = world.build_floor(current_job.tile_pos, mat_id_2026)
			if success and not floor_was_complete and floor_material_index >= 0:
				inventory.remove_at(floor_material_index)
		DFJob.JobType.BUILD_WORKSHOP:
			var workshop_was_complete: bool = world.get_workshop_at(current_job.tile_pos) != null
			var mat_id_2034 = 11
			var workshop_material_index: int = -1
			for i_2035 in range(inventory.size()):
				if inventory[i_2035].item_type == "stone" or inventory[i_2035].item_type == "wood":
					mat_id_2034 = inventory[i_2035].material
					workshop_material_index = i_2035
					break
			if workshop_was_complete:
				success = true
			else:
				for b in world.buildings:
					if b.tile_pos == current_job.tile_pos and not b.is_constructed:
						b.is_constructed = true
						world.create_workshop(b.type, b.tile_pos)
						success = true
						break
			if success and not workshop_was_complete and workshop_material_index >= 0:
				inventory.remove_at(workshop_material_index)
		DFJob.JobType.WORKSHOP_REACTION:
			var reaction_id: String = current_job.reaction_id
			if reaction_id.is_empty():
				reaction_id = "smelt_iron"
			var target_workshop = world.get_workshop_at(current_job.tile_pos)
			if target_workshop != null:
				# La orden solo entra en la cola. El operador recogerá insumos,
				# trabajará el tiempo requerido y recién entonces creará salidas.
				success = target_workshop.queue_recipe(reaction_id)
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
		DFJob.JobType.CLEAN:
			success = world.clean_sanitary_tile(current_job.tile_pos, 0.18) > 0.0
			if success:
				current_task = "Limpiando contaminación"
				stress = maxf(0.0, stress - 0.01)
		DFJob.JobType.EMPTY_LATRINE:
			success = _execute_empty_latrine_job(world)
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
			for ent in world.dwarves:
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
				
				# 2. Los cuidados reducen exposición y gravedad; no borran una
				# enfermedad sistémica de forma instantánea.
				if patient.has_infection:
					# Check if doctor has beer/alcohol in inventory
					var has_alcohol = false
					for i_2135 in range(inventory.size()):
						if inventory[i_2135].item_type == "drink":
							inventory.remove_at(i_2135)
							has_alcohol = true
							break
					var treatment_quality: float = 0.08 + get_skill_level(DFDwarf.Skill.DOCTORING) * 0.025
					if has_alcohol:
						treatment_quality += 0.05
					patient.pathogen_exposure = maxf(0.0, patient.pathogen_exposure - treatment_quality)
					patient.infection_chance = patient.pathogen_exposure
					patient.disease_severity = maxf(0.05, patient.disease_severity - treatment_quality * 0.50)
					patient.recovery_streak += 30 + get_skill_level(DFDwarf.Skill.DOCTORING) * 10
					patient.add_thought("Recibió cuidados que mejoraron sus posibilidades de recuperación.", 0.05)
					wounds_treated += 1
				
				# Restore health partially
				patient.health = minf(1.0, patient.health + 0.15 + get_skill_level(DFDwarf.Skill.DOCTORING) * 0.05)
				patient.needs_display_update = true
				
				# Clear medical rest if fully healed
				var still_needs_attention = patient.health < 0.9 or patient.disease_severity >= 0.20
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

	if success:
		add_skill_xp(job_skill, 5)
		if current_job != null:
			current_job.state = DFJob.JobState.COMPLETED
			current_job = null
		needs_display_update = true
		add_thought("Completó satisfactoriamente un trabajo.", 0.03)
		current_task = "idle"
	elif current_job != null:
		if _job_requires_physical_progress(current_job.job_type):
			_cancel_current_job("el destino ya no admite este trabajo")
		elif current_job.state != DFJob.JobState.IN_PROGRESS:
			_cancel_current_job("no se pudo completar la acción")

func _execute_empty_latrine_job(world: Object) -> bool:
	var target_latrine = null
	for building in world.buildings:
		if building.type == DFBuilding.BuildingType.LATRINE and building.tile_pos == current_job.tile_pos:
			target_latrine = building
			break
	if target_latrine == null:
		return false
	var removed: float = target_latrine.remove_sanitation_waste(4.0)
	if removed <= 0.0:
		return true
	var disposal_pos: Vector3i = current_job.disposal_pos
	if disposal_pos.x < 0:
		disposal_pos = tile_pos
	world.add_splatter_substance(disposal_pos, "compost", removed)
	current_task = "Transportando residuos al compostaje"
	fatigue = minf(1.0, fatigue + 0.01)
	add_thought("Mantuvo utilizable una instalación sanitaria.", 0.03)
	return true

func _pick_up_job(world, jobs: Array) -> void:
	var best_job: DFJob = null
	var best_score = -9999
	var best_dist = 9999

	# Priorizar talar antes de recoger madera si hay árboles marcados cerca (distancia <= 15)
	var has_nearby_chop = false
	if profession == Profession.WOODCUTTER:
		for pj in jobs:
			if pj.state == DFJob.JobState.UNASSIGNED and pj.job_type == DFJob.JobType.CHOP_TREE:
				var d_chop = abs(tile_pos.x - pj.tile_pos.x) + abs(tile_pos.z - pj.tile_pos.z) + abs(tile_pos.y - pj.tile_pos.y) * 2
				if d_chop <= 15:
					has_nearby_chop = true
					break

	for j in jobs:
		if j.state != DFJob.JobState.UNASSIGNED:
			continue
			
		# Restricción estricta de profesión
		if j.job_type == DFJob.JobType.CHOP_TREE and profession != Profession.WOODCUTTER:
			continue
		if j.job_type == DFJob.JobType.DIG and profession != Profession.MINER:
			continue
		if j.job_type == DFJob.JobType.HUNT and profession != Profession.HUNTER:
			continue
		if j.job_type == DFJob.JobType.FISH and profession != Profession.FISHER and profession != Profession.COOK and profession != Profession.FARMER and profession != Profession.HUNTER:
			continue
		if j.job_type == DFJob.JobType.COOK_FOOD and profession != Profession.COOK:
			continue
		if j.job_type == DFJob.JobType.BREW_DRINK and profession != Profession.COOK and profession != Profession.BREWER:
			continue
		if j.job_type == DFJob.JobType.SMELT_ORE and profession != Profession.SMITH:
			continue
		if j.job_type == DFJob.JobType.MAKE_CHARCOAL and profession != Profession.SMITH and profession != Profession.WOODCUTTER:
			continue
		if j.job_type == DFJob.JobType.PROCESS_PLANT and profession != Profession.FARMER:
			continue
		if j.job_type == DFJob.JobType.TAN_HIDE and profession != Profession.HUNTER and profession != Profession.COOK and profession != Profession.CARPENTER:
			continue
		if j.job_type == DFJob.JobType.SPIN_THREAD and profession != Profession.FARMER and profession != Profession.CRAFTSMAN:
			continue
		if j.job_type == DFJob.JobType.STORE_IN_CONTAINER:
			pass  # Todos pueden guardar comida en almacenes
			
		# Si hay árboles cerca para cortar, ignorar otros tipos de trabajo
		if has_nearby_chop and j.job_type != DFJob.JobType.CHOP_TREE:
			continue

		# Verificar si tenemos la herramienta requerida para el trabajo
		if not _has_tool_for_job(j.job_type):
			var tool_substring = "Pickaxe" if j.job_type == DFJob.JobType.DIG else "Axe" if j.job_type == DFJob.JobType.CHOP_TREE else "Caña" if j.job_type == DFJob.JobType.FISH else "Sword"
			var target_tool = _find_nearest_item_on_ground_matching(world, tool_substring)
			if target_tool != null:
				# Ir a recoger la herramienta primero
				_move_toward(world, target_tool.tile_pos)
				current_task = "Buscando herramienta: " + target_tool.name
				var dist_to_tool = abs(tile_pos.x - target_tool.tile_pos.x) + abs(tile_pos.z - target_tool.tile_pos.z)
				if dist_to_tool <= 1:
					inventory.append(target_tool)
					world.remove_entity(target_tool)
					add_thought("Recogió un " + target_tool.name + " para empezar a trabajar.", 0.01)
				return
			else:
				# Si no hay herramienta ni en inventario ni en el suelo, ignorar el trabajo
				continue
				
		var dist = abs(tile_pos.x - j.tile_pos.x) + abs(tile_pos.z - j.tile_pos.z) + abs(tile_pos.y - j.tile_pos.y) * 2
		var skill_level = get_skill_level(j.get_required_skill())
		var skill_bonus = skill_level * 5
		var dist_penalty = int(dist)
		var score = skill_bonus - dist_penalty
		if score > best_score:
			best_score = score
			best_job = j
			best_dist = dist

	if best_job != null:
		assign_job(best_job)
		current_task = best_job.get_description()

func _path_request_slot_is_due(world) -> bool:
	if is_possessed:
		return true
	if has_meta("is_follower") and bool(get_meta("is_follower", false)):
		return true
	var global_tick: int = int(world.get_meta("simulation_tick_total", 0))
	return posmod(id, PATH_REQUEST_BUCKETS) == posmod(global_tick, PATH_REQUEST_BUCKETS)

func _move_toward(world, target: Vector3i) -> void:
	var effective_speed = speed * (1.0 - fatigue_level * 0.2)
	var carried_ratio: float = get_carried_weight() / maxf(1.0, get_carrying_capacity())
	if carried_ratio > 1.0:
		effective_speed *= maxf(0.25, 1.0 / carried_ratio)
		fatigue = minf(1.25, fatigue + 0.0005 * carried_ratio)
	effective_speed = maxf(0.3, effective_speed)

	# A* era solicitado por todos los habitantes en el mismo fotograma al cambiar
	# de tarea. Los cálculos iniciales se distribuyen; posesión y seguidores
	# mantienen respuesta inmediata. Esta comprobación ocurre antes del temporizador
	# de movimiento para garantizar un turno de ruta en un máximo de tres ticks.
	var needs_new_path: bool = path.is_empty() or path_index >= path.size()
	if needs_new_path and not _path_request_slot_is_due(world):
		return

	# Only move every N ticks: faster dwarves = more frequent moves
	if move_tick_counter > 0:
		move_tick_counter -= 1
		return
	move_tick_counter = ceil(2.0 / effective_speed)

	if tile_pos == last_pos:
		stuck_counter += 1
	else:
		stuck_counter = 0
		path_replan_count = 0
	last_pos = tile_pos
	if stuck_counter > 5:
		# Un atasco corto suele ser tráfico entre habitantes. Primero se invalida
		# la ruta y se vuelve a intentar; recién después de tres rutas fallidas se
		# abandona la acción con una causa trazable.
		path.clear()
		path_index = 0
		stuck_counter = 0
		path_replan_count += 1
		if path_replan_count < 3:
			current_task = "Buscando una ruta alternativa"
			return
		path_replan_count = 0
		if preferred_bed.x >= 0 and target == preferred_bed:
			preferred_bed = Vector3i(-1, -1, -1)
			claimed_bed = Vector3i(-1, -1, -1)
			is_sleeping = true
			current_task = "Durmiendo sin cama"
			return
		var abandoned_job: bool = current_job != null
		var abandoned_workshop: bool = operating_workshop != null
		var abandoned_plan: bool = not autonomous_plan.is_empty()
		if abandoned_job:
			_cancel_current_job("ruta bloqueada después de tres intentos")
		if abandoned_workshop:
			operating_workshop.unassign_dwarf()
			operating_workshop = null
		if abandoned_plan:
			DFAutonomousPlan.fail_step(autonomous_plan, "Ruta bloqueada después de tres intentos")
		if not abandoned_job and not abandoned_workshop and not abandoned_plan:
			current_task = "Sin ruta accesible"
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
		# Consulta espacial O(1). El barrido anterior de todas las entidades por
		# cada paso convertía una aldea concurrida en trabajo cuadrático.
		var blocked_by_entity: bool = world.is_actor_occupied(next_step, self)
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
				var alt_blocked: bool = world.is_actor_occupied(alt, self)
				if not alt_blocked:
					world.move_entity(self, alt)
					# El desvío cambió el origen real: la ruta anterior ya no es
					# válida y debe recalcularse desde esta nueva casilla.
					path.clear()
					path_index = 0
					path_replan_count = 0
					has_moved_this_tick = true
					stats_tracker["distance_traveled"] += 1
					found_alt = true
					break
			if not found_alt:
				return
		else:
			world.move_entity(self, next_step)
			# Fatigue from movement
			fatigue_level = minf(1.0, fatigue_level + 0.002)
		path_index += 1
		has_moved_this_tick = true
		stats_tracker["distance_traveled"] += 1

func get_display_char() -> String:
	if is_possessed:
		return "@"
	if current_job != null and task_progress > 0:
		return "&"
	if is_sleeping:
		return "z"
	if mood == MoodState.BESERK or mood == MoodState.TANTRUM:
		return "!"
	return "@"

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
	return Color("#88CCFF") if gender == "Male" else Color("#FF88CC")

func get_needs_string() -> String:
	var hunger_pct = int(hunger * 100)
	var thirst_pct = int(thirst * 100)
	var health_pct = int(health * 100)
	var fatigue_pct = int(fatigue * 100)
	var result = "H:%d%% S:%d%% V:%d%% I:%d%% " % [
		hunger_pct, thirst_pct, int(bladder_fill * 100), int(bowel_fill * 100)
	]
	if is_pregnant:
		result += "EMBARAZADA! "
	if disease_phase == DiseasePhase.SYMPTOMATIC:
		result += get_disease_status()
	elif disease_phase == DiseasePhase.RECOVERING:
		result += "Recuperándose"
	elif health_pct < 30:
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
	for e in world.dwarves:
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
	for e in world.dwarves:
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
	for e in world.dwarves:
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
	var pending: Array = world.get_meta("_pending_births", null)
	if pending != null:
		pending.append(child)
	else:
		world.add_entity(child)
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
	for e in world.dwarves:
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
	if current_job != null:
		return current_job.get_description()
	if current_task == "idle" or current_task == "":
		var titles = ["Descansando", "Ocioso", "Disponible", "Sin tarea"]
		var moods = {
			MoodState.TANTRUM: " furioso", MoodState.BESERK: " berserker",
			MoodState.MELANCHOLY: " melancólico", MoodState.STRANGE_MOOD: " inspirado",
			MoodState.FELL_MOOD: " siniestro", MoodState.MACABRE_MOOD: " macabro",
			MoodState.SECRETIVE_MOOD: " secreto"
		}
		var mood_suffix = moods.get(mood, "")
		return "%s%s" % [titles[randi() % titles.size()], mood_suffix]
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

func _workshop_item_matches(item: DFItem, requirement: Dictionary) -> bool:
	if item == null or item.is_decayed or item.is_inside_container:
		return false
	var item_type_lower: String = item.item_type.to_lower()
	var material_lower: String = item.material_name.to_lower()
	if bool(requirement.get("fuel", false)):
		return item_type_lower in ["fuel", "charcoal", "coal", "coal_ore", "wood"]
	var required_type: String = str(requirement.get("type", "")).to_lower()
	if not required_type.is_empty() and item_type_lower != required_type:
		return false
	var materials: Array = requirement.get("material", [])
	if not materials.is_empty():
		var material_ok: bool = false
		for candidate in materials:
			var candidate_lower: String = str(candidate).to_lower()
			if candidate_lower == material_lower or candidate_lower == item_type_lower or item_type_lower.begins_with(candidate_lower + "_"):
				material_ok = true
				break
		if not material_ok:
			return false
	var specifics: Array = requirement.get("specific", [])
	if not specifics.is_empty():
		var specific_ok: bool = false
		for candidate in specifics:
			var candidate_lower: String = str(candidate).to_lower()
			if candidate_lower in item_type_lower or candidate_lower in material_lower or candidate_lower in item.name.to_lower():
				specific_ok = true
				break
		if not specific_ok:
			return false
	return true

func _prepare_workshop_inputs(world, recipe: Dictionary) -> bool:
	var selected_indices: Array[int] = []
	var missing_requirement: Dictionary = {}
	for requirement in recipe.get("inputs", []):
		var required_count: int = int(requirement.get("count", 1))
		var matched_count: int = 0
		for inventory_index in range(inventory.size()):
			if inventory_index in selected_indices:
				continue
			var inventory_item = inventory[inventory_index]
			if not inventory_item is DFItem:
				continue
			if _workshop_item_matches(inventory_item, requirement):
				selected_indices.append(inventory_index)
				matched_count += 1
				if matched_count >= required_count:
					break
		if matched_count < required_count and not bool(requirement.get("optional", false)):
			missing_requirement = requirement
			break

	if not missing_requirement.is_empty():
		var nearest_item: DFItem = null
		var nearest_distance: int = 999999
		for ground_item in world.items:
			if ground_item.carried_by_id >= 0:
				continue
			if not _workshop_item_matches(ground_item, missing_requirement):
				continue
			if ground_item.is_reserved_for_other(id, simulation_minute):
				continue
			var ground_distance: int = abs(ground_item.tile_pos.x - tile_pos.x) + abs(ground_item.tile_pos.z - tile_pos.z) + abs(ground_item.tile_pos.y - tile_pos.y) * 2
			if ground_distance < nearest_distance:
				nearest_distance = ground_distance
				nearest_item = ground_item
		if nearest_item == null:
			current_task = "Esperando insumos para %s" % str(recipe.get("name", "el taller"))
			return false
		nearest_item.reserve_for(id, simulation_minute + 30)
		if nearest_distance <= 1:
			nearest_item.release_reservation(id)
			nearest_item.carried_by_id = id
			world.remove_entity(nearest_item)
			inventory.append(nearest_item)
			current_task = "Llevando insumo a %s" % operating_workshop.name
		else:
			current_task = "Recogiendo insumo para %s" % operating_workshop.name
			_move_toward(world, nearest_item.tile_pos)
		return false

	selected_indices.sort()
	selected_indices.reverse()
	for inventory_index in selected_indices:
		inventory.remove_at(inventory_index)
	operating_workshop.current_recipe = recipe.duplicate(true)
	needs_display_update = true
	return true

func _produce_workshop_outputs(world, recipe: Dictionary) -> void:
	for output in recipe.get("outputs", []):
		if bool(output.get("optional", false)):
			continue
		var output_count: int = int(output.get("count", 1))
		for output_index in range(output_count):
			var produced: DFItem = world._spawn_item(
				operating_workshop.tile_pos,
				str(output.get("name", "Producto")),
				str(output.get("type", "craft")),
				0,
				"*",
				Color("#FFD27F")
			)
			produced.created_by_entity_id = id
			produced.production_recipe_id = str(recipe.get("id", ""))
			produced.production_site = operating_workshop.tile_pos
	stats_tracker["items_crafted"] = int(stats_tracker.get("items_crafted", 0)) + 1
	add_thought("Fabricó %s usando insumos reales." % str(recipe.get("name", "un objeto")), 0.04)

func _workshop_skill_from_recipe(recipe: Dictionary) -> int:
	match str(recipe.get("skill", "CRAFTSMAN")).to_upper():
		"MINING": return Skill.MINING
		"CARPENTRY": return Skill.CARPENTRY
		"MASONRY": return Skill.MASONRY
		"SMITHING": return Skill.SMITHING
		"COOKING": return Skill.COOKING
		"BREWING": return Skill.BREWING
		"FARMING": return Skill.FARMING
		"WEAVING": return Skill.MECHANICS
		_: return Skill.CRAFTSMAN

func _operate_workshop(world) -> void:
	if is_possessed:
		return
	if operating_workshop == null:
		return

	if hunger > 0.6 or thirst > 0.6 or fatigue > 0.8:
		operating_workshop.unassign_dwarf()
		operating_workshop = null
		current_task = "idle"
		return

	if operating_workshop.production_queue.is_empty():
		operating_workshop.unassign_dwarf()
		operating_workshop = null
		current_task = "idle"
		return

	var dist: int = abs(tile_pos.x - operating_workshop.tile_pos.x) + abs(tile_pos.z - operating_workshop.tile_pos.z)
	if dist > 1 or tile_pos.y != operating_workshop.tile_pos.y:
		current_task = "Yendo a " + operating_workshop.name
		_move_toward(world, operating_workshop.tile_pos)
		return

	var recipe: Dictionary = operating_workshop.production_queue[0]
	if operating_workshop.current_recipe.is_empty() and not _prepare_workshop_inputs(world, recipe):
		return

	current_task = "Fabricando %s en %s" % [str(recipe.get("name", "producto")), operating_workshop.name]
	var skill_id: int = _workshop_skill_from_recipe(recipe)
	var operator_level: int = get_skill_level(skill_id)
	operating_workshop.operator_skill = operator_level
	var result: Dictionary = operating_workshop.tick(1.0)
	if bool(result.get("completed", false)):
		var completed_recipe: Dictionary = result.get("recipe", {})
		_produce_workshop_outputs(world, completed_recipe)
		add_skill_xp(skill_id, 8)
		if operating_workshop.production_queue.is_empty():
			operating_workshop.unassign_dwarf()
			operating_workshop = null
			current_task = "idle"

func _check_workshops(world) -> void:
	if is_possessed or operating_workshop != null:
		return
	var best_w = null
	var best_dist = 9999
	for w in world.workshops:
		if w.dwarf_assigned < 0 and not w.production_queue.is_empty():
			var d = abs(tile_pos.x - w.tile_pos.x) + abs(tile_pos.z - w.tile_pos.z) + abs(tile_pos.y - w.tile_pos.y) * 2
			if d < best_dist:
				best_dist = d
				best_w = w

	if best_w != null:
		operating_workshop = best_w
		var ws_skill = get_skill_level(Skill.SMITHING)
		best_w.assign_dwarf(id, ws_skill)
		current_task = "Yendo a " + best_w.name

func _consume_inventory_material(kw: String) -> void:
	for item in inventory:
		if kw in item.name.lower():
			inventory.erase(item)
			return

func tick_autonomous_survival(world) -> void:
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
					for e in world.get_items_at(stock_tile):
						if e.get("item_type") in ["food", "drink", "seed"]:
							var d = abs(e.tile_pos.x - tile_pos.x) + abs(e.tile_pos.z - tile_pos.z)
							if d < nearest_dist:
								nearest_dist = d
								nearest_food = e
		for e_2770 in world.items:
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
					world.remove_entity(nearest_food)
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
	
	# 1. Talar arboles de forma autonoma (si tiene hacha)
	var has_axe = "axe" in equipped_weapon.to_lower()
	if not has_axe:
		for inv_item in inventory:
			if "Axe" in inv_item.name:
				has_axe = true
				break
	if has_axe:
		var nearest_tree = _find_nearest_tree(world)
		if nearest_tree.x >= 0:
			var dist_tree = abs(tile_pos.x - nearest_tree.x) + abs(tile_pos.z - nearest_tree.z)
			if dist_tree <= 1:
				current_task = "Talar arbol (auto)"
				world.chop_tree(nearest_tree, tile_pos)
				add_thought("Tale un arbol por mi cuenta.", 0.05)
				return
			else:
				current_task = "Yendo a talar arbol"
				_move_toward(world, nearest_tree)
				return

	# 2. Picar piedra/carbon de forma autonoma (si tiene pico)
	var has_pickaxe = "pickaxe" in equipped_weapon.to_lower()
	if not has_pickaxe:
		for inv_item_2843 in inventory:
			if "Pickaxe" in inv_item_2843.name:
				has_pickaxe = true
				break
	if has_pickaxe:
		var nearest_wall = _find_nearest_mineable_wall(world)
		if nearest_wall.x >= 0:
			var dist_wall = abs(tile_pos.x - nearest_wall.x) + abs(tile_pos.z - nearest_wall.z)
			if dist_wall <= 1:
				current_task = "Picar piedra (auto)"
				world.dig_tile(nearest_wall)
				add_thought("Pique roca por mi cuenta.", 0.05)
				return
			else:
				current_task = "Yendo a picar piedra"
				_move_toward(world, nearest_wall)
				return

	# 3. Encender fogata y cocinar con varillas (si hay recursos y no hay fogata activa)
	var has_campfire = false
	for bld in world.buildings:
		if bld.type == 19: # 19 = BuildingType.CAMPFIRE
			has_campfire = true
			break
			
	if not has_campfire:
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
			var plaza_pos = Vector3i(128, tile_pos.y, 128)
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
						world.remove_entity(target_fuel)
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
						world.remove_entity(target_food)
					else:
						_move_toward(world, target_food.tile_pos)
					return

	# Si no hay nada que hacer, estudiar o buscar maestros (Curiosidad) antes de merodear
	var is_sleep_time_survival = game_hour >= 22.0 or game_hour < 5.0
	if not is_sleep_time_survival:
		if preferred_study_skill < 0:
			preferred_study_skill = randi() % 7
			
		var master = _find_nearby_master_for_skill(world, preferred_study_skill)
		if master != null:
			var dist_2939 = abs(tile_pos.x - master.tile_pos.x) + abs(tile_pos.z - master.tile_pos.z)
			if dist_2939 > 1:
				_move_toward(world, master.tile_pos)
				current_task = "Siguiendo a %s (Aprendiz)" % master.name
			else:
				current_task = "Estudiando de %s" % master.name
				add_skill_xp(preferred_study_skill, 5)
				if randf() < 0.02:
					add_thought("Aprendió técnicas avanzadas observando a %s." % master.name, 0.02)
					if get_skill_level(preferred_study_skill) >= master.get_skill_level(preferred_study_skill):
						preferred_study_skill = -1
			return
		else:
			# Estudiar de forma autodidacta en su cabaña
			if preferred_bed.x >= 0:
				var dist_2954 = abs(tile_pos.x - preferred_bed.x) + abs(tile_pos.z - preferred_bed.z)
				if dist_2954 > 0:
					_move_toward(world, preferred_bed)
					current_task = "Yendo a su cabaña a estudiar"
				else:
					current_task = "Estudiando de forma autodidacta"
					add_skill_xp(preferred_study_skill, 1)
				return

	# Si no se puede hacer nada de lo anterior, merodear libremente
	_idle_wander(world)


func _has_tool_for_job(job_type: int) -> bool:
	if job_type == DFJob.JobType.DIG:
		if "pickaxe" in equipped_weapon.to_lower():
			return true
		for item in inventory:
			if "Pickaxe" in item.name:
				return true
		return false
	elif job_type == DFJob.JobType.CHOP_TREE:
		if "axe" in equipped_weapon.to_lower():
			return true
		for item_2978 in inventory:
			if "Axe" in item_2978.name:
				return true
		return false
	elif job_type == DFJob.JobType.HUNT:
		if equipped_weapon != "" and equipped_weapon != "none":
			return true
		for item_2985 in inventory:
			var iname = item_2985.name.to_lower()
			if "sword" in iname or "axe" in iname or "spear" in iname or "bow" in iname or "crossbow" in iname or "mace" in iname or "knife" in iname or "dagger" in iname or "pickaxe" in iname:
				return true
		return false
	elif job_type == DFJob.JobType.FISH:
		return true
	return true

func _find_nearest_item_on_ground_matching(world, item_substring: String):
	var nearest_item = null
	var nearest_dist = 9999.0
	for e in world.items:
		if e is DFItem and item_substring in e.name:
			var d = abs(tile_pos.x - e.tile_pos.x) + abs(tile_pos.z - e.tile_pos.z)
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
	for e in world.items:
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

	current_job = null
	operating_workshop = null

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
	var mat_names = ["GRANITE", "LIMESTONE", "IRON", "GOLD", "SILVER", "COPPER", "WOOD", "OBSIDIAN", "MARBLE"]
	var art_types = ["weapon", "armor", "furniture", "toy", "instrument", "craft"]
	var mood_mat_prefs = {
		StrangeMoodType.FEY: ["GOLD", "SILVER", "MARBLE", "OBSIDIAN"],
		StrangeMoodType.POSSESSED: mat_names,
		StrangeMoodType.MACABRE: ["BONE", "SKULL", "WOOD", "OBSIDIAN"],
		StrangeMoodType.FELL: ["BONE", "SKULL", "IRON", "OBSIDIAN"],
		StrangeMoodType.SECRETIVE: ["WOOD", "COPPER", "IRON", "GRANITE"]
	}
	var type_prefs = {
		StrangeMoodType.FEY: ["weapon", "armor", "instrument", "craft"],
		StrangeMoodType.POSSESSED: art_types,
		StrangeMoodType.MACABRE: ["weapon", "armor", "furniture", "craft"],
		StrangeMoodType.FELL: ["weapon", "armor", "craft"],
		StrangeMoodType.SECRETIVE: ["furniture", "toy", "craft", "instrument"]
	}

	var prefs = mood_mat_prefs.get(strange_mood_type, mat_names)
	strange_mood_artifact_material = randi() % prefs.size()
	var type_pref_list = type_prefs.get(strange_mood_type, art_types)
	strange_mood_artifact_type = type_pref_list[randi() % type_pref_list.size()]

	var num_materials = 1 + randi() % 3
	for i in range(num_materials):
		var mat = prefs[randi() % prefs.size()]
		strange_mood_materials_needed[mat] = strange_mood_materials_needed.get(mat, 0) + (1 + randi() % 2)

	var artifact_prefixes = ["Aethel", "Baron", "Crystal", "Dawn", "Ebony", "Frost", "Glimmer", "Iron",
		"Kings", "Lunar", "Mithril", "Night", "Onyx", "Phoenix", "Quartz", "Royal",
		"Shadow", "Silver", "Thunder", "Ursa", "Valor", "Wyrm", "Xen", "Zephyr"]
	var artifact_suffixes = ["Heart", "Blade", "Crown", "Dream", "Eye", "Flame", "Gift", "Hammer",
		"Hope", "Justice", "Key", "Light", "Memory", "Oath", "Peace", "Quest",
		"Reign", "Shield", "Song", "Star", "Tears", "Union", "Vision", "Wings"]
	strange_mood_artifact_name = "%s %s" % [artifact_prefixes[randi() % artifact_prefixes.size()], artifact_suffixes[randi() % artifact_suffixes.size()]]

func _process_strange_mood(world) -> void:
	if not is_alive:
		mood = MoodState.NORMAL
		return

	current_job = null
	operating_workshop = null
	mood_counter -= 1

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
	var found_tile = _find_nearby_open_tile(world)
	if found_tile.x >= 0:
		var dist = abs(tile_pos.x - found_tile.x) + abs(tile_pos.z - found_tile.z)
		if dist <= 1:
			strange_mood_workshop_pos = found_tile
			var improvised = DFWorkshop.new(1, found_tile)
			improvised.name = "Taller improvisado"
			world.workshops.append(improvised)
			strange_mood_workshop_ref = improvised
			strange_mood_phase = StrangeMoodPhase.CLAIMED_WORKSHOP
			world.messages.append("%s construye un taller improvisado en su desesperación!" % name)
		else:
			_move_toward(world, found_tile)
			current_task = "Buscando lugar para taller"
	else:
		mood_counter -= 10

func _find_nearby_open_tile(world) -> Vector3i:
	for dz in range(-8, 9):
		for dx in range(-8, 9):
			var pos = Vector3i(tile_pos.x + dx, tile_pos.y, tile_pos.z + dz)
			if pos.x < 1 or pos.x >= world.width - 1 or pos.z < 1 or pos.z >= world.depth - 1:
				continue
			if not world.is_blocked(pos) and not world.is_water(pos):
				return pos
	return Vector3i(-1, -1, -1)

func _gather_mood_materials(world) -> void:
	if strange_mood_materials_needed.is_empty():
		strange_mood_phase = StrangeMoodPhase.WORKING
		return

	var all_gathered = true
	for mat in strange_mood_materials_needed:
		var needed = strange_mood_materials_needed[mat]
		var gathered = strange_mood_materials_gathered.get(mat, 0)
		if gathered < needed:
			all_gathered = false
			break

	if all_gathered:
		strange_mood_phase = StrangeMoodPhase.WORKING
		world.messages.append("%s tiene todos los materiales. ¡Comienza a trabajar!" % name)
		return

	for mat_3287 in strange_mood_materials_needed:
		var needed_3288 = strange_mood_materials_needed[mat_3287]
		var gathered_3289 = strange_mood_materials_gathered.get(mat_3287, 0)
		if gathered_3289 >= needed_3288:
			continue

		var found = _find_material_on_ground(world, mat_3287)
		if found != null:
			var dist = abs(tile_pos.x - found.tile_pos.x) + abs(tile_pos.z - found.tile_pos.z)
			if dist <= 1:
				strange_mood_materials_gathered[mat_3287] = gathered_3289 + 1
				world.remove_entity(found)
				current_task = "Recogió %s para su obra" % mat_3287
				needs_display_update = true
				return
			else:
				_move_toward(world, found.tile_pos)
				current_task = "Buscando %s" % mat_3287
				return
		else:
			for inv_item in inventory:
				if mat_3287.to_lower() in inv_item.name.to_lower() or mat_3287.to_lower() in inv_item.item_type.to_lower():
					strange_mood_materials_gathered[mat_3287] = gathered_3289 + 1
					inventory.erase(inv_item)
					current_task = "Usó %s de su inventario" % inv_item.name
					needs_display_update = true
					return

			mood_counter -= 5
			if randf() < 0.05:
				world.messages.append("%s está desesperado, no encuentra %s para su obra!" % [name, mat_3287])
			return

func _find_material_on_ground(world, mat_id: String) -> Object:
	var found = null
	var best_dist = 9999
	for e in world.items:
		if e is DFItem and e.get("item_type") != null:
			var name_lower = e.name.to_lower()
			var type_lower = e.item_type.to_lower()
			var mat_lower = mat_id.to_lower()
			# DFItem es un RefCounted, no un Dictionary: Object.get() solo recibe
			# el nombre de la propiedad y no acepta un segundo valor por defecto.
			var e_mat_name: String = e.material_name.to_lower()
			if mat_lower in name_lower or mat_lower in type_lower or mat_lower == e_mat_name:
				var d = abs(e.tile_pos.x - tile_pos.x) + abs(e.tile_pos.z - tile_pos.z)
				if d < best_dist:
					best_dist = d
					found = e
	return found

func _work_on_artifact(world) -> void:
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

	world.add_entity(artifact_item)
	world.messages.append("¡¡ %s ha creado '%s' !!" % [name, strange_mood_artifact_name])
	add_thought("¡Ha creado el artefacto '%s'! Su nombre será recordado por siempre." % strange_mood_artifact_name, happy_bonus)
	artistic_inspiration = 0.0
	mood = MoodState.NORMAL
	strange_mood_phase = StrangeMoodPhase.IDLE
	stress = 0.0
	happiness = minf(1.0, happiness + happy_bonus)

	if strange_mood_type == StrangeMoodType.FELL:
		world.messages.append("Un escalofrío recorre la fortaleza. El artefacto '%s' tiene un aura oscura..." % strange_mood_artifact_name)

	for e in world.dwarves:
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
	if hunting_target != null and hunting_target.get("is_alive") == true:
		var d = abs(tile_pos.x - hunting_target.tile_pos.x) + abs(tile_pos.z - hunting_target.tile_pos.z)
		if d <= 30:
			current_task = "Cazando " + str(hunting_target.get("name"))
			needs_display_update = true
			return true
	var target_creature_id = current_job.get_meta("creature_id", -1)
	var target = null
	for e in world.creatures:
		if e.get("id") == target_creature_id and e.get("is_alive") == true:
			target = e
			break
	if target == null:
		for e_3419 in world.creatures:
			if e_3419.get("creature_type") != null and e_3419.get("creature_type") != "dwarf" and e_3419.get("is_alive") == true:
				var dist = abs(tile_pos.x - e_3419.tile_pos.x) + abs(tile_pos.z - e_3419.tile_pos.z)
				if dist <= 20:
					target = e_3419
					break
	if target == null:
		return false
	hunting_target = target
	var target_name: String = str(target.get("name"))
	if target_name.is_empty():
		target_name = "presa"
	current_task = "Saliendo a cazar " + target_name
	add_thought("Salió a cazar " + target_name, 0.05)
	needs_display_update = true
	return true

func _execute_fish_job(world) -> bool:
	if current_job == null:
		return false
	var dist = abs(tile_pos.x - current_job.tile_pos.x) + abs(tile_pos.z - current_job.tile_pos.z)
	if not world.is_water(current_job.tile_pos):
		current_task = "Buscando agua"
		return false
	if dist > 1:
		current_task = "Yendo a pescar"
		_move_toward(world, current_job.tile_pos)
		if current_job != null: current_job.state = DFJob.JobState.IN_PROGRESS
		return false
	if tile_pos == current_job.tile_pos:
		var land_adjacent = _find_adjacent_land_tile(world, current_job.tile_pos)
		if land_adjacent.x >= 0:
			_move_toward(world, land_adjacent)
			current_task = "Yendo a la orilla"
			if current_job != null: current_job.state = DFJob.JobState.IN_PROGRESS
			return false
		return false
	current_task = "Pescando"
	var fish_skill = get_skill_level(Skill.FISHING)
	var catch_chance = 0.12 + fish_skill * 0.04
	if randf() < catch_chance:
		var fish_variants = ["Trucha", "Salm?n", "Carpa", "Perca", "Bagre", "Anguila"]
		if fish_skill >= 4: fish_variants.append_array(["Esturi?n", "Pez Luna"])
		var fish_name = fish_variants[randi() % fish_variants.size()]
		var fish_size = 1 + (1 if fish_skill >= 2 else 0) + (1 if fish_skill >= 4 else 0)
		for f_i in range(fish_size):
			var fish_item = world._spawn_item(tile_pos, fish_name + " Crudo", "food", 0, "%", Color("#4488CC"))
			fish_item.nutrition = 0.5 + fish_skill * 0.03
			fish_item.is_edible = true
			inventory.append(fish_item)
		stats_tracker["fish_caught"] = stats_tracker.get("fish_caught", 0) + fish_size
		add_thought("Atrap? " + str(fish_size) + " " + fish_name + "(s) fresco(s).", 0.06 + fish_skill * 0.005)
		needs_display_update = true
		return true
	return false

func _find_adjacent_land_tile(world, water_pos: Vector3i) -> Vector3i:
	for adj_dz in range(-1, 2):
		for adj_dx in range(-1, 2):
			if adj_dx == 0 and adj_dz == 0: continue
			var adj = Vector3i(water_pos.x + adj_dx, water_pos.y, water_pos.z + adj_dz)
			if adj.x >= 0 and adj.x < world.width and adj.z >= 0 and adj.z < world.depth:
				if not world.is_water(adj) and not world.is_blocked(adj):
					return adj
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
		for e in world.items:
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
		world.remove_entity(to_erase)
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
		if current_job != null: current_job.state = DFJob.JobState.IN_PROGRESS
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
	inventory.append(meal)
	stats_tracker["food_cooked"] = stats_tracker.get("food_cooked", 0) + 1
	add_thought("Cocin? " + meal_name + " con maestr?a.", 0.08 + cook_skill * 0.01)
	needs_display_update = true
	return true

func _execute_brew_job(world) -> bool:
	if _move_to_workshop(world, DFWorkshop.WorkshopType.STILL):
		if current_job != null: current_job.state = DFJob.JobState.IN_PROGRESS
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
	inventory.append(drink)
	add_thought("Cervece? " + drink_name + " de primera calidad.", 0.07 + brew_skill * 0.005)
	needs_display_update = true
	return true

func _execute_smelt_job(world) -> bool:
	if _move_to_workshop(world, DFWorkshop.WorkshopType.SMELTER):
		if current_job != null: current_job.state = DFJob.JobState.IN_PROGRESS
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
		inventory.append(bar)
	add_thought("Fundi? " + str(bar_count) + " " + bar_name + "(s).", 0.06)
	needs_display_update = true
	return true

func _execute_make_charcoal_job(world) -> bool:
	if _move_to_workshop(world, DFWorkshop.WorkshopType.KILN):
		if current_job != null: current_job.state = DFJob.JobState.IN_PROGRESS
		return false
	var res = _find_best_item_slot(world, "wood")
	if not res[0]:
		return false
	var fuel_skill = get_skill_level(Skill.SMITHING)
	var coal_count = 1 + (1 if fuel_skill >= 2 else 0)
	for c_i in range(coal_count):
		var coal = world._spawn_item(tile_pos, "Carb?n Vegetal", "fuel", 0, "@", Color("#333333"))
		coal.is_edible = false
		inventory.append(coal)
	add_thought("Produjo " + str(coal_count) + " carb?n(es) vegetal(es).", 0.04)
	needs_display_update = true
	return true

func _execute_process_plant_job(world) -> bool:
	if _move_to_workshop(world, DFWorkshop.WorkshopType.LOOM):
		if current_job != null: current_job.state = DFJob.JobState.IN_PROGRESS
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
		inventory.append(fiber)
	add_thought("Proces? plantas en " + str(fiber_count) + " fibra(s).", 0.04)
	needs_display_update = true
	return true

func _execute_spin_thread_job(world) -> bool:
	if _move_to_workshop(world, DFWorkshop.WorkshopType.LOOM):
		if current_job != null: current_job.state = DFJob.JobState.IN_PROGRESS
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
		inventory.append(thread)
	add_thought("Hil? " + str(thread_count) + " hilo(s) de fibra.", 0.04)
	needs_display_update = true
	return true

func _execute_tan_hide_job(world) -> bool:
	if _move_to_workshop(world, DFWorkshop.WorkshopType.TANNER):
		if current_job != null: current_job.state = DFJob.JobState.IN_PROGRESS
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
		inventory.append(leather)
	add_thought("Curti? " + str(leather_count) + " cuero(s).", 0.05)
	needs_display_update = true
	return true

func _execute_store_in_container_job(world) -> bool:
	var carried_food = null
	for item in inventory:
		if item.is_food or item.is_meat or item.is_drink or item.item_type == "fish":
			carried_food = item
			break
	var target_food = null
	var best_dist = 999999
	if carried_food == null:
		var requested_item_id: int = int(current_job.get_meta("target_item_id", -1)) if current_job != null else -1
		var current_tick: int = int(world.get_meta("simulation_tick_total", 0))
		for ent in world.items:
			if ent is DFItem and (ent.is_food or ent.is_meat or ent.is_drink or ent.item_type == "fish") and not ent.is_inside_container and not ent.is_decayed:
				if requested_item_id >= 0 and ent.id != requested_item_id:
					continue
				if ent.is_reserved_for_other(id, current_tick):
					continue
				var already_in_sp = false
				for sp in world.stockpiles:
					if sp.has_tile(ent.tile_pos):
						already_in_sp = true
						break
				if already_in_sp:
					continue
				var d = abs(ent.tile_pos.x - tile_pos.x) + abs(ent.tile_pos.z - tile_pos.z)
				if d < best_dist:
					best_dist = d
					target_food = ent
		if target_food != null:
			target_food.reserve_for(id, current_tick + 600)
	if carried_food == null and target_food != null:
		var dist = abs(tile_pos.x - target_food.tile_pos.x) + abs(tile_pos.z - target_food.tile_pos.z)
		if dist > 1:
			_move_toward(world, target_food.tile_pos)
			current_task = "Yendo a recoger comida"
			if current_job != null: current_job.state = DFJob.JobState.IN_PROGRESS
			return false
		_detach_item_from_container(world, target_food)
		inventory.append(target_food)
		target_food.carried_by_id = id
		target_food.is_in_stockpile = false
		world.remove_entity(target_food)
		needs_display_update = true
		current_task = "Recogiendo comida para almacenar"
		return false
	if carried_food == null:
		return false
	var best_fs_pos = Vector3i(-1, -1, -1)
	var best_fs_dist = 999999
	for b in world.buildings:
		if b.type == DFBuilding.BuildingType.FOOD_STORE:
			var container = _find_container_at(world, b.tile_pos)
			if container == null or not container.has_container_space(carried_food):
				continue
			var d_3722 = abs(b.tile_pos.x - tile_pos.x) + abs(b.tile_pos.z - tile_pos.z)
			if d_3722 < best_fs_dist:
				best_fs_dist = d_3722
				best_fs_pos = b.tile_pos
	if best_fs_pos.y == -1:
		current_task = "Esperando espacio de almacenamiento"
		return false
	var dist_to_fs = abs(tile_pos.x - best_fs_pos.x) + abs(tile_pos.z - best_fs_pos.z)
	if dist_to_fs > 1:
		_move_toward(world, best_fs_pos)
		current_task = "Llevando comida al almacén"
		if current_job != null: current_job.state = DFJob.JobState.IN_PROGRESS
		return false
	carried_food.tile_pos = best_fs_pos
	carried_food.is_in_stockpile = true
	carried_food.carried_by_id = -1
	if not _put_item_in_container_at(world, carried_food, best_fs_pos):
		# Otro transportista pudo llenar el cofre durante el trayecto. Se conserva
		# el objeto en el inventario y se busca otro destino en el siguiente tick.
		carried_food.carried_by_id = id
		carried_food.is_in_stockpile = false
		current_task = "Buscando otro cofre con espacio"
		return false
	carried_food.release_reservation(id)
	world.add_entity(carried_food)
	inventory.erase(carried_food)
	add_thought("Guardó " + carried_food.name + " en el almacén de comida.", 0.04)
	needs_display_update = true
	return true

func _find_container_at(world: Object, pos: Vector3i):
	for entity in world.items:
		if (
			entity is DFItem
			and entity.is_container
			and entity.tile_pos == pos
			and entity.contained_volume < entity.container_volume
		):
			return entity
	return null

func _detach_item_from_container(world: Object, item: DFItem) -> void:
	if not item.is_inside_container:
		return
	for entity in world.items:
		if entity is DFItem and entity.is_container and entity.id == item.container_id:
			entity.container_contents.erase(item)
			entity.contained_volume = maxf(
				0.0,
				entity.contained_volume - item.get_item_volume()
			)
			break
	item.remove_from_container()

func _put_item_in_container_at(world: Object, item: DFItem, pos: Vector3i) -> bool:
	item.is_inside_container = false
	item.container_id = -1
	var container = _find_container_at(world, pos)
	if container == null or not container.has_container_space(item):
		return false
	item.put_in_container(container)
	return true

func _execute_collect_job(world, item_type_to_collect: String) -> bool:
	var carried_item: DFItem = null
	for inventory_item in inventory:
		if inventory_item is DFItem and inventory_item.item_type == item_type_to_collect:
			carried_item = inventory_item
			break

	if carried_item == null:
		var has_storage_space: bool = false
		for capacity_stockpile in world.stockpiles:
			if capacity_stockpile.get_free_tile(world, item_type_to_collect).y != -1:
				has_storage_space = true
				break
		if not has_storage_space:
			_cancel_current_job("no hay espacio en ningún almacén")
			return false

		var target_item: DFItem = null
		var best_distance: int = 999999
		var current_tick: int = int(world.get_meta("simulation_tick_total", 0))
		for world_item in world.items:
			if not world_item is DFItem:
				continue
			if world_item.item_type != item_type_to_collect or world_item.is_inside_container:
				continue
			if world_item.is_decayed or world_item.carried_by_id >= 0:
				continue
			if world_item.is_reserved_for_other(id, current_tick):
				continue
			var already_stored: bool = false
			for occupied_stockpile in world.stockpiles:
				if occupied_stockpile.has_tile(world_item.tile_pos) and world_item.is_in_stockpile:
					already_stored = true
					break
			if already_stored:
				continue
			var item_distance: int = abs(world_item.tile_pos.x - tile_pos.x) + abs(world_item.tile_pos.z - tile_pos.z) + abs(world_item.tile_pos.y - tile_pos.y) * 2
			if item_distance < best_distance:
				best_distance = item_distance
				target_item = world_item

		if target_item == null:
			_cancel_current_job("ya no queda %s suelta para recoger" % item_type_to_collect)
			return false

		target_item.reserve_for(id, current_tick + 600)
		if best_distance > 1 or target_item.tile_pos.y != tile_pos.y:
			_move_toward(world, target_item.tile_pos)
			current_task = "Yendo a recoger " + target_item.name
			if current_job != null:
				current_job.state = DFJob.JobState.IN_PROGRESS
			return false

		target_item.release_reservation(id)
		target_item.carried_by_id = id
		target_item.is_in_stockpile = false
		world.remove_entity(target_item)
		inventory.append(target_item)
		add_thought("Recogió %s para almacenarlo." % target_item.name, 0.02)
		current_task = "Transportando " + target_item.name
		needs_display_update = true
		return false

	var target_stockpile = null
	var target_drop_pos: Vector3i = Vector3i(-1, -1, -1)
	var best_stockpile_distance: int = 999999
	for candidate_stockpile in world.stockpiles:
		var candidate_pos: Vector3i = candidate_stockpile.get_free_tile(world, carried_item.item_type)
		if candidate_pos.y == -1:
			continue
		var candidate_distance: int = abs(candidate_pos.x - tile_pos.x) + abs(candidate_pos.z - tile_pos.z) + abs(candidate_pos.y - tile_pos.y) * 2
		if candidate_distance < best_stockpile_distance:
			best_stockpile_distance = candidate_distance
			target_drop_pos = candidate_pos
			target_stockpile = candidate_stockpile

	if target_stockpile == null:
		current_task = "Esperando espacio para guardar " + carried_item.name
		return false

	if best_stockpile_distance > 1 or target_drop_pos.y != tile_pos.y:
		_move_toward(world, target_drop_pos)
		current_task = "Llevando " + carried_item.name + " al almacén"
		if current_job != null:
			current_job.state = DFJob.JobState.IN_PROGRESS
		return false

	carried_item.tile_pos = target_drop_pos
	carried_item.carried_by_id = -1
	carried_item.is_in_stockpile = true
	carried_item.release_reservation(id)
	var stored_in_container: bool = _put_item_in_container_at(world, carried_item, target_drop_pos)
	world.add_entity(carried_item)
	inventory.erase(carried_item)
	if stored_in_container:
		add_thought("Guardó %s dentro de un cofre." % carried_item.name, 0.05)
	else:
		add_thought("Apiló %s en el almacén." % carried_item.name, 0.03)
	current_task = "idle"
	needs_display_update = true
	return true

func _find_house_exterior_storage_pos(world) -> Vector3i:
	# Recopilar todas las posiciones de puertas
	var door_positions = []
	for ent in world.items:
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
					var has_item: bool = not world.get_items_at(p).is_empty()
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
				var plaza_pos = Vector3i(128, tile_pos.y, 128)
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
						world.remove_entity(target_fuel)
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
							world.add_entity(raw_meat_item)
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
		for ent1 in world.creatures:
			if ent1 == hunting_target:
				target_exists = true
				break
		if not target_exists or not hunting_target.get("is_alive"):
			# El target murió o desapareció, buscar si dejó un cadáver en su lugar para degollarlo
			if hunting_target != null:
				var corpse_found = null
				for ent2 in world.items:
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
						world.remove_entity(corpse_found)
						var raw_meat = world._spawn_item(tile_pos, "Carne Cruda de " + c_name, "food", 0, "%", Color("#FF5533"))
						raw_meat.nutrition = 0.5
						raw_meat.is_edible = true
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
		for ent3 in world.creatures:
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
