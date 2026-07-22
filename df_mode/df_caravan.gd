extends RefCounted
class_name DFCaravan

# Sistema de Caravanas Comerciales
# Civilizaciones externas visitan la fortaleza para comerciar.

enum CaravanState {
	APPROACHING,
	ARRIVED,
	TRADING,
	DEPARTING,
	GONE
}

const CIVILIZATIONS = {
	"human": {
		"name": "Humanos del Reino del Norte",
		"glyph": "H",
		"color": Color("#88CCFF"),
		"goods": ["food", "drink", "weapon", "armor", "cloth", "seed"],
		"wants": ["stone", "ore", "gem", "metal", "bone", "leather"],
		"aggro": 0.0,
		"base_wealth": 2000
	},
	"elf": {
		"name": "Elfos del Bosque Eterno",
		"glyph": "E",
		"color": Color("#55FF55"),
		"goods": ["food", "drink", "cloth", "toy", "seed", "wood"],
		"wants": ["metal", "weapon", "gem", "tool"],
		"aggro": 0.0,
		"base_wealth": 1500
	},
	"dwarf": {
		"name": "Enanos de la Montana Profunda",
		"glyph": "D",
		"color": Color("#FF8844"),
		"goods": ["weapon", "armor", "tool", "gem", "metal", "drink"],
		"wants": ["food", "wood", "cloth", "leather", "seed"],
		"aggro": 0.0,
		"base_wealth": 3000
	},
	"goblin": {
		"name": "Trasgos de las Cavernas",
		"glyph": "g",
		"color": Color("#AA0000"),
		"goods": ["weapon", "toy", "armor"],
		"wants": ["food", "drink", "gem", "metal"],
		"aggro": 0.4,
		"base_wealth": 500
	},
	"kobold": {
		"name": "Kobolds del Tunel Olvidado",
		"glyph": "k",
		"color": Color("#AAAA00"),
		"goods": ["toy", "tool", "raw_material"],
		"wants": ["food", "drink", "gem"],
		"aggro": 0.1,
		"base_wealth": 300
	}
}

const TRADE_GOODS = {
	"food":          {"base_price": 3,  "glyph": "%", "color": Color("#FF8844"), "name": "Comida"},
	"drink":         {"base_price": 5,  "glyph": "~", "color": Color("#FFCC00"), "name": "Bebida"},
	"wood":          {"base_price": 2,  "glyph": "=", "color": Color("#8B5A2B"), "name": "Madera"},
	"stone":         {"base_price": 1,  "glyph": "#", "color": Color("#888888"), "name": "Piedra"},
	"ore":           {"base_price": 8,  "glyph": "*", "color": Color("#AA5500"), "name": "Mineral"},
	"metal":         {"base_price": 15, "glyph": "i", "color": Color("#AAAAAA"), "name": "Metal"},
	"weapon":        {"base_price": 25, "glyph": "/", "color": Color("#88CCFF"), "name": "Arma"},
	"armor":         {"base_price": 30, "glyph": "[", "color": Color("#88CCFF"), "name": "Armadura"},
	"tool":          {"base_price": 10, "glyph": "p", "color": Color("#88CCFF"), "name": "Herramienta"},
	"cloth":         {"base_price": 6,  "glyph": "&", "color": Color("#FF88FF"), "name": "Tela"},
	"gem":           {"base_price": 50, "glyph": "*", "color": Color("#55FFFF"), "name": "Gema"},
	"toy":           {"base_price": 8,  "glyph": "o", "color": Color("#FF88FF"), "name": "Juguete"},
	"seed":          {"base_price": 2,  "glyph": ".", "color": Color("#00FF88"), "name": "Semilla"},
	"leather":       {"base_price": 7,  "glyph": "=", "color": Color("#AA5500"), "name": "Cuero"},
	"bone":          {"base_price": 4,  "glyph": "=", "color": Color("#DDDDDD"), "name": "Hueso"},
	"luxury":        {"base_price": 100,"glyph": "*", "color": Color("#FFD700"), "name": "Lujo"},
}

const CARAVAN_SEASONS = ["Spring", "Summer", "Autumn"]

var rng: RandomNumberGenerator
var caravans: Array = []
var trade_history: Dictionary = {}
var total_trades: int = 0
var total_wealth_traded: float = 0.0
var relations: Dictionary = {}
var _seed: int

func _init(seed: int):
	_seed = seed
	rng = RandomNumberGenerator.new()
	rng.seed = seed
	for civ_id in CIVILIZATIONS:
		relations[civ_id] = rng.randf_range(-20, 40)
		trade_history[civ_id] = {"total_trades": 0, "total_value": 0.0}

func tick(minute_ticked: bool, game_minute: int, game_hour: int, game_day: int,
		  game_season: String, dwarves_count: int, fortress_wealth: float,
		  world_width: int, world_depth: int, entities: Array) -> Dictionary:
	var events: Array = []
	
	# Spawnear nuevas caravanas
	if minute_ticked and game_day == 1 and game_hour == 8 and game_minute == 0:
		if game_season in CARAVAN_SEASONS:
			_try_spawn_caravan(game_season, dwarves_count, fortress_wealth)
	
	# Procesar caravanas existentes
	for caravan in caravans:
		match caravan.state:
			CaravanState.APPROACHING:
				_approach_tick(caravan)
				if caravan.progress >= 1.0:
					caravan.state = CaravanState.ARRIVED
					caravan.arrival_day = game_day
					events.append("! " + caravan.civ_name + " ha llegado! (" + caravan.merchant_name + ")")
			
			CaravanState.ARRIVED:
				var wait_days = game_day - caravan.arrival_day
				if wait_days >= caravan.stay_duration:
					caravan.state = CaravanState.DEPARTING
					caravan.progress = 0.0
					caravan.departure_day = game_day
					events.append(caravan.civ_name + " empacando para partir...")
			
			CaravanState.DEPARTING:
				caravan.progress += 0.01
				if caravan.progress >= 1.0:
					caravan.state = CaravanState.GONE
					var profit = caravan.total_sold - caravan.total_bought
					var profit_str = "ganancia" if profit >= 0 else "perdida"
					events.append("Caravana de " + caravan.civ_name + " partio (" + profit_str + ": " + str(abs(profit)) + " oro)")
	
	# Limpiar caravanas GONE
	var before = caravans.size()
	caravans = caravans.filter(func(c): return c.state != CaravanState.GONE)
	if caravans.size() < before:
		var removed = before - caravans.size()
		events.append(str(removed) + " caravana(s) han partido del mapa.")
	
	return {"events": events}

func _try_spawn_caravan(season: String, dwarves_count: int, fortress_wealth: float) -> void:
	var active = 0
	for c in caravans:
		if c.state != CaravanState.GONE:
			active += 1
	if active >= 2:
		return
	
	var candidates = []
	for civ_id in CIVILIZATIONS:
		var civ_data = CIVILIZATIONS[civ_id]
		var rel = relations.get(civ_id, 0)
		var prob = 0.02 + (fortress_wealth / 50000.0) * 0.3 + (rel + 100) / 400.0 * 0.3
		prob *= (1.0 - civ_data.aggro * 0.5)
		if rng.randf() < prob:
			candidates.append(civ_id)
	
	if candidates.is_empty():
		return
	
	var chosen_id = candidates[rng.randi() % candidates.size()]
	var civ = CIVILIZATIONS[chosen_id]
	
	var caravan = {
		"id": chosen_id,
		"civ_name": civ.name,
		"civ_glyph": civ.glyph,
		"civ_color": civ.color,
		"merchant_name": "Mercader",
		"state": CaravanState.APPROACHING,
		"progress": 0.0,
		"arrival_day": 0,
		"departure_day": 0,
		"stay_duration": 3 + rng.randi() % 3,
		"return_interval": 20 + rng.randi() % 40,
		"inventory": [],
		"total_sold": 0,
		"total_bought": 0,
		"wealth": civ.base_wealth + int(fortress_wealth * 0.1),
		"tile_pos": Vector3i(10, 3, 10),
		"pack_animals": 2 + rng.randi() % 4
	}
	caravans.append(caravan)

func _approach_tick(caravan: Dictionary) -> void:
	caravan.progress += 0.01 + rng.randf() * 0.005

func get_caravans_for_sidebar() -> Array:
	var result: Array = []
	for c in caravans:
		if c.state in [CaravanState.APPROACHING, CaravanState.ARRIVED, CaravanState.DEPARTING]:
			result.append({
				"name": c.civ_name,
				"merchant": c.merchant_name,
				"state": c.state,
				"glyph": c.civ_glyph,
				"color": c.civ_color,
				"tile_pos": c.tile_pos,
				"wealth": c.wealth,
				"inventory_count": c.inventory.size(),
				"pack_animals": c.pack_animals
			})
	return result

func get_trade_stats() -> Dictionary:
	return {
		"total_caravans": total_trades,
		"total_wealth": total_wealth_traded,
		"active_caravans": caravans.size(),
		"relations": relations
	}
