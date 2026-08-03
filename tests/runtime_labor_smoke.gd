extends SceneTree

const DFWorldScript = preload("res://df_mode/df_world.gd")
const DFDwarfScript = preload("res://df_mode/df_dwarf.gd")
const DFItemScript = preload("res://df_mode/df_item.gd")
const DFJobScript = preload("res://df_mode/df_job.gd")


func _make_floor_world() -> Object:
	var world = DFWorldScript.new(14, 8, 4)
	for z in range(8):
		for x in range(14):
			var pos := Vector3i(x, 1, z)
			world.set_tile(pos, DFWorldScript.TileType.FLOOR)
			world.set_material(pos, DFWorldScript.MatType.STONE)
	return world


func _run_job(world, worker, job, max_ticks: int = 400) -> bool:
	worker.assign_job(job)
	for simulation_tick in range(1, max_ticks + 1):
		world.set_meta("simulation_tick_total", simulation_tick)
		worker._work_on_job(world)
		if job.state == DFJobScript.JobState.COMPLETED:
			return true
		if job.state == DFJobScript.JobState.CANCELLED:
			return false
	return false


func _test_excavation(failures: Array[String]) -> void:
	var world = _make_floor_world()
	var wall_pos := Vector3i(11, 1, 2)
	world.set_tile(wall_pos, DFWorldScript.TileType.WALL)
	world.set_material(wall_pos, DFWorldScript.MatType.GRANITE)
	var miner = DFDwarfScript.new(Vector3i(2, 1, 2), "Minero de prueba")
	miner.profession = DFDwarfScript.Profession.MINER
	miner.equipped_weapon = "pickaxe"
	world.add_entity(miner)
	var dig_job = DFJobScript.new(DFJobScript.JobType.DIG, wall_pos, 8)
	if not _run_job(world, miner, dig_job):
		failures.append("El trabajo de excavación no terminó.")
	if world.is_wall(wall_pos):
		failures.append("La pared continuó intacta después de excavar.")
	var produced_stone: bool = false
	for item in world.items:
		if item.item_type == "stone":
			produced_stone = true
			break
	if not produced_stone:
		failures.append("Excavar granito no produjo piedra real.")
	if int(miner.stats_tracker.get("distance_traveled", 0)) < 5:
		failures.append("El minero no recorrió realmente la ruta de trabajo.")


func _test_construction(failures: Array[String]) -> void:
	var world = _make_floor_world()
	var builder = DFDwarfScript.new(Vector3i(2, 1, 5), "Constructor de prueba")
	builder.profession = DFDwarfScript.Profession.MASON
	world.add_entity(builder)
	var wood = DFItemScript.new(
		Vector3i(6, 1, 5),
		"Tronco de prueba",
		"wood",
		DFWorldScript.MatType.WOOD,
		"|",
		Color("#8B6914")
	)
	world.add_entity(wood)
	var wall_pos := Vector3i(11, 1, 5)
	var build_job = DFJobScript.new(DFJobScript.JobType.BUILD_WALL, wall_pos, 8)
	if not _run_job(world, builder, build_job):
		failures.append("El trabajo de construcción no terminó.")
	if world.get_tile(wall_pos) != DFWorldScript.TileType.CONSTRUCTED_WALL:
		failures.append("El muro construido no apareció.")
	if world.items.has(wood) or builder.inventory.has(wood):
		failures.append("La madera no fue consumida al completar el muro.")
	if int(builder.stats_tracker.get("distance_traveled", 0)) < 5:
		failures.append("El constructor no recorrió recurso y obra.")


func _initialize() -> void:
	var failures: Array[String] = []
	_test_excavation(failures)
	_test_construction(failures)
	if failures.is_empty():
		print("[LABOR_SMOKE] OK: excavación y construcción completaron cadenas reales.")
		quit(0)
		return
	for failure in failures:
		push_error("[LABOR_SMOKE] %s" % failure)
	quit(1)
