class_name DFContentDefinition
extends Resource
## Definición genérica editable desde el Inspector de Godot.
## Para añadir contenido no hace falta crear otra clase ni modificar DFData.

@export_category("Identidad")
@export_enum("creatures", "plants", "materials", "items", "entities", "buildings", "reactions") var category: String = "creatures"
@export var id: StringName
@export var display_name: String = "Sin nombre"
@export_multiline var description: String = ""
@export var enabled: bool = true
@export var source_mod: String = "base"
@export_category("Datos del juego")
## Aquí van los campos que ya reconoce Bigliworld: tile, color, size, biomes, type, value, etc.
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
