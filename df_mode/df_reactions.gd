extends RefCounted
class_name DFReactions

static var _initialized: bool = false
static var _reactions: Array = []
static var _reactions_by_id: Dictionary = {}
static var _reactions_by_building: Dictionary = {}

static func ensure_loaded() -> void:
	if _initialized:
		return
	_initialized = true
	var path = "res://df_mode/data/reactions.json"
	var f = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return
	var content = f.get_as_text()
	f.close()
	var json = JSON.new()
	var err = json.parse(content)
	if err != OK:
		return
	var data = json.data
	if typeof(data) != TYPE_ARRAY:
		return
	_reactions = data
	for r in _reactions:
		var rid = r.get("id", "")
		if rid != "":
			_reactions_by_id[rid] = r
		var bld = r.get("building", "")
		if bld != "":
			if not _reactions_by_building.has(bld):
				_reactions_by_building[bld] = []
			_reactions_by_building[bld].append(r)

static func get_all() -> Array:
	ensure_loaded()
	return _reactions

static func get_reaction(id: String) -> Dictionary:
	ensure_loaded()
	return _reactions_by_id.get(id, {})

static func get_reactions_for_building(building_id: String) -> Array:
	ensure_loaded()
	return _reactions_by_building.get(building_id, [])

static func get_recipe_list_for_workshop(workshop_type: int, workshop_type_names: Dictionary) -> Array:
	ensure_loaded()
	var building_name = ""
	for wt in workshop_type_names:
		if wt == workshop_type:
			building_name = workshop_type_names[wt]
			break
	if building_name == "":
		return []
	var raw = _reactions_by_building.get(building_name.to_upper(), [])
	var result = []
	for r in raw:
		result.append({
			"id": r.get("id", ""),
			"name": r.get("name", "Reacción"),
			"building": building_name,
		})
	return result
