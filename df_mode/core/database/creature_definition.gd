extends Resource
class_name CreatureDefinition

@export_category("Identity")
@export var id: String = ""
@export var display_name: String = "Creature"
@export var glyph: String = "?"
@export var color: Color = Color.WHITE
@export var size: String = "medium"

@export_category("Attributes")
@export_range(0.1, 100.0, 0.1) var health: float = 10.0
@export_range(0.0, 100.0, 0.1) var strength: float = 5.0
@export_range(0.0, 100.0, 0.1) var agility: float = 5.0
@export_range(0.0, 100.0, 0.1) var intelligence: float = 1.0
@export_range(0.0, 100.0, 0.1) var armor: float = 0.0
@export_range(0.1, 10.0, 0.1) var speed: float = 1.0
@export_range(1, 50, 1) var sight_range: int = 8

@export_category("Ecology")
@export var biomes: PackedStringArray = []
@export var diet: PackedStringArray = ["plant"]
@export var prey_ids: PackedStringArray = []
@export var predator_ids: PackedStringArray = []
@export var reproduction_interval: int = 300
@export var is_hostile: bool = false

func apply_to(creature: Object) -> void:
	if creature.name.is_empty() or creature.name.to_lower() == id.to_lower():
		creature.name = display_name
	creature.glyph = glyph
	creature.display_color = color
	creature.size_label = size
	creature.health = minf(creature.health, health / 10.0)
	creature.strength = strength
	creature.agility = agility
	creature.intelligence = intelligence
	creature.armor = armor
	creature.speed = speed
	creature.sight_range = sight_range
	creature.is_hostile = is_hostile
	creature.set_meta("definition_id", id)
	creature.set_meta("diet", diet)
	creature.set_meta("prey_ids", prey_ids)
