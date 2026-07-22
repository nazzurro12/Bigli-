extends RefCounted
class_name DFWorldHydrology
## Hidrología mundial determinista y escalable.
## Usa priority-flood para rellenar depresiones, crea una red de drenaje acíclica
## y calcula acumulación de caudal sin ejecutar pathfinding por cada río.

const NO_DIRECTION: int = 255
const DIRECTIONS: Array[Vector2i] = [
	Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
	Vector2i(-1, 0),                         Vector2i(1, 0),
	Vector2i(-1, 1),  Vector2i(0, 1),  Vector2i(1, 1)
]

static func generate(
		elevation_map: Array,
		rainfall_map: Array,
		width: int,
		height: int,
		sea_level: int,
		river_density: float = 1.0
	) -> Dictionary:
	var total: int = width * height
	var raw_height := PackedByteArray()
	raw_height.resize(total)
	for raw_z in range(height):
		for raw_x in range(width):
			raw_height[raw_z * width + raw_x] = clampi(int(elevation_map[raw_z][raw_x]), 0, 100)

	var filled_height := PackedByteArray()
	filled_height.resize(total)
	var visited := PackedByteArray()
	visited.resize(total)
	var parent := PackedInt32Array()
	parent.resize(total)
	parent.fill(-1)
	var visit_order := PackedInt32Array()
	visit_order.resize(total)

	# Las alturas están cuantizadas de 0 a 100, así que una cola por cubetas
	# es mucho más barata que un heap de un millón de nodos.
	var buckets: Array = []
	buckets.resize(101)
	for bucket_index in range(101):
		buckets[bucket_index] = []

	var seeded: int = 0
	for seed_z in range(height):
		for seed_x in range(width):
			var seed_idx: int = seed_z * width + seed_x
			var is_border: bool = seed_x == 0 or seed_z == 0 or seed_x == width - 1 or seed_z == height - 1
			var is_sea: bool = int(raw_height[seed_idx]) <= sea_level
			if not is_border and not is_sea:
				continue
			visited[seed_idx] = 1
			filled_height[seed_idx] = raw_height[seed_idx]
			buckets[int(filled_height[seed_idx])].append(seed_idx)
			seeded += 1

	# Salvaguarda para mundos sin océano por una configuración extrema.
	if seeded == 0:
		for border_x in range(width):
			_seed_cell(border_x, 0, width, raw_height, filled_height, visited, buckets)
			_seed_cell(border_x, height - 1, width, raw_height, filled_height, visited, buckets)
		for border_z in range(1, height - 1):
			_seed_cell(0, border_z, width, raw_height, filled_height, visited, buckets)
			_seed_cell(width - 1, border_z, width, raw_height, filled_height, visited, buckets)

	var processed: int = 0
	var current_level: int = 0
	while processed < total:
		while current_level <= 100 and buckets[current_level].is_empty():
			current_level += 1
		if current_level > 100:
			break
		var current_idx: int = int(buckets[current_level].pop_back())
		visit_order[processed] = current_idx
		processed += 1
		var cx: int = current_idx % width
		var cz: int = int(current_idx / width)
		for direction in DIRECTIONS:
			var nx: int = cx + direction.x
			var nz: int = cz + direction.y
			if nx < 0 or nx >= width or nz < 0 or nz >= height:
				continue
			var neighbor_idx: int = nz * width + nx
			if visited[neighbor_idx] != 0:
				continue
			visited[neighbor_idx] = 1
			var neighbor_level: int = maxi(int(raw_height[neighbor_idx]), current_level)
			filled_height[neighbor_idx] = neighbor_level
			parent[neighbor_idx] = current_idx
			buckets[neighbor_level].append(neighbor_idx)

	# Receptor de flujo. En pendientes usa el vecino más bajo; en mesetas y
	# depresiones rellenas usa el padre del priority-flood, evitando ciclos.
	var receiver := PackedInt32Array()
	receiver.resize(total)
	receiver.fill(-1)
	var direction_flat := PackedByteArray()
	direction_flat.resize(total)
	direction_flat.fill(NO_DIRECTION)
	for order_index in range(processed):
		var receiver_idx: int = int(visit_order[order_index])
		if int(raw_height[receiver_idx]) <= sea_level:
			continue
		var receiver_x: int = receiver_idx % width
		var receiver_z: int = int(receiver_idx / width)
		var best_idx: int = -1
		var best_height: int = int(filled_height[receiver_idx])
		for dir_index in range(DIRECTIONS.size()):
			var flow_direction: Vector2i = DIRECTIONS[dir_index]
			var flow_nx: int = receiver_x + flow_direction.x
			var flow_nz: int = receiver_z + flow_direction.y
			if flow_nx < 0 or flow_nx >= width or flow_nz < 0 or flow_nz >= height:
				continue
			var flow_neighbor_idx: int = flow_nz * width + flow_nx
			var neighbor_height: int = int(filled_height[flow_neighbor_idx])
			if neighbor_height < best_height:
				best_height = neighbor_height
				best_idx = flow_neighbor_idx
		if best_idx < 0:
			best_idx = int(parent[receiver_idx])
		if best_idx < 0:
			continue
		receiver[receiver_idx] = best_idx
		direction_flat[receiver_idx] = _direction_index(receiver_x, receiver_z, best_idx % width, int(best_idx / width))

	# Cada celda conserva el identificador del desagüe final de su cuenca. Como
	# el receptor siempre fue visitado antes, la asignación es lineal.
	var watershed_flat := PackedInt32Array()
	watershed_flat.resize(total)
	watershed_flat.fill(-1)
	for basin_order_index in range(processed):
		var basin_idx: int = int(visit_order[basin_order_index])
		var basin_receiver: int = int(receiver[basin_idx])
		if basin_receiver >= 0 and watershed_flat[basin_receiver] >= 0:
			watershed_flat[basin_idx] = watershed_flat[basin_receiver]
		else:
			watershed_flat[basin_idx] = basin_receiver if basin_receiver >= 0 else basin_idx

	var accumulation := PackedFloat32Array()
	accumulation.resize(total)
	for rain_z in range(height):
		for rain_x in range(width):
			var rain_idx: int = rain_z * width + rain_x
			var rainfall: float = clampf(float(rainfall_map[rain_z][rain_x]), 0.0, 1.5)
			accumulation[rain_idx] = 1.0 + rainfall * 5.0

	# El padre siempre aparece antes que el hijo en visit_order. Recorrerlo al
	# revés suma primero los afluentes y después el cauce principal.
	for reverse_index in range(processed - 1, -1, -1):
		var upstream_idx: int = int(visit_order[reverse_index])
		var target_idx: int = int(receiver[upstream_idx])
		if target_idx >= 0:
			accumulation[target_idx] += accumulation[upstream_idx]

	var safe_density: float = maxf(0.25, river_density)
	var linear_size: float = sqrt(float(total))
	var river_threshold: float = maxf(55.0, linear_size * 0.11 / safe_density)

	var flow_rows: Array = []
	var accumulation_rows: Array = []
	var river_rows: Array = []
	var river_order_rows: Array = []
	var lake_rows: Array = []
	var drainage_rows: Array = []
	var watershed_rows: Array = []
	for output_z in range(height):
		var flow_row := PackedByteArray()
		var accumulation_row := PackedFloat32Array()
		var river_row := PackedByteArray()
		var river_order_row := PackedByteArray()
		var lake_row := PackedByteArray()
		var drainage_row := PackedFloat32Array()
		var watershed_row := PackedInt32Array()
		flow_row.resize(width)
		accumulation_row.resize(width)
		river_row.resize(width)
		river_order_row.resize(width)
		lake_row.resize(width)
		drainage_row.resize(width)
		watershed_row.resize(width)
		for output_x in range(width):
			var output_idx: int = output_z * width + output_x
			var raw: int = int(raw_height[output_idx])
			var filled: int = int(filled_height[output_idx])
			var flow: float = float(accumulation[output_idx])
			var is_land: bool = raw > sea_level
			var is_lake: bool = is_land and filled > raw
			var is_river: bool = is_land and not is_lake and flow >= river_threshold and raw >= sea_level + 1
			var order: int = 0
			if is_river:
				order = 1
				if flow >= river_threshold * 4.0:
					order = 2
				if flow >= river_threshold * 16.0:
					order = 3
				if flow >= river_threshold * 64.0:
					order = 4
				if flow >= river_threshold * 256.0:
					order = 5
			flow_row[output_x] = direction_flat[output_idx]
			accumulation_row[output_x] = flow
			river_row[output_x] = 1 if is_river else 0
			river_order_row[output_x] = order
			lake_row[output_x] = 1 if is_lake else 0
			var slope: float = clampf(float(filled - sea_level) / 70.0, 0.0, 1.0)
			var channel_factor: float = clampf(flow / (river_threshold * 20.0), 0.0, 1.0)
			drainage_row[output_x] = clampf(0.25 + slope * 0.55 + channel_factor * 0.20, 0.0, 1.0)
			watershed_row[output_x] = watershed_flat[output_idx]
		flow_rows.append(flow_row)
		accumulation_rows.append(accumulation_row)
		river_rows.append(river_row)
		river_order_rows.append(river_order_row)
		lake_rows.append(lake_row)
		drainage_rows.append(drainage_row)
		watershed_rows.append(watershed_row)

	return {
		"flow_direction": flow_rows,
		"flow_accumulation": accumulation_rows,
		"river": river_rows,
		"river_order": river_order_rows,
		"lake": lake_rows,
		"drainage": drainage_rows,
		"watershed": watershed_rows,
		"water_volume": accumulation_rows,
		"river_threshold": river_threshold
	}

static func _seed_cell(
		x: int,
		z: int,
		width: int,
		raw_height: PackedByteArray,
		filled_height: PackedByteArray,
		visited: PackedByteArray,
		buckets: Array
	) -> void:
	var idx: int = z * width + x
	if visited[idx] != 0:
		return
	visited[idx] = 1
	filled_height[idx] = raw_height[idx]
	buckets[int(filled_height[idx])].append(idx)

static func _direction_index(from_x: int, from_z: int, to_x: int, to_z: int) -> int:
	var dx: int = clampi(to_x - from_x, -1, 1)
	var dz: int = clampi(to_z - from_z, -1, 1)
	for index in range(DIRECTIONS.size()):
		if DIRECTIONS[index] == Vector2i(dx, dz):
			return index
	return NO_DIRECTION
