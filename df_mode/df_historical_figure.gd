extends RefCounted
class_name DFHistoricalFigure

# ===========================================================================================
# FIGURA HISTÓRICA - Dwarf Fortress Style
# Personas de la historia del mundo: reyes, héroes, asesinos, nigromantes, bestias legendarias
# Cada figura tiene una biografía generada algorítmicamente en español
# ===========================================================================================

enum Disposition {
	FRIENDLY,    # Amistoso con la fortaleza
	NEUTRAL,     # Neutral
	HOSTILE,     # Hostil
	ALLIED,      # Aliado formal
	AT_WAR,      # En guerra
}

enum Personality {
	BRAVE,       # Valiente - busca combate
	COWARDLY,    # Cobarde - huye del peligro
	CUNNING,     # Astuto - prefiere tácticas
	RUTHLESS,    # Despiadado - no da cuartel
	NOBLE,       # Noble - sigue el código de honor
	MELANCHOLIC, # Melancólico - tendencias oscuras
	VISIONARY,   # Visionario - construye imperios
}

var id: int = -1
var name: String = ""
var race: String = ""
var birth_year: int = 0
var death_year: int = -1  # -1 = vivo
var civ_id: int = -1
var site_id: int = -1
var death_site_id: int = -1

var is_ruler: bool = false
var is_hero: bool = false
var is_villain: bool = false
var is_necromancer: bool = false
var is_werewolf: bool = false  # Puede estar maldito
var is_vampire: bool = false   # Vampiro histórico

var profession: String = "Aldeano"
var personality: int = Personality.BRAVE
var disposition: int = Disposition.NEUTRAL
var kills: int = 0
var artifacts_created: Array = []  # Nombres de reliquias forjadas
var sites_founded: Array = []
var battles_won: int = 0
var battles_lost: int = 0
var children: Array = []  # IDs de hijos
var spouse_id: int = -1
var family_id: int = -1  # ID de la dinastía/familia
var notable_deeds: Array = []  # Strings de hazañas en español

var lifespan: int = 80
var is_immortal: bool = false

# Stats de combate histórico (para resolver batallas)
var combat_power: float = 5.0
var leadership: float = 1.0  # Multiplica el poder del ejército que comanda

func _init(_id: int, _name: String, _race: String, _birth: int, _civ: int, rng: RandomNumberGenerator):
	id = _id
	name = _name
	race = _race
	birth_year = _birth
	civ_id = _civ
	
	# Asignar esperanza de vida según raza
	match race:
		"dwarf":     lifespan = rng.randi_range(150, 200)
		"elf":       lifespan = 999999; is_immortal = true
		"goblin":    lifespan = 999999; is_immortal = true
		"human":     lifespan = rng.randi_range(55, 90)
		"megabeast": lifespan = 999999; is_immortal = true
		_:           lifespan = rng.randi_range(60, 100)
	
	# Personalidad aleatoria
	personality = rng.randi() % 7
	
	# Stats de combate aleatorios
	combat_power = rng.randf_range(2.0, 12.0)
	leadership = rng.randf_range(0.5, 2.5)
	
	# Maldiciones raras (1% vampiro, 0.5% hombre lobo)
	if rng.randf() < 0.01:
		is_vampire = true
		lifespan = 999999
		is_immortal = true
		combat_power *= 2.0
		notable_deeds.append("Fue maldecido con la inmortalidad vampírica")
	elif rng.randf() < 0.005:
		is_werewolf = true
		combat_power *= 1.5
		notable_deeds.append("Fue mordido por una criatura de la noche")

func is_alive(_current_year: int = -1) -> bool:
	return death_year == -1

func check_old_age(current_year: int) -> bool:
	if death_year != -1: return false
	if is_immortal: return false
	if current_year - birth_year >= lifespan:
		death_year = current_year
		return true
	return false

func get_age(current_year: int) -> int:
	if death_year != -1:
		return death_year - birth_year
	return current_year - birth_year

func add_deed(deed: String) -> void:
	notable_deeds.append(deed)
	if notable_deeds.size() > 20:
		notable_deeds.pop_front()

func get_title() -> String:
	if is_ruler:
		match race:
			"dwarf":  return "Rey"
			"elf":    return "Señor del Bosque"
			"goblin": return "Gran Señor de Guerra"
			"human":  return "Rey"
		return "Gobernante"
	if is_necromancer: return "Nigromante"
	if is_hero and kills > 10: return "Campeón Legendario"
	if is_hero: return "Héroe"
	if is_villain: return "Villano"
	if is_vampire: return "Señor Vampiro"
	if is_werewolf: return "Hombre Lobo"
	return profession

func get_personality_name() -> String:
	match personality:
		Personality.BRAVE:       return "Valiente"
		Personality.COWARDLY:    return "Cobarde"
		Personality.CUNNING:     return "Astuto"
		Personality.RUTHLESS:    return "Despiadado"
		Personality.NOBLE:       return "Noble"
		Personality.MELANCHOLIC: return "Melancólico"
		Personality.VISIONARY:   return "Visionario"
	return "Normal"

func get_combat_modifier() -> float:
	# Modificador de combate basado en personalidad
	match personality:
		Personality.BRAVE:    return 1.3
		Personality.COWARDLY: return 0.6
		Personality.RUTHLESS: return 1.5
		Personality.CUNNING:  return 1.1
		_:                    return 1.0

func get_full_biography(current_year: int) -> String:
	var bio = "=== %s '%s' ===\n" % [get_title(), name]
	bio += "Raza: %s | Edad: %d años" % [_translate_race(race), get_age(current_year)]
	if not is_alive():
		bio += " (fallecido)"
	bio += "\n"
	bio += "Personalidad: %s | Poder de combate: %.1f\n" % [get_personality_name(), combat_power]
	
	if kills > 0:
		bio += "Bajas confirmadas: %d\n" % kills
	if battles_won > 0:
		bio += "Batallas ganadas: %d | Perdidas: %d\n" % [battles_won, battles_lost]
	if not artifacts_created.is_empty():
		bio += "Reliquias forjadas: %s\n" % ", ".join(artifacts_created)
	if not sites_founded.is_empty():
		bio += "Asentamientos fundados: %s\n" % ", ".join(sites_founded)
	
	if is_vampire:
		bio += "[ADVERTENCIA: Esta figura es un vampiro inmortal]\n"
	if is_werewolf:
		bio += "[ADVERTENCIA: Esta figura padece la maldición del hombre lobo]\n"
	
	if not notable_deeds.is_empty():
		bio += "\nHazañas notables:\n"
		for deed in notable_deeds.slice(-5):  # Últimas 5
			bio += "  - %s\n" % deed
	
	return bio

func _translate_race(r: String) -> String:
	match r:
		"dwarf":     return "Enano"
		"elf":       return "Elfo"
		"goblin":    return "Goblin"
		"human":     return "Humano"
		"megabeast": return "Megabestia"
	return r.capitalize()
