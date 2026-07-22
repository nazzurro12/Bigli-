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
	food_reserve = 0.0
	wood_reserve = 0.0
	for entity in world.entities:
		if entity.get("creature_type") == "dwarf" and entity.get("is_alive") != false:
			population += 1
		var item_type = entity.get("item_type")
		if item_type in ["food", "plant", "animal_product"]:
			food_reserve += 1.0
		elif item_type == "wood":
			wood_reserve += 1.0

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
