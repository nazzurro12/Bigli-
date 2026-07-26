extends RefCounted
class_name DFConsequenceSystem

const MAX_WORLD_EVENTS: int = 500
const MAX_PERSONAL_EVENTS: int = 80
const WITNESS_RANGE: int = 8

var world = null
var events: Array = []
var next_event_id: int = 1

func _init(p_world = null) -> void:
	world = p_world

func record_action(actor, action_type: String, data: Dictionary = {}) -> Dictionary:
	if actor == null:
		return {}
	var position: Vector3i = data.get("position", actor.tile_pos)
	var witnesses: Array = []
	if data.get("detect_witnesses", true):
		witnesses = _find_witnesses(actor, position, data.get("witness_ids", []))
	var event: Dictionary = {
		"id": next_event_id,
		"type": action_type,
		"actor_id": actor.id,
		"actor_name": actor.name,
		"position": [position.x, position.y, position.z],
		"target_ids": data.get("target_ids", []).duplicate(),
		"witness_ids": witnesses.map(func(person): return person.id),
		"tags": data.get("tags", []).duplicate(),
		"severity": clampf(float(data.get("severity", 0.25)), 0.0, 1.0),
		"summary": str(data.get("summary", _default_summary(actor, action_type))),
		"possession_origin": bool(data.get("possession_origin", actor.is_possessed)),
		"time": Time.get_ticks_msec()
	}
	next_event_id += 1
	events.append(event)
	if events.size() > MAX_WORLD_EVENTS:
		events.pop_front()
	_apply_consequences(actor, witnesses, event)
	return event

func record_possession_started(actor) -> Dictionary:
	actor.possession_count += 1
	return record_action(actor, "possession_started", {
		"tags": ["possession", "identity"],
		"severity": 0.1,
		"witness_ids": [],
		"detect_witnesses": false,
		"summary": "%s quedó bajo control del jugador." % actor.name,
		"possession_origin": true
	})

func record_possession_ended(actor) -> Dictionary:
	var event: Dictionary = record_action(actor, "possession_ended", {
		"tags": ["possession", "identity", "continuity"],
		"severity": 0.2,
		"witness_ids": [],
		"detect_witnesses": false,
		"summary": "%s recuperó su autonomía con una historia cambiada." % actor.name,
		"possession_origin": true
	})
	actor.last_possession_event_id = int(event.get("id", -1))
	return event

func _apply_consequences(actor, witnesses: Array, event: Dictionary) -> void:
	var tags: Array = event.get("tags", [])
	var severity: float = float(event.get("severity", 0.25))
	_append_personal_event(actor, event)
	_apply_reputation(actor, tags, severity)
	for witness in witnesses:
		_append_personal_event(witness, event)
		if witness.has_method("add_memory"):
			witness.add_memory("witness", str(event.summary), severity)
		if witness.has_method("modify_relationship"):
			witness.modify_relationship(actor.id, _relationship_delta(tags, severity))
	_evaluate_opportunities(actor, witnesses, event)

func _apply_reputation(actor, tags: Array, severity: float) -> void:
	var changes: Dictionary = {
		"rescue": {"valor": 0.45, "proteccion": 0.55, "confianza": 0.25},
		"defense": {"valor": 0.35, "proteccion": 0.40},
		"help": {"proteccion": 0.20, "confianza": 0.20},
		"theft": {"delito": 0.45, "confianza": -0.35},
		"threat": {"violencia": 0.35, "confianza": -0.20},
		"affection": {"afecto": 0.20},
		"craft": {"oficio": 0.20},
		"work": {"oficio": 0.10}
	}
	for tag: Variant in tags:
		var dimensions: Dictionary = changes.get(str(tag), {})
		for dimension: Variant in dimensions:
			var current: float = float(actor.reputation.get(dimension, 0.0))
			actor.reputation[dimension] = clampf(current + float(dimensions[dimension]) * severity, -1.0, 1.0)

func _evaluate_opportunities(actor, witnesses: Array, event: Dictionary) -> void:
	var tags: Array = event.get("tags", [])
	if "rescue" not in tags or "defense" not in tags:
		return
	var authority_witness = null
	for witness in witnesses:
		if witness.is_military or witness.is_noble or witness.appointed_position.to_lower() in ["capitan de la guardia", "monarca", "rey", "reina"]:
			authority_witness = witness
			break
	if authority_witness == null:
		return
	var protection: float = float(actor.reputation.get("proteccion", 0.0))
	var courage: float = float(actor.reputation.get("valor", 0.0))
	if protection < 0.25 or courage < 0.20:
		return
	for existing: Variant in actor.career_offers:
		if existing is Dictionary and existing.get("role", "") == "guard":
			return
	var offer: Dictionary = {
		"role": "guard",
		"source_id": authority_witness.id,
		"source_name": authority_witness.name,
		"event_id": event.id,
		"reason": "Su intervención fue presenciada y demostró valor protegiendo a otros.",
		"status": "pending"
	}
	actor.career_offers.append(offer)
	actor.add_memory("opportunity", "%s recomienda a %s para la guardia." % [authority_witness.name, actor.name], 0.8)

func _find_witnesses(actor, position: Vector3i, explicit_ids: Array) -> Array:
	var result: Array = []
	if world == null:
		return result
	for candidate in world.dwarves:
		if candidate == actor or not candidate.is_alive:
			continue
		var explicit: bool = candidate.id in explicit_ids
		var distance: int = abs(candidate.tile_pos.x - position.x) + abs(candidate.tile_pos.y - position.y) + abs(candidate.tile_pos.z - position.z)
		if explicit or distance <= WITNESS_RANGE:
			result.append(candidate)
	return result

func _append_personal_event(person, event: Dictionary) -> void:
	person.life_history.append(event.duplicate(true))
	person.recent_events.append(event.duplicate(true))
	if person.life_history.size() > MAX_PERSONAL_EVENTS:
		person.life_history.pop_front()
	if person.recent_events.size() > 12:
		person.recent_events.pop_front()

func _relationship_delta(tags: Array, severity: float) -> float:
	if "rescue" in tags or "help" in tags:
		return 0.35 * severity
	if "theft" in tags or "threat" in tags:
		return -0.35 * severity
	return 0.0

func _default_summary(actor, action_type: String) -> String:
	return "%s realizó la acción '%s'." % [actor.name, action_type]
