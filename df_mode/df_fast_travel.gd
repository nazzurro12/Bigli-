extends RefCounted
class_name DFFastTravel

var world_ref = null
var main_ref = null

var active: bool = false
var traveling: bool = false
var travel_progress: float = 0.0
var travel_distance: int = 0
var travel_speed: float = 0.0
var destination_x: int = 0
var destination_z: int = 0
var start_x: int = 0
var start_z: int = 0
var encounter_timer: int = 0
var current_message: String = ""
var step_size: int = 10

enum TravelPhase {
	SELECTING,
	TRAVELING,
	ENCOUNTER,
	COMPLETE
}
var phase: int = TravelPhase.SELECTING

func _init(world, main_node):
	world_ref = world
	main_ref = main_node

func start_fast_travel(cam_x: int, cam_z: int) -> void:
	active = true
	traveling = false
	phase = TravelPhase.SELECTING
	start_x = cam_x
	start_z = cam_z
	destination_x = cam_x
	destination_z = cam_z
	travel_distance = 0
	travel_progress = 0.0
	encounter_timer = 0
	current_message = ""

func cancel() -> void:
	active = false
	traveling = false
	phase = TravelPhase.SELECTING

func move_destination(dx: int, dz: int) -> void:
	if phase != TravelPhase.SELECTING:
		return
	if world_ref == null:
		return
	destination_x = clampi(destination_x + dx * step_size, 0, world_ref.width - 1)
	destination_z = clampi(destination_z + dz * step_size, 0, world_ref.depth - 1)
	travel_distance = int(sqrt(pow(destination_x - start_x, 2) + pow(destination_z - start_z, 2)))

func get_destination_tile_info() -> Dictionary:
	if world_ref == null:
		return {}
	var ww = main_ref.world_gen.world_width if main_ref.world_gen != null else 256
	var wd = main_ref.world_gen.world_depth if main_ref.world_gen != null else 256
	var gx = int(float(destination_x) / float(world_ref.width) * ww)
	var gz = int(float(destination_z) / float(world_ref.depth) * wd)
	var biome = "grassland"
	if main_ref.world_gen != null:
		if main_ref.world_gen.biome_map.size() > gz and gz >= 0:
			if main_ref.world_gen.biome_map[gz].size() > gx and gx >= 0:
				biome = main_ref.world_gen.biome_map[gz][gx]
	var height = world_ref.get_surface_height(destination_x, destination_z)
	return {"biome": biome, "height": height, "gx": gx, "gz": gz}

func get_current_biome() -> String:
	return get_destination_tile_info().get("biome", "grassland")

func start_travel() -> void:
	if travel_distance < 1:
		return
	phase = TravelPhase.TRAVELING
	travel_progress = 0.0
	travel_speed = 5.0 + 10.0 * (1.0 - float(travel_distance) / 500.0)
	travel_speed = clampf(travel_speed, 5.0, 15.0)
	start_x = main_ref.camera_pos.x
	start_z = main_ref.camera_pos.z

func tick_travel(delta: float) -> void:
	if phase != TravelPhase.TRAVELING:
		return
	if world_ref == null or main_ref == null:
		return
	travel_progress += delta * travel_speed / maxf(1.0, float(travel_distance))
	encounter_timer += 1
	var encounter_chance = 0.02 * travel_speed
	if encounter_timer < 15:
		encounter_chance = 0.0
	if world_ref.current_season == DFWorld.Season.AUTUMN:
		encounter_chance *= 1.3
	elif world_ref.current_season == DFWorld.Season.WINTER:
		encounter_chance *= 0.7
	if randf() < encounter_chance:
		_trigger_encounter()
	travel_progress = clampf(travel_progress, 0.0, 1.0)
	if travel_progress >= 1.0:
		var fx = start_x + int((destination_x - start_x) * travel_progress)
		var fz = start_z + int((destination_z - start_z) * travel_progress)
		fx = clampi(fx, 2, world_ref.width - 2)
		fz = clampi(fz, 2, world_ref.depth - 2)
		var fy = world_ref.get_surface_height(fx, fz)
		main_ref.camera_pos = Vector3i(fx, fy, fz)
		if main_ref.possessed_dwarf != null:
			main_ref.possessed_dwarf.tile_pos = main_ref.camera_pos
		phase = TravelPhase.COMPLETE
		current_message = "Has llegado a tu destino. [ENTER para cerrar]"
		return
	var current_x = start_x + int((destination_x - start_x) * travel_progress)
	var current_z = start_z + int((destination_z - start_z) * travel_progress)
	current_x = clampi(current_x, 2, world_ref.width - 2)
	current_z = clampi(current_z, 2, world_ref.depth - 2)
	var current_y = world_ref.get_surface_height(current_x, current_z)
	main_ref.camera_pos = Vector3i(current_x, current_y, current_z)
	if main_ref.possessed_dwarf != null:
		main_ref.possessed_dwarf.tile_pos = main_ref.camera_pos

func _trigger_encounter() -> void:
	var biome = "grassland"
	if main_ref.world_gen != null:
		var cx = main_ref.camera_pos.x
		var cz = main_ref.camera_pos.z
		var ww = main_ref.world_gen.world_width
		var wd = main_ref.world_gen.world_depth
		var gx = int(float(cx) / float(world_ref.width) * ww) if world_ref.width > 0 else 0
		var gz = int(float(cz) / float(world_ref.depth) * wd) if world_ref.depth > 0 else 0
		if gx >= 0 and gx < ww and gz >= 0 and gz < wd:
			if main_ref.world_gen.biome_map.size() > gz and gz >= 0:
				if main_ref.world_gen.biome_map[gz].size() > gx and gx >= 0:
					biome = main_ref.world_gen.biome_map[gz][gx]
	var table = _get_encounters_for_biome(biome)
	var encounter = table[randi() % table.size()]
	current_message = encounter["msg"]
	phase = TravelPhase.ENCOUNTER
	if encounter.get("goods", {}).size() > 0:
		var goods = encounter["goods"]
		_spawn_encounter_loot(goods)
	if encounter.get("hostile", false):
		var danger_name = encounter.get("danger", "criaturas")
		current_message += "\n[!Peligro! %s hostiles en el area.]" % danger_name.capitalize()
		main_ref.add_message("!Encuentro hostil durante el viaje! %s." % encounter["msg"])
	main_ref.add_message("[VIAJE] %s" % encounter["msg"])
	encounter_timer = 0

func _get_encounters_for_biome(biome: String) -> Array:
	var tables = {
		"grassland": [
			{"msg": "Encuentras un rebano de ciervos pastando.", "goods": {"food": 3}, "hostile": false},
			{"msg": "Un grupo de bandidos huye al verte. Dejan caer una bolsa.", "goods": {"coin": 10}, "hostile": false},
			{"msg": "Ves una caravana mercante en la distancia.", "goods": {}, "hostile": false},
			{"msg": "Una manada de lobos merodea cerca.", "goods": {}, "hostile": true, "danger": "lobos"},
			{"msg": "Encuentras un arroyo cristalino.", "goods": {"drink": 2}, "hostile": false},
		],
		"temperate_forest": [
			{"msg": "El bosque susurra secretos antiguos. Ves ruinas cubiertas de musgo.", "goods": {"stone": 5}, "hostile": false},
			{"msg": "Una manada de jabalies cruza el sendero.", "goods": {}, "hostile": false},
			{"msg": "Encuentras un claro con un altar de piedra. Hay ofrendas.", "goods": {"coin": 15}, "hostile": false},
			{"msg": "Un oso se incorpora sobre sus patas traseras. Retrocedes.", "goods": {}, "hostile": true, "danger": "oso"},
			{"msg": "Una druida solitaria te ofrece hierbas.", "goods": {"food": 2, "drink": 1}, "hostile": false},
		],
		"desert": [
			{"msg": "El calor es abrasador. Encuentras un oasis con palmeras.", "goods": {"drink": 5}, "hostile": false},
			{"msg": "Una tormenta de arena se acerca. Te refugias.", "goods": {}, "hostile": false},
			{"msg": "Ves las ruinas de una antigua civilizacion.", "goods": {"coin": 20, "stone": 3}, "hostile": false},
			{"msg": "Escarabajos gigantes emergen de la arena.", "goods": {}, "hostile": true, "danger": "escarabajos"},
			{"msg": "Una caravana nomada te ofrece agua.", "goods": {"food": 3, "drink": 3}, "hostile": false},
		],
		"swamp": [
			{"msg": "El pantano apesta a podredumbre. Ves hongos brillantes.", "goods": {"food": 2}, "hostile": false},
			{"msg": "Una niebla espesa te desorienta.", "goods": {}, "hostile": false},
			{"msg": "Encuentras una cabana de un eremita.", "goods": {"food": 3, "drink": 2}, "hostile": false},
			{"msg": "Cocodrilos acechan en las aguas turbias.", "goods": {}, "hostile": true, "danger": "cocodrilos"},
		],
		"taiga": [
			{"msg": "El frio penetra los huesos. Encuentras refugio en una cueva.", "goods": {"stone": 3}, "hostile": false},
			{"msg": "Un alce gigante cruza lentamente el camino.", "goods": {}, "hostile": false},
			{"msg": "Ves luces en la distancia. Es una aldea de tramperos.", "goods": {"food": 4}, "hostile": false},
			{"msg": "Lobos grises te siguen durante media hora.", "goods": {}, "hostile": true, "danger": "lobos grises"},
		],
		"savanna": [
			{"msg": "La sabana se extiende infinita. Ves jirafas al horizonte.", "goods": {}, "hostile": false},
			{"msg": "Un leon ruge a lo lejos. Cambias de direccion.", "goods": {}, "hostile": false},
			{"msg": "Encuentras un arbol baobab con agua.", "goods": {"drink": 3}, "hostile": false},
			{"msg": "Manadas de nus cruzan la llanura en estampida.", "goods": {}, "hostile": true, "danger": "estampida"},
		],
		
		"mountains": [
			{"msg": "Las montanas se alzan majestuosas. El aire es puro.", "goods": {"stone": 5}, "hostile": false},
			{"msg": "Encuentras una veta de mineral.", "goods": {"ore": 3}, "hostile": false},
			{"msg": "Un aguila gigante vuela en circulos sobre ti.", "goods": {}, "hostile": false},
			{"msg": "Un derrumbe bloquea el paso. Tienes que rodear.", "goods": {}, "hostile": true, "danger": "derrumbe"},
			{"msg": "Una cabra montes te guia a un paso seguro.", "goods": {"food": 1}, "hostile": false},
		],
		"tundra": [
			{"msg": "El viento helado corta la piel. Ves una aurora boreal.", "goods": {}, "hostile": false},
			{"msg": "Un mamut lanudo cruza la llanura nevada.", "goods": {}, "hostile": false},
			{"msg": "Encuentras un iglu abandonado con provisiones.", "goods": {"food": 4, "drink": 1}, "hostile": false},
			{"msg": "Osos polares acechan entre los icebergs.", "goods": {}, "hostile": true, "danger": "oso polar"},
		],
		"badlands": [
			{"msg": "El terreno es arido. Ves formaciones rocosas extranas.", "goods": {"stone": 3}, "hostile": false},
			{"msg": "El viento silba entre los canones. Hay pinturas rupestres.", "goods": {"coin": 5}, "hostile": false},
			{"msg": "Un grupo de saqueadores merodea.", "goods": {}, "hostile": true, "danger": "saqueadores"},
		],
	}
	# For biomes not explicitly defined, use grassland or fallback
	var result = tables.get(biome, [])
	if result.size() == 0:
		result = tables.get("grassland", [{"msg": "El camino es tranquilo.", "goods": {}, "hostile": false}])
	return result

func _spawn_encounter_loot(goods: Dictionary) -> void:
	if world_ref == null:
		return
	var spawn_pos = main_ref.camera_pos if main_ref != null else Vector3i(64, 3, 64)
	var item_types = {"food": ["%", Color(1.0, 0.53, 0.27), "Provisiones"], "drink": ["~", Color(1.0, 0.8, 0.0), "Agua Fresca"], "coin": ["$", Color(1.0, 0.84, 0.0), "Monedas"], "stone": ["*", Color(0.5, 0.5, 0.5), "Piedras"], "ore": ["*", Color(0.8, 0.4, 0.2), "Mineral"]}
	for item_type in goods.keys():
		var count = goods[item_type]
		var data = item_types.get(item_type, ["*", Color.WHITE, item_type])
		for i in range(count):
			world_ref._spawn_item(spawn_pos, data[2], item_type, 0, data[0], data[1])

func resume_travel() -> void:
	if phase == TravelPhase.ENCOUNTER:
		phase = TravelPhase.TRAVELING
		current_message = ""
	elif phase == TravelPhase.COMPLETE:
		active = false
		phase = TravelPhase.SELECTING
		current_message = ""

func get_progress_string() -> String:
	return "Viajando... %d%% completado" % int(travel_progress * 100)

func is_at_destination() -> bool:
	return travel_progress >= 1.0
