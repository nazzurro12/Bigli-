extends RefCounted
class_name DFJusticeSystem

const DFDwarf = preload("res://df_mode/df_dwarf.gd")
const DFJob = preload("res://df_mode/df_job.gd")
const DFBuilding = preload("res://df_mode/df_building.gd")

enum SentenceType { TIME, LABOR, CORPORAL, FINE }
enum CrimeSeverity { MINOR = 1, MODERATE = 2, SERIOUS = 3, SEVERE = 4 }

const MAX_PRISONERS_PER_CELL: int = 1
const PATROL_INTERVAL_TICKS: int = 20
const ARREST_INTERVAL_TICKS: int = 10
const SENTENCE_FACTOR: float = 30.0
const LABOR_SENTENCE_FACTOR: float = 15.0
const MAX_SENTENCE_MINUTES: int = 7200

var sheriff_id: int = -1
var captain_id: int = -1
var prison_cells: Array = []
var arrest_warrants: Dictionary = {}
var tick_counter: int = 0
var main_ref = null

func _init(p_main) -> void:
	main_ref = p_main

func register_prison_cell(pos: Vector3i) -> void:
	var key: String = "%d,%d,%d" % [pos.x, pos.y, pos.z]
	for cell in prison_cells:
		if cell["key"] == key:
			return
	prison_cells.append({"key": key, "pos": pos, "prisoner_id": -1})

func unregister_prison_cell(pos: Vector3i) -> void:
	var key: String = "%d,%d,%d" % [pos.x, pos.y, pos.z]
	for i in range(prison_cells.size() - 1, -1, -1):
		if prison_cells[i]["key"] == key:
			var prisoner = prison_cells[i]["prisoner_id"]
			if prisoner >= 0:
				_release_prisoner(prisoner)
			prison_cells.remove_at(i)
			return

func get_free_cell() -> Dictionary:
	for cell in prison_cells:
		if cell["prisoner_id"] < 0:
			return cell
	return {}

func tick(world, minute_ticked: bool, game_minute: int) -> Array:
	if world == null:
		return []
	var messages: Array = []
	tick_counter += 1

	_scan_for_prison_cells(world)
	_find_authorities(world)

	if minute_ticked:
		_process_sentences(world, messages)
		_process_warrants(world, messages)

	if tick_counter % ARREST_INTERVAL_TICKS == 0:
		_scan_for_crimes(world, messages, game_minute)

	if tick_counter % PATROL_INTERVAL_TICKS == 0:
		_auto_patrol(world)

	return messages

func _scan_for_prison_cells(world) -> void:
	if world.buildings == null:
		return
	for building in world.buildings:
		if building.type == DFBuilding.BuildingType.PRISON:
			register_prison_cell(building.tile_pos)
		if building.type == DFBuilding.BuildingType.CHAIN:
			register_prison_cell(building.tile_pos)

func _find_authorities(world) -> void:
	if sheriff_id < 0:
		for dwarf in world.dwarves:
			if dwarf.is_alive and dwarf.profession == DFDwarf.Profession.SHERIFF:
				sheriff_id = dwarf.id
				break
	if captain_id < 0:
		for dwarf2 in world.dwarves:
			if dwarf2.is_alive and dwarf2.profession == DFDwarf.Profession.CAPTAIN_OF_GUARD:
				captain_id = dwarf2.id
				break

func _scan_for_crimes(world, messages: Array, game_minute: int) -> void:
	var authority_ids: Array = []
	if sheriff_id >= 0:
		authority_ids.append(sheriff_id)
	if captain_id >= 0:
		authority_ids.append(captain_id)
	if authority_ids.is_empty():
		return

	for dwarf in world.dwarves:
		if not dwarf.is_alive or dwarf.is_arrested or dwarf.is_imprisoned:
			continue
		if arrest_warrants.has(dwarf.id):
			continue

		for record in dwarf.legal_record:
			var status: String = record.get("status", "")
			if status == "unreported":
				record["status"] = str("reported")
				var severity: float = float(record.get("severity", 0.25))
				if severity >= 0.3:
					arrest_warrants[dwarf.id] = {
						"crime": record.get("offense", "Delito"),
						"severity": severity,
						"issued_tick": tick_counter,
						"event_id": record.get("event_id", -1)
					}
					messages.append("! ORDEN DE ARRESTO: %s buscado por %s." % [dwarf.name, record.get("offense", "Delito")])
					_create_arrest_job(world, dwarf)
					break

func _create_arrest_job(world, criminal) -> void:
	if main_ref == null or not main_ref.has_method("_queue_job_once"):
		return
	var guard_pos: Vector3i = criminal.tile_pos
	main_ref._queue_job_once(DFJob.JobType.ARREST_DWARF, guard_pos, 9)

func _process_warrants(world, messages: Array) -> void:
	var to_remove: Array = []
	for dwarf_id: Variant in arrest_warrants.keys():
		var dwarf = _find_dwarf(world, int(dwarf_id))
		if dwarf == null or not dwarf.is_alive:
			to_remove.append(dwarf_id)
			continue
		if dwarf.is_arrested or dwarf.is_imprisoned:
			to_remove.append(dwarf_id)
	for rid in to_remove:
		arrest_warrants.erase(rid)

func _process_sentences(world, messages: Array) -> void:
	for dwarf in world.dwarves:
		if not dwarf.is_alive or not dwarf.is_imprisoned:
			continue
		if dwarf.sentence_remaining <= 0:
			_release_prisoner(dwarf.id)
			messages.append("! %s ha cumplido su condena y fue liberado." % dwarf.name)
			continue
		dwarf.sentence_remaining -= 1

		if dwarf.sentence_type == "labor" and dwarf.sentence_remaining % 60 == 0:
			var labor_task: String = "Trabajos forzados"
			dwarf.current_task = labor_task
			dwarf.add_thought("Cumple su condena con trabajos forzados.", -0.01)

func _release_prisoner(dwarf_id: int) -> void:
	for i in range(prison_cells.size()):
		if prison_cells[i]["prisoner_id"] == dwarf_id:
			prison_cells[i]["prisoner_id"] = -1
			break

func _find_dwarf(world, dwarf_id: int):
	for dwarf in world.dwarves:
		if dwarf.id == dwarf_id:
			return dwarf
	return null

func _auto_patrol(world) -> void:
	if main_ref == null or not main_ref.has_method("_queue_job_once"):
		return
	if not prison_cells.is_empty():
		for cell in prison_cells:
			if cell["prisoner_id"] >= 0:
				var cell_pos: Vector3i = cell["pos"]
				if main_ref.has_method("_count_open_jobs"):
					var open_guards: int = main_ref._count_open_jobs(DFJob.JobType.GUARD_PRISON)
					if open_guards < 2 and randi() % 3 == 0:
						main_ref._queue_job_once(DFJob.JobType.GUARD_PRISON, cell_pos, 7)

func get_justice_summary() -> Dictionary:
	var summary: Dictionary = {
		"cells_total": prison_cells.size(),
		"cells_occupied": 0,
		"prisoners": [],
		"warrants_active": arrest_warrants.size(),
		"sheriff_id": sheriff_id,
		"captain_id": captain_id,
	}
	for cell in prison_cells:
		if cell["prisoner_id"] >= 0:
			summary["cells_occupied"] += 1
			summary["prisoners"].append(cell["prisoner_id"])
	return summary

func export_state() -> Dictionary:
	return {
		"sheriff_id": sheriff_id,
		"captain_id": captain_id,
		"prison_cells": prison_cells.duplicate(),
		"arrest_warrants": arrest_warrants.duplicate(),
		"tick_counter": tick_counter,
	}

func import_state(data: Dictionary) -> void:
	sheriff_id = int(data.get("sheriff_id", -1))
	captain_id = int(data.get("captain_id", -1))
	prison_cells = data.get("prison_cells", []).duplicate()
	arrest_warrants = data.get("arrest_warrants", {}).duplicate()
	tick_counter = int(data.get("tick_counter", 0))
