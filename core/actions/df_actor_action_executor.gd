extends RefCounted
class_name DFActorActionExecutor

const SKILL_MINING: int = 0
const SKILL_MASONRY: int = 2
const SKILL_WOODCUTTING: int = 8

enum ActionType {
	MOVE,
	CHOP_TREE,
	MINE,
	PICK_UP,
	DROP,
	BUILD_WALL,
	BUILD_FLOOR,
	BUILD_STAIRS_UP,
	BUILD_STAIRS_DOWN,
	CLIMB_UP,
	CLIMB_DOWN,
}

static func execute(actor, world, action_type: int, target: Vector3i = Vector3i.ZERO, _data: Dictionary = {}) -> Dictionary:
	if actor == null or world == null:
		return _result(false, "Acción inválida")
	match action_type:
		ActionType.MOVE:
			return _move(actor, world, target)
		ActionType.CHOP_TREE:
			return _chop(actor, world, target)
		ActionType.MINE:
			return _mine(actor, world, target)
		ActionType.PICK_UP:
			return _pick_up(actor, world, target)
		ActionType.DROP:
			return _drop(actor, world, target)
		ActionType.BUILD_WALL:
			return _build(actor, world, target, true)
		ActionType.BUILD_FLOOR:
			return _build(actor, world, target, false)
		ActionType.BUILD_STAIRS_UP:
			return _stairs(actor, world, target, true)
		ActionType.BUILD_STAIRS_DOWN:
			return _stairs(actor, world, target, false)
		ActionType.CLIMB_UP:
			return _climb(actor, world, true)
		ActionType.CLIMB_DOWN:
			return _climb(actor, world, false)
	return _result(false, "Acción desconocida")

static func contextual_action(actor, world, target: Vector3i) -> Dictionary:
	var tile_type: int = world.get_tile(target)
	if tile_type == world.TileType.TREE:
		return execute(actor, world, ActionType.CHOP_TREE, target)
	if world.is_wall(target):
		return execute(actor, world, ActionType.MINE, target)
	for entity in world.entities:
		if entity == actor:
			continue
		if "tile_pos" in entity and entity.tile_pos == target and "item_type" in entity:
			return execute(actor, world, ActionType.PICK_UP, target)
	return _result(false, "No hay una acción contextual en esa casilla")

static func _move(actor, world, direction: Vector3i) -> Dictionary:
	if direction == Vector3i.ZERO:
		return _result(false, "Dirección inválida")
	var target: Vector3i = actor.tile_pos + direction
	if target.x < 0 or target.x >= world.width or target.z < 0 or target.z >= world.depth:
		return _result(false, "Límite del mapa")
	var occupant: Variant = world.get_entity_at(target)
	if occupant != null and occupant != actor:
		return _result(false, "La casilla está ocupada")
	if world.is_blocked(target):
		return _result(false, "El paso está bloqueado")
	actor.tile_pos = target
	if "path" in actor:
		actor.path.clear()
	if "path_index" in actor:
		actor.path_index = 0
	if "has_moved_this_tick" in actor:
		actor.has_moved_this_tick = true
	return _result(true, "Se movió")

static func _chop(actor, world, target: Vector3i) -> Dictionary:
	if not _has_tool(actor, ["axe", "hacha"]):
		return _result(false, "Necesita un hacha")
	if _distance(actor.tile_pos, target) > 1:
		return _result(false, "El árbol está demasiado lejos")
	if world.get_tile(target) != world.TileType.TREE:
		return _result(false, "No hay un árbol allí")
	if world.chop_tree(target, actor.tile_pos):
		_gain_skill(actor, SKILL_WOODCUTTING, 2)
		return _result(true, "Taló el árbol")
	return _result(false, "No pudo talar el árbol")

static func _mine(actor, world, target: Vector3i) -> Dictionary:
	if not _has_tool(actor, ["pickaxe", "pico"]):
		return _result(false, "Necesita un pico")
	if _distance(actor.tile_pos, target) > 1:
		return _result(false, "La roca está demasiado lejos")
	if not world.is_wall(target):
		return _result(false, "La casilla no es excavable")
	var material: int = world.get_material(target)
	if world.dig_tile(target):
		_gain_skill(actor, SKILL_MINING, 2)
		return _result(true, "Extrajo %s" % world.get_material_name(material))
	return _result(false, "No pudo excavar")

static func _pick_up(actor, world, target: Vector3i) -> Dictionary:
	if _distance(actor.tile_pos, target) > 1:
		return _result(false, "El objeto está demasiado lejos")
	var found: Variant = null
	for entity in world.entities:
		if entity == actor:
			continue
		if "tile_pos" in entity and entity.tile_pos == target and "item_type" in entity:
			found = entity
			break
	if found == null:
		return _result(false, "No hay ningún objeto para recoger")
	if actor.inventory.size() >= 8:
		return _result(false, "El inventario está lleno")
	world.remove_entity(found)
	found.carried_by_id = actor.id
	found.release_reservation()
	actor.inventory.append(found)
	if "needs_display_update" in actor:
		actor.needs_display_update = true
	return _result(true, "Recogió %s" % str(found.name))

static func _drop(actor, world, target: Vector3i) -> Dictionary:
	if actor.inventory.is_empty():
		return _result(false, "No lleva ningún objeto")
	var item: Variant = actor.inventory.pop_back()
	item.tile_pos = target
	item.carried_by_id = -1
	item.release_reservation()
	world.add_entity(item)
	if "needs_display_update" in actor:
		actor.needs_display_update = true
	return _result(true, "Soltó %s" % str(item.name))

static func _build(actor, world, target: Vector3i, wall: bool) -> Dictionary:
	if _distance(actor.tile_pos, target) > 1:
		return _result(false, "El lugar de construcción está demasiado lejos")
	var material_index: int = _find_build_material(actor)
	if material_index < 0:
		return _result(false, "Necesita madera o piedra")
	var item: Variant = actor.inventory[material_index]
	var material_id: int = int(item.material) if "material" in item else world.MatType.CONSTRUCTION
	var success: bool = world.build_wall(target, material_id) if wall else world.build_floor(target, material_id)
	if not success:
		return _result(false, "No se puede construir en esa casilla")
	actor.inventory.remove_at(material_index)
	_gain_skill(actor, SKILL_MASONRY, 2)
	return _result(true, "Construyó una pared" if wall else "Construyó un suelo")

static func _stairs(actor, world, target: Vector3i, upward: bool) -> Dictionary:
	if _distance(actor.tile_pos, target) > 1:
		return _result(false, "La escalera está demasiado lejos")
	if not _has_tool(actor, ["pickaxe", "pico"]):
		return _result(false, "Necesita un pico para abrir la escalera")
	var success: bool = world.build_stairs_up(target) if upward else world.build_stairs_down(target)
	if success:
		_gain_skill(actor, SKILL_MINING, 2)
		return _result(true, "Construyó una escalera ascendente" if upward else "Construyó una escalera descendente")
	return _result(false, "No pudo construir la escalera")

static func _climb(actor, world, upward: bool) -> Dictionary:
	var current_type: int = world.get_tile(actor.tile_pos)
	var allowed: Array = [world.TileType.STAIRS_UP, world.TileType.STAIRS_UPDOWN, world.TileType.RAMP] if upward else [world.TileType.STAIRS_DOWN, world.TileType.STAIRS_UPDOWN, world.TileType.RAMP]
	if current_type not in allowed:
		return _result(false, "No hay una conexión vertical en esta casilla")
	var delta_y: int = 1 if upward else -1
	var destination: Vector3i = actor.tile_pos + Vector3i(0, delta_y, 0)
	if world.is_blocked(destination):
		return _result(false, "La salida de la escalera está bloqueada")
	actor.tile_pos = destination
	if "path" in actor:
		actor.path.clear()
	return _result(true, "Subió de nivel" if upward else "Bajó de nivel")

static func _has_tool(actor, names: Array) -> bool:
	var weapon_name: String = str(actor.equipped_weapon).to_lower() if "equipped_weapon" in actor else ""
	for token in names:
		if str(token).to_lower() in weapon_name:
			return true
	for item in actor.inventory:
		var item_name: String = str(item.name).to_lower() if "name" in item else ""
		var item_type: String = str(item.item_type).to_lower() if "item_type" in item else ""
		for token in names:
			var lowered: String = str(token).to_lower()
			if lowered in item_name or lowered in item_type:
				return true
	return false

static func _find_build_material(actor) -> int:
	for index in range(actor.inventory.size()):
		var item: Variant = actor.inventory[index]
		if "item_type" in item and str(item.item_type).to_lower() in ["wood", "stone", "plank", "stone_block"]:
			return index
	return -1

static func _gain_skill(actor, skill_id: int, amount: int) -> void:
	if actor.has_method("add_skill_xp"):
		actor.add_skill_xp(skill_id, amount)

static func _distance(a: Vector3i, b: Vector3i) -> int:
	return abs(a.x - b.x) + abs(a.z - b.z) + abs(a.y - b.y)

static func _result(success: bool, message: String) -> Dictionary:
	return {"success": success, "message": message}
