extends RefCounted
class_name DFCreature

const DFItem = preload("res://df_mode/df_item.gd")
const DFPathfinding = preload("res://df_mode/df_pathfinding.gd")
const CreatureBehaviorRules = preload("res://core/ecology/creature_behavior_rules.gd")
const CreatureDecisionRules = preload("res://core/ai/creature_decision_rules.gd")
const CombatMath = preload("res://core/combat/combat_math.gd")

enum AIState {
	IDLE, WANDER, SEEK_FOOD, SEEK_WATER, EAT, DRINK, SLEEP,
	HUNT, FLEE, ATTACK, GUARD, SOCIALIZE, MATE, FOLLOW,
	MIGRATE, INVESTIGATE, STALK, PATROL, PLAY, GROOM, TRAINED_GUARD
}

enum PersonalityType {
	PASSIVE, SKITTISH, NERVOUS, DOCILE, FRIENDLY,
	SOCIABLE, CURIOS, AGGRESSIVE, TERRITORIAL, WILD
}

enum CreatureSize { TINY, SMALL, MEDIUM, LARGE, GIANT, MEGA }

const SIGHT_RANGES = {
	CreatureSize.TINY: 3, CreatureSize.SMALL: 5, CreatureSize.MEDIUM: 8,
	CreatureSize.LARGE: 10, CreatureSize.GIANT: 12, CreatureSize.MEGA: 15
}

const HEARING_RANGES = {
	CreatureSize.TINY: 4, CreatureSize.SMALL: 6, CreatureSize.MEDIUM: 10,
	CreatureSize.LARGE: 14, CreatureSize.GIANT: 18, CreatureSize.MEGA: 22
}

const SPEED_BY_SIZE = {
	CreatureSize.TINY: 1.5, CreatureSize.SMALL: 1.3, CreatureSize.MEDIUM: 1.0,
	CreatureSize.LARGE: 0.8, CreatureSize.GIANT: 0.5, CreatureSize.MEGA: 0.3
}

const STRENGTH_BY_SIZE = {
	CreatureSize.TINY: 0.5, CreatureSize.SMALL: 2.0, CreatureSize.MEDIUM: 5.0,
	CreatureSize.LARGE: 12.0, CreatureSize.GIANT: 25.0, CreatureSize.MEGA: 50.0
}

const FOOD_CAPACITY_BY_SIZE = {
	CreatureSize.TINY: 1.0, CreatureSize.SMALL: 3.0, CreatureSize.MEDIUM: 10.0,
	CreatureSize.LARGE: 30.0, CreatureSize.GIANT: 80.0, CreatureSize.MEGA: 200.0
}

const MAX_HUNGER = 1.0
const MAX_THIRST = 1.0
const MAX_FATIGUE = 1.0
const BREEDING_COOLDOWN = 200
const MIGRATION_CHECK_INTERVAL = 50

var name: String = ""
var tile_pos: Vector3i
var id: int
var is_alive: bool = true
var creature_type: String = ""
var glyph: String = "?"
var display_color: Color = Color.WHITE
var size_label: String = "medium"
var creature_size: int = CreatureSize.MEDIUM
var body: Object = null

# Definición data-driven. Se rellena desde df_mode/content_packs o df_mode/mods.
var definition: Dictionary = {}
var aggression: String = "passive" # passive, territorial, hostile, predator
var attack_triggers: PackedStringArray = []
var prey_types: PackedStringArray = []
var predator_types: PackedStringArray = []
var competition_types: PackedStringArray = []
var flee_hp_threshold: float = 0.0
var group_behavior: bool = false
var nocturnal: bool = false
var settlement_data: Dictionary = {}
var description: String = ""
var biomes: PackedStringArray = []
var diet: PackedStringArray = ["plant"]
var reproduction_interval: int = 300
var max_health_points: float = 100.0
var spawn_group_min: int = 1
var spawn_group_max: int = 1
var spawn_weight: int = 1



# -----------------------------------------------------------------------------
# CATÁLOGO INTEGRADO DE CRIATURAS
# Este mismo archivo representa una criatura individual y también entrega
# las definiciones base que DFData necesita mediante get_all().
# -----------------------------------------------------------------------------
static func get_all() -> Array:
	return [
		{
			"id": "BIGLI_RABBIT",
			"name": "Conejo bigli",
			"description": "Pequeño herbívoro que vive en pastizales y bosques templados.",
			"tile": "r",
			"glyph": "r",
			"color": "#D9C7A3",
			"size": "small",
			"biomes": ["temperate_forest", "grassland"],
			"diet": ["plant"],
			"aggression": "passive",
			"attack_triggers": ["on_attacked"],
			"max_hp": 12,
			"strength": 1.0,
			"agility": 8.0,
			"intelligence": 0.4,
			"armor": 0.0,
			"move_speed": 1.4,
			"attack_damage": 1.0,
			"sight_range": 8,
			"flee_hp_threshold": 0.65,
			"prey_types": [],
			"predator_types": ["BIGLI_FOX", "BIGLI_WOLF"],
			"reproduction_interval": 160,
			"spawn_group_min": 2,
			"spawn_group_max": 6,
			"spawn_weight": 14
		},
		{
			"id": "BIGLI_FOX",
			"name": "Zorro bigli",
			"description": "Depredador pequeño que caza animales débiles en bosques y pastizales.",
			"tile": "f",
			"glyph": "f",
			"color": "#DD7722",
			"size": "small",
			"biomes": ["temperate_forest", "grassland"],
			"diet": ["meat"],
			"aggression": "predator",
			"attack_triggers": ["on_sight_prey", "on_attacked"],
			"max_hp": 25,
			"strength": 4.0,
			"agility": 7.0,
			"intelligence": 1.5,
			"armor": 0.0,
			"move_speed": 1.3,
			"attack_damage": 4.0,
			"sight_range": 10,
			"flee_hp_threshold": 0.15,
			"prey_types": ["BIGLI_RABBIT", "BIGLI_FROG"],
			"predator_types": ["BIGLI_WOLF", "BIGLI_BEAR"],
			"reproduction_interval": 260,
			"spawn_group_min": 1,
			"spawn_group_max": 2,
			"spawn_weight": 5
		},
		{
			"id": "BIGLI_DEER",
			"name": "Ciervo bigli",
			"description": "Herbívoro veloz que suele desplazarse en pequeños grupos.",
			"tile": "d",
			"glyph": "d",
			"color": "#A97848",
			"size": "medium",
			"biomes": ["temperate_forest", "grassland"],
			"diet": ["plant"],
			"aggression": "passive",
			"attack_triggers": ["on_attacked"],
			"max_hp": 45,
			"strength": 3.0,
			"agility": 8.0,
			"intelligence": 0.8,
			"armor": 0.0,
			"move_speed": 1.25,
			"attack_damage": 3.0,
			"sight_range": 12,
			"flee_hp_threshold": 0.50,
			"prey_types": [],
			"predator_types": ["BIGLI_WOLF", "BIGLI_BEAR"],
			"reproduction_interval": 320,
			"spawn_group_min": 2,
			"spawn_group_max": 5,
			"spawn_weight": 9
		},
		{
			"id": "BIGLI_WOLF",
			"name": "Lobo bigli",
			"description": "Depredador social que caza en manada y protege su territorio.",
			"tile": "w",
			"glyph": "w",
			"color": "#777777",
			"size": "medium",
			"biomes": ["temperate_forest", "grassland", "mountain"],
			"diet": ["meat"],
			"aggression": "predator",
			"attack_triggers": ["on_sight_prey", "on_attacked"],
			"max_hp": 55,
			"strength": 8.0,
			"agility": 6.0,
			"intelligence": 1.8,
			"armor": 1.0,
			"move_speed": 1.15,
			"attack_damage": 8.0,
			"sight_range": 14,
			"flee_hp_threshold": 0.10,
			"prey_types": ["BIGLI_RABBIT", "BIGLI_DEER", "BIGLI_BOAR"],
			"predator_types": ["BIGLI_BEAR"],
			"group_behavior": true,
			"reproduction_interval": 360,
			"spawn_group_min": 2,
			"spawn_group_max": 5,
			"spawn_weight": 5
		},
		{
			"id": "BIGLI_BOAR",
			"name": "Jabalí bigli",
			"description": "Animal robusto que responde violentamente cuando es atacado.",
			"tile": "b",
			"glyph": "b",
			"color": "#70452F",
			"size": "medium",
			"biomes": ["temperate_forest", "grassland", "swamp"],
			"diet": ["plant", "meat"],
			"aggression": "territorial",
			"attack_triggers": ["on_attacked"],
			"max_hp": 70,
			"strength": 9.0,
			"agility": 3.0,
			"intelligence": 0.7,
			"armor": 3.0,
			"move_speed": 0.95,
			"attack_damage": 9.0,
			"sight_range": 8,
			"flee_hp_threshold": 0.05,
			"prey_types": [],
			"predator_types": ["BIGLI_WOLF", "BIGLI_BEAR"],
			"reproduction_interval": 300,
			"spawn_group_min": 1,
			"spawn_group_max": 4,
			"spawn_weight": 7
		},
		{
			"id": "BIGLI_BEAR",
			"name": "Oso bigli",
			"description": "Gran depredador del bosque. Es lento, resistente y muy peligroso.",
			"tile": "B",
			"glyph": "B",
			"color": "#4C3326",
			"size": "large",
			"biomes": ["temperate_forest", "mountain"],
			"diet": ["plant", "meat"],
			"aggression": "predator",
			"attack_triggers": ["on_sight_prey", "on_attacked"],
			"max_hp": 140,
			"strength": 18.0,
			"agility": 2.0,
			"intelligence": 1.2,
			"armor": 6.0,
			"move_speed": 0.8,
			"attack_damage": 18.0,
			"sight_range": 11,
			"flee_hp_threshold": 0.02,
			"prey_types": ["BIGLI_DEER", "BIGLI_BOAR", "BIGLI_WOLF"],
			"predator_types": [],
			"reproduction_interval": 600,
			"spawn_group_min": 1,
			"spawn_group_max": 1,
			"spawn_weight": 2
		},
		{
			"id": "BIGLI_FROG",
			"name": "Rana bigli",
			"description": "Pequeña criatura de pantano que se alimenta de insectos.",
			"tile": "g",
			"glyph": "g",
			"color": "#55AA44",
			"size": "tiny",
			"biomes": ["swamp", "river", "lake"],
			"diet": ["meat"],
			"aggression": "passive",
			"attack_triggers": ["on_attacked"],
			"max_hp": 8,
			"strength": 1.0,
			"agility": 4.0,
			"intelligence": 0.2,
			"armor": 0.0,
			"move_speed": 1.1,
			"attack_damage": 1.0,
			"sight_range": 6,
			"flee_hp_threshold": 0.70,
			"prey_types": ["BIGLI_SPIDER"],
			"predator_types": ["BIGLI_FOX"],
			"reproduction_interval": 120,
			"spawn_group_min": 2,
			"spawn_group_max": 8,
			"spawn_weight": 15
		},
		{
			"id": "BIGLI_SPIDER",
			"name": "Araña bigli",
			"description": "Pequeño depredador que habita bosques, cuevas y pantanos.",
			"tile": "s",
			"glyph": "s",
			"color": "#392E43",
			"size": "tiny",
			"biomes": ["temperate_forest", "swamp", "cave"],
			"diet": ["meat"],
			"aggression": "predator",
			"attack_triggers": ["on_sight_prey", "on_attacked"],
			"max_hp": 15,
			"strength": 3.0,
			"agility": 5.0,
			"intelligence": 0.3,
			"armor": 0.0,
			"move_speed": 1.2,
			"attack_damage": 3.0,
			"sight_range": 7,
			"flee_hp_threshold": 0.20,
			"prey_types": [],
			"predator_types": ["BIGLI_FROG", "BIGLI_FOX"],
			"reproduction_interval": 100,
			"spawn_group_min": 1,
			"spawn_group_max": 4,
			"spawn_weight": 10
		}
	]


static func get_definition(definition_id: String) -> Dictionary:
	var wanted := definition_id.to_lower()
	for creature_definition in get_all():
		if str(creature_definition.get("id", "")).to_lower() == wanted:
			return creature_definition.duplicate(true)
	return {}


static func _packed_lower(values: Variant) -> PackedStringArray:
	var result := PackedStringArray()
	if values is Array or values is PackedStringArray:
		for value in values:
			result.append(str(value).to_lower())
	return result


static var _id_counter: int = 1000

# ---- AI STATE ----
var ai_state: int = AIState.IDLE
var ai_state_timer: int = 0
var ai_decision_timer: int = 0
var ai_target_pos: Vector3i = Vector3i(-1, -1, -1)
var ai_target_id: int = -1
var ai_target_type: String = ""
var path: Array = []
var path_index: int = 0
var stuck_counter: int = 0
var last_pos: Vector3i = Vector3i(-1, -1, -1)

# ---- STATS ----
var strength: float = 5.0
var agility: float = 5.0
var toughness: float = 5.0
var speed: float = 1.0
var move_tick_counter: int = 0
var fatigue_level: float = 0.0
var sight_range: int = 8
var hearing_range: int = 10
var stealth: float = 0.0
var intelligence: float = 0.3

# ---- VITAL NEEDS ----
var hunger: float = 0.0
var thirst: float = 0.0
var fatigue: float = 0.0
var health: float = 1.0
var is_sleeping: bool = false
var sleep_timer: int = 0

# ---- SOCIAL ----
var personality: int = PersonalityType.WILD
var pack_id: int = -1
var pack_leader_id: int = -1
var pack_members: Array = []
var social_timer: int = 0
var is_lonely: bool = false
var dominance: float = 0.5
var is_tame: bool = false
var owner_id: int = -1

# ---- REPRODUCTION ----
var is_mature: bool = true
var is_pregnant: bool = false
var gestation_timer: int = 0
var gestation_period: int = 100
var children_count: int = 0
var breeding_cooldown: int = 0
var mating_timer: int = 0
var gender: String = "Male"

# ---- TERRITORY ----
var home_pos: Vector3i = Vector3i(-1, -1, -1)
var territory_center: Vector3i = Vector3i(-1, -1, -1)
var territory_radius: int = 15
var has_territory: bool = false
var territory_defense_timer: int = 0

# ---- COMBAT ----
var combat_skill: float = 1.0
var attack_damage: float = 3.0
var attack_type: String = "bite"
var armor: float = 0.0
var is_hostile: bool = false
var fear_level: float = 0.0
var target_id: int = -1
var combat_cooldown: int = 0
var wounds: Array = []
var bleeding: float = 0.0
var has_infection: bool = false

# ---- MEMORY / KNOWLEDGE ----
var memory: Array = []
var known_food_sources: Array = []
var known_water_sources: Array = []
var known_threats: Array = []
var known_dangers: Array = []
var home_range: Vector3i = Vector3i(-1, -1, -1)

# ---- MIGRATION ----
var migration_target: Vector3i = Vector3i(-1, -1, -1)
var migration_timer: int = 0
var is_migrating: bool = false
var seasonal_home: Vector3i = Vector3i(-1, -1, -1)

# ---- GENETICS & BODY COMPOSITION ----
# Body mass in kg by size category (base values, scaled by genome.size_multiplier)
const BASE_MASS_BY_SIZE: Dictionary = {
	CreatureSize.TINY:   0.2,
	CreatureSize.SMALL:  4.0,
	CreatureSize.MEDIUM: 40.0,
	CreatureSize.LARGE:  200.0,
	CreatureSize.GIANT:  800.0,
	CreatureSize.MEGA:   4000.0,
}
var genome: RefCounted = null   # DFGenetics.Genome
var body_mass_kg: float = 40.0  # Effective mass after genome scaling

func _init(pos: Vector3i, ctype: String, cglyph: String, ccolor: Color, csize: String, content_definition: Dictionary = {}):
	var DFAnatomy = preload("res://df_mode/df_anatomy.gd")
	if ctype == "dwarf" or ctype == "goblin" or ctype == "human" or ctype == "elf":
		body = DFAnatomy.Body.new("humanoid")
	elif ctype in ["fox", "wolf", "bear", "deer", "horse", "cow", "boar", "tiger", "lion", "rabbit", "badger", "llama"]:
		body = DFAnatomy.Body.new("quadruped")
	elif ctype in ["spider", "ant", "bee", "beetle"]:
		body = DFAnatomy.Body.new("insect")
	else:
		body = DFAnatomy.Body.new("quadruped")
	tile_pos = pos
	id = _id_counter; _id_counter += 1
	name = ctype.capitalize()
	creature_type = ctype
	glyph = cglyph
	display_color = ccolor
	size_label = csize
	creature_size = _parse_size(csize)
	speed = SPEED_BY_SIZE.get(creature_size, 1.0)
	sight_range = SIGHT_RANGES.get(creature_size, 8)
	hearing_range = HEARING_RANGES.get(creature_size, 10)
	strength = STRENGTH_BY_SIZE.get(creature_size, 5.0)
	attack_damage = strength * 0.6
	_pick_personality()
	gender = "Male" if randi() % 2 == 0 else "Female"
	# Initialize default genome and compute effective body mass
	var DFGenetics = preload("res://df_mode/df_genetics.gd")
	genome = DFGenetics.Genome.new()
	body_mass_kg = BASE_MASS_BY_SIZE.get(creature_size, 40.0) * genome.size_multiplier
	home_pos = pos
	territory_center = pos
	apply_content_definition(content_definition)


## Aplica campos opcionales. Los valores ausentes conservan el comportamiento clásico.
func apply_content_definition(content: Dictionary) -> void:
	if content.is_empty():
		return

	definition = content.duplicate(true)
	creature_type = str(content.get("id", creature_type)).to_lower()
	name = str(content.get("name", content.get("display_name", name)))
	description = str(content.get("description", description))
	glyph = str(content.get("tile", content.get("glyph", glyph)))

	var raw_color: Variant = content.get("color", display_color)
	if raw_color is Color:
		display_color = raw_color
	else:
		display_color = Color.from_string(str(raw_color), display_color)

	size_label = str(content.get("size", size_label)).to_lower()
	creature_size = _parse_size(size_label)
	biomes = PackedStringArray(content.get("biomes", []))
	diet = PackedStringArray(content.get("diet", ["plant"]))
	aggression = str(content.get("aggression", aggression)).to_lower()
	attack_triggers = PackedStringArray(content.get("attack_triggers", []))
	prey_types = _packed_lower(content.get("prey_types", content.get("prey_ids", [])))
	predator_types = _packed_lower(content.get("predator_types", content.get("predator_ids", [])))
	competition_types = _packed_lower(content.get("competition_types", []))
	flee_hp_threshold = clampf(float(content.get("flee_hp_threshold", 0.0)), 0.0, 1.0)
	group_behavior = bool(content.get("group_behavior", false))
	nocturnal = bool(content.get("nocturnal", false))
	reproduction_interval = maxi(1, int(content.get("reproduction_interval", reproduction_interval)))
	spawn_group_min = maxi(1, int(content.get("spawn_group_min", spawn_group_min)))
	spawn_group_max = maxi(spawn_group_min, int(content.get("spawn_group_max", spawn_group_max)))
	spawn_weight = maxi(1, int(content.get("spawn_weight", spawn_weight)))

	settlement_data = {
		"has_settlement": bool(content.get("has_settlement", false)),
		"type": str(content.get("settlement_type", "")),
		"size": str(content.get("settlement_size", "lair")),
		"chance": float(content.get("settlement_chance", 0.0)),
		"patrol_radius": int(content.get("patrol_radius", territory_radius))
	}

	max_health_points = maxf(0.1, float(content.get("max_hp", content.get("health", max_health_points))))
	health = clampf(max_health_points / 100.0, 0.01, 1.0)
	strength = float(content.get("strength", strength))
	agility = float(content.get("agility", agility))
	intelligence = float(content.get("intelligence", intelligence))
	attack_damage = float(content.get("attack_damage", attack_damage))
	armor = float(content.get("armor", armor))
	speed = float(content.get("move_speed", content.get("speed", speed)))
	sight_range = int(content.get("sight_range", sight_range))
	hearing_range = int(content.get("hearing_range", hearing_range))
	territory_radius = int(settlement_data["patrol_radius"])

	is_hostile = aggression in ["hostile", "predator"]
	if aggression == "territorial":
		personality = PersonalityType.TERRITORIAL
	elif is_hostile:
		personality = PersonalityType.AGGRESSIVE

func _parse_size(s: String) -> int:
	match s:
		"tiny": return CreatureSize.TINY
		"small": return CreatureSize.SMALL
		"medium": return CreatureSize.MEDIUM
		"large": return CreatureSize.LARGE
		"giant": return CreatureSize.GIANT
		"mega": return CreatureSize.MEGA
	return CreatureSize.MEDIUM

func _pick_personality() -> void:
	var p_types = [PersonalityType.PASSIVE, PersonalityType.SKITTISH, PersonalityType.NERVOUS,
		PersonalityType.DOCILE, PersonalityType.FRIENDLY, PersonalityType.SOCIABLE,
		PersonalityType.CURIOS, PersonalityType.AGGRESSIVE, PersonalityType.TERRITORIAL,
		PersonalityType.WILD]
	var weights = [2, 2, 1, 2, 1, 1, 1, 1, 1, 2]
	if creature_type in ["wolf", "bear", "tiger", "lion", "boar"]:
		weights = [0, 1, 0, 0, 0, 0, 0, 3, 3, 3]
	elif creature_type in ["rabbit", "deer", "horse", "cow", "llama"]:
		weights = [3, 3, 2, 3, 2, 2, 1, 0, 0, 1]
	elif creature_type in ["fox", "badger"]:
		weights = [1, 2, 2, 1, 1, 1, 2, 1, 2, 1]
	var total = 0
	for w in weights: total += w
	var roll = randi() % total
	var cumulative = 0
	for i in range(p_types.size()):
		cumulative += weights[i]
		if roll < cumulative:
			personality = p_types[i]
			break

func get_display_char() -> String:
	if is_sleeping and ai_state == AIState.SLEEP:
		return "z"
	if ai_state == AIState.ATTACK or ai_state == AIState.HUNT:
		return "!"
	if is_hostile:
		return "X"
	return glyph

func get_display_color() -> Color:
	if not is_alive: return Color("#444444")
	if is_hostile: return Color.RED
	if ai_state == AIState.ATTACK: return Color("#FF4400")
	if fear_level > 0.5: return Color("#AAAA44")
	return display_color

func get_size_label() -> String:
	var labels = {CreatureSize.TINY: "Minúsculo", CreatureSize.SMALL: "Pequeño",
		CreatureSize.MEDIUM: "Mediano", CreatureSize.LARGE: "Grande",
		CreatureSize.GIANT: "Gigante", CreatureSize.MEGA: "Colosal"}
	return labels.get(creature_size, "Mediano")

func get_lore_text() -> String:
	return "No hay registro de esta criatura."

func get_body() -> Object:
	return body

func get_ai_state_name() -> String:
	var names = {
		AIState.IDLE: "Quieto", AIState.WANDER: "Deambulando",
		AIState.SEEK_FOOD: "Buscando comida", AIState.SEEK_WATER: "Buscando agua",
		AIState.EAT: "Comiendo", AIState.DRINK: "Bebiendo", AIState.SLEEP: "Durmiendo",
		AIState.HUNT: "Cazando", AIState.FLEE: "Huyendo", AIState.ATTACK: "Atacando",
		AIState.GUARD: "Guardia", AIState.SOCIALIZE: "Socializando",
		AIState.MATE: "Apareándose", AIState.FOLLOW: "Siguiendo",
		AIState.MIGRATE: "Migrando", AIState.INVESTIGATE: "Investigando",
		AIState.STALK: "Acechando", AIState.PATROL: "Patrullando",
		AIState.PLAY: "Jugando", AIState.GROOM: "Acicalándose",
		AIState.TRAINED_GUARD: "Guardia Entrenado"
	}
	return names.get(ai_state, "Desconocido")

# ---- CORE AI TICK ----
func tick(world, minute_ticked: bool = false) -> void:
	if not is_alive: return
	if ai_state == AIState.SLEEP and not is_sleeping:
		is_sleeping = true
	if minute_ticked:
		_update_vitals(world)
		_tick_bleeding()
		tick_metabolism(world)
		tick_grooming()
		_check_hazard_splatters(world)
		tick_population_ecology(world)
		# Apply floor substance transfer for standing limbs
		var standing: Array = []
		for bp in body.parts:
			if bp.can_stand:
				standing.append(bp)
		if not standing.is_empty():
			world.apply_step_coatings(tile_pos, standing)
			world.deposit_footprint(tile_pos, standing)
	_make_ai_decision(world, minute_ticked)

func _update_vitals(world = null) -> void:
	hunger = minf(1.0, hunger + 0.003 * speed)
	thirst = minf(1.0, thirst + 0.004 * speed)
	if not is_sleeping:
		fatigue = minf(1.0, fatigue + 0.002 * speed)
	if is_sleeping:
		fatigue = maxf(0.0, fatigue - 0.05)
		sleep_timer += 1
		if fatigue < 0.1 or sleep_timer > 50:
			is_sleeping = false
			sleep_timer = 0
			ai_state = AIState.IDLE
	if health <= 0.0:
		is_alive = false
		ai_state = AIState.IDLE
	if breeding_cooldown > 0:
		breeding_cooldown -= 1
	if is_pregnant:
		gestation_timer += 1
		if gestation_timer >= gestation_period and world != null:
			_give_birth(world)
	ai_decision_timer += 1

func _tick_bleeding() -> void:
	if bleeding > 0:
		health -= bleeding * 0.02
		bleeding *= 0.95
		if bleeding < 0.01:
			bleeding = 0.0

# ---- AI DECISION MAKING ----
func _make_ai_decision(world, minute_ticked: bool) -> void:
	if not minute_ticked: return
	if ai_decision_timer < 1: return
	ai_decision_timer = 0
	if is_hostile and combat_cooldown > 0:
		combat_cooldown -= 1
	if CreatureBehaviorRules.should_flee(health, flee_hp_threshold):
		fear_level = 1.0
	if _apply_data_driven_triggers(world):
		return
	_hunt_nearby_prey(world)
	_check_threats(world)
	if fear_level > 0.4:
		ai_state = AIState.FLEE
		_execute_flee(world)
		return
	match personality:
		PersonalityType.PASSIVE, PersonalityType.DOCILE:
			_passive_ai(world)
		PersonalityType.SKITTISH, PersonalityType.NERVOUS:
			_nervous_ai(world)
		PersonalityType.FRIENDLY, PersonalityType.SOCIABLE:
			_social_ai(world)
		PersonalityType.AGGRESSIVE, PersonalityType.TERRITORIAL:
			_aggressive_ai(world)
		PersonalityType.CURIOS:
			_curious_ai(world)
		PersonalityType.WILD:
			_wild_ai(world)
		_:
			_passive_ai(world)


func _apply_data_driven_triggers(world) -> bool:
	if not CreatureDecisionRules.can_scan_for_trigger(attack_triggers, world.get("is_daytime") == true, nocturnal):
		return false
	var closest = null
	var closest_distance := sight_range + 1
	for entity in world.entities:
		if not CreatureDecisionRules.is_valid_living_target(entity, self):
			continue
		var distance := CreatureDecisionRules.manhattan_distance(entity.tile_pos, tile_pos)
		if distance > sight_range or distance >= closest_distance:
			continue
		var raw_entity_type = entity.get("creature_type")
		var entity_type := str(raw_entity_type if raw_entity_type != null else "").to_lower()
		var attacks_player := attack_triggers.has("on_sight_player") and CreatureDecisionRules.is_player_target(entity)
		var attacks_prey := attack_triggers.has("on_sight_prey") and CreatureBehaviorRules.is_target_prey(prey_types, entity_type)
		if attacks_player or attacks_prey:
			closest = entity
			closest_distance = distance
	if closest == null:
		return false
	ai_target_id = closest.id
	var raw_closest_type = closest.get("creature_type")
	ai_target_type = str(raw_closest_type if raw_closest_type != null else "dwarf")
	ai_target_pos = closest.tile_pos
	ai_state = AIState.HUNT
	_move_toward(world, ai_target_pos)
	if closest_distance <= 1:
		_perform_attack(world, closest)
	return true

func _passive_ai(world) -> void:
	if hunger > 0.6:
		_seek_food(world)
	elif thirst > 0.6:
		_seek_water(world)
	elif fatigue > 0.8:
		ai_state = AIState.SLEEP; is_sleeping = true
	elif ai_state == AIState.IDLE or ai_state == AIState.WANDER:
		if randi() % 10 == 0:
			ai_state = AIState.WANDER
			_wander(world)
		else:
			ai_state = AIState.IDLE

func _nervous_ai(world) -> void:
	if hunger > 0.7:
		_seek_food(world)
	elif thirst > 0.7:
		_seek_water(world)
	elif fatigue > 0.9:
		ai_state = AIState.SLEEP; is_sleeping = true
	else:
		if randi() % 3 == 0:
			ai_state = AIState.WANDER; _wander(world)
		else:
			ai_state = AIState.IDLE
	_scan_for_danger(world)

func _social_ai(world) -> void:
	if hunger > 0.6: _seek_food(world)
	elif thirst > 0.6: _seek_water(world)
	elif fatigue > 0.8: ai_state = AIState.SLEEP; is_sleeping = true
	elif pack_id >= 0 and randi() % 5 == 0:
		_follow_pack_leader(world)
	elif randi() % 8 == 0:
		_try_socialize(world)
	else:
		if randi() % 4 == 0: ai_state = AIState.WANDER; _wander(world)
		else: ai_state = AIState.IDLE

func _aggressive_ai(world) -> void:
	if hunger > 0.5:
		if _hunt_prey(world): return
		_seek_food(world)
	elif thirst > 0.6:
		_seek_water(world)
	elif fatigue > 0.9:
		ai_state = AIState.SLEEP; is_sleeping = true
	else:
		_patrol_territory(world)

func _curious_ai(world) -> void:
	if hunger > 0.7: _seek_food(world)
	elif thirst > 0.7: _seek_water(world)
	elif fatigue > 0.85: ai_state = AIState.SLEEP; is_sleeping = true
	elif randi() % 3 == 0 and ai_target_id < 0:
		_investigate_nearby(world)
	else:
		if randi() % 5 == 0: ai_state = AIState.WANDER; _wander(world)

func _wild_ai(world) -> void:
	if hunger > 0.4:
		if _hunt_prey(world): return
		_seek_food(world)
	elif thirst > 0.5:
		_seek_water(world)
	elif fatigue > 0.7:
		ai_state = AIState.SLEEP; is_sleeping = true
	else:
		_patrol_territory(world)

# ---- HUNTING ----
func _hunt_nearby_prey(world) -> void:
	if not personality in [PersonalityType.AGGRESSIVE, PersonalityType.TERRITORIAL, PersonalityType.WILD]:
		return
	if hunger < 0.3 and not is_hostile: return
	var nearest_prey = null
	var nearest_dist = sight_range
	for e in world.entities:
		if e == self: continue
		var alive = e.get("is_alive")
		if alive != null and alive == false: continue
		var e_type = e.get("creature_type")
		var _size_lbl = e.get("size_label")
		var _csize = e.get("creature_size"); var e_size = _csize if _csize != null else CreatureSize.MEDIUM
		if e_type == null: continue
		if e_type == creature_type: continue
		if not CreatureBehaviorRules.is_target_prey(prey_types, str(e_type)): continue
		if e_size > creature_size and hunger < 0.7: continue
		var _pers = e.get("personality"); var p_type = _pers if _pers != null else PersonalityType.PASSIVE
		if p_type in [PersonalityType.AGGRESSIVE, PersonalityType.TERRITORIAL]: continue
		var dist = abs(e.tile_pos.x - tile_pos.x) + abs(e.tile_pos.z - tile_pos.z)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest_prey = e
	if nearest_prey != null:
		ai_target_id = nearest_prey.id
		ai_target_type = nearest_prey.creature_type
		ai_state = AIState.HUNT
		ai_target_pos = nearest_prey.tile_pos

func _hunt_prey(world) -> bool:
	if ai_target_id >= 0:
		var target = _find_entity_by_id(world, ai_target_id)
		if CreatureDecisionRules.is_valid_living_target(target, self):
			ai_target_pos = target.tile_pos
			ai_state = AIState.HUNT
			_move_toward(world, ai_target_pos)
			var dist = abs(tile_pos.x - ai_target_pos.x) + abs(tile_pos.z - ai_target_pos.z)
			if dist <= 1:
				_perform_attack(world, target)
			return true

		# El objetivo desapareció, murió o era un objeto sin salud.
		ai_target_id = -1
		ai_target_type = ""
		ai_target_pos = Vector3i(-1, -1, -1)
	return false

func _perform_attack(world, target) -> void:
	# Defensa final: world.entities también contiene DFItem, talleres y cadáveres.
	# Solo las entidades vivas con una propiedad health pueden combatir.
	if not CreatureDecisionRules.is_valid_living_target(target, self):
		ai_target_id = -1
		ai_target_type = ""
		ai_state = AIState.IDLE
		return

	var raw_health: Variant = target.get("health")
	if raw_health == null:
		ai_target_id = -1
		ai_target_type = ""
		ai_state = AIState.IDLE
		return

	ai_state = AIState.ATTACK
	var dmg: float = CombatMath.roll_attack_damage(attack_damage)
	var old_health: float = float(raw_health)
	var new_health: float = CombatMath.health_after_damage(old_health, dmg)
	target.set("health", new_health)

	var target_name_value: Variant = target.get("name")
	var target_name: String = str(target_name_value) if target_name_value != null else "algo"
	var msg := "%s ataca a %s" % [name.capitalize(), target_name]

	if old_health > 0.0 and new_health <= 0.0:
		if target.get("is_alive") != null:
			target.set("is_alive", false)
		msg += " ¡y lo mata!"
		body.ingested_substances["food"] = body.ingested_substances.get("food", 0.0) + 0.3
		_feed_on_corpse(world, target)
	elif dmg > strength * 0.5:
		msg += " causando una herida grave."
	else:
		msg += " causando una herida."

	var target_bleeding: Variant = target.get("bleeding")
	if target_bleeding != null:
		target.set("bleeding", float(target_bleeding) + 0.1)

	if world.combat_system != null:
		world.combat_system._add_log(msg)

func _feed_on_corpse(world, target) -> void:
	body.ingested_substances["food"] = body.ingested_substances.get("food", 0.0) + 0.5
	ai_state = AIState.EAT
	var _cn = target.get("name"); var corpse_item = DFItem.new(target.tile_pos, "Cuerpo de %s" % (_cn if _cn != null else "criatura"), "corpse", 0, "%", Color("#884422"))
	corpse_item.nutrition = 0.8
	world.entities.append(corpse_item)

# ---- FLEEING ----
func _check_threats(world) -> void:
	if personality in [PersonalityType.AGGRESSIVE, PersonalityType.TERRITORIAL]:
		if fear_level > 0:
			fear_level = maxf(0.0, fear_level - 0.01)
		return
	if personality in [PersonalityType.SKITTISH, PersonalityType.NERVOUS, PersonalityType.PASSIVE]:
		for e in world.entities:
			if e == self: continue
			var e_type = e.get("creature_type")
			if e_type == null: continue
			if e_type == "dwarf" and e.get("is_alive") == true:
				var dist = abs(e.tile_pos.x - tile_pos.x) + abs(e.tile_pos.z - tile_pos.z)
				if dist < sight_range:
					fear_level = minf(1.0, fear_level + maxf(0, 0.5 - dist * 0.03))
				continue
			var _ep = e.get("personality"); var e_personality = _ep if _ep != null else PersonalityType.PASSIVE
			if e_personality in [PersonalityType.AGGRESSIVE, PersonalityType.TERRITORIAL]:
				var dist_513 = abs(e.tile_pos.x - tile_pos.x) + abs(e.tile_pos.z - tile_pos.z)
				if dist_513 < hearing_range:
					fear_level = minf(1.0, fear_level + maxf(0, 0.3 - dist_513 * 0.02))
					if e_personality == PersonalityType.TERRITORIAL and dist_513 < territory_radius: 
						fear_level = minf(1.0, fear_level + 0.2)

func _execute_flee(world) -> void:
	fear_level = maxf(0.0, fear_level - 0.01)
	var flee_dir = Vector3i(randi() % 7 - 3, 0, randi() % 7 - 3)
	if flee_dir == Vector3i(0, 0, 0): flee_dir = Vector3i(1, 0, 0)
	var target = Vector3i(tile_pos.x + flee_dir.x * 5, tile_pos.y, tile_pos.z + flee_dir.z * 5)
	target.x = clampi(target.x, 1, world.width - 2)
	target.z = clampi(target.z, 1, world.depth - 2)
	_move_toward(world, target)
	if fear_level <= 0:
		ai_state = AIState.IDLE

func _seek_food(world) -> void:
	ai_state = AIState.SEEK_FOOD
	if _drink_from_splatters(world):
		return
	_check_items_for_food(world)
	if known_food_sources.is_empty():
		if randi() % 3 == 0:
			_wander(world)
		return
	var best = _get_nearest_known_source(world, known_food_sources)
	if best.x >= 0:
		ai_target_pos = best
		_move_toward(world, best)
		var dist = abs(tile_pos.x - best.x) + abs(tile_pos.z - best.z)
		if dist <= 1:
			body.ingested_substances["food"] = body.ingested_substances.get("food", 0.0) + 0.3
			ai_state = AIState.EAT

func _drink_from_splatters(world) -> bool:
	var here = world.get_splatters_at(tile_pos)
	var drinkable = ["beer", "water", "mud"]
	var total = 0.0
	for s in drinkable:
		total += here.get(s, 0.0)
	if total > 0.01:
		for s_555 in drinkable:
			var amount = here.get(s_555, 0.0)
			if amount > 0.0:
				var sip = minf(amount, 0.02)
				body.ingested_substances[s_555] = body.ingested_substances.get(s_555, 0.0) + sip
				world.add_splatter_substance(tile_pos, s_555, -sip)
				body.nausea = maxf(0.0, body.nausea - 0.1)
				if s_555 == "beer" or s_555 == "mud":
					body.ingested_substances["food"] = body.ingested_substances.get("food", 0.0) + 0.05
				thirst = maxf(0.0, thirst - 0.1)
				ai_state = AIState.DRINK
				return true
	var nearby = _find_nearby_splatters(world, 4)
	if nearby.size() > 0:
		ai_target_pos = nearby[randi() % nearby.size()]
		_move_toward(world, ai_target_pos)
		return true
	return false

func _find_nearby_splatters(world, radius: int) -> Array:
	var result = []
	var drinkable = ["beer", "water", "mud"]
	for dx in range(-radius, radius + 1):
		for dz in range(-radius, radius + 1):
			var pos = Vector3i(tile_pos.x + dx, tile_pos.y, tile_pos.z + dz)
			var subs = world.get_splatters_at(pos)
			for s in drinkable:
				if subs.get(s, 0.0) > 0.01:
					result.append(pos)
					break
	return result

func _check_items_for_food(world) -> void:
	for it in world.entities:
		if it.get("item_type") == null: continue
		if it.item_type in ["food", "plant", "animal_product"]:
			var dist = abs(it.tile_pos.x - tile_pos.x) + abs(it.tile_pos.z - tile_pos.z)
			if dist <= 1:
				world.entities.erase(it)
				body.ingested_substances["food"] = body.ingested_substances.get("food", 0.0) + 0.5
				ai_state = AIState.EAT
				return

func _seek_water(world) -> void:
	ai_state = AIState.SEEK_WATER
	if known_water_sources.is_empty():
		if randi() % 3 == 0:
			_wander(world)
		return
	var best = _get_nearest_known_source(world, known_water_sources)
	if best.x >= 0:
		ai_target_pos = best
		_move_toward(world, best)
		var dist = abs(tile_pos.x - best.x) + abs(tile_pos.z - best.z)
		if dist <= 1:
			if world.is_water(best):
				thirst = maxf(0.0, thirst - 0.4)
				ai_state = AIState.DRINK
				if not best in known_water_sources:
					known_water_sources.append(best)

func _learn_water_source(world) -> void:
	for dx in [-1, 0, 1]:
		for dz in [-1, 0, 1]:
			var pos = Vector3i(tile_pos.x + dx, tile_pos.y, tile_pos.z + dz)
			if world.is_water(pos) and not pos in known_water_sources:
				known_water_sources.append(pos)

func _learn_food_source(world) -> void:
	for e in world.entities:
		if e is DFItem and e.get("is_food") or e.get("item_type") == "food":
			var pos = e.tile_pos
			if not pos in known_food_sources:
				known_food_sources.append(pos)

# ---- SOCIAL ----
func _try_socialize(world) -> bool:
	var mate = _find_nearby_same_type(world, 3)
	if mate != null:
		ai_state = AIState.SOCIALIZE
		ai_target_id = mate.id
		ai_target_pos = mate.tile_pos
		_move_toward(world, mate.tile_pos)
		var dist = abs(tile_pos.x - mate.tile_pos.x) + abs(tile_pos.z - mate.tile_pos.z)
		if dist <= 1:
			if breeding_cooldown <= 0 and not is_pregnant:
				if randi() % 5 == 0:
					_try_mate(mate)
		return true
	return false

func _find_nearby_same_type(world, radius: int):
	for e in world.entities:
		if e == self: continue
		var alive = e.get("is_alive")
		if alive != null and alive == false: continue
		if e.get("creature_type") == creature_type:
			var dist = abs(e.tile_pos.x - tile_pos.x) + abs(e.tile_pos.z - tile_pos.z)
			if dist <= radius:
				return e
	return null

func _try_mate(partner) -> void:
	ai_state = AIState.MATE
	if partner.get("is_pregnant") == null or partner.get("is_pregnant") == false:
		is_pregnant = true
		gestation_timer = 0
		gestation_period = 80 + randi() % 40
		breeding_cooldown = BREEDING_COOLDOWN
		if partner.get("breeding_cooldown") != null:
			partner.breeding_cooldown = BREEDING_COOLDOWN

func _give_birth(world) -> void:
	is_pregnant = false
	gestation_timer = 0
	var num_offspring = 1 + randi() % 3
	for i in range(num_offspring):
		var offset = Vector3i(randi() % 3 - 1, 0, randi() % 3 - 1)
		var spawn_pos = Vector3i(
			clampi(tile_pos.x + offset.x, 0, world.width - 1),
			tile_pos.y,
			clampi(tile_pos.z + offset.z, 0, world.depth - 1)
		)
		if world.is_blocked(spawn_pos): spawn_pos = tile_pos
		var baby = load("res://df_mode/df_creature.gd").new(spawn_pos, creature_type, glyph, display_color, size_label)
		baby.creature_size = max(0, creature_size - 1)
		baby.strength = strength * 0.3
		baby.health = 1.0
		baby.hunger = 0.5
		baby.is_mature = false
		baby.personality = personality
		baby.pack_id = pack_id
		baby.home_pos = home_pos
		baby.territory_center = territory_center
		# Inherit genome from parent (no partner genome stored yet, so mutate own)
		var DFGenetics = preload("res://df_mode/df_genetics.gd")
		var parent_genome = genome if genome != null else DFGenetics.Genome.new()
		baby.genome = parent_genome.mutate(0.15, 0.12)
		baby.body_mass_kg = BASE_MASS_BY_SIZE.get(baby.creature_size, 10.0) * baby.genome.size_multiplier
		world.entities.append(baby)
		children_count += 1

# ---- PACK SYSTEM ----
func _follow_pack_leader(world) -> void:
	if pack_leader_id < 0: return
	var leader = _find_entity_by_id(world, pack_leader_id)
	if leader == null or leader.is_alive == false:
		pack_leader_id = -1
		ai_state = AIState.IDLE
		return
	var dist = abs(tile_pos.x - leader.tile_pos.x) + abs(tile_pos.z - leader.tile_pos.z)
	if dist > 3:
		ai_state = AIState.FOLLOW
		_move_toward(world, leader.tile_pos)

# ---- TERRITORY ----
func _patrol_territory(world) -> void:
	ai_state = AIState.PATROL
	if not has_territory:
		territory_center = home_pos
		territory_radius = 8 + randi() % 8
		has_territory = true
	var patrol_target = Vector3i(
		territory_center.x + randi() % territory_radius - territory_radius/2,
		territory_center.y,
		territory_center.z + randi() % territory_radius - territory_radius/2
	)
	patrol_target.x = clampi(patrol_target.x, 0, world.width - 1)
	patrol_target.z = clampi(patrol_target.z, 0, world.depth - 1)
	_move_toward(world, patrol_target)
	for e in world.entities:
		if e == self: continue
		
		if e.get("creature_type") != creature_type and e.get("is_alive") != false:
			var d = abs(e.tile_pos.x - territory_center.x) + abs(e.tile_pos.z - territory_center.z)
			if d < territory_radius and e.get("is_hostile") != true:
				if personality == PersonalityType.TERRITORIAL:
					ai_state = AIState.ATTACK
					ai_target_id = e.id
					ai_target_pos = e.tile_pos
					return

# ---- MIGRATION ----
func _check_migration(world, season: int) -> void:
	if migration_timer > 0: 
		migration_timer -= 1
		return
	var should_migrate = false
	if creature_type in ["deer", "horse", "bison"] and season in [0, 3]:
		should_migrate = true
	if should_migrate and not is_migrating:
		is_migrating = true
		migration_timer = MIGRATION_CHECK_INTERVAL
		var mx = randi() % world.width
		var mz = randi() % world.depth
		migration_target = Vector3i(mx, world.get_surface_height(mx, mz), mz)
		ai_state = AIState.MIGRATE
	if is_migrating and ai_state == AIState.MIGRATE:
		_move_toward(world, migration_target)
		var dist = abs(tile_pos.x - migration_target.x) + abs(tile_pos.z - migration_target.z)
		if dist <= 3:
			is_migrating = false
			ai_state = AIState.IDLE
			home_pos = migration_target
			territory_center = migration_target

# ---- INVESTIGATE ----
func _investigate_nearby(world) -> void:
	for dx in range(-sight_range, sight_range + 1):
		for dz in range(-sight_range, sight_range + 1):
			var pos = Vector3i(tile_pos.x + dx, tile_pos.y, tile_pos.z + dz)
			if pos.x < 0 or pos.x >= world.width or pos.z < 0 or pos.z >= world.depth: continue
			if world.get_entity_at(pos) != null:
				ai_target_pos = pos
				ai_state = AIState.INVESTIGATE
				_move_toward(world, pos)
				return

# ---- STALK ----
func _stalk_prey(world, prey) -> void:
	ai_state = AIState.STALK
	var dist = abs(tile_pos.x - prey.tile_pos.x) + abs(tile_pos.z - prey.tile_pos.z)
	if dist > sight_range:
		ai_state = AIState.IDLE
		return
	var approach_pos = Vector3i(
		tile_pos.x + clampi(prey.tile_pos.x - tile_pos.x, -1, 1),
		tile_pos.y,
		tile_pos.z + clampi(prey.tile_pos.z - tile_pos.z, -1, 1)
	)
	if not world.is_blocked(approach_pos):
		_move_toward(world, approach_pos)
	if dist <= 1:
		_perform_attack(world, prey)

# ---- MOVEMENT ----
func _move_toward(world, target: Vector3i) -> void:
	var effective_speed = speed * (1.0 - fatigue_level * 0.15) * creature_size_speed_mod()
	effective_speed = maxf(0.3, effective_speed)
	if move_tick_counter > 0:
		move_tick_counter -= 1
		return
	move_tick_counter = max(1, ceil(2.0 / effective_speed))

	if tile_pos == last_pos:
		stuck_counter += 1
	else:
		stuck_counter = 0
	last_pos = tile_pos
	if stuck_counter > 5:
		_wander(world)
		stuck_counter = 0
		return
	if path_index >= path.size() or path.is_empty():
		path = DFPathfinding.find_path(world, tile_pos, target, false)
		path_index = 0
		if path.is_empty(): return

	# Path smoothing: skip intermediates
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
		path = DFPathfinding.find_path(world, tile_pos, target, false)
		path_index = 0
		if path.is_empty(): return

	if next_step != tile_pos:
		# Entity collision avoidance
		var blocked_by_entity = false
		for e in world.entities:
			if e == self: continue
			if e is DFItem: continue
			var _ial = e.get("is_alive"); if (_ial != null and _ial == false): continue
			if e.tile_pos == next_step:
				blocked_by_entity = true
				break
		if blocked_by_entity:
			var dirs = [Vector3i(-1, 0, 0), Vector3i(1, 0, 0), Vector3i(0, 0, -1), Vector3i(0, 0, 1),
				Vector3i(-1, 0, -1), Vector3i(1, 0, 1), Vector3i(-1, 0, 1), Vector3i(1, 0, -1)]
			var found_alt = false
			dirs.shuffle()
			for d in dirs:
				var alt = tile_pos + d
				if alt.x < 0 or alt.x >= world.width or alt.z < 0 or alt.z >= world.depth: continue
				if world.is_blocked(alt): continue
				var alt_blocked = false
				for e_851 in world.entities:
					if e_851 == self: continue
					if e_851 is DFItem: continue
					var _ial2 = e_851.get("is_alive"); if (_ial2 != null and _ial2 == false): continue
					if e_851.tile_pos == alt:
						alt_blocked = true
						break
				if not alt_blocked:
					tile_pos = alt
					found_alt = true
					break
			if not found_alt: return
		else:
			tile_pos = next_step
			fatigue_level = minf(1.0, fatigue_level + 0.001)
		path_index += 1

func creature_size_speed_mod() -> float:
	match creature_size:
		CreatureSize.TINY: return 1.5
		CreatureSize.SMALL: return 1.3
		CreatureSize.MEDIUM: return 1.0
		CreatureSize.LARGE: return 0.8
		CreatureSize.GIANT: return 0.6
		CreatureSize.MEGA: return 0.5
		_: return 1.0

func _wander(world) -> void:
	var ox = (randi() % 7) - 3
	var oz = (randi() % 7) - 3
	var target = Vector3i(
		clampi(tile_pos.x + ox, 1, world.width - 2),
		tile_pos.y,
		clampi(tile_pos.z + oz, 1, world.depth - 2)
	)
	if not world.is_blocked(target) and not world.is_water(target):
		_move_toward(world, target)
	else:
		_move_toward(world, Vector3i(tile_pos.x, tile_pos.y, tile_pos.z))



# ---- HELPERS ----
func _find_entity_by_id(world, eid: int):
	for e in world.entities:
		if e.id == eid: return e
	return null

func _scan_for_danger(world) -> void:
	for e in world.entities:
		if e == self: continue
		var _esp = e.get("personality"); var e_personality = _esp if _esp != null else -1
		var e_type = e.get("creature_type")
		var _esz = e.get("creature_size"); var e_size = _esz if _esz != null else CreatureSize.MEDIUM
		if e_type != null and e_size > creature_size and e_personality in [PersonalityType.AGGRESSIVE, PersonalityType.TERRITORIAL]:
			var dist = abs(e.tile_pos.x - tile_pos.x) + abs(e.tile_pos.z - tile_pos.z)
			if dist < hearing_range:
				fear_level = minf(1.0, fear_level + 0.1)
				ai_state = AIState.FLEE

func _get_nearest_known_source(_world, sources: Array) -> Vector3i:
	var best = Vector3i(-1, -1, -1)
	var best_dist = 99999
	for s in sources:
		var d = abs(tile_pos.x - s.x) + abs(tile_pos.z - s.z) + abs(tile_pos.y - s.y) * 2
		if d < best_dist:
			best_dist = d
			best = s
	return best

func apply_wound(damage: float, body_part: int) -> void:
	health = maxf(0.0, health - damage * 0.02)
	wounds.append({"part": body_part, "damage": damage, "turn": 0})
	if damage > 5:
		bleeding += 0.05 * (damage / 5.0)
		fear_level = minf(1.0, fear_level + 0.2)
	if attack_triggers.has("on_attacked") and health > flee_hp_threshold:
		is_hostile = true
		ai_state = AIState.ATTACK
	if health <= 0:
		is_alive = false

func take_damage(damage: float, body_part: int, is_critical: bool) -> bool:
	apply_wound(damage, body_part)
	if health <= 0.0:
		is_alive = false
		return true
	return false

func get_summary() -> String:
	var text = "%s (%s)" % [name.capitalize(), get_size_label()]
	text += " | %s" % get_ai_state_name()
	if is_hostile: text += " | HOSTIL"
	if is_pregnant: text += " | EMBARAZADA"
	if is_sleeping: text += " | DURMIENDO"
	if body and body.ebriety > 0.3: text += " | EBRIO(%.1f)" % body.ebriety
	if body and body.disease_type != "": text += " | ENFERMO"
	text += " | HP: %d%%" % int(health * 100)
	text += " | H: %d%% T: %d%%" % [int(hunger * 100), int(thirst * 100)]
	return text

# ---- METABOLISM ----
## Processes ingested substances from the digestive tract.
## Concentrations are mass-relative, so a TINY creature ingesting the same
## alcohol as a LARGE one will suffer disproportionately higher toxicity.
func tick_metabolism(world) -> void:
	var bm: float = maxf(0.01, body_mass_kg)
	var met_rate: float = genome.metabolic_rate if genome else 1.0
	var alc_tol: float = genome.alcohol_tolerance if genome else 1.0

	# -- Digestion: food and water slowly absorbed --
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

	# -- Alcohol --
	var alc: float = body.ingested_substances.get("beer", 0.0)
	if alc > 0.0:
		var bac: float = alc / bm
		body.ebriety = clampf(bac / (0.005 * alc_tol), 0.0, 4.0)
		var burned: float = 0.003 * met_rate
		body.ingested_substances["beer"] = maxf(0.0, alc - burned)
		if body.ingested_substances["beer"] <= 0.0:
			body.ingested_substances.erase("beer")
		if body.ebriety > 1.5:
			body.nausea = minf(1.0, body.nausea + 0.025)
			health = maxf(0.0, health - body.ebriety * 0.005)
	else:
		body.ebriety = maxf(0.0, body.ebriety - 0.008)
	
	# -- Toxins --
	var poison: float = body.ingested_substances.get("poison", 0.0)
	if poison > 0.0:
		var dmg: float = (poison * 0.4) / bm
		health = maxf(0.0, health - dmg)
		body.nausea = minf(1.0, body.nausea + 0.04)
		body.ingested_substances["poison"] = maxf(0.0, poison - 0.002 * met_rate)
		if body.ingested_substances["poison"] <= 0.0:
			body.ingested_substances.erase("poison")
	
	# -- Pathogens --
	var pathogen: float = body.ingested_substances.get("pathogen", 0.0)
	if pathogen > 0.0:
		var path_resist: float = genome.pathogen_resistance if genome else 1.0
		if body.disease_type == "" and randf() < (0.008 * pathogen / path_resist):
			body.disease_type = "infection"
		body.ingested_substances["pathogen"] = maxf(0.0, pathogen - 0.01)
		if body.ingested_substances["pathogen"] <= 0.0:
			body.ingested_substances.erase("pathogen")
	
	# -- Disease progression --
	if body.disease_type != "":
		health = maxf(0.0, health - 0.001)
		fatigue = minf(1.0, fatigue + 0.002)
		# Infected creatures cough and spread pathogen aerosols
		if randf() < 0.025:
			var dirs = [Vector3i(1,0,0), Vector3i(-1,0,0), Vector3i(0,0,1), Vector3i(0,0,-1), Vector3i(0,0,0)]
			for d in dirs:
				world.add_splatter_substance(tile_pos + d, "pathogen", 0.004)
	
	# -- Nausea / Vomiting --
	if body.nausea >= 0.9 and not body.is_vomiting:
		body.is_vomiting = true
		var vomit_extra: float = 0.0
		for sub in body.ingested_substances.keys():
			vomit_extra += body.ingested_substances[sub]
			world.add_splatter_substance(tile_pos, sub, body.ingested_substances[sub] * 0.5)
		body.ingested_substances.clear()
		world.add_splatter_substance(tile_pos, "vomit", 0.06 + vomit_extra * 0.3)
		body.nausea = 0.0
		body.ebriety = maxf(0.0, body.ebriety - 0.6)
		body.is_vomiting = false

# ---- GROOMING ----
## Animals instinctively lick/groom their limbs. This is a generic behavior:
## any body part with coatings has a chance to be cleaned by the creature's mouth.
## The substance is moved from limb coatings into the digestive tract.
func tick_grooming() -> void:
	var dirty_parts: Array = []
	for bp in body.parts:
		if not bp.coatings.is_empty():
			dirty_parts.append(bp)
	
	if dirty_parts.is_empty():
		return
	
	# Grooming chance: base 15% per minute for creatures + scaling with dirtiness
	var groom_chance: float = 0.15 + 0.1 * float(dirty_parts.size())
	if randf() > groom_chance:
		return
	
	if ai_state not in [AIState.ATTACK, AIState.FLEE, AIState.HUNT, AIState.MATE]:
		ai_state = AIState.GROOM
	for bp_1052 in dirty_parts:
		for sub in bp_1052.coatings.keys():
			var amount: float = bp_1052.coatings[sub]
			if amount > 0.0:
				body.ingested_substances[sub] = body.ingested_substances.get(sub, 0.0) + amount
		bp_1052.coatings.clear()

# ---- HAZARD AVOIDANCE ----
func _check_hazard_splatters(world) -> void:
	var subs = world.get_splatters_at(tile_pos)
	var hazards = ["vomit", "poison"]
	for h in hazards:
		if subs.get(h, 0.0) > 0.02:
			fear_level = minf(1.0, fear_level + 0.1)
			if ai_state not in [AIState.ATTACK, AIState.HUNT, AIState.MATE]:
				ai_state = AIState.FLEE
			return

# ---- POPULATION ECOLOGY ----
func tick_population_ecology(world) -> void:
	if not minute_ticked_since_ecology:
		minute_ticked_since_ecology = true
		_ecology_breed_check(world)
		_ecology_starve_check(world)
		_ecology_migrate_check(world)

var minute_ticked_since_ecology: bool = false

func _ecology_breed_check(world) -> void:
	if breeding_cooldown > 0: return
	if not is_mature: return
	if is_pregnant: return
	if hunger > 0.5 or thirst > 0.5: return
	# Count same-type creatures nearby for social breeding
	# same_nearby unused
	var opposite_nearby = 0
	for e in world.entities:
		if e == self: continue
		if e.get("creature_type") == creature_type and e.get("is_alive") == true:
			var d = abs(e.tile_pos.x - tile_pos.x) + abs(e.tile_pos.z - tile_pos.z)
			if d < 10:
				# same_nearby += 1
				if e.get("gender") != gender: opposite_nearby += 1
	# Need at least one opposite gender nearby to breed
	if opposite_nearby < 1: return
	# Food availability boosts breeding chance
	var food_nearby = 0
	for e_1099 in world.entities:
		if e_1099 is DFItem and e_1099.get("is_edible") == true:
			var d_1101 = abs(e_1099.tile_pos.x - tile_pos.x) + abs(e_1099.tile_pos.z - tile_pos.z)
			if d_1101 < 15: food_nearby += 1
	var breed_chance = 0.02 + food_nearby * 0.005
	if creature_size <= CreatureSize.SMALL: breed_chance *= 2.0
	if randf() < breed_chance:
		is_pregnant = true
		gestation_timer = 0
		breeding_cooldown = 50

func _ecology_starve_check(_world) -> void:
	if hunger > 0.9 and thirst > 0.9:
		health = maxf(0.0, health - 0.02)
		if health <= 0.0:
			is_alive = false
	if hunger > 0.9 and randi() % 5 == 0:
		ai_state = AIState.SEEK_FOOD

func _ecology_migrate_check(world) -> void:
	if is_migrating: return
	if ai_state == AIState.FLEE: return
	var food_nearby = 0
	for e in world.entities:
		if e is DFItem and e.get("is_edible") == true:
			var d = abs(e.tile_pos.x - tile_pos.x) + abs(e.tile_pos.z - tile_pos.z)
			if d < 20: food_nearby += 1
	# If no food nearby and hungry, migrate
	if food_nearby < 2 and hunger > 0.6:
		if randi() % 20 == 0:
			is_migrating = true
			ai_state = AIState.MIGRATE
			var edge_x = 1 if tile_pos.x < world.width / 2 else world.width - 2
			var edge_z = 1 if tile_pos.z < world.depth / 2 else world.depth - 2
			migration_target = Vector3i(edge_x, tile_pos.y, edge_z)
			_move_toward(world, migration_target)
