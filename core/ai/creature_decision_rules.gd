class_name CreatureDecisionRules
extends RefCounted
## Decisiones puras de IA. El ejecutor sigue siendo DFCreature durante la migración.

static func can_scan_for_trigger(triggers: PackedStringArray, is_daytime: bool, nocturnal: bool) -> bool:
	if triggers.is_empty():
		return false
	# Una criatura nocturna no inicia caza diurna, salvo si reacciona al daño.
	return not (nocturnal and is_daytime and not triggers.has("on_attacked"))

static func is_player_target(entity: Object) -> bool:
	return entity is DFDwarf

static func is_valid_living_target(entity: Object, self_entity: Object) -> bool:
	if entity == null or entity == self_entity:
		return false

	# world.entities contiene criaturas y objetos. Un DFItem normalmente no tiene
	# creature_type, health ni is_alive, por lo que nunca debe ser un objetivo.
	var creature_type_value: Variant = entity.get("creature_type")
	var health_value: Variant = entity.get("health")
	var alive_value: Variant = entity.get("is_alive")
	var tile_pos_value: Variant = entity.get("tile_pos")

	if creature_type_value == null or str(creature_type_value).is_empty():
		return false
	if health_value == null or tile_pos_value == null:
		return false
	return alive_value == true and float(health_value) > 0.0

static func manhattan_distance(a: Vector3i, b: Vector3i) -> int:
	return abs(a.x - b.x) + abs(a.z - b.z)
