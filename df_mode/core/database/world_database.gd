extends Resource
class_name WorldDatabase

@export var creatures: Array[CreatureDefinition] = []
@export var factions: Array[FactionDefinition] = []

func get_creature(id: String) -> CreatureDefinition:
	for definition in creatures:
		if definition.id.to_lower() == id.to_lower():
			return definition
	return null

func get_faction(id: String) -> FactionDefinition:
	for definition in factions:
		if definition.id == id:
			return definition
	return null
