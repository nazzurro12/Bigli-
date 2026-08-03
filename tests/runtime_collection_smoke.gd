extends SceneTree

const DFWorldScript = preload("res://df_mode/df_world.gd")
const DFDwarfScript = preload("res://df_mode/df_dwarf.gd")
const DFItemScript = preload("res://df_mode/df_item.gd")
const DFJobScript = preload("res://df_mode/df_job.gd")
const DFStockpileScript = preload("res://df_mode/df_stockpile.gd")


func _initialize() -> void:
	var world = DFWorldScript.new(8, 8, 4)
	for z in range(8):
		for x in range(8):
			var floor_pos := Vector3i(x, 1, z)
			world.set_tile(floor_pos, DFWorldScript.TileType.FLOOR)
			world.set_material(floor_pos, DFWorldScript.MatType.STONE)
	world.set_meta("simulation_tick_total", 1)

	var worker = DFDwarfScript.new(Vector3i(2, 1, 2), "Recolector de prueba")
	worker.profession = DFDwarfScript.Profession.MINER
	world.add_entity(worker)

	var stone = DFItemScript.new(
		Vector3i(3, 1, 2),
		"Piedra de prueba",
		"stone",
		DFWorldScript.MatType.STONE,
		"*",
		Color.GRAY
	)
	world.add_entity(stone)

	var stockpile = DFStockpileScript.new([Vector3i(2, 1, 2)])
	world.stockpiles.append(stockpile)

	var job = DFJobScript.new(DFJobScript.JobType.COLLECT_STONE, stone.tile_pos, 8)
	job.set_meta("target_item_id", stone.id)
	worker.assign_job(job)

	var completed: bool = worker._execute_collect_job(world, "stone")
	var failures: Array[String] = []
	if not completed:
		failures.append("La cadena de recolección no informó finalización.")
	if worker.inventory.has(stone):
		failures.append("La piedra quedó atrapada en el inventario.")
	if not world.items.has(stone):
		failures.append("La piedra desapareció del mundo al depositarse.")
	if not stone.is_in_stockpile:
		failures.append("La piedra no fue marcada como almacenada.")
	if stone.tile_pos != Vector3i(2, 1, 2):
		failures.append("La piedra no terminó en la casilla del almacén.")
	if stone.carried_by_id != -1:
		failures.append("La piedra conserva un transportista después de almacenarse.")

	if failures.is_empty():
		print("[COLLECTION_SMOKE] OK: suelo -> inventario -> almacén.")
		quit(0)
		return
	for failure in failures:
		push_error("[COLLECTION_SMOKE] %s" % failure)
	quit(1)
