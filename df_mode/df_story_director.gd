extends RefCounted
class_name DFStoryDirector

## Convierte estados reales de la simulación en historias legibles.
## No inventa sucesos: selecciona la presión más interesante que ya existe.

const REFRESH_MINUTES: int = 30
const TRAIT_FEAR: int = 11
const TRAIT_HONESTY: int = 12

var active_hook: Dictionary = {}
var last_refresh_minute: int = -REFRESH_MINUTES
var possession_session: Dictionary = {}
var last_consequence_report: Dictionary = {}
var active_campaign: Dictionary = {}
var completed_campaigns: Array = []
var campaign_serial: int = 0

func refresh(world, minute: int, force: bool = false) -> Dictionary:
	if world == null:
		active_hook = {}
		return active_hook
	if not force and minute - last_refresh_minute < REFRESH_MINUTES:
		return active_hook
	last_refresh_minute = minute
	_refresh_campaign(world, minute)
	active_hook = _find_best_hook(world)
	if not active_campaign.is_empty():
		active_hook["campaign"] = active_campaign.duplicate(true)
	return active_hook

func _refresh_campaign(world, minute: int) -> void:
	var metrics := _campaign_metrics(world)
	if active_campaign.is_empty():
		active_campaign = _create_campaign(metrics, minute)
		return
	var objective: Dictionary = active_campaign.get("objective", {})
	var metric_name: String = str(objective.get("metric", "population"))
	var progress: int = int(metrics.get(metric_name, 0))
	active_campaign["progress"] = progress
	if progress < int(objective.get("target", 1)):
		return
	var chapter: int = int(active_campaign.get("chapter", 0)) + 1
	active_campaign["chapter"] = chapter
	if chapter >= 5:
		active_campaign["completed_minute"] = minute
		completed_campaigns.append(active_campaign.duplicate(true))
		if completed_campaigns.size() > 40:
			completed_campaigns.pop_front()
		active_campaign = {}
		return
	active_campaign["objective"] = _campaign_objective(active_campaign.get("theme", "prosperity"), chapter, metrics)
	active_campaign["progress"] = int(metrics.get(active_campaign.objective.metric, 0))

func _create_campaign(metrics: Dictionary, minute: int) -> Dictionary:
	campaign_serial += 1
	var themes: Array[String] = ["refugio", "prosperidad", "industria", "exploracion", "legado", "comunidad"]
	var theme: String = themes[posmod(campaign_serial + int(metrics.get("population", 0)), themes.size())]
	return {
		"id": campaign_serial,
		"title": _campaign_title(theme, campaign_serial),
		"theme": theme,
		"chapter": 0,
		"started_minute": minute,
		"objective": _campaign_objective(theme, 0, metrics),
		"progress": 0,
	}

func _campaign_title(theme: String, serial: int) -> String:
	var names := {
		"refugio": "Hogares bajo las estrellas",
		"prosperidad": "La despensa de las estaciones",
		"industria": "Manos que transforman el mundo",
		"exploracion": "Más allá del horizonte",
		"legado": "Una obra para la memoria",
		"comunidad": "Vidas entrelazadas",
	}
	return "%s · Ciclo %d" % [str(names.get(theme, "Crónica de la colonia")), serial]

func _campaign_objective(theme: String, chapter: int, metrics: Dictionary) -> Dictionary:
	var chains := {
		"refugio": ["beds", "floors", "buildings", "beds", "population"],
		"prosperidad": ["food", "water", "food", "containers", "population"],
		"industria": ["workshops", "wood", "stone", "metal", "workshops"],
		"exploracion": ["stone", "metal", "workshops", "buildings", "population"],
		"legado": ["buildings", "floors", "workshops", "beds", "population"],
		"comunidad": ["beds", "food", "buildings", "containers", "population"],
	}
	var labels := {
		"beds": "Instalar camas utilizables",
		"floors": "Construir espacios habitables",
		"buildings": "Completar edificios",
		"food": "Asegurar reservas de comida",
		"water": "Asegurar reservas de bebida",
		"containers": "Instalar almacenamiento",
		"workshops": "Levantar talleres productivos",
		"wood": "Reunir madera",
		"stone": "Extraer piedra",
		"metal": "Descubrir y almacenar metal",
		"population": "Sostener una comunidad mayor",
	}
	var chain: Array = chains.get(theme, chains["comunidad"])
	var metric: String = str(chain[clampi(chapter, 0, chain.size() - 1)])
	var baseline: int = int(metrics.get(metric, 0))
	var increase: int = maxi(1, 2 + chapter * 2)
	return {"metric": metric, "label": labels.get(metric, metric), "baseline": baseline, "target": baseline + increase}

func _campaign_metrics(world) -> Dictionary:
	var result := {"population": 0, "beds": 0, "floors": 0, "buildings": 0, "food": 0, "water": 0, "containers": 0, "workshops": 0, "wood": 0, "stone": 0, "metal": 0}
	for dwarf in world.dwarves:
		if dwarf.get("is_alive") != false:
			result.population += 1
	result.buildings = world.buildings.size()
	result.workshops = world.workshops.size()
	for building in world.buildings:
		var type_name: String = str(building.get("name")).to_lower()
		if "almac" in type_name or "cofre" in type_name:
			result.containers += 1
	for item in world.items:
		var item_name: String = str(item.get("name")).to_lower()
		var item_type: String = str(item.get("item_type")).to_lower()
		if item.get("is_bed") == true or "cama" in item_name: result.beds += 1
		if item_type in ["food", "meat", "plant", "meal"]: result.food += 1
		if item_type in ["water", "drink", "beer"]: result.water += 1
		if item_type in ["wood", "plank"]: result.wood += 1
		if item_type == "stone": result.stone += 1
		if "ore" in item_type or item_type in ["bar", "metal"]: result.metal += 1
	for tile_data in world.tile_data.values():
		if tile_data is Dictionary and bool(tile_data.get("constructed_floor", false)):
			result.floors += 1
	return result

func serialize_state() -> Dictionary:
	return {"active_campaign": active_campaign.duplicate(true), "completed_campaigns": completed_campaigns.duplicate(true), "campaign_serial": campaign_serial}

func deserialize_state(data: Dictionary) -> void:
	active_campaign = data.get("active_campaign", {}).duplicate(true)
	completed_campaigns = data.get("completed_campaigns", []).duplicate(true)
	campaign_serial = int(data.get("campaign_serial", 0))

func _find_best_hook(world) -> Dictionary:
	var best: Dictionary = {}
	var best_score: float = -1.0
	for actor_value: Variant in world.dwarves:
		if not (actor_value is Object):
			continue
		var actor: Object = actor_value
		if actor.get("is_alive") == false:
			continue
		var candidate := _build_hook(actor)
		var score: float = float(candidate.get("score", 0.0))
		if score > best_score:
			best_score = score
			best = candidate
	return best

func _build_hook(actor: Object) -> Dictionary:
	var actor_name: String = str(actor.get("name"))
	var hunger: float = _number(actor.get("hunger"))
	var thirst: float = _number(actor.get("thirst"))
	var stress: float = _number(actor.get("stress"))
	var health: float = _number(actor.get("health"), 1.0)
	var happiness: float = _number(actor.get("happiness"), 0.5)
	var current_task: String = str(actor.get("current_task"))
	var rivals: Array = actor.get("rivals") if actor.get("rivals") is Array else []
	var family: Dictionary = actor.get("family") if actor.get("family") is Dictionary else {}
	var autonomous_goal: String = str(actor.get("autonomous_goal"))
	var autonomous_reason: String = str(actor.get("autonomous_reason"))

	var score: float = hunger * 32.0 + thirst * 36.0 + stress * 28.0
	score += (1.0 - health) * 35.0 + (1.0 - happiness) * 12.0
	score += mini(rivals.size(), 3) * 6.0
	if not autonomous_goal.is_empty():
		score += 9.0

	var problem := "Su vida parece estable, pero busca un propósito propio."
	var stakes := "Sin intervención continuará siguiendo su rutina."
	var objective := "Intervén en su rutina y deja una consecuencia observable."
	var objective_type := "act"
	if thirst >= 0.65:
		problem = "Tiene sed y todavía no ha asegurado agua."
		stakes = "Su salud y su capacidad de trabajar empeorarán."
		objective = "Consigue una bebida y pulsa E para beber."
		objective_type = "drink"
	elif hunger >= 0.65:
		problem = "Tiene hambre y no sabe cuándo conseguirá su próxima comida."
		stakes = "Podría abandonar sus obligaciones para sobrevivir."
		objective = "Consigue alimento y pulsa E para comer."
		objective_type = "eat"
	elif health <= 0.70:
		problem = "Su salud está deteriorada y necesita recuperarse."
		stakes = "Una jornada exigente puede prolongar su recuperación."
		objective = "Evita esfuerzos y busca recursos útiles."
		objective_type = "act"
	elif stress >= 0.65:
		problem = "La presión acumulada está alterando sus decisiones."
		stakes = "Sus relaciones y su trabajo pueden deteriorarse."
		objective = "Cambia su rutina sin empeorar sus necesidades."
		objective_type = "act"
	elif not rivals.is_empty():
		problem = "Mantiene un conflicto sin resolver con otro habitante."
		stakes = "La rivalidad puede dividir a sus conocidos."
		objective = "Acércate a otras personas y decide dónde intervenir."
		objective_type = "act"
	elif current_task != "idle" and not current_task.is_empty():
		problem = "Está dedicando su día a: %s." % current_task
		stakes = "El resultado afectará los recursos y planes de la colonia."

	var desire := autonomous_goal
	if desire.is_empty():
		if thirst >= hunger and thirst >= 0.45:
			desire = "Conseguir agua y recuperar la seguridad."
		elif hunger >= 0.45:
			desire = "Encontrar alimento sin fallar a sus obligaciones."
		elif stress >= 0.45:
			desire = "Recuperar el control de su vida."
		elif family.get("children", []) is Array and not family.get("children", []).is_empty():
			desire = "Proteger el futuro de su familia."
		else:
			desire = "Ser útil y ganarse un lugar en la comunidad."
	if not autonomous_reason.is_empty() and autonomous_goal.is_empty():
		desire = autonomous_reason

	return {
		"actor_id": int(actor.get("id")),
		"actor_name": actor_name,
		"title": "La vida de %s" % actor_name,
		"desire": desire,
		"problem": problem,
		"stakes": stakes,
		"objective": objective,
		"objective_type": objective_type,
		"score": score,
	}

func begin_possession(actor: Object, minute: int) -> Dictionary:
	possession_session = _snapshot(actor, minute)
	possession_session["actions"] = []
	last_consequence_report = {}
	return possession_session

func record_action(action_type: String, message: String, minute: int, target: Vector3i) -> void:
	if possession_session.is_empty():
		return
	var actions: Array = possession_session.get("actions", [])
	actions.append({
		"type": action_type,
		"message": message,
		"minute": minute,
		"target": target,
	})
	if actions.size() > 24:
		actions.pop_front()
	possession_session["actions"] = actions

func end_possession(actor: Object, minute: int) -> Dictionary:
	if possession_session.is_empty() or int(possession_session.get("actor_id", -1)) != int(actor.get("id")):
		return {}
	var after := _snapshot(actor, minute)
	var duration: int = maxi(0, minute - int(possession_session.get("minute", minute)))
	var start_position: Vector3i = possession_session.get("position", actor.get("tile_pos"))
	var end_position: Vector3i = after.get("position", start_position)
	var distance: int = abs(end_position.x - start_position.x) + abs(end_position.z - start_position.z)
	var inventory_delta: int = int(after.get("inventory_count", 0)) - int(possession_session.get("inventory_count", 0))
	var relationship_changes: int = _count_relationship_changes(possession_session.get("relationships", {}), after.get("relationships", {}))
	var need_change: float = (
		float(possession_session.get("hunger", 0.0)) + float(possession_session.get("thirst", 0.0))
		- float(after.get("hunger", 0.0)) - float(after.get("thirst", 0.0))
	)
	var interpretation := _interpret_possession(actor, distance, inventory_delta, relationship_changes)
	var recorded_actions: Array = possession_session.get("actions", [])
	var objective_type: String = str(active_hook.get("objective_type", "act"))
	var objective_resolved: bool = _objective_was_resolved(objective_type, recorded_actions, need_change)
	var consequences: Array[String] = []
	for action_value: Variant in recorded_actions.slice(-3):
		if action_value is Dictionary:
			consequences.append(str(action_value.get("message", "Realizó una acción.")))
	if distance > 0:
		consequences.append("Recorrió %d casillas bajo tu control." % distance)
	if inventory_delta > 0:
		consequences.append("Terminó con %d objeto(s) adicional(es)." % inventory_delta)
	elif inventory_delta < 0:
		consequences.append("Terminó con %d objeto(s) menos." % abs(inventory_delta))
	if relationship_changes > 0:
		consequences.append("%d relación(es) cambiaron." % relationship_changes)
	if need_change > 0.15:
		consequences.append("Sus necesidades inmediatas mejoraron.")
	elif need_change < -0.15:
		consequences.append("Sus necesidades inmediatas empeoraron.")
	if consequences.is_empty():
		consequences.append("El mundo no registró todavía una consecuencia material.")

	last_consequence_report = {
		"actor_id": int(actor.get("id")),
		"actor_name": str(actor.get("name")),
		"minute": minute,
		"duration": duration,
		"interpretation": interpretation,
		"consequences": consequences,
		"actions_count": recorded_actions.size(),
		"objective_resolved": objective_resolved,
	}
	if actor.has_method("add_memory"):
		actor.call("add_memory", "possession", interpretation, 0.65)
	possession_session = {}
	return last_consequence_report

func _objective_was_resolved(objective_type: String, actions: Array, need_change: float) -> bool:
	for action_value: Variant in actions:
		if not (action_value is Dictionary):
			continue
		var action_type: String = str(action_value.get("type", ""))
		if objective_type == "drink" and action_type == "drink":
			return true
		if objective_type == "eat" and action_type == "eat":
			return true
	if objective_type == "act":
		return not actions.is_empty()
	return need_change > 0.15

func _snapshot(actor: Object, minute: int) -> Dictionary:
	var inventory_value: Variant = actor.get("inventory")
	var relationships_value: Variant = actor.get("relationships")
	return {
		"actor_id": int(actor.get("id")),
		"minute": minute,
		"position": actor.get("tile_pos"),
		"inventory_count": inventory_value.size() if inventory_value is Array else 0,
		"relationships": relationships_value.duplicate(true) if relationships_value is Dictionary else {},
		"hunger": _number(actor.get("hunger")),
		"thirst": _number(actor.get("thirst")),
	}

func _count_relationship_changes(before: Dictionary, after: Dictionary) -> int:
	var changed: int = 0
	var ids: Dictionary = {}
	for relation_id: Variant in before:
		ids[relation_id] = true
	for relation_id: Variant in after:
		ids[relation_id] = true
	for relation_id: Variant in ids:
		if absf(float(before.get(relation_id, 0.0)) - float(after.get(relation_id, 0.0))) >= 0.05:
			changed += 1
	return changed

func _interpret_possession(actor: Object, distance: int, inventory_delta: int, relationship_changes: int) -> String:
	var honesty: float = actor.get_trait(TRAIT_HONESTY) if actor.has_method("get_trait") else 0.5
	var fear: float = actor.get_trait(TRAIT_FEAR) if actor.has_method("get_trait") else 0.5
	var disruption: int = distance + abs(inventory_delta) * 4 + relationship_changes * 6
	if disruption <= 1:
		return "Sintió una breve ausencia, pero cree que nada importante cambió."
	if honesty >= 0.70:
		return "Recuerda acciones que no decidió y piensa contárselo a alguien de confianza."
	if fear >= 0.70:
		return "No comprende lo ocurrido y teme volver a perder el control."
	return "Intenta explicar sus acciones como propias, aunque algunos recuerdos no encajan."

func _number(value: Variant, fallback: float = 0.0) -> float:
	return fallback if value == null else float(value)
