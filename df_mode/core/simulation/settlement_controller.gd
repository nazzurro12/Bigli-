extends RefCounted
class_name SettlementController

var name: String = "Fortaleza"
var faction_id: String = "dwarves"
var food_reserve: float = 0.0
var wood_reserve: float = 0.0
var stone_reserve: float = 0.0
var drink_reserve: float = 0.0
var reserved_resources: Dictionary = {}
var carried_resources: Dictionary = {}
var available_resources: Dictionary = {}
var population: int = 0
var last_decision: String = ""

func refresh(world) -> void:
	population = 0
	food_reserve = 0.0
	wood_reserve = 0.0
	stone_reserve = 0.0
	drink_reserve = 0.0
	reserved_resources.clear()
	carried_resources.clear()
	available_resources.clear()
	for entity in world.entities:
		if entity.get("creature_type") == "dwarf" and entity.get("is_alive") != false:
			population += 1
			var inventory_value = entity.get("inventory")
			if inventory_value is Array:
				for carried_item in inventory_value:
					_count_item(carried_item, carried_resources)
		elif entity.get("item_type") != null:
			_count_item(entity, reserved_resources if _is_reserved(entity) else available_resources)
	_refresh_legacy_totals()

func _count_item(item, target: Dictionary) -> void:
	if item == null:
		return
	var item_type := str(item.get("item_type"))
	if item_type.is_empty():
		return
	var amount := maxi(1, int(item.get("stack_size") if item.get("stack_size") != null else 1))
	var resource_class := _resource_class(item_type)
	target[resource_class] = int(target.get(resource_class, 0)) + amount

func _resource_class(item_type: String) -> String:
	match item_type:
		"food", "meat", "fish", "plant", "animal_product": return "food"
		"drink": return "drink"
		"wood", "plank": return "wood"
		"stone", "ore", "metal_bar": return "stone"
		_: return item_type

func _is_reserved(item) -> bool:
	var reserved_by = item.get("reserved_by_id")
	if reserved_by != null and int(reserved_by) >= 0:
		return true
	if item.has_meta("reserved_by_job_id"):
		return int(item.get_meta("reserved_by_job_id", -1)) >= 0
	return false

func _total(resource_type: String) -> float:
	return float(available_resources.get(resource_type, 0)) + float(reserved_resources.get(resource_type, 0)) + float(carried_resources.get(resource_type, 0))

func get_available(resource_type: String) -> int:
	return int(available_resources.get(resource_type, 0))

func get_snapshot() -> Dictionary:
	return {
		"population": population,
		"available": available_resources.duplicate(true),
		"reserved": reserved_resources.duplicate(true),
		"carried": carried_resources.duplicate(true)
	}

func _refresh_legacy_totals() -> void:
	food_reserve = _total("food")
	drink_reserve = _total("drink")
	wood_reserve = _total("wood")
	stone_reserve = _total("stone")

func decide() -> String:
	if population <= 0:
		return ""
	if get_available("food") < population * 2:
		last_decision = "La reserva de comida es baja: priorizar cultivo, recolección y caza."
	elif get_available("drink") < population:
		last_decision = "La reserva de bebida es baja: priorizar agua potable y elaboración."
	elif get_available("wood") < 4:
		last_decision = "La reserva de madera es baja: priorizar tala y transporte."
	else:
		last_decision = "Las reservas son estables: ampliar talleres y defensas."
	return last_decision
