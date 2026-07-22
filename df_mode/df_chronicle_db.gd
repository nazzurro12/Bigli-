extends RefCounted
class_name DFChronicleDB

# Base de datos relacional de eventos históricos de la fortaleza en español
var events: Array = []
var next_event_id: int = 1

func add_event(year: int, type: String, data: Dictionary) -> int:
	var evt: Dictionary = data.duplicate(true)
	evt["id"] = next_event_id
	next_event_id += 1
	evt["year"] = year
	evt["type"] = type
	if not evt.has("cause_ids"):
		evt["cause_ids"] = []
	if not evt.has("text"):
		evt["text"] = _generate_text(evt)
	events.append(evt)
	return int(evt["id"])

func get_events_for_year(year: int) -> Array:
	var res = []
	for e in events:
		if e["year"] == year:
			res.append(e)
	return res

func _generate_text(e: Dictionary) -> String:
	match e["type"]:
		"FOUND_CIV":
			var race_es = _translate_race(e.get("race", ""))
			return "En el año %d, se fundó la civilización de los %s conocida como '%s'." % [e["year"], race_es, e.get("civ_name", "")]
		"FOUND_SITE":
			return "En el año %d, la civilización '%s' fundó el asentamiento de '%s'." % [e["year"], e.get("civ_name", ""), e.get("site_name", "")]
		"DEATH_OLD_AGE":
			return "En el año %d, %s falleció pacíficamente de vejez a la edad de %d años." % [e["year"], e.get("hf_name", ""), e.get("age", 0)]
		"DEATH_BATTLE":
			return "En el año %d, %s cayó en combate a manos de %s durante la contienda en %s." % [e["year"], e.get("victim_name", ""), e.get("killer_name", ""), e.get("battle_site", "")]
		"SUCCESSION":
			return "En el año %d, %s ascendió al trono como gobernante de '%s'." % [e["year"], e.get("hf_name", ""), e.get("civ_name", "")]
		"BEAST_ATTACK":
			return "En el año %d, la megabestia legendaria '%s' atacó el asentamiento de '%s' sembrando el terror." % [e["year"], e.get("beast_name", ""), e.get("site_name", "")]
		"BEAST_DEATH":
			return "En el año %d, la temible bestia '%s' fue finalmente derrotada y ejecutada por el héroe %s en '%s'." % [e["year"], e.get("beast_name", ""), e.get("killer_name", ""), e.get("site_name", "")]
		"WAR_DECLARED":
			return "En el año %d, estalló la guerra: la civilización '%s' declaró formalmente las hostilidades contra '%s'." % [e["year"], e.get("civ_a", ""), e.get("civ_b", "")]
		"WAR_PEACE":
			return "En el año %d, se firmó la paz: '%s' y '%s' acordaron el fin del conflicto armado." % [e["year"], e.get("civ_a", ""), e.get("civ_b", "")]
		"BATTLE_CONQUEST":
			return "En el año %d, tras una sangrienta batalla, la civilización '%s' conquistó y tomó control del asentamiento de '%s' (anteriormente de '%s')." % [e["year"], e.get("attacker_civ", ""), e.get("site_name", ""), e.get("defender_civ", "")]
		"BATTLE_DEFENDED":
			return "En el año %d, las fuerzas defensoras de '%s' repelieron exitosamente un asalto masivo de '%s' en '%s'." % [e["year"], e.get("defender_civ", ""), e.get("attacker_civ", ""), e.get("site_name", "")]
		"ARTIFACT_CREATION":
			return "En el año %d, %s de '%s' entró en un misterioso estado de trance y creó la reliquia legendaria '%s' (%s de %s)." % [e["year"], e.get("hf_name", ""), e.get("civ_name", ""), e.get("art_name", ""), e.get("art_type", ""), e.get("art_material", "")]
		"HERO_DUEL":
			return "En el año %d, durante la batalla en '%s', se presenció un duelo singular: el campeón %s venció y decapitó al líder enemigo %s." % [e["year"], e.get("site_name", ""), e.get("champion_name", ""), e.get("victim_name", "")]
		"MARRIAGE":
			return "En el año %d, %s contrajo matrimonio con %s en '%s', uniendo sus destinos bajo la dinastía %s." % [e["year"], e.get("hf_a", ""), e.get("hf_b", ""), e.get("civ", ""), e.get("family", "")]
		"BIRTH":
			return "En el año %d, nació %s, hijo de %s y %s, en la civilización '%s'. La dinastía %s se fortalece." % [e["year"], e.get("child_name", ""), e.get("parent_a", ""), e.get("parent_b", ""), e.get("civ", ""), e.get("family", "")]
		"DYNASTY_FOUNDED":
			return "En el año %d, %s fundó la dinastía %s, dando inicio a un linaje de %s que perdurará por generaciones." % [e["year"], e.get("founder", ""), e.get("dynasty", ""), e.get("race", "")]
		"SUCCESSION_BLOOD":
			return "En el año %d, %s heredó el trono de '%s' por derecho de sangre, continuando la dinastía %s tras el fallecimiento de %s." % [e["year"], e.get("hf_name", ""), e.get("civ_name", ""), e.get("dynasty", ""), e.get("predecessor", "")]
		"INHERITANCE":
			return "En el año %d, tras la muerte de %s, la dinastía %s transmitió sus bienes y títulos a %s en '%s'." % [e["year"], e.get("deceased", ""), e.get("dynasty", ""), e.get("heir", ""), e.get("civ", "")]
		"AGE_CHANGE":
			return "En el año %d terminó la %s y comenzó la %s." % [e["year"], e.get("previous_age", "era anterior"), e.get("age_name", "nueva era")]
	return "En el año %d, aconteció un suceso histórico." % e["year"]

func _translate_race(race: String) -> String:
	match race.to_lower():
		"dwarf": return "enanos"
		"elf": return "elfos"
		"human": return "humanos"
		"goblin": return "goblins"
		"megabeast": return "monstruos"
	return "seres"
