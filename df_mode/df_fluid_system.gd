extends RefCounted
class_name DFFluidSystem

## Simulación hidráulica basada en autómatas celulares (7 niveles de fluido)
## y ciclo meteorológico de congelamiento / descongelamiento.

static var _active_fluids: Dictionary = {}
static var _tick_budget: int = 128

static func register_fluid(pos: Vector3i, level: int) -> void:
	if level > 0:
		_active_fluids[pos] = clampi(level, 1, 7)
	else:
		_active_fluids.erase(pos)

static func get_fluid_level(pos: Vector3i) -> int:
	return int(_active_fluids.get(pos, 0))

static func process_fluids(world) -> void:
	if world == null or _active_fluids.is_empty():
		return

	var keys: Array = _active_fluids.keys()
	var processed_count: int = 0
	keys.shuffle()

	for pos_val in keys:
		if processed_count >= _tick_budget:
			break
		processed_count += 1

		var pos: Vector3i = pos_val
		var level: int = int(_active_fluids.get(pos, 0))
		if level <= 0:
			_active_fluids.erase(pos)
			continue

		# 1. PASO VERTICAL (Gravedad): Descender si la celda inferior es transitable
		var below := Vector3i(pos.x, pos.y - 1, pos.z)
		if pos.y > 0 and _can_fluid_flow_to(world, below):
			var below_level: int = int(_active_fluids.get(below, 0))
			if below_level < 7:
				var transfer: int = mini(level, 7 - below_level)
				var new_below: int = below_level + transfer
				var new_current: int = level - transfer

				register_fluid(below, new_below)
				register_fluid(pos, new_current)
				_update_world_tile(world, below, new_below)
				_update_world_tile(world, pos, new_current)
				continue

		# 2. PASO HORIZONTAL (Presión e Igualación): Esparcir a vecinos
		var dirs = [Vector3i(-1, 0, 0), Vector3i(1, 0, 0), Vector3i(0, 0, -1), Vector3i(0, 0, 1)]
		dirs.shuffle()
		for d in dirs:
			var n: Vector3i = pos + d
			if n.x < 0 or n.x >= world.width or n.z < 0 or n.z >= world.depth:
				continue
			if not _can_fluid_flow_to(world, n):
				continue

			var n_level: int = int(_active_fluids.get(n, 0))
			if level > n_level + 1:
				var diff: int = (level - n_level) / 2
				if diff > 0:
					register_fluid(n, n_level + diff)
					register_fluid(pos, level - diff)
					_update_world_tile(world, n, n_level + diff)
					_update_world_tile(world, pos, level - diff)
					break

static func _can_fluid_flow_to(world, pos: Vector3i) -> bool:
	if pos.x < 0 or pos.x >= world.width or pos.z < 0 or pos.z >= world.depth:
		return false
	var t: int = world.get_tile(pos)
	if t in [DFWorld.TileType.WALL, DFWorld.TileType.CAVE_WALL, DFWorld.TileType.CONSTRUCTED_WALL, DFWorld.TileType.FORTIFICATION]:
		return false
	return true

static func _update_world_tile(world, pos: Vector3i, level: int) -> void:
	if level >= 5:
		var t_cur: int = world.get_tile(pos)
		if t_cur not in [DFWorld.TileType.WATER_DEEP, DFWorld.TileType.WATER_SHALLOW]:
			world.set_meta("orig_tile_" + str(pos), t_cur)
		world.set_tile(pos, DFWorld.TileType.WATER_DEEP)
	elif level >= 1:
		var t_cur: int = world.get_tile(pos)
		if t_cur not in [DFWorld.TileType.WATER_DEEP, DFWorld.TileType.WATER_SHALLOW]:
			world.set_meta("orig_tile_" + str(pos), t_cur)
		world.set_tile(pos, DFWorld.TileType.WATER_SHALLOW)
	else:
		var current_t: int = world.get_tile(pos)
		if current_t in [DFWorld.TileType.WATER_DEEP, DFWorld.TileType.WATER_SHALLOW]:
			var default_tile: int = DFWorld.TileType.GRASS if pos.y >= 3 else DFWorld.TileType.CAVE_FLOOR
			var orig: int = int(world.get_meta("orig_tile_" + str(pos), default_tile))
			world.set_tile(pos, orig)

static func process_temperature_freeze_thaw(world, current_season: String) -> void:
	if world == null:
		return
	var is_winter: bool = (current_season == "Winter" or current_season == "Invierno")

	for pos in _active_fluids.keys():
		var t: int = world.get_tile(pos)
		if is_winter:
			if t in [DFWorld.TileType.WATER_SHALLOW, DFWorld.TileType.WATER_DEEP]:
				world.set_tile(pos, DFWorld.TileType.ICE)
		else:
			if t == DFWorld.TileType.ICE:
				var lvl: int = get_fluid_level(pos)
				_update_world_tile(world, pos, lvl if lvl > 0 else 4)
