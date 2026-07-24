extends SceneTree

func _init() -> void:
	print("Instantiating DFMain scene...")
	var scene = load("res://df_mode/df_main.tscn")
	var node = scene.instantiate()
	root.add_child(node)
	
	# Wait for ready and start generation
	await create_timer(0.5).timeout
	
	# Keep ticking for a few frames
	for i in range(10):
		await create_timer(0.1).timeout
		print("Frame ", i, " ticks:")
		if node.world != null:
			print("Entities count: ", node.world.entities.size())
			var idx = 0
			for e in node.world.entities:
				var nm = e.get("name") if e.get("name") != null else "Unnamed"
				var alive = e.get("is_alive") == true
				var pos = e.get("tile_pos")
				var is_dwarf = e is DFDwarf
				print("  [", idx, "] Name: ", nm, ", IsDwarf: ", is_dwarf, ", Alive: ", alive, ", Pos: ", pos)
				idx += 1
		else:
			print("  World is null!")
	quit()
