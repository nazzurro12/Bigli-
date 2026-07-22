extends RefCounted
class_name DFData

const DFMaterials = preload("res://df_mode/df_materials.gd")

const DFCreatures = preload("res://df_mode/df_creature.gd")
const DFPlants = preload("res://df_mode/df_plants.gd")
const DFItems = preload("res://df_mode/df_items.gd")
const DFEntities = preload("res://df_mode/df_entities.gd")
const DFNamegen = preload("res://df_mode/df_namegen.gd")
const WorldContentCatalog = preload("res://core/content/world_content_catalog.gd")

static var instance: DFData = null

var namegen: DFNamegen = null

var materials: Array = []
var creatures: Array = []
var plants: Array = []
var items: Array = []
var entities: Array = []

var bodies: Array = []
var buildings: Array = []
var colors: Array = []
var graphics: Dictionary = {}
var interactions: Array = []
var reactions: Array = []
var texts: Array = []

var _materials_by_id: Dictionary = {}
var _creatures_by_id: Dictionary = {}
var _plants_by_id: Dictionary = {}
var _items_by_id: Dictionary = {}
var _entities_by_id: Dictionary = {}

var _materials_by_type: Dictionary = {}
var _creatures_by_size: Dictionary = {}
var _plants_by_type: Dictionary = {}

var _buildings_by_id: Dictionary = {}
var _reactions_by_id: Dictionary = {}
var _reactions_by_building: Dictionary = {}
var _colors_by_id: Dictionary = {}
var _texts_by_id: Dictionary = {}
var _interactions_by_id: Dictionary = {}


func _init(seed_val: int = -1):
	if instance == null:
		instance = self
	namegen = DFNamegen.new(seed_val)
	_load_all()


func _load_all() -> void:
	materials = DFMaterials.get_all()
	creatures = DFCreatures.get_all()
	plants = DFPlants.get_all()
	items = DFItems.get_all()
	entities = DFEntities.get_all()

	for m in materials:
		_materials_by_id[m.get("id", "")] = m
		var t = m.get("type", "stone")
		if not _materials_by_type.has(t):
			_materials_by_type[t] = []
		_materials_by_type[t].append(m)

	for c in creatures:
		_creatures_by_id[c.get("id", "")] = c
		var s = c.get("size", "medium")
		if not _creatures_by_size.has(s):
			_creatures_by_size[s] = []
		_creatures_by_size[s].append(c)

	for p in plants:
		_plants_by_id[p.get("id", "")] = p
		var t_78 = "tree" if p.get("is_tree", false) else "crop"
		if not _plants_by_type.has(t_78):
			_plants_by_type[t_78] = []
		_plants_by_type[t_78].append(p)

	for i in items:
		_items_by_id[i.get("id", "")] = i

	for e in entities:
		_entities_by_id[e.get("id", "")] = e

	_load_json_files()
	_load_content_packs()


func _load_json_files() -> void:
	bodies = _load_json("res://df_mode/data/bodies.json")
	var bld = _load_json("res://df_mode/data/buildings.json")
	if typeof(bld) == TYPE_ARRAY:
		buildings = bld
		for b in buildings:
			var bid = b.get("id", "")
			if bid != "":
				_buildings_by_id[bid] = b
	var col = _load_json("res://df_mode/data/colors.json")
	if typeof(col) == TYPE_ARRAY:
		colors = col
		for c in colors:
			var cid = c.get("id", "")
			if cid != "":
				_colors_by_id[cid] = c
	var gr = _load_json("res://df_mode/data/graphics.json")
	if typeof(gr) == TYPE_DICTIONARY:
		graphics = gr
	var react = _load_json("res://df_mode/data/reactions.json")
	if typeof(react) == TYPE_ARRAY:
		reactions = react
		for r in reactions:
			var rid = r.get("id", "")
			if rid != "":
				_reactions_by_id[rid] = r
			var bld_type = r.get("building", "")
			if bld_type != "":
				if not _reactions_by_building.has(bld_type):
					_reactions_by_building[bld_type] = []
				_reactions_by_building[bld_type].append(r)
	var interact = _load_json("res://df_mode/data/interactions.json")
	if typeof(interact) == TYPE_ARRAY:
		interactions = interact
		for ix in interactions:
			var iid = ix.get("id", "")
			if iid != "":
				_interactions_by_id[iid] = ix
	var txt = _load_json("res://df_mode/data/texts.json")
	if typeof(txt) == TYPE_ARRAY:
		texts = txt
		for t in texts:
			var tid = t.get("id", "")
			if tid != "":
				_texts_by_id[tid] = t


## Añade o reemplaza definiciones usando Resources o paquetes JSON externos.
## Se ejecuta al crear DFData, antes de que el mundo genere criaturas u objetos.
func _load_content_packs() -> void:
	var content: Dictionary = WorldContentCatalog.load_all()
	_merge_content_array(materials, _materials_by_id, content.get("materials", []))
	_merge_content_array(creatures, _creatures_by_id, content.get("creatures", []))
	_merge_content_array(plants, _plants_by_id, content.get("plants", []))
	_merge_content_array(items, _items_by_id, content.get("items", []))
	_merge_content_array(entities, _entities_by_id, content.get("entities", []))
	_merge_content_array(buildings, _buildings_by_id, content.get("buildings", []))
	_merge_content_array(reactions, _reactions_by_id, content.get("reactions", []))
	_rebuild_secondary_indexes()


func _merge_content_array(target: Array, index: Dictionary, additions: Array) -> void:
	for definition in additions:
		var id := str(definition.get("id", ""))
		if id.is_empty():
			continue
		if index.has(id):
			for i in target.size():
				if str(target[i].get("id", "")) == id:
					target[i] = definition
					break
		else:
			target.append(definition)
		index[id] = definition


func _rebuild_secondary_indexes() -> void:
	_materials_by_type.clear()
	_creatures_by_size.clear()
	_plants_by_type.clear()
	_reactions_by_building.clear()
	for material in materials:
		var material_type: String = str(material.get("type", "stone"))
		if not _materials_by_type.has(material_type):
			_materials_by_type[material_type] = []
		_materials_by_type[material_type].append(material)
	for creature in creatures:
		var size: String = str(creature.get("size", "medium"))
		if not _creatures_by_size.has(size):
			_creatures_by_size[size] = []
		_creatures_by_size[size].append(creature)
	for plant in plants:
		var plant_type: String = "tree" if plant.get("is_tree", false) else "crop"
		if not _plants_by_type.has(plant_type):
			_plants_by_type[plant_type] = []
		_plants_by_type[plant_type].append(plant)
	for reaction in reactions:
		var building_id: String = str(reaction.get("building", ""))
		if not building_id.is_empty():
			if not _reactions_by_building.has(building_id):
				_reactions_by_building[building_id] = []
			_reactions_by_building[building_id].append(reaction)


func _load_json(path: String) -> Variant:
	var f = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return []
	var content = f.get_as_text()
	f.close()
	var json = JSON.new()
	var err = json.parse(content)
	if err != OK:
		return []
	return json.data


func get_material(id: String) -> Dictionary:
	return _materials_by_id.get(id, {})

func get_material_properties(id: String) -> Dictionary:
	var mat = _materials_by_id.get(id, {})
	if mat.is_empty():
		return DFMaterialProperties.compute({"id": id, "type": "stone", "value": 1})
	return DFMaterialProperties.compute(mat)

func get_material_property(id: String, prop: String, default = 0.0):
	var props = get_material_properties(id)
	return props.get(prop, default)


func get_random_material(mat_type: String = "") -> Dictionary:
	if mat_type != "" and _materials_by_type.has(mat_type):
		var pool = _materials_by_type[mat_type]
		return pool[randi() % pool.size()]
	if not materials.is_empty():
		return materials[randi() % materials.size()]
	return {}


func get_materials_by_type(mat_type: String) -> Array:
	return _materials_by_type.get(mat_type, [])


func get_creature(id: String) -> Dictionary:
	return _creatures_by_id.get(id, {})


func get_random_creature(size: String = "") -> Dictionary:
	if size != "" and _creatures_by_size.has(size):
		var pool = _creatures_by_size[size]
		return pool[randi() % pool.size()]
	if not creatures.is_empty():
		return creatures[randi() % creatures.size()]
	return {}


func get_creatures_by_size(sz: String) -> Array:
	return _creatures_by_size.get(sz, [])


func get_plant(id: String) -> Dictionary:
	return _plants_by_id.get(id, {})


func get_random_plant(is_tree: bool = false) -> Dictionary:
	var t = "tree" if is_tree else "crop"
	if _plants_by_type.has(t):
		var pool = _plants_by_type[t]
		return pool[randi() % pool.size()]
	if not plants.is_empty():
		return plants[randi() % plants.size()]
	return {}


func get_item(id: String) -> Dictionary:
	return _items_by_id.get(id, {})


func get_random_item(item_type: String = "") -> Dictionary:
	if item_type != "":
		var pool = []
		for i in items:
			if i.get("type", "") == item_type:
				pool.append(i)
		if not pool.is_empty():
			return pool[randi() % pool.size()]
	if not items.is_empty():
		return items[randi() % items.size()]
	return {}


func get_entity(id: String) -> Dictionary:
	return _entities_by_id.get(id, {})


func get_building(id: String) -> Dictionary:
	return _buildings_by_id.get(id, {})


func get_color(id: String) -> Dictionary:
	return _colors_by_id.get(id, {})


func get_reaction(id: String) -> Dictionary:
	return _reactions_by_id.get(id, {})


func get_reactions_for_building(building_id: String) -> Array:
	return _reactions_by_building.get(building_id, [])


func get_all_reactions() -> Array:
	return reactions


func get_text(id: String) -> Array:
	var t = _texts_by_id.get(id, {})
	return t.get("lines", [])


func get_interaction(id: String) -> Dictionary:
	return _interactions_by_id.get(id, {})

func get_all_plant_ids() -> Array:
	var result = []
	for p in plants:
		result.append(p.get("id", ""))
	return result

func get_plant_names_by_type(is_tree: bool = false) -> Array:
	var result = []
	for p in plants:
		if p.get("is_tree", false) == is_tree:
			result.append(p.get("name", ""))
	return result

func get_plant_id_by_name(name: String) -> String:
	for p in plants:
		if p.get("name", "").to_lower() == name.to_lower():
			return p.get("id", "")
	return ""

func get_material_id_by_name(name: String) -> String:
	var n_lower = name.to_lower()
	for m in materials:
		if m.get("name", "").to_lower() == n_lower:
			return m.get("id", "")
	return ""

func get_reactions_for_building_name(building_name: String) -> Array:
	return _reactions_by_building.get(building_name.to_upper(), [])

func get_building_id_by_workshop_type(ws_type: int) -> String:
	var ws_names = {
		1: "MASONRY", 2: "CARPENTER", 3: "FORGE", 4: "SMELTER",
		5: "KITCHEN", 6: "STILL", 7: "LOOM", 8: "TANNER",
		9: "CRAFTSHOP", 10: "JEWELER", 11: "KILN", 12: "BUTCHER"
	}
	var name = ws_names.get(ws_type, "")
	if name == "":
		return ""
	for b in buildings:
		if b.get("id", "").to_lower() == name.to_lower():
			return b.get("id", "")
	return name


func generate_artifact_name(concept: String = "") -> String:
	return namegen.generate_artifact_name(concept)


func generate_dwarf_name() -> String:
	return namegen.generate_dwarf_name()


func generate_world_name() -> String:
	return namegen.generate_world_name()


func generate_site_name(lang: String = "dwarf") -> String:
	return namegen.generate_site_name(lang)
