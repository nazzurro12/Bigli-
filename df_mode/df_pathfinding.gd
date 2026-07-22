extends RefCounted
class_name DFPathfinding

static var _path_cache: Dictionary = {}
static var _cache_max_size: int = 512
static var _world_version: int = 0

static func bump_world_version() -> void:
	_world_version += 1
	if _path_cache.size() > _cache_max_size * 2:
		_path_cache.clear()

static func _cache_key(from: Vector3i, to: Vector3i, use_ramps: bool) -> String:
	return "%d,%d,%d->%d,%d,%d_%s" % [from.x, from.y, from.z, to.x, to.y, to.z, "r" if use_ramps else "f"]

static func find_path(world, from: Vector3i, to: Vector3i, use_dwarf_rules: bool = true) -> Array:
	var DFWorld = preload("res://df_mode/df_world.gd")
	var actual_to = to
	
	# If target is solid (wall, tree) or generally blocked, redirect to the nearest passable neighbor
	var target_blocked = false
	if world.has_method("is_wall") and world.is_wall(to):
		target_blocked = true
	elif world.has_method("get_tile") and world.get_tile(to) == world.TileType.TREE:
		target_blocked = true
	elif world.has_method("is_blocked") and world.is_blocked(to):
		target_blocked = true
		
	if target_blocked:
		var dirs = [Vector3i(-1,0,0), Vector3i(1,0,0), Vector3i(0,0,-1), Vector3i(0,0,1), Vector3i(0,1,0), Vector3i(0,-1,0)]
		var best_n = to
		var best_dist = 999999.0
		for d in dirs:
			var n = to + d
			if n.x < 0 or n.x >= world.width or n.z < 0 or n.z >= world.depth:
				continue
			var passable = false
			if use_dwarf_rules:
				passable = world.is_stair(n) or world.is_floor(n) or world.is_open_space(n)
				if passable and world.get_tile(n) == world.TileType.TREE:
					passable = false
			else:
				passable = not world.is_blocked(n)
				
			if passable:
				var dist = _heuristic(from, n)
				if dist < best_dist:
					best_dist = dist
					best_n = n
		actual_to = best_n
		if from == actual_to:
			return [from]

	var key = _cache_key(from, actual_to, use_dwarf_rules)
	var cached = _path_cache.get(key)
	if cached != null and cached.has("version") and cached["version"] == _world_version:
		return cached["path"].duplicate()

	var path = _find_path_internal(world, from, actual_to, use_dwarf_rules)

	if _path_cache.size() >= _cache_max_size:
		var keys = _path_cache.keys()
		for i in range(_cache_max_size / 4):
			_path_cache.erase(keys[i])
	_path_cache[key] = {"path": path.duplicate(), "version": _world_version}
	return path

static func _find_path_internal(world, from: Vector3i, to: Vector3i, use_dwarf_rules: bool) -> Array:
	var open_heap: Array = []
	var open_set: Dictionary = {}
	var closed_set: Dictionary = {}
	var came_from: Dictionary = {}
	var g_score: Dictionary = {}

	var start_key = _key(from)
	var goal_key = _key(to)
	g_score[start_key] = 0
	_heap_push(open_heap, from, _heuristic(from, to))
	open_set[start_key] = true

	var iterations = 0
	var max_iter = 5000
	while not open_heap.is_empty() and iterations < max_iter:
		iterations += 1
		var current = _heap_pop(open_heap)
		var current_key = _key(current)
		open_set.erase(current_key)

		if current_key == goal_key:
			return _reconstruct_path(came_from, current)

		if closed_set.has(current_key):
			continue
		closed_set[current_key] = true

		var neighbors = _get_neighbors(world, current, use_dwarf_rules)
		for next in neighbors:
			var n_key = _key(next)
			if closed_set.has(n_key):
				continue
			var tentative_g = g_score.get(current_key, 999999) + 1
			if tentative_g < g_score.get(n_key, 999999):
				came_from[n_key] = current
				g_score[n_key] = tentative_g
				if not open_set.has(n_key):
					var f = tentative_g + _heuristic(next, to)
					_heap_push(open_heap, next, f)
					open_set[n_key] = true

	return []

static func _get_neighbors(world, pos: Vector3i, use_dwarf_rules: bool) -> Array:
	if use_dwarf_rules:
		return _get_dwarf_neighbors(world, pos)
	else:
		return _get_creature_neighbors(world, pos)

static func _get_dwarf_neighbors(world, pos: Vector3i) -> Array:
	var result = []
	var dirs = [Vector3i(-1, 0, 0), Vector3i(1, 0, 0), Vector3i(0, 0, -1), Vector3i(0, 0, 1)]
	for d in dirs:
		var n = pos + d
		if n.x < 0 or n.x >= world.width or n.z < 0 or n.z >= world.depth:
			continue
		if world.is_stair(n) or world.is_floor(n) or world.is_open_space(n):
			if world.get_tile(n) != world.TileType.TREE:
				result.append(n)
	var up = Vector3i(pos.x, pos.y + 1, pos.z)
	var t_pos = world.get_tile(pos)
	if t_pos in [world.TileType.STAIRS_UP, world.TileType.STAIRS_UPDOWN, world.TileType.RAMP]:
		if world.is_stair(up) or world.is_floor(up) or world.is_open_space(up):
			result.append(up)
	var down = Vector3i(pos.x, pos.y - 1, pos.z)
	if t_pos in [world.TileType.STAIRS_DOWN, world.TileType.STAIRS_UPDOWN, world.TileType.RAMP]:
		if world.is_stair(down) or world.is_floor(down) or world.is_open_space(down):
			result.append(down)
	return result

static func _get_creature_neighbors(world, pos: Vector3i) -> Array:
	var result = []
	var dirs = [Vector3i(-1, 0, 0), Vector3i(1, 0, 0), Vector3i(0, 0, -1), Vector3i(0, 0, 1)]
	for d in dirs:
		var n = pos + d
		if n.x < 0 or n.x >= world.width or n.z < 0 or n.z >= world.depth:
			continue
		if not world.is_blocked(n):
			result.append(n)
	var up = Vector3i(pos.x, pos.y + 1, pos.z)
	if world.is_stair(pos) or world.is_stair(up):
		if not world.is_blocked(up):
			result.append(up)
	var down = Vector3i(pos.x, pos.y - 1, pos.z)
	if world.is_stair(pos) or world.is_stair(down):
		if not world.is_blocked(down):
			result.append(down)
	return result

static func _heuristic(a: Vector3i, b: Vector3i) -> float:
	return abs(a.x - b.x) + abs(a.z - b.z) + abs(a.y - b.y) * 2.0

static func _reconstruct_path(came_from: Dictionary, current: Vector3i) -> Array:
	var p = [current]
	var key = _key(current)
	while came_from.has(key):
		current = came_from[key]
		p.push_front(current)
		key = _key(current)
	return p

static func _key(v: Vector3i) -> String:
	return "%d,%d,%d" % [v.x, v.y, v.z]

static func _heap_push(heap: Array, item: Variant, priority: float) -> void:
	heap.append([item, priority])
	var i = heap.size() - 1
	while i > 0:
		var parent = (i - 1) / 2
		if heap[parent][1] <= heap[i][1]:
			break
		var tmp = heap[parent]
		heap[parent] = heap[i]
		heap[i] = tmp
		i = parent

static func _heap_pop(heap: Array) -> Variant:
	if heap.is_empty():
		return null
	var result = heap[0][0]
	var last = heap.pop_back()
	if not heap.is_empty():
		heap[0] = last
		_sift_down(heap, 0)
	return result

static func _sift_down(heap: Array, idx: int) -> void:
	var size = heap.size()
	while true:
		var smallest = idx
		var left = idx * 2 + 1
		var right = idx * 2 + 2
		if left < size and heap[left][1] < heap[smallest][1]:
			smallest = left
		if right < size and heap[right][1] < heap[smallest][1]:
			smallest = right
		if smallest == idx:
			break
		var tmp = heap[idx]
		heap[idx] = heap[smallest]
		heap[smallest] = tmp
		idx = smallest
