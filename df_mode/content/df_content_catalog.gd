class_name DFContentCatalog
extends RefCounted
## Lee definiciones de Resources y JSON de forma recursiva.
## Las carpetas se mantienen separadas del código para permitir contenido y mods.

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
		if directory.current_is_dir():
			if not file_name.begins_with("."):
				_scan_folder(full_path, result)
		elif file_name.ends_with(".tres") or file_name.ends_with(".res"):
			var resource := load(full_path)
			if resource is DFContentDefinition and resource.enabled:
				_add(result, resource.category, resource.to_game_data(), full_path)
		elif file_name.ends_with(".json"):
			_load_json_pack(full_path, result)
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
	var pack = parser.data
	if typeof(pack) != TYPE_DICTIONARY:
		push_warning("El paquete debe ser un objeto JSON: %s" % path)
		return
	for category in VALID_CATEGORIES:
		var definitions = pack.get(category, [])
		if typeof(definitions) != TYPE_ARRAY:
			continue
		for definition in definitions:
			if typeof(definition) == TYPE_DICTIONARY:
				_add(result, category, definition, path)

static func _add(result: Dictionary, category: String, definition: Dictionary, source_path: String) -> void:
	if not VALID_CATEGORIES.has(category):
		return
	var id := str(definition.get("id", ""))
	if id.is_empty():
		push_warning("Definición sin id ignorada en %s" % source_path)
		return
	var clean := definition.duplicate(true)
	clean["source_file"] = source_path
	result[category].append(clean)
