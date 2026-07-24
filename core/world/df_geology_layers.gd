extends RefCounted
class_name DFGeologyLayers

static var _noise_cache: Dictionary = {}

static func configure_world(world, seed_value: int) -> void:
	if world == null:
		return
	world.geology_seed = seed_value
	world.geology_enabled = true

static func get_material_at(world, pos: Vector3i) -> int:
	var surface: int = world.get_surface_height(pos.x, pos.z)
	var depth: int = maxi(0, surface - pos.y)
	if depth <= 0:
		return world.MatType.SOIL
	var base_material: int = _base_rock(world, pos, depth)
	if depth >= 2 and _vein_value(pos, world.geology_seed + 101, 0.040) > 0.70:
		return world.MatType.COAL
	if depth >= 3 and _vein_value(pos, world.geology_seed + 211, 0.032) > 0.76:
		return world.MatType.IRON
	if depth >= 3 and _vein_value(pos, world.geology_seed + 307, 0.035) > 0.79:
		return world.MatType.COPPER
	if depth >= 3 and _vein_value(pos, world.geology_seed + 401, 0.038) > 0.82:
		return world.MatType.TIN
	if depth >= 4 and _vein_value(pos, world.geology_seed + 503, 0.026) > 0.84:
		return world.MatType.SILVER
	if depth >= 4 and _vein_value(pos, world.geology_seed + 607, 0.022) > 0.87:
		return world.MatType.GOLD
	if depth >= 5 and _vein_value(pos, world.geology_seed + 709, 0.018) > 0.90:
		return world.MatType.PLATINUM
	if depth >= 6 and _vein_value(pos, world.geology_seed + 809, 0.020) > 0.88:
		return world.MatType.OBSIDIAN
	return base_material

static func thin_surface_forest(world, biome: String, seed_value: int) -> int:
	if world == null:
		return 0
	var keep_ratio: float = _tree_keep_ratio(biome)
	var removed: int = 0
	var tree_positions: Array = world.tree_data.keys().duplicate()
	for value in tree_positions:
		var pos: Vector3i = value
		var random_value: float = _hash01(pos.x, pos.z, seed_value)
		if random_value > keep_ratio:
			if world.get_tile(pos) == world.TileType.TREE:
				world.set_tile(pos, world.TileType.GRASS)
				world.set_material(pos, world.MatType.SOIL)
			world.tree_data.erase(pos)
			world.tile_data.erase(pos)
			removed += 1
	return removed

static func _tree_keep_ratio(biome: String) -> float:
	match biome:
		"rainforest", "dense_temperate_forest":
			return 0.78
		"temperate_forest", "pine_forest", "mountain_forest", "taiga":
			return 0.52
		"swamp":
			return 0.40
		"savanna":
			return 0.22
		"grassland", "alpine_meadow":
			return 0.12
		"desert", "badlands", "glacier", "tundra", "beach":
			return 0.03
	return 0.28

static func _base_rock(world, pos: Vector3i, depth: int) -> int:
	var selector: float = _vein_value(pos, world.geology_seed + 17, 0.012)
	if depth <= 1:
		return world.MatType.CLAY if selector > 0.58 else world.MatType.SOIL
	if selector < -0.55:
		return world.MatType.LIMESTONE
	if selector < -0.15:
		return world.MatType.SANDSTONE
	if selector < 0.25:
		return world.MatType.GRANITE
	if selector < 0.60:
		return world.MatType.DIORITE
	return world.MatType.GABBRO

static func _vein_value(pos: Vector3i, seed_value: int, frequency: float) -> float:
	var noise: FastNoiseLite = _get_noise(seed_value, frequency)
	return noise.get_noise_3d(float(pos.x), float(pos.y) * 3.0, float(pos.z))

static func _get_noise(seed_value: int, frequency: float) -> FastNoiseLite:
	var key: String = "%d:%.4f" % [seed_value, frequency]
	if _noise_cache.has(key):
		return _noise_cache[key]
	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.seed = seed_value
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = frequency
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 3
	noise.fractal_gain = 0.5
	_noise_cache[key] = noise
	return noise

static func _hash01(x: int, z: int, seed_value: int) -> float:
	var value: int = x * 73856093 ^ z * 19349663 ^ seed_value * 83492791
	value = abs(value)
	return float(value % 100000) / 100000.0
