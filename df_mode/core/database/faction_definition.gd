extends Resource
class_name FactionDefinition

@export var id: String = ""
@export var display_name: String = "Faction"
@export var culture: String = ""
@export var technology_level: int = 0
@export var starting_relations: Dictionary = {}
@export var preferred_jobs: PackedStringArray = []
