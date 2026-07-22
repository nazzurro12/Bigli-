extends RefCounted
class_name DFItem



enum ItemCategory {
	WEAPON, ARMOR, HELMET, GLOVES, SHOES, SHIELD, PANTS, AMMO,
	TOOL, FOOD, DRINK, SEED, RAW_MATERIAL, BAR, GEM, TOY,
	TRAP_COMPONENT, SIEGE_AMMO, CORPSE, SKIN, BONE, MEAT,
	FISH, EGG, CHEESE, CLOTH, THREAD, DYE, LEATHER, WOOD,
	STONE, ORE, CHARCOAL, POTION, SCROLL, BOOK, FLASK,
	BARREL, BAG, POT, MECHANISM, PARTS, TRASH, ARTIFACT,
	ASH, LYE, POTASH, PEARLASH, PLANTER, QUERN, MILLSTONE,
	SOAP, TALLOW, WAX, HONEY, HIVE, NEST_BOX, MINECART,
	WHEELBARROW, PEDESTAL, DISPLAY_CASE, ALTAR, ANIMAL_TRAP,
	DECORATION, DOOR, HATCH_COVER, FLOODGATE, WINDOW,
	GRATE, CAGE, CHAIN, ANVIL, CRAFTS
}

enum QualityLevel {
	NEGATIVE_5 = -5, NEGATIVE_4 = -4, NEGATIVE_3 = -3, NEGATIVE_2 = -2,
	NEGATIVE = -1, NORMAL = 0, WELL_CRAFTED = 1, FINELY_CRAFTED = 2,
	SUPERIOR = 3, EXCEPTIONAL = 4, FLAWLESS = 5, MASTERWORK = 6, ARTIFACT = 7
}

const QUALITY_NAMES = {
	QualityLevel.NEGATIVE_5: "Terrible", QualityLevel.NEGATIVE_4: "Pésimo",
	QualityLevel.NEGATIVE_3: "Horrible", QualityLevel.NEGATIVE_2: "Malo",
	QualityLevel.NEGATIVE: "Deficiente", QualityLevel.NORMAL: "Normal",
	QualityLevel.WELL_CRAFTED: "Bien Hecho", QualityLevel.FINELY_CRAFTED: "Fino",
	QualityLevel.SUPERIOR: "Superior", QualityLevel.EXCEPTIONAL: "Excepcional",
	QualityLevel.FLAWLESS: "Impecable", QualityLevel.MASTERWORK: "Obra Maestra",
	QualityLevel.ARTIFACT: "Artefacto"
}

const QUALITY_COLORS = {
	QualityLevel.NEGATIVE_5: Color("#444444"), QualityLevel.NEGATIVE_4: Color("#664444"),
	QualityLevel.NEGATIVE_3: Color("#884444"), QualityLevel.NEGATIVE_2: Color("#AA6644"),
	QualityLevel.NEGATIVE: Color("#CC8844"), QualityLevel.NORMAL: Color("#FFFFFF"),
	QualityLevel.WELL_CRAFTED: Color("#AAFFAA"), QualityLevel.FINELY_CRAFTED: Color("#88FF88"),
	QualityLevel.SUPERIOR: Color("#44FFDD"), QualityLevel.EXCEPTIONAL: Color("#44AAFF"),
	QualityLevel.FLAWLESS: Color("#AA88FF"), QualityLevel.MASTERWORK: Color("#FFD700"),
	QualityLevel.ARTIFACT: Color("#FF44FF")
}

const QUALITY_VALUE_MULTIPLIER = {
	QualityLevel.NEGATIVE_5: 0.1, QualityLevel.NEGATIVE_4: 0.2,
	QualityLevel.NEGATIVE_3: 0.3, QualityLevel.NEGATIVE_2: 0.5,
	QualityLevel.NEGATIVE: 0.7, QualityLevel.NORMAL: 1.0,
	QualityLevel.WELL_CRAFTED: 1.5, QualityLevel.FINELY_CRAFTED: 2.0,
	QualityLevel.SUPERIOR: 3.0, QualityLevel.EXCEPTIONAL: 5.0,
	QualityLevel.FLAWLESS: 8.0, QualityLevel.MASTERWORK: 15.0,
	QualityLevel.ARTIFACT: 100.0
}

enum DamageType { BLUNT, EDGE, PIERCE, MAGIC, FIRE }

const DECAY_TIMES = {
	"food": 200, "drink": 300, "corpse": 100, "meat": 150, "fish": 120,
	"egg": 180, "cheese": 400, "milk": 100, "honey": 1000
}

var DEFAULT_STACK_SIZE = {
	35: 5, 38: 3, 37: 3,
	44: 10, 43: 5, 46: 5,
	49: 10,
	4: 10, 5: 10, 21: 15,
	22: 5, 23: 5
}

var name: String = ""
var tile_pos: Vector3i
var item_type: String = ""
var item_category: int = ItemCategory.RAW_MATERIAL
var material: int = 0
var material_name: String = "stone"
var glyph: String = "*"
var display_color: Color = Color.WHITE
var id: int
static var _id_counter: int = 5000

var is_food: bool = false
var is_bed: bool = false
var is_drink: bool = false
var is_meat: bool = false
var is_corpse: bool = false
var is_organic: bool = false
var is_edible: bool = false
var nutrition: float = 0.3
var hydration: float = 0.0

# ---- OWNERSHIP / RESERVATIONS / EQUIPMENT TAGS ----
# Los objetos en el suelo tienen carried_by_id = -1. Al entrar en un inventario,
# carried_by_id guarda el ID persistente del enano que lo transporta.
var carried_by_id: int = -1
var reserved_by_id: int = -1
var reservation_expiry_tick: int = 0
var tool_tags: Array = []
var equipment_slot: String = ""

# ---- QUALITY ----
var quality: int = QualityLevel.NORMAL
var quality_name: String = ""
var quality_color: Color = Color.WHITE

# ---- DURABILITY / WEAR ----
var max_durability: float = 100.0
var durability: float = 100.0
var wear: float = 0.0
var is_broken: bool = false
var decay_timer: int = 0
var decay_time: int = -1
var rust_timer: int = 0
var is_corroded: bool = false
var is_in_water: bool = false
var is_decayed: bool = false

# ---- VALUE ----
var base_value: float = 1.0
var total_value: float = 1.0

# ---- STACK / CONTAINER ----
var stack_size: int = 1
var max_stack: int = 1
var is_container: bool = false
var container_volume: float = 0.0
var container_contents: Array = []
var contained_volume: float = 0.0
var is_inside_container: bool = false
var is_in_stockpile: bool = false
var container_id: int = -1

# ---- WEAPON / ARMOR PROPERTIES ----
var weapon_damage: float = 1.0
var weapon_type: int = DamageType.BLUNT
var armor_protection: float = 0.0
var armor_slot: String = ""
var is_weapon: bool = false
var is_armor: bool = false
var is_tool: bool = false

# ---- ARTIFACT ----
var is_artifact: bool = false
var artifact_name: String = ""
var artifact_powers: Array = []
var artifact_creator_id: int = -1
var artifact_creation_year: int = 0
var artifact_lore: String = ""

# ---- CUSTOMIZATION ----
var rune: String = ""
var decoration: String = ""
var dye_color: String = ""

func _init(pos: Vector3i, iname: String, itype: String, imat: int, cglyph: String, ccolor: Color):
	tile_pos = pos
	name = iname
	item_type = itype
	material = imat
	glyph = cglyph
	display_color = ccolor
	id = _id_counter
	_id_counter += 1
	material_name = _get_material_name(imat)
	_apply_type_defaults(itype)
	_apply_name_defaults()
	_determine_quality()
	_calculate_value()
	_calculate_durability()

func _get_material_name(imat: int) -> String:
	return DFMaterialProperties.enum_to_id(imat)

func _apply_type_defaults(itype: String) -> void:
	match itype:
		"food":
			is_food = true; is_edible = true; is_organic = true
			nutrition = 0.4; hydration = 0.03; item_category = ItemCategory.FOOD
			decay_time = DECAY_TIMES.get("food", 200)
		"drink":
			# Una bebida no debe entrar por la rama de comida.
			is_drink = true; is_edible = false; nutrition = 0.0; hydration = 0.5
			item_category = ItemCategory.DRINK; decay_time = DECAY_TIMES.get("drink", 300)
		"meat":
			is_meat = true; is_food = true; is_edible = true; is_organic = true
			nutrition = 0.6; hydration = 0.05; item_category = ItemCategory.MEAT
			decay_time = DECAY_TIMES.get("meat", 150)
		"corpse":
			is_corpse = true; is_organic = true; is_edible = false
			item_category = ItemCategory.CORPSE; decay_time = DECAY_TIMES.get("corpse", 100)
		"wood":
			item_category = ItemCategory.WOOD
			max_stack = DEFAULT_STACK_SIZE.get(ItemCategory.WOOD, 3)
		"stone", "iron_ore", "coal_ore", "gold_ore", "copper_ore", "tin_ore", "silver_ore", "platinum_ore":
			item_category = ItemCategory.ORE; max_stack = DEFAULT_STACK_SIZE.get(ItemCategory.STONE, 3)
		"iron_bar", "gold_bar", "silver_bar", "copper_bar", "bronze_bar", "steel_bar":
			item_category = ItemCategory.BAR; max_stack = DEFAULT_STACK_SIZE.get(ItemCategory.BAR, 5)
		"ash":
			item_category = ItemCategory.ASH; max_stack = 10
		"charcoal":
			item_category = ItemCategory.CHARCOAL; max_stack = 10
		"weapon":
			is_weapon = true; item_category = ItemCategory.WEAPON
			weapon_damage = 5.0; weapon_type = DamageType.EDGE
		"armor":
			is_armor = true; item_category = ItemCategory.ARMOR
			armor_protection = 5.0
		"tool":
			is_tool = true; item_category = ItemCategory.TOOL
		_:
			if "weapon" in itype or "sword" in itype or "axe" in itype or "mace" in itype or "hammer" in itype or "spear" in itype or "dagger" in itype or "pick" in itype or "crossbow" in itype or "bow" in itype:
				is_weapon = true; item_category = ItemCategory.WEAPON
				weapon_damage = 4.0
			elif "armor" in itype or "mail" in itype or "breastplate" in itype or "helm" in itype or "helmet" in itype or "shield" in itype or "buckler" in itype:
				is_armor = true; item_category = ItemCategory.ARMOR
				armor_protection = 4.0
			elif "barrel" in itype or "bag" in itype or "pot" in itype or "jug" in itype or "flask" in itype or "minecart" in itype or "wheelbarrow" in itype:
				is_container = true; item_category = ItemCategory.BARREL
				container_volume = 100.0

func _apply_name_defaults() -> void:
	var lower_name: String = name.to_lower()

	if is_tool or is_weapon:
		if "pico" in lower_name or "pickaxe" in lower_name or "piqueta" in lower_name:
			tool_tags.append("mining")
		elif "hacha" in lower_name or "woodcutter axe" in lower_name:
			tool_tags.append("woodcutting")
		elif "azada" in lower_name or "hoe" in lower_name:
			tool_tags.append("farming")
		elif "ballesta" in lower_name or "crossbow" in lower_name or "arco" in lower_name or "bow" in lower_name:
			tool_tags.append("hunting")
		elif "bistur" in lower_name or "venda" in lower_name or "medical" in lower_name:
			tool_tags.append("medicine")

	if is_armor:
		equipment_slot = armor_slot if not armor_slot.is_empty() else "body"
	elif is_weapon:
		equipment_slot = "weapon"
	elif is_tool:
		equipment_slot = "tool"

func reserve_for(dwarf_id: int, expiry_tick: int) -> void:
	reserved_by_id = dwarf_id
	reservation_expiry_tick = expiry_tick

func release_reservation(requester_id: int = -1) -> void:
	if requester_id >= 0 and reserved_by_id != requester_id:
		return
	reserved_by_id = -1
	reservation_expiry_tick = 0

func is_reserved_for_other(dwarf_id: int, current_tick: int) -> bool:
	if reserved_by_id < 0:
		return false
	if reservation_expiry_tick > 0 and current_tick >= reservation_expiry_tick:
		release_reservation()
		return false
	return reserved_by_id != dwarf_id

func _determine_quality() -> void:
	if is_artifact:
		quality = QualityLevel.ARTIFACT
	elif is_food or is_drink:
		quality = QualityLevel.NORMAL
	else:
		var roll = randi() % 100
		if roll < 5: quality = QualityLevel.WELL_CRAFTED
		elif roll < 10: quality = QualityLevel.FINELY_CRAFTED
		elif roll < 13: quality = QualityLevel.SUPERIOR
		elif roll < 15: quality = QualityLevel.EXCEPTIONAL
		elif roll < 16: quality = QualityLevel.FLAWLESS
		elif roll < 17: quality = QualityLevel.MASTERWORK
		elif roll < 2: quality = QualityLevel.NEGATIVE
		else: quality = QualityLevel.NORMAL
	quality_name = QUALITY_NAMES.get(quality, "Normal")
	quality_color = QUALITY_COLORS.get(quality, Color.WHITE)

func set_quality(level: int) -> void:
	quality = clampi(level, 0, QualityLevel.ARTIFACT)
	quality_name = QUALITY_NAMES.get(quality, "Normal")
	quality_color = QUALITY_COLORS.get(quality, Color.WHITE)
	_calculate_value()
	_calculate_durability()

func _calculate_value() -> void:
	var mat_name = _get_material_name(material)
	var mat_props = DFMaterialProperties.compute_by_id(mat_name)
	var material_val = DFMaterialProperties.get_value_factor(mat_props, 1)
	var quality_mult = QUALITY_VALUE_MULTIPLIER.get(quality, 1.0)
	var size_factor = 1.0
	if is_weapon: size_factor = 3.0
	elif is_armor: size_factor = 5.0
	elif is_food: size_factor = 0.5
	elif is_drink: size_factor = 0.5
	base_value = material_val * 10.0 * size_factor
	total_value = base_value * quality_mult

func _calculate_durability() -> void:
	var mat_name = _get_material_name(material)
	var mat_props = DFMaterialProperties.compute_by_id(mat_name)
	var strength = DFMaterialProperties.get_strength_factor(mat_props)
	max_durability = 50.0 + strength * 60.0
	if quality >= QualityLevel.MASTERWORK:
		max_durability *= 2.0
	elif quality >= QualityLevel.FLAWLESS:
		max_durability *= 1.5
	elif quality <= QualityLevel.NEGATIVE:
		max_durability *= 0.5
	durability = max_durability

func apply_wear(amount: float) -> void:
	if is_broken: return
	wear += amount
	durability = maxf(0.0, durability - amount)
	if durability <= 0:
		is_broken = true
		name = "%s (roto)" % name
		if is_weapon: weapon_damage *= 0.3
		if is_armor: armor_protection *= 0.2

func repair(amount: float) -> void:
	if is_broken:
		var fix_threshold = max_durability * 0.1
		if amount >= fix_threshold:
			is_broken = false
			durability = max_durability * 0.3
			name = name.replace(" (roto)", "")
		else:
			return
	durability = minf(max_durability, durability + amount)
	wear = maxf(0.0, wear - amount)

func tick_decay() -> void:
	if is_decayed or is_broken: return
	if is_inside_container: return
	tick_organic_decay()
	tick_metal_rust()
	tick_wear_and_tear()
	if durability <= 0:
		is_broken = true
		name = "%s (roto)" % name
		if is_weapon: weapon_damage *= 0.3
		if is_armor: armor_protection *= 0.2

func tick_organic_decay() -> void:
	if not is_organic or decay_time < 0: return
	var effective_dt = 1.0
	if is_in_stockpile:
		effective_dt = 0.5
	if is_in_water:
		effective_dt = 0.0
	decay_timer += effective_dt
	var season_mult = 1.0
	var season_idx = _get_current_season_index()
	match season_idx:
		0: season_mult = 0.7
		1: season_mult = 1.5
		2: season_mult = 1.0
		3: season_mult = 0.4
	if decay_timer >= decay_time * season_mult:
		is_decayed = true
		is_edible = false
		name = "%s (podrido)" % name
		display_color = display_color.darkened(0.3)
		nutrition *= 0.2

func tick_metal_rust() -> void:
	if not _is_metal() or is_corroded: return
	rust_timer += 1
	var rust_threshold = 2000
	if tile_pos.y >= _get_surface_y(): rust_threshold = 800
	if rust_timer >= rust_threshold:
		durability = maxf(0.0, durability - 1.0)
		if durability <= 0:
			is_corroded = true
			name = "%s (oxidado)" % name
			if is_weapon: weapon_damage *= 0.5
			if is_armor: armor_protection *= 0.5

func tick_wear_and_tear() -> void:
	if is_organic: return
	if randi() % 5000 == 0:
		durability = maxf(0.0, durability - 0.5)

func _is_metal() -> bool:
	return item_type in ["weapon", "armor", "helmet", "shoes", "gloves", "pants", "shield", "ammo", "tool", "mechanism", "chain", "anvil", "trap_component", "pick", "axe"]

func _get_current_season_index() -> int:
	return 0

func _get_surface_y() -> int:
	return 0

func get_quality_string() -> String:
	if quality == QualityLevel.NORMAL: return ""
	return quality_name

func get_full_name() -> String:
	var prefix = ""
	if is_artifact: prefix = "Artefacto: "
	elif quality != QualityLevel.NORMAL: prefix = quality_name + " "
	var suffix = ""
	if is_broken: suffix = " (roto)"
	if is_decayed: suffix = " (podrido)"
	return "%s%s%s" % [prefix, name.capitalize(), suffix]

func get_display_char() -> String:
	if is_broken: return "x"
	if is_corpse: return "%"
	if is_food: return "%"
	if is_drink: return "~"
	if is_container: return "O"
	if is_weapon: return "/"
	if is_armor: return "["
	return glyph

func get_display_color() -> Color:
	if is_decayed: return display_color.darkened(0.4)
	if is_broken: return Color("#666666")
	if quality != QualityLevel.NORMAL: return quality_color
	return display_color

func get_lore_text() -> String:
	if is_artifact:
		return "Un %s: '%s'. Creado en el año %d por un artesano legendario." % [get_full_name(), artifact_name, artifact_creation_year]
	return "Un(a) %s tirado(a) en el suelo." % name

func get_value_string() -> String:
	if total_value >= 1000: return "%.0fK☼" % (total_value / 1000.0)
	return "%d☼" % int(total_value)

func get_condition_percent() -> float:
	if max_durability <= 0: return 1.0
	return maxf(0.0, durability / max_durability)

func get_condition_label() -> String:
	var pct = get_condition_percent()
	if pct >= 0.9: return "Como nuevo"
	elif pct >= 0.7: return "Buen estado"
	elif pct >= 0.5: return "Usado"
	elif pct >= 0.3: return "Gastado"
	elif pct > 0: return "Deteriorado"
	return "Roto"

func has_container_space(item) -> bool:
	if not is_container: return false
	return contained_volume + item.get_item_volume() <= container_volume

func get_item_volume() -> float:
	if is_weapon: return 3.0
	if is_armor: return 5.0
	if is_container: return 10.0
	if is_food: return 0.5
	if is_drink: return 0.5
	return 1.0

func put_in_container(container) -> void:
	is_inside_container = true
	container_id = container.id
	container.container_contents.append(self)
	container.contained_volume += get_item_volume()

func remove_from_container() -> void:
	is_inside_container = false
	container_id = -1

func can_stack_with(other) -> bool:
	if other == null: return false
	if other.item_type != item_type: return false
	if other.material != material: return false
	if other.quality != quality: return false
	if other.is_broken or is_broken: return false
	if other.is_artifact or is_artifact: return false
	return true

func try_stack(other) -> bool:
	if not can_stack_with(other): return false
	var combined = stack_size + other.stack_size
	if combined <= max_stack:
		stack_size = combined
		other.stack_size = 0
		return true
	else:
		var room = max_stack - stack_size
		stack_size = max_stack
		other.stack_size -= room
		return true

func split_stack(amount: int):
	if amount <= 0 or amount >= stack_size: return null
	var new_item = get_script().new(tile_pos, name, item_type, material, glyph, display_color)
	new_item.stack_size = amount
	new_item.quality = quality
	new_item.durability = durability
	new_item.max_durability = max_durability
	new_item.wear = wear
	new_item.is_broken = is_broken
	new_item.is_food = is_food
	new_item.is_drink = is_drink
	new_item.is_edible = is_edible
	new_item.is_organic = is_organic
	new_item.nutrition = nutrition
	new_item.hydration = hydration
	new_item.tool_tags = tool_tags.duplicate()
	new_item.equipment_slot = equipment_slot
	new_item.carried_by_id = carried_by_id
	new_item.total_value = total_value * float(amount) / float(stack_size)
	stack_size -= amount
	return new_item

func get_description() -> String:
	var desc = get_full_name()
	if is_weapon: desc += " (Daño: %.1f)" % weapon_damage
	if is_armor: desc += " (Protección: %.1f)" % armor_protection
	if stack_size > 1: desc += " [x%d]" % stack_size
	desc += " " + get_value_string()
	return desc

func extend_description() -> String:
	var desc = get_full_name()
	desc += "\nMaterial: %s" % material_name.capitalize()
	if quality != QualityLevel.NORMAL:
		desc += "\nCalidad: %s" % quality_name
	desc += "\nCondición: %s (%d%%)" % [get_condition_label(), int(get_condition_percent() * 100)]
	desc += "\nValor: %s" % get_value_string()
	if is_weapon:
		var dtype = {DamageType.BLUNT: "Contundente", DamageType.EDGE: "Cortante", DamageType.PIERCE: "Perforante"}
		desc += "\nDaño: %.1f (%s)" % [weapon_damage, dtype.get(weapon_type, "Genérico")]
	if is_armor:
		desc += "\nProtección: %.1f" % armor_protection
	if is_container:
		desc += "\nCapacidad: %.0f/%.0f" % [contained_volume, container_volume]
	if is_organic and decay_time > 0:
		var decay_pct = int(float(decay_timer) / float(decay_time) * 100)
		desc += "\nDescomposición: %d%%" % decay_pct
	if is_artifact:
		desc += "\n¡ARTEFACTO LEGENDARIO!"
		desc += "\n'%s'" % artifact_name
		if not artifact_lore.is_empty():
			desc += "\n%s" % artifact_lore
	return desc

func create_artifact(base_name: String, creator: String, year: int) -> void:
	is_artifact = true
	quality = QualityLevel.ARTIFACT
	quality_name = "Artefacto"
	quality_color = Color("#FF44FF")
	artifact_name = "%s de %s" % [base_name, creator]
	artifact_creator_id = creator.hash()
	artifact_creation_year = year
	base_value *= 100.0
	total_value = base_value
	max_durability *= 3.0
	durability = max_durability
	var themes = [
		"la noche eterna", "los susurros de la piedra", "el fuego interior",
		"el vacío potencial", "los cuarenta y ocho", "la luna fragmentada",
		"el eco del abismo", "la memoria del mundo", "el sueño de los dioses",
		"la danza de las sombras"
	]
	var powers = [
		"brillo tenue en la oscuridad", "calor reconfortante",
		"susurros de advertencia", "suerte en la minería",
		"protección contra el mal", "peso reducido"
	]
	artifact_lore = "Se dice que '%s' fue creado en el año %d por %s, inspirado por %s. Se rumorea que posee %s." % [
		artifact_name, year, creator,
		themes[randi() % themes.size()],
		powers[randi() % powers.size()]
	]

func add_rune(rune_name: String) -> void:
	rune = rune_name
	if is_weapon: weapon_damage *= 1.2
	if is_armor: armor_protection *= 1.2
	total_value *= 1.5

func add_decoration(deco_type: String, deco_material: String = "gold") -> void:
	decoration = "%s de %s" % [deco_type, deco_material]
	total_value *= 1.3

func get_quality_damage_multiplier() -> float:
	var mults = {
		QualityLevel.NEGATIVE_5: 0.5, QualityLevel.NEGATIVE_4: 0.6,
		QualityLevel.NEGATIVE_3: 0.7, QualityLevel.NEGATIVE_2: 0.8,
		QualityLevel.NEGATIVE: 0.9, QualityLevel.NORMAL: 1.0,
		QualityLevel.WELL_CRAFTED: 1.15, QualityLevel.FINELY_CRAFTED: 1.3,
		QualityLevel.SUPERIOR: 1.5, QualityLevel.EXCEPTIONAL: 1.8,
		QualityLevel.FLAWLESS: 2.2, QualityLevel.MASTERWORK: 3.0,
		QualityLevel.ARTIFACT: 5.0
	}
	return mults.get(quality, 1.0)

func get_quality_armor_multiplier() -> float:
	var mults = {
		QualityLevel.NEGATIVE_5: 0.4, QualityLevel.NEGATIVE_4: 0.5,
		QualityLevel.NEGATIVE_3: 0.6, QualityLevel.NEGATIVE_2: 0.7,
		QualityLevel.NEGATIVE: 0.85, QualityLevel.NORMAL: 1.0,
		QualityLevel.WELL_CRAFTED: 1.2, QualityLevel.FINELY_CRAFTED: 1.4,
		QualityLevel.SUPERIOR: 1.7, QualityLevel.EXCEPTIONAL: 2.0,
		QualityLevel.FLAWLESS: 2.5, QualityLevel.MASTERWORK: 3.5,
		QualityLevel.ARTIFACT: 6.0
	}
	return mults.get(quality, 1.0)

func get_effective_weapon_damage() -> float:
	return weapon_damage * get_quality_damage_multiplier()

func get_effective_armor_protection() -> float:
	return armor_protection * get_quality_armor_multiplier()
