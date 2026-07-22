class_name WorldContentDefinition
extends Resource
## Recurso canónico del motor para añadir contenido desde el Inspector.

@export_category("Identidad")
@export_enum("creatures", "plants", "materials", "items", "entities", "buildings", "reactions") var category := "creatures"
@export var id: StringName
@export var display_name := "Sin nombre"
@export_multiline var description := ""
@export var enabled := true
@export var source_mod := "base"
@export_category("Datos del juego")
@export var data: Dictionary = {}

func to_game_data() -> Dictionary:
	var result := data.duplicate(true)
	result["id"] = str(id)
	if not display_name.is_empty():
		result["name"] = display_name
	if not description.is_empty():
		result["description"] = description
	result["source_mod"] = source_mod
	return result
