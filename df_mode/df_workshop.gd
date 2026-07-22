extends RefCounted
class_name DFWorkshop

const DFReactions = preload("res://df_mode/df_reactions.gd")

# Tipos de taller
enum WorkshopType {
	NONE,
	MASONRY,     # Albañilería - piedra -> bloques, mecanismos
	CARPENTRY,   # Carpintería - madera -> muebles, vigas, escudos
	FORGE,       # Forja - metal -> armas, armaduras
	SMELTER,     # Fundición - mineral -> lingotes
	KITCHEN,     # Cocina - comida -> preparaciones
	STILL,       # Destilería - plantas -> bebidas
	LOOM,        # Telar - fibras -> tela
	TANNER,      # Curtiembre - piel -> cuero
	CRAFT_SHOP,  # Artesanía - varios -> objetos decorativos
	JEWELER,     # Joyería - gemas + metales -> joyas
	KILN,        # Horno - madera -> carbón, arcilla -> ladrillos
	BUTCHER,     # Carnicería - animales -> carne, piel, huesos
}

# Nombre de talleres en español
const WORKSHOP_NAMES = {
	WorkshopType.MASONRY: "Taller de Albañilería",
	WorkshopType.CARPENTRY: "Taller de Carpintería",
	WorkshopType.FORGE: "Forja",
	WorkshopType.SMELTER: "Fundición",
	WorkshopType.KITCHEN: "Cocina",
	WorkshopType.STILL: "Destilería",
	WorkshopType.LOOM: "Telar",
	WorkshopType.TANNER: "Curtiembre",
	WorkshopType.CRAFT_SHOP: "Taller de Artesanía",
	WorkshopType.JEWELER: "Joyero",
	WorkshopType.KILN: "Horno de Carbón",
	WorkshopType.BUTCHER: "Carnicería",
}

# Glifos para el mapa
const WORKSHOP_GLYPHS = {
	WorkshopType.MASONRY: "m",
	WorkshopType.CARPENTRY: "c",
	WorkshopType.FORGE: "F",
	WorkshopType.SMELTER: "s",
	WorkshopType.KITCHEN: "k",
	WorkshopType.STILL: "b",
	WorkshopType.LOOM: "l",
	WorkshopType.TANNER: "t",
	WorkshopType.CRAFT_SHOP: "a",
	WorkshopType.JEWELER: "j",
	WorkshopType.KILN: "H",
	WorkshopType.BUTCHER: "B",
}

# Colores de los talleres
const WORKSHOP_COLORS = {
	WorkshopType.MASONRY: Color("#AAAAAA"),
	WorkshopType.CARPENTRY: Color("#8B6914"),
	WorkshopType.FORGE: Color("#FF4400"),
	WorkshopType.SMELTER: Color("#FF8800"),
	WorkshopType.KITCHEN: Color("#44FF44"),
	WorkshopType.STILL: Color("#FFCC00"),
	WorkshopType.LOOM: Color("#88AAAA"),
	WorkshopType.TANNER: Color("#886644"),
	WorkshopType.CRAFT_SHOP: Color("#FF88FF"),
	WorkshopType.JEWELER: Color("#44FFFF"),
	WorkshopType.KILN: Color("#FF6600"),
	WorkshopType.BUTCHER: Color("#CC3333"),
}

# RECETAS DE PRODUCCIÓN
# Cada receta define: que materiales consume y que produce

static func get_recipes_for(ws_type: int) -> Array:
	match ws_type:
		WorkshopType.MASONRY:
			return [
				{
					"name": "Bloques de Piedra",
					"id": "stone_blocks",
					"time": 10,
					"skill": "MASONRY",
					"inputs": [{"material": ["stone", "granite", "limestone", "sandstone", "diorite", "gabbro", "marble", "obsidian"], "count": 1}],
					"outputs": [{"name": "Bloques de Piedra", "type": "construction", "count": 3}],
					"value": 8
				},
				{
					"name": "Mecanismo de Piedra",
					"id": "stone_mechanism",
					"time": 15,
					"skill": "MASONRY",
					"inputs": [{"material": ["stone", "granite", "limestone"], "count": 2}],
					"outputs": [{"name": "Mecanismo de Piedra", "type": "mechanism", "count": 1}],
					"value": 15
				},
				{
					"name": "Losa Decorativa",
					"id": "decorative_slab",
					"time": 20,
					"skill": "MASONRY",
					"inputs": [{"material": ["marble", "obsidian", "granite"], "count": 1}],
					"outputs": [{"name": "Losa Decorativa", "type": "furniture", "count": 1}],
					"value": 25
				},
			]

		WorkshopType.CARPENTRY:
			return [
				{
					"name": "Viga de Madera",
					"id": "wood_beam",
					"time": 8,
					"skill": "CARPENTRY",
					"inputs": [{"material": ["wood"], "count": 1}],
					"outputs": [{"name": "Viga de Madera", "type": "construction", "count": 2}],
					"value": 5
				},
				{
					"name": "Tablas de Madera",
					"id": "wood_planks",
					"time": 8,
					"skill": "CARPENTRY",
					"inputs": [{"material": ["wood"], "count": 1}],
					"outputs": [{"name": "Tablas de Madera", "type": "plank", "count": 3}],
					"value": 6
				},
				{
					"name": "Escudo de Madera",
					"id": "shield_wood",
					"time": 12,
					"skill": "CARPENTRY",
					"inputs": [{"material": ["wood"], "count": 2}],
					"outputs": [{"name": "Escudo de Madera", "type": "shield", "count": 1, "armor": "shield_wood"}],
					"value": 10
				},
				{
					"name": "Arco",
					"id": "bow_wood",
					"time": 15,
					"skill": "CARPENTRY",
					"inputs": [{"material": ["wood"], "count": 2}],
					"outputs": [{"name": "Arco de Madera", "type": "weapon", "count": 1, "weapon": "bow"}],
					"value": 12
				},
				{
					"name": "Cama",
					"id": "bed",
					"time": 20,
					"skill": "CARPENTRY",
					"inputs": [{"material": ["wood"], "count": 3}],
					"outputs": [{"name": "Cama de Madera", "type": "furniture", "count": 1}],
					"value": 15
				},
				{
					"name": "Hacha Primitiva",
					"id": "crude_axe",
					"time": 10,
					"skill": "CARPENTRY",
					"inputs": [{"material": ["wood"], "count": 2}, {"material": ["stone", "granite"], "count": 1}],
					"outputs": [{"name": "Stone Axe", "type": "tool", "count": 1}],
					"value": 8
				},
				{
					"name": "Pico Primitivo",
					"id": "crude_pick",
					"time": 12,
					"skill": "CARPENTRY",
					"inputs": [{"material": ["wood"], "count": 2}, {"material": ["stone", "granite"], "count": 2}],
					"outputs": [{"name": "Stone Pickaxe", "type": "tool", "count": 1}],
					"value": 10
				},
				{
					"name": "Ramas de árbol",
					"id": "gather_branches",
					"time": 5,
					"skill": "CARPENTRY",
					"inputs": [{"material": ["wood"], "count": 1}],
					"outputs": [{"name": "Ramas", "type": "crafting", "count": 3}],
					"value": 2
				},
				{
					"name": "Cuerda de Fibra",
					"id": "make_rope",
					"time": 8,
					"skill": "CARPENTRY",
					"inputs": [{"type": "fiber", "count": 2}],
					"outputs": [{"name": "Cuerda", "type": "crafting", "count": 1}],
					"value": 4
				},
			]

		WorkshopType.SMELTER:
			return [
				{
					"name": "Fundir Hierro",
					"id": "smelt_iron",
					"time": 20,
					"skill": "SMITHING",
					"inputs": [{"material": ["iron"], "count": 1}, {"fuel": true, "count": 1}],
					"outputs": [{"name": "Lingote de Hierro", "type": "metal_bar", "count": 2}],
					"value": 20
				},
				{
					"name": "Fundir Cobre",
					"id": "smelt_copper",
					"time": 15,
					"skill": "SMITHING",
					"inputs": [{"material": ["copper"], "count": 1}, {"fuel": true, "count": 1}],
					"outputs": [{"name": "Lingote de Cobre", "type": "metal_bar", "count": 3}],
					"value": 10
				},
				{
					"name": "Fundir Oro",
					"id": "smelt_gold",
					"time": 25,
					"skill": "SMITHING",
					"inputs": [{"material": ["gold"], "count": 1}, {"fuel": true, "count": 1}],
					"outputs": [{"name": "Lingote de Oro", "type": "metal_bar", "count": 1}],
					"value": 40
				},
				{
					"name": "Fundir Plata",
					"id": "smelt_silver",
					"time": 20,
					"skill": "SMITHING",
					"inputs": [{"material": ["silver"], "count": 1}, {"fuel": true, "count": 1}],
					"outputs": [{"name": "Lingote de Plata", "type": "metal_bar", "count": 2}],
					"value": 25
				},
				{
					"name": "Hacer Acero",
					"id": "make_steel",
					"time": 35,
					"skill": "SMITHING",
					"inputs": [{"material": ["iron"], "count": 2}, {"fuel": true, "count": 2}],
					"outputs": [{"name": "Lingote de Acero", "type": "metal_bar", "count": 1}],
					"value": 60,
					"skill_req": 5
				},
			]

		WorkshopType.FORGE:
			return [
				{
					"name": "Hacha de Batalla",
					"id": "forge_axe",
					"time": 25,
					"skill": "SMITHING",
					"inputs": [{"type": "metal_bar", "count": 3}, {"fuel": true, "count": 1}],
					"outputs": [{"name": "Hacha de Batalla", "type": "weapon", "count": 1, "weapon": "axe_battle"}],
					"value": 30
				},
				{
					"name": "Espada Corta",
					"id": "forge_sword",
					"time": 20,
					"skill": "SMITHING",
					"inputs": [{"type": "metal_bar", "count": 2}, {"fuel": true, "count": 1}],
					"outputs": [{"name": "Espada Corta", "type": "weapon", "count": 1, "weapon": "sword_short"}],
					"value": 25
				},
				{
					"name": "Lanza",
					"id": "forge_spear",
					"time": 18,
					"skill": "SMITHING",
					"inputs": [{"type": "metal_bar", "count": 2}, {"fuel": true, "count": 1}],
					"outputs": [{"name": "Lanza", "type": "weapon", "count": 1, "weapon": "spear"}],
					"value": 20
				},
				{
					"name": "Maza",
					"id": "forge_mace",
					"time": 22,
					"skill": "SMITHING",
					"inputs": [{"type": "metal_bar", "count": 3}, {"fuel": true, "count": 1}],
					"outputs": [{"name": "Maza", "type": "weapon", "count": 1, "weapon": "mace"}],
					"value": 28
				},
				{
					"name": "Espada Larga",
					"id": "forge_longsword",
					"time": 30,
					"skill": "SMITHING",
					"inputs": [{"type": "metal_bar", "count": 3}, {"fuel": true, "count": 1}],
					"outputs": [{"name": "Espada Larga", "type": "weapon", "count": 1, "weapon": "sword_long"}],
					"value": 35,
					"skill_req": 4
				},
				{
					"name": "Coraza",
					"id": "forge_breastplate",
					"time": 30,
					"skill": "SMITHING",
					"inputs": [{"type": "metal_bar", "count": 4}, {"fuel": true, "count": 2}],
					"outputs": [{"name": "Coraza de Metal", "type": "armor", "count": 1, "armor": "breastplate"}],
					"value": 40
				},
				{
					"name": "Cota de Malla",
					"id": "forge_mail",
					"time": 35,
					"skill": "SMITHING",
					"inputs": [{"type": "metal_bar", "count": 5}, {"fuel": true, "count": 2}],
					"outputs": [{"name": "Cota de Malla", "type": "armor", "count": 1, "armor": "mail_shirt"}],
					"value": 50
				},
				{
					"name": "Yelmo",
					"id": "forge_helmet",
					"time": 20,
					"skill": "SMITHING",
					"inputs": [{"type": "metal_bar", "count": 2}, {"fuel": true, "count": 1}],
					"outputs": [{"name": "Yelmo de Metal", "type": "armor", "count": 1, "armor": "helmet"}],
					"value": 22
				},
				{
					"name": "Ballesta",
					"id": "forge_crossbow",
					"time": 28,
					"skill": "SMITHING",
					"inputs": [{"type": "metal_bar", "count": 2}, {"material": ["wood"], "count": 1}],
					"outputs": [{"name": "Ballesta", "type": "weapon", "count": 1, "weapon": "crossbow"}],
					"value": 30
				},
				{
					"name": "Pico de Metal",
					"id": "forge_pickaxe",
					"time": 20,
					"skill": "SMITHING",
					"inputs": [{"type": "metal_bar", "count": 2}, {"fuel": true, "count": 1}],
					"outputs": [{"name": "Metal Pickaxe", "type": "tool", "count": 1}],
					"value": 25
				},
				{
					"name": "Hacha de Metal",
					"id": "forge_metal_axe",
					"time": 18,
					"skill": "SMITHING",
					"inputs": [{"type": "metal_bar", "count": 2}, {"fuel": true, "count": 1}],
					"outputs": [{"name": "Metal Axe", "type": "tool", "count": 1}],
					"value": 22
				},
			]

		WorkshopType.KITCHEN:
			return [
				{
					"name": "Preparar Comida",
					"id": "prepare_meal",
					"time": 10,
					"skill": "COOKING",
					"inputs": [{"type": "food", "count": 2}],
					"outputs": [{"name": "Comida Preparada", "type": "prepared_meal", "count": 3, "nutrition": 0.6}],
					"value": 5
				},
				{
					"name": "Guiso",
					"id": "make_stew",
					"time": 15,
					"skill": "COOKING",
					"inputs": [{"type": "food", "count": 3}],
					"outputs": [{"name": "Guiso Enano", "type": "prepared_meal", "count": 5, "nutrition": 0.8}],
					"value": 8
				},
				{
					"name": "Ración de Viaje",
					"id": "make_ration",
					"time": 20,
					"skill": "COOKING",
					"inputs": [{"type": "food", "count": 4}],
					"outputs": [{"name": "Ración de Viaje", "type": "prepared_meal", "count": 6, "nutrition": 0.9}],
					"value": 12
				},
			]

		WorkshopType.STILL:
			return [
				{
					"name": "Cerveza Enana",
					"id": "brew_dwarven_ale",
					"time": 15,
					"skill": "BREWING",
					"inputs": [{"type": "food", "count": 2}],
					"outputs": [{"name": "Cerveza Enana", "type": "drink", "count": 5, "nutrition": 0.4}],
					"value": 10
				},
				{
					"name": "Vino de Cuevas",
					"id": "brew_cave_wine",
					"time": 20,
					"skill": "BREWING",
					"inputs": [{"type": "food", "count": 3}],
					"outputs": [{"name": "Vino de Cuevas", "type": "drink", "count": 4, "nutrition": 0.5}],
					"value": 15
				},
			]

		WorkshopType.LOOM:
			return [
				{
					"name": "Tela de Fibra",
					"id": "weave_cloth",
					"time": 15,
					"skill": "CARPENTRY",
					"inputs": [{"type": "fiber", "count": 3}],
					"outputs": [{"name": "Tela de Fibra", "type": "cloth", "count": 2}],
					"value": 8
				},
			]

		WorkshopType.TANNER:
			return [
				{
					"name": "Curtir Cuero",
					"id": "tan_hide",
					"time": 15,
					"skill": "CARPENTRY",
					"inputs": [{"type": "hide", "count": 1}],
					"outputs": [{"name": "Cuero Curtido", "type": "leather", "count": 2}],
					"value": 6
				},
			]

		WorkshopType.CRAFT_SHOP:
			return [
				{
					"name": "Garra Decorativa",
					"id": "craft_trophy",
					"time": 10,
					"skill": "MASONRY",
					"inputs": [{"type": "crafting", "count": 1}, {"type": "mechanism", "count": 1, "optional": true}],
					"outputs": [{"name": "Trofeo de Caza", "type": "furniture", "count": 1}],
					"value": 20
				},
			]

		WorkshopType.JEWELER:
			return [
				{
					"name": "Anillo de Oro",
					"id": "craft_gold_ring",
					"time": 20,
					"skill": "MASONRY",
					"inputs": [{"type": "metal_bar", "count": 1, "specific": ["gold", "silver", "platinum"]}],
					"outputs": [{"name": "Anillo de Metal", "type": "furniture", "count": 1}],
					"value": 50
				},
				{
					"name": "Engarzar Gema",
					"id": "set_gem",
					"time": 25,
					"skill": "MASONRY",
					"inputs": [{"type": "gem", "count": 1}, {"type": "metal_bar", "count": 1}],
					"outputs": [{"name": "Joya Engarzada", "type": "furniture", "count": 1}],
					"value": 80
				},
			]

		WorkshopType.KILN:
			return [
				{
					"name": "Carbón Vegetal",
					"id": "make_charcoal",
					"time": 30,
					"skill": "SMITHING",
					"inputs": [{"material": ["wood"], "count": 2}],
					"outputs": [{"name": "Carbón Vegetal", "type": "fuel", "count": 3}],
					"value": 15
				},
				{
					"name": "Ceniza",
					"id": "make_ash",
					"time": 10,
					"skill": "SMITHING",
					"inputs": [{"material": ["wood"], "count": 1}],
					"outputs": [{"name": "Ceniza", "type": "crafting", "count": 2}],
					"value": 3
				},
			]

		WorkshopType.BUTCHER:
			return [
				{
					"name": "Descuartizar",
					"id": "butcher_creature",
					"time": 20,
					"skill": "COOKING",
					"inputs": [{"type": "corpse", "count": 1}],
					"outputs": [{"name": "Carne Fresca", "type": "food", "count": 4, "nutrition": 0.5},
						{"name": "Piel Cruda", "type": "hide", "count": 1},
						{"name": "Huesos", "type": "bone", "count": 3},
						{"name": "Cráneo", "type": "skull", "count": 1, "optional": true}],
					"value": 15
				},
				{
					"name": "Ahumar Carne",
					"id": "smoke_meat",
					"time": 25,
					"skill": "COOKING",
					"inputs": [{"type": "food", "count": 2, "specific": ["meat"]}],
					"outputs": [{"name": "Carne Ahumada", "type": "food", "count": 2, "nutrition": 0.8}],
					"value": 12
				},
			]

	return _append_json_reactions(ws_type, [])

static func _building_name_for_json(ws_type: int) -> String:
	var names = {
		WorkshopType.MASONRY: "MASONRY",
		WorkshopType.CARPENTRY: "CARPENTER",
		WorkshopType.FORGE: "FORGE",
		WorkshopType.SMELTER: "SMELTER",
		WorkshopType.KITCHEN: "KITCHEN",
		WorkshopType.STILL: "STILL",
		WorkshopType.LOOM: "LOOM",
		WorkshopType.TANNER: "TANNER",
		WorkshopType.CRAFT_SHOP: "CRAFTSHOP",
		WorkshopType.JEWELER: "JEWELER",
		WorkshopType.KILN: "KILN",
		WorkshopType.BUTCHER: "BUTCHER",
	}
	return names.get(ws_type, "")

static func _append_json_reactions(ws_type: int, base_recipes: Array) -> Array:
	var building_name = _building_name_for_json(ws_type)
	if building_name == "" or DFData.instance == null:
		return base_recipes
	var json_reactions = DFData.instance.get_reactions_for_building_name(building_name)
	if json_reactions.is_empty():
		return base_recipes
	var result = base_recipes.duplicate()
	for r in json_reactions:
		var rid = r.get("id", "")
		var rname = r.get("name", "")
		if rid == "" or rname == "":
			continue
		var already_exists = false
		for existing in result:
			if existing.get("id", "") == rid or existing.get("name", "") == rname:
				already_exists = true
				break
		if not already_exists:
			result.append({
				"name": rname,
				"id": rid,
				"time": 15,
				"skill": "CRAFTSMAN",
				"inputs": [{"type": "crafting", "count": 1}],
				"outputs": [{"name": rname, "type": "craft", "count": 1}],
				"value": 5,
				"_json": true
			})
	return result

# ---------- CLASE TALLER ----------
var workshop_type: int = WorkshopType.NONE
var tile_pos: Vector3i
var name: String = ""
var dwarf_assigned: int = -1
var operator_skill: int = 0  # ID del enano asignado (-1 = sin asignar)
var is_active: bool = false
var current_recipe: Dictionary = {}
var recipe_progress: float = 0.0
var production_queue: Array = []  # Cola de recetas a producir

var _rng: RandomNumberGenerator

func _init(type: int, pos: Vector3i):
	workshop_type = type
	tile_pos = pos
	name = WORKSHOP_NAMES.get(type, "Taller")
	_rng = RandomNumberGenerator.new()
	_rng.seed = randi()

func get_recipes() -> Array:
	var base = get_recipes_for(workshop_type)
	var extra = DFReactions.get_recipe_list_for_workshop(workshop_type, WORKSHOP_NAMES)
	var merged = base.duplicate()
	for r in extra:
		var dup = false
		for b in merged:
			if b.get("id", "") == r.get("id", ""):
				dup = true
				break
		if not dup:
			merged.append(r)
	return merged

func get_display_char() -> String:
	return WORKSHOP_GLYPHS.get(workshop_type, "?")

func get_display_color() -> Color:
	return WORKSHOP_COLORS.get(workshop_type, Color.WHITE)

func queue_recipe(recipe_id: String) -> bool:
	for r in get_recipes():
		if r["id"] == recipe_id:
			production_queue.append(r.duplicate(true))
			return true
	return false

func get_queue_count() -> int:
	return production_queue.size()

func tick(progress_amount: float) -> Dictionary:
	if production_queue.is_empty() or dwarf_assigned < 0:
		return {"progress": false}
	
	var recipe = production_queue[0]
	var speed_mult = 1.0 + operator_skill * 0.15
	recipe_progress += progress_amount * speed_mult
	
	if recipe_progress >= recipe["time"]:
		recipe_progress = 0.0
		var completed = production_queue.pop_front()
		completed["quality_bonus"] = operator_skill
		return {"progress": true, "recipe": completed, "completed": true}
	
	return {"progress": true, "completed": false}

func can_assign_dwarf(dwarf_id: int) -> bool:
	return dwarf_assigned < 0 or dwarf_assigned == dwarf_id

func assign_dwarf(dwarf_id: int, skill: int = 0) -> void:
	dwarf_assigned = dwarf_id
	operator_skill = skill
	is_active = true

func unassign_dwarf() -> void:
	dwarf_assigned = -1
	is_active = false

func get_status_string() -> String:
	if dwarf_assigned < 0:
		return "Sin operador"
	if production_queue.is_empty():
		return "Esperando órdenes"
	var recipe = production_queue[0]
	return "Fabricando: %s (%.0f%%)" % [recipe["name"], (recipe_progress / recipe["time"]) * 100.0]
