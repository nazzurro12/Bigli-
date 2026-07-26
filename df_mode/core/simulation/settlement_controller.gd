extends RefCounted
class_name SettlementController

var name: String = "Fortaleza"
var faction_id: String = "dwarves"
var food_reserve: float = 0.0
var wood_reserve: float = 0.0
var population: int = 0
var last_decision: String = ""

func refresh(world) -> void:
	population = 0
	for dwarf: Variant in world.dwarves:
		if dwarf.get("is_alive") != false:
			population += 1
	food_reserve = 0.0
	wood_reserve = 0.0
	for entity in world.items:
		if entity.get("is_decayed") == true:
			continue
		var item_type: Variant = entity.get("item_type")
		var stack_size: float = maxf(1.0, float(entity.get("stack_size")))
		if item_type in ["food", "plant", "animal_product"]:
			food_reserve += stack_size
		elif item_type == "wood":
			wood_reserve += stack_size

func decide() -> String:
	if population <= 0:
		return ""
	if food_reserve < float(population) * 2.0:
		last_decision = "La reserva de comida es baja: priorizar cultivo, recolección y caza."
	elif wood_reserve < 4.0:
		last_decision = "La reserva de madera es baja: priorizar tala y transporte."
	else:
		last_decision = "Las reservas son estables: ampliar talleres y defensas."
	return last_decision

func export_state() -> Dictionary:
	return {
		"name": name,
		"faction_id": faction_id,
		"food_reserve": food_reserve,
		"wood_reserve": wood_reserve,
		"population": population,
		"last_decision": last_decision,
	}

func import_state(data: Dictionary) -> void:
	name = str(data.get("name", "Fortaleza"))
	faction_id = str(data.get("faction_id", "dwarves"))
	food_reserve = float(data.get("food_reserve", 0.0))
	wood_reserve = float(data.get("wood_reserve", 0.0))
	population = int(data.get("population", 0))
	last_decision = str(data.get("last_decision", ""))
