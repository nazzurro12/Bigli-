extends SceneTree

const MAIN_SCENE_PATH: String = "res://df_mode/df_main.tscn"
const EXCLUDED_DIRECTORIES: Array[String] = [
	"res://.git",
	"res://.godot",
	"res://addons",
]

var _failures: PackedStringArray = PackedStringArray()


func _initialize() -> void:
	call_deferred("_run_smoke_test")


func _run_smoke_test() -> void:
	print("[SMOKE] Comprobando scripts GDScript...")
	var script_paths: PackedStringArray = PackedStringArray()
	_collect_scripts("res://", script_paths)
	script_paths.sort()

	for script_path: String in script_paths:
		var script_resource: Resource = ResourceLoader.load(
			script_path,
			"",
			ResourceLoader.CACHE_MODE_REPLACE
		)
		if script_resource == null:
			_failures.append("No se pudo cargar %s" % script_path)

	print("[SMOKE] %d scripts cargados." % script_paths.size())
	print("[SMOKE] Instanciando %s..." % MAIN_SCENE_PATH)

	var packed_scene: PackedScene = ResourceLoader.load(
		MAIN_SCENE_PATH,
		"PackedScene",
		ResourceLoader.CACHE_MODE_REPLACE
	) as PackedScene
	if packed_scene == null:
		_failures.append("No se pudo cargar la escena principal.")
		_finish()
		return

	var main_instance: Node = packed_scene.instantiate()
	if main_instance == null:
		_failures.append("No se pudo instanciar la escena principal.")
		_finish()
		return

	root.add_child(main_instance)
	for _frame_index: int in range(8):
		await process_frame

	if not is_instance_valid(main_instance) or main_instance.is_queued_for_deletion():
		_failures.append("La escena principal se cerró durante el arranque.")
	else:
		main_instance.queue_free()
		await process_frame

	_finish()


func _collect_scripts(directory_path: String, output: PackedStringArray) -> void:
	if _is_excluded(directory_path):
		return
	var directory: DirAccess = DirAccess.open(directory_path)
	if directory == null:
		_failures.append("No se pudo abrir %s" % directory_path)
		return

	directory.list_dir_begin()
	var entry_name: String = directory.get_next()
	while not entry_name.is_empty():
		if entry_name != "." and entry_name != "..":
			var entry_path: String = directory_path.path_join(entry_name)
			if directory.current_is_dir():
				_collect_scripts(entry_path, output)
			elif entry_name.ends_with(".gd"):
				output.append(entry_path)
		entry_name = directory.get_next()
	directory.list_dir_end()


func _is_excluded(path: String) -> bool:
	for excluded_path: String in EXCLUDED_DIRECTORIES:
		if path == excluded_path or path.begins_with(excluded_path + "/"):
			return true
	return false


func _finish() -> void:
	if _failures.is_empty():
		print("[SMOKE] OK: scripts y escena principal cargaron correctamente.")
		quit(0)
		return

	for failure: String in _failures:
		push_error("[SMOKE] %s" % failure)
	print("[SMOKE] FALLÓ con %d problema(s)." % _failures.size())
	quit(1)
