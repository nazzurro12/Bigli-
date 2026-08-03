extends SceneTree

const DFWorldScript = preload("res://df_mode/df_world.gd")
const DFDwarfScript = preload("res://df_mode/df_dwarf.gd")
const DFItemScript = preload("res://df_mode/df_item.gd")
const DFJobScript = preload("res://df_mode/df_job.gd")
const DFStockpileScript = preload("res://df_mode/df_stockpile.gd")


func _initialize() -> void:
	var world = DFWorldScript.new(12, 6, 4)
	for z in range(6):
		for x in range(12):
			var floor_pos := Vector3i(x, 1, z)
			world.set_tile(floor_pos, DFWorldScript.TileType.FLOOR)
			world.set_material(floor_pos, DFWorldScript.MatType.STONE)

	var worker = DFDwarfScript.new(Vector3i(2, 1, 2), "Recolector de prueba")
	worker.profession = DFDwarfScript.Profession.MINER
	world.add_entity(worker)

	# El recurso está lejos: la prueba exige navegación de ida.
	var stone = DFItemScript.new(
		Vector3i(9, 1, 2),
		"Piedra de prueba",
		"stone",
		DFWorldScript.MatType.STONE,
		"*",
		Color.GRAY
	)
	world.add_entity(stone)

	# El almacén está detrás del punto inicial: también exige viaje de regreso.
	var stockpile = DFStockpileScript.new([Vector3i(1, 1, 2)])
	world.stockpiles.append(stockpile)

	var job = DFJobScript.new(DFJobScript.JobType.COLLECT_STONE, stone.tile_pos, 8)
	job.set_meta("target_item_id", stone.id)
	worker.assign_job(job)

	var completed: bool = false
	for simulation_tick in range(1, 301):
		world.set_meta("simulation_tick_total", simulation_tick)
		if worker._execute_collect_job(world, "stone"):
			completed = true
			break

	var failures: Array[String] = []
	if not completed:
		failures.append("No terminó en 300 ticks.")
	if worker.inventory.has(stone):
		failures.append("La piedra quedó atrapada en el inventario.")
	if not world.items.has(stone):
		failures.append("La piedra desapareció del mundo al depositarse.")
	if not stone.is_in_stockpile:
		failures.append("La piedra no fue marcada como almacenada.")
	if stone.tile_pos != Vector3i(1, 1, 2):
		failures.append("La piedra no terminó en el almacén.")
	if stone.carried_by_id != -1:
		failures.append("La piedra conserva un transportista.")
	if int(worker.stats_tracker.get("distance_traveled", 0)) < 8:
		failures.append("La prueba no recorrió realmente ida y regreso.")

	if failures.is_empty():
		print("[COLLECTION_SMOKE] OK: caminó, recogió y almacenó el objeto exacto.")
		quit(0)
		return
	for failure in failures:
		push_error("[COLLECTION_SMOKE] %s" % failure)
	quit(1)
