extends RefCounted
class_name DFConsequenceSystem

const MAX_WORLD_EVENTS: int = 500
const MAX_PERSONAL_EVENTS: int = 80
const MAX_RUMORS_PER_PERSON: int = 24
const SOCIAL_BUDGET_PER_TICK: int = 8
const WITNESS_RANGE: int = 8

var world = null
var events: Array = []
var next_event_id: int = 1
var social_cursor: int = 0

func _init(p_world: Object = null) -> void:
	world = p_world

func record_action(actor: Object, action_type: String, data: Dictionary = {}) -> Dictionary:
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
		"witness_names": witnesses.map(func(person): return str(person.name)),
		"tags": data.get("tags", []).duplicate(),
		"severity": clampf(float(data.get("severity", 0.25)), 0.0, 1.0),
		"summary": str(data.get("summary", _default_summary(actor, action_type))),
		"interpretations": data.get("interpretations", []).duplicate(true),
		"immediate_results": data.get("immediate_results", []).duplicate(true),
		"future_hooks": data.get("future_hooks", []).duplicate(true),
		"caused_by_event_id": int(data.get("caused_by_event_id", -1)),
		"possession_origin": bool(data.get("possession_origin", actor.is_possessed)),
		"world_minute": _world_minute(),
		"status": "observed" if not witnesses.is_empty() else "private"
	}
	next_event_id += 1
	events.append(event)
	if events.size() > MAX_WORLD_EVENTS:
		events.pop_front()
	_apply_consequences(actor, witnesses, event)
	return event

func get_event_report(event_id: int) -> Dictionary:
	for event: Dictionary in events:
		if int(event.get("id", -1)) != event_id:
			continue
		var report: Dictionary = event.duplicate(true)
		var focus_event: Dictionary = event
		var parent_id: int = int(event.get("caused_by_event_id", -1))
		if parent_id >= 0:
			var parent_event: Dictionary = _event_by_id(parent_id)
			if not parent_event.is_empty():
				focus_event = parent_event
		report["action"] = focus_event.duplicate(true)
		report["headline"] = str(focus_event.get("summary", "Acción sin descripción"))
		report["witness_names"] = focus_event.get("witness_names", []).duplicate()
		report["interpretations"] = focus_event.get("interpretations", []).duplicate(true)
		report["immediate_results"] = focus_event.get("immediate_results", []).duplicate(true)
		report["future_hooks"] = focus_event.get("future_hooks", []).duplicate(true)
		report["observation"] = "Presenciada por %s." % ", ".join(focus_event.get("witness_names", [])) if not focus_event.get("witness_names", []).is_empty() else "Nadie presenció la acción."
		report["causal_chain"] = _build_causal_chain(event)
		return report
	return {}

func _build_causal_chain(event: Dictionary) -> Array:
	var chain: Array = []
	var cursor: Dictionary = event
	var visited: Dictionary = {}
	while not cursor.is_empty() and not visited.has(int(cursor.get("id", -1))):
		var cursor_id: int = int(cursor.get("id", -1))
		visited[cursor_id] = true
		chain.push_front({
			"id": cursor_id,
			"summary": str(cursor.get("summary", "")),
			"world_minute": int(cursor.get("world_minute", 0))
		})
		var parent_id: int = int(cursor.get("caused_by_event_id", -1))
		if parent_id < 0:
			break
		cursor = _event_by_id(parent_id)
	return chain

func _event_by_id(event_id: int) -> Dictionary:
	for event: Dictionary in events:
		if int(event.get("id", -1)) == event_id:
			return event
	return {}

func _world_minute() -> int:
	if world == null:
		return 0
	if world.has_meta("simulation_minute"):
		return int(world.get_meta("simulation_minute", 0))
	return int(world.get_meta("simulation_tick_total", 0)) / 25

func tick_social_simulation(absolute_minute: int) -> Array:
	var results: Array = []
	if world == null or world.dwarves.is_empty():
		return results
	var processed: int = mini(SOCIAL_BUDGET_PER_TICK, world.dwarves.size())
	for offset: int in range(processed):
		var index: int = (social_cursor + offset) % world.dwarves.size()
		var person = world.dwarves[index]
		if person == null or not person.is_alive or person.is_possessed:
			continue
		var decision: Dictionary = _resolve_pending_opportunity(person, absolute_minute)
		if not decision.is_empty():
			results.append(decision)
		_share_one_rumor(person, absolute_minute)
	social_cursor = (social_cursor + processed) % world.dwarves.size()
	return results

func record_possession_started(actor: Object) -> Dictionary:
	actor.possession_count += 1
	return record_action(actor, "possession_started", {
		"tags": ["possession", "identity"],
		"severity": 0.1,
		"witness_ids": [],
		"detect_witnesses": false,
		"summary": "%s quedó bajo control del jugador." % actor.name,
		"possession_origin": true
	})

func record_possession_ended(actor: Object) -> Dictionary:
	var caused_by_event_id: int = -1
	for recent_index: int in range(actor.recent_events.size() - 1, -1, -1):
		var recent_event: Dictionary = actor.recent_events[recent_index]
		if bool(recent_event.get("possession_origin", false)) and str(recent_event.get("type", "")) not in ["possession_started", "possession_ended"]:
			caused_by_event_id = int(recent_event.get("id", -1))
			break
	var event: Dictionary = record_action(actor, "possession_ended", {
		"tags": ["possession", "identity", "continuity"],
		"severity": 0.2,
		"witness_ids": [],
		"detect_witnesses": false,
		"summary": "%s recuperó su autonomía con una historia cambiada." % actor.name,
		"caused_by_event_id": caused_by_event_id,
		"possession_origin": true
	})
	actor.last_possession_event_id = int(event.get("id", -1))
	return event

func _apply_consequences(actor: Object, witnesses: Array, event: Dictionary) -> void:
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
		_update_witness_knowledge(witness, actor, event, 1.0)
		_add_rumor(witness, event, 1.0, witness.id)
	_apply_law(actor, witnesses, event)
	_evaluate_opportunities(actor, witnesses, event)

func _apply_reputation(actor: Object, tags: Array, severity: float) -> void:
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

func _evaluate_opportunities(actor: Object, witnesses: Array, event: Dictionary) -> void:
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
		"created_minute": int(world.get_meta("simulation_tick_total", 0)) / 25 if world != null else 0,
		"reason": "Su intervención fue presenciada y demostró valor protegiendo a otros.",
		"status": "pending"
	}
	actor.career_offers.append(offer)
	actor.add_memory("opportunity", "%s recomienda a %s para la guardia." % [authority_witness.name, actor.name], 0.8)

func _update_witness_knowledge(observer: Object, actor: Object, event: Dictionary, confidence: float) -> void:
	var actor_knowledge: Dictionary = observer.known_reputations.get(actor.id, {
		"valor": 0.0, "proteccion": 0.0, "confianza": 0.0,
		"delito": 0.0, "violencia": 0.0, "confidence": 0.0
	})
	var tags: Array = event.get("tags", [])
	var severity: float = float(event.get("severity", 0.25)) * confidence
	if "rescue" in tags or "defense" in tags:
		actor_knowledge["valor"] = clampf(float(actor_knowledge.get("valor", 0.0)) + 0.4 * severity, -1.0, 1.0)
		actor_knowledge["proteccion"] = clampf(float(actor_knowledge.get("proteccion", 0.0)) + 0.5 * severity, -1.0, 1.0)
		actor_knowledge["confianza"] = clampf(float(actor_knowledge.get("confianza", 0.0)) + 0.25 * severity, -1.0, 1.0)
	if "theft" in tags or "crime" in tags:
		actor_knowledge["delito"] = clampf(float(actor_knowledge.get("delito", 0.0)) + 0.5 * severity, -1.0, 1.0)
		actor_knowledge["confianza"] = clampf(float(actor_knowledge.get("confianza", 0.0)) - 0.35 * severity, -1.0, 1.0)
	if "threat" in tags or "assault" in tags:
		actor_knowledge["violencia"] = clampf(float(actor_knowledge.get("violencia", 0.0)) + 0.45 * severity, -1.0, 1.0)
	actor_knowledge["confidence"] = maxf(float(actor_knowledge.get("confidence", 0.0)), confidence)
	actor_knowledge["last_event_id"] = event.get("id", -1)
	observer.known_reputations[actor.id] = actor_knowledge

func _apply_law(actor, witnesses: Array, event: Dictionary) -> void:
	var tags: Array = event.get("tags", [])
	if "crime" not in tags and "theft" not in tags and "assault" not in tags:
		return
	var authority_ids: Array = []
	for witness in witnesses:
		if witness.is_military or witness.is_noble or witness.profession in [25, 28, 29, 33, 34]:
			authority_ids.append(witness.id)
	var legal_case: Dictionary = {
		"event_id": event.get("id", -1),
		"offense": _offense_name(tags),
		"severity": event.get("severity", 0.25),
		"authority_witness_ids": authority_ids,
		"status": "reported" if not authority_ids.is_empty() else "unreported",
		"summary": event.get("summary", "")
	}
	actor.legal_record.append(legal_case)
	if actor.legal_record.size() > 30:
		actor.legal_record.pop_front()

func _add_rumor(person, event: Dictionary, confidence: float, source_id: int) -> void:
	for known: Variant in person.rumors:
		if known is Dictionary and int(known.get("event_id", -1)) == int(event.get("id", -2)):
			if confidence > float(known.get("confidence", 0.0)):
				known["confidence"] = confidence
				known["source_id"] = source_id
			return
	person.rumors.append({
		"event_id": event.get("id", -1),
		"actor_id": event.get("actor_id", -1),
		"summary": event.get("summary", ""),
		"tags": event.get("tags", []).duplicate(),
		"confidence": confidence,
		"source_id": source_id,
		"heard_at": event.get("world_minute", _world_minute())
	})
	if person.rumors.size() > MAX_RUMORS_PER_PERSON:
		person.rumors.pop_front()

func _share_one_rumor(speaker, absolute_minute: int) -> void:
	if speaker.rumors.is_empty() or world == null:
		return
	var listener = null
	var best_distance: int = 5
	for candidate in world.dwarves:
		if candidate == speaker or not candidate.is_alive:
			continue
		var distance: int = abs(candidate.tile_pos.x - speaker.tile_pos.x) + abs(candidate.tile_pos.z - speaker.tile_pos.z)
		if distance < best_distance:
			best_distance = distance
			listener = candidate
	if listener == null:
		return
	var rumor_index: int = (absolute_minute + speaker.id) % speaker.rumors.size()
	var rumor: Dictionary = speaker.rumors[rumor_index]
	var confidence: float = float(rumor.get("confidence", 0.0)) * 0.72
	if confidence < 0.18:
		return
	var actor = world.get_dwarf_by_id(int(rumor.get("actor_id", -1)))
	if actor == null:
		return
	var synthetic_event: Dictionary = {
		"id": rumor.get("event_id", -1),
		"tags": rumor.get("tags", []),
		"severity": confidence,
		"summary": rumor.get("summary", "")
	}
	_add_rumor(listener, synthetic_event, confidence, speaker.id)
	_update_witness_knowledge(listener, actor, synthetic_event, confidence)

func _resolve_pending_opportunity(person, absolute_minute: int) -> Dictionary:
	for offer: Variant in person.career_offers:
		if not (offer is Dictionary) or offer.get("status", "") != "pending":
			continue
		if absolute_minute - int(offer.get("created_minute", absolute_minute - 60)) < 30:
			continue
		var bravery: float = float(person.personality.get(0, 0.5))
		var industry: float = float(person.personality.get(3, 0.5))
		var ambition: float = float(person.personality.get(17, 0.5))
		var violence: float = float(person.personality.get(2, 0.5))
		var acceptance: float = bravery * 0.30 + industry * 0.25 + ambition * 0.35 + violence * 0.10
		var accepted: bool = acceptance >= 0.52
		offer["status"] = "accepted" if accepted else "declined"
		offer["decided_minute"] = absolute_minute
		var decision: Dictionary = {
			"type": "career_decision",
			"role": offer.get("role", ""),
			"accepted": accepted,
			"reason": "La decisión nació de su personalidad y experiencia.",
			"minute": absolute_minute
		}
		person.life_decisions.append(decision)
		if accepted and offer.get("role", "") == "guard":
			person.profession = 13
			person.is_military = true
			if "guard" not in person.social_roles:
				person.social_roles.append("guard")
			person.current_task = "reporting_for_guard_duty"
			person.add_memory("life_change", "%s decidió incorporarse a la guardia." % person.name, 0.9)
		else:
			person.add_memory("life_choice", "%s rechazó una oportunidad y mantuvo su camino." % person.name, 0.6)
		return decision
	return {}

func _offense_name(tags: Array) -> String:
	if "theft" in tags:
		return "robo"
	if "assault" in tags:
		return "agresion"
	return "delito"

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
