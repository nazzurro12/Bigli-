extends RefCounted
class_name DFWorldSimulation

const WorldDatabase = preload("res://df_mode/core/database/world_database.gd")
const SettlementController = preload("res://df_mode/core/simulation/settlement_controller.gd")

var database: WorldDatabase = null
var settlement: SettlementController = SettlementController.new()
var faction_relations: Dictionary = {}
var history: Array[Dictionary] = []
var elapsed_minutes: int = 0
var next_event_id: int = 1

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
	if faction_relations.is_empty():
		set_relation("dwarves", "goblins", -60)
		set_relation("dwarves", "humans", 15)
		set_relation("dwarves", "elves", 5)
		set_relation("humans", "goblins", -35)
	record("Fundación de %s" % settlement.name)

func tick(world, minute_ticked: bool) -> Array[String]:
	if not minute_ticked:
		return []
	elapsed_minutes += 1
	world.set_meta("simulation_minute", elapsed_minutes)
	_update_needs(world)
	settlement.refresh(world)
	var messages: Array[String] = []
	if elapsed_minutes % 30 == 0:
		var decision = settlement.decide()
		if not decision.is_empty():
			messages.append("[ASENTAMIENTO] " + decision)
	if elapsed_minutes % 240 == 0:
		_decay_relations()
	return messages

func _update_needs(world) -> void:
	for entity in world.entities:
		if entity.get("is_alive") == false or entity.get("creature_type") == null:
			continue
		# DFDwarf es la única autoridad de sus necesidades. La capa mundial no
		# mantiene una segunda copia en metadata porque ambas terminaban divergiendo.
		if entity.get("creature_type") == "dwarf":
			var dwarf_needs: Dictionary = _safe_get(entity, "needs", {})
			entity.set_meta("simulation_priority", _highest_need(dwarf_needs))
			continue
		var hunger := clampf(float(_safe_get(entity, "hunger", 0.0)), 0.0, 2.0)
		var thirst := clampf(float(_safe_get(entity, "thirst", 0.0)), 0.0, 2.0)
		var fatigue := clampf(float(_safe_get(entity, "fatigue", 0.0)), 0.0, 2.0)
		entity.set_meta("simulation_priority", _highest_need({
			"hunger": hunger,
			"thirst": thirst,
			"sleep": fatigue,
			"safety": clampf(float(_safe_get(entity, "fear_level", 0.0)), 0.0, 1.0)
		}))

func _highest_need(needs: Dictionary) -> Variant:
	var selected: Variant = ""
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

func record(description: String, event_type: String = "simulation", participants: Array = [], location: Variant = null, cause_event_id: int = -1) -> int:
	var event_id := next_event_id
	next_event_id += 1
	history.append({
		"id": event_id,
		"minute": elapsed_minutes,
		"type": event_type,
		"description": description,
		"participants": participants.duplicate(),
		"location": location,
		"cause_event_id": cause_event_id
	})
	if history.size() > 200:
		history.pop_front()
	return event_id

func serialize_state() -> Dictionary:
	return {
		"elapsed_minutes": elapsed_minutes,
		"next_event_id": next_event_id,
		"faction_relations": faction_relations.duplicate(true),
		"history": history.duplicate(true),
		"settlement_name": settlement.name,
		"settlement_faction_id": settlement.faction_id
	}

func restore_state(data: Dictionary) -> void:
	elapsed_minutes = maxi(0, int(data.get("elapsed_minutes", 0)))
	next_event_id = maxi(1, int(data.get("next_event_id", 1)))
	faction_relations = data.get("faction_relations", {}).duplicate(true)
	history = data.get("history", []).duplicate(true)
	settlement.name = str(data.get("settlement_name", "Fortaleza"))
	settlement.faction_id = str(data.get("settlement_faction_id", "dwarves"))
