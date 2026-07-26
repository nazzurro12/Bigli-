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
	royal_guard.is_military = true
	royal_guard.profession = DFDwarf.Profession.CAPTAIN_OF_GUARD
	rescued_guard.is_military = true
	world.add_entity(wanderer)
	world.add_entity(royal_guard)
	world.add_entity(rescued_guard)
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
	_expect(wanderer.career_offers.size() == 1, "La acción debe producir una oportunidad de guardia")
	_expect(wanderer.possession_count == 1, "La identidad debe conservar su historial de posesión")
	_expect(wanderer.life_history.size() >= 3, "La vida debe conservar inicio, acción y fin de la posesión")

	var saved: Dictionary = DFSaveLoad._dwarf_to_dict(wanderer)
	var restored = DFSaveLoad._dict_to_dwarf(JSON.parse_string(JSON.stringify(saved)))
	_expect(restored.career_offers.size() == 1, "La oportunidad debe sobrevivir al guardado")
	_expect(restored.life_history.size() == wanderer.life_history.size(), "La historia personal debe sobrevivir al guardado")
	_expect(restored.possession_count == 1, "El historial de posesión debe sobrevivir al guardado")

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
