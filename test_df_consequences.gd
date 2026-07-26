extends Node

const DFWorld = preload("res://df_mode/df_world.gd")
const DFDwarf = preload("res://df_mode/df_dwarf.gd")
const DFConsequenceSystem = preload("res://df_mode/df_consequence_system.gd")
const DFSaveLoad = preload("res://df_mode/df_save_load.gd")

var failures: Array[String] = []

func _ready() -> void:
	var world = DFWorld.new(24, 24, 4)
	var wanderer = DFDwarf.new(Vector3i(10, 1, 10), "Ivo")
	var royal_guard = DFDwarf.new(Vector3i(11, 1, 10), "Mara")
	var rescued_guard = DFDwarf.new(Vector3i(12, 1, 10), "Sol")
	var neighbor = DFDwarf.new(Vector3i(20, 1, 20), "Nora")
	royal_guard.is_military = true
	royal_guard.profession = DFDwarf.Profession.CAPTAIN_OF_GUARD
	rescued_guard.is_military = true
	world.add_entity(wanderer)
	world.add_entity(royal_guard)
	world.add_entity(rescued_guard)
	world.add_entity(neighbor)
	world.consequence_system = DFConsequenceSystem.new(world)

	wanderer.is_possessed = true
	world.consequence_system.record_possession_started(wanderer)
	var event: Dictionary = world.consequence_system.record_action(wanderer, "defended_people", {
		"target_ids": [royal_guard.id, rescued_guard.id],
		"witness_ids": [royal_guard.id, rescued_guard.id],
		"tags": ["defense", "rescue", "help"],
		"severity": 1.0,
		"summary": "Ivo protegió a dos personas durante un asalto.",
		"possession_origin": true
	})
	world.consequence_system.record_possession_ended(wanderer)
	wanderer.is_possessed = false

	_expect(event.get("possession_origin", false), "El evento debe recordar que ocurrió durante una posesión")
	_expect(event.get("witness_ids", []).size() == 2, "Los dos guardias deben quedar registrados como testigos")
	_expect(float(wanderer.reputation.get("proteccion", 0.0)) >= 0.5, "La identidad poseída debe ganar reputación de protección")
	_expect(royal_guard.get_relationship_value(wanderer.id) > 0.0, "El testigo debe mejorar su relación con quien lo ayudó")
	_expect(not royal_guard.memories.is_empty(), "El testigo debe conservar un recuerdo")
	_expect(royal_guard.known_reputations.has(wanderer.id), "El testigo debe formar una opinión propia del actor")
	_expect(not royal_guard.rumors.is_empty(), "El hecho debe poder circular como información social")
	_expect(wanderer.career_offers.size() == 1, "La acción debe producir una oportunidad de guardia")
	_expect(wanderer.possession_count == 1, "La identidad debe conservar su historial de posesión")
	_expect(wanderer.life_history.size() >= 3, "La vida debe conservar inicio, acción y fin de la posesión")

	wanderer.personality[DFDwarf.PersonalityTrait.BRAVERY] = 0.9
	wanderer.personality[DFDwarf.PersonalityTrait.INDUSTRY] = 0.9
	wanderer.personality[DFDwarf.PersonalityTrait.AMBITION] = 0.9
	var decisions: Array = world.consequence_system.tick_social_simulation(60)
	_expect(not decisions.is_empty(), "La IA autónoma debe decidir sobre la oportunidad después de la posesión")
	_expect(wanderer.career_offers[0].get("status", "") == "accepted", "Una personalidad compatible debe aceptar la oportunidad")
	_expect(wanderer.is_military, "Aceptar debe transformar realmente su profesión y rutina")
	_expect("guard" in wanderer.social_roles, "El nuevo papel social debe quedar registrado")

	neighbor.tile_pos = Vector3i(10, 1, 11)
	royal_guard.tile_pos = Vector3i(18, 1, 18)
	rescued_guard.tile_pos = Vector3i(19, 1, 19)
	world.consequence_system._share_one_rumor(neighbor if not neighbor.rumors.is_empty() else wanderer, 70)
	world.consequence_system._share_one_rumor(wanderer, 71)

	var crime_event: Dictionary = world.consequence_system.record_action(neighbor, "took_property", {
		"witness_ids": [wanderer.id],
		"tags": ["theft", "crime"],
		"severity": 0.7,
		"summary": "Nora tomó una propiedad ajena.",
		"possession_origin": false
	})
	_expect(not crime_event.is_empty(), "Las acciones contrarias a las normas también deben producir consecuencias")
	_expect(neighbor.legal_record.size() == 1, "La identidad responsable debe conservar un expediente legal")
	_expect(neighbor.legal_record[0].get("status", "") == "reported", "Un guardia testigo debe convertir el hecho en reporte")

	var saved: Dictionary = DFSaveLoad._dwarf_to_dict(wanderer)
	var restored = DFSaveLoad._dict_to_dwarf(JSON.parse_string(JSON.stringify(saved)))
	_expect(restored.career_offers.size() == 1, "La oportunidad debe sobrevivir al guardado")
	_expect(restored.life_history.size() == wanderer.life_history.size(), "La historia personal debe sobrevivir al guardado")
	_expect(restored.possession_count == 1, "El historial de posesión debe sobrevivir al guardado")
	_expect(restored.life_decisions.size() == 1, "Las decisiones autónomas deben sobrevivir al guardado")
	_expect(restored.social_roles.has("guard"), "Los roles adquiridos deben sobrevivir al guardado")

	if failures.is_empty():
		print("CONSEQUENCE_SYSTEM_TESTS_OK")
		get_tree().quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		get_tree().quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
