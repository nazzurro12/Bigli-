extends RefCounted
class_name DFLegends

enum ViewMode {
	OVERVIEW = 1,
	CHRONOLOGY = 2,
	CIVILIZATIONS = 3,
	FIGURES = 4,
	BEASTS = 5,
	ARTIFACTS = 6,
	SITES = 7,
	WARS = 8,
	FAMILIES = 9,
	FIGURE_DETAIL = 10,
}

var current_mode: int = ViewMode.OVERVIEW
var current_page: int = 0
var world_name: String = ""
var seed_val: int = 0

var world_gen: Object = null
var history_gen: Object = null

var items_per_page: int = 5
var total_pages: int = 1

var selected_figure_id: int = -1

func _init(p_seed_val: int, p_world_name: String) -> void:
	seed_val = p_seed_val
	world_name = p_world_name

func load_from_history(p_world_gen: Object, p_history_gen: Object) -> void:
	world_gen = p_world_gen
	history_gen = p_history_gen
	_calculate_pages()

func switch_mode(mode: int) -> void:
	if mode == ViewMode.FIGURE_DETAIL and selected_figure_id < 0:
		return
	current_mode = mode
	current_page = 0
	_calculate_pages()

func select_figure(hf_id: int) -> void:
	selected_figure_id = hf_id
	current_mode = ViewMode.FIGURE_DETAIL
	current_page = 0
	_calculate_pages()

func _calculate_pages() -> void:
	if history_gen == null:
		total_pages = 1
		return
	match current_mode:
		ViewMode.OVERVIEW:
			total_pages = 1
		ViewMode.CHRONOLOGY:
			var ev_count = history_gen.chronicle.events.size() if history_gen.chronicle != null else 0
			total_pages = max(1, int(ceil(float(ev_count) / 15.0)))
		ViewMode.CIVILIZATIONS:
			total_pages = max(1, int(ceil(float(history_gen.civs.size()) / 5.0)))
		ViewMode.FIGURES:
			var f_count = 0
			for hf in history_gen.historical_figures:
				if hf.race != "megabeast":
					f_count += 1
			total_pages = max(1, int(ceil(float(f_count) / 5.0)))
		ViewMode.BEASTS:
			var b_count = 0
			for hf_72 in history_gen.historical_figures:
				if hf_72.race == "megabeast":
					b_count += 1
			total_pages = max(1, int(ceil(float(b_count) / 3.0)))
		ViewMode.ARTIFACTS:
			total_pages = max(1, int(ceil(float(history_gen.artifacts.size()) / 5.0)))
		ViewMode.SITES:
			total_pages = max(1, int(ceil(float(history_gen.sites.size()) / 5.0)))
		ViewMode.WARS:
			total_pages = max(1, int(ceil(float(history_gen.active_wars.size()) / 5.0)))
		ViewMode.FAMILIES:
			var f_count_83 = history_gen.family_db.size() if history_gen != null else 0
			total_pages = max(1, int(ceil(float(f_count_83) / 5.0)))
		ViewMode.FIGURE_DETAIL:
			total_pages = 1
		_:
			total_pages = 1

func next_page() -> void:
	if total_pages > 0:
		current_page = (current_page + 1) % total_pages

func prev_page() -> void:
	if total_pages > 0:
		current_page = (current_page - 1 + total_pages) % total_pages

func get_page_info() -> String:
	return "Pag. %d/%d" % [current_page + 1, total_pages]

func get_current_text() -> String:
	if history_gen == null or world_gen == null:
		return "Sin registros historicos."
	var text = ""
	match current_mode:
		ViewMode.OVERVIEW:
			text = _get_overview_text()
		ViewMode.CHRONOLOGY:
			text = _get_chronology_text()
		ViewMode.CIVILIZATIONS:
			text = _get_civs_text()
		ViewMode.FIGURES:
			text = _get_figures_text()
		ViewMode.BEASTS:
			text = _get_beasts_text()
		ViewMode.ARTIFACTS:
			text = _get_artifacts_text()
		ViewMode.SITES:
			text = _get_sites_text()
		ViewMode.WARS:
			text = _get_wars_text()
		ViewMode.FAMILIES:
			text = _get_families_text()
		ViewMode.FIGURE_DETAIL:
			text = _get_figure_detail_text()
	return text

# ============================================================================
# OVERVIEW
# ============================================================================
func _get_overview_text() -> String:
	var text = "=== RESUMEN DE LEYENDAS ===\n"
	text += "Mundo: %s\n" % world_name
	text += "Semilla: %d\n\n" % seed_val
	var beasts_count = 0
	var hf_count = 0
	for hf in history_gen.historical_figures:
		if hf.race == "megabeast":
			beasts_count += 1
		else:
			hf_count += 1
	text += "Civilizaciones: %d\n" % history_gen.civs.size()
	text += "Asentamientos: %d\n" % history_gen.sites.size()
	text += "Figuras Historicas: %d\n" % hf_count
	text += "Bestias Legendarias: %d\n" % beasts_count
	text += "Reliquias Creadas: %d\n" % history_gen.artifacts.size()
	text += "Guerras Activas: %d\n" % history_gen.active_wars.size()
	text += "Dinastias: %d\n" % history_gen.family_db.size()
	text += "\n[1-9] Categorias  [0] Seleccionar  [PgUp/PgDn] Paginas"
	return text

# ============================================================================
# CHRONOLOGY
# ============================================================================
func _get_chronology_text() -> String:
	var text = "=== CRONOLOGIA HISTORICA ===\n"
	var events = history_gen.chronicle.events if history_gen.chronicle != null else []
	var page_size = 15
	var start = current_page * page_size
	var end = min(events.size(), start + page_size)
	for i in range(start, end):
		var ev = events[i]
		var ev_text = ev.get("text", "Evento")
		text += "- %s\n" % ev_text
	return text

# ============================================================================
# CIVILIZATIONS
# ============================================================================
func _get_civs_text() -> String:
	var text = "=== CIVILIZACIONES ===\n"
	var start = current_page * 5
	var end = min(history_gen.civs.size(), start + 5)
	for i in range(start, end):
		var civ = history_gen.civs[i]
		var state = "Muerta" if civ.get("is_dead", false) else "Activa"
		text += "- %s (%s, %s)\n" % [civ["name"], _translate_race(civ["race"]), state]
		text += "  Poblacion: %d\n" % civ["population"]
	return text

# ============================================================================
# FIGURES (with family info)
# ============================================================================
func _get_figures_text() -> String:
	var text = "=== FIGURAS HISTORICAS ===\n"
	var non_beasts = []
	for hf in history_gen.historical_figures:
		if hf.race != "megabeast":
			non_beasts.append(hf)
	var start = current_page * 5
	var end = min(non_beasts.size(), start + 5)
	var idx = start + 1
	for i in range(start, end):
		var hf_194 = non_beasts[i]
		var ruler_tag = " [Rey]" if hf_194.is_ruler else ""
		var dyn_name = _get_dynasty_name(hf_194.id)
		var dyn_tag = " [%s]" % dyn_name if dyn_name != "" else ""
		text += "%d. %s (%s, %s)%s%s\n" % [idx, hf_194.name, _translate_race(hf_194.race), hf_194.profession, ruler_tag, dyn_tag]
		text += "  Edad: %d | Bajas: %d\n" % [hf_194.get_age(63), hf_194.kills]
		if hf_194.spouse_id >= 0:
			var spouse = _get_hf(hf_194.spouse_id)
			if spouse != null:
				text += "  Conyuge: %s\n" % spouse.name
		if not hf_194.children.is_empty():
			var alive_kids = 0
			for cid in hf_194.children:
				var c = _get_hf(cid)
				if c != null and c.is_alive(-1):
					alive_kids += 1
			text += "  Hijos vivos: %d\n" % alive_kids
		if not hf_194.notable_deeds.is_empty():
			text += "  Hazanas:\n"
			for deed in hf_194.notable_deeds.slice(0, 2):
				text += "    * %s\n" % deed
		text += "\n"
		idx += 1
	text += "\nPulsa [0] + numero para ver detalle familiar de una figura."
	return text

# ============================================================================
# BEASTS
# ============================================================================
func _get_beasts_text() -> String:
	var text = "=== MEGABESTIAS LEYENDARIAS ===\n"
	var beasts = []
	for hf in history_gen.historical_figures:
		if hf.race == "megabeast":
			beasts.append(hf)
	var start = current_page * 3
	var end = min(beasts.size(), start + 3)
	for i in range(start, end):
		var b = beasts[i]
		var state = "Muerta en el ano %d" % b.death_year if b.death_year != -1 else "Viva"
		text += "- %s (%s)\n" % [b.name, state]
		text += "  Poder: %.1f | Bajas: %d\n" % [b.combat_power, b.kills]
		if not b.notable_deeds.is_empty():
			text += "  Eventos:\n"
			for deed in b.notable_deeds.slice(0, 2):
				text += "    * %s\n" % deed
		text += "\n"
	return text

# ============================================================================
# ARTIFACTS
# ============================================================================
func _get_artifacts_text() -> String:
	var text = "=== RELIQUIAS Y ARTEFACTOS ===\n"
	var start = current_page * 5
	var end = min(history_gen.artifacts.size(), start + 5)
	for i in range(start, end):
		var art = history_gen.artifacts[i]
		text += "- %s (%s de %s)\n" % [art["name"], art["type"], art["material"]]
		text += "  Creada por: ID %d en el ano %d\n" % [art["creator_id"], art["year"]]
		var creator = _get_hf(art["creator_id"])
		if creator != null:
			text += "  Creador: %s\n" % creator.name
			var dyn_c = _get_dynasty_name(creator.id)
			if dyn_c != "":
				text += "  Dinastia: %s\n" % dyn_c
	return text

# ============================================================================
# SITES
# ============================================================================
func _get_sites_text() -> String:
	var text = "=== ASENTAMIENTOS ===\n"
	var start = current_page * 5
	var end = min(history_gen.sites.size(), start + 5)
	for i in range(start, end):
		var site = history_gen.sites[i]
		var civ = _get_civ_name(site["civ_id"])
		var sack_tag = " [SAQUEADA]" if site.get("is_sacked", false) else ""
		text += "- %s (ano %d)%s\n" % [site["name"], site["founded"], sack_tag]
		text += "  %s | Pob: %d | (%d, %d)\n" % [civ, site["population"], site["x"], site["z"]]
	return text

# ============================================================================
# WARS
# ============================================================================
func _get_wars_text() -> String:
	var text = "=== GUERRAS E INCIDENTES ===\n"
	var start = current_page * 5
	var end = min(history_gen.active_wars.size(), start + 5)
	for i in range(start, end):
		var war = history_gen.active_wars[i]
		var civ_a = _get_civ_name(war["civ_a"])
		var civ_b = _get_civ_name(war["civ_b"])
		text += "- %s vs %s\n" % [civ_a, civ_b]
		text += "  Duracion: %d anos\n" % war["duration"]
	return text

# ============================================================================
# FAMILIES / DYNASTIES
# ============================================================================
func _get_families_text() -> String:
	var text = "=== DINASTIAS ===\n"
	if history_gen.family_db.is_empty():
		text += "No hay datos de familias."
		return text
	var fam_list = []
	for fam_id in history_gen.family_db:
		fam_list.append(history_gen.family_db[fam_id])
	var start = current_page * 5
	var end = min(fam_list.size(), start + 5)
	var idx = start + 1
	for i in range(start, end):
		var fam = fam_list[i]
		var founder = _get_hf(fam["founder_id"])
		var founder_name = founder.name if founder != null else "Desconocido"
		var head = _get_hf(fam["current_head_id"])
		var head_name = head.name if head != null else "Nadie"
		var alive_count = 0
		var dead_count = 0
		for mid in fam["members"]:
			var m = _get_hf(mid)
			if m == null: continue
			if m.is_alive(-1):
				alive_count += 1
			else:
				dead_count += 1
		var art_count = fam.get("artifacts_held", []).size()
		text += "%d. %s\n" % [idx, fam["dynasty_name"]]
		text += "  Fundador: %s (ano %d)\n" % [founder_name, fam["founded_year"]]
		text += "  Cabeza: %s | Vivos: %d | Muertos: %d\n" % [head_name, alive_count, dead_count]
		if art_count > 0:
			text += "  Reliquias familiares: %d\n" % art_count
		text += "\n"
		idx += 1
	if fam_list.is_empty():
		text += "Ninguna dinastia registrada.\n"
	return text

# ============================================================================
# FIGURE DETAIL (full biography + family tree)
# ============================================================================
func _get_figure_detail_text() -> String:
	if selected_figure_id < 0:
		return "Ninguna figura seleccionada."
	var hf = _get_hf(selected_figure_id)
	if hf == null:
		return "Figura historica no encontrada."
	var dyn_name = _get_dynasty_name(hf.id)
	var ruler_tag = " [Rey]" if hf.is_ruler else ""
	var state = "Vivo" if hf.is_alive(-1) else "Muerto en %d" % hf.death_year
	var text = "=== %s '%s' ===%s\n" % [hf.get_title(), hf.name, ruler_tag]
	text += "Raza: %s | Estado: %s | Edad: %d\n" % [_translate_race(hf.race), state, hf.get_age(63)]
	text += "Profesion: %s\n" % hf.profession
	if dyn_name != "":
		text += "Dinastia: %s\n" % dyn_name
	text += "Poder: %.1f | Bajas: %d | Liderazgo: %.1f\n" % [hf.combat_power, hf.kills, hf.leadership]
	text += "\n"

	# Family tree section
	text += "--- ARBOL FAMILIAR ---\n"

	# Parents
	var parents = _find_parents(hf.id)
	if not parents.is_empty():
		text += "PADRES:\n"
		for p in parents:
			var pstate = "vivo" if p.is_alive(-1) else "muerto"
			text += "  - %s (%s)\n" % [p.name, pstate]
	else:
		text += "PADRES: Desconocidos\n"

	# Spouse
	if hf.spouse_id >= 0:
		var spouse = _get_hf(hf.spouse_id)
		if spouse != null:
			var sstate = "vivo" if spouse.is_alive(-1) else "muerto"
			text += "CONYUGE: %s (%s)\n" % [spouse.name, sstate]

	# Children
	if not hf.children.is_empty():
		text += "HIJOS:\n"
		for cid in hf.children:
			var c = _get_hf(cid)
			if c == null: continue
			var cstate = "vivo" if c.is_alive(-1) else "muerto en %d" % c.death_year
			var ctag = " [Rey]" if c.is_ruler else ""
			text += "  - %s (%d anos, %s)%s\n" % [c.name, c.get_age(63), cstate, ctag]
	else:
		text += "HIJOS: Ninguno\n"

	# Siblings (share a parent)
	var siblings = _find_siblings(hf.id)
	if not siblings.is_empty():
		text += "HERMANOS:\n"
		for s in siblings:
			var sstate_390 = "vivo" if s.is_alive(-1) else "muerto"
			var stag = " [Rey]" if s.is_ruler else ""
			text += "  - %s (%d anos, %s)%s\n" % [s.name, s.get_age(63), sstate_390, stag]

	text += "\n--- HAZANAS ---\n"
	if not hf.notable_deeds.is_empty():
		for deed in hf.notable_deeds:
			text += "  * %s\n" % deed
	else:
		text += "  Ninguna registrada.\n"

	# Family artifacts
	text += "\n--- RELIQUIAS FAMILIARES ---\n"
	if hf.family_id >= 0 and history_gen.family_db.has(hf.family_id):
		var fam = history_gen.family_db[hf.family_id]
		var held = fam.get("artifacts_held", [])
		if not held.is_empty():
			for aid in held:
				for ai in history_gen.artifact_instances:
					if ai["art_id"] == aid:
						var inh = ""
						if ai.has("inherited_by"):
							var heir = _get_hf(ai["inherited_by"])
							inh = " -> heredado a %s" % (heir.name if heir != null else "desconocido")
						text += "  - %s (%s)%s\n" % [ai["name"], ai.get("type", "objeto"), inh]
						break
		else:
			text += "  Ninguna.\n"
	else:
		text += "  Ninguna.\n"

	text += "\n--- NOTAS ---\n"
	var death_records = 0
	for cs in history_gen.corpse_sites:
		if cs["hf_id"] == hf.id:
			death_records = 1
			break
	if death_records > 0:
		text += "  Registro mortuorio: documentado.\n"
	text += "\nPulsa [0] para volver a lista de figuras."
	return text

# ============================================================================
# HELPERS
# ============================================================================
func _find_parents(hf_id: int) -> Array:
	var res = []
	for hf in history_gen.historical_figures:
		if hf.id != hf_id and hf_id in hf.children:
			res.append(hf)
	return res

func _find_siblings(hf_id: int) -> Array:
	var res = []
	var parents = _find_parents(hf_id)
	if parents.is_empty():
		return res
	var parent_ids = []
	for p in parents:
		parent_ids.append(p.id)
	for hf in history_gen.historical_figures:
		if hf.id == hf_id:
			continue
		if hf.race == "megabeast":
			continue
		var is_sibling = false
		for pid in parent_ids:
			if pid in hf.children:
				is_sibling = true
				break
		if is_sibling:
			res.append(hf)
	return res

func get_figure_detail_data(hf_id: int) -> Dictionary:
	var data = {
		"hf_id": hf_id,
		"name": "Desconocido",
		"race": "",
		"age": 0,
		"alive": false,
		"is_ruler": false,
		"title": "",
		"profession": "",
		"dynasty_name": "",
		"dynasty_color": Color(0.5, 0.5, 0.5),
		"spouse": {},
		"parents": [],
		"children": [],
		"siblings": [],
		"notable_deeds": []
	}
	var hf = _get_hf(hf_id)
	if hf == null:
		return data
	data.name = hf.name
	data.race = hf.race
	data.age = hf.get_age(63)
	data.alive = hf.is_alive(-1)
	data.is_ruler = hf.is_ruler
	data.title = hf.get_title()
	data.profession = hf.profession
	data.notable_deeds = hf.notable_deeds.duplicate()
	data.dynasty_name = _get_dynasty_name(hf.id)

	if hf.family_id >= 0 and history_gen.family_db.has(hf.family_id):
		var fam = history_gen.family_db[hf.family_id]
		if fam.has("dynasty_color"):
			data.dynasty_color = fam["dynasty_color"]
		else:
			var h = hash(fam["dynasty_name"])
			var r = float((h & 0xFF) % 200 + 55) / 255.0
			var g = float(((h >> 8) & 0xFF) % 200 + 55) / 255.0
			var b = float(((h >> 16) & 0xFF) % 200 + 55) / 255.0
			var c = Color(r, g, b)
			fam["dynasty_color"] = c
			data.dynasty_color = c

	if hf.spouse_id >= 0:
		var s = _get_hf(hf.spouse_id)
		if s != null:
			data.spouse = {
				"hf_id": s.id,
				"name": s.name,
				"age": s.get_age(63),
				"alive": s.is_alive(-1),
				"is_ruler": s.is_ruler,
				"title": s.get_title(),
				"profession": s.profession,
				"dynasty_name": _get_dynasty_name(s.id)
			}

	for cid in hf.children:
		var c_523 = _get_hf(cid)
		if c_523 != null:
			data.children.append({
				"hf_id": c_523.id,
				"name": c_523.name,
				"age": c_523.get_age(63),
				"alive": c_523.is_alive(-1),
				"is_ruler": c_523.is_ruler,
				"title": c_523.get_title(),
				"profession": c_523.profession
			})

	for p in _find_parents(hf.id):
		data.parents.append({
			"hf_id": p.id,
			"name": p.name,
			"age": p.get_age(63),
			"alive": p.is_alive(-1),
			"is_ruler": p.is_ruler,
			"title": p.get_title(),
			"profession": p.profession
		})

	for s_546 in _find_siblings(hf.id):
		data.siblings.append({
			"hf_id": s_546.id,
			"name": s_546.name,
			"age": s_546.get_age(63),
			"alive": s_546.is_alive(-1),
			"is_ruler": s_546.is_ruler,
			"title": s_546.get_title(),
			"profession": s_546.profession
		})

	return data

func _get_hf(hf_id: int):
	for hf in history_gen.historical_figures:
		if hf.id == hf_id:
			return hf
	return null

func _get_dynasty_name(hf_id: int) -> String:
	for hf in history_gen.historical_figures:
		if hf.id == hf_id:
			if hf.family_id >= 0 and history_gen.family_db.has(hf.family_id):
				return history_gen.family_db[hf.family_id]["dynasty_name"]
	return ""

func _translate_race(race: String) -> String:
	match race.to_lower():
		"dwarf": return "Enano"
		"elf": return "Elfo"
		"human": return "Humano"
		"goblin": return "Goblin"
		"megabeast": return "Megabestia"
	return "Desconocida"

func _get_civ_name(civ_id: int) -> String:
	if history_gen != null:
		for civ in history_gen.civs:
			if civ["id"] == civ_id:
				return civ["name"]
	return "Desconocida"
