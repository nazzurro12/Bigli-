extends RefCounted
class_name DFCorpse

## DFCorpse — Representa el cadáver de un enano (o criatura) en el mundo.
##
## Cada vez que un enano/criatura muere, su cuerpo se convierte en un DFCorpse
## que se pudre con el tiempo. Si no se entierra, genera miasma, enfermedades,
## y eventualmente un fantasma que atormenta a los vivos.

enum CorpseState {
	FRESH,       # Recién muerto, se puede comer (para carnívoros)
	STALE,       # Comienza a oler, ya no es comestible
	DECAYING,    # Podrido, miasma, riesgo de infección
	SKELETON,    # Solo huesos, miasma disminuye
	DUST         # Se desintegró, desaparece
}

enum BurialState {
	UNBURIED,        # En el suelo, a la vista
	BURIED,          # Enterrado en una tumba/cementerio
	MEMORIALIZED     # Se erigió una placa/epitafio, el fantasma descansa
}

enum FuneralState {
	NONE,            # Sin funeral iniciado
	GATHERING,       # Asistentes estan reuniendose alrededor del cadaver
	MOURNING,        # Periodo de duelo activo
	COMPLETED        # Funeral terminado, listo para entierro
}

static var _id_counter: int = 8000

# ---- IDENTIDAD ----
var id: int
var dwarf_name: String = "Unnamed"
var dwarf_profession: String = "Ciudadano"
var dwarf_id: int = -1           # ID del enano original (para reliquias/herencia)
var gender: String = "???"
var age_at_death: int = 0
var cause_of_death: String = "Desconocida"
var death_year: int = 63
var death_day: int = 1
var death_hour: int = 6

# ---- POSICIÓN ----
var tile_pos: Vector3i

# ---- ESTADO ----
var state: int = CorpseState.FRESH
var burial_state: int = BurialState.UNBURIED
var decay_timer: float = 0.0
var decay_thresholds: Dictionary = {
	CorpseState.STALE: 120.0,      # 2 horas de juego -> comienza a oler
	CorpseState.DECAYING: 300.0,    # 5 horas -> podrido, miasma maxima
	CorpseState.SKELETON: 720.0,    # 12 horas -> solo huesos
	CorpseState.DUST: 1440.0        # 24 horas -> desaparece
}

# ---- ITEMS ----
# Los items que el enano llevaba al morir. Se dropean alrededor del cadaver
# si no se recogen, pero quedan registrados aqui para herencia.
var carried_items: Array = []       # IDs de items que llevaba
var dropped_items_at: Array = []    # IDs de items ya dropeados en el suelo

# ---- MIASMA ----
var miasma_intensity: float = 0.0   # 0.0 = nada, 1.0 = maximo
var miasma_radius: int = 2          # Tiles alrededor afectados por el olor

# ---- FANTASMA ----
var ghost_spawn_timer: float = 0.0
var ghost_spawn_threshold: float = 720.0  # 12 horas sin entierro -> fantasma
var ghost_summoned: bool = false
var ghost_id: int = -1

# ---- SEPELIO / TUMBA ----
var grave_pos: Vector3i = Vector3i(-1, -1, -1)
var buried_at_tick: int = -1
var memorial_slab_id: int = -1# ---- FUNERAL ----
var funeral_state: int = FuneralState.NONE
var funeral_participant_ids: Array = []
var funeral_timer: float = 0.0
var funeral_start_tick: int = -1
var funeral_mourning_duration: float = 45.0  # 45 minutos de juego de duelo
var funeral_gathering_duration: float = 15.0 # 15 min para reunirse
var funeral_completed: bool = false

# ---- HISTORIA ----
var life_summary: String = ""
var epitaph: String = ""
var known_skills: Dictionary = {}

# ---- EPIDEMIOLOGÍA ----
var has_disease: bool = false
var disease_name: String = ""
var disease_contagious: bool = false

func _init(pos: Vector3i, dwarf_ref = null, cause: String = "Desconocida"):
	tile_pos = pos
	id = _id_counter
	_id_counter += 1
	cause_of_death = cause

	if dwarf_ref != null:
		dwarf_name = dwarf_ref.name
		dwarf_id = dwarf_ref.id
		gender = dwarf_ref.gender
		age_at_death = dwarf_ref.age
		# Copiar datos del enano
		if dwarf_ref.has_method("get_description"):
			dwarf_profession = dwarf_ref.get_description()
		# Skills conocidos
		if dwarf_ref.has("skills") and dwarf_ref.skills is Dictionary:
			known_skills = dwarf_ref.skills.duplicate()
		# Personalidad
		if dwarf_ref.has("personality") and dwarf_ref.personality is Dictionary:
			life_summary = _generate_life_summary(dwarf_ref)
		# Items en inventario
		if dwarf_ref.has("inventory") and dwarf_ref.inventory is Array:
			for item in dwarf_ref.inventory:
				carried_items.append(item.id if item.has("id") else -1)

	# Registrar muerte en el mundo
	var hour_str: String = "%02d:%02d" % [6, 0]
	if Engine.get_main_loop() and Engine.get_main_loop().has_method("get_game_time"):
		var gt = Engine.get_main_loop().get_game_time()
		if gt is Dictionary:
			death_hour = gt.get("hour", 6)
			death_day = gt.get("day", 1)
			death_year = gt.get("year", 63)

func _generate_life_summary(dwarf) -> String:
	# Genera un resumen de la vida del enano basado en sus estadisticas
	var parts: Array = []
	if dwarf.has("stats_tracker") and dwarf.stats_tracker is Dictionary:
		var st = dwarf.stats_tracker
		if st.get("kills", 0) > 0:
			parts.append("mató a %d criaturas" % st["kills"])
		if st.get("items_crafted", 0) > 5:
			parts.append("creó %d objetos" % st["items_crafted"])
		if st.get("trees_cut", 0) > 5:
			parts.append("taló %d árboles" % st["trees_cut"])
		if st.get("ore_mined", 0) > 5:
			parts.append("extrajo %d menas" % st["ore_mined"])
		if st.get("battles_fought", 0) > 0:
			parts.append("luchó en %d batallas" % st["battles_fought"])
	if parts.is_empty():
		parts.append("vivió una vida tranquila")
	return dwarf_name + " " + ", ".join(parts) + "."

func tick_decay(delta_minutes: float) -> Dictionary:
	## Procesa la pudrición del cadáver.
	## Retorna un Dictionary con eventos ocurridos este tick.
	var events: Dictionary = {
		"miasma_changed": false,
		"state_changed": false,
		"ghost_spawned": false,
		"decayed_away": false
	}

	if burial_state != BurialState.UNBURIED:
		# Enterrado -> no se pudre
		state = CorpseState.SKELETON
		miasma_intensity = 0.0
		return events

	decay_timer += delta_minutes
	var old_state = state

	# Determinar estado segun el timer
	if decay_timer >= decay_thresholds[CorpseState.DUST]:
		state = CorpseState.DUST
		miasma_intensity = 0.0
		events["decayed_away"] = true
	elif decay_timer >= decay_thresholds[CorpseState.SKELETON]:
		state = CorpseState.SKELETON
		miasma_intensity = 0.2
	elif decay_timer >= decay_thresholds[CorpseState.DECAYING]:
		state = CorpseState.DECAYING
		miasma_intensity = 0.8 + sin(decay_timer * 0.1) * 0.2
	elif decay_timer >= decay_thresholds[CorpseState.STALE]:
		state = CorpseState.STALE
		miasma_intensity = 0.3
	else:
		state = CorpseState.FRESH
		miasma_intensity = 0.0

	if state != old_state:
		events["state_changed"] = true
		events["miasma_changed"] = true

	# Control de fantasma si no se entierra
	if burial_state == BurialState.UNBURIED and not ghost_summoned:
		ghost_spawn_timer += delta_minutes
		if ghost_spawn_timer >= ghost_spawn_threshold:
			events["ghost_spawned"] = true

	return events

func get_display_char() -> String:
	match state:
		CorpseState.FRESH:
			return "%"
		CorpseState.STALE:
			return "&"
		CorpseState.DECAYING:
			return "¥"
		CorpseState.SKELETON:
			return "♰"
		CorpseState.DUST:
			return "·"
	return "%"

func get_display_color() -> Color:
	match state:
		CorpseState.FRESH:
			return Color("#884422")
		CorpseState.STALE:
			return Color("#664422")
		CorpseState.DECAYING:
			return Color("#445522")
		CorpseState.SKELETON:
			return Color("#CCCCBB")
		CorpseState.DUST:
			return Color("#666666")
	return Color("#884422")

func get_state_name() -> String:
	match state:
		CorpseState.FRESH: return "Fresco"
		CorpseState.STALE: return "Oloroso"
		CorpseState.DECAYING: return "Podrido"
		CorpseState.SKELETON: return "Esqueleto"
		CorpseState.DUST: return "Polvo"
	return "Desconocido"

func get_burial_name() -> String:
	match burial_state:
		BurialState.UNBURIED: return "Sin enterrar"
		BurialState.BURIED: return "Enterrado"
		BurialState.MEMORIALIZED: return "Memorializado"
	return "Desconocido"

func get_full_description() -> String:
	var desc: String = "Cadáver de %s\n" % dwarf_name
	desc += "Profesión: %s\n" % dwarf_profession
	desc += "Edad: %d\n" % age_at_death
	desc += "Causa de muerte: %s\n" % cause_of_death
	desc += "Estado: %s\n" % get_state_name()
	desc += "Sepelio: %s\n" % get_burial_name()
	desc += "Descomposición: %.0f%%\n" % ((decay_timer / decay_thresholds[CorpseState.DUST]) * 100)
	if state >= CorpseState.DECAYING:
		desc += "¡MIASMA! (Intensidad: %.0f%%)\n" % (miasma_intensity * 100)
	if ghost_summoned:
		desc += "¡FANTASMA ACTIVO!\n"
	return desc

func is_edible() -> bool:
	return state == CorpseState.FRESH

func is_rotten() -> bool:
	return state >= CorpseState.DECAYING

func is_skeleton() -> bool:
	return state >= CorpseState.SKELETON

func has_miasma() -> bool:
	return miasma_intensity > 0.1

func _generate_epitaph_from_life(dwarf_ref) -> void:
	"""Genera un epitafio personalizado basado en la personalidad, habilidades y vida del enano."""
	var traits_desc: String = ""
	var skills_desc: String = ""
	var stat_desc: String = ""
	
	# Personalidad
	if dwarf_ref.has("personality") and dwarf_ref.personality is Dictionary:
		var p = dwarf_ref.personality
		var high_traits = []
		var trait_names = {
			0: "valiente", 1: "avaro", 2: "violento", 3: "trabajador",
			4: "vago", 5: "sociable", 6: "curioso", 7: "celoso",
			8: "compasivo", 9: "orgulloso", 10: "iracundo", 11: "miedoso",
			12: "honesto", 13: "cruel", 14: "indulgente", 15: "jugueton",
			16: "cortes", 17: "ambicioso", 18: "terco", 19: "paciente",
			20: "vanidoso"
		}
		for t_key in p:
			if p[t_key] > 0.7:
				var tname = trait_names.get(t_key, "")
				if not tname.is_empty():
					high_traits.append(tname)
		if not high_traits.is_empty():
			traits_desc = high_traits[0]
			if high_traits.size() > 1:
				traits_desc += " y " + high_traits[1]
	
	# Habilidades destacadas
	if dwarf_ref.has("skills") and dwarf_ref.skills is Dictionary:
		var best_skill = -1
		var best_val = -1
		var skill_names = [
			"mineria", "carpinteria", "albanileria", "herreria", "cocina",
			"cerveceria", "agricultura", "pesca", "tala", "grabado",
			"mecanica", "medicina", "organizacion", "tactica", "asedio",
			"comercio", "diplomacia", "liderazgo", "musica", "poesia",
			"danza", "escritura", "lectura", "alquimia", "anatomia"
		]
		for s_key in dwarf_ref.skills:
			if dwarf_ref.skills[s_key] > best_val:
				best_val = dwarf_ref.skills[s_key]
				best_skill = s_key
		if best_skill >= 0 and best_val >= 2:
			var sname = skill_names[best_skill] if best_skill < skill_names.size() else "artesania"
			skills_desc = sname
	
	# Estadisticas de vida
	if dwarf_ref.has("stats_tracker") and dwarf_ref.stats_tracker is Dictionary:
		var st = dwarf_ref.stats_tracker
		if st.get("kills", 0) >= 10:
			stat_desc = "asesino de %d" % st["kills"]
		elif st.get("items_crafted", 0) >= 20:
			stat_desc = "artifice de %d objetos" % st["items_crafted"]
		elif st.get("battles_fought", 0) >= 5:
			stat_desc = "veterano de %d batallas" % st["battles_fought"]
		elif st.get("distance_traveled", 0) >= 100:
			stat_desc = "viajero incansable"
	
	# Construir el epitafio
	var templates = []
	if not traits_desc.is_empty() and not skills_desc.is_empty():
		templates.append("Fue %s, maestro de la %s." % [traits_desc, skills_desc])
	elif not traits_desc.is_empty():
		templates.append("Fue %s. La montaña lo recordara." % [traits_desc.capitalize()])
	elif not skills_desc.is_empty():
		templates.append("Maestro de la %s. Su obra perdura." % [skills_desc])
	else:
		templates.append("Vivio entre el martillo y el yunque.")
	
	if not stat_desc.is_empty():
		templates.append("%s" % stat_desc.capitalize())
	else:
		templates.append("Que la tierra le sea leve.")
	
	# Anadir causa de muerte si es notable
	if cause_of_death != "Desconocida" and cause_of_death != "Vejez":
		if not traits_desc.is_empty():
			templates.append("Cayo %s." % cause_of_death)
	
	epitaph = dwarf_name + "\n" + "\n".join(templates)

func _get_base_epitaph() -> String:
	"""Epitafio generico de respaldo si no se pudo generar uno personalizado."""
	var epitaphs: Array = [
		"Aquí yace %s. Recordado por la piedra.",
		"%s: tallado en la memoria de la fortaleza.",
		"La tierra abraza a %s. Que la montaña lo guarde.",
		"%s partió al gran vacío. La fortaleza sigue.",
		"La muerte encontró a %s, pero su obra perdura.",
		"El eco de %s resuena en estos pasillos.",
		"%s: una vida entre el martillo y el yunque.",
		"Que el sueño eterno traiga paz a %s."
	]
	var base = epitaphs[randi() % epitaphs.size()]
	return base % dwarf_name

func get_epitaph_text() -> String:
	if not epitaph.is_empty():
		return epitaph
	return _get_base_epitaph()
