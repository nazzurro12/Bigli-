extends RefCounted
class_name DFWorldSimulation

const WorldDatabase = preload("res://df_mode/core/database/world_database.gd")
const SettlementController = preload("res://df_mode/core/simulation/settlement_controller.gd")

var database: WorldDatabase = null
var settlement: SettlementController = SettlementController.new()
var faction_relations: Dictionary = {}
var history: Array[Dictionary] = []
var elapsed_minutes: int = 0

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
			if definition != null:
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
