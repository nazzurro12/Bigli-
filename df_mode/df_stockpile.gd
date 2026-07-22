extends RefCounted
class_name DFStockpile

const DFItem = preload("res://df_mode/df_item.gd")

var tiles: Array = []
var accepts_categories: Array = ["stone", "wood", "item"]
var display_color: Color = Color(0.8, 0.8, 0.2, 0.3)
var owner_site_id: int = -1
var is_foreign: bool = false
var stockpile_name: String = "Almacén"
const MAX_ITEMS_PER_TILE: int = 8
const DEFAULT_CANDIDATE_LIMIT: int = 16

func _init(initial_tiles: Array = []):
	tiles = initial_tiles.duplicate()

func add_tile(pos: Vector3i) -> void:
	if not tiles.has(pos):
		tiles.append(pos)

func has_tile(pos: Vector3i) -> bool:
	return tiles.has(pos)

# Devuelve varios destinos con capacidad. El enano decide cuál de ellos es
# realmente alcanzable antes de recoger el objeto. Esto evita el estado eterno
# "Llevando..." hacia almacenes aislados por agua, muros o desniveles.
func get_candidate_tiles(
	world: Object,
	preferred_item_type: String = "",
	max_candidates: int = DEFAULT_CANDIDATE_LIMIT
) -> Array[Vector3i]:
	var candidates: Array[Vector3i] = []
	if world == null or max_candidates <= 0:
		return candidates

	# 1. Apilar junto a objetos del mismo tipo.
	if not preferred_item_type.is_empty():
		for same_type_tile_value: Variant in tiles:
			var same_type_pos: Vector3i = same_type_tile_value
			if _tile_has_capacity(world, same_type_pos) and _tile_contains_item_type(world, same_type_pos, preferred_item_type):
				_append_unique_candidate(candidates, same_type_pos, max_candidates)
				if candidates.size() >= max_candidates:
					return candidates

	# 2. Comida y bebida prefieren estanterías físicas.
	if preferred_item_type in ["food", "drink", "meat", "fish"]:
		for shelf_tile_value: Variant in tiles:
			var shelf_pos: Vector3i = shelf_tile_value
			if _tile_has_capacity(world, shelf_pos) and _is_shelf_tile(world, shelf_pos):
				_append_unique_candidate(candidates, shelf_pos, max_candidates)
				if candidates.size() >= max_candidates:
					return candidates

	# 3. Cualquier suelo interior con capacidad.
	for free_tile_value: Variant in tiles:
		var free_pos: Vector3i = free_tile_value
		if _tile_has_capacity(world, free_pos):
			_append_unique_candidate(candidates, free_pos, max_candidates)
			if candidates.size() >= max_candidates:
				break
	return candidates

func get_free_tile(world: Object, preferred_item_type: String = "") -> Vector3i:
	var candidates: Array[Vector3i] = get_candidate_tiles(world, preferred_item_type, 1)
	return candidates[0] if not candidates.is_empty() else Vector3i(-1, -1, -1)

func _append_unique_candidate(candidates: Array[Vector3i], pos: Vector3i, max_candidates: int) -> void:
	if candidates.size() >= max_candidates:
		return
	if not candidates.has(pos):
		candidates.append(pos)

func _tile_has_capacity(world: Object, pos: Vector3i) -> bool:
	return world.is_floor(pos) and not world.is_blocked(pos) and _count_items_at(world, pos) < MAX_ITEMS_PER_TILE

func _tile_contains_item_type(world: Object, pos: Vector3i, item_type: String) -> bool:
	for entity: Variant in world.entities:
		if entity is DFItem and entity.tile_pos == pos and entity.is_in_stockpile and entity.item_type == item_type:
			return true
	return false

func _is_shelf_tile(world: Object, pos: Vector3i) -> bool:
	for building: Variant in world.buildings:
		if building.tile_pos == pos and str(building.get("name")) == "Almacén de Comida":
			return true
	return false

func _count_items_at(world: Object, pos: Vector3i) -> int:
	var count: int = 0
	for entity: Variant in world.entities:
		if entity is DFItem and entity.tile_pos == pos and entity.is_in_stockpile:
			count += maxi(1, entity.stack_size)
	return count

func _has_item_at(world: Object, pos: Vector3i) -> bool:
	return _count_items_at(world, pos) > 0
