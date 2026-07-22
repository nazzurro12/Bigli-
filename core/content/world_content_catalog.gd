class_name WorldContentCatalog
extends RefCounted
## Catálogo canónico: datos de juego, contenido heredado y mods.

const CONTENT_FOLDERS := ["res://database", "res://mods", "res://df_mode/content_packs", "res://df_mode/mods"]
const VALID_CATEGORIES := ["creatures", "plants", "materials", "items", "entities", "buildings", "reactions"]

static func load_all() -> Dictionary:
	var result := {}
	for category in VALID_CATEGORIES:
		result[category] = []
	for folder in CONTENT_FOLDERS:
		_scan_folder(folder, result)
	return result

static func _scan_folder(path: String, result: Dictionary) -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		return
	directory.list_dir_begin()
	var file_name := directory.get_next()
	while not file_name.is_empty():
		var full_path := path.path_join(file_name)
		if directory.current_is_dir() and not file_name.begins_with("."):
			_scan_folder(full_path, result)
		elif file_name.ends_with(".json"):
			_load_json_pack(full_path, result)
		elif file_name.ends_with(".tres") or file_name.ends_with(".res"):
			var resource := load(full_path)
			if resource != null and resource.has_method("to_game_data") and bool(resource.get("enabled")):
				_add(result, str(resource.get("category")), resource.to_game_data(), full_path)
		file_name = directory.get_next()
	directory.list_dir_end()

static func _load_json_pack(path: String, result: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		push_warning("No se pudo leer el paquete de contenido: %s" % path)
		return
	if typeof(parser.data) != TYPE_DICTIONARY:
		push_warning("El paquete debe ser un objeto JSON: %s" % path)
		return
	for category in VALID_CATEGORIES:
		var definitions = parser.data.get(category, [])
		if typeof(definitions) == TYPE_ARRAY:
			for definition in definitions:
				if typeof(definition) == TYPE_DICTIONARY:
					_add(result, category, definition, path)

static func _add(result: Dictionary, category: String, definition: Dictionary, source_path: String) -> void:
	if not VALID_CATEGORIES.has(category):
		return
	if str(definition.get("id", "")).is_empty():
		push_warning("Definición sin id ignorada en %s" % source_path)
		return
	var clean := definition.duplicate(true)
	clean["source_file"] = source_path
	result[category].append(clean)
