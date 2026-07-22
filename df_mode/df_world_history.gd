extends RefCounted
class_name DFWorldHistory

const DFNamegen = preload("res://df_mode/df_namegen.gd")
const DFChronicleDB = preload("res://df_mode/df_chronicle_db.gd")
const DFHistoricalFigure = preload("res://df_mode/df_historical_figure.gd")
const DFItem = preload("res://df_mode/df_item.gd")
const DFCreature = preload("res://df_mode/df_creature.gd")

var namegen: DFNamegen = null
var chronicle: DFChronicleDB = null

var civs: Array = []
var sites: Array = []
var historical_figures: Array = []
var beasts: Array = []
var artifacts: Array = []
var active_wars: Array = []
var written_works: Array = []
var religions: Array = []

var hf_counter: int = 1
var art_counter: int = 1
var book_counter: int = 1
var rng: RandomNumberGenerator

var artifact_instances: Array = []
var beast_instances: Array = []
var corpse_sites: Array = []
var historical_npcs: Array = []

var family_db: Dictionary = {}  # family_id -> {dynasty_name, members, founder_id, founded_year, race, current_head_id}
var next_family_id: int = 1
var initial_megabeast_count: int = 0
var current_age_label: String = "Edad del Mito"

var body_part_pool = ["cabeza", "torso", "brazo", "pierna", "ala", "cola", "garra", "cuerno", "colmillo", "aguijon", "tentaculo", "ojo", "pico", "cresta", "escama"]
var material_organic_pool = ["escama", "cuero", "piel", "pluma", "concha", "exoesqueleto", "musculo", "hueso", "colmillo", "garra", "cuerno", "sangre"]
var breath_weapon_pool = [
	{"name": "fuego", "damage_type": "FIRE", "color": Color("#FF4400"), "desc": "llamas abrasadoras que carbonizan la piedra"},
	{"name": "hielo", "damage_type": "COLD", "color": Color("#44CCFF"), "desc": "un chorro de escarcha que congela el aire"},
	{"name": "ácido", "damage_type": "ACID", "color": Color("#44FF44"), "desc": "ácido corrosivo que disuelve la carne"},
	{"name": "relámpago", "damage_type": "LIGHTNING", "color": Color("#FFFF00"), "desc": "un rayo cegador que parte el cielo"},
	{"name": "veneno", "damage_type": "POISON", "color": Color("#AA44FF"), "desc": "una nube verdosa de vapores letales"},
	{"name": "oscuridad", "damage_type": "DARK", "color": Color("#220022"), "desc": "sombra viva que apaga la luz y la esperanza"},
]

func _init(seed_value: int = -1):
	rng = RandomNumberGenerator.new()
	rng.seed = seed_value if seed_value >= 0 else randi()
	namegen = DFNamegen.new(rng.randi())
	chronicle = DFChronicleDB.new()

func generate_history(world_gen: Object, history_length: int = 250) -> Array:
	_setup_initial_world(world_gen)
	_generate_religions()
	for year in range(1, history_length + 1):
		_simulate_year(year, world_gen)
		if year % 25 == 0 and rng.randf() < 0.3:
			_generate_written_work(year)
	world_gen.civs = civs
	world_gen.sites = sites
	return chronicle.events

# ============================================================================
# RELIGION / PHILOSOPHY (procedural belief systems)
# ============================================================================
func _generate_religions() -> void:
	var num_religions = rng.randi_range(3, 6)
	var domains = ["Naturaleza", "Muerte", "Guerra", "Sabiduría", "Destino", "Fuego", "Agua", "Tierra", "Cielo", "Caos", "Orden", "Vida", "Noche", "Sol", "Luna", "Tiempo", "Venganza", "Música"]
	var tenets = ["La fuerza lo es todo", "El conocimiento es poder", "Toda vida es sagrada", "La muerte es una liberación", "La guerra purifica", "El destino es ineludible",
		"La naturaleza debe ser protegida", "El caos es la verdadera libertad", "La sabiduría viene del sufrimiento", "La paz es una ilusión"]
	var rituals = ["Oraciones al amanecer", "Sacrificios bajo la luna", "Ayuno en soledad", "Danzas rituales", "Cantos sagrados", "Peregrinaciones", "Ofrendas de sangre",
		"Meditación profunda", "Visiones inducidas", "Tatuajes sagrados"]

	for i in range(num_religions):
		var domain = domains[rng.randi() % domains.size()]
		var rel_name = namegen.generate_site_name("dwarf").capitalize() + "ismo"
		var high_name = namegen.generate_dwarf_name()
		var tenet = tenets[rng.randi() % tenets.size()]
		var ritual = rituals[rng.randi() % rituals.size()]

		var religion = {
			"id": i,
			"name": rel_name,
			"domain": domain,
			"deity_name": high_name,
			"tenet": tenet,
			"ritual": ritual,
			"adherent_civs": [],
			"holy_sites": []
		}
		religions.append(religion)
		chronicle.add_event(1, "RELIGION", {"name": rel_name, "domain": domain, "deity": high_name})

# ============================================================================
# WRITTEN WORKS (procedural books, poems, songs from simulation)
# ============================================================================
func _generate_written_work(year: int) -> void:
	var genres = [
		{"name": "poema", "template": "Oh %s, %s del %s, tu %s es %s"},
		{"name": "tratado", "template": "Sobre la naturaleza del %s y su %s con el %s"},
		{"name": "cantar", "template": "Cantar de %s: como el heroe %s vencio al %s"},
		{"name": "cronica", "template": "Cronica del ano %d: el %s cayo ante %s"},
	]
	var genre = genres[rng.randi() % genres.size()]
	var title_words = [namegen.get_random_word("dwarf"), namegen.get_random_word("elf"), namegen.get_random_word("goblin")]
	var title = "%s %s %s" % [title_words[0].capitalize(), title_words[1].to_lower(), title_words[2].to_lower()]

	var author = null
	for hf in historical_figures:
		if hf.is_alive(year) and hf.race != "megabeast" and rng.randf() < 0.1:
			author = hf
			break
	if author == null:
		author = historical_figures[rng.randi() % historical_figures.size()] if not historical_figures.is_empty() else null
	if author == null:
		return

	var subject_hf = null
	for hf_119 in historical_figures:
		if hf_119.is_alive(year) and hf_119 != author and hf_119.race != "megabeast" and rng.randf() < 0.2:
			subject_hf = hf_119
			break

	var work = {
		"id": book_counter,
		"title": title,
		"genre": genre["name"],
		"author_id": author.id,
		"author_name": author.name,
		"year": year,
		"subject_id": subject_hf.id if subject_hf != null else -1,
		"subject_name": subject_hf.name if subject_hf != null else "el mundo"
	}
	written_works.append(work)
	book_counter += 1
	chronicle.add_event(year, "WRITTEN_WORK", {"title": title, "genre": genre["name"], "author": author.name})

# ============================================================================
# BEAST GENERATION (truly procedural — every beast is a unique creature)
# ============================================================================
func _generate_beast_name() -> String:
	var parts = []
	var num_parts = rng.randi_range(2, 4)
	for _i in range(num_parts):
		var lang = ["dwarf", "elf", "goblin", "human"][rng.randi() % 4]
		var w = namegen.get_random_word(lang)
		var seg_len = clampi(rng.randi_range(2, mini(5, w.length())), 2, 5)
		parts.append(w.substr(0, seg_len).capitalize())
	var name = "".join(parts)
	if name.length() > 16:
		name = name.substr(0, rng.randi_range(6, 14))

	var epithet_pool = [
		"Abismal", "Ancient", "Atronador", "Bestial", "Colosal", "Devorador",
		"Escamoso", "Eterno", "Funesto", "Incandescente", "Infernal", "Inmortal",
		"Insaciable", "Milenario", "Primigenio", "Putrido", "Quimérico", "Resplandeciente",
		"Sangriento", "Sigiloso", "Telúrico", "Vermiforme", "Viscoso", "Voraz"
	]
	var epithet = epithet_pool[rng.randi() % epithet_pool.size()]
	return "%s el %s" % [name, epithet]

func _generate_procedural_body() -> Dictionary:
	var num_heads = rng.randi_range(1, min(3 + rng.randi() % 3, 7))
	var num_limbs = rng.randi_range(2, 8)
	var num_wings = rng.randi_range(0, 4)
	var num_tails = rng.randi_range(0, 3)
	var num_eyes = rng.randi_range(1, 12)
	var has_stinger = rng.randf() < 0.3
	var has_tentacles = rng.randf() < 0.2
	var num_tentacles = 0
	if has_tentacles:
		num_tentacles = rng.randi_range(2, 8)

	return {
		"heads": num_heads,
		"limbs": num_limbs,
		"wings": num_wings,
		"tails": num_tails,
		"eyes": num_eyes,
		"stinger": has_stinger,
		"tentacles": num_tentacles,
		"body_length": rng.randf_range(3.0, 30.0),
		"body_height": rng.randf_range(1.5, 15.0)
	}

func _generate_procedural_materials() -> Dictionary:
	var hide_options = ["escamas", "cuero grueso", "placas oseas", "exoesqueleto quitinoso", "piel pétrea", "pelaje metálico", "plumas ferreas", "cristal orgánico"]
	var blood_options = ["sangre roja", "icor verde", "ácido claro", "magma líquido", "sombra negra", "mercurio brillante", "savia luminosa", "viscosidad plateada"]
	var bone_options = ["hueso compacto", "cartílago flexible", "cristal de silicio", "obsidiana viva", "marfil negro", "adamantita natural"]

	return {
		"hide": hide_options[rng.randi() % hide_options.size()],
		"blood": blood_options[rng.randi() % blood_options.size()],
		"bone": bone_options[rng.randi() % bone_options.size()]
	}

func _generate_procedural_abilities() -> Array:
	var num_abilities = rng.randi_range(1, 3)
	var abilities = []

	var has_breath = rng.randf() < 0.5
	if has_breath:
		var bw = breath_weapon_pool[rng.randi() % breath_weapon_pool.size()]
		abilities.append({
			"type": "breath",
			"name": "Aliento de %s" % bw["name"],
			"element": bw["name"],
			"damage_type": bw["damage_type"],
			"color": bw["color"],
			"description": "Respira %s: %s" % [bw["name"], bw["desc"]]
		})

	var passive_pool = [
		{"name": "Regeneración", "desc": "Sus heridas se cierran ante tus ojos"},
		{"name": "Inmunidad al fuego", "desc": "Las llamas lo acarician sin dañarlo"},
		{"name": "Inmunidad a la magia", "desc": "Los hechizos se disipan al tocarlo"},
		{"name": "Aura de miedo", "desc": "Los debiles de corazon huyen al verlo"},
		{"name": "Reflejos de cristal", "desc": "Su piel refleja los ataques fisicos"},
		{"name": "Venenoso al tacto", "desc": "Su carne segrega un veneno letal"},
		{"name": "Camuflaje", "desc": "Se mimetiza con el entorno"},
		{"name": "Vista termica", "desc": "Percibe el calor de los seres vivos"},
	]
	var special_pool = [
		{"name": "Terremoto", "desc": "Golpea el suelo y derriba a todos cercanos"},
		{"name": "Alarido sónico", "desc": "Emite un grito que rompe tímpanos"},
		{"name": "Telarañas", "desc": "Teje redes pegajosas que inmovilizan"},
		{"name": "Cola maza", "desc": "Su cola es un arma contundente masiva"},
		{"name": "Pinzas", "desc": "Sus pinzas pueden partir un enano en dos"},
	]

	for _i in range(num_abilities):
		var pool = passive_pool if rng.randf() < 0.5 else special_pool
		var chosen = pool[rng.randi() % pool.size()]
		var already_have = false
		for a in abilities:
			if a.get("name", "") == chosen["name"]:
				already_have = true
				break
		if not already_have:
			abilities.append({"type": "passive" if _i < 1 else "special", "name": chosen["name"], "description": chosen["desc"]})

	return abilities

func _generate_appearance_from_body(body: Dictionary, materials: Dictionary) -> Dictionary:
	var color_primary = Color(rng.randf_range(0.0, 1.0), rng.randf_range(0.0, 1.0), rng.randf_range(0.0, 1.0))
	var color_secondary = Color(
		clampf(color_primary.r + rng.randf_range(-0.3, 0.3), 0.0, 1.0),
		clampf(color_primary.g + rng.randf_range(-0.3, 0.3), 0.0, 1.0),
		clampf(color_primary.b + rng.randf_range(-0.3, 0.3), 0.0, 1.0)
	)
	var is_glowing = rng.randf() < 0.3
	var glow_color = Color(rng.randf(), rng.randf(), rng.randf()) if is_glowing else Color.BLACK

	var g = "D"
	if body["tentacles"] > 0:
		g = "K"
	elif body["wings"] >= 4:
		g = "W"
	elif body["heads"] >= 3:
		g = "H"
	elif body["heads"] >= 2:
		g = "2"
	elif body["tails"] >= 2:
		g = "S"
	elif body["stinger"]:
		g = "S"
	else:
		g = ["D", "T", "G", "R"][rng.randi() % 4]

	var size_label = "mega"
	var mass = body["body_length"] * body["body_height"]
	if mass < 20.0:
		size_label = "large"
	elif mass < 80.0:
		size_label = "giant"
	else:
		size_label = "mega"

	var size_map = {"large": "large", "giant": "giant", "mega": "mega"}

	return {
		"glyph": g,
		"color": color_primary,
		"color_secondary": color_secondary,
		"glow": is_glowing,
		"glow_color": glow_color,
		"size": size_map.get(size_label, "mega"),
		"size_label": size_label,
		"body_description": _build_body_description(body, materials)
	}

func _build_body_description(body: Dictionary, materials: Dictionary) -> String:
	var parts = []
	if body["heads"] == 1:
		parts.append("una sola cabeza")
	elif body["heads"] <= 3:
		parts.append("%d cabezas" % body["heads"])
	else:
		parts.append("un circulo de %d cabezas" % body["heads"])

	parts.append("%d miembros" % body["limbs"])
	if body["wings"] > 0:
		parts.append("%d alas" % body["wings"])
	if body["tails"] == 1:
		parts.append("una cola larga")
	elif body["tails"] > 1:
		parts.append("%d colas" % body["tails"])
	if body["stinger"]:
		parts.append("un aguijon en la cola")
	if body["tentacles"] > 0:
		parts.append("%d tentaculos undulantes" % body["tentacles"])

	var text = "Criatura de %s" % ", ".join(parts)
	text += ". Su cuerpo mide %.1f metros de largo y %.1f de alto." % [body["body_length"], body["body_height"]]
	text += " Su piel es de %s, su sangre es %s y su esqueleto es de %s." % [materials["hide"], materials["blood"], materials["bone"]]
	return text

func _generate_beast_full_description(body: Dictionary, materials: Dictionary, appearance: Dictionary, abilities: Array) -> String:
	var desc = appearance["body_description"] + "\n"
	if appearance["glow"]:
		desc += "Emite un resplandor %s que ilumina la noche.\n" % _color_name(appearance["glow_color"])

	for a in abilities:
		desc += a["description"] + ".\n"

	return desc

func _color_name(c: Color) -> String:
	var colors = [
		{ "name": "rojo", "r": 1.0, "g": 0.0, "b": 0.0 },
		{ "name": "verde", "r": 0.0, "g": 1.0, "b": 0.0 },
		{ "name": "azul", "r": 0.0, "g": 0.0, "b": 1.0 },
		{ "name": "amarillo", "r": 1.0, "g": 1.0, "b": 0.0 },
		{ "name": "magenta", "r": 1.0, "g": 0.0, "b": 1.0 },
		{ "name": "cian", "r": 0.0, "g": 1.0, "b": 1.0 },
		{ "name": "naranja", "r": 1.0, "g": 0.5, "b": 0.0 },
		{ "name": "violeta", "r": 0.5, "g": 0.0, "b": 1.0 },
	]
	var best = colors[0]
	var best_dist = 999.0
	for col in colors:
		var d = abs(c.r - col["r"]) + abs(c.g - col["g"]) + abs(c.b - col["b"])
		if d < best_dist:
			best_dist = d
			best = col
	return best["name"]

func _generate_beast_instance(world_gen: Object) -> Dictionary:
	var name = _generate_beast_name()
	var body = _generate_procedural_body()
	var materials = _generate_procedural_materials()
	var abilities = _generate_procedural_abilities()
	var appearance = _generate_appearance_from_body(body, materials)
	var full_desc = _generate_beast_full_description(body, materials, appearance, abilities)

	var base_damage = (body["body_length"] * body["body_height"] * 0.5) + (body["heads"] * 5.0) + (body["tentacles"] * 3.0)
	var age_factor = 1.0 + rng.randf() * 3.0
	var final_damage = base_damage * age_factor

	var bx = rng.randi_range(30, world_gen.world_width - 30)
	var bz = rng.randi_range(30, world_gen.world_depth - 30)
	var lair_dist = rng.randi_range(8, 20)
	var lx = clampi(bx + rng.randi_range(-lair_dist, lair_dist), 10, world_gen.world_width - 10)
	var lz = clampi(bz + rng.randi_range(-lair_dist, lair_dist), 10, world_gen.world_depth - 10)

	return {
		"name": name,
		"body": body,
		"materials": materials,
		"abilities": abilities,
		"appearance": appearance,
		"description": full_desc,
		"world_x": bx,
		"world_z": bz,
		"lair_x": lx,
		"lair_z": lz,
		"attack_damage": final_damage,
		"age_factor": age_factor
	}

# ============================================================================
# ARTIFACT GENERATION (procedural descriptions with historical references)
# ============================================================================
func _generate_artifact_name_from_lang(concept: String, creator_race: String) -> String:
	return namegen.generate_artifact_name(concept)

func _generate_artifact_description(art_props: Dictionary, creator_name: String, year: int, civ_name: String) -> String:
	var desc = "Un %s de %s creado en el anio %d por %s de %s." % [art_props["type"].to_lower(), art_props["material"], year, creator_name, civ_name]

	var image_themes = [
		"escenas de batalla contra %s" if rng.randf() < 0.5 and not beast_instances.is_empty() else "%s danzando alrededor del fuego",
		"la coronacion de un rey en %s" if rng.randf() < 0.5 and not sites.is_empty() else "un ser celestial descendiendo sobre %s",
		"animales exoticos de tierras lejanas",
		"arboles ancestrales con raices de %s" % art_props["material"],
		"geometrias imposibles que duelen al mirarlas",
		"la figura de %s contemplando el horizonte" % namegen.generate_dwarf_name(),
		"runas antiguas que narran la fundacion de %s" % civ_name,
	]

	var image_desc = image_themes[rng.randi() % image_themes.size()]
	if "%s" in image_desc:
		var fill = namegen.get_random_word("dwarf").capitalize() if rng.randf() < 0.5 else namegen.generate_dwarf_name()
		image_desc = image_desc % fill

	var quality_terms = ["Exquisito", "Sobrio", "Intrincado", "Colosal", "Delicado", "Austero", "Recargado", "Minimalista"]
	var quality_term = quality_terms[rng.randi() % quality_terms.size()]

	var detail_desc = ""
	if rng.randf() < 0.5:
		var detail_words = ["incrustaciones de %s" % ["oro", "plata", "marfil", "gemas", "esmalte"][rng.randi() % 5],
			"filigranas en los bordes",
			"un brillo interno que pulsa",
			"inscripciones en escritura %s" % ["enana", "elfica", "goblin", "arcana"][rng.randi() % 4],
			"pequenas marcas que cuentan una historia"]
		detail_desc = " Se distingue por %s." % detail_words[rng.randi() % detail_words.size()]

	desc += " Es de estilo %s. Su superficie muestra %s.%s" % [quality_term, image_desc, detail_desc]
	return desc

# ============================================================================
# SETUP
# ============================================================================
func _setup_initial_world(world_gen: Object) -> void:
	var area_scale: float = sqrt(float(world_gen.world_width * world_gen.world_depth)) / 256.0
	var density_multiplier: float = [0.65, 1.0, 1.55][clampi(int(world_gen.setting_civ_density), 0, 2)]
	var target_civs: int = clampi(roundi(8.0 * area_scale * density_multiplier), 6, 28)
	var num_civs: int = rng.randi_range(maxi(6, target_civs - 2), target_civs + 2)
	var langs: Array[String] = ["dwarf", "elf", "human", "goblin"]
	var used_capitals: Array = []

	for i in range(num_civs):
		var race: String = langs[rng.randi() % langs.size()]
		var civ_name: String = "Los %s de %s" % [_translate_race_plural(race), namegen.generate_site_name(race).capitalize()]
		var capital_pos: Vector2i = world_gen.find_best_site_for_race(race, used_capitals) if world_gen.has_method("find_best_site_for_race") else Vector2i(int(world_gen.world_width / 2), int(world_gen.world_depth / 2))
		used_capitals.append(capital_pos)
		var cx: int = capital_pos.x
		var cz: int = capital_pos.y

		var civ = {
			"id": i,
			"name": civ_name,
			"race": race,
			"capital_x": cx,
			"capital_z": cz,
			"population": 150,
			"ruler_id": -1,
			"color": Color(rng.randf(), rng.randf(), rng.randf()),
			"relations": {},
			"is_dead": false
		}
		civs.append(civ)
		chronicle.add_event(1, "FOUND_CIV", {"race": race, "civ_name": civ_name})

		var ruler_name = namegen.generate_dwarf_name() if race == "dwarf" else namegen.generate_site_name(race)
		var ruler = DFHistoricalFigure.new(hf_counter, ruler_name, race, 0, i, rng)
		ruler.is_ruler = true
		ruler.profession = "Rey" if race != "goblin" else "Señor Demoníaco"
		ruler.site_id = sites.size()
		var fam_id = _create_dynasty(ruler, 1, race)
		historical_figures.append(ruler)
		var init_dyn_name = family_db[fam_id]["dynasty_name"]
		historical_npcs.append({
			"hf_id": hf_counter,
			"name": ruler_name,
			"race": race,
			"world_x": cx,
			"world_z": cz,
			"is_alive": true,
			"profession": ruler.profession,
			"site_id": sites.size(),
			"civ_id": i,
			"family_id": fam_id,
			"dynasty_name": init_dyn_name
		})
		civ["ruler_id"] = hf_counter
		hf_counter += 1
		chronicle.add_event(1, "SUCCESSION", {"hf_name": ruler.name, "civ_name": civ_name})

		var site_name = namegen.generate_site_name(race).capitalize()
		var site = {
			"id": sites.size(),
			"name": "%s (%s)" % [site_name, civ_name],
			"civ_id": i,
			"x": cx,
			"z": cz,
			"population": 150,
			"founded": 1,
			"is_capital": true,
			"is_sacked": false
		}
		sites.append(site)
		chronicle.add_event(1, "FOUND_SITE", {"civ_name": civ_name, "site_name": site_name})

	for c1 in civs:
		for c2 in civs:
			if c1["id"] != c2["id"]:
				if c1["race"] == "goblin" or c2["race"] == "goblin":
					c1["relations"][c2["id"]] = rng.randi_range(-80, -30)
				else:
					c1["relations"][c2["id"]] = rng.randi_range(-20, 40)

	var beast_density_index: int = clampi(int(world_gen.setting_beast_density), 0, 2)
	var beast_density_multiplier: float = [0.60, 1.0, 1.65][beast_density_index]
	var world_area_scale: float = sqrt(float(world_gen.world_width * world_gen.world_depth)) / 256.0
	var target_beasts: int = clampi(roundi(8.0 * world_area_scale * beast_density_multiplier), 4, 72)
	var num_beasts: int = rng.randi_range(maxi(3, target_beasts - 2), target_beasts + 2)
	for _i in range(num_beasts):
		var beast_data = _generate_beast_instance(world_gen)
		var beast = DFHistoricalFigure.new(hf_counter, beast_data["name"], "megabeast", 0, -1, rng)
		beast.lifespan = 999999
		beast.profession = "Megabestia"
		beast.combat_power = beast_data["attack_damage"] * 0.5
		beast.add_deed("Descripcion: %s" % beast_data["description"])
		historical_figures.append(beast)
		beasts.append(beast)

		beast_instances.append({
			"hf_id": hf_counter,
			"name": beast_data["name"],
			"world_x": beast_data["world_x"],
			"world_z": beast_data["world_z"],
			"lair_x": beast_data["lair_x"],
			"lair_z": beast_data["lair_z"],
			"alive": true,
			"size": beast_data["appearance"]["size"],
			"glyph": beast_data["appearance"]["glyph"],
			"color": beast_data["appearance"]["color"],
			"color_secondary": beast_data["appearance"]["color_secondary"],
			"glow": beast_data["appearance"]["glow"],
			"glow_color": beast_data["appearance"]["glow_color"],
			"is_hostile": true,
			"attack_damage": beast_data["attack_damage"],
			"abilities": beast_data["abilities"],
			"materials": beast_data["materials"],
			"body": beast_data["body"],
			"description": beast_data["description"]
		})
		hf_counter += 1

	initial_megabeast_count = beast_instances.size()
	current_age_label = get_current_age_label()

# ============================================================================
# SIMULATION
# ============================================================================
func _simulate_year(year: int, world_gen: Object) -> void:
	var alive_hfs = []
	for hf in historical_figures:
		if hf.is_alive(year):
			if hf.check_old_age(year):
				chronicle.add_event(year, "DEATH_OLD_AGE", {"hf_name": hf.name, "age": year - hf.birth_year})
				_register_death(hf, year, world_gen)
				if hf.is_ruler:
					_elect_new_ruler(hf.civ_id, year)
			else:
				alive_hfs.append(hf)

	_tick_diplomacy(year)
	_process_family_affairs(year)

	for civ in civs:
		if not civ["is_dead"] and civ["population"] > 0:
			civ["population"] += int(civ["population"] * 0.03)
			var active = _get_civ_sites(civ["id"])
			if civ["population"] > 300 * (active.size() + 1) and rng.randf() < 0.15:
				_found_site(civ, year, world_gen)

	if year % 5 == 0 and rng.randf() < 0.2:
		_generate_random_event(year)

	_process_warfare(year)
	_process_strange_moods(year)
	_process_beast_attacks(year)

	var calculated_age: String = get_current_age_label()
	if calculated_age != current_age_label:
		var previous_age: String = current_age_label
		current_age_label = calculated_age
		chronicle.add_event(year, "AGE_CHANGE", {"previous_age": previous_age, "age_name": current_age_label})

func get_alive_megabeast_count() -> int:
	var alive: int = 0
	for beast_variant in beast_instances:
		if beast_variant is Dictionary and bool((beast_variant as Dictionary).get("alive", false)):
			alive += 1
	return alive

func get_current_age_label() -> String:
	var alive_beasts: int = get_alive_megabeast_count()
	var total_beasts: int = maxi(1, initial_megabeast_count if initial_megabeast_count > 0 else beast_instances.size())
	var beast_ratio: float = float(alive_beasts) / float(total_beasts)
	if beast_ratio > 0.66:
		return "Edad del Mito"
	if beast_ratio > 0.33:
		return "Edad de las Leyendas"
	if alive_beasts > 0:
		return "Edad de los Héroes"

	var total_population: int = 0
	var population_by_race: Dictionary = {}
	for civ_variant in civs:
		if not civ_variant is Dictionary:
			continue
		var civ: Dictionary = civ_variant
		if bool(civ.get("is_dead", false)):
			continue
		var population: int = maxi(0, int(civ.get("population", 0)))
		var race: String = str(civ.get("race", "human"))
		total_population += population
		population_by_race[race] = int(population_by_race.get(race, 0)) + population
	var dominant_race: String = ""
	var dominant_population: int = 0
	for race_variant in population_by_race.keys():
		var race_key: String = str(race_variant)
		var race_population: int = int(population_by_race[race_key])
		if race_population > dominant_population:
			dominant_population = race_population
			dominant_race = race_key
	if total_population > 0 and float(dominant_population) / float(total_population) >= 0.55:
		match dominant_race:
			"dwarf": return "Edad de los Enanos"
			"elf": return "Edad de los Elfos"
			"goblin": return "Edad de los Goblins"
			"human": return "Edad de los Humanos"
	return "Edad de las Civilizaciones"

func _generate_random_event(year: int) -> void:
	var event_types = ["PLAGUE", "FAMINE", "PLENTY", "DISCOVERY", "FESTIVAL", "MIGRATION"]
	var et = event_types[rng.randi() % event_types.size()]
	var target_civ = civs[rng.randi() % civs.size()] if not civs.is_empty() else null
	if target_civ == null: return

	match et:
		"PLAGUE":
			var lost = int(target_civ["population"] * rng.randf_range(0.1, 0.3))
			target_civ["population"] = maxi(10, target_civ["population"] - lost)
			chronicle.add_event(year, "PLAGUE", {"civ_name": target_civ["name"], "lost": lost})
		"FAMINE":
			var lost_593 = int(target_civ["population"] * rng.randf_range(0.05, 0.15))
			target_civ["population"] = maxi(10, target_civ["population"] - lost_593)
			chronicle.add_event(year, "FAMINE", {"civ_name": target_civ["name"], "lost_593": lost_593})
		"PLENTY":
			var gain = int(target_civ["population"] * rng.randf_range(0.05, 0.15))
			target_civ["population"] += gain
			chronicle.add_event(year, "PLENTY", {"civ_name": target_civ["name"], "gain": gain})
		"DISCOVERY":
			var discovery_types = ["una nueva tecnica de mineria", "la escritura ancestral", "un nuevo metal", "la domesticacion de bestias", "la agricultura en roca"]
			var d = discovery_types[rng.randi() % discovery_types.size()]
			chronicle.add_event(year, "DISCOVERY", {"civ_name": target_civ["name"], "discovery": d})
		"FESTIVAL":
			chronicle.add_event(year, "FESTIVAL", {"civ_name": target_civ["name"]})
		"MIGRATION":
			var migrants = rng.randi_range(5, 20)
			target_civ["population"] += migrants
			chronicle.add_event(year, "MIGRATION", {"civ_name": target_civ["name"], "migrants": migrants})

func _register_death(hf: Object, year: int, world_gen: Object) -> void:
	for i in range(historical_npcs.size()):
		if historical_npcs[i]["hf_id"] == hf.id:
			var npc = historical_npcs[i]
			npc["is_alive"] = false
			var dyn_name = _get_dynasty_name(hf.id)
			corpse_sites.append({
				"hf_id": hf.id,
				"name": hf.name,
				"race": hf.race,
				"death_year": year,
				"world_x": npc["world_x"],
				"world_z": npc["world_z"],
				"profession": hf.profession,
				"was_ruler": hf.is_ruler,
				"family_id": hf.family_id,
				"dynasty_name": dyn_name
			})

			if hf.is_ruler:
				var civ = _get_civ(hf.civ_id)
				if not civ.is_empty():
					var heir = _find_heir(hf, civ)
					if heir != null:
						var heir_dyn = _get_dynasty_name(heir.id)
						chronicle.add_event(year, "INHERITANCE", {
							"deceased": hf.name,
							"heir": heir.name,
							"dynasty": heir_dyn if heir_dyn != "" else "desconocida",
							"civ": civ["name"]
						})

			for ai in range(artifact_instances.size()):
				if artifact_instances[ai]["creator_id"] == hf.id:
					var heir_645 = null
					if not hf.children.is_empty():
						for child_id in hf.children:
							var ch = _get_hf(child_id)
							if ch != null and ch.is_alive(-1):
								heir_645 = ch
								break
					if heir_645 == null and hf.family_id >= 0 and family_db.has(hf.family_id):
						for mid in family_db[hf.family_id]["members"]:
							if mid == hf.id: continue
							var m = _get_hf(mid)
							if m != null and m.is_alive(-1):
								heir_645 = m
								break
					if heir_645 != null:
						artifact_instances[ai]["inherited_by"] = heir_645.id
						artifact_instances[ai]["inherited_name"] = heir_645.name
						if family_db.has(hf.family_id):
							var held = family_db[hf.family_id]["artifacts_held"]
							if not artifact_instances[ai]["art_id"] in held:
								held.append(artifact_instances[ai]["art_id"])
			return

func _update_npc_position(hf_id: int, world_x: int, world_z: int) -> void:
	for i in range(historical_npcs.size()):
		if historical_npcs[i]["hf_id"] == hf_id:
			historical_npcs[i]["world_x"] = world_x
			historical_npcs[i]["world_z"] = world_z
			return

func _tick_diplomacy(year: int) -> void:
	for c1 in civs:
		if c1["is_dead"]: continue
		for c2_id in c1["relations"].keys():
			var c2 = _get_civ(c2_id)
			if c2 == null or c2["is_dead"]: continue
			c1["relations"][c2_id] += rng.randi_range(-5, 5)
			c1["relations"][c2_id] = clampi(c1["relations"][c2_id], -100, 100)
			if c1["relations"][c2_id] < -60 and not _is_at_war(c1["id"], c2_id):
				_declare_war(c1, c2, year)
			elif c1["relations"][c2_id] > 80 and rng.randf() < 0.05:
				chronicle.add_event(year, "ALLIANCE", {"civ_a": c1["name"], "civ_b": c2["name"]})

func _process_warfare(year: int) -> void:
	var resolved_wars = []
	for war in active_wars:
		var c1 = _get_civ(war["civ_a"])
		var c2 = _get_civ(war["civ_b"])
		if c1 == null or c1["is_dead"] or c2 == null or c2["is_dead"]:
			resolved_wars.append(war)
			continue
		if rng.randf() < 0.3:
			_resolve_battle(c1, c2, year)
		war["duration"] += 1
		if war["duration"] > 5 and rng.randf() < 0.15:
			chronicle.add_event(year, "WAR_PEACE", {"civ_a": c1["name"], "civ_b": c2["name"]})
			resolved_wars.append(war)
			c1["relations"][c2["id"]] = -20
			c2["relations"][c1["id"]] = -20
	for r in resolved_wars:
		active_wars.erase(r)

func _resolve_battle(attacker: Dictionary, defender: Dictionary, year: int) -> void:
	var defender_sites_list = _get_civ_sites(defender["id"])
	if defender_sites_list.is_empty():
		return
	var target_site = defender_sites_list[rng.randi() % defender_sites_list.size()]
	var attack_power = rng.randi_range(50, 300)
	var defend_power = target_site["population"] + rng.randi_range(20, 150)
	var att_leader = _get_civ_champion(attacker["id"])
	var def_leader = _get_civ_champion(defender["id"])
	var battle_x = target_site["x"]
	var battle_z = target_site["z"]

	if att_leader != null and def_leader != null and rng.randf() < 0.5:
		if rng.randf() < 0.5:
			def_leader.death_year = year
			chronicle.add_event(year, "HERO_DUEL", {"site_name": target_site["name"], "champion_name": att_leader.name, "victim_name": def_leader.name})
			att_leader.kills += 1
			_register_death(def_leader, year, null)
			_update_npc_position(def_leader.id, battle_x, battle_z)
			attack_power += 50
			defend_power -= 30
		else:
			att_leader.death_year = year
			chronicle.add_event(year, "HERO_DUEL", {"site_name": target_site["name"], "champion_name": def_leader.name, "victim_name": att_leader.name})
			def_leader.kills += 1
			_register_death(att_leader, year, null)
			_update_npc_position(att_leader.id, battle_x, battle_z)
			defend_power += 50
			attack_power -= 30

	if attack_power > defend_power:
		var old_pop = target_site["population"]
		target_site["population"] = int(old_pop * 0.4)
		target_site["civ_id"] = attacker["id"]
		target_site["is_sacked"] = true
		attacker["population"] += int(old_pop * 0.3)
		chronicle.add_event(year, "BATTLE_CONQUEST", {"attacker_civ": attacker["name"], "site_name": target_site["name"], "defender_civ": defender["name"]})
		var def_ruler = _get_hf(defender["ruler_id"])
		if def_ruler != null and def_ruler.is_alive(year) and defender_sites_list[0]["id"] == target_site["id"]:
			def_ruler.death_year = year
			var killer_name = "el general " + att_leader.name if att_leader else "la armada enemiga"
			chronicle.add_event(year, "DEATH_BATTLE", {"victim_name": def_ruler.name, "killer_name": killer_name, "battle_site": target_site["name"]})
			_register_death(def_ruler, year, null)
			_update_npc_position(def_ruler.id, battle_x, battle_z)
			_elect_new_ruler(defender["id"], year)
	else:
		chronicle.add_event(year, "BATTLE_DEFENDED", {"defender_civ": defender["name"], "attacker_civ": attacker["name"], "site_name": target_site["name"]})

func _process_strange_moods(year: int) -> void:
	if rng.randf() < 0.12 and not historical_figures.is_empty():
		var hf = historical_figures[rng.randi() % historical_figures.size()]
		if hf.is_alive(year) and hf.race != "megabeast":
			var civ = _get_civ(hf.civ_id)
			if civ != null:
				var art_props = _generate_artifact_properties(hf.race, year)
				var lore = _generate_artifact_description(art_props, hf.name, year, civ["name"])

				var artifact = {
					"id": art_counter,
					"name": art_props["name"],
					"type": art_props["type"],
					"material": art_props["material"],
					"creator_id": hf.id,
					"site_id": -1,
					"year": year
				}
				artifacts.append(artifact)

				var art_world_x = civ["capital_x"]
				var art_world_z = civ["capital_z"]
				var art_site_id = -1
				var civ_sites = _get_civ_sites(civ["id"])
				if not civ_sites.is_empty():
					var chosen_site = civ_sites[rng.randi() % civ_sites.size()]
					art_world_x = chosen_site["x"]
					art_world_z = chosen_site["z"]
					art_site_id = chosen_site["id"]

				artifact_instances.append({
					"art_id": art_counter,
					"name": art_props["name"],
					"type": art_props["type"],
					"material": art_props["material"],
					"creator_name": hf.name,
					"creator_id": hf.id,
					"year": year,
					"world_x": art_world_x,
					"world_z": art_world_z,
					"site_id": art_site_id,
					"glyph": art_props["glyph"],
					"color": art_props["color"],
					"item_category": art_props["item_category"],
					"is_lost": rng.randf() < 0.3,
					"lore": lore
				})
				if hf.family_id >= 0 and family_db.has(hf.family_id):
					var held = family_db[hf.family_id]["artifacts_held"]
					if not art_counter in held:
						held.append(art_counter)
				art_counter += 1
				chronicle.add_event(year, "ARTIFACT_CREATION", {
					"hf_name": hf.name,
					"civ_name": civ["name"],
					"art_name": art_props["name"],
					"art_type": art_props["type"],
					"art_material": art_props["material"]
				})

func _generate_artifact_properties(creator_race: String, year: int) -> Dictionary:
	var types = [
		{"type": "Espada", "glyph": "/", "concept": "SWORD", "item_category": "weapon"},
		{"type": "Escudo", "glyph": "[", "concept": "SHIELD", "item_category": "armor"},
		{"type": "Yelmo", "glyph": "^", "concept": "HELMET", "item_category": "armor"},
		{"type": "Corona", "glyph": "!", "concept": "CROWN", "item_category": "armor"},
		{"type": "Cetro", "glyph": "!", "concept": "SCEPTER", "item_category": "weapon"},
		{"type": "Martillo", "glyph": "\\", "concept": "HAMMER", "item_category": "weapon"},
		{"type": "Lanza", "glyph": "/", "concept": "SPEAR", "item_category": "weapon"},
		{"type": "Arco", "glyph": ")", "concept": "BOW", "item_category": "weapon"},
		{"type": "Anillo", "glyph": "o", "concept": "RING", "item_category": "armor"},
		{"type": "Amuleto", "glyph": "o", "concept": "AMULET", "item_category": "armor"},
	]
	var t = types[rng.randi() % types.size()]

	var material_entries = [
		{"name": "Acero", "color": Color("#88CCFF")},
		{"name": "Hierro", "color": Color("#CC6633")},
		{"name": "Oro", "color": Color("#FFD700")},
		{"name": "Plata", "color": Color("#C0C0C0")},
		{"name": "Bronce", "color": Color("#CD7F32")},
		{"name": "Cobre", "color": Color("#CC7733")},
		{"name": "Platino", "color": Color("#E5E4E2")},
		{"name": "Obsidiana", "color": Color("#202020")},
		{"name": "Marfil", "color": Color("#FFFDD0")},
		{"name": "Cristal", "color": Color("#AAFFFF")},
		{"name": "Adamantita", "color": Color("#FF44FF")},
	]
	var mat = material_entries[rng.randi() % material_entries.size()]

	var name = _generate_artifact_name_from_lang(t["concept"], creator_race)
	var suffix_chance = rng.randf()
	if suffix_chance < 0.2:
		var concepts = ["FOREVER", "NIGHT", "GOLD", "STORM", "FATE", "KING", "SOUL", "SHADOW", "BLOOD"]
		var c = concepts[rng.randi() % concepts.size()]
		var trans = namegen.translate_word(c, creator_race)
		if trans != "":
			name = "%s de %s" % [name, trans.capitalize()]
	elif suffix_chance < 0.35:
		var poetic = ["lo Inmemorial", "lo Eterno", "lo Sagrado", "lo Maldito", "lo Abisal", "lo Lunar"]
		name = "%s de %s" % [name, poetic[rng.randi() % poetic.size()]]

	return {
		"name": name,
		"type": t["type"],
		"glyph": t["glyph"],
		"item_category": t["item_category"],
		"material": mat["name"],
		"color": Color(
			clampf(mat["color"].r + rng.randf_range(-0.1, 0.1), 0.0, 1.0),
			clampf(mat["color"].g + rng.randf_range(-0.1, 0.1), 0.0, 1.0),
			clampf(mat["color"].b + rng.randf_range(-0.1, 0.1), 0.0, 1.0)
		)
	}

func _process_beast_attacks(year: int) -> void:
	if year % 8 == 0 and not sites.is_empty():
		var alive_bi = []
		for bi in range(beast_instances.size()):
			if beast_instances[bi]["alive"]:
				alive_bi.append(bi)
		if not alive_bi.is_empty():
			var bi_877 = alive_bi[rng.randi() % alive_bi.size()]
			var beast_rec = beast_instances[bi_877]
			var target_site = sites[rng.randi() % sites.size()]
			var civ = _get_civ(target_site["civ_id"])
			if civ == null: return
			beast_rec["world_x"] = target_site["x"]
			beast_rec["world_z"] = target_site["z"]
			var abilities_text = ""
			for a in beast_rec.get("abilities", []):
				abilities_text += " " + a["description"]
			chronicle.add_event(year, "BEAST_ATTACK", {"beast_name": beast_rec["name"], "site_name": target_site["name"]})

			var champion = _get_civ_champion(civ["id"])
			if champion != null and rng.randf() < 0.4:
				beast_rec["alive"] = false
				beast_rec["world_x"] = target_site["x"]
				beast_rec["world_z"] = target_site["z"]
				chronicle.add_event(year, "BEAST_DEATH", {"beast_name": beast_rec["name"], "killer_name": champion.name, "site_name": target_site["name"]})
				champion.kills += 1
				var new_work_year = year
				_generate_written_work(new_work_year)
			else:
				target_site["population"] = int(target_site["population"] * 0.6)
				if target_site["population"] < 10:
					target_site["population"] = 0

func _found_site(civ: Dictionary, year: int, world_gen: Object) -> void:
	var site_name: String = namegen.generate_site_name(civ["race"]).capitalize()
	var used_positions: Array = []
	for existing_variant in sites:
		if existing_variant is Dictionary:
			var existing: Dictionary = existing_variant
			used_positions.append(Vector2i(int(existing.get("x", 0)), int(existing.get("z", 0))))
	var origin := Vector2i(int(civ.get("capital_x", 0)), int(civ.get("capital_z", 0)))
	var site_pos: Vector2i = world_gen.find_site_near(str(civ.get("race", "human")), origin, used_positions) if world_gen.has_method("find_site_near") else origin
	var sx: int = site_pos.x
	var sz: int = site_pos.y
	var site = {
		"id": sites.size(),
		"name": site_name,
		"civ_id": civ["id"],
		"x": sx,
		"z": sz,
		"population": 60,
		"founded": year,
		"is_capital": false,
		"is_sacked": false
	}
	sites.append(site)
	chronicle.add_event(year, "FOUND_SITE", {"civ_name": civ["name"], "site_name": site_name})

func _elect_new_ruler(civ_id: int, year: int) -> void:
	var civ = _get_civ(civ_id)
	if civ == null: return

	var old_ruler_hf = _get_hf(civ["ruler_id"])
	var heir = null
	if old_ruler_hf != null:
		heir = _find_heir(old_ruler_hf, civ)

	if heir != null:
		heir.is_ruler = true
		heir.profession = "Rey" if civ["race"] != "goblin" else "Señor Demoníaco"
		civ["ruler_id"] = heir.id
		for i in range(historical_npcs.size()):
			if historical_npcs[i]["hf_id"] == heir.id:
				historical_npcs[i]["profession"] = heir.profession
				break
		var heir_dyn = _get_dynasty_name(heir.id)
		chronicle.add_event(year, "SUCCESSION_BLOOD", {
			"hf_name": heir.name,
			"civ_name": civ["name"],
			"dynasty": heir_dyn if heir_dyn != "" else "desconocida",
			"predecessor": old_ruler_hf.name if old_ruler_hf != null else "desconocido"
		})
		if heir.family_id >= 0 and family_db.has(heir.family_id):
			family_db[heir.family_id]["current_head_id"] = heir.id
		return

	var ruler_name = namegen.generate_dwarf_name() if civ["race"] == "dwarf" else namegen.generate_site_name(civ["race"])
	var ruler = DFHistoricalFigure.new(hf_counter, ruler_name, civ["race"], year - 20, civ_id, rng)
	ruler.is_ruler = true
	ruler.profession = "Rey" if civ["race"] != "goblin" else "Señor Demoníaco"
	ruler.site_id = -1
	var fam_id = -1
	if old_ruler_hf != null and old_ruler_hf.family_id >= 0 and family_db.has(old_ruler_hf.family_id):
		fam_id = old_ruler_hf.family_id
		ruler.family_id = fam_id
		family_db[fam_id]["members"].append(ruler.id)
		family_db[fam_id]["current_head_id"] = ruler.id
	else:
		fam_id = _create_dynasty(ruler, year, civ["race"])
	historical_figures.append(ruler)
	var dyn_name_ruler = family_db[fam_id]["dynasty_name"] if family_db.has(fam_id) else ""
	historical_npcs.append({
		"hf_id": hf_counter,
		"name": ruler_name,
		"race": civ["race"],
		"world_x": civ["capital_x"],
		"world_z": civ["capital_z"],
		"is_alive": true,
		"profession": ruler.profession,
		"site_id": -1,
		"civ_id": civ_id,
		"family_id": fam_id,
		"dynasty_name": dyn_name_ruler
	})
	civ["ruler_id"] = hf_counter
	hf_counter += 1
	chronicle.add_event(year, "SUCCESSION", {"hf_name": ruler.name, "civ_name": civ["name"]})

func _get_civ_champion(civ_id: int) -> Object:
	var candidates = []
	for hf in historical_figures:
		if hf.civ_id == civ_id and hf.death_year == -1 and hf.race != "megabeast":
			candidates.append(hf)
	if candidates.is_empty():
		return null
	return candidates[rng.randi() % candidates.size()]

func _is_at_war(c1_id: int, c2_id: int) -> bool:
	for war in active_wars:
		if (war["civ_a"] == c1_id and war["civ_b"] == c2_id) or (war["civ_a"] == c2_id and war["civ_b"] == c1_id):
			return true
	return false

func _declare_war(c1: Dictionary, c2: Dictionary, year: int) -> void:
	active_wars.append({"civ_a": c1["id"], "civ_b": c2["id"], "duration": 0})
	chronicle.add_event(year, "WAR_DECLARED", {"civ_a": c1["name"], "civ_b": c2["name"]})

func _get_civ(id: int) -> Dictionary:
	for c in civs:
		if c["id"] == id:
			return c
	return {}

func _get_civ_sites(civ_id: int) -> Array:
	var res = []
	for s in sites:
		if s["civ_id"] == civ_id and s["population"] > 0:
			res.append(s)
	return res

func _get_hf(id: int) -> Object:
	for hf in historical_figures:
		if hf.id == id:
			return hf
	return null

func _translate_race_plural(race: String) -> String:
	match race.to_lower():
		"dwarf": return "Enanos"
		"elf": return "Elfos"
		"human": return "Humanos"
		"goblin": return "Goblins"
	return "Seres"

# ============================================================================
# GENEALOGY / FAMILY / DYNASTY
# ============================================================================
func _generate_dynasty_name(race: String) -> String:
	var base = namegen.generate_dwarf_name() if race == "dwarf" else namegen.generate_site_name(race)
	var suffixes = ["idas", "idas", "iak", "ung", "heim", "dor", "mar", "oth", "ar", "varr", "klan"]
	var suffix = suffixes[rng.randi() % suffixes.size()]
	var name = base.capitalize() + suffix
	if name.length() > 18:
		name = name.substr(0, rng.randi_range(8, 16))
	return name

func _create_dynasty(founder_hf: Object, year: int, race: String) -> int:
	var fam_id = next_family_id
	next_family_id += 1
	var dyn_name = _generate_dynasty_name(race)
	family_db[fam_id] = {
		"id": fam_id,
		"dynasty_name": dyn_name,
		"founder_id": founder_hf.id,
		"founded_year": year,
		"members": [founder_hf.id],
		"current_head_id": founder_hf.id,
		"race": race,
		"artifacts_held": []
	}
	founder_hf.family_id = fam_id
	chronicle.add_event(year, "DYNASTY_FOUNDED", {"dynasty": dyn_name, "founder": founder_hf.name, "race": race})
	return fam_id

func _process_family_affairs(year: int) -> void:
	_process_marriages(year)
	_process_births(year)

func _find_adult_unmarried_hfs(year: int, civ_id: int) -> Array:
	var candidates = []
	for hf in historical_figures:
		if hf.is_alive(year) and hf.civ_id == civ_id and hf.race != "megabeast":
			if hf.spouse_id == -1 and year - hf.birth_year >= 15:
				candidates.append(hf)
	return candidates

func _process_marriages(year: int) -> void:
	for civ in civs:
		if civ["is_dead"]: continue
		var candidates = _find_adult_unmarried_hfs(year, civ["id"])
		if candidates.size() < 2: continue

		var pairs_to_try = min(candidates.size() / 2, 3)
		for _p in range(pairs_to_try):
			var idx_a = rng.randi() % candidates.size()
			var hf_a = candidates[idx_a]
			candidates.remove_at(idx_a)
			if candidates.is_empty(): break
			var idx_b = rng.randi() % candidates.size()
			var hf_b = candidates[idx_b]
			candidates.remove_at(idx_b)

			if hf_a.spouse_id != -1 or hf_b.spouse_id != -1 or hf_a.id == hf_b.id:
				continue
			if rng.randf() < 0.25:
				hf_a.spouse_id = hf_b.id
				hf_b.spouse_id = hf_a.id

				var fam_id = -1
				if hf_a.family_id >= 0 and family_db.has(hf_a.family_id):
					fam_id = hf_a.family_id
				elif hf_b.family_id >= 0 and family_db.has(hf_b.family_id):
					fam_id = hf_b.family_id
				else:
					fam_id = _create_dynasty(hf_a, year, civ["race"])

				if hf_a.family_id != fam_id:
					hf_a.family_id = fam_id
					if family_db.has(fam_id) and not hf_a.id in family_db[fam_id]["members"]:
						family_db[fam_id]["members"].append(hf_a.id)
				if hf_b.family_id != fam_id:
					hf_b.family_id = fam_id
					if family_db.has(fam_id) and not hf_b.id in family_db[fam_id]["members"]:
						family_db[fam_id]["members"].append(hf_b.id)

				var dyn_name = family_db[fam_id]["dynasty_name"] if family_db.has(fam_id) else "desconocida"
				chronicle.add_event(year, "MARRIAGE", {
					"hf_a": hf_a.name, "hf_b": hf_b.name,
					"civ": civ["name"], "family": dyn_name
				})

func _process_births(year: int) -> void:
	var processed_couples: Dictionary = {}
	for hf in historical_figures:
		if not hf.is_alive(year): continue
		if hf.race == "megabeast": continue
		if hf.spouse_id == -1: continue
		var spouse = _get_hf(hf.spouse_id)
		if spouse == null or not spouse.is_alive(year): continue

		var couple_key = "%d_%d" % [mini(hf.id, spouse.id), maxi(hf.id, spouse.id)]
		if processed_couples.has(couple_key): continue
		processed_couples[couple_key] = true

		if rng.randf() < 0.12:
			var civ = _get_civ(hf.civ_id)
			if civ.is_empty(): continue
			var race = hf.race
			var child_name = namegen.generate_dwarf_name() if race == "dwarf" else namegen.generate_site_name(race)
			var child = DFHistoricalFigure.new(hf_counter, child_name, race, year, hf.civ_id, rng)
			child.family_id = hf.family_id if hf.family_id >= 0 else spouse.family_id
			historical_figures.append(child)

			hf.children.append(child.id)
			spouse.children.append(child.id)

			if child.family_id >= 0 and family_db.has(child.family_id):
				family_db[child.family_id]["members"].append(child.id)
			elif child.family_id < 0:
				var new_fam = _create_dynasty(child, year, race)
				child.family_id = new_fam
				hf.family_id = new_fam
				spouse.family_id = new_fam
				if family_db.has(new_fam):
					family_db[new_fam]["members"].append(hf.id)
					family_db[new_fam]["members"].append(spouse.id)

			var civ_sites_list = _get_civ_sites(hf.civ_id)
			var site_x = civ["capital_x"]
			var site_z = civ["capital_z"]
			if not civ_sites_list.is_empty():
				var s = civ_sites_list[rng.randi() % civ_sites_list.size()]
				site_x = s["x"]
				site_z = s["z"]

			var dyn_name = family_db[child.family_id]["dynasty_name"] if child.family_id >= 0 and family_db.has(child.family_id) else ""
			historical_npcs.append({
				"hf_id": hf_counter,
				"name": child_name,
				"race": race,
				"world_x": site_x,
				"world_z": site_z,
				"is_alive": true,
				"profession": "Niño",
				"site_id": -1,
				"civ_id": hf.civ_id,
				"family_id": child.family_id,
				"dynasty_name": dyn_name
			})
			hf_counter += 1
			chronicle.add_event(year, "BIRTH", {
				"child_name": child_name,
				"parent_a": hf.name,
				"parent_b": spouse.name,
				"family": dyn_name if dyn_name != "" else "desconocida",
				"civ": civ["name"]
			})

			var dynasty = family_db.get(child.family_id)
			if dynasty != null and dynasty["current_head_id"] == -1:
				dynasty["current_head_id"] = child.id

func _find_heir(deceased_hf: Object, civ: Dictionary) -> Object:
	var candidates = []
	for child_id in deceased_hf.children:
		var child = _get_hf(child_id)
		if child != null and child.is_alive(-1):
			candidates.append(child)
	if not candidates.is_empty():
		candidates.sort_custom(func(a, b): return a.id < b.id)
		return candidates[0]
	var same_family = []
	if deceased_hf.family_id >= 0 and family_db.has(deceased_hf.family_id):
		for mid in family_db[deceased_hf.family_id]["members"]:
			if mid == deceased_hf.id: continue
			var m = _get_hf(mid)
			if m != null and m.is_alive(-1):
				same_family.append(m)
		if not same_family.is_empty():
			return same_family[rng.randi() % same_family.size()]
	return null

func _get_dynasty_name(hf_id: int) -> String:
	for hf in historical_figures:
		if hf.id == hf_id and hf.family_id >= 0 and family_db.has(hf.family_id):
			return family_db[hf.family_id]["dynasty_name"]
	return ""

func _get_family_tree_summary(family_id: int) -> String:
	if not family_db.has(family_id):
		return "Familia desconocida."
	var fam = family_db[family_id]
	var text = "=== Dinastia %s ===\n" % fam["dynasty_name"]
	text += "Fundada en el anio %d por %s.\n" % [fam["founded_year"], _get_hf_name(fam["founder_id"])]
	var alive = []
	var dead = []
	for mid in fam["members"]:
		var m = _get_hf(mid)
		if m == null: continue
		if m.is_alive(-1):
			alive.append(m)
		else:
			dead.append(m)
	text += "Miembros vivos: %d\n" % alive.size()
	if not alive.is_empty():
		text += "Vivos: "
		var names = []
		for a in alive:
			var title = "Rey " if a.is_ruler else ""
			names.append(title + a.name)
		text += ", ".join(names) + "\n"
	text += "Fallecidos: %d\n" % dead.size()
	var head = _get_hf(fam["current_head_id"])
	if head != null:
		text += "Cabeza actual: %s\n" % head.name
	if not fam["artifacts_held"].is_empty():
		text += "Reliquias familiares: %d\n" % fam["artifacts_held"].size()
	return text

func _get_hf_name(hf_id: int) -> String:
	for hf in historical_figures:
		if hf.id == hf_id:
			return hf.name
	return "Desconocido"

# ============================================================================
# MATERIALIZATION
# ============================================================================
func materialize_near_embark(world: Object, world_gen: Object, embark_cursor: Vector2i) -> int:
	var items_spawned = 0
	var creatures_spawned = 0
	var corpses_spawned = 0
	var local_w = world.width
	var local_d = world.depth

	for ai in artifact_instances:
		var local_pos = _world_to_local(ai["world_x"], ai["world_z"], world_gen, embark_cursor, local_w, local_d)
		if local_pos.x < 0:
			continue
		if world.is_blocked(local_pos) or world.is_water(local_pos):
			var surface_h = world.get_surface_height(local_pos.x, local_pos.z)
			local_pos = Vector3i(local_pos.x, surface_h, local_pos.z)
			if world.is_blocked(local_pos) or world.is_water(local_pos):
				continue

		var item = DFItem.new(local_pos, ai["name"], ai.get("item_category", "weapon"), 0, ai["glyph"], ai["color"])
		item.is_artifact = true
		item.artifact_name = ai["name"]
		item.artifact_creation_year = ai["year"]
		item.quality = DFItem.QualityLevel.ARTIFACT
		item.base_value = 500 + rng.randi_range(100, 3000)
		item.total_value = item.base_value
		var lore = ai.get("lore", "Forjado en el anio %d por %s." % [ai["year"], ai.get("creator_name", "desconocido")])
		if ai.has("inherited_by") and ai.get("inherited_name", "") != "":
			lore += " Herencia de %s, pasado a %s." % [ai.get("creator_name", "desconocido"), ai["inherited_name"]]
		item.artifact_lore = lore
		world.entities.append(item)
		items_spawned += 1

	for bi in beast_instances:
		if not bi["alive"]:
			var local_pos_1284 = _world_to_local(bi["world_x"], bi["world_z"], world_gen, embark_cursor, local_w, local_d)
			if local_pos_1284.x < 0:
				continue
			if world.is_blocked(local_pos_1284) or world.is_water(local_pos_1284):
				continue
			var body_info = bi.get("body", {})
			var body_desc = bi.get("description", "Los restos de una bestia legendaria.")
			var corpse = DFItem.new(local_pos_1284, "Cadaver de %s" % bi["name"], "corpse", 0, "%", Color("#664400"))
			corpse.is_corpse = true
			corpse.is_organic = true
			corpse.decay_time = 500
			corpse.artifact_lore = body_desc
			world.entities.append(corpse)
			corpses_spawned += 1
		else:
			var lair_pos = _world_to_local(bi["lair_x"], bi["lair_z"], world_gen, embark_cursor, local_w, local_d)
			if lair_pos.x < 0:
				var roam_pos = _world_to_local(bi["world_x"], bi["world_z"], world_gen, embark_cursor, local_w, local_d)
				if roam_pos.x < 0:
					continue
				lair_pos = roam_pos
			if world.is_blocked(lair_pos) or world.is_water(lair_pos):
				var surf_h = world.get_surface_height(lair_pos.x, lair_pos.z)
				lair_pos = Vector3i(lair_pos.x, surf_h, lair_pos.z)
				if world.is_blocked(lair_pos) or world.is_water(lair_pos):
					continue
			var color = bi.get("color", Color.RED)
			var creature = DFCreature.new(lair_pos, bi["name"].to_lower().replace(" ", "_"), bi.get("glyph", "D"), color, bi.get("size", "mega"))
			creature.name = bi["name"]
			creature.is_hostile = bi.get("is_hostile", true)
			creature.combat_skill = 10.0
			creature.attack_damage = bi.get("attack_damage", 20.0)
			creature.health = 1.0
			creature.territory_center = lair_pos
			creature.home_pos = lair_pos
			creature.ai_state = DFCreature.AIState.IDLE
			creature.set_meta("beast_instance_id", bi.get("hf_id", -1))
			world.entities.append(creature)
			creatures_spawned += 1

	for cs in corpse_sites:
		var local_pos_1325 = _world_to_local(cs["world_x"], cs["world_z"], world_gen, embark_cursor, local_w, local_d)
		if local_pos_1325.x < 0:
			continue
		if world.is_blocked(local_pos_1325) or world.is_water(local_pos_1325):
			continue
		var epitaph = "Aqui yace %s, %s, caido en el anio %d." % [cs["name"], cs["profession"], cs["death_year"]]
		if cs["was_ruler"]:
			epitaph += " Gobernante de su pueblo."
		var dyn_name_cs = cs.get("dynasty_name", "")
		if dyn_name_cs != "":
			epitaph += " De la dinastia %s." % dyn_name_cs
		if cs.get("family_id", -1) >= 0 and family_db.has(cs["family_id"]):
			var fam = family_db[cs["family_id"]]
			var living_members = 0
			for mid in fam["members"]:
				if mid == cs["hf_id"]: continue
				var m = _get_hf(mid)
				if m != null and m.is_alive(-1):
					living_members += 1
			if living_members > 0:
				epitaph += " Le sobreviven %d miembros de su linaje." % living_members
		var grave = DFItem.new(local_pos_1325, "Tumba de %s" % cs["name"], "decoration", 0, "+", Color("#AAAAAA"))
		grave.base_value = 50
		grave.total_value = 50
		grave.artifact_lore = epitaph
		world.entities.append(grave)
		corpses_spawned += 1

	var local_books = []
	for w in written_works:
		var author_civ = -1
		for hf in historical_figures:
			if hf.id == w["author_id"]:
				author_civ = hf.civ_id
				break
		if author_civ < 0:
			continue
		var civ = _get_civ(author_civ)
		if civ.is_empty():
			continue
		var book_pos = _world_to_local(civ["capital_x"], civ["capital_z"], world_gen, embark_cursor, local_w, local_d)
		if book_pos.x < 0:
			continue
		var book_item = DFItem.new(book_pos, w["title"], "tool", 0, "=", Color("#FFDD88"))
		var author_dynasty = ""
		for hf_1370 in historical_figures:
			if hf_1370.id == w["author_id"]:
				author_dynasty = _get_dynasty_name(hf_1370.id)
				break
		var dyn_line = ""
		if author_dynasty != "":
			dyn_line = " Perteneciente a la dinastia %s." % author_dynasty
		book_item.artifact_lore = "Un %s escrito por %s en el anio %d. Trata sobre %s.%s" % [w["genre"], w["author_name"], w["year"], w["subject_name"], dyn_line]
		book_item.base_value = 30
		book_item.total_value = 30
		world.entities.append(book_item)
		local_books.append(book_item)
		items_spawned += 1

	return items_spawned + creatures_spawned + corpses_spawned

func _world_to_local(world_x: int, world_z: int, world_gen: Object, embark_cursor: Vector2i, local_w: int, local_d: int) -> Vector3i:
	var half_win = 3.5
	var dx = world_x - embark_cursor.x
	var dz = world_z - embark_cursor.y
	if abs(dx) > half_win or abs(dz) > half_win:
		return Vector3i(-1, -1, -1)
	var margin = 12
	var scale = (local_w - 2.0 * margin) / (2.0 * half_win)
	var lx = int(local_w / 2.0 + dx * scale)
	var lz = int(local_d / 2.0 + dz * scale)
	if lx < margin or lx >= local_w - margin or lz < margin or lz >= local_d - margin:
		return Vector3i(-1, -1, -1)
	var sy = 3
	if world_gen != null and world_gen.elevation_map.size() > 0:
		var wgx = clampi(world_x, 0, world_gen.world_width - 1)
		var wgz = clampi(world_z, 0, world_gen.world_depth - 1)
		sy = clampi(world_gen.elevation_map[wgz][wgx], 2, 12)
	return Vector3i(lx, sy, lz)
