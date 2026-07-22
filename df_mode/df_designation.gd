extends RefCounted
class_name DFDesignation

const DFWorld = preload("res://df_mode/df_world.gd")
const DFJob = preload("res://df_mode/df_job.gd")
const DFStockpile = preload("res://df_mode/df_stockpile.gd")

enum DesignationMode {
	NONE,
	DIG,
	CHOP,
	BUILD_WALL,
	BUILD_FLOOR,
	STAIRS_UP,
	STAIRS_DOWN,
	SMOOTH,
	STOCKPILE,
	REMOVE_DESIGNATION,
	FARM_PLOT,
	BUILD_WORKSHOP,
	QUERY_WORKSHOP,
	DECONSTRUCT
}

var mode: int = DesignationMode.NONE
var selection_start: Vector3i = Vector3i(-1, -1, -1)
var selection_end: Vector3i = Vector3i(-1, -1, -1)
var is_selecting: bool = false
var world = null
var job_queue: Array = []
var building_type_to_build: int = 1 # Default: Smelter

func _init(w):
	world = w

func get_mode_name() -> String:
	match mode:
		DesignationMode.NONE: return "View"
		DesignationMode.DIG: return "Dig"
		DesignationMode.CHOP: return "Chop Trees"
		DesignationMode.BUILD_WALL: return "Build Wall"
		DesignationMode.BUILD_FLOOR: return "Build Floor"
		DesignationMode.STAIRS_UP: return "Stairs Up"
		DesignationMode.STAIRS_DOWN: return "Stairs Down"
		DesignationMode.SMOOTH: return "Smooth Stone"
		DesignationMode.STOCKPILE: return "Stockpile"
		DesignationMode.FARM_PLOT: return "Farm Plot"
		DesignationMode.BUILD_WORKSHOP: return "Build Workshop"
		DesignationMode.QUERY_WORKSHOP: return "Query Workshop"
		DesignationMode.REMOVE_DESIGNATION: return "Remove Designation"
		DesignationMode.DECONSTRUCT: return "Deconstruct"
	return "View"

func get_mode_color() -> Color:
	match mode:
		DesignationMode.DIG: return Color("#FFAA00")
		DesignationMode.CHOP: return Color("#00FF44")
		DesignationMode.BUILD_WALL: return Color("#AAAAAA")
		DesignationMode.BUILD_FLOOR: return Color("#886644")
		DesignationMode.STAIRS_UP: return Color("#FFFFFF")
		DesignationMode.STAIRS_DOWN: return Color("#FFFFFF")
		DesignationMode.SMOOTH: return Color("#88AAFF")
		DesignationMode.STOCKPILE: return Color("#888844")
		DesignationMode.FARM_PLOT: return Color("#5C3A1E")
		DesignationMode.BUILD_WORKSHOP: return Color("#CC5533")
		DesignationMode.QUERY_WORKSHOP: return Color.WHITE
		DesignationMode.REMOVE_DESIGNATION: return Color("#FF0000")
		DesignationMode.DECONSTRUCT: return Color("#FF3333")
		_: return Color("#FFFF00")

func set_mode(new_mode: int) -> void:
	if new_mode != DesignationMode.NONE and new_mode != DesignationMode.REMOVE_DESIGNATION:
		mode = new_mode
		is_selecting = false
	elif new_mode == DesignationMode.NONE:
		mode = DesignationMode.NONE
		is_selecting = false

func toggle_remove_mode() -> void:
	if mode == DesignationMode.REMOVE_DESIGNATION:
		mode = DesignationMode.NONE
	else:
		mode = DesignationMode.REMOVE_DESIGNATION
	is_selecting = false

func start_selection(pos: Vector3i) -> void:
	if mode == DesignationMode.NONE:
		return
	selection_start = pos
	selection_end = pos
	is_selecting = true

func update_selection(pos: Vector3i) -> void:
	if not is_selecting:
		return
	selection_end = pos

func confirm_selection() -> int:
	if mode == DesignationMode.NONE or not is_selecting:
		return 0
	if mode == DesignationMode.REMOVE_DESIGNATION:
		return _remove_jobs_in_area()
	return _create_jobs_in_area()

func cancel_selection() -> void:
	is_selecting = false

func get_selection_rect() -> Rect2i:
	if not is_selecting:
		return Rect2i(0, 0, 0, 0)
	var min_x = min(selection_start.x, selection_end.x)
	var min_z = min(selection_start.z, selection_end.z)
	var max_x = max(selection_start.x, selection_end.x)
	var max_z = max(selection_start.z, selection_end.z)
	return Rect2i(min_x, min_z, max_x - min_x + 1, max_z - min_z + 1)

func is_in_selection(pos: Vector3i) -> bool:
	if not is_selecting:
		return false
	var r = get_selection_rect()
	return pos.x >= r.position.x and pos.x < r.position.x + r.size.x and \
		pos.z >= r.position.y and pos.z < r.position.y + r.size.y

func has_job_at(pos: Vector3i, job_type: int = -1) -> bool:
	for j in job_queue:
		if j.tile_pos == pos and j.state != DFJob.JobState.COMPLETED and j.state != DFJob.JobState.CANCELLED:
			if job_type == -1 or j.job_type == job_type:
				return true
	return false

func get_job_at(pos: Vector3i, job_type: int = -1) -> DFJob:
	for j in job_queue:
		if j.tile_pos == pos and j.state != DFJob.JobState.COMPLETED and j.state != DFJob.JobState.CANCELLED:
			if job_type == -1 or j.job_type == job_type:
				return j
	return null

func _create_jobs_in_area() -> int:
	var count = 0
	var r = get_selection_rect()
	var y_level = selection_start.y
	for z in range(r.position.y, r.position.y + r.size.y):
		for x in range(r.position.x, r.position.x + r.size.x):
			var pos = Vector3i(x, y_level, z)
			if _can_create_job_at(pos):
				var job_type = _mode_to_job_type()
				if job_type >= 0 and not has_job_at(pos, job_type):
					if _is_valid_for_job(pos, job_type):
						var job = DFJob.new(job_type, pos)
						if job_type == DFJob.JobType.BUILD_WORKSHOP:
							var DFBuilding = preload("res://df_mode/df_building.gd")
							var b = DFBuilding.new(building_type_to_build, pos)
							b.is_constructed = false
							world.buildings.append(b)
							job.result_tile_type = building_type_to_build
							# A workshop is 3x3, but for now we'll just queue one job for the top-left tile.
							# To avoid spamming 9 jobs, we could skip the inner loop if it's a workshop.
							
						job_queue.append(job)
						count += 1
						if job_type == DFJob.JobType.BUILD_WORKSHOP:
							break # Solo coloca un taller en el click
			if mode == DesignationMode.BUILD_WORKSHOP and count > 0:
				break
	
	if mode == DesignationMode.STOCKPILE:
		var stockpile_tiles = []
		for z_164 in range(r.position.y, r.position.y + r.size.y):
			for x_165 in range(r.position.x, r.position.x + r.size.x):
				var pos_166 = Vector3i(x_165, selection_start.y, z_164)
				if world.is_floor(pos_166):
					stockpile_tiles.append(pos_166)
		if stockpile_tiles.size() > 0:
			var sp = DFStockpile.new(stockpile_tiles)
			world.stockpiles.append(sp)
			count += stockpile_tiles.size()

	if mode == DesignationMode.FARM_PLOT:
		for z_175 in range(r.position.y, r.position.y + r.size.y):
			for x_176 in range(r.position.x, r.position.x + r.size.x):
				var pos_177 = Vector3i(x_176, selection_start.y, z_175)
				if world.make_farm_plot(pos_177):
					count += 1

	is_selecting = false
	return count

func _remove_jobs_in_area() -> int:
	var count = 0
	var r = get_selection_rect()
	var to_remove = []
	var y_level = selection_start.y
	for j in job_queue:
		if j.state == DFJob.JobState.UNASSIGNED or j.state == DFJob.JobState.ASSIGNED:
			if j.tile_pos.y == y_level and j.tile_pos.x >= r.position.x and j.tile_pos.x < r.position.x + r.size.x and \
			   j.tile_pos.z >= r.position.y and j.tile_pos.z < r.position.y + r.size.y:
				to_remove.append(j)
				count += 1
	for j_195 in to_remove:
		job_queue.erase(j_195)
	is_selecting = false
	return count

func _can_create_job_at(pos: Vector3i) -> bool:
	if pos.x < 0 or pos.x >= world.width or pos.z < 0 or pos.z >= world.depth:
		return false
	if world.is_water(pos):
		return false
	return true

func _is_valid_for_job(pos: Vector3i, job_type: int) -> bool:
	match job_type:
		DFJob.JobType.DIG:
			return world.is_wall(pos)
		DFJob.JobType.CHOP_TREE:
			return world.get_tile(pos) == DFWorld.TileType.TREE
		DFJob.JobType.BUILD_WALL:
			return world.is_floor(pos) or world.is_open_space(pos)
		DFJob.JobType.BUILD_FLOOR:
			return world.is_open_space(pos) or world.get_tile(pos) == DFWorld.TileType.CAVE_WALL
		DFJob.JobType.BUILD_STAIRS_UP:
			return world.is_wall(pos) or world.is_floor(pos)
		DFJob.JobType.BUILD_STAIRS_DOWN:
			return world.is_wall(pos) or world.is_floor(pos)
		DFJob.JobType.SMOOTH:
			return world.get_tile(pos) == DFWorld.TileType.STONE_FLOOR or world.get_tile(pos) == DFWorld.TileType.CAVE_FLOOR
		DFJob.JobType.FARM_PLANT:
			return world.get_tile(pos) == DFWorld.TileType.FARM_SOIL and not world.growing_crops.has(pos)
		DFJob.JobType.FARM_HARVEST:
			return world.get_tile(pos) == DFWorld.TileType.FARM_SOIL and world.is_grown_crop(pos)
		DFJob.JobType.BUILD_WORKSHOP:
			return world.is_floor(pos) or world.is_open_space(pos)
		DFJob.JobType.DECONSTRUCT:
			return world.get_tile(pos) in [DFWorld.TileType.CONSTRUCTED_WALL, DFWorld.TileType.CONSTRUCTED_FLOOR]
	return true

func _mode_to_job_type() -> int:
	match mode:
		DesignationMode.DIG: return DFJob.JobType.DIG
		DesignationMode.CHOP: return DFJob.JobType.CHOP_TREE
		DesignationMode.BUILD_WALL: return DFJob.JobType.BUILD_WALL
		DesignationMode.BUILD_FLOOR: return DFJob.JobType.BUILD_FLOOR
		DesignationMode.STAIRS_UP: return DFJob.JobType.BUILD_STAIRS_UP
		DesignationMode.STAIRS_DOWN: return DFJob.JobType.BUILD_STAIRS_DOWN
		DesignationMode.SMOOTH: return DFJob.JobType.SMOOTH
		DesignationMode.BUILD_WORKSHOP: return DFJob.JobType.BUILD_WORKSHOP
		DesignationMode.DECONSTRUCT: return DFJob.JobType.DECONSTRUCT
	return -1

func _get_height_at(x: int, z: int) -> int:
	if world != null:
		return world.get_surface_height(x, z)
	return 3

func get_next_unassigned_job() -> DFJob:
	for j in job_queue:
		if j.state == DFJob.JobState.UNASSIGNED:
			return j
	return null

func get_assigned_jobs(dwarf_id: int) -> Array:
	var result = []
	for j in job_queue:
		if j.assigned_dwarf_id == dwarf_id and j.state in [DFJob.JobState.ASSIGNED, DFJob.JobState.IN_PROGRESS]:
			result.append(j)
	return result

func get_pending_count() -> int:
	var count = 0
	for j in job_queue:
		if j.state == DFJob.JobState.UNASSIGNED:
			count += 1
	return count

func get_active_count() -> int:
	var count = 0
	for j in job_queue:
		if j.state in [DFJob.JobState.ASSIGNED, DFJob.JobState.IN_PROGRESS]:
			count += 1
	return count

func apply(world_ref, tile: Vector3i) -> void:
	if mode == DesignationMode.REMOVE_DESIGNATION:
		_remove_single_job(tile)
		return
	if mode == DesignationMode.NONE:
		return
	if not is_selecting:
		start_selection(tile)
	else:
		update_selection(tile)
		confirm_selection()

func _remove_single_job(pos: Vector3i) -> void:
	var to_remove = []
	for j in job_queue:
		if j.tile_pos == pos and j.state in [DFJob.JobState.UNASSIGNED, DFJob.JobState.ASSIGNED]:
			to_remove.append(j)
	for j_292 in to_remove:
		job_queue.erase(j_292)

func cancel_last() -> void:
	if is_selecting:
		cancel_selection()
		return
	for i in range(job_queue.size() - 1, -1, -1):
		if job_queue[i].state == DFJob.JobState.UNASSIGNED:
			job_queue.remove_at(i)
			break
