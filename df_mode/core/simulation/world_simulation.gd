extends RefCounted
class_name DFWorldSimulation

const WorldDatabase = preload("res://df_mode/core/database/world_database.gd")
const SettlementController = preload("res://df_mode/core/simulation/settlement_controller.gd")

const REGIONAL_DECISION_INTERVAL_MINUTES: int = 180
const REGIONAL_JOURNEY_STEP_MINUTES: int = 30
const REGIONAL_JOURNEY_LIMIT: int = 8
const REGIONAL_UPDATES_PER_STEP: int = 2
const REGIONAL_TRAVEL_MINUTES: int = 360
const REGIONAL_SURVEY_MINUTES: int = 180
const TRAIL_TRAFFIC_REQUIRED: int = 2
const ROAD_TRAFFIC_REQUIRED: int = 5
const MAINTAINED_ROAD_TRAFFIC_REQUIRED: int = 12
const WORLD_REGION_LIMIT: int = 257

var database: WorldDatabase = null
var settlement: SettlementController = SettlementController.new()
var faction_relations: Dictionary = {}
var history: Array[Dictionary] = []
## Estados resumidos de las regiones que no están materializadas. La clave es "x:z".
var regional_states: Dictionary = {}
## Viajes conservan la identidad del habitante mediante dwarf_id; nunca crean una copia.
var regional_journeys: Array[Dictionary] = []
## Tráfico acumulado entre regiones. Convierte recorridos repetidos en senderos y caminos.
var regional_routes: Dictionary = {}
var regional_update_cursor: int = 0
var elapsed_minutes: int = 0
var initialized: bool = false

## Lee una propiedad de Dictionary u Object sin llamar Object.get() con dos argumentos.
static func _safe_get(source: Variant, property_name: StringName, default_value: Variant = null) -> Variant:
	if source == null:
		return default_value
	if source is Dictionary:
		return source.get(property_name, default_value)
	if source is Object:
		var value: Variant = source.get(property_name)
		return default_value if value == null else value
	return default_value


func _init(world_database: WorldDatabase = null) -> void:
	database = world_database

func initialize(world) -> void:
	if database != null:
		for entity in world.entities:
			var creature_type = entity.get("creature_type")
			var definition = database.get_creature(str(creature_type) if creature_type != null else "")
			if definition != null and entity is DFCreature:
				definition.apply_to(entity)
	if initialized:
		_refresh_active_region(world)
		_restore_regional_assignments(world)
		return
	if faction_relations.is_empty():
		set_relation("dwarves", "goblins", -60)
		set_relation("dwarves", "humans", 15)
		set_relation("dwarves", "elves", 5)
		set_relation("humans", "goblins", -35)
	record("Fundación de %s" % settlement.name)
	initialized = true
	_refresh_active_region(world)
	_restore_regional_assignments(world)

func tick(world, minute_ticked: bool) -> Array[String]:
	if not minute_ticked:
		return []
	elapsed_minutes += 1
	_update_needs(world)
	settlement.refresh(world)
	_refresh_active_region(world)
	var messages: Array[String] = []
	if elapsed_minutes % 30 == 0:
		var decision = settlement.decide()
		if not decision.is_empty():
			messages.append("[ASENTAMIENTO] " + decision)
	if elapsed_minutes % REGIONAL_JOURNEY_STEP_MINUTES == 0:
		messages.append_array(_advance_regional_journeys(world))
	if elapsed_minutes % REGIONAL_DECISION_INTERVAL_MINUTES == 0:
		var regional_decision: String = _consider_regional_action(world)
		if not regional_decision.is_empty():
			messages.append("[REGIONES] " + regional_decision)
	if elapsed_minutes % 240 == 0:
		_decay_relations()
	return messages

func _active_region(world) -> Vector2i:
	var raw_region: Variant = world.get_meta("active_world_region", [])
	if raw_region is Array and raw_region.size() >= 2:
		return Vector2i(int(raw_region[0]), int(raw_region[1]))
	return Vector2i.ZERO

func _region_key(region: Vector2i) -> String:
	return "%d:%d" % [region.x, region.y]

func _route_key(first: Vector2i, second: Vector2i) -> String:
	var first_key: String = _region_key(first)
	var second_key: String = _region_key(second)
	return first_key + ">" + second_key if first_key < second_key else second_key + ">" + first_key

func _new_region_state(region: Vector2i) -> Dictionary:
	return {
		"x": region.x,
		"z": region.y,
		"discovered": false,
		"visited": false,
		"population": 0,
		"food": 0.0,
		"wood": 0.0,
		"housing": 0,
		"safety": 0.5,
		"outpost_level": 0,
		"last_update_minute": elapsed_minutes,
	}

func _ensure_region(region: Vector2i) -> Dictionary:
	var key: String = _region_key(region)
	if not regional_states.has(key):
		regional_states[key] = _new_region_state(region)
	return regional_states[key]

func _refresh_active_region(world) -> void:
	var region: Vector2i = _active_region(world)
	var state: Dictionary = _ensure_region(region)
	state["discovered"] = true
	state["visited"] = true
	state["population"] = settlement.population
	state["food"] = settlement.food_reserve
	state["wood"] = settlement.wood_reserve
	state["housing"] = world.buildings.size()
	state["last_update_minute"] = elapsed_minutes
	regional_states[_region_key(region)] = state

func _consider_regional_action(world) -> String:
	if settlement.population < 5:
		return ""
	if settlement.food_reserve < float(settlement.population) * 2.0:
		return ""
	if regional_journeys.size() >= REGIONAL_JOURNEY_LIMIT:
		return ""
	var explorer: Variant = _select_regional_explorer(world)
	if explorer == null:
		return ""
	var origin: Vector2i = _active_region(world)
	var target: Vector2i = _choose_neighbor(origin, int(explorer.get("id")))
	if target == origin:
		return ""
	var explorer_id: int = int(explorer.get("id"))
	var explorer_name: String = str(explorer.get("name"))
	var journey: Dictionary = {
		"dwarf_id": explorer_id,
		"dwarf_name": explorer_name,
		"origin": [origin.x, origin.y],
		"target": [target.x, target.y],
		"stage": "outbound",
		"remaining_minutes": REGIONAL_TRAVEL_MINUTES,
		"started_minute": elapsed_minutes,
	}
	regional_journeys.append(journey)
	explorer.set_meta("regional_assignment", journey.duplicate(true))
	explorer.set("autonomous_goal", "Explorar otra región")
	explorer.set("autonomous_reason", "Curiosidad, iniciativa y estabilidad del asentamiento")
	record("%s partió por iniciativa propia hacia la región %s." % [explorer_name, _region_key(target)])
	return "%s decidió explorar la región %s sin recibir órdenes." % [explorer_name, _region_key(target)]

func _select_regional_explorer(world) -> Variant:
	var best: Variant = null
	var best_score: float = 0.62
	for dwarf: Variant in world.dwarves:
		if dwarf.get("is_alive") == false or dwarf.get("creature_type") != "dwarf":
			continue
		if dwarf.get("is_possessed") == true or dwarf.get("current_job") != null:
			continue
		if dwarf.has_meta("regional_assignment"):
			continue
		var personality_value: Variant = dwarf.get("personality")
		var personality: Dictionary = personality_value if personality_value is Dictionary else {}
		var curiosity: float = float(personality.get(6, 0.5))
		var ambition: float = float(personality.get(17, 0.5))
		var bravery: float = float(personality.get(0, 0.5))
		var fear: float = float(personality.get(11, 0.5))
		var industry: float = float(personality.get(3, 0.5))
		var score: float = curiosity * 0.34 + ambition * 0.23 + bravery * 0.20 + industry * 0.13 + (1.0 - fear) * 0.10
		if score > best_score:
			best = dwarf
			best_score = score
	return best

func _choose_neighbor(origin: Vector2i, dwarf_id: int) -> Vector2i:
	var directions: Array[Vector2i] = [
		Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1),
	]
	var decision_cycle: int = elapsed_minutes / REGIONAL_DECISION_INTERVAL_MINUTES
	var start_index: int = posmod(dwarf_id + decision_cycle, directions.size())
	for offset: int in range(directions.size()):
		var direction: Vector2i = directions[(start_index + offset) % directions.size()]
		var candidate: Vector2i = origin + direction
		if candidate.x >= 0 and candidate.y >= 0 and candidate.x < WORLD_REGION_LIMIT and candidate.y < WORLD_REGION_LIMIT:
			var state: Dictionary = _ensure_region(candidate)
			if not bool(state.get("discovered", false)):
				return candidate
	var fallback: Vector2i = origin + directions[start_index]
	fallback.x = clampi(fallback.x, 0, WORLD_REGION_LIMIT - 1)
	fallback.y = clampi(fallback.y, 0, WORLD_REGION_LIMIT - 1)
	return fallback

func _advance_regional_journeys(world) -> Array[String]:
	var messages: Array[String] = []
	if regional_journeys.is_empty():
		return messages
	var updates: int = mini(REGIONAL_UPDATES_PER_STEP, regional_journeys.size())
	for _update_index: int in range(updates):
		if regional_journeys.is_empty():
			break
		regional_update_cursor = posmod(regional_update_cursor, regional_journeys.size())
		var journey: Dictionary = regional_journeys[regional_update_cursor]
		journey["remaining_minutes"] = maxi(0, int(journey.get("remaining_minutes", 0)) - REGIONAL_JOURNEY_STEP_MINUTES)
		if int(journey["remaining_minutes"]) > 0:
			regional_journeys[regional_update_cursor] = journey
			regional_update_cursor += 1
			continue
		var stage: String = str(journey.get("stage", "outbound"))
		if stage == "outbound":
			journey["stage"] = "survey"
			journey["remaining_minutes"] = REGIONAL_SURVEY_MINUTES
			var target: Vector2i = _array_to_region(journey.get("target", []))
			var target_state: Dictionary = _ensure_region(target)
			target_state["discovered"] = true
			target_state["last_update_minute"] = elapsed_minutes
			regional_states[_region_key(target)] = target_state
			messages.append("[REGIONES] %s alcanzó y comenzó a reconocer %s." % [journey.get("dwarf_name", "Un explorador"), _region_key(target)])
			regional_journeys[regional_update_cursor] = journey
			regional_update_cursor += 1
		elif stage == "survey":
			journey["stage"] = "returning"
			journey["remaining_minutes"] = REGIONAL_TRAVEL_MINUTES
			regional_journeys[regional_update_cursor] = journey
			regional_update_cursor += 1
		else:
			messages.append(_complete_regional_journey(world, journey))
			regional_journeys.remove_at(regional_update_cursor)
	return messages

func _complete_regional_journey(world, journey: Dictionary) -> String:
	var origin: Vector2i = _array_to_region(journey.get("origin", []))
	var target: Vector2i = _array_to_region(journey.get("target", []))
	var route_key: String = _route_key(origin, target)
	var route: Dictionary = regional_routes.get(route_key, {
		"from": [origin.x, origin.y],
		"to": [target.x, target.y],
		"traffic": 0,
		"level": 0,
		"last_used_minute": elapsed_minutes,
	})
	route["traffic"] = int(route.get("traffic", 0)) + 1
	route["level"] = _route_level_for_traffic(int(route["traffic"]))
	route["last_used_minute"] = elapsed_minutes
	regional_routes[route_key] = route
	var dwarf_id: int = int(journey.get("dwarf_id", -1))
	var dwarf: Variant = _find_dwarf(world, dwarf_id)
	if dwarf != null:
		dwarf.remove_meta("regional_assignment")
		dwarf.set_meta("regions_explored", int(dwarf.get_meta("regions_explored", 0)) + 1)
		dwarf.set("autonomous_goal", "")
		dwarf.set("autonomous_reason", "")
		var history_value: Variant = dwarf.get("life_history")
		if history_value is Array:
			history_value.append({
				"minute": elapsed_minutes,
				"type": "regional_exploration",
				"description": "Exploró la región %s y regresó por voluntad propia." % _region_key(target),
			})
	var traveler_name: String = str(journey.get("dwarf_name", "El explorador"))
	var route_label: String = _route_level_name(int(route["level"]))
	record("%s regresó de %s; la ruta ahora es %s." % [traveler_name, _region_key(target), route_label])
	return "[REGIONES] %s regresó de %s. El tránsito formó %s." % [traveler_name, _region_key(target), route_label]

func _route_level_for_traffic(traffic: int) -> int:
	if traffic >= MAINTAINED_ROAD_TRAFFIC_REQUIRED:
		return 3
	if traffic >= ROAD_TRAFFIC_REQUIRED:
		return 2
	if traffic >= TRAIL_TRAFFIC_REQUIRED:
		return 1
	return 0

func _route_level_name(level: int) -> String:
	match level:
		1:
			return "un sendero"
		2:
			return "un camino"
		3:
			return "un camino mantenido"
		_:
			return "una ruta apenas reconocible"

func _array_to_region(value: Variant) -> Vector2i:
	if value is Array and value.size() >= 2:
		return Vector2i(int(value[0]), int(value[1]))
	return Vector2i.ZERO

func _find_dwarf(world, dwarf_id: int) -> Variant:
	for dwarf: Variant in world.dwarves:
		if int(dwarf.get("id")) == dwarf_id:
			return dwarf
	return null

func _restore_regional_assignments(world) -> void:
	for journey: Dictionary in regional_journeys:
		var dwarf: Variant = _find_dwarf(world, int(journey.get("dwarf_id", -1)))
		if dwarf != null:
			dwarf.set_meta("regional_assignment", journey.duplicate(true))

func _update_needs(world) -> void:
	for entity in world.entities:
		if entity.get("is_alive") == false or entity.get("creature_type") == null:
			continue
		var needs: Dictionary = entity.get_meta("simulation_needs", {"hunger": 0.0, "thirst": 0.0, "sleep": 0.0, "safety": 0.0, "social": 0.0})
		needs["hunger"] = clampf(float(needs.get("hunger", 0.0)) + 0.012, 0.0, 1.0)
		needs["thirst"] = clampf(float(needs.get("thirst", 0.0)) + 0.016, 0.0, 1.0)
		needs["sleep"] = clampf(float(needs.get("sleep", 0.0)) + 0.008, 0.0, 1.0)
		needs["safety"] = clampf(float(_safe_get(entity, "fear_level", 0.0)), 0.0, 1.0)
		entity.set_meta("simulation_needs", needs)
		var priority = _highest_need(needs)
		entity.set_meta("simulation_priority", priority)
		if entity.get("creature_type") != "dwarf":
			if priority == "hunger": entity.hunger = maxf(float(_safe_get(entity, "hunger", 0.0)), 0.72)
			elif priority == "thirst": entity.thirst = maxf(float(_safe_get(entity, "thirst", 0.0)), 0.72)
			elif priority == "sleep": entity.fatigue = maxf(float(_safe_get(entity, "fatigue", 0.0)), 0.78)

func _highest_need(needs: Dictionary) -> String:
	var selected := ""
	var value := -1.0
	for need_name in needs:
		if float(needs[need_name]) > value:
			selected = need_name
			value = float(needs[need_name])
	return selected

func set_relation(first_faction: String, second_faction: String, value: int) -> void:
	faction_relations[_relation_key(first_faction, second_faction)] = clampi(value, -100, 100)

func get_relation(first_faction: String, second_faction: String) -> int:
	return faction_relations.get(_relation_key(first_faction, second_faction), 0)

func _decay_relations() -> void:
	for key in faction_relations:
		faction_relations[key] = move_toward(float(faction_relations[key]), 0.0, 1.0)

func _relation_key(first_faction: String, second_faction: String) -> String:
	return first_faction + ":" + second_faction if first_faction < second_faction else second_faction + ":" + first_faction

func record(description: String) -> void:
	history.append({"minute": elapsed_minutes, "description": description})
	if history.size() > 200:
		history.pop_front()

func export_state() -> Dictionary:
	return {
		"elapsed_minutes": elapsed_minutes,
		"faction_relations": faction_relations.duplicate(true),
		"history": history.duplicate(true),
		"initialized": initialized,
		"settlement": settlement.export_state(),
		"regional_states": regional_states.duplicate(true),
		"regional_journeys": regional_journeys.duplicate(true),
		"regional_routes": regional_routes.duplicate(true),
		"regional_update_cursor": regional_update_cursor,
	}

func import_state(data: Dictionary) -> void:
	elapsed_minutes = int(data.get("elapsed_minutes", 0))
	faction_relations = data.get("faction_relations", {}).duplicate(true)
	history.clear()
	for entry: Variant in data.get("history", []):
		if entry is Dictionary:
			history.append({
				"minute": int(entry.get("minute", 0)),
				"description": str(entry.get("description", "")),
			})
	initialized = bool(data.get("initialized", true))
	var settlement_data: Variant = data.get("settlement", {})
	if settlement_data is Dictionary:
		settlement.import_state(settlement_data)
	var states_value: Variant = data.get("regional_states", {})
	regional_states.clear()
	if states_value is Dictionary:
		for state_key: Variant in states_value:
			var state_value: Variant = states_value[state_key]
			if state_value is Dictionary:
				regional_states[str(state_key)] = _normalize_region_state(state_value)
	var routes_value: Variant = data.get("regional_routes", {})
	regional_routes.clear()
	if routes_value is Dictionary:
		for route_key: Variant in routes_value:
			var route_value: Variant = routes_value[route_key]
			if route_value is Dictionary:
				regional_routes[str(route_key)] = _normalize_route(route_value)
	regional_journeys.clear()
	for journey: Variant in data.get("regional_journeys", []):
		if journey is Dictionary:
			regional_journeys.append(_normalize_journey(journey))
	regional_update_cursor = int(data.get("regional_update_cursor", 0))

func _normalize_region_state(state: Dictionary) -> Dictionary:
	return {
		"x": int(state.get("x", 0)),
		"z": int(state.get("z", 0)),
		"discovered": bool(state.get("discovered", false)),
		"visited": bool(state.get("visited", false)),
		"population": int(state.get("population", 0)),
		"food": float(state.get("food", 0.0)),
		"wood": float(state.get("wood", 0.0)),
		"housing": int(state.get("housing", 0)),
		"safety": float(state.get("safety", 0.5)),
		"outpost_level": int(state.get("outpost_level", 0)),
		"last_update_minute": int(state.get("last_update_minute", 0)),
	}

func _normalize_route(route: Dictionary) -> Dictionary:
	var from_region: Vector2i = _array_to_region(route.get("from", []))
	var to_region: Vector2i = _array_to_region(route.get("to", []))
	return {
		"from": [from_region.x, from_region.y],
		"to": [to_region.x, to_region.y],
		"traffic": int(route.get("traffic", 0)),
		"level": int(route.get("level", 0)),
		"last_used_minute": int(route.get("last_used_minute", 0)),
	}

func _normalize_journey(journey: Dictionary) -> Dictionary:
	var origin: Vector2i = _array_to_region(journey.get("origin", []))
	var target: Vector2i = _array_to_region(journey.get("target", []))
	return {
		"dwarf_id": int(journey.get("dwarf_id", -1)),
		"dwarf_name": str(journey.get("dwarf_name", "")),
		"origin": [origin.x, origin.y],
		"target": [target.x, target.y],
		"stage": str(journey.get("stage", "outbound")),
		"remaining_minutes": int(journey.get("remaining_minutes", 0)),
		"started_minute": int(journey.get("started_minute", 0)),
	}
