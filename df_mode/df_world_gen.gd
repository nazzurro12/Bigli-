extends RefCounted
class_name DFWorldGen

const DFWorld = preload("res://df_mode/df_world.gd")
const DFNamegen = preload("res://df_mode/df_namegen.gd")
const DFData = preload("res://df_mode/df_data.gd")
const WorldGenerationSettings = preload("res://world/world_generation_settings.gd")
const DFWorldHydrology = preload("res://df_mode/df_world_hydrology.gd")
const DFWorldSites = preload("res://df_mode/df_world_sites.gd")

const BIOME_FALLBACK: String = "grassland"

var rng: RandomNumberGenerator
var namegen: DFNamegen
var generation_settings: WorldGenerationSettings
var _noise_cache: Dictionary = {}

var world_name: String = ""
var world_width: int = 1024
var world_depth: int = 1024
var sea_level_value: int = 30
var local_region_span: float = 6.0

# Los mapas mundiales usan filas Packed* para que un mundo de 1024² no
# consuma cientos de megabytes en Variants de GDScript.
var elevation_map: Array = []
var rainfall_map: Array = []
var temperature_map: Array = []
var biome_map: Array = []
var river_map: Array = []
var river_order_map: Array = []
var lake_map: Array = []
var flow_direction_map: Array = []
var flow_accumulation_map: Array = []
var watershed_map: Array = []
var landmass_map: Array = []
var landmass_sizes: Dictionary = {}
var ocean_distance_map: Array = []
var drainage_map: Array = []
var vegetation_map: Array = []
var savagery_map: Array = []
var evil_map: Array = []
var geological_map: Array = [] # Perfil geológico compacto por región.
var volcanism_map: Array = []
var magma_map: Array = []
var aquifer_map: Array = []
var road_map: Array = []
var site_lookup: Dictionary = {}

var civs: Array = []
var sites: Array = []
var history_events: Array = []
var creatures: Array = []

var world_curse: String = ""
var world_curse_description: String = ""
var lore_seed: int = 0
var civ_lineages: Dictionary = {}
var world_alignment: String = "Neutral"
var setting_beast_density: int = 1
var embark_pos: Vector2i = Vector2i(-1, -1)
var setting_civ_density: int = 1

var config_tree_density: float = 1.0
var config_tree_spacing: int = 2
var config_ore_density: float = 1.0
var config_hidden_mines_chance: float = 0.3
var config_berry_bush_chance: float = 0.05
var config_cactus_chance: float = 0.05
var config_mountain_strength: float = 0.95
var config_rainfall: float = 1.0
var config_river_density: float = 1.15
var config_site_density: float = 1.0
var config_world_chunk_size: int = 64
var config_local_map_size: int = 256

func _init(seed_value: int = -1) -> void:
	rng = RandomNumberGenerator.new()
	generation_settings = load("res://world/world_generation_settings.tres") as WorldGenerationSettings
	if generation_settings != null:
		config_tree_density = generation_settings.tree_density
		config_ore_density = generation_settings.ore_density
		config_hidden_mines_chance = generation_settings.hidden_caves_chance
		config_mountain_strength = generation_settings.mountain_strength
		config_rainfall = generation_settings.rainfall
		config_river_density = generation_settings.river_density
		config_site_density = generation_settings.site_density
		config_world_chunk_size = generation_settings.world_chunk_size
		config_local_map_size = generation_settings.local_map_size
		sea_level_value = clampi(roundi(generation_settings.sea_level * 100.0), 12, 55)
	var selected_seed: int = seed_value
	if selected_seed < 0:
		selected_seed = generation_settings.seed if generation_settings != null else randi()
	rng.seed = selected_seed

func generate(world: Object, seed_value: int = -1, build_local_map_immediately: bool = false) -> void:
	if seed_value >= 0:
		rng.seed = seed_value
	_noise_cache.clear()
	namegen = DFNamegen.new(rng.randi())
	lore_seed = rng.randi()
	world_name = namegen.generate_world_name()
	world_curse = _generate_curse()
	history_events.clear()
	road_map.clear()
	site_lookup.clear()

	add_history_event(0, "ERA", "=== LA CREACIÓN DE %s ===" % world_name)
	add_history_event(0, "ERA", "Las placas primordiales se separan y levantan continentes.")
	_generate_elevation()
	_generate_landmasses()
	_generate_ocean_distance()
	_generate_temperature()
	_generate_rainfall()
	_generate_hydrology()
	_generate_biomes()
	_generate_vegetation()
	_generate_savagery()
	_generate_evil()
	add_history_event(0, "ERA", "Cuencas, lagos, afluentes y grandes ríos atraviesan la tierra.")

	_generate_geology()
	_generate_magma()
	_generate_aquifers()
	add_history_event(0, "ERA", "Estratos, acuíferos y cámaras magmáticas quedan ocultos bajo el mundo.")
	add_history_event(0, "ERA", world_curse_description)

	if build_local_map_immediately and world != null:
		generate_local_map(world)

func _get_world_sample(x: int, z: int, local_w: int, local_d: int) -> Vector2:
	var safe_w: float = maxf(1.0, float(local_w))
	var safe_d: float = maxf(1.0, float(local_d))
	if embark_pos.x >= 0:
		var half_span: float = local_region_span * 0.5
		var gx: float = float(embark_pos.x) - half_span + ((float(x) + 0.5) / safe_w) * local_region_span
		var gz: float = float(embark_pos.y) - half_span + ((float(z) + 0.5) / safe_d) * local_region_span
		return Vector2(clampf(gx, 0.0, float(world_width - 1)), clampf(gz, 0.0, float(world_depth - 1)))
	var gx_full: float = ((float(x) + 0.5) / safe_w) * float(world_width - 1)
	var gz_full: float = ((float(z) + 0.5) / safe_d) * float(world_depth - 1)
	return Vector2(clampf(gx_full, 0.0, float(world_width - 1)), clampf(gz_full, 0.0, float(world_depth - 1)))

func _get_world_coords(x: int, z: int, local_w: int, local_d: int) -> Vector2i:
	var sample: Vector2 = _get_world_sample(x, z, local_w, local_d)
	return Vector2i(clampi(floori(sample.x), 0, world_width - 1), clampi(floori(sample.y), 0, world_depth - 1))

func _sample_local_elevation(x: int, z: int, local_w: int, local_d: int) -> float:
	var sample: Vector2 = _get_world_sample(x, z, local_w, local_d)
	var x0: int = clampi(floori(sample.x), 0, world_width - 1)
	var z0: int = clampi(floori(sample.y), 0, world_depth - 1)
	var x1: int = mini(x0 + 1, world_width - 1)
	var z1: int = mini(z0 + 1, world_depth - 1)
	var tx: float = clampf(sample.x - float(x0), 0.0, 1.0)
	var tz: float = clampf(sample.y - float(z0), 0.0, 1.0)
	var h00: float = float(elevation_map[z0][x0])
	var h10: float = float(elevation_map[z0][x1])
	var h01: float = float(elevation_map[z1][x0])
	var h11: float = float(elevation_map[z1][x1])
	var raw_height: float = lerpf(lerpf(h00, h10, tx), lerpf(h01, h11, tx), tz)
	var local_height: float
	if raw_height <= float(sea_level_value):
		local_height = clampf(raw_height / maxf(1.0, float(sea_level_value)) * 2.0, 0.0, 2.0)
	else:
		local_height = 2.0 + ((raw_height - float(sea_level_value)) / maxf(1.0, 100.0 - float(sea_level_value))) * 10.0
	var seed_offset: float = float(int(rng.seed) % 10007)
	var detail: float = _octave_noise(float(x) + seed_offset, float(z) - seed_offset, 3, 0.55, 34.0) * 0.34
	return clampf(local_height + detail, 0.0, 12.0)

func _is_local_river(x: int, z: int, local_w: int, local_d: int) -> bool:
	var sample: Vector2 = _get_world_sample(x, z, local_w, local_d)
	var wx: int = clampi(floori(sample.x), 0, world_width - 1)
	var wz: int = clampi(floori(sample.y), 0, world_depth - 1)
	if not is_river(wx, wz):
		return false
	var order: int = maxi(1, get_river_order(wx, wz))
	var width_fraction: float = 0.018 + float(order) * 0.012
	var fx: float = sample.x - floor(sample.x)
	var fz: float = sample.y - floor(sample.y)
	var phase: float = float((_coord_hash(wx, wz, 41) % 628)) / 100.0
	var center: float = 0.5 + sin(float(wx + wz) * 0.31 + phase) * 0.16
	var direction_index: int = int(flow_direction_map[wz][wx]) if not flow_direction_map.is_empty() else DFWorldHydrology.NO_DIRECTION
	if direction_index < 0 or direction_index >= DFWorldHydrology.DIRECTIONS.size():
		return absf(fx - center) < width_fraction
	var direction: Vector2i = DFWorldHydrology.DIRECTIONS[direction_index]
	if direction.x == 0:
		return absf(fx - center) < width_fraction
	if direction.y == 0:
		return absf(fz - center) < width_fraction
	var diagonal_offset: float = (center - 0.5) * 0.8
	if direction.x == direction.y:
		return absf((fz - fx) - diagonal_offset) < width_fraction * 1.35
	return absf((fz + fx - 1.0) - diagonal_offset) < width_fraction * 1.35

func _is_local_lake(x: int, z: int, local_w: int, local_d: int) -> bool:
	var coords: Vector2i = _get_world_coords(x, z, local_w, local_d)
	if not is_lake(coords.x, coords.y):
		return false
	var edge_noise: float = _octave_noise(float(x), float(z), 2, 0.5, 18.0) * 0.5 + 0.5
	return edge_noise > 0.18

func generate_local_map(world: Object, embark_pt: Vector2i = Vector2i(-1, -1)) -> void:
	embark_pos = embark_pt
	world.tiles.clear()
	world.tile_data.clear()
	world.elevation = []
	for z in range(world.depth):
		var row: Array[int] = []
		row.resize(world.width)
		for x in range(world.width):
			row[x] = clampi(roundi(_sample_local_elevation(x, z, world.width, world.depth)), 0, 12)
		world.elevation.append(row)

	_place_terrain_in_local(world)
	_place_trees_in_local(world)
	_place_flora_in_local(world)
	_place_features_in_local(world)
	_place_ore_in_local(world)
	_generate_creatures()
	# Los asentamientos se materializan al final para que árboles, flora y vetas
	# no reaparezcan dentro de calles, paredes, habitaciones o campos.
	if embark_pos.x >= 0 and not sites.is_empty():
		DFWorldSites.materialize_nearby_sites(world, self, embark_pos)

func _generate_name() -> String:
	var prefixes = ["Ara", "Bel", "Cal", "Dor", "Ere", "Fal", "Gar", "Hal", "Ith", "Kel",
		"Lor", "Mor", "Nor", "Oth", "Pel", "Quen", "Ral", "Sil", "Tal", "Ur",
		"Val", "Wen", "Xan", "Yor", "Zol", "Bri", "Dag", "Fir", "Gor", "Hel",
		"Iron", "Bronze", "Gold", "Silver", "Copper", "Stone", "Ash", "Crimson",
		"Azure", "Emerald", "Onyx", "Ruby", "Sapphire", "Crystal", "Shadow", "Dawn"]
	var suffixes = ["dor", "mar", "nor", "vir", "dal", "bar", "thar", "mir", "lor", "nis",
		"dur", "fal", "gar", "hon", "kar", "lon", "mand", "nan", "rion", "sia",
		"tar", "van", "wyr", "zar", "thal", "lund", "morn", "rath", "stead", "wick",
		"deep", "peak", "vale", "heim", "mark", "gard", "lund", "hold", "heim"]
	return prefixes[rng.randi() % prefixes.size()] + suffixes[rng.randi() % suffixes.size()]

func _generate_curse() -> String:
	var curses = ["Neutral", "Neutral", "Neutral", "Good", "Good", "Evil", "Sinister", "Haunted", "Terrifying"]
	var c = curses[rng.randi() % curses.size()]
	var curse_descriptions = {
		"Good": [
			"La tierra esta bendecida con paz y abundancia. La conciencia florece sin miedo.",
			"Los ecos de los cuarenta y ocho resuenan armoniosos en cada valle.",
			"El sol brilla con la promesa de que las preguntas encontraran respuesta."
		],
		"Evil": [
			"Un velo oscuro cubre la tierra. La conciencia duele aqui.",
			"Las sombras guardan rencor. Los muertos susurran secretos que los vivos no deberIan saber.",
			"El VacIo Potencial se filtra por las grietas de la realidad."
		],
		"Sinister": [
			"Fuerzas siniestras se reUnen en las sombras. Algo observa desde el Otro Lado.",
			"Las preguntas de los cuarenta y ocho encontraron respuestas equivocadas."
		],
		"Haunted": [
			"Los muertos no descansan. Las almas de los que no hallaron respuesta vagan sin rumbo.",
			"El mundo recuerda cada vida, cada muerte, cada pregunta sin respuesta."
		],
		"Terrifying": [
			"Horrores indescriptibles acechan en lo salvaje. La conciencia aqui es una maldicion.",
			"El tejido de la realidad es delgado. Algo del otro lado esta tocando."
		]
	}
	var desc_list = curse_descriptions.get(c, ["La tierra es salvaje e indomable."])
	world_curse_description = desc_list[rng.randi() % desc_list.size()]
	var curse_names = {"Good": "Bendito", "Evil": "Malvado", "Sinister": "Siniestro", "Haunted": "Embrujado", "Terrifying": "Aterrador", "Neutral": "Neutral"}
	world_alignment = curse_names.get(c, "Neutral")
	return c

func _noise2d(x: float, y: float) -> float:
	# La semilla forma parte del hash. Antes, gran parte del clima conservaba
	# el mismo patrón entre mundos aunque cambiaran las placas continentales.
	var seed_component: int = int(rng.seed & 0x7fffffff)
	var n: int = int(floor(x)) + int(floor(y)) * 373 + seed_component * 1013
	n = (n << 13) ^ n
	var nn: int = (n * (n * n * 60493 + 19990303) + 1376312589) & 0x7fffffff
	return 1.0 - float(nn) / 1073741824.0

func _smooth_noise(x: float, y: float, scale: float) -> float:
	var sx = x / scale; var sy = y / scale
	var ix = int(floor(sx)); var iy = int(floor(sy))
	var fx = sx - ix; var fy = sy - iy
	fx = fx * fx * (3.0 - 2.0 * fx)
	fy = fy * fy * (3.0 - 2.0 * fy)
	var v00 = _noise2d(ix, iy); var v10 = _noise2d(ix + 1, iy)
	var v01 = _noise2d(ix, iy + 1); var v11 = _noise2d(ix + 1, iy + 1)
	return v00 + (v10 - v00) * fx + ((v01 + (v11 - v01) * fx) - (v00 + (v10 - v00) * fx)) * fy

func _octave_noise(x: float, y: float, octaves: int, persistence: float, scale: float) -> float:
	# FastNoiseLite ejecuta los octavos en código nativo. En un mundo de 1024²
	# esto evita cientos de millones de operaciones interpretadas en GDScript.
	var safe_scale: float = maxf(0.001, scale)
	var cache_key: String = "%d:%.4f:%.4f" % [octaves, persistence, safe_scale]
	var noise_variant: Variant = _noise_cache.get(cache_key, null)
	var noise: FastNoiseLite
	if noise_variant is FastNoiseLite:
		noise = noise_variant
	else:
		noise = FastNoiseLite.new()
		var hashed_seed: int = int((int(rng.seed) & 0x7fffffff) ^ (hash(cache_key) & 0x7fffffff))
		noise.seed = hashed_seed
		noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		noise.frequency = 1.0 / safe_scale
		noise.fractal_type = FastNoiseLite.FRACTAL_FBM
		noise.fractal_octaves = maxi(1, octaves)
		noise.fractal_gain = clampf(persistence, 0.0, 1.0)
		noise.fractal_lacunarity = 2.0
		_noise_cache[cache_key] = noise
	return noise.get_noise_2d(x, y)


func _generate_elevation() -> void:
	elevation_map.clear()
	var plate_count: int = clampi(int(round(sqrt(float(world_width * world_depth)) / 85.0)), 8, 18)
	var plates: Array = []
	for plate_index in range(plate_count):
		plates.append({
			"center": Vector2(rng.randf_range(0.08, 0.92), rng.randf_range(0.08, 0.92)),
			"radius": rng.randf_range(0.18, 0.42),
			"uplift": rng.randf_range(-0.18, 0.36),
			"ridge": rng.randf_range(0.4, 1.0)
		})
	for z in range(world_depth):
		var row := PackedByteArray()
		row.resize(world_width)
		var nz: float = float(z) / maxf(1.0, float(world_depth - 1))
		for x in range(world_width):
			var nx: float = float(x) / maxf(1.0, float(world_width - 1))
			var continental_noise: float = _octave_noise(float(x), float(z), 5, 0.56, float(world_width) * 0.46)
			var detail_noise: float = _octave_noise(float(x) + 1907.0, float(z) - 881.0, 4, 0.52, float(world_width) * 0.075)
			var plate_field: float = 0.0
			var ridge_field: float = 0.0
			var point := Vector2(nx, nz)
			for plate_variant in plates:
				var plate: Dictionary = plate_variant
				var center: Vector2 = plate["center"]
				var radius: float = float(plate["radius"])
				var distance: float = point.distance_to(center)
				var influence: float = clampf(1.0 - distance / radius, 0.0, 1.0)
				influence = influence * influence * (3.0 - 2.0 * influence)
				plate_field += influence * float(plate["uplift"])
				var boundary: float = 1.0 - absf(distance - radius * 0.66) / maxf(0.001, radius * 0.24)
				ridge_field = maxf(ridge_field, clampf(boundary, 0.0, 1.0) * float(plate["ridge"]))
			var edge_distance: float = minf(minf(nx, 1.0 - nx), minf(nz, 1.0 - nz))
			var edge_falloff: float = smoothstep(0.0, 0.095, edge_distance)
			var ridge_noise: float = 1.0 - absf(_octave_noise(float(x) + 700.0, float(z) + 1300.0, 4, 0.52, float(world_width) * 0.095))
			ridge_noise = pow(clampf(ridge_noise, 0.0, 1.0), 3.0)
			var normalized: float = 0.47 + continental_noise * 0.21 + plate_field * 0.50
			normalized += ridge_field * ridge_noise * 0.20 * config_mountain_strength
			normalized += detail_noise * 0.055
			normalized *= edge_falloff
			row[x] = clampi(roundi(clampf(normalized, 0.0, 1.0) * 100.0), 0, 100)
		elevation_map.append(row)
	# Una sola pasada suave elimina píxeles aislados sin borrar cordilleras.
	var smoothed: Array = []
	for smooth_z in range(world_depth):
		var smooth_row := PackedByteArray()
		smooth_row.resize(world_width)
		for smooth_x in range(world_width):
			var smooth_total: int = int(elevation_map[smooth_z][smooth_x]) * 4
			var smooth_weight: int = 4
			for smooth_direction in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
				var smooth_nx: int = smooth_x + smooth_direction.x
				var smooth_nz: int = smooth_z + smooth_direction.y
				if smooth_nx >= 0 and smooth_nx < world_width and smooth_nz >= 0 and smooth_nz < world_depth:
					smooth_total += int(elevation_map[smooth_nz][smooth_nx])
					smooth_weight += 1
			smooth_row[smooth_x] = clampi(roundi(float(smooth_total) / float(smooth_weight)), 0, 100)
		smoothed.append(smooth_row)
	elevation_map = smoothed

func is_ocean(x: int, z: int) -> bool:
	if z < 0 or z >= world_depth or x < 0 or x >= world_width:
		return true
	return int(elevation_map[z][x]) <= sea_level_value

func is_river(x: int, z: int) -> bool:
	return z >= 0 and z < river_map.size() and x >= 0 and x < river_map[z].size() and int(river_map[z][x]) != 0

func is_lake(x: int, z: int) -> bool:
	return z >= 0 and z < lake_map.size() and x >= 0 and x < lake_map[z].size() and int(lake_map[z][x]) != 0

func is_road(x: int, z: int) -> bool:
	return z >= 0 and z < road_map.size() and x >= 0 and x < road_map[z].size() and int(road_map[z][x]) != 0

func get_river_order(x: int, z: int) -> int:
	if z < 0 or z >= river_order_map.size() or x < 0 or x >= river_order_map[z].size():
		return 0
	return int(river_order_map[z][x])

func get_biome(x: int, z: int) -> String:
	if z < 0 or z >= biome_map.size() or x < 0 or x >= biome_map[z].size():
		return BIOME_FALLBACK
	return str(biome_map[z][x])

func get_site_at(x: int, z: int) -> Dictionary:
	return site_lookup.get("%d:%d" % [x, z], {})

func get_landmass_id(x: int, z: int) -> int:
	if z < 0 or z >= landmass_map.size() or x < 0 or x >= landmass_map[z].size():
		return -1
	return int(landmass_map[z][x])

func get_landmass_size(landmass_id: int) -> int:
	return int(landmass_sizes.get(landmass_id, 0))

func get_world_chunk(position: Vector2i) -> Vector2i:
	var safe_chunk_size: int = maxi(1, config_world_chunk_size)
	return Vector2i(
		clampi(int(position.x / safe_chunk_size), 0, int((world_width - 1) / safe_chunk_size)),
		clampi(int(position.y / safe_chunk_size), 0, int((world_depth - 1) / safe_chunk_size))
	)

func get_region_summary(position: Vector2i) -> Dictionary:
	var x: int = clampi(position.x, 0, world_width - 1)
	var z: int = clampi(position.y, 0, world_depth - 1)
	return {
		"position": Vector2i(x, z),
		"chunk": get_world_chunk(Vector2i(x, z)),
		"biome": get_biome(x, z),
		"elevation": int(elevation_map[z][x]),
		"rainfall": float(rainfall_map[z][x]),
		"temperature": float(temperature_map[z][x]),
		"drainage": float(drainage_map[z][x]),
		"savagery": float(savagery_map[z][x]),
		"alignment": float(evil_map[z][x]),
		"is_river": is_river(x, z),
		"river_order": get_river_order(x, z),
		"watershed_id": int(watershed_map[z][x]) if not watershed_map.is_empty() else -1,
		"landmass_id": get_landmass_id(x, z),
		"landmass_size": get_landmass_size(get_landmass_id(x, z)),
		"is_lake": is_lake(x, z),
		"is_road": is_road(x, z),
		"site": get_site_at(x, z)
	}

func _generate_landmasses() -> void:
	landmass_map.clear()
	landmass_sizes.clear()
	for z in range(world_depth):
		var row := PackedInt32Array()
		row.resize(world_width)
		row.fill(-1)
		landmass_map.append(row)

	var total: int = world_width * world_depth
	var queue := PackedInt32Array()
	queue.resize(total)
	var next_landmass_id: int = 0
	var cardinal: Array[Vector2i] = [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]
	for start_z in range(world_depth):
		for start_x in range(world_width):
			if is_ocean(start_x, start_z) or int(landmass_map[start_z][start_x]) >= 0:
				continue
			var head: int = 0
			var tail: int = 0
			queue[tail] = start_z * world_width + start_x
			tail += 1
			landmass_map[start_z][start_x] = next_landmass_id
			var region_count: int = 0
			while head < tail:
				var current_idx: int = int(queue[head])
				head += 1
				region_count += 1
				var current_x: int = current_idx % world_width
				var current_z: int = int(current_idx / world_width)
				for direction in cardinal:
					var nx: int = current_x + direction.x
					var nz: int = current_z + direction.y
					if nx < 0 or nx >= world_width or nz < 0 or nz >= world_depth:
						continue
					if is_ocean(nx, nz) or int(landmass_map[nz][nx]) >= 0:
						continue
					landmass_map[nz][nx] = next_landmass_id
					queue[tail] = nz * world_width + nx
					tail += 1
			landmass_sizes[next_landmass_id] = region_count
			next_landmass_id += 1

func _generate_ocean_distance() -> void:
	var total: int = world_width * world_depth
	var distance_flat := PackedInt32Array()
	distance_flat.resize(total)
	distance_flat.fill(-1)
	var queue := PackedInt32Array()
	queue.resize(total)
	var tail_index: int = 0
	for z in range(world_depth):
		for x in range(world_width):
			if is_ocean(x, z):
				var idx: int = z * world_width + x
				distance_flat[idx] = 0
				queue[tail_index] = idx
				tail_index += 1
	var head_index: int = 0
	var cardinal: Array[Vector2i] = [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]
	while head_index < tail_index:
		var queue_idx: int = int(queue[head_index])
		head_index += 1
		var queue_x: int = queue_idx % world_width
		var queue_z: int = int(queue_idx / world_width)
		var next_distance: int = int(distance_flat[queue_idx]) + 1
		for cardinal_direction in cardinal:
			var neighbor_x: int = queue_x + cardinal_direction.x
			var neighbor_z: int = queue_z + cardinal_direction.y
			if neighbor_x < 0 or neighbor_x >= world_width or neighbor_z < 0 or neighbor_z >= world_depth:
				continue
			var neighbor_idx: int = neighbor_z * world_width + neighbor_x
			if distance_flat[neighbor_idx] >= 0:
				continue
			distance_flat[neighbor_idx] = next_distance
			queue[tail_index] = neighbor_idx
			tail_index += 1
	ocean_distance_map.clear()
	for distance_z in range(world_depth):
		var distance_row := PackedInt32Array()
		distance_row.resize(world_width)
		for distance_x in range(world_width):
			distance_row[distance_x] = distance_flat[distance_z * world_width + distance_x]
		ocean_distance_map.append(distance_row)

func _generate_temperature() -> void:
	temperature_map.clear()
	for z in range(world_depth):
		var row := PackedFloat32Array()
		row.resize(world_width)
		var latitude: float = 1.0 - absf(float(z) - float(world_depth - 1) * 0.5) / maxf(1.0, float(world_depth - 1) * 0.5)
		for x in range(world_width):
			var elevation_normalized: float = float(elevation_map[z][x]) / 100.0
			var climate_noise: float = _octave_noise(float(x) + 2999.0, float(z) - 2111.0, 3, 0.5, float(world_width) * 0.24) * 0.11
			var altitude_cooling: float = maxf(0.0, elevation_normalized - float(sea_level_value) / 100.0) * 0.62
			row[x] = clampf(latitude * 0.86 + 0.10 + climate_noise - altitude_cooling, 0.0, 1.0)
		temperature_map.append(row)

func _generate_rainfall() -> void:
	rainfall_map.clear()
	for z in range(world_depth):
		var row := PackedFloat32Array()
		row.resize(world_width)
		var airborne_moisture: float = 1.05
		var previous_elevation: float = float(elevation_map[z][0])
		for x in range(world_width):
			var elevation: float = float(elevation_map[z][x])
			if is_ocean(x, z):
				airborne_moisture = minf(1.25, airborne_moisture + 0.08)
			var rise: float = maxf(0.0, elevation - previous_elevation) / 100.0
			var fall: float = maxf(0.0, previous_elevation - elevation) / 100.0
			var distance_to_ocean: float = float(ocean_distance_map[z][x])
			var coastal_factor: float = exp(-distance_to_ocean / maxf(20.0, float(world_width) * 0.085))
			var noise: float = _octave_noise(float(x) - 1700.0, float(z) + 900.0, 4, 0.55, float(world_width) * 0.13) * 0.5 + 0.5
			var rain: float = 0.16 + noise * 0.36 + coastal_factor * 0.30 + airborne_moisture * 0.20 + rise * 1.65 - fall * 0.42
			rain = clampf(rain * config_rainfall, 0.0, 1.0)
			row[x] = rain
			airborne_moisture = clampf(airborne_moisture - rain * 0.018 - rise * 0.12 + coastal_factor * 0.012, 0.12, 1.25)
			previous_elevation = elevation
		rainfall_map.append(row)

func _distance_to_water(x: int, z: int) -> float:
	if z < 0 or z >= ocean_distance_map.size() or x < 0 or x >= ocean_distance_map[z].size():
		return float(maxi(world_width, world_depth))
	return float(ocean_distance_map[z][x])

func _generate_hydrology() -> void:
	var hydrology: Dictionary = DFWorldHydrology.generate(elevation_map, rainfall_map, world_width, world_depth, sea_level_value, config_river_density)
	flow_direction_map = hydrology.get("flow_direction", [])
	flow_accumulation_map = hydrology.get("flow_accumulation", [])
	watershed_map = hydrology.get("watershed", [])
	river_map = hydrology.get("river", [])
	river_order_map = hydrology.get("river_order", [])
	lake_map = hydrology.get("lake", [])
	drainage_map = hydrology.get("drainage", [])

func _generate_rivers() -> void:
	_generate_hydrology()

func _generate_drainage() -> void:
	if drainage_map.is_empty():
		_generate_hydrology()

func _generate_biomes() -> void:
	biome_map.clear()
	for z in range(world_depth):
		var row := PackedStringArray()
		row.resize(world_width)
		for x in range(world_width):
			var elevation: float = float(elevation_map[z][x]) / 100.0
			var rain: float = float(rainfall_map[z][x])
			var temperature: float = float(temperature_map[z][x])
			var drainage: float = float(drainage_map[z][x])
			var biome: String = BIOME_FALLBACK
			if is_ocean(x, z):
				biome = "ocean_deep" if int(elevation_map[z][x]) < sea_level_value - 9 else "ocean_shallow"
			elif is_lake(x, z):
				biome = "lake"
			elif int(elevation_map[z][x]) <= sea_level_value + 2:
				biome = "beach" if rain < 0.65 else "swamp"
			elif elevation >= 0.84:
				biome = "glacier" if temperature < 0.34 else "mountain"
			elif elevation >= 0.72:
				if temperature < 0.26:
					biome = "tundra"
				elif rain > 0.62:
					biome = "mountain_forest"
				else:
					biome = "alpine_meadow"
			elif temperature < 0.20:
				biome = "tundra"
			elif temperature < 0.38:
				biome = "taiga" if rain > 0.42 else "tundra"
			elif temperature > 0.76:
				if rain < 0.24:
					biome = "desert"
				elif rain < 0.46:
					biome = "savanna"
				elif rain > 0.76:
					biome = "rainforest"
				else:
					biome = "tropical_forest"
			else:
				if rain < 0.20:
					biome = "badlands"
				elif rain < 0.38:
					biome = "grassland"
				elif rain < 0.64:
					biome = "temperate_forest"
				elif drainage < 0.40:
					biome = "swamp"
				else:
					biome = "dense_temperate_forest"
			row[x] = biome
		biome_map.append(row)

func _generate_vegetation() -> void:
	vegetation_map.clear()
	for z in range(world_depth):
		var row := PackedFloat32Array()
		row.resize(world_width)
		for x in range(world_width):
			var biome: String = get_biome(x, z)
			var rain: float = float(rainfall_map[z][x])
			var base: float
			match biome:
				"rainforest": base = 0.95
				"dense_temperate_forest", "tropical_forest": base = 0.78
				"temperate_forest", "pine_forest", "mountain_forest": base = 0.62
				"taiga": base = 0.44
				"swamp": base = 0.50
				"savanna": base = 0.24
				"grassland", "alpine_meadow": base = 0.12
				_: base = 0.025
			var patch_noise: float = _octave_noise(float(x) + 777.0, float(z) - 333.0, 3, 0.5, 36.0) * 0.10
			row[x] = clampf(base * (0.55 + rain * 0.65) + patch_noise, 0.0, 1.0)
		vegetation_map.append(row)

func _generate_savagery() -> void:
	savagery_map.clear()
	for z in range(world_depth):
		var row := PackedFloat32Array()
		row.resize(world_width)
		for x in range(world_width):
			var wilderness: float = _octave_noise(float(x) + 4400.0, float(z) + 1100.0, 4, 0.58, float(world_width) * 0.09) * 0.5 + 0.5
			var remoteness: float = clampf(float(ocean_distance_map[z][x]) / maxf(20.0, float(world_width) * 0.18), 0.0, 1.0)
			var mountain_bonus: float = clampf((float(elevation_map[z][x]) - 65.0) / 35.0, 0.0, 1.0) * 0.22
			row[x] = clampf(wilderness * 0.66 + remoteness * 0.22 + mountain_bonus, 0.0, 1.0)
		savagery_map.append(row)

func _generate_evil() -> void:
	evil_map.clear()
	var curse_bonus: float = 0.42 if world_curse in ["Evil", "Sinister", "Haunted", "Terrifying"] else -0.08 if world_curse == "Good" else 0.0
	for z in range(world_depth):
		var row := PackedFloat32Array()
		row.resize(world_width)
		for x in range(world_width):
			var regional: float = _octave_noise(float(x) - 6000.0, float(z) + 5100.0, 4, 0.56, float(world_width) * 0.15) * 0.5 + 0.5
			row[x] = clampf(regional + curse_bonus, 0.0, 1.0)
		evil_map.append(row)

func _generate_geology() -> void:
	geological_map.clear()
	volcanism_map.clear()
	for z in range(world_depth):
		var profile_row := PackedByteArray()
		var volcanism_row := PackedFloat32Array()
		profile_row.resize(world_width)
		volcanism_row.resize(world_width)
		for x in range(world_width):
			var volcanic: float = _octave_noise(float(x) + 8100.0, float(z) - 9200.0, 4, 0.55, float(world_width) * 0.075) * 0.5 + 0.5
			var metamorphic: float = _octave_noise(float(x) - 2500.0, float(z) + 7200.0, 3, 0.5, float(world_width) * 0.11) * 0.5 + 0.5
			var elevation: int = int(elevation_map[z][x])
			var profile: int = 0
			if volcanic > 0.78:
				profile = 3
			elif elevation > 72 and metamorphic > 0.48:
				profile = 2
			elif elevation > 58:
				profile = 1
			elif metamorphic > 0.70:
				profile = 4
			profile_row[x] = profile
			volcanism_row[x] = volcanic
		geological_map.append(profile_row)
		volcanism_map.append(volcanism_row)

func _get_geology_layers(wx: int, wz: int) -> Array[String]:
	if wz < 0 or wz >= geological_map.size() or wx < 0 or wx >= geological_map[wz].size():
		return ["SOIL", "LIMESTONE", "GRANITE", "GNEISS", "INFERNALITE"]
	var profile: int = int(geological_map[wz][wx])
	var biome: String = get_biome(wx, wz)
	var layers: Array[String] = []
	if biome in ["desert", "beach"]:
		layers.append("SAND")
	elif biome == "swamp":
		layers.append("PEAT")
	elif biome not in ["mountain", "glacier"]:
		layers.append("SOIL")
	match profile:
		0:
			layers.append_array(["CLAYSTONE", "LIMESTONE", "SANDSTONE", "DOLOMITE", "GRANITE", "GNEISS"])
		1:
			layers.append_array(["GRANITE", "DIORITE", "GABBRO", "BASALT", "GNEISS"])
		2:
			layers.append_array(["SLATE", "MARBLE", "QUARTZITE", "SCHIST", "GNEISS", "GRANITE"])
		3:
			layers.append_array(["BASALT", "OBSIDIAN", "GABBRO", "GRANITE", "INFERNALITE"])
		_:
			layers.append_array(["SANDSTONE", "MARBLE", "DIORITE", "GNEISS", "GRANITE"])
	if layers.back() != "INFERNALITE":
		layers.append("INFERNALITE")
	return layers

func _generate_magma() -> void:
	magma_map.clear()
	for z in range(world_depth):
		var row := PackedByteArray()
		row.resize(world_width)
		for x in range(world_width):
			var volcanic: float = float(volcanism_map[z][x]) if not volcanism_map.is_empty() else 0.0
			var deep_noise: float = _octave_noise(float(x) + 13000.0, float(z) - 17000.0, 2, 0.5, 31.0) * 0.5 + 0.5
			row[x] = 1 if int(elevation_map[z][x]) > sea_level_value + 8 and volcanic > 0.83 and deep_noise > 0.54 else 0
		magma_map.append(row)

func _generate_aquifers() -> void:
	aquifer_map.clear()
	for z in range(world_depth):
		var row := PackedByteArray()
		row.resize(world_width)
		for x in range(world_width):
			var rain: float = float(rainfall_map[z][x])
			var drainage: float = float(drainage_map[z][x])
			var profile: int = int(geological_map[z][x])
			var suitable_rock: bool = profile in [0, 4]
			row[x] = 1 if not is_ocean(x, z) and rain > 0.48 and drainage < 0.72 and (suitable_rock or rain > 0.76) else 0
		aquifer_map.append(row)

func rebuild_civilized_world() -> void:
	var result: Dictionary = DFWorldSites.build_civilized_world(self, civs, sites, int(rng.seed))
	road_map = result.get("road_map", [])
	site_lookup = result.get("site_lookup", {})
	sites = result.get("sites", sites)

func find_best_site_for_race(race: String, used_positions: Array = []) -> Vector2i:
	var best := Vector2i(int(world_width / 2), int(world_depth / 2))
	var best_score: float = -INF
	var attempts: int = clampi(int(1600.0 * config_site_density), 800, 4000)
	var margin: int = maxi(12, int(world_width / 80))
	for attempt in range(attempts):
		var x: int = rng.randi_range(margin, world_width - margin - 1)
		var z: int = rng.randi_range(margin, world_depth - margin - 1)
		if is_ocean(x, z) or is_lake(x, z):
			continue
		var too_close: bool = false
		var minimum_distance: float = maxf(24.0, float(world_width) * 0.045)
		for used_variant in used_positions:
			var used: Vector2i = used_variant
			if Vector2i(x, z).distance_to(used) < minimum_distance:
				too_close = true
				break
		if too_close:
			continue
		var score: float = _site_score(race, x, z)
		if score > best_score:
			best_score = score
			best = Vector2i(x, z)
	return best

func find_site_near(race: String, origin: Vector2i, used_positions: Array = []) -> Vector2i:
	var best: Vector2i = origin
	var best_score: float = -INF
	var radius: int = maxi(28, int(world_width / 9))
	for attempt in range(900):
		var x: int = clampi(origin.x + rng.randi_range(-radius, radius), 4, world_width - 5)
		var z: int = clampi(origin.y + rng.randi_range(-radius, radius), 4, world_depth - 5)
		if is_ocean(x, z) or is_lake(x, z):
			continue
		var too_close: bool = false
		for used_variant in used_positions:
			var used: Vector2i = used_variant
			if Vector2i(x, z).distance_to(used) < 10.0:
				too_close = true
				break
		if too_close:
			continue
		var distance_penalty: float = Vector2i(x, z).distance_to(origin) * 0.035
		var score: float = _site_score(race, x, z) - distance_penalty
		if score > best_score:
			best_score = score
			best = Vector2i(x, z)
	return best

func _site_score(race: String, x: int, z: int) -> float:
	var elevation: float = float(elevation_map[z][x]) / 100.0
	var rain: float = float(rainfall_map[z][x])
	var vegetation: float = float(vegetation_map[z][x])
	var savagery: float = float(savagery_map[z][x])
	var evil: float = float(evil_map[z][x])
	var river_bonus: float = 1.0 if is_river(x, z) else 0.0
	if river_bonus == 0.0:
		for dz in range(-3, 4):
			for dx in range(-3, 4):
				if is_river(x + dx, z + dz) or is_lake(x + dx, z + dz):
					river_bonus = 0.75
					break
			if river_bonus > 0.0:
				break
	var biome: String = get_biome(x, z)
	var score: float = 0.0
	match race:
		"dwarf":
			score = elevation * 5.0 + float(volcanism_map[z][x]) * 0.7 + (1.0 - rain) * 0.4
			if biome in ["mountain", "mountain_forest", "alpine_meadow"]:
				score += 2.4
		"elf":
			score = vegetation * 5.2 + rain * 1.7 + river_bonus * 1.1 - evil * 1.5
			if biome in ["temperate_forest", "dense_temperate_forest", "rainforest", "tropical_forest"]:
				score += 2.5
		"goblin":
			score = savagery * 3.0 + evil * 3.2 + elevation * 1.4 + (1.0 - river_bonus) * 0.5
		_:
			score = river_bonus * 3.2 + rain * 1.5 + (1.0 - absf(elevation - 0.48)) * 2.4 + vegetation * 0.8 - savagery * 0.7
			if biome in ["grassland", "savanna", "temperate_forest"]:
				score += 1.5
	if biome in ["glacier", "ocean_deep", "ocean_shallow", "lake"]:
		score -= 20.0
	return score

func _coord_hash(x: int, z: int, salt: int = 0) -> int:
	var value: int = int(rng.seed) ^ (x * 374761393) ^ (z * 668265263) ^ (salt * 1274126177)
	value = int((value ^ (value >> 13)) * 1274126177)
	return absi(value)

func add_history_event(year: int, category: String, text: String) -> void:
	history_events.append({"year": year, "category": category, "text": text})

func get_history_strings() -> Array:
	var result = []
	result.append("THE WORLD OF %s" % world_name)
	result.append("Alignment: %s" % world_curse)
	result.append("========================================")
	result.append("")
	var last = -1
	for e in history_events:
		if e.year != last: result.append(""); last = e.year
		result.append("[%s] %s" % [e.category, e.text])
	return result

func get_world_info() -> Dictionary:
	var info = {"name": world_name, "width": world_width, "depth": world_depth, "biomes": {},
		"civilizations": civs, "sites": sites, "events": history_events.size(), "year": 63, "curse": world_curse}
	for z in range(world_depth):
		for x in range(world_width):
			if biome_map.size() > z and biome_map[z].size() > x:
				var b = biome_map[z][x]
				info.biomes[b] = info.biomes.get(b, 0) + 1
	return info

func _place_terrain_in_local(world) -> void:
	for z in range(world.depth):
		for x in range(world.width):
			var coords = _get_world_coords(x, z, world.width, world.depth)
			var wx = coords.x
			var wz = coords.y
			var h := clampi(int(world.elevation[z][x]), 0, 12)
			var pos = Vector3i(x, h, z)
			var biome: String = get_biome(wx, wz)
			var is_river: bool = _is_local_river(x, z, world.width, world.depth)
			var is_lake_tile: bool = _is_local_lake(x, z, world.width, world.depth)
			var tile_type = DFWorld.TileType.GRASS
			var mat = DFWorld.MatType.SOIL

			if h <= 1:
				tile_type = DFWorld.TileType.WATER_DEEP; mat = DFWorld.MatType.WATER
				for bh in range(h - 1, -2, -1):
					var bp = Vector3i(x, bh, z)
					if not world.tiles.has(bp): world.set_tile(bp, DFWorld.TileType.WATER_DEEP); world.set_material(bp, DFWorld.MatType.WATER)
			elif h == 2:
				tile_type = DFWorld.TileType.WATER_SHALLOW; mat = DFWorld.MatType.WATER
			else:
				match biome:
					"desert": tile_type = DFWorld.TileType.SAND; mat = DFWorld.MatType.SAND
					"beach": tile_type = DFWorld.TileType.SAND; mat = DFWorld.MatType.SAND
					"swamp": tile_type = DFWorld.TileType.MURKY_POOL if rng.randf() < 0.3 else DFWorld.TileType.GRASS; mat = DFWorld.MatType.SOIL
					"badlands": tile_type = DFWorld.TileType.DIRT; mat = DFWorld.MatType.CLAY
					"tundra": tile_type = DFWorld.TileType.SNOW; mat = DFWorld.MatType.SOIL
					"glacier": tile_type = DFWorld.TileType.ICE; mat = DFWorld.MatType.WATER
					"alpine_meadow": tile_type = DFWorld.TileType.GRASS; mat = DFWorld.MatType.SOIL
					"taiga": tile_type = DFWorld.TileType.GRASS; mat = DFWorld.MatType.SOIL
					_: tile_type = DFWorld.TileType.GRASS; mat = DFWorld.MatType.SOIL

			if (is_river or is_lake_tile) and h > 2:
				tile_type = DFWorld.TileType.WATER_DEEP; mat = DFWorld.MatType.WATER
				for bh_516 in range(h - 1, 0, -1):
					var bp_517 = Vector3i(x, bh_516, z)
					if not world.tiles.has(bp_517): world.set_tile(bp_517, DFWorld.TileType.WATER_SHALLOW); world.set_material(bp_517, DFWorld.MatType.WATER)
			# Detect if this tile should be a natural ramp (sloped borders of 1 Z-level)
			var should_be_ramp = false
			if h > 1 and not is_river and not is_lake_tile:
				var dirs = [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]
				for d in dirs:
					var nx = x + d.x
					var nz = z + d.y
					if nx >= 0 and nx < world.width and nz >= 0 and nz < world.depth:
						var nh := int(world.elevation[nz][nx])
						if nh == h + 1:
							should_be_ramp = true
							break
			
			if should_be_ramp:
				tile_type = DFWorld.TileType.RAMP

			if not world.tiles.has(pos) or world.get_tile(pos) in [DFWorld.TileType.FLOOR, DFWorld.TileType.CAVE_FLOOR]:
				world.set_tile(pos, tile_type); world.set_material(pos, mat)

			var geo_layers: Array[String] = _get_geology_layers(wx, wz)
			var geo_idx = 0
			for y in range(h - 1, -maxi(h + 4, 8), -1):
				var upos = Vector3i(x, y, z)
				if not world.tiles.has(upos):
					var geo_mat = _geo_to_material(geo_layers[mini(geo_idx, geo_layers.size() - 1)])
					var is_aquifer = aquifer_map[wz][wx] if aquifer_map.size() > wz and aquifer_map[wz].size() > wx else false
					
					if magma_map.size() > wz and magma_map[wz].size() > wx and magma_map[wz][wx] and y < -2:
						world.set_tile(upos, DFWorld.TileType.MAGMA)
						world.set_material(upos, geo_mat)
					else:
						# Carve caves using 3D pseudo-noise
						var cave_noise = _octave_noise(float(x) + float(y) * 0.7, float(z) + float(y) * 1.3, 2, 0.5, 16.0) + 0.5
						var is_cave = cave_noise > (0.6 - config_hidden_mines_chance * 0.5)
						
						if is_cave:
							if is_aquifer and rng.randf() < 0.25:
								world.set_tile(upos, DFWorld.TileType.WATER_SHALLOW)
								world.set_material(upos, DFWorld.MatType.WATER)
								world.tile_data[upos] = {"aquifer": true, "layer": geo_layers[mini(geo_idx, geo_layers.size() - 1)]}
							else:
								world.set_tile(upos, DFWorld.TileType.CAVE_FLOOR)
								world.set_material(upos, geo_mat)
								world.tile_data[upos] = {"layer": geo_layers[mini(geo_idx, geo_layers.size() - 1)]}
						else:
							# Solid cave wall
							world.set_tile(upos, DFWorld.TileType.CAVE_WALL)
							world.set_material(upos, geo_mat)
							world.tile_data[upos] = {"layer": geo_layers[mini(geo_idx, geo_layers.size() - 1)]}
							if is_aquifer:
								world.tile_data[upos]["aquifer"] = true
					geo_idx += 1

			if h >= 7:
				for wh in range(h + 1, h + 4):
					var wp = Vector3i(x, wh, z)
					if not world.tiles.has(wp): world.set_tile(wp, DFWorld.TileType.WALL); world.set_material(wp, DFWorld.MatType.GRANITE)

func _geo_to_material(geo: String) -> int:
	match geo:
		"SOIL": return DFWorld.MatType.SOIL
		"SAND": return DFWorld.MatType.SAND
		"CLAY": return DFWorld.MatType.CLAY
		"PEAT": return DFWorld.MatType.SOIL
		"LIMESTONE": return DFWorld.MatType.LIMESTONE
		"SANDSTONE": return DFWorld.MatType.SANDSTONE
		"GRANITE": return DFWorld.MatType.GRANITE
		"DIORITE": return DFWorld.MatType.DIORITE
		"GABBRO": return DFWorld.MatType.GABBRO
		"MARBLE": return DFWorld.MatType.MARBLE
		"OBSIDIAN": return DFWorld.MatType.OBSIDIAN
		_: return DFWorld.MatType.STONE

func _place_trees_in_local(world) -> void:
	for z in range(world.depth):
		for x in range(world.width):
			var coords = _get_world_coords(x, z, world.width, world.depth)
			var wx = coords.x
			var wz = coords.y
			var veg = vegetation_map[wz][wx] if vegetation_map.size() > wz and vegetation_map[wz].size() > wx else 0
			var h = world.get_surface_height(x, z)
			if veg <= 0 or h < 2 or h > 8: continue
			if world.get_tile(Vector3i(x, h, z)) != DFWorld.TileType.GRASS: continue
			var chance = veg * 0.4 * config_tree_density
			if rng.randf() < chance and _check_tree_spacing(world, x, h, z, config_tree_spacing):
				world.set_tile(Vector3i(x, h, z), DFWorld.TileType.TREE)
				world.set_material(Vector3i(x, h, z), DFWorld.MatType.WOOD)

func _place_flora_in_local(world) -> void:
	for z in range(world.depth):
		for x in range(world.width):
			var coords = _get_world_coords(x, z, world.width, world.depth)
			var wx = coords.x
			var wz = coords.y
			var biome: String = get_biome(wx, wz)
			var h = world.get_surface_height(x, z)
			
			# 1. Flora superficial
			if h >= 2 and h <= 8:
				var pos = Vector3i(x, h, z)
				var t = world.get_tile(pos)
				if t == DFWorld.TileType.GRASS or t == DFWorld.TileType.SAND:
					if rng.randf() < config_cactus_chance and (biome == "desert" or biome == "beach"):
						world._spawn_item(pos, "Cactus", "wood", DFWorld.MatType.WOOD, "♣", Color("#88FF88"))
					elif rng.randf() < config_berry_bush_chance and biome in ["grassland", "alpine_meadow", "taiga", "swamp"]:
						world._spawn_item(pos, "Arbusto de Bayas", "food", 0, "*", Color("#FF5555"))
							
			# 2. Flora subterránea
			for y in range(h - 1, -8, -1):
				var pos_c = Vector3i(x, y, z)
				if world.get_tile(pos_c) == DFWorld.TileType.CAVE_FLOOR:
					if rng.randf() < 0.02: # 2% de probabilidad fija en cuevas abiertas
						world._spawn_item(pos_c, "Plump Helmet Silvestre", "food", 0, "%", Color("#FF88FF"))

func _check_tree_spacing(world, x: int, y: int, z: int, min_dist: int) -> bool:
	for dz in range(-min_dist, min_dist + 1):
		for dx in range(-min_dist, min_dist + 1):
			if dx == 0 and dz == 0: continue
			var tx = x + dx; var tz = z + dz
			if tx >= 0 and tx < world.width and tz >= 0 and tz < world.depth:
				if world.get_tile(Vector3i(tx, y, tz)) == DFWorld.TileType.TREE: return false
	return true

func _place_features_in_local(world) -> void:
	for z in range(world.depth):
		for x in range(world.width):
			var coords = _get_world_coords(x, z, world.width, world.depth)
			var wx = coords.x
			var wz = coords.y
			if magma_map.size() <= wz or magma_map[0].size() <= wx: continue
			if magma_map[wz][wx]:
				var h = world.get_surface_height(x, z)
				var pipe_pos = Vector3i(x, h, z)
				if not world.is_water(pipe_pos):
					world.set_tile(pipe_pos, DFWorld.TileType.STONE_FLOOR)
					world.set_material(pipe_pos, DFWorld.MatType.OBSIDIAN)
					world.tile_data[pipe_pos] = {"magma_pipe": true, "warm": true}

func _place_ore_in_local(world) -> void:
	for z in range(world.depth):
		for x in range(world.width):
			for y in range(-6, 6):
				var pos = Vector3i(x, y, z)
				var t = world.get_tile(pos)
				if t not in [DFWorld.TileType.STONE_FLOOR, DFWorld.TileType.CAVE_FLOOR, DFWorld.TileType.CAVE_WALL]: continue
				if world.get_material(pos) in [DFWorld.MatType.IRON, DFWorld.MatType.GOLD, DFWorld.MatType.COPPER, DFWorld.MatType.COAL, DFWorld.MatType.PLATINUM]: continue
				var td = world.get_tile_data(pos)
				if td.get("aquifer", false): continue
				var r = rng.randf() / config_ore_density
				if y < -3:
					if r < 0.001: world.set_material(pos, DFWorld.MatType.PLATINUM); world.tile_data[pos] = {"ore": "platinum", "yield": rng.randi_range(1, 4)}
					elif r < 0.003: world.set_material(pos, DFWorld.MatType.GOLD); world.tile_data[pos] = {"ore": "gold", "yield": rng.randi_range(1, 6)}
					elif r < 0.008: world.set_material(pos, DFWorld.MatType.SILVER); world.tile_data[pos] = {"ore": "silver", "yield": rng.randi_range(2, 8)}
					elif r < 0.015: world.set_material(pos, DFWorld.MatType.IRON); world.tile_data[pos] = {"ore": "iron", "yield": rng.randi_range(3, 12)}
					elif r < 0.025: world.set_material(pos, DFWorld.MatType.COPPER); world.tile_data[pos] = {"ore": "copper", "yield": rng.randi_range(4, 16)}
					elif r < 0.035: world.set_material(pos, DFWorld.MatType.COAL); world.tile_data[pos] = {"ore": "coal", "yield": rng.randi_range(5, 20)}
					elif r < 0.040: world.set_material(pos, DFWorld.MatType.TIN); world.tile_data[pos] = {"ore": "tin", "yield": rng.randi_range(3, 12)}
				else:
					if r < 0.002: world.set_material(pos, DFWorld.MatType.IRON); world.tile_data[pos] = {"ore": "iron", "yield": rng.randi_range(3, 12)}
					elif r < 0.005: world.set_material(pos, DFWorld.MatType.COPPER); world.tile_data[pos] = {"ore": "copper", "yield": rng.randi_range(4, 16)}
					elif r < 0.009: world.set_material(pos, DFWorld.MatType.COAL); world.tile_data[pos] = {"ore": "coal", "yield": rng.randi_range(5, 20)}
					elif r < 0.012: world.set_material(pos, DFWorld.MatType.TIN); world.tile_data[pos] = {"ore": "tin", "yield": rng.randi_range(3, 12)}

func _generate_creatures() -> void:
	creatures.clear()
	if embark_pos.x < 0:
		return
	var data := DFData.new(rng.seed)
	var all_creatures: Array = data.creatures
	if all_creatures.is_empty():
		return
	# Solo se preparan criaturas de las regiones cercanas al mapa cargado.
	# El mundo gigantesco no mantiene millones de animales activos.
	var attempts: int = clampi(18 * setting_beast_density, 12, 72)
	for attempt in range(attempts):
		var wx: int = clampi(embark_pos.x + rng.randi_range(-4, 4), 0, world_width - 1)
		var wz: int = clampi(embark_pos.y + rng.randi_range(-4, 4), 0, world_depth - 1)
		if is_ocean(wx, wz) or is_lake(wx, wz):
			continue
		var creature_variant: Variant = all_creatures[rng.randi() % all_creatures.size()]
		if not creature_variant is Dictionary:
			continue
		var creature: Dictionary = creature_variant
		creatures.append({
			"name": str(creature.get("name", "Criatura")),
			"glyph": str(creature.get("tile", creature.get("glyph", "c"))),
			"color": Color(str(creature.get("color", "#FFFFFF"))),
			"x": wx,
			"z": wz,
			"biome": get_biome(wx, wz)
		})

func _is_in_territory(civ: Dictionary, x: int, z: int) -> bool:
	var cx = civ.get("capital_x", 0)
	var cz = civ.get("capital_z", 0)
	var dist = sqrt(float((x - cx) * (x - cx) + (z - cz) * (z - cz)))
	return dist < 60.0

# ===========================================================================================
# GENERACIÓN DE MAZMORRAS, BÓVEDAS Y GUARIDAS
# ===========================================================================================
var dungeons: Array = []
var vaults: Array = []
var lairs: Array = []
var ruins: Array = []

func generate_deep_sites(world) -> void:
	_generate_dungeons(world)
	_generate_vaults(world)
	_generate_lairs(world)
	_generate_ruins(world)

func _generate_dungeons(world) -> void:
	var num_dungeons = rng.randi_range(3, 8)
	var dungeon_prefixes = ["Catacumbas de", "La Mazmorra de", "Las Criptas de", "Los Túneles de", "La Fortaleza de"]
	var dungeon_suffixes = ["la Perdición", "los Sin Nombre", "el Eterno", "la Oscuridad", "los Caídos"]
	
	for i in range(num_dungeons):
		var dx = rng.randi_range(10, world_width - 10)
		var dz = rng.randi_range(10, world_depth - 10)
		var d_name = "%s %s" % [dungeon_prefixes[rng.randi() % dungeon_prefixes.size()], dungeon_suffixes[rng.randi() % dungeon_suffixes.size()]]
		var dungeon = {
			"name": d_name,
			"world_x": dx,
			"world_z": dz,
			"depth_levels": rng.randi_range(3, 7),
			"difficulty": rng.randi_range(1, 5),
			"monster_type": ["Goblin", "Zombie", "Esqueleto", "Troll", "Cultistas"][rng.randi() % 5],
			"has_boss": rng.randf() < 0.6,
			"has_treasure": rng.randf() < 0.8,
			"discovered": false
		}
		dungeons.append(dungeon)
		add_history_event(0, "SITE_GEN", "La %s aguarda a quienes se atrevan a descender." % d_name)

func _generate_vaults(world) -> void:
	var num_vaults = rng.randi_range(1, 4)
	for i in range(num_vaults):
		var vx = rng.randi_range(20, world_width - 20)
		var vz = rng.randi_range(20, world_depth - 20)
		var alignment_type = ["Ángel", "Demonio", "Dragón", "Titán"][rng.randi() % 4]
		var vault = {
			"name": "La Bóveda del %s" % alignment_type,
			"world_x": vx,
			"world_z": vz,
			"guardian_type": alignment_type,
			"artifact_inside": true,
			"sealed": true,
			"discovered": false
		}
		vaults.append(vault)
		add_history_event(0, "SITE_GEN", "Una bóveda sellada guarda secretos del tiempo de los dioses al norte.")

func _generate_lairs(world) -> void:
	var num_lairs = rng.randi_range(2, 6)
	var lair_types = [
		{"name": "Nido del Dragón", "creature": "Dragon"},
		{"name": "Cueva del Troll", "creature": "Giant troll"},
		{"name": "Guarida del Wyvern", "creature": "Wyvern"},
		{"name": "Madriguera del Hydra", "creature": "Hydra"},
		{"name": "Guarida del Licántropo", "creature": "Werewolf"},
	]
	for i in range(num_lairs):
		var lx = rng.randi_range(15, world_width - 15)
		var lz = rng.randi_range(15, world_depth - 15)
		var t = lair_types[rng.randi() % lair_types.size()]
		var lair = {
			"name": t["name"],
			"creature": t["creature"],
			"world_x": lx,
			"world_z": lz,
			"is_active": true,
			"discovered": false
		}
		lairs.append(lair)

func _generate_ruins(world) -> void:
	var num_ruins = rng.randi_range(4, 12)
	var ruin_types = [
		"Ruinas de un Palacio Antiguo",
		"Los Restos de una Fortaleza Élfica",
		"Vestigios de un Templo Olvidado",
		"Las Ruinas de la Ciudad Hundida",
		"Columnas de una Civilización Perdida",
	]
	for i in range(num_ruins):
		var rx = rng.randi_range(5, world_width - 5)
		var rz = rng.randi_range(5, world_depth - 5)
		var ruin = {
			"name": ruin_types[rng.randi() % ruin_types.size()],
			"world_x": rx,
			"world_z": rz,
			"has_artifacts": rng.randf() < 0.3,
			"has_inscriptions": rng.randf() < 0.5,
			"discovered": false
		}
		ruins.append(ruin)

func get_sites_summary() -> String:
	var text = "=== Puntos de Interés del Mundo ===\n\n"
	text += "MAZMORRAS (%d):\n" % dungeons.size()
	for d in dungeons:
		text += "  - %s [Dificultad: %d/5]\n" % [d["name"], d["difficulty"]]
	text += "\nBÓVEDAS SELLADAS (%d):\n" % vaults.size()
	for v in vaults:
		text += "  - %s\n" % v["name"]
	text += "\nGUARIDAS DE BESTIAS (%d):\n" % lairs.size()
	for l in lairs:
		text += "  - %s (%s)\n" % [l["name"], l["creature"]]
	text += "\nRUINAS (%d):\n" % ruins.size()
	for r in ruins:
		text += "  - %s\n" % r["name"]
	return text
