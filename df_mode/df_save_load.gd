extends RefCounted
class_name DFSaveLoad

const SAVE_DIR = "user://saves/"

static func _v3i_to_arr(v: Vector3i) -> Array:
	return [v.x, v.y, v.z]

static func _arr_to_v3i(a: Array) -> Vector3i:
	if a.size() < 3: return Vector3i.ZERO
	return Vector3i(a[0], a[1], a[2])

static func _color_to_arr(c: Color) -> Array:
	return [c.r, c.g, c.b, c.a]

static func _arr_to_color(a: Array) -> Color:
	if a.size() < 4: return Color.WHITE
	return Color(a[0], a[1], a[2], a[3])

static func _body_part_to_dict(bp) -> Dictionary:
	return {
		"name": bp.name,
		"is_vital": bp.is_vital,
		"is_severed": bp.is_severed,
		"skin_damage": bp.skin_damage,
		"fat_damage": bp.fat_damage,
		"muscle_damage": bp.muscle_damage,
		"bone_damage": bp.bone_damage,
		"organ_damage": bp.organ_damage,
		"has_bone": bp.has_bone,
		"has_organ": bp.has_organ,
		"can_grasp": bp.can_grasp,
		"can_stand": bp.can_stand,
		"coatings": bp.coatings.duplicate(),
		"connected_parts": []
	}

static func _body_to_dict(body) -> Dictionary:
	if body == null: return {}
	var parts_data = []
	for p in body.parts:
		parts_data.append(_body_part_to_dict(p))
	return {
		"parts": parts_data,
		"blood_level": body.blood_level,
		"bleed_rate": body.bleed_rate,
		"is_dead": body.is_dead,
		"ingested_substances": body.ingested_substances.duplicate(),
		"ebriety": body.ebriety,
		"disease_type": body.disease_type,
		"nausea": body.nausea,
		"is_vomiting": body.is_vomiting
	}

static func _dict_to_body(d: Dictionary):
	if d.is_empty(): return null
	var body = DFAnatomy.Body.new("humanoid")
	body.blood_level = d.get("blood_level", 100.0)
	body.bleed_rate = d.get("bleed_rate", 0.0)
	body.is_dead = d.get("is_dead", false)
	body.ingested_substances = d.get("ingested_substances", {}).duplicate()
	body.ebriety = d.get("ebriety", 0.0)
	body.disease_type = d.get("disease_type", "")
	body.nausea = d.get("nausea", 0.0)
	body.is_vomiting = d.get("is_vomiting", false)
	var parts_data = d.get("parts", [])
	body.parts = []
	body.root = null
	for pd in parts_data:
		var bp = DFAnatomy.BodyPart.new(pd.get("name", ""), pd.get("is_vital", false))
		bp.is_severed = pd.get("is_severed", false)
		bp.skin_damage = pd.get("skin_damage", 0.0)
		bp.fat_damage = pd.get("fat_damage", 0.0)
		bp.muscle_damage = pd.get("muscle_damage", 0.0)
		bp.bone_damage = pd.get("bone_damage", 0.0)
		bp.organ_damage = pd.get("organ_damage", 0.0)
		bp.has_bone = pd.get("has_bone", true)
		bp.has_organ = pd.get("has_organ", false)
		bp.can_grasp = pd.get("can_grasp", false)
		bp.can_stand = pd.get("can_stand", false)
		bp.coatings = pd.get("coatings", {}).duplicate()
		body.parts.append(bp)
		if bp.name == "Torso Superior" or (body.root == null and bp.is_vital == false and bp.has_organ):
			body.root = bp
	if body.root == null and body.parts.size() > 0:
		body.root = body.parts[0]
	return body

static func _genome_to_dict(g) -> Dictionary:
	if g == null: return {}
	return {
		"size_multiplier": g.size_multiplier,
		"metabolic_rate": g.metabolic_rate,
		"alcohol_tolerance": g.alcohol_tolerance,
		"pathogen_resistance": g.pathogen_resistance
	}

static func _dict_to_genome(d: Dictionary):
	if d.is_empty(): return null
	var g = DFGenetics.Genome.new(
		d.get("size_multiplier", 1.0),
		d.get("metabolic_rate", 1.0),
		d.get("alcohol_tolerance", 1.0),
		d.get("pathogen_resistance", 1.0)
	)
	return g

static func _item_to_dict(item) -> Dictionary:
	return {
		"__type": "DFItem",
		"name": item.name,
		"tile_pos": _v3i_to_arr(item.tile_pos),
		"item_type": item.item_type,
		"item_category": item.item_category,
		"material": item.material,
		"material_name": item.material_name,
		"glyph": item.glyph,
		"display_color": _color_to_arr(item.display_color),
		"id": item.id,
		"is_food": item.is_food,
		"is_drink": item.is_drink,
		"is_meat": item.is_meat,
		"is_corpse": item.is_corpse,
		"is_organic": item.is_organic,
		"is_edible": item.is_edible,
		"nutrition": item.nutrition,
		"quality": item.quality,
		"max_durability": item.max_durability,
		"durability": item.durability,
		"wear": item.wear,
		"is_broken": item.is_broken,
		"decay_timer": item.decay_timer,
		"decay_time": item.decay_time,
		"rust_timer": item.rust_timer,
		"is_corroded": item.is_corroded,
		"is_in_water": item.is_in_water,
		"is_decayed": item.is_decayed,
		"base_value": item.base_value,
		"total_value": item.total_value,
		"stack_size": item.stack_size,
		"max_stack": item.max_stack,
		"is_container": item.is_container,
		"container_volume": item.container_volume,
		"container_contents": [],
		"contained_volume": item.contained_volume,
		"is_inside_container": item.is_inside_container,
		"is_in_stockpile": item.is_in_stockpile,
		"container_id": item.container_id,
		"weapon_damage": item.weapon_damage,
		"weapon_type": item.weapon_type,
		"armor_protection": item.armor_protection,
		"armor_slot": item.armor_slot,
		"is_weapon": item.is_weapon,
		"is_armor": item.is_armor,
		"is_tool": item.is_tool,
		"is_artifact": item.is_artifact,
		"artifact_name": item.artifact_name,
		"artifact_powers": item.artifact_powers.duplicate(),
		"artifact_creator_id": item.artifact_creator_id,
		"artifact_creation_year": item.artifact_creation_year,
		"artifact_lore": item.artifact_lore,
		"rune": item.rune,
		"decoration": item.decoration,
		"dye_color": item.dye_color
	}

static func _dict_to_item(d: Dictionary):
	var pos = _arr_to_v3i(d.get("tile_pos", [0, 0, 0]))
	var item = DFItem.new(pos, d.get("name", ""), d.get("item_type", ""), d.get("material", 0), d.get("glyph", "*"), _arr_to_color(d.get("display_color", [1,1,1,1])))
	item.id = d.get("id", item.id)
	if item.id >= DFItem._id_counter: DFItem._id_counter = item.id + 1
	item.item_category = d.get("item_category", item.item_category)
	item.material_name = d.get("material_name", item.material_name)
	item.is_food = d.get("is_food", false)
	item.is_drink = d.get("is_drink", false)
	item.is_meat = d.get("is_meat", false)
	item.is_corpse = d.get("is_corpse", false)
	item.is_organic = d.get("is_organic", false)
	item.is_edible = d.get("is_edible", false)
	item.nutrition = d.get("nutrition", 0.3)
	item.quality = d.get("quality", 0)
	item.quality_name = item.QUALITY_NAMES.get(item.quality, "Normal")
	item.quality_color = item.QUALITY_COLORS.get(item.quality, Color.WHITE)
	item.max_durability = d.get("max_durability", 100.0)
	item.durability = d.get("durability", 100.0)
	item.wear = d.get("wear", 0.0)
	item.is_broken = d.get("is_broken", false)
	item.decay_timer = d.get("decay_timer", 0)
	item.decay_time = d.get("decay_time", -1)
	item.rust_timer = d.get("rust_timer", 0)
	item.is_corroded = d.get("is_corroded", false)
	item.is_in_water = d.get("is_in_water", false)
	item.is_decayed = d.get("is_decayed", false)
	item.base_value = d.get("base_value", 1.0)
	item.total_value = d.get("total_value", 1.0)
	item.stack_size = d.get("stack_size", 1)
	item.max_stack = d.get("max_stack", 1)
	item.is_container = d.get("is_container", false)
	item.container_volume = d.get("container_volume", 0.0)
	item.contained_volume = d.get("contained_volume", 0.0)
	item.is_inside_container = d.get("is_inside_container", false)
	item.is_in_stockpile = d.get("is_in_stockpile", false)
	item.container_id = d.get("container_id", -1)
	item.weapon_damage = d.get("weapon_damage", 1.0)
	item.weapon_type = d.get("weapon_type", 0)
	item.armor_protection = d.get("armor_protection", 0.0)
	item.armor_slot = d.get("armor_slot", "")
	item.is_weapon = d.get("is_weapon", false)
	item.is_armor = d.get("is_armor", false)
	item.is_tool = d.get("is_tool", false)
	item.is_artifact = d.get("is_artifact", false)
	item.artifact_name = d.get("artifact_name", "")
	item.artifact_powers = d.get("artifact_powers", []).duplicate()
	item.artifact_creator_id = d.get("artifact_creator_id", -1)
	item.artifact_creation_year = d.get("artifact_creation_year", 0)
	item.artifact_lore = d.get("artifact_lore", "")
	item.rune = d.get("rune", "")
	item.decoration = d.get("decoration", "")
	item.dye_color = d.get("dye_color", "")
	return item

static func _dwarf_to_dict(dwarf) -> Dictionary:
	return {
		"__type": "DFDwarf",
		"home_z": dwarf.home_z,
		"is_possessed": dwarf.is_possessed,
		"body": _body_to_dict(dwarf.body),
		"name": dwarf.name,
		"tile_pos": _v3i_to_arr(dwarf.tile_pos),
		"id": dwarf.id,
		"hunger": dwarf.hunger,
		"thirst": dwarf.thirst,
		"fatigue": dwarf.fatigue,
		"happiness": dwarf.happiness,
		"health": dwarf.health,
		"inventory": [],
		"thoughts": dwarf.thoughts.duplicate(),
		"minutes_since_alcohol": dwarf.minutes_since_alcohol,
		"skills": dwarf.skills.duplicate(),
		"current_task": dwarf.current_task,
		"task_progress": dwarf.task_progress,
		"task_target": _v3i_to_arr(dwarf.task_target),
		"is_alive": dwarf.is_alive,
		"gender": dwarf.gender,
		"age": dwarf.age,
		"birth_year": dwarf.birth_year,
		"caste": dwarf.caste,
		"glyph": dwarf.glyph,
		"display_color": _color_to_arr(dwarf.display_color),
		"is_world_settlement_resident": dwarf.is_world_settlement_resident,
		"settlement_site_id": dwarf.settlement_site_id,
		"settlement_family_id": dwarf.settlement_family_id,
		"home_structure_id": dwarf.home_structure_id,
		"work_structure_id": dwarf.work_structure_id,
		"civilization_id": dwarf.civilization_id,
		"religion_id": dwarf.religion_id,
		"settlement_home_position": _v3i_to_arr(dwarf.settlement_home_position),
		"settlement_work_position": _v3i_to_arr(dwarf.settlement_work_position),
		"settlement_leisure_position": _v3i_to_arr(dwarf.settlement_leisure_position),
		"settlement_work_label": dwarf.settlement_work_label,
		"path": [],
		"path_index": dwarf.path_index,
		"last_pos": _v3i_to_arr(dwarf.last_pos),
		"stuck_counter": dwarf.stuck_counter,
		"move_tick_counter": dwarf.move_tick_counter,
		"speed": dwarf.speed,
		"has_moved_this_tick": dwarf.has_moved_this_tick,
		"needs_display_update": true,
		"strength": dwarf.strength,
		"agility": dwarf.agility,
		"toughness": dwarf.toughness,
		"combat_skill": dwarf.combat_skill,
		"weapon_skill": dwarf.weapon_skill,
		"shield_skill": dwarf.shield_skill,
		"dodge_skill": dwarf.dodge_skill,
		"armor_value": dwarf.armor_value,
		"equipped_weapon": dwarf.equipped_weapon,
		"equipped_armor": dwarf.equipped_armor,
		"equipped_shield": dwarf.equipped_shield,
		"equipped_helmet": dwarf.equipped_helmet,
		"has_shield": dwarf.has_shield,
		"is_military": dwarf.is_military,
		"squad_id": dwarf.squad_id,
		"creature_type": dwarf.creature_type,
		"combat_cooldown": dwarf.combat_cooldown,
		"combat_stance": dwarf.combat_stance,
		"fatigue_level": dwarf.fatigue_level,
		"target_entity_id": dwarf.target_entity_id,
		"kill_count": dwarf.kill_count,
		"wounds": dwarf.wounds.duplicate(),
		"scars": dwarf.scars.duplicate(),
		"wounds_head": dwarf.wounds_head,
		"wounds_upper_body": dwarf.wounds_upper_body,
		"wounds_lower_body": dwarf.wounds_lower_body,
		"wounds_arm_l": dwarf.wounds_arm_l,
		"wounds_arm_r": dwarf.wounds_arm_r,
		"wounds_leg_l": dwarf.wounds_leg_l,
		"wounds_leg_r": dwarf.wounds_leg_r,
		"stats_tracker": dwarf.stats_tracker.duplicate(),
		"personality": dwarf.personality.duplicate(),
		"emotions": dwarf.emotions.duplicate(),
		"current_emotion": dwarf.current_emotion,
		"emotion_intensity": dwarf.emotion_intensity,
		"stress": dwarf.stress,
		"trauma": dwarf.trauma.duplicate(),
		"relationships": dwarf.relationships.duplicate(),
		"family": dwarf.family.duplicate(),
		"friends": dwarf.friends.duplicate(),
		"rivals": dwarf.rivals.duplicate(),
		"preferences": dwarf.preferences.duplicate(),
		"memories": dwarf.memories.duplicate(),
		"recent_events": dwarf.recent_events.duplicate(),
		"prayer_counter": dwarf.prayer_counter,
		"meditation_counter": dwarf.meditation_counter,
		"artistic_inspiration": dwarf.artistic_inspiration,
		"creative_works": dwarf.creative_works.duplicate(),
		"needs": dwarf.needs.duplicate(),
		"mood": dwarf.mood,
		"mood_counter": dwarf.mood_counter,
		"tantrum_destruction": dwarf.tantrum_destruction,
		"profession": dwarf.profession,
		"appointed_position": dwarf.appointed_position,
		"is_noble": dwarf.is_noble,
		"noble_rank": dwarf.noble_rank,
		"demands": dwarf.demands.duplicate(),
		"mandates": dwarf.mandates.duplicate(),
		"sleep_timer": dwarf.sleep_timer,
		"is_sleeping": dwarf.is_sleeping,
		"is_resting_medical": dwarf.is_resting_medical,
		"sleep_quality": dwarf.sleep_quality,
		"preferred_bed": _v3i_to_arr(dwarf.preferred_bed),
		"room_quality": dwarf.room_quality,
		"social_timer": dwarf.social_timer,
		"last_social_interaction": dwarf.last_social_interaction,
		"loneliness": dwarf.loneliness,
		"prayer_timer": dwarf.prayer_timer,
		"favored_deity": dwarf.favored_deity,
		"religious_fervor": dwarf.religious_fervor,
		"preferred_food": dwarf.preferred_food,
		"preferred_drink": dwarf.preferred_drink,
		"preferred_color": _color_to_arr(dwarf.preferred_color),
		"preferred_stone": dwarf.preferred_stone,
		"learning_counter": dwarf.learning_counter,
		"knowledge": dwarf.knowledge.duplicate(),
		"pain_threshold": dwarf.pain_threshold,
		"current_pain": dwarf.current_pain,
		"is_in_pain": dwarf.is_in_pain,
		"bleeding_rate": dwarf.bleeding_rate,
		"is_bleeding": dwarf.is_bleeding,
		"infection_chance": dwarf.infection_chance,
		"has_infection": dwarf.has_infection,
		"rest_timer": dwarf.rest_timer,
		"nausea": dwarf.nausea,
		"is_vomiting": dwarf.is_vomiting,
		"dizziness": dwarf.dizziness,
		"is_stunned": dwarf.is_stunned,
		"stun_timer": dwarf.stun_timer,
		"noise_made": dwarf.noise_made,
		"stealth_skill": dwarf.stealth_skill,
		"territory_home": _v3i_to_arr(dwarf.territory_home),
		"owned_items": dwarf.owned_items.duplicate(),
		"claimed_bed": _v3i_to_arr(dwarf.claimed_bed),
		"claimed_container": _v3i_to_arr(dwarf.claimed_container),
		"labor_settings": dwarf.labor_settings.duplicate(),
		"is_on_break": dwarf.is_on_break,
		"break_timer": dwarf.break_timer,
		"socialized_recently": dwarf.socialized_recently,
		"genome": _genome_to_dict(dwarf.genome),
		"body_mass_kg": dwarf.body_mass_kg,
		"is_pregnant": dwarf.is_pregnant,
		"pregnancy_progress": dwarf.pregnancy_progress,
		"partner_id": dwarf.partner_id,
		"marriage_counter": dwarf.marriage_counter,
		"is_child": dwarf.is_child,
		"mother_id": dwarf.mother_id,
		"father_id": dwarf.father_id
	}

static func _dict_to_dwarf(d: Dictionary):
	var DFDwarf = load("res://df_mode/df_dwarf.gd")
	var pos = _arr_to_v3i(d.get("tile_pos", [0, 0, 0]))
	var df = DFDwarf.new(pos, d.get("name", "Urist"))
	df.id = d.get("id", df.id)
	if df.id >= DFDwarf._id_counter: DFDwarf._id_counter = df.id + 1
	df.home_z = d.get("home_z", 0)
	df.is_possessed = d.get("is_possessed", false)
	df.body = _dict_to_body(d.get("body", {}))
	df.hunger = d.get("hunger", 0.0)
	df.thirst = d.get("thirst", 0.0)
	df.fatigue = d.get("fatigue", 0.0)
	df.happiness = d.get("happiness", 0.8)
	df.health = d.get("health", 1.0)
	df.thoughts = d.get("thoughts", []).duplicate()
	df.minutes_since_alcohol = d.get("minutes_since_alcohol", 0)
	df.skills = d.get("skills", {}).duplicate()
	df.current_task = d.get("current_task", "idle")
	df.task_progress = d.get("task_progress", 0.0)
	df.task_target = _arr_to_v3i(d.get("task_target", [-1, -1, -1]))
	df.is_alive = d.get("is_alive", true)
	df.gender = d.get("gender", "Male")
	df.age = d.get("age", 20)
	df.birth_year = d.get("birth_year", 43)
	df.caste = d.get("caste", "dwarf")
	df.glyph = d.get("glyph", "")
	df.display_color = _arr_to_color(d.get("display_color", [0.0, 0.0, 0.0, 0.0]))
	df.is_world_settlement_resident = d.get("is_world_settlement_resident", false)
	df.settlement_site_id = d.get("settlement_site_id", -1)
	df.settlement_family_id = d.get("settlement_family_id", -1)
	df.home_structure_id = d.get("home_structure_id", -1)
	df.work_structure_id = d.get("work_structure_id", -1)
	df.civilization_id = d.get("civilization_id", -1)
	df.religion_id = d.get("religion_id", -1)
	df.settlement_home_position = _arr_to_v3i(d.get("settlement_home_position", [-1, -1, -1]))
	df.settlement_work_position = _arr_to_v3i(d.get("settlement_work_position", [-1, -1, -1]))
	df.settlement_leisure_position = _arr_to_v3i(d.get("settlement_leisure_position", [-1, -1, -1]))
	df.settlement_work_label = d.get("settlement_work_label", "Trabajando")
	df.path_index = d.get("path_index", 0)
	df.last_pos = _arr_to_v3i(d.get("last_pos", [-1, -1, -1]))
	df.stuck_counter = d.get("stuck_counter", 0)
	df.move_tick_counter = d.get("move_tick_counter", 0)
	df.speed = d.get("speed", 1.0)
	df.has_moved_this_tick = d.get("has_moved_this_tick", false)
	df.needs_display_update = true
	df.strength = d.get("strength", 5.0)
	df.agility = d.get("agility", 5.0)
	df.toughness = d.get("toughness", 5.0)
	df.combat_skill = d.get("combat_skill", 1.0)
	df.weapon_skill = d.get("weapon_skill", 1.0)
	df.shield_skill = d.get("shield_skill", 0.0)
	df.dodge_skill = d.get("dodge_skill", 1.0)
	df.armor_value = d.get("armor_value", 0.0)
	df.equipped_weapon = d.get("equipped_weapon", "fist")
	df.equipped_armor = d.get("equipped_armor", "shirt")
	df.equipped_shield = d.get("equipped_shield", "")
	df.equipped_helmet = d.get("equipped_helmet", "")
	df.has_shield = d.get("has_shield", false)
	df.is_military = d.get("is_military", false)
	df.squad_id = d.get("squad_id", -1)
	df.creature_type = d.get("creature_type", "dwarf")
	df.combat_cooldown = d.get("combat_cooldown", 0)
	df.combat_stance = d.get("combat_stance", 0)
	df.fatigue_level = d.get("fatigue_level", 0.0)
	df.target_entity_id = d.get("target_entity_id", -1)
	df.kill_count = d.get("kill_count", 0)
	df.wounds = d.get("wounds", []).duplicate()
	df.scars = d.get("scars", []).duplicate()
	df.wounds_head = d.get("wounds_head", 0.0)
	df.wounds_upper_body = d.get("wounds_upper_body", 0.0)
	df.wounds_lower_body = d.get("wounds_lower_body", 0.0)
	df.wounds_arm_l = d.get("wounds_arm_l", 0.0)
	df.wounds_arm_r = d.get("wounds_arm_r", 0.0)
	df.wounds_leg_l = d.get("wounds_leg_l", 0.0)
	df.wounds_leg_r = d.get("wounds_leg_r", 0.0)
	df.stats_tracker = d.get("stats_tracker", {}).duplicate()
	df.personality = d.get("personality", {}).duplicate()
	df.emotions = d.get("emotions", []).duplicate()
	df.current_emotion = d.get("current_emotion", 12)
	df.emotion_intensity = d.get("emotion_intensity", 0.5)
	df.stress = d.get("stress", 0.0)
	df.trauma = d.get("trauma", []).duplicate()
	df.relationships = d.get("relationships", {}).duplicate()
	df.family = d.get("family", {"mother": -1, "father": -1, "spouse": -1, "children": []}).duplicate()
	df.friends = d.get("friends", []).duplicate()
	df.rivals = d.get("rivals", []).duplicate()
	df.preferences = d.get("preferences", {}).duplicate()
	df.memories = d.get("memories", []).duplicate()
	df.recent_events = d.get("recent_events", []).duplicate()
	df.prayer_counter = d.get("prayer_counter", 0)
	df.meditation_counter = d.get("meditation_counter", 0)
	df.artistic_inspiration = d.get("artistic_inspiration", 0.0)
	df.creative_works = d.get("creative_works", []).duplicate()
	df.needs = d.get("needs", {}).duplicate()
	df.mood = d.get("mood", 0)
	df.mood_counter = d.get("mood_counter", 0)
	df.tantrum_destruction = d.get("tantrum_destruction", 0)
	df.profession = d.get("profession", 0)
	df.appointed_position = d.get("appointed_position", "")
	df.is_noble = d.get("is_noble", false)
	df.noble_rank = d.get("noble_rank", -1)
	df.demands = d.get("demands", []).duplicate()
	df.mandates = d.get("mandates", []).duplicate()
	df.sleep_timer = d.get("sleep_timer", 0.0)
	df.is_sleeping = d.get("is_sleeping", false)
	df.is_resting_medical = d.get("is_resting_medical", false)
	df.sleep_quality = d.get("sleep_quality", 1.0)
	df.preferred_bed = _arr_to_v3i(d.get("preferred_bed", [-1, -1, -1]))
	df.room_quality = d.get("room_quality", 0.0)
	df.social_timer = d.get("social_timer", 0.0)
	df.last_social_interaction = d.get("last_social_interaction", 0)
	df.loneliness = d.get("loneliness", 0.0)
	df.prayer_timer = d.get("prayer_timer", 0.0)
	df.favored_deity = d.get("favored_deity", "")
	df.religious_fervor = d.get("religious_fervor", 0.5)
	df.preferred_food = d.get("preferred_food", "")
	df.preferred_drink = d.get("preferred_drink", "Dwarven Ale")
	df.preferred_color = _arr_to_color(d.get("preferred_color", [0,0,1,1]))
	df.preferred_stone = d.get("preferred_stone", "granite")
	df.learning_counter = d.get("learning_counter", 0.0)
	df.knowledge = d.get("knowledge", {}).duplicate()
	df.pain_threshold = d.get("pain_threshold", 50.0)
	df.current_pain = d.get("current_pain", 0.0)
	df.is_in_pain = d.get("is_in_pain", false)
	df.bleeding_rate = d.get("bleeding_rate", 0.0)
	df.is_bleeding = d.get("is_bleeding", false)
	df.infection_chance = d.get("infection_chance", 0.0)
	df.has_infection = d.get("has_infection", false)
	df.rest_timer = d.get("rest_timer", 0.0)
	df.nausea = d.get("nausea", 0.0)
	df.is_vomiting = d.get("is_vomiting", false)
	df.dizziness = d.get("dizziness", 0.0)
	df.is_stunned = d.get("is_stunned", false)
	df.stun_timer = d.get("stun_timer", 0)
	df.noise_made = d.get("noise_made", 0.0)
	df.stealth_skill = d.get("stealth_skill", 1.0)
	df.territory_home = _arr_to_v3i(d.get("territory_home", [-1, -1, -1]))
	df.owned_items = d.get("owned_items", []).duplicate()
	df.claimed_bed = _arr_to_v3i(d.get("claimed_bed", [-1, -1, -1]))
	df.claimed_container = _arr_to_v3i(d.get("claimed_container", [-1, -1, -1]))
	df.labor_settings = d.get("labor_settings", {}).duplicate()
	df.is_on_break = d.get("is_on_break", false)
	df.break_timer = d.get("break_timer", 0.0)
	df.socialized_recently = d.get("socialized_recently", false)
	df.genome = _dict_to_genome(d.get("genome", {}))
	df.body_mass_kg = d.get("body_mass_kg", 70.0)
	df.is_pregnant = d.get("is_pregnant", false)
	df.pregnancy_progress = d.get("pregnancy_progress", 0.0)
	df.partner_id = d.get("partner_id", -1)
	df.marriage_counter = d.get("marriage_counter", 0)
	df.is_child = d.get("is_child", false)
	df.mother_id = d.get("mother_id", -1)
	df.father_id = d.get("father_id", -1)
	return df

static func _creature_to_dict(creature) -> Dictionary:
	return {
		"__type": "DFCreature",
		"name": creature.name,
		"tile_pos": _v3i_to_arr(creature.tile_pos),
		"id": creature.id,
		"is_alive": creature.is_alive,
		"creature_type": creature.creature_type,
		"glyph": creature.glyph,
		"display_color": _color_to_arr(creature.display_color),
		"size_label": creature.size_label,
		"creature_size": creature.creature_size,
		"body": _body_to_dict(creature.body),
		"ai_state": creature.ai_state,
		"ai_state_timer": creature.ai_state_timer,
		"ai_decision_timer": creature.ai_decision_timer,
		"ai_target_pos": _v3i_to_arr(creature.ai_target_pos),
		"ai_target_id": creature.ai_target_id,
		"ai_target_type": creature.ai_target_type,
		"path_index": creature.path_index,
		"stuck_counter": creature.stuck_counter,
		"last_pos": _v3i_to_arr(creature.last_pos),
		"strength": creature.strength,
		"agility": creature.agility,
		"toughness": creature.toughness,
		"speed": creature.speed,
		"move_tick_counter": creature.move_tick_counter,
		"fatigue_level": creature.fatigue_level,
		"sight_range": creature.sight_range,
		"hearing_range": creature.hearing_range,
		"stealth": creature.stealth,
		"intelligence": creature.intelligence,
		"hunger": creature.hunger,
		"thirst": creature.thirst,
		"fatigue": creature.fatigue,
		"health": creature.health,
		"is_sleeping": creature.is_sleeping,
		"sleep_timer": creature.sleep_timer,
		"personality": creature.personality,
		"pack_id": creature.pack_id,
		"pack_leader_id": creature.pack_leader_id,
		"pack_members": creature.pack_members.duplicate(),
		"social_timer": creature.social_timer,
		"is_lonely": creature.is_lonely,
		"dominance": creature.dominance,
		"is_tame": creature.is_tame,
		"owner_id": creature.owner_id,
		"is_mature": creature.is_mature,
		"is_pregnant": creature.is_pregnant,
		"gestation_timer": creature.gestation_timer,
		"gestation_period": creature.gestation_period,
		"children_count": creature.children_count,
		"breeding_cooldown": creature.breeding_cooldown,
		"mating_timer": creature.mating_timer,
		"gender": creature.gender,
		"home_pos": _v3i_to_arr(creature.home_pos),
		"territory_center": _v3i_to_arr(creature.territory_center),
		"territory_radius": creature.territory_radius,
		"has_territory": creature.has_territory,
		"territory_defense_timer": creature.territory_defense_timer,
		"combat_skill": creature.combat_skill,
		"attack_damage": creature.attack_damage,
		"attack_type": creature.attack_type,
		"armor": creature.armor,
		"is_hostile": creature.is_hostile,
		"fear_level": creature.fear_level,
		"target_id": creature.target_id,
		"combat_cooldown": creature.combat_cooldown,
		"wounds": creature.wounds.duplicate(),
		"bleeding": creature.bleeding,
		"has_infection": creature.has_infection,
		"memory": creature.memory.duplicate(),
		"known_food_sources": [],
		"known_water_sources": [],
		"known_threats": creature.known_threats.duplicate(),
		"known_dangers": creature.known_dangers.duplicate(),
		"home_range": _v3i_to_arr(creature.home_range),
		"migration_target": _v3i_to_arr(creature.migration_target),
		"migration_timer": creature.migration_timer,
		"is_migrating": creature.is_migrating,
		"seasonal_home": _v3i_to_arr(creature.seasonal_home),
		"genome": _genome_to_dict(creature.genome),
		"body_mass_kg": creature.body_mass_kg
	}

static func _dict_to_creature(d: Dictionary):
	var DFCreature = load("res://df_mode/df_creature.gd")
	var pos = _arr_to_v3i(d.get("tile_pos", [0, 0, 0]))
	var cr = DFCreature.new(pos, d.get("creature_type", ""), d.get("glyph", "?"), _arr_to_color(d.get("display_color", [1,1,1,1])), d.get("size_label", "medium"))
	cr.id = d.get("id", cr.id)
	if cr.id >= DFCreature._id_counter: DFCreature._id_counter = cr.id + 1
	cr.is_alive = d.get("is_alive", true)
	cr.body = _dict_to_body(d.get("body", {}))
	cr.ai_state = d.get("ai_state", 0)
	cr.ai_state_timer = d.get("ai_state_timer", 0)
	cr.ai_decision_timer = d.get("ai_decision_timer", 0)
	cr.ai_target_pos = _arr_to_v3i(d.get("ai_target_pos", [-1, -1, -1]))
	cr.ai_target_id = d.get("ai_target_id", -1)
	cr.ai_target_type = d.get("ai_target_type", "")
	cr.path_index = d.get("path_index", 0)
	cr.stuck_counter = d.get("stuck_counter", 0)
	cr.last_pos = _arr_to_v3i(d.get("last_pos", [-1, -1, -1]))
	cr.strength = d.get("strength", 5.0)
	cr.agility = d.get("agility", 5.0)
	cr.toughness = d.get("toughness", 5.0)
	cr.speed = d.get("speed", 1.0)
	cr.move_tick_counter = d.get("move_tick_counter", 0)
	cr.fatigue_level = d.get("fatigue_level", 0.0)
	cr.sight_range = d.get("sight_range", 8)
	cr.hearing_range = d.get("hearing_range", 10)
	cr.stealth = d.get("stealth", 0.0)
	cr.intelligence = d.get("intelligence", 0.3)
	cr.hunger = d.get("hunger", 0.0)
	cr.thirst = d.get("thirst", 0.0)
	cr.fatigue = d.get("fatigue", 0.0)
	cr.health = d.get("health", 1.0)
	cr.is_sleeping = d.get("is_sleeping", false)
	cr.sleep_timer = d.get("sleep_timer", 0)
	cr.personality = d.get("personality", 7)
	cr.pack_id = d.get("pack_id", -1)
	cr.pack_leader_id = d.get("pack_leader_id", -1)
	cr.pack_members = d.get("pack_members", []).duplicate()
	cr.social_timer = d.get("social_timer", 0)
	cr.is_lonely = d.get("is_lonely", false)
	cr.dominance = d.get("dominance", 0.5)
	cr.is_tame = d.get("is_tame", false)
	cr.owner_id = d.get("owner_id", -1)
	cr.is_mature = d.get("is_mature", true)
	cr.is_pregnant = d.get("is_pregnant", false)
	cr.gestation_timer = d.get("gestation_timer", 0)
	cr.gestation_period = d.get("gestation_period", 100)
	cr.children_count = d.get("children_count", 0)
	cr.breeding_cooldown = d.get("breeding_cooldown", 0)
	cr.mating_timer = d.get("mating_timer", 0)
	cr.gender = d.get("gender", "Male")
	cr.home_pos = _arr_to_v3i(d.get("home_pos", [-1, -1, -1]))
	cr.territory_center = _arr_to_v3i(d.get("territory_center", [-1, -1, -1]))
	cr.territory_radius = d.get("territory_radius", 15)
	cr.has_territory = d.get("has_territory", false)
	cr.territory_defense_timer = d.get("territory_defense_timer", 0)
	cr.combat_skill = d.get("combat_skill", 1.0)
	cr.attack_damage = d.get("attack_damage", 3.0)
	cr.attack_type = d.get("attack_type", "bite")
	cr.armor = d.get("armor", 0.0)
	cr.is_hostile = d.get("is_hostile", false)
	cr.fear_level = d.get("fear_level", 0.0)
	cr.target_id = d.get("target_id", -1)
	cr.combat_cooldown = d.get("combat_cooldown", 0)
	cr.wounds = d.get("wounds", []).duplicate()
	cr.bleeding = d.get("bleeding", 0.0)
	cr.has_infection = d.get("has_infection", false)
	cr.memory = d.get("memory", []).duplicate()
	cr.known_threats = d.get("known_threats", []).duplicate()
	cr.known_dangers = d.get("known_dangers", []).duplicate()
	cr.home_range = _arr_to_v3i(d.get("home_range", [-1, -1, -1]))
	cr.migration_target = _arr_to_v3i(d.get("migration_target", [-1, -1, -1]))
	cr.migration_timer = d.get("migration_timer", 0)
	cr.is_migrating = d.get("is_migrating", false)
	cr.seasonal_home = _arr_to_v3i(d.get("seasonal_home", [-1, -1, -1]))
	cr.genome = _dict_to_genome(d.get("genome", {}))
	cr.body_mass_kg = d.get("body_mass_kg", 40.0)
	return cr

static func _job_to_dict(job) -> Dictionary:
	return {
		"__type": "DFJob",
		"job_type": job.job_type,
		"tile_pos": _v3i_to_arr(job.tile_pos),
		"state": job.state,
		"assigned_dwarf_id": job.assigned_dwarf_id,
		"priority": job.priority,
		"work_remaining": job.work_remaining,
		"labor": job.labor,
		"result_tile_type": job.result_tile_type,
		"result_material": job.result_material,
		"work_order_id": job.work_order_id,
		"is_repeatable": job.is_repeatable,
		"repeat_count": job.repeat_count,
		"max_repeat": job.max_repeat,
		"linked_order_id": job.linked_order_id,
		"prerequisite_job_ids": job.prerequisite_job_ids.duplicate(),
		"dependent_job_ids": job.dependent_job_ids.duplicate(),
		"required_items": job.required_items.duplicate(),
		"required_skill": job.required_skill,
		"required_skill_level": job.required_skill_level,
		"expected_quality": job.expected_quality,
		"skill_xp_reward": job.skill_xp_reward,
		"item_produced": job.item_produced,
		"item_count_produced": job.item_count_produced,
		"reaction_id": job.reaction_id,
		"created_tick": job.created_tick,
		"assigned_tick": job.assigned_tick,
		"started_tick": job.started_tick,
		"completed_tick": job.completed_tick,
		"cancel_reason": job.cancel_reason
	}

static func _dict_to_job(d: Dictionary):
	var DFJob = load("res://df_mode/df_job.gd")
	var pos = _arr_to_v3i(d.get("tile_pos", [0, 0, 0]))
	var job = DFJob.new(d.get("job_type", 0), pos, d.get("priority", 5))
	job.state = d.get("state", 0)
	job.assigned_dwarf_id = d.get("assigned_dwarf_id", -1)
	job.work_remaining = d.get("work_remaining", 1.0)
	job.labor = d.get("labor", 0)
	job.result_tile_type = d.get("result_tile_type", -1)
	job.result_material = d.get("result_material", -1)
	job.work_order_id = d.get("work_order_id", -1)
	job.is_repeatable = d.get("is_repeatable", false)
	job.repeat_count = d.get("repeat_count", 0)
	job.max_repeat = d.get("max_repeat", -1)
	job.linked_order_id = d.get("linked_order_id", -1)
	job.prerequisite_job_ids = d.get("prerequisite_job_ids", []).duplicate()
	job.dependent_job_ids = d.get("dependent_job_ids", []).duplicate()
	job.required_items = d.get("required_items", {}).duplicate()
	job.required_skill = d.get("required_skill", -1)
	job.required_skill_level = d.get("required_skill_level", 0)
	job.expected_quality = d.get("expected_quality", 0.5)
	job.skill_xp_reward = d.get("skill_xp_reward", 5)
	job.item_produced = d.get("item_produced", "")
	job.item_count_produced = d.get("item_count_produced", 1)
	job.reaction_id = d.get("reaction_id", "")
	job.created_tick = d.get("created_tick", 0)
	job.assigned_tick = d.get("assigned_tick", -1)
	job.started_tick = d.get("started_tick", -1)
	job.completed_tick = d.get("completed_tick", -1)
	job.cancel_reason = d.get("cancel_reason", "")
	return job

static func _workshop_to_dict(w) -> Dictionary:
	return {
		"__type": "DFWorkshop",
		"workshop_type": w.workshop_type,
		"tile_pos": _v3i_to_arr(w.tile_pos),
		"name": w.name,
		"dwarf_assigned": w.dwarf_assigned,
		"operator_skill": w.operator_skill,
		"is_active": w.is_active,
		"current_recipe": w.current_recipe.duplicate(),
		"recipe_progress": w.recipe_progress,
		"production_queue": w.production_queue.duplicate(true)
	}

static func _dict_to_workshop(d: Dictionary):
	var DFWorkshop = load("res://df_mode/df_workshop.gd")
	var pos = _arr_to_v3i(d.get("tile_pos", [0, 0, 0]))
	var w = DFWorkshop.new(d.get("workshop_type", 0), pos)
	w.dwarf_assigned = d.get("dwarf_assigned", -1)
	w.operator_skill = d.get("operator_skill", 0)
	w.is_active = d.get("is_active", false)
	w.current_recipe = d.get("current_recipe", {}).duplicate()
	w.recipe_progress = d.get("recipe_progress", 0.0)
	w.production_queue = d.get("production_queue", []).duplicate(true)
	return w

static func _stockpile_to_dict(s) -> Dictionary:
	return {
		"__type": "DFStockpile",
		"tiles": s.tiles.duplicate(),
		"accepts_categories": s.accepts_categories.duplicate(),
		"display_color": _color_to_arr(s.display_color),
		"owner_site_id": s.owner_site_id,
		"is_foreign": s.is_foreign,
		"stockpile_name": s.stockpile_name
	}

static func _dict_to_stockpile(d: Dictionary):
	var DFStockpile = load("res://df_mode/df_stockpile.gd")
	var sp = DFStockpile.new(d.get("tiles", []).duplicate())
	sp.accepts_categories = d.get("accepts_categories", ["stone", "wood", "item"]).duplicate()
	sp.display_color = _arr_to_color(d.get("display_color", [0.8, 0.8, 0.2, 0.3]))
	sp.owner_site_id = d.get("owner_site_id", -1)
	sp.is_foreign = d.get("is_foreign", false)
	sp.stockpile_name = d.get("stockpile_name", "Almacén")
	return sp

static func _building_to_dict(b) -> Dictionary:
	return {
		"__type": "DFBuilding",
		"type": b.type,
		"tile_pos": _v3i_to_arr(b.tile_pos),
		"size": _v3i_to_arr(b.size),
		"is_constructed": b.is_constructed,
		"name": b.name
	}

static func _dict_to_building(d: Dictionary):
	var DFBuilding = load("res://df_mode/df_building.gd")
	var pos = _arr_to_v3i(d.get("tile_pos", [0, 0, 0]))
	var b = DFBuilding.new(d.get("type", 1), pos)
	b.is_constructed = d.get("is_constructed", true)
	b.name = d.get("name", b.name)
	return b

static func serialize_entity(entity) -> Dictionary:
	if entity == null: return {}
	if entity.get("creature_type") == "dwarf":
		return _dwarf_to_dict(entity)
	elif entity.get("item_type") != null and entity.get("creature_type") == null:
		return _item_to_dict(entity)
	elif entity.get("creature_type") != null and entity.get("creature_type") != "":
		return _creature_to_dict(entity)
	return {}

static func deserialize_entity(d: Dictionary):
	var t = d.get("__type", "")
	match t:
		"DFDwarf": return _dict_to_dwarf(d)
		"DFItem": return _dict_to_item(d)
		"DFCreature": return _dict_to_creature(d)
	return null

static func ensure_save_dir() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)

static func get_save_path(slot: int) -> String:
	return SAVE_DIR + "slot_" + str(slot) + ".json"

static func save_game(main) -> bool:
	ensure_save_dir()
	if main.world == null:
		return false
	var data = {}
	data["version"] = 1
	data["_game_minute"] = main._game_minute
	data["_game_hour"] = main._game_hour
	data["_game_day"] = main._game_day
	data["_game_season"] = main._game_season
	data["_game_year"] = main._game_year
	data["_simulation_tick_clock"] = main._simulation_tick_clock
	data["paused"] = main.paused
	data["camera_pos"] = _v3i_to_arr(main.camera_pos)
	data["_current_cycle_follow_index"] = main._current_cycle_follow_index
	data["follow_dwarf"] = main.renderer.follow_dwarf if main.renderer != null else -1
	data["_chronicle_events_game"] = main._chronicle_events_game.duplicate()
	data["generation_seed"] = main.generation_seed
	data["world_name"] = main.world_name
	data["embark_prepare_points"] = main.embark_prepare_points
	data["embark_custom_skills"] = main.embark_custom_skills.duplicate()
	data["embark_custom_items"] = main.embark_custom_items.duplicate()
	if main.world_gen != null:
		data["world_seed"] = main.generation_seed
	else:
		data["world_seed"] = -1

	var w = main.world
	data["world"] = {}
	data["world"]["width"] = w.width
	data["world"]["depth"] = w.depth
	data["world"]["height"] = w.height
	data["world"]["name"] = w.world_name
	data["world"]["world_version"] = w.world_version
	data["world"]["generated_world_sites"] = w.get_meta("generated_world_sites", []).duplicate(true)
	data["world"]["active_world_region"] = w.get_meta("active_world_region", []).duplicate()

	var pos_keys = w.tiles.keys()
	var tile_data_arr = []
	for pk in pos_keys:
		tile_data_arr.append({
			"p": _v3i_to_arr(pk),
			"t": w.tiles[pk],
			"m": w.materials.get(pk, 0),
			"td": w.tile_data.get(pk, {}).duplicate(),
			"r": w.revealed.get(pk, false)
		})
	data["world"]["tiles"] = tile_data_arr

	data["world"]["elevation"] = []
	for z in range(w.depth):
		if z < w.elevation.size():
			data["world"]["elevation"].append(w.elevation[z].duplicate())
		else:
			data["world"]["elevation"].append([])

	var flarr = []
	for fk in w.fluid_levels.keys():
		if w.fluid_levels[fk] > 0:
			flarr.append({"p": _v3i_to_arr(fk), "v": w.fluid_levels[fk]})
	data["world"]["fluid_levels"] = flarr

	data["world"]["weather"] = {
		"current_weather": w.current_weather,
		"weather_duration": w.weather_duration,
		"weather_transition": w.weather_transition,
		"wind_direction": [w.wind_direction.x, w.wind_direction.y],
		"wind_strength": w.wind_strength,
		"fog_density": w.fog_density,
		"cloud_cover": w.cloud_cover,
		"lightning_flash": w.lightning_flash,
		"lightning_timer": w.lightning_timer,
		"ambient_temperature": w.ambient_temperature,
		"ground_temperature": w.ground_temperature,
		"humidity": w.humidity,
		"precipitation_intensity": w.precipitation_intensity,
		"current_season": w.current_season,
		"season_day": w.season_day,
		"season_length": w.season_length,
		"year_day": w.year_day,
		"year_length": w.year_length,
		"day_time": w.day_time,
		"is_daytime": w.is_daytime,
		"dawn_timer": w.dawn_timer,
		"dusk_timer": w.dusk_timer
	}

	data["world"]["disaster"] = {
		"active_disaster": w.active_disaster,
		"disaster_timer": w.disaster_timer,
		"disaster_pos": _v3i_to_arr(w.disaster_pos),
		"disaster_intensity": w.disaster_intensity,
		"disaster_radius": w.disaster_radius,
		"earthquake_tiles_remaining": w.earthquake_tiles_remaining,
		"cavein_queue": w.cavein_queue.duplicate(),
		"flood_tiles": w.flood_tiles.duplicate(),
		"fire_spread_counter": w.fire_spread_counter
	}

	var ftarr = []
	for ftk in w.fire_tiles.keys():
		var ftv = w.fire_tiles[ftk]
		ftarr.append({"p": _v3i_to_arr(ftk), "intensity": ftv.get("intensity", 0.0), "fuel": ftv.get("fuel", 0.0)})
	data["world"]["fire_tiles"] = ftarr

	var sptarr = []
	for spk in w.splatters.keys():
		var spv = w.splatters[spk]
		if spv is Dictionary and not spv.is_empty():
			sptarr.append({"p": _v3i_to_arr(spk), "substances": spv.duplicate()})
	data["world"]["splatters"] = sptarr

	data["world"]["tree_data"] = []
	for tdk in w.tree_data.keys():
		data["world"]["tree_data"].append({"p": _v3i_to_arr(tdk), "data": w.tree_data[tdk].duplicate()})

	data["world"]["growing_crops"] = []
	for gck in w.growing_crops.keys():
		data["world"]["growing_crops"].append({"p": _v3i_to_arr(gck), "data": w.growing_crops[gck].duplicate()})

	data["world"]["leaf_litter"] = []
	for llk in w.leaf_litter.keys():
		data["world"]["leaf_litter"].append({"p": _v3i_to_arr(llk), "v": w.leaf_litter[llk]})

	data["world"]["light_level"] = w.light_level
	data["world"]["tree_growth_timer"] = w.tree_growth_timer
	data["world"]["tree_growth_interval"] = w.tree_growth_interval
	data["world"]["grass_growth_timer"] = w.grass_growth_timer
	data["world"]["evaporation_rate"] = w.evaporation_rate
	data["world"]["fluid_update_interval"] = w.fluid_update_interval
	data["world"]["fluid_tick_counter"] = w.fluid_tick_counter
	data["world"]["erosion_timer"] = w.erosion_timer
	data["world"]["tree_growth_timer"] = w.tree_growth_timer

	var building_arr = []
	for b in w.buildings:
		building_arr.append(_building_to_dict(b))
	data["world"]["buildings"] = building_arr

	var workshop_arr = []
	for ws in w.workshops:
		workshop_arr.append(_workshop_to_dict(ws))
	data["world"]["workshops"] = workshop_arr

	var stockpile_arr = []
	for sp in w.stockpiles:
		stockpile_arr.append(_stockpile_to_dict(sp))
	data["world"]["stockpiles"] = stockpile_arr

	var riv_arr = []
	for rv in w.rivers:
		if rv is Dictionary:
			riv_arr.append(rv.duplicate())
		else:
			riv_arr.append(rv)
	data["world"]["rivers"] = riv_arr

	data["entities"] = []
	for e in w.entities:
		var sd = serialize_entity(e)
		if not sd.is_empty():
			data["entities"].append(sd)

	if main.designation != null:
		var d = main.designation
		data["designation"] = {
			"mode": d.mode,
			"selection_start": _v3i_to_arr(d.selection_start),
			"selection_end": _v3i_to_arr(d.selection_end),
			"is_selecting": d.is_selecting,
			"building_type_to_build": d.building_type_to_build,
			"job_queue": []
		}
		for j in d.job_queue:
			data["designation"]["job_queue"].append(_job_to_dict(j))
	else:
		data["designation"] = {}

	var json_str = JSON.stringify(data, "", true)
	var file = FileAccess.open(get_save_path(0), FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(json_str)
	file.close()
	return true

static func load_game(main) -> bool:
	var path = get_save_path(0)
	if not FileAccess.file_exists(path):
		return false
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var json_str = file.get_as_text()
	file.close()
	var parse = JSON.parse_string(json_str)
	if parse == null or typeof(parse) != TYPE_DICTIONARY:
		return false
	var data = parse as Dictionary

	if main.world == null:
		var wd = data.get("world", {})
		main.world = DFWorld.new(wd.get("width", 128), wd.get("depth", 128), wd.get("height", 16))
	var w = main.world

	var wd = data.get("world", {})
	w.width = wd.get("width", 128)
	w.depth = wd.get("depth", 128)
	w.height = wd.get("height", 16)
	w.world_name = wd.get("name", "")
	w.world_version = wd.get("world_version", 0)
	w.set_meta("generated_world_sites", wd.get("generated_world_sites", []).duplicate(true))
	w.set_meta("active_world_region", wd.get("active_world_region", []).duplicate())

	w.tiles.clear()
	w.materials.clear()
	w.tile_data.clear()
	w.revealed.clear()
	var tile_data_arr = wd.get("tiles", [])
	for entry in tile_data_arr:
		var p = _arr_to_v3i(entry.get("p", [0, 0, 0]))
		w.tiles[p] = entry.get("t", 0)
		w.materials[p] = entry.get("m", 0)
		w.tile_data[p] = entry.get("td", {}).duplicate()
		if entry.get("r", false):
			w.revealed[p] = true

	w.elevation = []
	for zrow in wd.get("elevation", []):
		if zrow is Array:
			w.elevation.append(zrow.duplicate())
		else:
			w.elevation.append([])

	w.fluid_levels.clear()
	var flarr = wd.get("fluid_levels", [])
	for fl in flarr:
		w.fluid_levels[_arr_to_v3i(fl.get("p", [0, 0, 0]))] = fl.get("v", 0.0)

	var weather = wd.get("weather", {})
	w.current_weather = weather.get("current_weather", 0)
	w.weather_duration = weather.get("weather_duration", 0)
	w.weather_transition = weather.get("weather_transition", 0)
	var wdir = weather.get("wind_direction", [1.0, 0.0])
	w.wind_direction = Vector2(wdir[0] if wdir.size() > 0 else 1.0, wdir[1] if wdir.size() > 1 else 0.0)
	w.wind_strength = weather.get("wind_strength", 0.5)
	w.fog_density = weather.get("fog_density", 0.0)
	w.cloud_cover = weather.get("cloud_cover", 0.0)
	w.lightning_flash = weather.get("lightning_flash", false)
	w.lightning_timer = weather.get("lightning_timer", 0)
	w.ambient_temperature = weather.get("ambient_temperature", 0.5)
	w.ground_temperature = weather.get("ground_temperature", 0.5)
	w.humidity = weather.get("humidity", 0.5)
	w.precipitation_intensity = weather.get("precipitation_intensity", 0.0)
	w.current_season = weather.get("current_season", 0)
	w.season_day = weather.get("season_day", 0)
	w.season_length = weather.get("season_length", 28)
	w.year_day = weather.get("year_day", 0)
	w.year_length = weather.get("year_length", 112)
	w.day_time = weather.get("day_time", 0.5)
	w.is_daytime = weather.get("is_daytime", true)
	w.dawn_timer = weather.get("dawn_timer", 0)
	w.dusk_timer = weather.get("dusk_timer", 0)

	var disaster = wd.get("disaster", {})
	w.active_disaster = disaster.get("active_disaster", 0)
	w.disaster_timer = disaster.get("disaster_timer", 0)
	w.disaster_pos = _arr_to_v3i(disaster.get("disaster_pos", [-1, -1, -1]))
	w.disaster_intensity = disaster.get("disaster_intensity", 0.0)
	w.disaster_radius = disaster.get("disaster_radius", 0)
	w.earthquake_tiles_remaining = disaster.get("earthquake_tiles_remaining", 0)
	w.cavein_queue = disaster.get("cavein_queue", []).duplicate()
	w.flood_tiles = disaster.get("flood_tiles", []).duplicate()
	w.fire_spread_counter = disaster.get("fire_spread_counter", 0)

	w.fire_tiles.clear()
	for ft in wd.get("fire_tiles", []):
		w.fire_tiles[_arr_to_v3i(ft.get("p", [0, 0, 0]))] = {"intensity": ft.get("intensity", 1.0), "fuel": ft.get("fuel", 1.0)}

	w.splatters.clear()
	for sp in wd.get("splatters", []):
		w.splatters[_arr_to_v3i(sp.get("p", [0, 0, 0]))] = sp.get("substances", {}).duplicate()

	w.tree_data.clear()
	for td in wd.get("tree_data", []):
		w.tree_data[_arr_to_v3i(td.get("p", [0, 0, 0]))] = td.get("data", {}).duplicate()

	w.growing_crops.clear()
	for gc in wd.get("growing_crops", []):
		w.growing_crops[_arr_to_v3i(gc.get("p", [0, 0, 0]))] = gc.get("data", {}).duplicate()

	w.leaf_litter.clear()
	for ll in wd.get("leaf_litter", []):
		w.leaf_litter[_arr_to_v3i(ll.get("p", [0, 0, 0]))] = ll.get("v", 0)

	w.light_level = wd.get("light_level", 1.0)
	w.tree_growth_timer = wd.get("tree_growth_timer", 0)
	w.tree_growth_interval = wd.get("tree_growth_interval", 50)
	w.grass_growth_timer = wd.get("grass_growth_timer", 0)
	w.evaporation_rate = wd.get("evaporation_rate", 0.01)
	w.fluid_update_interval = wd.get("fluid_update_interval", 10)
	w.fluid_tick_counter = wd.get("fluid_tick_counter", 0)
	w.erosion_timer = wd.get("erosion_timer", 0)

	w.buildings = []
	for bd in wd.get("buildings", []):
		w.buildings.append(_dict_to_building(bd))

	w.workshops = []
	for wsd in wd.get("workshops", []):
		w.workshops.append(_dict_to_workshop(wsd))

	w.stockpiles = []
	for spd in wd.get("stockpiles", []):
		w.stockpiles.append(_dict_to_stockpile(spd))

	w.rivers = []
	for rvd in wd.get("rivers", []):
		if rvd is Dictionary:
			w.rivers.append(rvd.duplicate())
		else:
			w.rivers.append(rvd)

	w.entities.clear()
	for ed in data.get("entities", []):
		var entity = deserialize_entity(ed)
		if entity != null:
			w.entities.append(entity)

	main._game_minute = data.get("_game_minute", 0)
	main._game_hour = data.get("_game_hour", 6)
	main._game_day = data.get("_game_day", 1)
	main._game_season = data.get("_game_season", "Spring")
	main._game_year = data.get("_game_year", 63)
	main._simulation_tick_clock = data.get("_simulation_tick_clock", 0)
	main.paused = data.get("paused", false)
	main.camera_pos = _arr_to_v3i(data.get("camera_pos", [64, 3, 64]))
	main._current_cycle_follow_index = data.get("_current_cycle_follow_index", 0)
	main._chronicle_events_game = data.get("_chronicle_events_game", []).duplicate()
	main.generation_seed = data.get("generation_seed", -1)
	main.world_name = data.get("world_name", "")
	main.embark_prepare_points = data.get("embark_prepare_points", 100)
	main.embark_custom_skills = data.get("embark_custom_skills", {}).duplicate()
	main.embark_custom_items = data.get("embark_custom_items", {}).duplicate()

	var follow_id = data.get("follow_dwarf", -1)
	if main.renderer != null:
		main.renderer.follow_dwarf = follow_id

	var desig_data = data.get("designation", {})
	if not desig_data.is_empty():
		main.designation = DFDesignation.new(w)
		main.designation.mode = desig_data.get("mode", 0)
		main.designation.selection_start = _arr_to_v3i(desig_data.get("selection_start", [-1, -1, -1]))
		main.designation.selection_end = _arr_to_v3i(desig_data.get("selection_end", [-1, -1, -1]))
		main.designation.is_selecting = desig_data.get("is_selecting", false)
		main.designation.building_type_to_build = desig_data.get("building_type_to_build", 1)
		main.designation.job_queue = []
		for jd in desig_data.get("job_queue", []):
			main.designation.job_queue.append(_dict_to_job(jd))

	if main.renderer != null:
		main.renderer.set_world(w)
		main.renderer.designation = main.designation
		main.renderer.paused = main.paused
		main.renderer.game_year = main._game_year
		main.renderer.game_hour = main._game_hour
		main.renderer.game_day = main._game_day
		main.renderer.game_season = main._game_season

	return true

static func get_save_list() -> Array:
	ensure_save_dir()
	var dir = DirAccess.open(SAVE_DIR)
	if dir == null:
		return []
	var saves = []
	dir.list_dir_begin()
	var fname = dir.get_next()
	while fname != "":
		if fname.ends_with(".json"):
			var slot_str = fname.trim_prefix("slot_").trim_suffix(".json")
			var slot = int(slot_str)
			var path = SAVE_DIR + fname
			var mod_time = FileAccess.get_modified_time(path)
			var timestamp = Time.get_datetime_dict_from_unix_time(int(mod_time)) if mod_time > 0 else {}
			var date_str = ""
			if timestamp.has("year"):
				date_str = "%04d-%02d-%02d %02d:%02d" % [timestamp.year, timestamp.month, timestamp.day, timestamp.hour, timestamp.minute]
			saves.append({"slot": slot, "file": fname, "date": date_str, "path": path})
		fname = dir.get_next()
	dir.list_dir_end()
	saves.sort_custom(func(a, b): return a.slot < b.slot)
	return saves

static func delete_save(slot: int) -> void:
	var path = get_save_path(slot)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)

static func save_game_slot(main, slot: int) -> bool:
	ensure_save_dir()
	if main.world == null:
		return false
	var data = _build_save_data(main)
	var json_str = JSON.stringify(data, "", true)
	var file = FileAccess.open(get_save_path(slot), FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(json_str)
	file.close()
	return true

static func load_game_slot(main, slot: int) -> bool:
	var path = get_save_path(slot)
	if not FileAccess.file_exists(path):
		return false
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var json_str = file.get_as_text()
	file.close()
	var data = JSON.parse_string(json_str)
	if data == null or typeof(data) != TYPE_DICTIONARY:
		return false
	_apply_save_data(main, data as Dictionary)
	return true

static func _build_save_data(main) -> Dictionary:
	var data = {}
	data["version"] = 1
	data["_game_minute"] = main._game_minute
	data["_game_hour"] = main._game_hour
	data["_game_day"] = main._game_day
	data["_game_season"] = main._game_season
	data["_game_year"] = main._game_year
	data["_simulation_tick_clock"] = main._simulation_tick_clock
	data["paused"] = main.paused
	data["camera_pos"] = _v3i_to_arr(main.camera_pos)
	data["_current_cycle_follow_index"] = main._current_cycle_follow_index
	data["follow_dwarf"] = main.renderer.follow_dwarf if main.renderer != null else -1
	data["_chronicle_events_game"] = main._chronicle_events_game.duplicate()
	data["generation_seed"] = main.generation_seed
	data["world_name"] = main.world_name
	data["embark_prepare_points"] = main.embark_prepare_points
	data["embark_custom_skills"] = main.embark_custom_skills.duplicate()
	data["embark_custom_items"] = main.embark_custom_items.duplicate()

	var w = main.world
	data["world"] = {}
	data["world"]["width"] = w.width
	data["world"]["depth"] = w.depth
	data["world"]["height"] = w.height
	data["world"]["name"] = w.world_name
	data["world"]["world_version"] = w.world_version
	data["world"]["generated_world_sites"] = w.get_meta("generated_world_sites", []).duplicate(true)
	data["world"]["active_world_region"] = w.get_meta("active_world_region", []).duplicate()

	var pos_keys = w.tiles.keys()
	var tile_data_arr = []
	for pk in pos_keys:
		tile_data_arr.append({
			"p": _v3i_to_arr(pk),
			"t": w.tiles[pk],
			"m": w.materials.get(pk, 0),
			"td": w.tile_data.get(pk, {}).duplicate(),
			"r": w.revealed.get(pk, false)
		})
	data["world"]["tiles"] = tile_data_arr

	data["world"]["elevation"] = []
	for z in range(w.depth):
		if z < w.elevation.size():
			data["world"]["elevation"].append(w.elevation[z].duplicate())
		else:
			data["world"]["elevation"].append([])

	var flarr = []
	for fk in w.fluid_levels.keys():
		if w.fluid_levels[fk] > 0:
			flarr.append({"p": _v3i_to_arr(fk), "v": w.fluid_levels[fk]})
	data["world"]["fluid_levels"] = flarr

	data["world"]["weather"] = {
		"current_weather": w.current_weather,
		"weather_duration": w.weather_duration,
		"weather_transition": w.weather_transition,
		"wind_direction": [w.wind_direction.x, w.wind_direction.y],
		"wind_strength": w.wind_strength,
		"fog_density": w.fog_density,
		"cloud_cover": w.cloud_cover,
		"lightning_flash": w.lightning_flash,
		"lightning_timer": w.lightning_timer,
		"ambient_temperature": w.ambient_temperature,
		"ground_temperature": w.ground_temperature,
		"humidity": w.humidity,
		"precipitation_intensity": w.precipitation_intensity,
		"current_season": w.current_season,
		"season_day": w.season_day,
		"season_length": w.season_length,
		"year_day": w.year_day,
		"year_length": w.year_length,
		"day_time": w.day_time,
		"is_daytime": w.is_daytime,
		"dawn_timer": w.dawn_timer,
		"dusk_timer": w.dusk_timer
	}

	data["world"]["disaster"] = {
		"active_disaster": w.active_disaster,
		"disaster_timer": w.disaster_timer,
		"disaster_pos": _v3i_to_arr(w.disaster_pos),
		"disaster_intensity": w.disaster_intensity,
		"disaster_radius": w.disaster_radius,
		"earthquake_tiles_remaining": w.earthquake_tiles_remaining,
		"cavein_queue": w.cavein_queue.duplicate(),
		"flood_tiles": w.flood_tiles.duplicate(),
		"fire_spread_counter": w.fire_spread_counter
	}

	var ftarr = []
	for ftk in w.fire_tiles.keys():
		var ftv = w.fire_tiles[ftk]
		ftarr.append({"p": _v3i_to_arr(ftk), "intensity": ftv.get("intensity", 0.0), "fuel": ftv.get("fuel", 0.0)})
	data["world"]["fire_tiles"] = ftarr

	var sptarr = []
	for spk in w.splatters.keys():
		var spv = w.splatters[spk]
		if spv is Dictionary and not spv.is_empty():
			sptarr.append({"p": _v3i_to_arr(spk), "substances": spv.duplicate()})
	data["world"]["splatters"] = sptarr

	data["world"]["tree_data"] = []
	for tdk in w.tree_data.keys():
		data["world"]["tree_data"].append({"p": _v3i_to_arr(tdk), "data": w.tree_data[tdk].duplicate()})

	data["world"]["growing_crops"] = []
	for gck in w.growing_crops.keys():
		data["world"]["growing_crops"].append({"p": _v3i_to_arr(gck), "data": w.growing_crops[gck].duplicate()})

	data["world"]["leaf_litter"] = []
	for llk in w.leaf_litter.keys():
		data["world"]["leaf_litter"].append({"p": _v3i_to_arr(llk), "v": w.leaf_litter[llk]})

	data["world"]["light_level"] = w.light_level
	data["world"]["tree_growth_timer"] = w.tree_growth_timer
	data["world"]["tree_growth_interval"] = w.tree_growth_interval
	data["world"]["grass_growth_timer"] = w.grass_growth_timer
	data["world"]["evaporation_rate"] = w.evaporation_rate
	data["world"]["fluid_update_interval"] = w.fluid_update_interval
	data["world"]["fluid_tick_counter"] = w.fluid_tick_counter
	data["world"]["erosion_timer"] = w.erosion_timer

	var building_arr = []
	for b in w.buildings:
		building_arr.append(_building_to_dict(b))
	data["world"]["buildings"] = building_arr

	var workshop_arr = []
	for ws in w.workshops:
		workshop_arr.append(_workshop_to_dict(ws))
	data["world"]["workshops"] = workshop_arr

	var stockpile_arr = []
	for sp in w.stockpiles:
		stockpile_arr.append(_stockpile_to_dict(sp))
	data["world"]["stockpiles"] = stockpile_arr

	var riv_arr = []
	for rv in w.rivers:
		if rv is Dictionary:
			riv_arr.append(rv.duplicate())
		else:
			riv_arr.append(rv)
	data["world"]["rivers"] = riv_arr

	data["entities"] = []
	for e in w.entities:
		var sd = serialize_entity(e)
		if not sd.is_empty():
			data["entities"].append(sd)

	if main.designation != null:
		var d = main.designation
		data["designation"] = {
			"mode": d.mode,
			"selection_start": _v3i_to_arr(d.selection_start),
			"selection_end": _v3i_to_arr(d.selection_end),
			"is_selecting": d.is_selecting,
			"building_type_to_build": d.building_type_to_build,
			"job_queue": []
		}
		for j in d.job_queue:
			data["designation"]["job_queue"].append(_job_to_dict(j))
	else:
		data["designation"] = {}
	return data

static func _apply_save_data(main, data: Dictionary) -> void:
	var wd = data.get("world", {})
	if main.world == null:
		main.world = DFWorld.new(wd.get("width", 128), wd.get("depth", 128), wd.get("height", 16))
	var w = main.world

	w.width = wd.get("width", 128)
	w.depth = wd.get("depth", 128)
	w.height = wd.get("height", 16)
	w.world_name = wd.get("name", "")
	w.world_version = wd.get("world_version", 0)
	w.set_meta("generated_world_sites", wd.get("generated_world_sites", []).duplicate(true))
	w.set_meta("active_world_region", wd.get("active_world_region", []).duplicate())

	w.tiles.clear()
	w.materials.clear()
	w.tile_data.clear()
	w.revealed.clear()
	for entry in wd.get("tiles", []):
		var p = _arr_to_v3i(entry.get("p", [0, 0, 0]))
		w.tiles[p] = entry.get("t", 0)
		w.materials[p] = entry.get("m", 0)
		w.tile_data[p] = entry.get("td", {}).duplicate()
		if entry.get("r", false):
			w.revealed[p] = true

	w.elevation = []
	for zrow in wd.get("elevation", []):
		if zrow is Array:
			w.elevation.append(zrow.duplicate())
		else:
			w.elevation.append([])

	w.fluid_levels.clear()
	for fl in wd.get("fluid_levels", []):
		w.fluid_levels[_arr_to_v3i(fl.get("p", [0, 0, 0]))] = fl.get("v", 0.0)

	var weather = wd.get("weather", {})
	w.current_weather = weather.get("current_weather", 0)
	w.weather_duration = weather.get("weather_duration", 0)
	w.weather_transition = weather.get("weather_transition", 0)
	var wdir = weather.get("wind_direction", [1.0, 0.0])
	w.wind_direction = Vector2(wdir[0] if wdir.size() > 0 else 1.0, wdir[1] if wdir.size() > 1 else 0.0)
	w.wind_strength = weather.get("wind_strength", 0.5)
	w.fog_density = weather.get("fog_density", 0.0)
	w.cloud_cover = weather.get("cloud_cover", 0.0)
	w.lightning_flash = weather.get("lightning_flash", false)
	w.lightning_timer = weather.get("lightning_timer", 0)
	w.ambient_temperature = weather.get("ambient_temperature", 0.5)
	w.ground_temperature = weather.get("ground_temperature", 0.5)
	w.humidity = weather.get("humidity", 0.5)
	w.precipitation_intensity = weather.get("precipitation_intensity", 0.0)
	w.current_season = weather.get("current_season", 0)
	w.season_day = weather.get("season_day", 0)
	w.season_length = weather.get("season_length", 28)
	w.year_day = weather.get("year_day", 0)
	w.year_length = weather.get("year_length", 112)
	w.day_time = weather.get("day_time", 0.5)
	w.is_daytime = weather.get("is_daytime", true)
	w.dawn_timer = weather.get("dawn_timer", 0)
	w.dusk_timer = weather.get("dusk_timer", 0)

	var disaster = wd.get("disaster", {})
	w.active_disaster = disaster.get("active_disaster", 0)
	w.disaster_timer = disaster.get("disaster_timer", 0)
	w.disaster_pos = _arr_to_v3i(disaster.get("disaster_pos", [-1, -1, -1]))
	w.disaster_intensity = disaster.get("disaster_intensity", 0.0)
	w.disaster_radius = disaster.get("disaster_radius", 0)
	w.earthquake_tiles_remaining = disaster.get("earthquake_tiles_remaining", 0)
	w.cavein_queue = disaster.get("cavein_queue", []).duplicate()
	w.flood_tiles = disaster.get("flood_tiles", []).duplicate()
	w.fire_spread_counter = disaster.get("fire_spread_counter", 0)

	w.fire_tiles.clear()
	for ft in wd.get("fire_tiles", []):
		w.fire_tiles[_arr_to_v3i(ft.get("p", [0, 0, 0]))] = {"intensity": ft.get("intensity", 1.0), "fuel": ft.get("fuel", 1.0)}

	w.splatters.clear()
	for sp in wd.get("splatters", []):
		w.splatters[_arr_to_v3i(sp.get("p", [0, 0, 0]))] = sp.get("substances", {}).duplicate()

	w.tree_data.clear()
	for td in wd.get("tree_data", []):
		w.tree_data[_arr_to_v3i(td.get("p", [0, 0, 0]))] = td.get("data", {}).duplicate()

	w.growing_crops.clear()
	for gc in wd.get("growing_crops", []):
		w.growing_crops[_arr_to_v3i(gc.get("p", [0, 0, 0]))] = gc.get("data", {}).duplicate()

	w.leaf_litter.clear()
	for ll in wd.get("leaf_litter", []):
		w.leaf_litter[_arr_to_v3i(ll.get("p", [0, 0, 0]))] = ll.get("v", 0)

	w.light_level = wd.get("light_level", 1.0)
	w.tree_growth_timer = wd.get("tree_growth_timer", 0)
	w.tree_growth_interval = wd.get("tree_growth_interval", 50)
	w.grass_growth_timer = wd.get("grass_growth_timer", 0)
	w.evaporation_rate = wd.get("evaporation_rate", 0.01)
	w.fluid_update_interval = wd.get("fluid_update_interval", 10)
	w.fluid_tick_counter = wd.get("fluid_tick_counter", 0)
	w.erosion_timer = wd.get("erosion_timer", 0)

	w.buildings = []
	for bd in wd.get("buildings", []):
		w.buildings.append(_dict_to_building(bd))

	w.workshops = []
	for wsd in wd.get("workshops", []):
		w.workshops.append(_dict_to_workshop(wsd))

	w.stockpiles = []
	for spd in wd.get("stockpiles", []):
		w.stockpiles.append(_dict_to_stockpile(spd))

	w.rivers = []
	for rvd in wd.get("rivers", []):
		if rvd is Dictionary:
			w.rivers.append(rvd.duplicate())
		else:
			w.rivers.append(rvd)

	w.entities.clear()
	for ed in data.get("entities", []):
		var entity = deserialize_entity(ed)
		if entity != null:
			w.entities.append(entity)

	main._game_minute = data.get("_game_minute", 0)
	main._game_hour = data.get("_game_hour", 6)
	main._game_day = data.get("_game_day", 1)
	main._game_season = data.get("_game_season", "Spring")
	main._game_year = data.get("_game_year", 63)
	main._simulation_tick_clock = data.get("_simulation_tick_clock", 0)
	main.paused = data.get("paused", false)
	main.camera_pos = _arr_to_v3i(data.get("camera_pos", [64, 3, 64]))
	main._current_cycle_follow_index = data.get("_current_cycle_follow_index", 0)
	main._chronicle_events_game = data.get("_chronicle_events_game", []).duplicate()
	main.generation_seed = data.get("generation_seed", -1)
	main.world_name = data.get("world_name", "")
	main.embark_prepare_points = data.get("embark_prepare_points", 100)
	main.embark_custom_skills = data.get("embark_custom_skills", {}).duplicate()
	main.embark_custom_items = data.get("embark_custom_items", {}).duplicate()

	var follow_id = data.get("follow_dwarf", -1)
	if main.renderer != null:
		main.renderer.follow_dwarf = follow_id

	var desig_data = data.get("designation", {})
	if not desig_data.is_empty():
		main.designation = DFDesignation.new(w)
		main.designation.mode = desig_data.get("mode", 0)
		main.designation.selection_start = _arr_to_v3i(desig_data.get("selection_start", [-1, -1, -1]))
		main.designation.selection_end = _arr_to_v3i(desig_data.get("selection_end", [-1, -1, -1]))
		main.designation.is_selecting = desig_data.get("is_selecting", false)
		main.designation.building_type_to_build = desig_data.get("building_type_to_build", 1)
		main.designation.job_queue = []
		for jd in desig_data.get("job_queue", []):
			main.designation.job_queue.append(_dict_to_job(jd))
	else:
		main.designation = null

	if main.renderer != null:
		main.renderer.set_world(w)
		main.renderer.designation = main.designation
		main.renderer.paused = main.paused
		main.renderer.game_year = main._game_year
		main.renderer.game_hour = main._game_hour
		main.renderer.game_day = main._game_day
		main.renderer.game_season = main._game_season

	w.combat_system = null
	w.invasion_system = null
	w.military_system = null
