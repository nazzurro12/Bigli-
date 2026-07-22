extends RefCounted
class_name DFDialogue

var world_ref = null
var main_ref = null
var target_entity = null
var target_type: String = ""  # "dwarf" or "creature"

var active_topic: String = ""
var response_text: String = ""

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

var topic_selected: int = 0

enum DialogueState {
	CLOSED,
	TOPIC_SELECT,
	SHOW_RESPONSE
}

var state: int = DialogueState.CLOSED

var topics: Array = []

func _init(world, main_node):
	world_ref = world
	main_ref = main_node
	topics = []
	state = DialogueState.CLOSED

func start_dialogue(entity) -> void:
	target_entity = entity
	if entity.get("creature_type") == "dwarf":
		target_type = "dwarf"
	else:
		target_type = "creature"
	topics = [
		{"id": "peligros", "label": "PELIGROS", "icon": "⚔"},
		{"id": "historia", "label": "HISTORIA", "icon": "📜"},
		{"id": "personas", "label": "PERSONAS", "icon": "👥"},
	]
	if entity.has_meta("historical_figure_id"):
		topics.append({"id": "hazanas", "label": "MIS HAZAÑAS", "icon": "🏆"})
	if main_ref != null and main_ref.possessed_dwarf != null and entity != main_ref.possessed_dwarf and target_type == "dwarf":
		if entity.has_meta("is_follower") and entity.get_meta("is_follower") == true:
			topics.append({"id": "despedir", "label": "DESPEDIR ACOMPAÑANTE", "icon": "🚪"})
		else:
			topics.append({"id": "reclutar", "label": "RECLUTAR ACOMPAÑANTE", "icon": "🤝"})
	topic_selected = 0
	state = DialogueState.TOPIC_SELECT
	active_topic = ""

func close_dialogue() -> void:
	state = DialogueState.CLOSED
	target_entity = null
	active_topic = ""
	response_text = ""

func is_active() -> bool:
	return state != DialogueState.CLOSED

func select_topic(index: int) -> void:
	if index < 0 or index >= topics.size():
		return
	var topic = topics[index]
	active_topic = topic["id"]
	response_text = _generate_response(active_topic)
	state = DialogueState.SHOW_RESPONSE

func previous_topic() -> void:
	topic_selected = posmod(topic_selected - 1, topics.size())

func next_topic() -> void:
	topic_selected = posmod(topic_selected + 1, topics.size())

func back_to_topics() -> void:
	state = DialogueState.TOPIC_SELECT
	active_topic = ""
	response_text = ""

func get_greeting() -> String:
	if target_entity == null:
		return "..."
	var name = _safe_get(target_entity, "name", "Alguien")
	if target_type == "dwarf":
		var moods = [
			"Saludos, %s. ¿En qué puedo ayudarte?" % name,
			"¡Hola, %s! Un placer verte." % name,
			"%s aquí. Dime qué necesitas." % name,
			"Oh, %s. Pasa, pasa. ¿Qué te trae?" % name,
			"¡Eh, %s! ¿Todo bien?" % name,
		]
		var mood_idx = abs(target_entity.id) % moods.size()
		return moods[mood_idx]
	else:
		var greetings = [
			"%s te observa con curiosidad." % name,
			"%s inclina la cabeza, expectante." % name,
			"%s emite un sonido suave." % name,
		]
		return greetings[abs(target_entity.id) % greetings.size()]

func _generate_response(topic_id: String) -> String:
	match topic_id:
		"peligros":
			return _generate_dangers_response()
		"historia":
			return _generate_history_response()
		"personas":
			return _generate_people_response()
		"hazanas":
			return _generate_hazanas_response()
		"reclutar":
			if target_entity != null:
				target_entity.set_meta("is_follower", true)
				target_entity.set_meta("follower_target_id", main_ref.possessed_dwarf.id)
			return "¡Sería un honor unirme a tu viaje! Te seguiré y lucharemos juntos."
		"despedir":
			if target_entity != null:
				target_entity.remove_meta("is_follower")
				target_entity.remove_meta("follower_target_id")
			return "De acuerdo, me quedaré aquí. ¡Que los ancestros te guíen!"
	return "No sé nada sobre eso."

func _generate_dangers_response() -> String:
	var text = ""
	var name = _safe_get(target_entity, "name", "Alguien") if target_entity != null else "Alguien"
	
	# Check invasion status
	if main_ref != null and main_ref.get("world") != null:
		var w = main_ref.world
		if w.invasion_system != null:
			var inv_status = w.invasion_system.get_invasion_status()
			if inv_status.get("active", false):
				text += "¡Peligro inminente! %s ataca la fortaleza.\n" % inv_status.get("name", "Una fuerza hostil")
				text += "Hay %d/%d enemigos en el área.\n" % [inv_status.get("spawned", 0), inv_status.get("force", 0)]
				text += "Nos superan en número. ¡Prepárate para defenderte!\n"
		
		# Check for hostile creatures nearby
		var nearby_hostiles = []
		for e in w.entities:
			if e == target_entity: continue
			if e.get("is_hostile") == true and e.get("is_alive") == true:
				var dist = abs(e.tile_pos.x - target_entity.tile_pos.x) + abs(e.tile_pos.z - target_entity.tile_pos.z)
				if dist < 15:
					nearby_hostiles.append({"name": _safe_get(e, "name", "Algo"), "dist": dist})
		
		if not nearby_hostiles.is_empty():
			if text != "":
				text += "\n"
			text += "Además, hay criaturas hostiles cerca:\n"
			for h in nearby_hostiles.slice(0, 3):
				text += "  - %s a %d pasos\n" % [h["name"], h["dist"]]
			if nearby_hostiles.size() > 3:
				text += "  ...y %d más acechando.\n" % (nearby_hostiles.size() - 3)
		elif text == "":
			text += "Por ahora, todo está tranquilo. No hay amenazas inmediatas.\n"
			text += "Pero nunca bajamos la guardia. La vigilancia es nuestro escudo.\n"
	
	if text == "":
		text = "No detecto peligros cercanos. Mantente alerta de todas formas."
	
	# Weather danger
	if main_ref != null and main_ref.get("world") != null:
		var w_163 = main_ref.world
		if w_163.get("current_season") != null:
			var season = w_163.current_season
			if season == 3:  # Winter
				text += "\nEl invierno es traicionero. El frío puede matar como cualquier espada."
	return text

func _generate_history_response() -> String:
	var text = ""
	var name = _safe_get(target_entity, "name", "Alguien") if target_entity != null else "Alguien"
	
	if target_type == "dwarf":
		text = "%s reflexiona un momento y dice:\n" % name
	
	# World name meaning from lore
	if main_ref != null and main_ref.get("lore") != null:
		var lore = main_ref.lore
		text += "\"Te contaré la historia de este mundo...\"\n\n"
		text += lore.get_creation_myth().substr(0, 400) + "\n"
		text += "...\n"
		text += "\"Eso es lo que recuerdo. La piedra guarda estas memorias.\"\n"
	else:
		# Fallback: mention recent events
		if main_ref != null and not main_ref._chronicle_events_game.is_empty():
			text += "\"Han ocurrido cosas importantes...\"\n"
			for evt in main_ref._chronicle_events_game.slice(-3):
				text += "  - %s\n" % evt
		else:
			text += "\"La historia de %s está siendo escrita.\"" % name
	
	# Inspirational thought
	if main_ref != null and main_ref.get("lore") != null:
		text += "\n\n%s reflexiona: \"%s\"" % [name, main_ref.lore.get_inspirational_thought()]
	
	return text

func _generate_people_response() -> String:
	var text = ""
	var name = _safe_get(target_entity, "name", "Alguien") if target_entity != null else "Alguien"
	
	if target_type == "dwarf":
		text = "== %s ==\n" % name
		var dwarf = target_entity
		
		# Role / task
		var task = _safe_get(dwarf, "current_task", "sin tarea")
		text += "Ahora mismo: %s\n" % task
		
		# Skills
		if dwarf.has_method("get_name_and_skill"):
			var skill_info = dwarf.get_name_and_skill()
			text += "Habilidades: %s\n" % skill_info
		elif dwarf.get("skills") != null:
			var best_skill = ""
			var best_val = 0
			for sk in dwarf.skills:
				var val = dwarf.skills[sk]
				if val > best_val:
					best_val = val
					best_skill = sk
			if best_skill != "":
				text += "Mejor habilidad: %s (nivel %d)\n" % [best_skill, best_val]
		
		# Health
		if dwarf.get("health") != null:
			var hp_pct = dwarf.health * 100
			var hp_desc = "saludable" if hp_pct > 80 else "herido" if hp_pct > 40 else "grave"
			text += "Estado: %s (%d%%)\n" % [hp_desc, hp_pct]
		
		# Needs
		if dwarf.get("hunger") != null:
			var hunger_pct = dwarf.hunger * 100
			text += "Hambre: %d%% | Sed: %d%% | Fatiga: %d%%\n" % [
				hunger_pct, dwarf.thirst * 100, dwarf.fatigue * 100
			]
		
		# Mood / thought
		if dwarf.get("thoughts") != null and not dwarf.thoughts.is_empty():
			text += "\"Último pensamiento: %s\"" % dwarf.thoughts[dwarf.thoughts.size() - 1]
	else:
		# Creature info
		text = "== %s ==\n" % name
		var cr = target_entity
		text += "Tipo: %s\n" % _safe_get(cr, "creature_type", "?")
		text += "Tamaño: %s\n" % _safe_get(cr, "size_label", "mediano")
		if cr.get("is_hostile") == true:
			text += "¡Cuidado! Es hostil.\n"
		elif _safe_get(cr, "fear_level", 0) > 0.3:
			text += "Parece asustado. Acércate con cuidado.\n"
		else:
			text += "Parece tranquilo.\n"
		
		# Lore about this creature type
		if main_ref != null and main_ref.get("lore") != null:
			var ctype = _safe_get(cr, "creature_type", "")
			var lore = main_ref.lore.get_bestiary_lore(ctype.capitalize())
			if lore.get("lore", "") != "" and lore["lore"] != "No hay registro de esta criatura.":
				text += "\nLeyenda: %s\n" % lore["lore"]
				text += "Significado: %s" % lore.get("significado", "desconocido")
	
	return text

func _generate_hazanas_response() -> String:
	if target_entity == null or not target_entity.has_meta("historical_figure_id"):
		return "No tengo hazañas que contar."
	var hf_id = target_entity.get_meta("historical_figure_id")
	if main_ref == null or main_ref.history_gen == null:
		return "La historia no me recuerda..."
	var hf = main_ref.history_gen._get_hf(hf_id)
	if hf == null:
		return "Mi nombre se perdió en el tiempo..."
	
	var name = hf.name
	var text = "== HAZAÑAS DE %s ==\n\n" % name.to_upper()
	
	if not hf.notable_deeds.is_empty():
		text += "Se me conoce por los siguientes acontecimientos:\n"
		for deed in hf.notable_deeds:
			text += "  ► %s.\n" % deed
	else:
		text += "He vivido tiempos de lucha y supervivencia.\n"
		
	text += "\nEstadísticas de batalla:\n"
	text += "  - Victorias en batalla: %d\n" % hf.battles_won
	text += "  - Derrotas en batalla: %d\n" % hf.battles_lost
	text += "  - Kills históricos: %d\n" % hf.kills
	
	# Si creó algún artefacto, mencionarlo
	var artifacts_made = []
	for art in main_ref.history_gen.artifact_instances:
		if art.get("creator_name") == hf.name:
			artifacts_made.append(art["name"])
	if not artifacts_made.is_empty():
		text += "\nSoy el forjador de reliquias legendarias:\n"
		for a_name in artifacts_made:
			text += "  - %s\n" % a_name
			
	return text
