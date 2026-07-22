extends RefCounted
class_name DFWorldSites
## Planos mundiales de asentamientos, caminos y materialización local.
## El mapa global guarda datos ligeros y deterministas. Las estructuras,
## habitantes y objetos se materializan al cargar la región local.

const DFWorld = preload("res://df_mode/df_world.gd")
const DFWorldHydrology = preload("res://df_mode/df_world_hydrology.gd")
const DFDwarf = preload("res://df_mode/df_dwarf.gd")
const DFBuilding = preload("res://df_mode/df_building.gd")
const DFWorkshop = preload("res://df_mode/df_workshop.gd")
const DFStockpile = preload("res://df_mode/df_stockpile.gd")
const DFItem = preload("res://df_mode/df_item.gd")

const ROAD: int = 1
const BRIDGE: int = 2
const BLUEPRINT_VERSION: int = 1
const MAX_MATERIALIZED_RESIDENTS: int = 40

const HUMAN_FIRST_NAMES: Array = [
	"Alonso", "Beatriz", "Catalina", "Diego", "Elena", "Fernando", "Gabriela", "Hernán",
	"Inés", "Julián", "Lucía", "Mateo", "Nora", "Octavio", "Paula", "Rodrigo",
	"Sara", "Tomás", "Valeria", "Yago", "Adriana", "Bruno", "Clara", "Damián"
]
const HUMAN_SURNAMES: Array = [
	"del Roble", "de la Vega", "Piedrabuena", "Campos", "Ribera", "Montes", "Herrera",
	"Molinero", "Carvajal", "Valle", "del Camino", "Torres", "Labrador", "Arriero"
]

static func build_civilized_world(world_gen: Object, civs: Array, sites: Array, seed_value: int) -> Dictionary:
	var width: int = int(world_gen.world_width)
	var height: int = int(world_gen.world_depth)
	var road_map: Array = []
	for z in range(height):
		var row := PackedByteArray()
		row.resize(width)
		road_map.append(row)

	var civ_by_id: Dictionary = {}
	for civ_variant in civs:
		if civ_variant is Dictionary:
			var indexed_civ: Dictionary = civ_variant
			civ_by_id[int(indexed_civ.get("id", -1))] = indexed_civ

	var site_lookup: Dictionary = {}
	for site_index in range(sites.size()):
		if not sites[site_index] is Dictionary:
			continue
		var indexed_site: Dictionary = sites[site_index]
		var sx: int = clampi(int(indexed_site.get("x", 0)), 0, width - 1)
		var sz: int = clampi(int(indexed_site.get("z", 0)), 0, height - 1)
		var civ_id: int = int(indexed_site.get("civ_id", -1))
		var site_civ: Dictionary = civ_by_id.get(civ_id, {})
		var race: String = str(site_civ.get("race", indexed_site.get("race", "human")))
		var population: int = maxi(0, int(indexed_site.get("population", 0)))
		var is_capital: bool = bool(indexed_site.get("is_capital", false))
		var is_sacked: bool = bool(indexed_site.get("is_sacked", false)) or population <= 0
		var site_type: String = _choose_site_type(race, population, is_capital, is_sacked)
		var radius: int = _site_radius(population, is_capital)
		var layout_seed: int = _coord_hash(seed_value, sx, sz, site_index)
		indexed_site["site_type"] = site_type
		indexed_site["race"] = race
		indexed_site["radius"] = radius
		indexed_site["layout_seed"] = layout_seed
		indexed_site["districts"] = _districts_for(site_type, population)
		indexed_site["structure_count"] = _structure_count(population, is_capital, is_sacked)
		indexed_site = _ensure_persistent_blueprint(indexed_site, site_index, layout_seed)
		sites[site_index] = indexed_site
		site_lookup[_key(sx, sz)] = indexed_site

	# Cada asentamiento secundario se conecta a la capital de su civilización.
	for site_variant in sites:
		if not site_variant is Dictionary:
			continue
		var secondary_site: Dictionary = site_variant
		if bool(secondary_site.get("is_capital", false)):
			continue
		var capital: Dictionary = _find_capital_for_civ(sites, int(secondary_site.get("civ_id", -1)))
		if capital.is_empty():
			continue
		var site_pos := Vector2i(int(secondary_site.get("x", 0)), int(secondary_site.get("z", 0)))
		var capital_pos := Vector2i(int(capital.get("x", 0)), int(capital.get("z", 0)))
		if world_gen.get_landmass_id(site_pos.x, site_pos.y) != world_gen.get_landmass_id(capital_pos.x, capital_pos.y):
			continue
		_draw_terrain_aware_road(world_gen, road_map, site_pos, capital_pos, seed_value)

	# Las capitales de un mismo continente forman una red mínima.
	var capitals_by_landmass: Dictionary = {}
	for capital_variant in sites:
		if not capital_variant is Dictionary:
			continue
		var capital_site: Dictionary = capital_variant
		if not bool(capital_site.get("is_capital", false)):
			continue
		var capital_x: int = int(capital_site.get("x", 0))
		var capital_z: int = int(capital_site.get("z", 0))
		var landmass_id: int = world_gen.get_landmass_id(capital_x, capital_z)
		if landmass_id < 0:
			continue
		var landmass_capitals: Array = capitals_by_landmass.get(landmass_id, [])
		landmass_capitals.append(capital_site)
		capitals_by_landmass[landmass_id] = landmass_capitals

	for landmass_variant in capitals_by_landmass.keys():
		var continental_capitals: Array = capitals_by_landmass[landmass_variant]
		if continental_capitals.size() <= 1:
			continue
		var connected: Array = [continental_capitals[0]]
		var remaining: Array = continental_capitals.slice(1)
		while not remaining.is_empty():
			var best_from: Dictionary = {}
			var best_to: Dictionary = {}
			var best_distance: float = INF
			var best_remaining_index: int = -1
			for connected_site_variant in connected:
				var connected_site: Dictionary = connected_site_variant
				var from_pos := Vector2i(int(connected_site.get("x", 0)), int(connected_site.get("z", 0)))
				for remaining_index in range(remaining.size()):
					var remaining_site: Dictionary = remaining[remaining_index]
					var to_pos := Vector2i(int(remaining_site.get("x", 0)), int(remaining_site.get("z", 0)))
					var distance: float = from_pos.distance_to(to_pos)
					if distance < best_distance:
						best_distance = distance
						best_from = connected_site
						best_to = remaining_site
						best_remaining_index = remaining_index
			if best_remaining_index < 0:
				break
			_draw_terrain_aware_road(
				world_gen,
				road_map,
				Vector2i(int(best_from.get("x", 0)), int(best_from.get("z", 0))),
				Vector2i(int(best_to.get("x", 0)), int(best_to.get("z", 0))),
				seed_value + connected.size() * 97 + int(landmass_variant) * 17
			)
			connected.append(best_to)
			remaining.remove_at(best_remaining_index)

	return {"road_map": road_map, "site_lookup": site_lookup, "sites": sites}

static func _ensure_persistent_blueprint(site: Dictionary, site_index: int, layout_seed: int) -> Dictionary:
	if int(site.get("blueprint_version", 0)) >= BLUEPRINT_VERSION:
		var existing_structures: Array = site.get("structures", [])
		if not existing_structures.is_empty():
			return site

	var rng := RandomNumberGenerator.new()
	rng.seed = layout_seed
	var site_id: int = int(site.get("id", site_index))
	var race: String = str(site.get("race", "human"))
	var population: int = maxi(0, int(site.get("population", 0)))
	var is_capital: bool = bool(site.get("is_capital", false))
	var is_ruin: bool = str(site.get("site_type", "")).begins_with("ruina") or bool(site.get("is_sacked", false))
	var condition: float = rng.randf_range(0.18, 0.62) if is_ruin else rng.randf_range(0.78, 1.0)
	var desired_houses: int = _structure_count(population, is_capital, is_ruin)
	if race == "human" and not is_ruin:
		desired_houses = clampi(desired_houses, 8, 20)
	else:
		desired_houses = clampi(desired_houses, 4, 20)

	var offsets: Array[Vector2i] = _house_offsets(desired_houses, rng)
	var structures: Array = []
	var families: Array = []
	var residents: Array = []
	var next_structure_index: int = 0
	var target_residents: int = clampi(maxi(desired_houses, int(population / 8)), desired_houses, MAX_MATERIALIZED_RESIDENTS)
	var remaining_residents: int = target_residents

	for house_index in range(desired_houses):
		var family_id: int = site_id * 100 + house_index
		var surname: String = str(HUMAN_SURNAMES[posmod(layout_seed + house_index * 7, HUMAN_SURNAMES.size())])
		var houses_left: int = maxi(1, desired_houses - house_index)
		var family_size: int = clampi(int(ceil(float(remaining_residents) / float(houses_left))), 1, 4)
		family_size = mini(family_size, remaining_residents)
		remaining_residents = maxi(0, remaining_residents - family_size)
		var structure_id: int = site_id * 1000 + next_structure_index
		next_structure_index += 1
		var house_width: int = 7 if house_index % 3 != 0 else 9
		var house_depth: int = 7 if house_index % 4 != 0 else 9
		var house_offset: Vector2i = offsets[house_index]
		structures.append({
			"structure_id": structure_id,
			"type": "house",
			"owner_family_id": family_id,
			"world_site_id": site_id,
			"condition": condition,
			"offset": [house_offset.x, house_offset.y],
			"size": [house_width, house_depth],
			"rooms": [{"type": "bedroom"}, {"type": "living_room"}],
			"furniture": ["bed", "chest", "table"],
			"stored_items": ["Pan", "Agua"]
		})
		var family_member_ids: Array = []
		for member_index in range(family_size):
			var resident_id: int = 2000000 + site_id * 1000 + residents.size()
			family_member_ids.append(resident_id)
			var first_name: String = str(HUMAN_FIRST_NAMES[posmod(layout_seed + house_index * 11 + member_index * 5, HUMAN_FIRST_NAMES.size())])
			var profession_name: String = _resident_profession_for_index(residents.size(), desired_houses)
			residents.append({
				"resident_id": resident_id,
				"name": "%s %s" % [first_name, surname],
				"gender": "Male" if (resident_id % 2) == 0 else "Female",
				"age": rng.randi_range(18, 66) if member_index < 2 else rng.randi_range(6, 17),
				"family_id": family_id,
				"home_structure_id": structure_id,
				"profession": profession_name,
				"religion_id": int(site.get("religion_id", -1))
			})
		families.append({
			"family_id": family_id,
			"surname": surname,
			"home_structure_id": structure_id,
			"member_ids": family_member_ids
		})

	var public_specs: Array = [
		{"type": "well", "offset": [0, -8], "size": [5, 5]},
		{"type": "granary", "offset": [-34, -30], "size": [11, 9]},
		{"type": "warehouse", "offset": [23, -30], "size": [11, 9]},
		{"type": "carpentry", "offset": [23, -16], "size": [9, 8]},
		{"type": "inn", "offset": [-34, -16], "size": [11, 9]},
		{"type": "field", "offset": [-34, 20], "size": [12, 9]},
		{"type": "field", "offset": [22, 20], "size": [12, 9]},
		{"type": "corral", "offset": [-7, 28], "size": [15, 11]}
	]
	for public_spec_variant in public_specs:
		var public_spec: Dictionary = public_spec_variant
		var public_type: String = str(public_spec.get("type", "public"))
		var public_structure_id: int = site_id * 1000 + next_structure_index
		next_structure_index += 1
		var stored_items: Array = []
		if public_type == "granary":
			stored_items = ["Pan", "Pan", "Grano", "Agua", "Cerveza"]
		elif public_type == "warehouse":
			stored_items = ["Madera", "Piedra", "Herramientas"]
		structures.append({
			"structure_id": public_structure_id,
			"type": public_type,
			"owner_family_id": -1,
			"world_site_id": site_id,
			"condition": condition,
			"offset": public_spec.get("offset", [0, 0]),
			"size": public_spec.get("size", [7, 7]),
			"rooms": [],
			"furniture": _public_furniture(public_type),
			"stored_items": stored_items
		})

	# Vincular oficios con edificios concretos.
	for resident_index in range(residents.size()):
		var resident_data: Dictionary = residents[resident_index]
		var work_type: String = _work_structure_type_for_profession(str(resident_data.get("profession", "citizen")))
		resident_data["work_structure_id"] = _find_blueprint_structure_id(structures, work_type)
		residents[resident_index] = resident_data

	site["blueprint_version"] = BLUEPRINT_VERSION
	site["condition"] = condition
	site["structures"] = structures
	site["families"] = families
	site["residents"] = residents if not is_ruin else []
	site["persistent_state"] = {
		"last_materialized_year": int(site.get("founded", 1)),
		"destroyed_structure_ids": [],
		"removed_item_ids": [],
		"resident_state": {}
	}
	return site

static func _house_offsets(count: int, rng: RandomNumberGenerator) -> Array[Vector2i]:
	var base_offsets: Array[Vector2i] = [
		Vector2i(-18, -12), Vector2i(10, -12), Vector2i(-18, 2), Vector2i(10, 2),
		Vector2i(-30, -4), Vector2i(22, -4), Vector2i(-8, -24), Vector2i(-8, 12),
		Vector2i(-30, 10), Vector2i(22, 10), Vector2i(8, -24), Vector2i(8, 12),
		Vector2i(-42, -10), Vector2i(34, -10), Vector2i(-20, 30), Vector2i(20, 30),
		Vector2i(-42, 8), Vector2i(34, 8), Vector2i(-20, -38), Vector2i(20, -38)
	]
	var result: Array[Vector2i] = []
	for index in range(mini(count, base_offsets.size())):
		var jitter := Vector2i(rng.randi_range(-1, 1), rng.randi_range(-1, 1))
		result.append(base_offsets[index] + jitter)
	return result

static func _resident_profession_for_index(index: int, house_count: int) -> String:
	var core_professions: Array[String] = [
		"carpenter", "farmer", "farmer", "innkeeper", "organizer", "trader",
		"cook", "brewer", "woodcutter", "mason", "doctor", "guard"
	]
	if index < core_professions.size():
		return core_professions[index]
	return "farmer" if index % 3 == 0 else "citizen" if index % 3 == 1 else "craftsman"

static func _public_furniture(structure_type: String) -> Array:
	match structure_type:
		"granary": return ["shelf", "shelf", "barrel", "barrel"]
		"warehouse": return ["shelf", "shelf", "crate"]
		"carpentry": return ["workbench", "tool_rack"]
		"inn": return ["table", "table", "chair", "chair", "bed"]
		"well": return ["well"]
		"corral": return ["trough"]
		_: return []

static func _work_structure_type_for_profession(profession_name: String) -> String:
	match profession_name:
		"carpenter", "craftsman", "woodcutter", "mason": return "carpentry"
		"farmer": return "field"
		"innkeeper", "trader", "cook", "brewer": return "inn"
		"organizer": return "granary"
		"doctor", "guard", "citizen": return "well"
		_: return "well"

static func _find_blueprint_structure_id(structures: Array, structure_type: String) -> int:
	for structure_variant in structures:
		if structure_variant is Dictionary:
			var structure: Dictionary = structure_variant
			if str(structure.get("type", "")) == structure_type:
				return int(structure.get("structure_id", -1))
	return -1

static func materialize_nearby_sites(world: Object, world_gen: Object, embark_pos: Vector2i) -> void:
	if world_gen == null or world == null:
		return
	world.set_meta("active_world_region", [embark_pos.x, embark_pos.y])
	var nearby: Array = []
	for site_variant in world_gen.sites:
		if not site_variant is Dictionary:
			continue
		var nearby_candidate: Dictionary = site_variant
		var nearby_site_pos := Vector2i(int(nearby_candidate.get("x", -9999)), int(nearby_candidate.get("z", -9999)))
		if maxi(absi(nearby_site_pos.x - embark_pos.x), absi(nearby_site_pos.y - embark_pos.y)) <= 2:
			nearby.append(nearby_candidate)
	if nearby.is_empty():
		_materialize_ancient_road(world, world_gen, embark_pos)
		return

	# Los sitios próximos se ordenan para que la aldea más cercana ocupe primero
	# el espacio local. Hasta dos asentamientos pueden mantenerse físicamente.
	nearby.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var apos := Vector2i(int(a.get("x", 0)), int(a.get("z", 0)))
		var bpos := Vector2i(int(b.get("x", 0)), int(b.get("z", 0)))
		return apos.distance_squared_to(embark_pos) < bpos.distance_squared_to(embark_pos)
	)

	var occupied_centers: Array[Vector2i] = []
	for site_index in range(mini(nearby.size(), 2)):
		var site_to_materialize: Dictionary = nearby[site_index]
		var site_world_pos := Vector2i(int(site_to_materialize.get("x", 0)), int(site_to_materialize.get("z", 0)))
		var delta := site_world_pos - embark_pos
		var direction := Vector2i(signi(delta.x), signi(delta.y))
		if direction == Vector2i.ZERO:
			var direction_options: Array[Vector2i] = [Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)]
			direction = direction_options[posmod(int(site_to_materialize.get("layout_seed", site_index)), direction_options.size())]
		var center_of_map := Vector2i(int(world.width / 2), int(world.depth / 2))
		var separation: int = 74 if site_index == 0 else 92
		var preferred := Vector2i(
			clampi(center_of_map.x + direction.x * separation, 48, world.width - 49),
			clampi(center_of_map.y + direction.y * separation, 48, world.depth - 49)
		)
		var local_center: Vector2i = _find_buildable_center(world, preferred, 44)
		if local_center.x < 0:
			continue
		var overlaps_existing: bool = false
		for occupied_center in occupied_centers:
			if local_center.distance_to(occupied_center) < 92.0:
				overlaps_existing = true
				break
		if overlaps_existing:
			continue
		occupied_centers.append(local_center)
		_materialize_site(world, world_gen, site_to_materialize, local_center, embark_pos)

static func _materialize_ancient_road(world: Object, world_gen: Object, embark_pos: Vector2i) -> void:
	if world_gen.road_map.is_empty():
		return
	var has_road: bool = false
	for dz in range(-2, 3):
		for dx in range(-2, 3):
			var wx: int = clampi(embark_pos.x + dx, 0, world_gen.world_width - 1)
			var wz: int = clampi(embark_pos.y + dz, 0, world_gen.world_depth - 1)
			if int(world_gen.road_map[wz][wx]) > 0:
				has_road = true
				break
		if has_road:
			break
	if not has_road:
		return
	var z: int = int(world.depth / 2)
	for x in range(world.width):
		_set_surface_path(world, x, z, -1, "camino_antiguo")

static func _materialize_site(world: Object, world_gen: Object, site: Dictionary, center: Vector2i, embark_pos: Vector2i) -> void:
	var site_id: int = int(site.get("id", -1))
	var is_ruin: bool = str(site.get("site_type", "")).begins_with("ruina") or bool(site.get("is_sacked", false))
	var is_capital: bool = bool(site.get("is_capital", false))
	var rng := RandomNumberGenerator.new()
	rng.seed = int(site.get("layout_seed", 1))

	_connect_world_road_to_plaza(world, world_gen, site, center, embark_pos)
	for plaza_z in range(center.y - 4, center.y + 5):
		for plaza_x in range(center.x - 4, center.x + 5):
			_set_surface_floor(world, plaza_x, plaza_z, site_id, -1, "plaza")

	var structures_variant: Variant = site.get("structures", [])
	var structures: Array = structures_variant if structures_variant is Array else []
	var structure_positions: Dictionary = {}
	var home_positions: Dictionary = {}
	var bed_positions: Dictionary = {}
	for structure_variant in structures:
		if not structure_variant is Dictionary:
			continue
		var structure: Dictionary = structure_variant
		var offset_variant: Variant = structure.get("offset", [0, 0])
		var offset_data: Array = offset_variant if offset_variant is Array else [0, 0]
		var origin := center + Vector2i(int(offset_data[0]), int(offset_data[1]))
		var structure_id: int = int(structure.get("structure_id", -1))
		var structure_type: String = str(structure.get("type", "house"))
		var result: Dictionary = {}
		match structure_type:
			"house":
				result = _build_house_from_blueprint(world, site_id, structure, origin, is_ruin, rng)
			"field":
				result = _build_field_from_blueprint(world, site_id, structure, origin, is_ruin, rng)
			"corral":
				result = _build_corral(world, site_id, structure, origin, is_ruin, rng)
			"well":
				result = _build_well(world, site_id, structure, origin, is_ruin)
			"granary", "warehouse", "carpentry", "inn":
				result = _build_public_structure(world, site_id, structure, origin, is_ruin, rng)
			_:
				result = _build_public_structure(world, site_id, structure, origin, is_ruin, rng)
		if result.has("center"):
			structure_positions[structure_id] = result["center"]
		if result.has("home"):
			home_positions[structure_id] = result["home"]
		if result.has("bed"):
			bed_positions[structure_id] = result["bed"]

	if is_capital:
		_build_perimeter_wall(world, center, 44, is_ruin, rng, site_id)

	if not is_ruin and str(site.get("race", "human")) == "human":
		_spawn_site_residents(world, site, center, structure_positions, home_positions, bed_positions)

	if not world.has_meta("generated_world_sites"):
		world.set_meta("generated_world_sites", [])
	var generated_sites: Array = world.get_meta("generated_world_sites", [])
	generated_sites.append({
		"site_id": site_id,
		"name": str(site.get("name", "Asentamiento")),
		"site_type": str(site.get("site_type", "aldea")),
		"center": [center.x, center.y],
		"structures": structures.duplicate(true),
		"families": site.get("families", []).duplicate(true),
		"residents": site.get("residents", []).duplicate(true),
		"population": int(site.get("population", 0)),
		"condition": float(site.get("condition", 1.0))
	})
	world.set_meta("generated_world_sites", generated_sites)

static func _connect_world_road_to_plaza(world: Object, world_gen: Object, site: Dictionary, center: Vector2i, embark_pos: Vector2i) -> void:
	var direction: Vector2i = _road_entry_direction(world_gen, site, embark_pos)
	var edge: Vector2i
	if absi(direction.x) >= absi(direction.y) and direction.x != 0:
		edge = Vector2i(1 if direction.x < 0 else world.width - 2, center.y)
	else:
		edge = Vector2i(center.x, 1 if direction.y < 0 else world.depth - 2)
	var site_id: int = int(site.get("id", -1))
	var current := edge
	while current.x != center.x:
		_set_surface_path(world, current.x, current.y, site_id, "carretera_principal")
		current.x += signi(center.x - current.x)
	while current.y != center.y:
		_set_surface_path(world, current.x, current.y, site_id, "carretera_principal")
		current.y += signi(center.y - current.y)
	_set_surface_path(world, center.x, center.y, site_id, "carretera_principal")
	# Calles secundarias que unen los distritos.
	for x in range(center.x - 42, center.x + 43):
		_set_surface_path(world, x, center.y + 16, site_id, "calle_secundaria")
	for z in range(center.y - 38, center.y + 40):
		_set_surface_path(world, center.x - 8, z, site_id, "calle_secundaria")

static func _road_entry_direction(world_gen: Object, site: Dictionary, embark_pos: Vector2i) -> Vector2i:
	var sx: int = int(site.get("x", embark_pos.x))
	var sz: int = int(site.get("z", embark_pos.y))
	var directions: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for direction in directions:
		var nx: int = sx + direction.x
		var nz: int = sz + direction.y
		if nx < 0 or nz < 0 or nx >= world_gen.world_width or nz >= world_gen.world_depth:
			continue
		if not world_gen.road_map.is_empty() and int(world_gen.road_map[nz][nx]) > 0:
			return direction
	var toward_embark := embark_pos - Vector2i(sx, sz)
	if toward_embark == Vector2i.ZERO:
		return Vector2i(0, 1)
	return Vector2i(signi(toward_embark.x), signi(toward_embark.y))

static func _build_rectangular_shell(
	world: Object,
	site_id: int,
	structure: Dictionary,
	origin: Vector2i,
	ruined: bool,
	rng: RandomNumberGenerator,
	building_kind: String
) -> Dictionary:
	var size_variant: Variant = structure.get("size", [7, 7])
	var size_data: Array = size_variant if size_variant is Array else [7, 7]
	var width: int = maxi(5, int(size_data[0]))
	var depth: int = maxi(5, int(size_data[1]))
	var structure_id: int = int(structure.get("structure_id", -1))
	var owner_family_id: int = int(structure.get("owner_family_id", -1))
	var center_x: int = origin.x + int(width / 2)
	var door_z: int = origin.y + depth - 1
	var condition: float = clampf(float(structure.get("condition", 1.0)), 0.0, 1.0)
	for z in range(origin.y, origin.y + depth):
		for x in range(origin.x, origin.x + width):
			if x < 1 or z < 1 or x >= world.width - 1 or z >= world.depth - 1:
				continue
			var is_edge: bool = x == origin.x or z == origin.y or x == origin.x + width - 1 or z == origin.y + depth - 1
			var is_door: bool = x == center_x and z == door_z
			var pos := _surface_pos(world, x, z)
			if is_edge and not is_door:
				if ruined and rng.randf() > condition:
					world.set_tile(pos, DFWorld.TileType.CONSTRUCTED_FLOOR)
				else:
					world.set_tile(pos, DFWorld.TileType.CONSTRUCTED_WALL)
			else:
				world.set_tile(pos, DFWorld.TileType.CONSTRUCTED_FLOOR)
			world.set_material(pos, DFWorld.MatType.CONSTRUCTION)
			world.tile_data[pos] = {
				"generated_structure": true,
				"world_site_id": site_id,
				"structure_id": structure_id,
				"owner_family_id": owner_family_id,
				"building_kind": building_kind,
				"condition": condition,
				"ruined": ruined
			}
	var door_pos := _surface_pos(world, center_x, door_z)
	var center_pos := _surface_pos(world, origin.x + int(width / 2), origin.y + int(depth / 2))
	_set_surface_path(world, center_x, door_z, site_id, "entrada_%s" % building_kind)
	_set_surface_path(world, center_x, door_z + 1, site_id, "sendero_%s" % building_kind)
	return {"center": center_pos, "door": door_pos, "width": width, "depth": depth}

static func _build_house_from_blueprint(world: Object, site_id: int, structure: Dictionary, origin: Vector2i, ruined: bool, rng: RandomNumberGenerator) -> Dictionary:
	var shell: Dictionary = _build_rectangular_shell(world, site_id, structure, origin, ruined, rng, "house")
	var width: int = int(shell.get("width", 7))
	var depth: int = int(shell.get("depth", 7))
	var owner_family_id: int = int(structure.get("owner_family_id", -1))
	var door_variant: Variant = shell.get("door", _surface_pos(world, origin.x + int(width / 2), origin.y + depth - 1))
	var door_pos: Vector3i = door_variant if door_variant is Vector3i else _surface_pos(world, origin.x + int(width / 2), origin.y + depth - 1)
	var bed_pos := _surface_pos(world, origin.x + 2, origin.y + 2)
	var home_variant: Variant = shell.get("center", _surface_pos(world, origin.x + int(width / 2), origin.y + int(depth / 2)))
	var home_pos: Vector3i = home_variant if home_variant is Vector3i else _surface_pos(world, origin.x + int(width / 2), origin.y + int(depth / 2))
	if not ruined:
		var bedroom := DFBuilding.new(DFBuilding.BuildingType.BEDROOM, bed_pos)
		bedroom.name = "Dormitorio familiar"
		world.buildings.append(bedroom)
		var bed_item: Variant = world._spawn_item(bed_pos, "Cama de Madera", "furniture", DFWorld.MatType.WOOD, "b", Color("#8B6914"))
		if bed_item is DFItem:
			bed_item.is_bed = true
			bed_item.set_meta("owner_family_id", owner_family_id)
		var chest_pos := _surface_pos(world, origin.x + width - 3, origin.y + 2)
		var chest := DFBuilding.new(DFBuilding.BuildingType.FOOD_STORE, chest_pos)
		chest.name = "Baúl familiar"
		world.buildings.append(chest)
		world._spawn_item(_surface_pos(world, origin.x + 2, origin.y + depth - 3), "Mesa de Madera", "furniture", DFWorld.MatType.WOOD, "T", Color("#9A7042"))
		world._spawn_item(door_pos, "Puerta de Madera", "door", DFWorld.MatType.WOOD, "+", Color("#8B5A2B"))
	return {"center": home_pos, "home": home_pos, "bed": bed_pos, "door": door_pos}

static func _build_public_structure(world: Object, site_id: int, structure: Dictionary, origin: Vector2i, ruined: bool, rng: RandomNumberGenerator) -> Dictionary:
	var structure_type: String = str(structure.get("type", "public"))
	var shell_result: Dictionary = _build_rectangular_shell(world, site_id, structure, origin, ruined, rng, structure_type)
	var structure_id: int = int(structure.get("structure_id", -1))
	var center_variant: Variant = shell_result.get("center", _surface_pos(world, origin.x, origin.y))
	var center: Vector3i = center_variant if center_variant is Vector3i else _surface_pos(world, origin.x, origin.y)
	if world.tile_data.has(center):
		var data: Dictionary = world.tile_data[center]
		data["building_kind"] = structure_type
		world.tile_data[center] = data
	if ruined:
		return {"center": center}

	match structure_type:
		"carpentry":
			var workshop := DFWorkshop.new(DFWorkshop.WorkshopType.CARPENTRY, center)
			workshop.name = "Carpintería de %s" % site_id
			world.workshops.append(workshop)
			var carpentry_building := DFBuilding.new(DFBuilding.BuildingType.CARPENTRY, center)
			carpentry_building.name = "Carpintería"
			world.buildings.append(carpentry_building)
		"inn":
			var inn_building := DFBuilding.new(DFBuilding.BuildingType.DINING_HALL, center)
			inn_building.name = "Posada"
			world.buildings.append(inn_building)
			world._spawn_item(center, "Mesa de la Posada", "furniture", DFWorld.MatType.WOOD, "T", Color("#B08050"))
		"granary", "warehouse":
			_register_foreign_stockpile(world, site_id, structure, origin)
			var store_building := DFBuilding.new(DFBuilding.BuildingType.STOCKPILE, center)
			store_building.name = "Granero" if structure_type == "granary" else "Almacén del Pueblo"
			world.buildings.append(store_building)
			_spawn_structure_supplies(world, site_id, structure, center)
	return {"center": center, "home": center}

static func _register_foreign_stockpile(world: Object, site_id: int, structure: Dictionary, origin: Vector2i) -> void:
	var size_data: Array = structure.get("size", [9, 7])
	var width: int = int(size_data[0])
	var depth: int = int(size_data[1])
	var tiles: Array = []
	for z in range(origin.y + 1, origin.y + depth - 1):
		for x in range(origin.x + 1, origin.x + width - 1):
			var pos := _surface_pos(world, x, z)
			if world.is_floor(pos):
				tiles.append(pos)
	var stockpile := DFStockpile.new(tiles)
	stockpile.owner_site_id = site_id
	stockpile.is_foreign = true
	var structure_type: String = str(structure.get("type", "warehouse"))
	stockpile.stockpile_name = "Granero" if structure_type == "granary" else "Almacén del Pueblo"
	stockpile.accepts_categories = ["food", "drink", "seed"] if structure_type == "granary" else ["wood", "stone", "item", "tool", "furniture"]
	world.stockpiles.append(stockpile)
	for shelf_index in range(0, tiles.size(), 12):
		var shelf_pos: Vector3i = tiles[shelf_index]
		var shelf := DFBuilding.new(DFBuilding.BuildingType.FOOD_STORE, shelf_pos)
		shelf.name = "Estantería de %s" % stockpile.stockpile_name
		world.buildings.append(shelf)

static func _spawn_structure_supplies(world: Object, site_id: int, structure: Dictionary, center: Vector3i) -> void:
	var stored_items: Array = structure.get("stored_items", [])
	for item_index in range(stored_items.size()):
		var item_name: String = str(stored_items[item_index])
		var item_type: String = "item"
		var glyph: String = "*"
		var color: Color = Color("#D0C090")
		if item_name in ["Pan", "Grano"]:
			item_type = "food"
			glyph = "%"
			color = Color("#E8B65A")
		elif item_name in ["Agua", "Cerveza"]:
			item_type = "drink"
			glyph = "~"
			color = Color("#66AADD")
		elif item_name == "Madera":
			item_type = "wood"
			glyph = "="
			color = Color("#8B6914")
		elif item_name == "Piedra":
			item_type = "stone"
			glyph = "*"
			color = Color("#888888")
		elif item_name == "Herramientas":
			item_type = "tool"
			glyph = "/"
			color = Color("#AACCFF")
		var spawn_pos := _surface_pos(world, center.x + (item_index % 3) - 1, center.z + int(item_index / 3))
		var spawned: Variant = world._spawn_item(spawn_pos, item_name, item_type, 0, glyph, color)
		if spawned is DFItem:
			spawned.is_in_stockpile = true
			spawned.set_meta("owner_site_id", site_id)

static func _build_field_from_blueprint(world: Object, site_id: int, structure: Dictionary, origin: Vector2i, ruined: bool, rng: RandomNumberGenerator) -> Dictionary:
	var size_data: Array = structure.get("size", [12, 9])
	var width: int = int(size_data[0])
	var depth: int = int(size_data[1])
	var structure_id: int = int(structure.get("structure_id", -1))
	var planted: int = 0
	for z in range(origin.y, origin.y + depth):
		for x in range(origin.x, origin.x + width):
			if x < 1 or z < 1 or x >= world.width - 1 or z >= world.depth - 1:
				continue
			if ruined and rng.randf() < 0.35:
				continue
			var pos := _surface_pos(world, x, z)
			if world.is_water(pos) or world.is_blocked(pos):
				continue
			world.set_tile(pos, DFWorld.TileType.FARM_SOIL)
			world.set_material(pos, DFWorld.MatType.SOIL)
			world.tile_data[pos] = {
				"generated_structure": true,
				"world_site_id": site_id,
				"structure_id": structure_id,
				"district": "agricola",
				"farm_quality": 1.2,
				"abandoned": ruined
			}
			if not ruined and ((x + z) % 3) == 0:
				var crop_type: String = "barley" if planted % 2 == 0 else "soft_wheat"
				world.plant_crop(pos, crop_type)
				planted += 1
	var center := _surface_pos(world, origin.x + int(width / 2), origin.y + int(depth / 2))
	return {"center": center}

static func _build_corral(world: Object, site_id: int, structure: Dictionary, origin: Vector2i, ruined: bool, rng: RandomNumberGenerator) -> Dictionary:
	var size_data: Array = structure.get("size", [15, 11])
	var width: int = int(size_data[0])
	var depth: int = int(size_data[1])
	var structure_id: int = int(structure.get("structure_id", -1))
	var door_x: int = origin.x + int(width / 2)
	for z in range(origin.y, origin.y + depth):
		for x in range(origin.x, origin.x + width):
			var edge: bool = x == origin.x or z == origin.y or x == origin.x + width - 1 or z == origin.y + depth - 1
			var gate: bool = z == origin.y and x in [door_x, door_x + 1]
			if not edge or gate:
				continue
			if ruined and rng.randf() < 0.25:
				continue
			var pos := _surface_pos(world, x, z)
			if world.is_water(pos):
				continue
			world.set_tile(pos, DFWorld.TileType.CONSTRUCTED_WALL)
			world.set_material(pos, DFWorld.MatType.WOOD)
			world.tile_data[pos] = {
				"generated_structure": true,
				"world_site_id": site_id,
				"structure_id": structure_id,
				"building_kind": "corral"
			}
	var center := _surface_pos(world, origin.x + int(width / 2), origin.y + int(depth / 2))
	world._spawn_item(center, "Abrevadero", "furniture", DFWorld.MatType.WOOD, "U", Color("#8B6914"))
	return {"center": center}

static func _build_well(world: Object, site_id: int, structure: Dictionary, origin: Vector2i, ruined: bool) -> Dictionary:
	var structure_id: int = int(structure.get("structure_id", -1))
	for dz in range(5):
		for dx in range(5):
			var x: int = origin.x + dx
			var z: int = origin.y + dz
			var pos := _surface_pos(world, x, z)
			var center_tile: bool = dx == 2 and dz == 2
			if center_tile and not ruined:
				world.set_tile(pos, DFWorld.TileType.WATER_SHALLOW)
				world.set_material(pos, DFWorld.MatType.WATER)
			else:
				world.set_tile(pos, DFWorld.TileType.CONSTRUCTED_FLOOR)
				world.set_material(pos, DFWorld.MatType.CONSTRUCTION)
			world.tile_data[pos] = {
				"generated_structure": true,
				"world_site_id": site_id,
				"structure_id": structure_id,
				"building_kind": "well",
				"potable_water": center_tile and not ruined
			}
	var center := _surface_pos(world, origin.x + 2, origin.y + 2)
	return {"center": center}

static func _spawn_site_residents(
	world: Object,
	site: Dictionary,
	plaza_center: Vector2i,
	structure_positions: Dictionary,
	home_positions: Dictionary,
	bed_positions: Dictionary
) -> void:
	var site_id: int = int(site.get("id", -1))
	var residents_variant: Variant = site.get("residents", [])
	var residents: Array = residents_variant if residents_variant is Array else []
	var families_by_id: Dictionary = {}
	for family_variant in site.get("families", []):
		if family_variant is Dictionary:
			var family_data: Dictionary = family_variant
			families_by_id[int(family_data.get("family_id", -1))] = family_data
	var created_by_id: Dictionary = {}
	var leisure_pos := _surface_pos(world, plaza_center.x, plaza_center.y)
	# Todos los habitantes del plano local se materializan como agentes persistentes.
	# El rendimiento se controla distribuyendo sus ticks, no eliminando personas.
	var active_resident_count: int = mini(residents.size(), MAX_MATERIALIZED_RESIDENTS)
	for resident_index in range(active_resident_count):
		var resident_variant: Variant = residents[resident_index]
		if not resident_variant is Dictionary:
			continue
		var resident_data: Dictionary = resident_variant
		var resident_id: int = int(resident_data.get("resident_id", -1))
		var home_structure: int = int(resident_data.get("home_structure_id", -1))
		var work_structure: int = int(resident_data.get("work_structure_id", -1))
		var spawn_variant: Variant = home_positions.get(home_structure, leisure_pos)
		var spawn_pos: Vector3i = spawn_variant if spawn_variant is Vector3i else leisure_pos
		var resident := DFDwarf.new(spawn_pos, str(resident_data.get("name", "Habitante")))
		resident.id = resident_id
		DFDwarf._id_counter = maxi(DFDwarf._id_counter, resident_id + 1)
		resident.caste = "human"
		resident.creature_type = "human"
		resident.glyph = "h" if str(resident_data.get("gender", "Male")) == "Male" else "m"
		resident.display_color = Color("#E7C49A")
		resident.gender = str(resident_data.get("gender", "Male"))
		resident.age = int(resident_data.get("age", 30))
		resident.profession = _profession_enum(str(resident_data.get("profession", "citizen")))
		resident.is_world_settlement_resident = true
		resident.settlement_site_id = site_id
		resident.settlement_family_id = int(resident_data.get("family_id", -1))
		resident.home_structure_id = home_structure
		resident.work_structure_id = work_structure
		resident.civilization_id = int(site.get("civ_id", -1))
		resident.religion_id = int(resident_data.get("religion_id", -1))
		var home_variant: Variant = home_positions.get(home_structure, spawn_pos)
		resident.settlement_home_position = home_variant if home_variant is Vector3i else spawn_pos
		var work_variant: Variant = structure_positions.get(work_structure, leisure_pos)
		resident.settlement_work_position = work_variant if work_variant is Vector3i else leisure_pos
		resident.settlement_leisure_position = leisure_pos
		resident.settlement_work_label = _work_label(str(resident_data.get("profession", "citizen")))
		resident.territory_home = resident.settlement_home_position
		var bed_variant: Variant = bed_positions.get(home_structure, resident.settlement_home_position)
		resident.preferred_bed = bed_variant if bed_variant is Vector3i else resident.settlement_home_position
		resident.claimed_bed = resident.preferred_bed
		resident.family["spouse"] = -1
		resident.family["children"] = []
		resident.worships = "La tradición de %s" % str(site.get("name", "su pueblo"))
		var bread := DFItem.new(spawn_pos, "Pan", "food", 0, "%", Color("#E8B65A"))
		bread.carried_by_id = resident.id
		resident.inventory.append(bread)
		var water := DFItem.new(spawn_pos, "Agua", "drink", 0, "~", Color("#66AADD"))
		water.carried_by_id = resident.id
		resident.inventory.append(water)
		world.entities.append(resident)
		created_by_id[resident_id] = resident

	for family_id_variant in families_by_id.keys():
		var family_info: Dictionary = families_by_id[family_id_variant]
		var member_ids: Array = family_info.get("member_ids", [])
		for member_id_variant in member_ids:
			var member_id: int = int(member_id_variant)
			if not created_by_id.has(member_id):
				continue
			var member: DFDwarf = created_by_id[member_id]
			for other_id_variant in member_ids:
				var other_id: int = int(other_id_variant)
				if other_id == member_id or not created_by_id.has(other_id):
					continue
				member.relationships[other_id] = 85
				if not member.friends.has(other_id):
					member.friends.append(other_id)
			if member_ids.size() >= 2 and member.age >= 18:
				var possible_spouse: int = int(member_ids[0]) if int(member_ids[0]) != member_id else int(member_ids[1])
				if created_by_id.has(possible_spouse):
					var spouse_variant: Variant = created_by_id[possible_spouse]
					if spouse_variant is DFDwarf and spouse_variant.age >= 18:
						member.family["spouse"] = possible_spouse

static func _profession_enum(profession_name: String) -> int:
	match profession_name:
		"carpenter": return DFDwarf.Profession.CARPENTER
		"farmer": return DFDwarf.Profession.FARMER
		"innkeeper", "trader": return DFDwarf.Profession.TRADER
		"organizer": return DFDwarf.Profession.ADMINISTRATOR
		"cook": return DFDwarf.Profession.COOK
		"brewer": return DFDwarf.Profession.BREWER
		"woodcutter": return DFDwarf.Profession.WOODCUTTER
		"mason": return DFDwarf.Profession.MASON
		"doctor": return DFDwarf.Profession.DOCTOR
		"guard": return DFDwarf.Profession.MILITARY
		"craftsman": return DFDwarf.Profession.CRAFTSMAN
		_: return DFDwarf.Profession.ADMINISTRATOR

static func _work_label(profession_name: String) -> String:
	match profession_name:
		"carpenter": return "Trabajando en la carpintería"
		"farmer": return "Cultivando los campos de la aldea"
		"innkeeper": return "Atendiendo la posada"
		"trader": return "Organizando el comercio local"
		"organizer": return "Ordenando el granero"
		"cook": return "Preparando comida en la posada"
		"brewer": return "Elaborando bebida"
		"woodcutter": return "Manteniendo las reservas de madera"
		"mason": return "Reparando edificios del pueblo"
		"doctor": return "Atendiendo a los habitantes"
		"guard": return "Patrullando la aldea"
		"craftsman": return "Fabricando bienes locales"
		_: return "Realizando tareas comunitarias"

static func _build_perimeter_wall(world: Object, center: Vector2i, radius: int, ruined: bool, rng: RandomNumberGenerator, site_id: int) -> void:
	for x in range(center.x - radius, center.x + radius + 1):
		_build_wall_tile(world, x, center.y - radius, ruined, rng, site_id)
		_build_wall_tile(world, x, center.y + radius, ruined, rng, site_id)
	for z in range(center.y - radius + 1, center.y + radius):
		_build_wall_tile(world, center.x - radius, z, ruined, rng, site_id)
		_build_wall_tile(world, center.x + radius, z, ruined, rng, site_id)
	for offset in range(-2, 3):
		_set_surface_path(world, center.x + offset, center.y - radius, site_id, "puerta_muralla")
		_set_surface_path(world, center.x + offset, center.y + radius, site_id, "puerta_muralla")
		_set_surface_path(world, center.x - radius, center.y + offset, site_id, "puerta_muralla")
		_set_surface_path(world, center.x + radius, center.y + offset, site_id, "puerta_muralla")

static func _build_wall_tile(world: Object, x: int, z: int, ruined: bool, rng: RandomNumberGenerator, site_id: int) -> void:
	if x < 1 or z < 1 or x >= world.width - 1 or z >= world.depth - 1:
		return
	if ruined and rng.randf() < 0.20:
		return
	var pos := _surface_pos(world, x, z)
	if world.is_water(pos):
		return
	world.set_tile(pos, DFWorld.TileType.CONSTRUCTED_WALL)
	world.set_material(pos, DFWorld.MatType.CONSTRUCTION)
	world.tile_data[pos] = {"generated_structure": true, "world_site_id": site_id, "fortification": true, "ruined": ruined}

static func _set_surface_path(world: Object, x: int, z: int, site_id: int = -1, road_kind: String = "path") -> void:
	if x < 0 or z < 0 or x >= world.width or z >= world.depth:
		return
	var pos := _surface_pos(world, x, z)
	if world.is_water(pos):
		world.set_tile(pos, DFWorld.TileType.BRIDGE)
	else:
		world.set_tile(pos, DFWorld.TileType.PATH)
	world.set_material(pos, DFWorld.MatType.CONSTRUCTION)
	world.tile_data[pos] = world.tile_data.get(pos, {})
	world.tile_data[pos]["generated_structure"] = true
	world.tile_data[pos]["world_site_id"] = site_id
	world.tile_data[pos]["road_kind"] = road_kind

static func _set_surface_floor(world: Object, x: int, z: int, site_id: int = -1, structure_id: int = -1, building_kind: String = "floor") -> void:
	if x < 0 or z < 0 or x >= world.width or z >= world.depth:
		return
	var pos := _surface_pos(world, x, z)
	world.set_tile(pos, DFWorld.TileType.CONSTRUCTED_FLOOR)
	world.set_material(pos, DFWorld.MatType.CONSTRUCTION)
	world.tile_data[pos] = {
		"generated_structure": true,
		"world_site_id": site_id,
		"structure_id": structure_id,
		"building_kind": building_kind
	}

static func _surface_pos(world: Object, x: int, z: int) -> Vector3i:
	var safe_x: int = clampi(x, 0, world.width - 1)
	var safe_z: int = clampi(z, 0, world.depth - 1)
	return Vector3i(safe_x, world.get_surface_height(safe_x, safe_z), safe_z)

static func _find_buildable_center(world: Object, preferred: Vector2i, radius: int) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_score: float = INF
	for search_radius in range(0, 50, 5):
		for dz in range(-search_radius, search_radius + 1, 5):
			for dx in range(-search_radius, search_radius + 1, 5):
				var candidate := preferred + Vector2i(dx, dz)
				if candidate.x < radius + 2 or candidate.y < radius + 2 or candidate.x >= world.width - radius - 2 or candidate.y >= world.depth - radius - 2:
					continue
				var min_height: int = 999
				var max_height: int = -999
				var water_count: int = 0
				for sample_z in range(candidate.y - radius, candidate.y + radius + 1, 6):
					for sample_x in range(candidate.x - radius, candidate.x + radius + 1, 6):
						var h: int = world.get_surface_height(sample_x, sample_z)
						min_height = mini(min_height, h)
						max_height = maxi(max_height, h)
						if world.is_water(Vector3i(sample_x, h, sample_z)):
							water_count += 1
				var score: float = float(max_height - min_height) * 20.0 + float(water_count) * 50.0 + candidate.distance_to(preferred)
				if score < best_score:
					best_score = score
					best = candidate
		if best.x >= 0 and best_score < 40.0:
			break
	return best

static func _draw_terrain_aware_road(world_gen: Object, road_map: Array, start: Vector2i, target: Vector2i, seed_value: int) -> void:
	var width: int = int(world_gen.world_width)
	var height: int = int(world_gen.world_depth)
	var current := Vector2i(clampi(start.x, 0, width - 1), clampi(start.y, 0, height - 1))
	var goal := Vector2i(clampi(target.x, 0, width - 1), clampi(target.y, 0, height - 1))
	if world_gen.get_landmass_id(current.x, current.y) < 0 or world_gen.get_landmass_id(current.x, current.y) != world_gen.get_landmass_id(goal.x, goal.y):
		return
	var visited: Dictionary = {}
	var max_steps: int = maxi(width, height) * 4
	for step in range(max_steps):
		var key: String = _key(current.x, current.y)
		visited[key] = true
		var over_water: bool = world_gen.is_lake(current.x, current.y) or world_gen.is_river(current.x, current.y)
		road_map[current.y][current.x] = BRIDGE if over_water else ROAD
		if current.distance_to(goal) <= 1.0:
			road_map[goal.y][goal.x] = ROAD
			break
		var best := current
		var best_score: float = INF
		for direction in DFWorldHydrology.DIRECTIONS:
			var candidate := current + direction
			if candidate.x < 0 or candidate.x >= width or candidate.y < 0 or candidate.y >= height:
				continue
			if world_gen.is_ocean(candidate.x, candidate.y):
				continue
			var candidate_key: String = _key(candidate.x, candidate.y)
			var distance_score: float = candidate.distance_to(goal)
			var elevation: float = float(world_gen.elevation_map[candidate.y][candidate.x])
			var terrain_cost: float = 0.0
			var biome: String = world_gen.get_biome(candidate.x, candidate.y)
			if world_gen.is_lake(candidate.x, candidate.y):
				terrain_cost += 25.0
			if world_gen.is_river(candidate.x, candidate.y):
				terrain_cost += 6.0
			if biome in ["mountain", "glacier"]:
				terrain_cost += 18.0
			elif biome in ["swamp", "rainforest"]:
				terrain_cost += 8.0
			terrain_cost += maxf(0.0, elevation - 72.0) * 0.4
			var revisit_cost: float = 100.0 if visited.has(candidate_key) else 0.0
			var jitter: float = float(_coord_hash(seed_value, candidate.x, candidate.y, step) % 100) / 500.0
			var score: float = distance_score + terrain_cost + revisit_cost + jitter
			if score < best_score:
				best_score = score
				best = candidate
		if best == current:
			break
		current = best

static func _find_capital_for_civ(sites: Array, civ_id: int) -> Dictionary:
	for site_variant in sites:
		if not site_variant is Dictionary:
			continue
		var site: Dictionary = site_variant
		if int(site.get("civ_id", -1)) == civ_id and bool(site.get("is_capital", false)):
			return site
	return {}

static func _choose_site_type(race: String, population: int, is_capital: bool, is_sacked: bool) -> String:
	if is_sacked:
		return "ruina_fortificada" if is_capital else "ruina"
	if race == "dwarf":
		return "fortaleza_enana" if is_capital or population >= 350 else "bastion_enano" if population >= 120 else "mina_enana"
	if race == "elf":
		return "ciudad_bosque" if is_capital or population >= 350 else "aldea_arborea"
	if race == "goblin":
		return "fortaleza_goblin" if is_capital or population >= 250 else "campamento_goblin"
	if is_capital or population >= 500:
		return "ciudad"
	if population >= 160:
		return "pueblo"
	return "aldea"

static func _site_radius(population: int, is_capital: bool) -> int:
	if is_capital:
		return 5
	if population >= 300:
		return 4
	if population >= 100:
		return 3
	return 2

static func _structure_count(population: int, is_capital: bool, is_sacked: bool) -> int:
	var count: int = clampi(4 + int(population / 25), 4, 20)
	if is_capital:
		count = maxi(count, 14)
	if is_sacked:
		count = maxi(5, int(float(count) * 0.75))
	return count

static func _districts_for(site_type: String, population: int) -> Array[String]:
	var result: Array[String] = ["residencial", "almacenamiento"]
	if population >= 60:
		result.append("agricola")
		result.append("artesanal")
	if population >= 150:
		result.append("comercial")
		result.append("religioso")
	if population >= 300 or site_type.contains("fortaleza"):
		result.append("militar")
		result.append("administrativo")
	return result

static func _key(x: int, z: int) -> String:
	return "%d:%d" % [x, z]

static func _coord_hash(seed_value: int, x: int, z: int, salt: int) -> int:
	var value: int = seed_value
	value = int((value ^ (x * 374761393)) * 668265263)
	value = int((value ^ (z * 1274126177)) * 2246822519)
	value = int(value ^ (salt * 3266489917))
	return absi(value)
