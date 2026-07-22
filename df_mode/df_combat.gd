extends RefCounted
class_name DFCombat

enum WeaponSkill {
	AXE, SWORD, MACE, SPEAR, HAMMER, CROSSBOW, BOW, DAGGER, MAUL, FLAIL, WHIP,
	SCRATCH, BITE, GORE, STING, CLAW, TALON, FIST, KICK, HEADBUTT, THROW
}

enum DamageType {
	SLASH, BLUNT, PIERCE, FIRE, COLD, MAGIC, ACID, POISON, HOLY, NECROTIC,
	TRUE, SONIC, LIGHTNING, PSYCHIC
}

enum BodyPart {
	HEAD, NECK, UPPER_BODY, LOWER_BODY, LEFT_ARM, RIGHT_ARM,
	LEFT_HAND, RIGHT_HAND, LEFT_LEG, RIGHT_LEG, LEFT_FOOT, RIGHT_FOOT,
	LEFT_EYE, RIGHT_EYE, MOUTH, NOSE, EAR_LEFT, EAR_RIGHT, BRAIN, HEART,
	LUNGS, LIVER, SPLEEN, KIDNEYS, STOMACH, INTESTINES, SPINE, PANCREAS,
	GALLBLADDER, THYROID, UPPER_SPINE, LOWER_SPINE, RIBCAGE, PELVIS
}

enum WeaponCategory {
	DAGGERS, SWORDS_SHORT, SWORDS_LONG, SWORDS_2H, AXES_HAND, AXES_BATTLE,
	AXES_GREAT, MACES, MAULS, FLAILS, HAMMERS_WAR, SPEARS, PIKE, HALBERD,
	BOWS, CROSSBOWS, BLOWGUNS, WHIPS, SCOURGES, SCRATCH_BITE, NATURAL,
	SIEGE, THROWN, IMPROVISED
}

enum ArmorSlot {
	HEAD, NECK, TORSO, ARMS, HANDS, LEGS, FEET, SHIELD, OVERALL
}

enum AttackType {
	SWING, THRUST, CHOP, STAB, SLASH, CRUSH, POUND, KICK, HEADBUTT,
	BITE, SCRATCH, CLAW, GORE, STING, DODGE, PARRY, BLOCK, THROW,
	CHARGE, LUNGE, SWEEP, COMBO, VICIOUS
}

enum SpecialAttack {
	NONE, BLEEDING, POISON, FIRE, ACID, STUN, KNOCKBACK, GRAB,
	DISARM, SHIELD_BASH, CHARGE, SWEEP, MULTI_HIT, ARMOR_PIERCING,
	BLEEDING_INTENSE, CRUSHING_BLOW, PRECISE_HIT, WILD_SWING, CHOP,
	COUNTER_ATTACK, RETALIATION, BERSERK_RAGE, FINISHING_BLOW
}

enum InjuryType {
	BRUISE, CUT, PUNCTURE, LACERATION, FRACTURE, CRUSH, BURN, FROSTBITE,
	SEVER, DISLOCATION, SPRAIN, RUPTURE, GOUGE, BITE_WOUND, GORE_WOUND,
	STAB_WOUND, CHOP_WOUND, BURN_ACID, POISON_WOUND, INFECTED
}

enum CombatStance {
	AGGRESSIVE, NORMAL, DEFENSIVE, RECKLESS, CAUTIOUS, BERSERK
}

enum WoundSeverity {
	SUPERFICIAL, MINOR, MODERATE, SEVERE, CRITICAL, MORTAL
}

const MAX_SKILL: int = 100
const MAX_STRENGTH: float = 50.0
const MAX_AGILITY: float = 50.0
const MAX_TOUGHNESS: float = 50.0
const BASE_HIT_CHANCE: float = 0.75
const BLOCK_CHANCE_BASE: float = 0.25
const DODGE_CHANCE_BASE: float = 0.10
const CRIT_MULTIPLIER: float = 2.0
const CRIT_CHANCE_BASE: float = 0.05
const PARRY_CHANCE_BASE: float = 0.15
const DISARM_CHANCE_BASE: float = 0.05
const STUN_CHANCE_BASE: float = 0.05
const BLEED_CHANCE_BASE: float = 0.20
const INFECTION_RATE: float = 0.05
const SHIELD_BLOCK_ANGLE: float = 60.0
const REACH_TINY: float = 0.5
const REACH_SHORT: float = 1.0
const REACH_MEDIUM: float = 1.5
const REACH_LONG: float = 2.0
const REACH_VERY_LONG: float = 3.0
const WEIGHT_LIGHT: float = 1.0
const WEIGHT_MEDIUM: float = 2.0
const WEIGHT_HEAVY: float = 3.5
const WEIGHT_VERY_HEAVY: float = 5.0
const STANCE_MODIFIERS = {
	CombatStance.AGGRESSIVE: {"hit": 0.10, "damage": 0.20, "dodge": -0.10, "parry": -0.10, "block": -0.05},
	CombatStance.NORMAL: {"hit": 0.0, "damage": 0.0, "dodge": 0.0, "parry": 0.0, "block": 0.0},
	CombatStance.DEFENSIVE: {"hit": -0.10, "damage": -0.15, "dodge": 0.10, "parry": 0.10, "block": 0.10},
	CombatStance.RECKLESS: {"hit": 0.15, "damage": 0.30, "dodge": -0.20, "parry": -0.15, "block": -0.10},
	CombatStance.CAUTIOUS: {"hit": -0.05, "damage": -0.10, "dodge": 0.15, "parry": 0.05, "block": 0.05},
	CombatStance.BERSERK: {"hit": 0.20, "damage": 0.40, "dodge": -0.25, "parry": -0.20, "block": -0.15}
}


const BODY_PART_NAMES = {
	BodyPart.HEAD: "Cabeza", BodyPart.NECK: "Cuello",
	BodyPart.UPPER_BODY: "Torso Superior", BodyPart.LOWER_BODY: "Torso Inferior",
	BodyPart.LEFT_ARM: "Brazo Izquierdo", BodyPart.RIGHT_ARM: "Brazo Derecho",
	BodyPart.LEFT_HAND: "Mano Izquierda", BodyPart.RIGHT_HAND: "Mano Derecha",
	BodyPart.LEFT_LEG: "Pierna Izquierda", BodyPart.RIGHT_LEG: "Pierna Derecha",
	BodyPart.LEFT_FOOT: "Pie Izquierdo", BodyPart.RIGHT_FOOT: "Pie Derecho",
	BodyPart.BRAIN: "Cerebro", BodyPart.HEART: "Corazón",
	BodyPart.LUNGS: "Pulmones", BodyPart.SPINE: "Columna"
}

const INJURY_NAMES = {
	InjuryType.BRUISE: "Magulladura", InjuryType.CUT: "Corte",
	InjuryType.PUNCTURE: "Perforación", InjuryType.LACERATION: "Laceración",
	InjuryType.FRACTURE: "Fractura", InjuryType.CRUSH: "Aplastamiento",
	InjuryType.BURN: "Quemadura", InjuryType.FROSTBITE: "Congelación",
	InjuryType.SEVER: "Desmembramiento", InjuryType.DISLOCATION: "Dislocación",
	InjuryType.SPRAIN: "Esguince", InjuryType.RUPTURE: "Ruptura",
	InjuryType.GOUGE: "Arrancamiento", InjuryType.BITE_WOUND: "Mordedura",
	InjuryType.GORE_WOUND: "Cornada", InjuryType.STAB_WOUND: "Puñalada",
	InjuryType.CHOP_WOUND: "Tajo", InjuryType.BURN_ACID: "Quemadura Ácida",
	InjuryType.POISON_WOUND: "Envenenamiento", InjuryType.INFECTED: "Infección"
}

var meat_yield: Dictionary = {
	"small": {"meat": 2, "bones": 1, "skin": 1, "fat": 1, "intestines": 1},
	"medium": {"meat": 5, "bones": 3, "skin": 2, "fat": 3, "intestines": 2},
	"large": {"meat": 12, "bones": 6, "skin": 4, "fat": 8, "intestines": 4, "heart": 1, "liver": 1},
	"megabeast": {"meat": 50, "bones": 20, "skin": 10, "fat": 30, "intestines": 15,
		"heart": 1, "liver": 1, "brain": 1, "eyes": 2, "rare_mat": 1}
}

var combat_log: Array = []
# var _tick: int = 0
var _rng: RandomNumberGenerator

var weapon_tables: Dictionary = {}
var armor_tables: Dictionary = {}
var combat_stats: Dictionary = {}

func _init():
	_rng = RandomNumberGenerator.new()

func calculate_physical_damage(
	attacker_strength: float,
	attacker_skill: float,
	weapon_damage: float,
	weapon_skill: int,
	damage_type: int
) -> Dictionary:
	var str_mod = 0.5 + (attacker_strength / MAX_STRENGTH)
	var skill_mod = 0.5 + (attacker_skill / 50.0)
	var base_damage = weapon_damage * str_mod * skill_mod
	if base_damage < 0.5:
		base_damage = 0.5

	var crit_roll = randf()
	var is_critical = crit_roll < (CRIT_CHANCE_BASE + (attacker_skill / (MAX_SKILL * 4.0)))
	if is_critical:
		base_damage *= CRIT_MULTIPLIER

	var variance = 0.8 + randf() * 0.4
	base_damage *= variance

	var injury_type = _get_injury_type(damage_type, base_damage)
	var special = _get_special_attack(weapon_skill, damage_type, is_critical)

	return {
		"damage": base_damage,
		"type": damage_type,
		"is_critical": is_critical,
		"weapon_skill": weapon_skill,
		"injury_type": injury_type,
		"special": special
	}

func _get_injury_type(damage_type: int, damage: float) -> int:
	match damage_type:
		DamageType.SLASH:
			return InjuryType.LACERATION if damage > 10 else InjuryType.CUT
		DamageType.BLUNT:
			return InjuryType.FRACTURE if damage > 15 else InjuryType.BRUISE
		DamageType.PIERCE:
			return InjuryType.PUNCTURE if damage > 8 else InjuryType.STAB_WOUND
		DamageType.FIRE:
			return InjuryType.BURN
		DamageType.COLD:
			return InjuryType.FROSTBITE
		DamageType.ACID:
			return InjuryType.BURN_ACID
		_:
			return InjuryType.BRUISE

func _get_special_attack(weapon_skill: int, _damage_type: int, is_critical: bool) -> int:
	if is_critical and randf() < 0.3:
		return SpecialAttack.FINISHING_BLOW if randf() < 0.5 else SpecialAttack.CRUSHING_BLOW

	var weapon_cat = _get_weapon_category(weapon_skill)
	match weapon_cat:
		WeaponCategory.AXES_BATTLE, WeaponCategory.AXES_GREAT, WeaponCategory.AXES_HAND:
			if randf() < 0.15:
				return SpecialAttack.CHOP if randf() < 0.5 else SpecialAttack.WILD_SWING
		WeaponCategory.SWORDS_LONG, WeaponCategory.SWORDS_2H:
			if randf() < 0.10:
				return SpecialAttack.PRECISE_HIT
		WeaponCategory.SPEARS, WeaponCategory.PIKE:
			if randf() < 0.10:
				return SpecialAttack.ARMOR_PIERCING
		WeaponCategory.HAMMERS_WAR, WeaponCategory.MAULS:
			if randf() < 0.15:
				return SpecialAttack.CRUSHING_BLOW
	return SpecialAttack.NONE

func _get_weapon_category(weapon_skill: int) -> int:
	match weapon_skill:
		WeaponSkill.AXE: return WeaponCategory.AXES_BATTLE
		WeaponSkill.SWORD: return WeaponCategory.SWORDS_LONG
		WeaponSkill.SPEAR: return WeaponCategory.SPEARS
		WeaponSkill.HAMMER: return WeaponCategory.HAMMERS_WAR
		WeaponSkill.MACE: return WeaponCategory.MACES
		WeaponSkill.MAUL: return WeaponCategory.MAULS
		WeaponSkill.FLAIL: return WeaponCategory.FLAILS
		WeaponSkill.DAGGER: return WeaponCategory.DAGGERS
		_: return WeaponCategory.NATURAL

func calculate_armor_reduction(
	incoming_damage: float,
	armor_value: float,
	damage_type: int
) -> Dictionary:
	var reduction = 0.0
	match damage_type:
		DamageType.SLASH:
			reduction = armor_value * 0.7
		DamageType.BLUNT:
			reduction = armor_value * 0.5
		DamageType.PIERCE:
			reduction = armor_value * 0.4
		DamageType.FIRE:
			reduction = armor_value * 0.3
		DamageType.ACID:
			reduction = armor_value * 0.2
		DamageType.MAGIC:
			reduction = armor_value * 0.1
		_:
			reduction = armor_value * 0.3

	var absorbed = minf(incoming_damage * 0.9, reduction)
	var final_damage = maxf(0.5, incoming_damage - absorbed)
	var blocked = final_damage < incoming_damage

	return {
		"final_damage": final_damage,
		"reduction": absorbed,
		"blocked_some": blocked,
		"absorbed_pct": (absorbed / maxf(1.0, incoming_damage)) * 100.0
	}

func resolve_attack(
	attacker_ref,
	defender_ref,
	weapon_damage: float = 5.0,
	weapon_skill: int = WeaponSkill.SCRATCH,
	damage_type: int = DamageType.BLUNT,
	attack_type: int = AttackType.SWING,
	attacker_pos: Vector3i = Vector3i(0, 0, 0),
	defender_pos: Vector3i = Vector3i(0, 0, 0)
) -> Dictionary:
	var attack_stats = _get_attack_stats(attacker_ref)
	var defense_stats = _get_defense_stats(defender_ref)

	var attacker_stance = attack_stats.get("stance", CombatStance.NORMAL)
	var stance_mod = get_stance_modifiers(attacker_stance)
	var weapon_data = attack_stats.get("weapon_data", {})
	var weapon_reach = weapon_data.get("reach", REACH_TINY)
	var weapon_weight = weapon_data.get("weight", WEIGHT_LIGHT)
	var weapon_material = weapon_data.get("material", "iron")
	var material_mod = get_material_quality_modifier(weapon_material)

	var momentum_bonus = calculate_momentum_bonus(attacker_pos, defender_pos, attack_stats.get("speed", 1.0), weapon_weight)
	var fatigue_cost = calculate_fatigue_cost(weapon_weight, attack_type)

	var target_body_part = BodyPart.UPPER_BODY
	match attack_type:
		AttackType.THRUST, AttackType.STAB:
			target_body_part = BodyPart.UPPER_BODY
		AttackType.CHOP, AttackType.SLASH:
			target_body_part = _random_body_part()
		AttackType.CRUSH, AttackType.POUND:
			target_body_part = BodyPart.UPPER_BODY
		AttackType.KICK:
			target_body_part = BodyPart.LEFT_LEG if randi() % 2 == 0 else BodyPart.RIGHT_LEG
		AttackType.HEADBUTT:
			target_body_part = BodyPart.HEAD
		AttackType.BITE:
			target_body_part = _random_body_part()

	var hit_chance = BASE_HIT_CHANCE
	hit_chance += (attack_stats["agility"] - defense_stats["agility"]) * 0.005
	hit_chance += (attack_stats["attack_skill"] - defense_stats["defense_skill"]) * 0.002
	hit_chance += stance_mod["hit"]
	# Reach advantage: longer weapon = easier to hit
	var reach_diff = weapon_reach - defense_stats.get("weapon_reach", REACH_TINY)
	if reach_diff > 0:
		hit_chance += reach_diff * 0.03
	hit_chance = clampf(hit_chance, 0.1, 0.95)

	if randf() > hit_chance:
		var miss_type = _get_miss_type()
		var miss_msg = "%s %s contra %s" % [_get_name(attacker_ref), miss_type, _get_name(defender_ref)]
		_add_log(miss_msg)
		return {"hit": false, "damage": 0, "fatal": false, "message": miss_msg, "fatigue_cost": fatigue_cost * 0.5}

	var dodge_chance = DODGE_CHANCE_BASE + defense_stats["agility"] * 0.005 + stance_mod["dodge"]
	# Fatigue penalty: tired entities dodge worse
	var defender_fatigue = defense_stats.get("fatigue", 0.0)
	dodge_chance -= defender_fatigue * 0.1
	dodge_chance = clampf(dodge_chance, 0.05, 0.6)
	if randf() < dodge_chance:
		_add_log("%s esquivó el ataque de %s" % [_get_name(defender_ref), _get_name(attacker_ref)])
		return {"hit": false, "damage": 0, "fatal": false, "message": "esquivó", "fatigue_cost": fatigue_cost}

	if defense_stats["has_shield"]:
		var block_chance = BLOCK_CHANCE_BASE + defense_stats["shield_skill"] * 0.003 + stance_mod["block"]
		# High fatigue reduces block
		block_chance -= defender_fatigue * 0.05
		block_chance = clampf(block_chance, 0.05, 0.5)
		if randf() < block_chance:
			_add_log("%s bloqueó el ataque de %s con su escudo" % [_get_name(defender_ref), _get_name(attacker_ref)])
			var shield_damage = weapon_damage * 0.3
			return {"hit": false, "damage": 0, "fatal": false, "message": "bloqueó", "shield_damage": shield_damage, "fatigue_cost": fatigue_cost * 0.8}

	if defense_stats.get("can_parry", false):
		var parry_chance = PARRY_CHANCE_BASE + defense_stats["attack_skill"] * 0.002 + stance_mod["parry"]
		parry_chance = clampf(parry_chance, 0.05, 0.4)
		if randf() < parry_chance:
			_add_log("%s paró el ataque de %s" % [_get_name(defender_ref), _get_name(attacker_ref)])
			return {"hit": false, "damage": 0, "fatal": false, "message": "paró", "fatigue_cost": fatigue_cost * 0.7}

	var adjusted_damage = weapon_damage * material_mod + momentum_bonus
	adjusted_damage *= (1.0 + stance_mod["damage"])

	var dmg_result = calculate_physical_damage(
		attack_stats["strength"],
		attack_stats["weapon_skill_level"],
		adjusted_damage,
		weapon_skill,
		damage_type
	)

	var armor_val = defense_stats["armor_value"]
	# Armor-piercing from reach/momentum: a charging spear pierces better
	if attack_type == AttackType.CHARGE and weapon_reach >= REACH_LONG:
		armor_val *= 0.7
	var final = calculate_armor_reduction(dmg_result["damage"], armor_val, damage_type)

	var fatal = _apply_damage(defender_ref, final["final_damage"], target_body_part, dmg_result["is_critical"])

	if dmg_result["special"] != SpecialAttack.NONE:
		_apply_special_effect(dmg_result["special"], attacker_ref, defender_ref, final["final_damage"], target_body_part)

	var body_part_name = BODY_PART_NAMES.get(target_body_part, "cuerpo")
	var msg = "%s atacó %s de %s causando %.0f pts de daño%s" % [
		_get_name(attacker_ref),
		body_part_name.to_lower(),
		_get_name(defender_ref),
		final["final_damage"],
		" ¡CRÍTICO!" if dmg_result["is_critical"] else ""
	]

	if final["blocked_some"] and final["reduction"] > 0:
		msg += " (armadura absorbió %.0f pts)" % final["reduction"]

	if momentum_bonus > 2.0:
		msg += " [IMPULSO +%.0f]" % momentum_bonus

	if dmg_result["special"] != SpecialAttack.NONE:
		msg += " [%s]" % _get_special_name(dmg_result["special"])

	if dmg_result["injury_type"] != InjuryType.BRUISE:
		var injury_name = INJURY_NAMES.get(dmg_result["injury_type"], "herida")
		msg += " causando %s en %s" % [injury_name.to_lower(), body_part_name.to_lower()]

	_add_log(msg)

	if fatal:
		_add_log("¡%s ha muerto!" % _get_name(defender_ref))

	return {
		"hit": true,
		"damage": final["final_damage"],
		"fatal": fatal,
		"body_part": target_body_part,
		"is_critical": dmg_result["is_critical"],
		"injury_type": dmg_result["injury_type"],
		"special": dmg_result["special"],
		"message": msg,
		"fatigue_cost": fatigue_cost,
		"momentum": momentum_bonus,
		"material_mod": material_mod
	}

func _get_miss_type() -> String:
	var misses = [
		"falló su ataque", "erró por poco", "atacó al aire",
		"su golpe no conectó", "perdió el equilibrio al atacar",
		"su arma silbó en el aire sin alcanzar"
	]
	return misses[randi() % misses.size()]

func _get_special_name(special: int) -> String:
	var names = {
		SpecialAttack.BLEEDING: "SANGRANTE",
		SpecialAttack.POISON: "VENENOSO",
		SpecialAttack.FIRE: "LLAMEANTE",
		SpecialAttack.ACID: "ÁCIDO",
		SpecialAttack.STUN: "ATURDIDOR",
		SpecialAttack.KNOCKBACK: "RECHAZO",
		SpecialAttack.GRAB: "AGARRE",
		SpecialAttack.DISARM: "DESARME",
		SpecialAttack.SHIELD_BASH: "GOLPE DE ESCUDO",
		SpecialAttack.CHARGE: "CARGA",
		SpecialAttack.SWEEP: "BARRIDO",
		SpecialAttack.ARMOR_PIERCING: "PERFORANTE",
		SpecialAttack.BLEEDING_INTENSE: "HEMATOMA",
		SpecialAttack.CRUSHING_BLOW: "APLASTANTE",
		SpecialAttack.PRECISE_HIT: "PRECISO",
		SpecialAttack.WILD_SWING: "SALVAJE",
		SpecialAttack.COUNTER_ATTACK: "CONTRAATAQUE",
		SpecialAttack.FINISHING_BLOW: "¡GOLPE FINAL!"
	}
	return names.get(special, "ESPECIAL")

func _apply_special_effect(special: int, attacker, defender, damage: float, body_part: int) -> void:
	match special:
		SpecialAttack.BLEEDING, SpecialAttack.BLEEDING_INTENSE:
			var bleed_rate = damage * 0.05
			if defender.has_method("apply_bleeding"):
				defender.apply_bleeding(bleed_rate)
			_add_log("%s está sangrando profusamente." % _get_name(defender))

		SpecialAttack.POISON:
			if defender.has_method("add_thought"):
				defender.add_thought("Siente el veneno corriendo por sus venas.", -0.15)
			_add_log("%s ha sido envenenado." % _get_name(defender))

		SpecialAttack.STUN:
			if "stun_timer" in defender:
				defender.stun_timer = 2 + randi() % 3
			_add_log("%s quedó aturdido por el golpe." % _get_name(defender))

		SpecialAttack.KNOCKBACK:
			if defender.has_method("get") and attacker.has_method("get"):
				var def_pos = defender.tile_pos
				var atk_pos = attacker.tile_pos
				var dx = sign(def_pos.x - atk_pos.x)
				var dz = sign(def_pos.z - atk_pos.z)
				var new_pos = Vector3i(def_pos.x + dx, def_pos.y, def_pos.z + dz)
				if not (defender.has_method("is_blocked") and defender.is_blocked(new_pos)):
					defender.tile_pos = new_pos
					_add_log("%s fue arrojado hacia atrás." % _get_name(defender))

		SpecialAttack.DISARM:
			if defender.has_method("equip_weapon"):
				defender.equip_weapon("fist")
			_add_log("¡%s fue desarmado!" % _get_name(defender))

		SpecialAttack.SHIELD_BASH:
			if attacker.has_method("equipped_shield") and attacker.equipped_shield != "":
				var bash_damage = damage * 0.5
				_apply_damage(defender, bash_damage, BodyPart.UPPER_BODY, false)
				_add_log("%s golpeó con su escudo a %s." % [_get_name(attacker), _get_name(defender)])

		SpecialAttack.FINISHING_BLOW:
			var extra_damage = damage * 1.5
			_apply_damage(defender, extra_damage, BodyPart.HEAD, true)
			_add_log("¡%s asestó un golpe mortal a %s en la cabeza!" % [_get_name(attacker), _get_name(defender)])

		SpecialAttack.ARMOR_PIERCING:
			var ignore_armor = damage * 0.3
			_apply_damage(defender, ignore_armor, body_part, false)
			_add_log("¡El ataque perforó la armadura de %s!" % _get_name(defender))

func _apply_damage(entity, damage: float, body_part: int, is_critical: bool) -> bool:
	if entity.has_method("take_damage"):
		var fatal = entity.take_damage(damage, body_part, is_critical)
		if damage > 10:
			var pain_amount = damage * 0.5
			if entity.has_method("inflict_pain"):
				entity.inflict_pain(pain_amount)
		return fatal
	return false

func creature_attack(creature_ref, dwarf_ref) -> Dictionary:
	var sz_val = creature_ref.get("size")
	var creature_size = sz_val if sz_val != null else "medium"
	var base_damage = {"small": 3.0, "medium": 8.0, "large": 18.0, "megabeast": 40.0,
		"tiny": 1.5, "giant": 65.0}.get(creature_size, 8.0)

	var _eq_wep = creature_ref.get("equipped_weapon")
	# var has_weapon = _eq_wep if _eq_wep != null else "fist"
	var natural_skills = [WeaponSkill.SCRATCH, WeaponSkill.BITE]
	var skill = natural_skills[randi() % natural_skills.size()]
	var damage_type = DamageType.SLASH

	var _cr_type = creature_ref.get("creature_type")
	var creature_qualities = _cr_type if _cr_type != null else ""
	if "dragon" in creature_qualities or "fire" in creature_qualities.to_lower():
		damage_type = DamageType.FIRE
		base_damage *= 1.5
	elif "giant" in creature_qualities.to_lower():
		skill = WeaponSkill.CLAW
		damage_type = DamageType.SLASH
	elif "undead" in creature_qualities.to_lower() or "zombie" in creature_qualities.to_lower():
		damage_type = DamageType.NECROTIC
		skill = WeaponSkill.BITE

	var attack_type = _get_creature_attack_type(creature_size)
	var _atk_p = creature_ref.get("tile_pos")
	var atk_pos = _atk_p if _atk_p != null else Vector3i(0, 0, 0)
	var _def_p = dwarf_ref.get("tile_pos")
	var def_pos = _def_p if _def_p != null else Vector3i(0, 0, 0)
	return resolve_attack(creature_ref, dwarf_ref, base_damage, skill, damage_type, attack_type, atk_pos, def_pos)

func _get_creature_attack_type(creature_size: String) -> int:
	match creature_size:
		"tiny", "small":
			return AttackType.BITE if randi() % 2 == 0 else AttackType.SCRATCH
		"medium":
			return [AttackType.SWING, AttackType.BITE, AttackType.CLAW, AttackType.CHARGE][randi() % 4]
		"large":
			return [AttackType.CRUSH, AttackType.GORE, AttackType.CHARGE, AttackType.POUND][randi() % 4]
		"giant", "megabeast":
			return [AttackType.CRUSH, AttackType.SWEEP, AttackType.CHARGE, AttackType.POUND, AttackType.COMBO][randi() % 5]
		_:
			return AttackType.SWING

func _get_attack_stats(entity) -> Dictionary:
	if entity.has_method("get_combat_attack_stats"):
		return entity.get_combat_attack_stats()
	return {
		"strength": 5.0,
		"agility": 3.0,
		"attack_skill": 2.0,
		"weapon_skill_level": 1.0,
		"can_parry": false,
		"stance": CombatStance.NORMAL,
		"speed": 1.0,
		"fatigue": 0.0,
		"weapon_data": {"reach": REACH_TINY, "weight": WEIGHT_LIGHT, "material": "flesh"}
	}

func _get_defense_stats(entity) -> Dictionary:
	if entity.has_method("get_combat_defense_stats"):
		return entity.get_combat_defense_stats()
	return {
		"agility": 2.0,
		"defense_skill": 1.0,
		"armor_value": 0.0,
		"has_shield": false,
		"shield_skill": 0.0,
		"can_parry": false,
		"fatigue": 0.0,
		"weapon_reach": REACH_TINY
	}

func _get_name(entity) -> String:
	if entity.has_method("get_entity_name"):
		return entity.get_entity_name()
	var n_val = entity.get("name")
	return n_val if n_val != null else "Algo"

func _random_body_part() -> int:
	var roll = randf()
	if roll < 0.03: return BodyPart.HEAD
	elif roll < 0.06: return BodyPart.NECK
	elif roll < 0.15: return BodyPart.BRAIN
	elif roll < 0.20: return BodyPart.HEART
	elif roll < 0.28: return BodyPart.LUNGS
	elif roll < 0.40: return BodyPart.UPPER_BODY
	elif roll < 0.50: return BodyPart.LOWER_BODY
	elif roll < 0.55: return BodyPart.LEFT_ARM
	elif roll < 0.60: return BodyPart.RIGHT_ARM
	elif roll < 0.63: return BodyPart.LEFT_HAND
	elif roll < 0.66: return BodyPart.RIGHT_HAND
	elif roll < 0.73: return BodyPart.LEFT_LEG
	elif roll < 0.80: return BodyPart.RIGHT_LEG
	elif roll < 0.83: return BodyPart.LEFT_FOOT
	elif roll < 0.86: return BodyPart.RIGHT_FOOT
	elif roll < 0.90: return BodyPart.SPINE
	elif roll < 0.93: return BodyPart.LIVER
	elif roll < 0.96: return BodyPart.STOMACH
	else: return BodyPart.KIDNEYS

func get_wound_severity(damage: float) -> String:
	if damage < 3: return "Superficial"
	elif damage < 8: return "Leve"
	elif damage < 15: return "Moderada"
	elif damage < 25: return "Grave"
	elif damage < 40: return "Crítica"
	else: return "Mortal"

func _add_log(msg: String) -> void:
	combat_log.append(msg)
	if combat_log.size() > 100:
		combat_log.pop_front()

func get_recent_log(count: int = 5) -> Array:
	var result = []
	var start = max(0, combat_log.size() - count)
	for i in range(start, combat_log.size()):
		result.append(combat_log[i])
	return result

func clear_log() -> void:
	combat_log.clear()

func loot_creature(creature_type: String, creature_size: String, seed: int) -> Array:
	var rng = RandomNumberGenerator.new()
	rng.seed = seed
	var loot = []
	var yields = meat_yield.get(creature_size, meat_yield["medium"])

	if yields.get("meat", 0) > 0:
		loot.append({
			"name": "Carne de %s" % creature_type.to_lower(),
			"type": "food",
			"count": rng.randi_range(max(1, yields["meat"] / 2), yields["meat"]),
			"nutrition": 0.3
		})
	if yields.get("bones", 0) > 0:
		loot.append({
			"name": "Huesos de %s" % creature_type.to_lower(),
			"type": "crafting",
			"count": rng.randi_range(max(1, yields["bones"] / 2), yields["bones"]),
			"material": "bone"
		})
	if yields.get("skin", 0) > 0:
		loot.append({
			"name": "Piel de %s" % creature_type.to_lower(),
			"type": "crafting",
			"count": rng.randi_range(max(1, yields["skin"] / 2), yields["skin"]),
			"material": "leather"
		})
	if yields.get("fat", 0) > 0:
		loot.append({
			"name": "Grasa de %s" % creature_type.to_lower(),
			"type": "crafting",
			"count": rng.randi_range(max(1, yields["fat"] / 2), yields["fat"]),
			"material": "fat"
		})
	if yields.get("heart", 0) > 0:
		loot.append({
			"name": "Corazón de %s" % creature_type.to_lower(),
			"type": "rare",
			"count": 1,
			"material": "organ"
		})
	if yields.get("liver", 0) > 0:
		loot.append({
			"name": "Hígado de %s" % creature_type.to_lower(),
			"type": "rare",
			"count": 1,
			"material": "organ"
		})
	if creature_size == "megabeast" and yields.get("rare_mat", 0) > 0:
		loot.append({
			"name": "Reliquia de %s" % creature_type.to_lower(),
			"type": "artifact",
			"count": 1,
			"material": "artifact"
		})

	return loot

func resolve_mass_combat(attackers: Array, defenders: Array, world) -> Dictionary:
	var results = {
		"attackers_casualties": 0,
		"defenders_casualties": 0,
		"attacker_victory": false,
		"defender_victory": false,
		"log": []
	}

	var total_attacker_strength = 0.0
	var total_defender_strength = 0.0

	for a in attackers:
		var stats = _get_attack_stats(a)
		total_attacker_strength += stats["strength"] + stats["weapon_skill_level"]

	for d in defenders:
		var stats_686 = _get_attack_stats(d)
		total_defender_strength += stats_686["strength"] + stats_686["weapon_skill_level"]

	var rounds = max(3, min(10, int(total_attacker_strength + total_defender_strength) / 5))
	for r in range(rounds):
		if attackers.is_empty() or defenders.is_empty():
			break

		var a_694 = attackers[randi() % attackers.size()]
		var d_695 = defenders[randi() % defenders.size()]

		var result = creature_attack(a_694, d_695)
		results["log"].append(result.get("message", ""))

		if result["fatal"]:
			results["defenders_casualties"] += 1
			defenders.erase(d_695)
		elif randi() % 3 == 0:
			var counter = creature_attack(d_695, a_694)
			results["log"].append(counter.get("message", ""))
			if counter["fatal"]:
				results["attackers_casualties"] += 1
				attackers.erase(a_694)

	if defenders.is_empty():
		results["attacker_victory"] = true
	else:
		results["defender_victory"] = true

	return results

static func get_weapon_base_damage(weapon_name: String) -> Dictionary:
	var weapons = {
		"fist": {"damage": 2.0, "skill": WeaponSkill.FIST, "type": DamageType.BLUNT, "name": "Puño", "category": WeaponCategory.NATURAL, "reach": REACH_TINY, "weight": WEIGHT_LIGHT, "material": "flesh", "two_handed": false},
		"bite": {"damage": 3.0, "skill": WeaponSkill.BITE, "type": DamageType.PIERCE, "name": "Mordisco", "category": WeaponCategory.NATURAL, "reach": REACH_TINY, "weight": WEIGHT_LIGHT, "material": "flesh", "two_handed": false},
		"claw": {"damage": 4.0, "skill": WeaponSkill.CLAW, "type": DamageType.SLASH, "name": "Garra", "category": WeaponCategory.NATURAL, "reach": REACH_TINY, "weight": WEIGHT_LIGHT, "material": "flesh", "two_handed": false},
		"kick": {"damage": 3.5, "skill": WeaponSkill.KICK, "type": DamageType.BLUNT, "name": "Patada", "category": WeaponCategory.NATURAL, "reach": REACH_SHORT, "weight": WEIGHT_LIGHT, "material": "flesh", "two_handed": false},
		"headbutt": {"damage": 4.0, "skill": WeaponSkill.HEADBUTT, "type": DamageType.BLUNT, "name": "Cabezazo", "category": WeaponCategory.NATURAL, "reach": REACH_TINY, "weight": WEIGHT_LIGHT, "material": "flesh", "two_handed": false},
		"gore": {"damage": 8.0, "skill": WeaponSkill.GORE, "type": DamageType.PIERCE, "name": "Cornada", "category": WeaponCategory.NATURAL, "reach": REACH_SHORT, "weight": WEIGHT_MEDIUM, "material": "flesh", "two_handed": false},
		"sting": {"damage": 3.0, "skill": WeaponSkill.STING, "type": DamageType.PIERCE, "name": "Aguijón", "category": WeaponCategory.NATURAL, "reach": REACH_SHORT, "weight": WEIGHT_LIGHT, "material": "flesh", "two_handed": false, "poison": 0.3},
		"axe_battle": {"damage": 15.0, "skill": WeaponSkill.AXE, "type": DamageType.SLASH, "name": "Hacha de Batalla", "category": WeaponCategory.AXES_BATTLE, "reach": REACH_MEDIUM, "weight": WEIGHT_HEAVY, "material": "iron", "two_handed": false},
		"sword_short": {"damage": 10.0, "skill": WeaponSkill.SWORD, "type": DamageType.SLASH, "name": "Espada Corta", "category": WeaponCategory.SWORDS_SHORT, "reach": REACH_SHORT, "weight": WEIGHT_MEDIUM, "material": "iron", "two_handed": false},
		"sword_long": {"damage": 14.0, "skill": WeaponSkill.SWORD, "type": DamageType.SLASH, "name": "Espada Larga", "category": WeaponCategory.SWORDS_LONG, "reach": REACH_MEDIUM, "weight": WEIGHT_MEDIUM, "material": "iron", "two_handed": false},
		"sword_2h": {"damage": 18.0, "skill": WeaponSkill.SWORD, "type": DamageType.SLASH, "name": "Espada a Dos Manos", "category": WeaponCategory.SWORDS_2H, "reach": REACH_LONG, "weight": WEIGHT_HEAVY, "material": "iron", "two_handed": true},
		"spear": {"damage": 9.0, "skill": WeaponSkill.SPEAR, "type": DamageType.PIERCE, "name": "Lanza", "category": WeaponCategory.SPEARS, "reach": REACH_LONG, "weight": WEIGHT_MEDIUM, "material": "iron", "two_handed": false},
		"pike": {"damage": 12.0, "skill": WeaponSkill.SPEAR, "type": DamageType.PIERCE, "name": "Pica", "category": WeaponCategory.PIKE, "reach": REACH_VERY_LONG, "weight": WEIGHT_HEAVY, "material": "iron", "two_handed": true},
		"halberd": {"damage": 14.0, "skill": WeaponSkill.SPEAR, "type": DamageType.SLASH, "name": "Alabarda", "category": WeaponCategory.HALBERD, "reach": REACH_LONG, "weight": WEIGHT_HEAVY, "material": "iron", "two_handed": true},
		"hammer_war": {"damage": 16.0, "skill": WeaponSkill.HAMMER, "type": DamageType.BLUNT, "name": "Martillo de Guerra", "category": WeaponCategory.HAMMERS_WAR, "reach": REACH_MEDIUM, "weight": WEIGHT_HEAVY, "material": "iron", "two_handed": false},
		"maul": {"damage": 20.0, "skill": WeaponSkill.MAUL, "type": DamageType.BLUNT, "name": "Mazo", "category": WeaponCategory.MAULS, "reach": REACH_MEDIUM, "weight": WEIGHT_VERY_HEAVY, "material": "iron", "two_handed": true},
		"mace": {"damage": 12.0, "skill": WeaponSkill.MACE, "type": DamageType.BLUNT, "name": "Maza", "category": WeaponCategory.MACES, "reach": REACH_SHORT, "weight": WEIGHT_MEDIUM, "material": "iron", "two_handed": false},
		"flail": {"damage": 13.0, "skill": WeaponSkill.FLAIL, "type": DamageType.BLUNT, "name": "Mayal", "category": WeaponCategory.FLAILS, "reach": REACH_MEDIUM, "weight": WEIGHT_MEDIUM, "material": "iron", "two_handed": false},
		"crossbow": {"damage": 8.0, "skill": WeaponSkill.CROSSBOW, "type": DamageType.PIERCE, "name": "Ballesta", "category": WeaponCategory.CROSSBOWS, "reach": REACH_VERY_LONG, "weight": WEIGHT_MEDIUM, "material": "wood", "two_handed": true},
		"bow": {"damage": 6.0, "skill": WeaponSkill.BOW, "type": DamageType.PIERCE, "name": "Arco", "category": WeaponCategory.BOWS, "reach": REACH_VERY_LONG, "weight": WEIGHT_MEDIUM, "material": "wood", "two_handed": true},
		"dagger_large": {"damage": 6.0, "skill": WeaponSkill.DAGGER, "type": DamageType.PIERCE, "name": "Daga Grande", "category": WeaponCategory.DAGGERS, "reach": REACH_SHORT, "weight": WEIGHT_LIGHT, "material": "iron", "two_handed": false},
		"morningstar": {"damage": 14.0, "skill": WeaponSkill.MACE, "type": DamageType.BLUNT, "name": "Estrella Matutina", "category": WeaponCategory.MACES, "reach": REACH_MEDIUM, "weight": WEIGHT_HEAVY, "material": "iron", "two_handed": false},
		"scimitar": {"damage": 11.0, "skill": WeaponSkill.SWORD, "type": DamageType.SLASH, "name": "Cimitarra", "category": WeaponCategory.SWORDS_SHORT, "reach": REACH_MEDIUM, "weight": WEIGHT_MEDIUM, "material": "iron", "two_handed": false},
		"whip": {"damage": 8.0, "skill": WeaponSkill.WHIP, "type": DamageType.SLASH, "name": "Látigo", "category": WeaponCategory.WHIPS, "reach": REACH_LONG, "weight": WEIGHT_LIGHT, "material": "leather", "two_handed": false},
		"scourge": {"damage": 10.0, "skill": WeaponSkill.WHIP, "type": DamageType.SLASH, "name": "Azote", "category": WeaponCategory.WHIPS, "reach": REACH_LONG, "weight": WEIGHT_LIGHT, "material": "leather", "two_handed": false},
		"axe_great": {"damage": 22.0, "skill": WeaponSkill.AXE, "type": DamageType.SLASH, "name": "Gran Hacha", "category": WeaponCategory.AXES_GREAT, "reach": REACH_LONG, "weight": WEIGHT_VERY_HEAVY, "material": "iron", "two_handed": true},
		"axe_hand": {"damage": 8.0, "skill": WeaponSkill.AXE, "type": DamageType.SLASH, "name": "Hacha de Mano", "category": WeaponCategory.AXES_HAND, "reach": REACH_SHORT, "weight": WEIGHT_MEDIUM, "material": "iron", "two_handed": false},
		"dagger": {"damage": 4.0, "skill": WeaponSkill.DAGGER, "type": DamageType.PIERCE, "name": "Daga", "category": WeaponCategory.DAGGERS, "reach": REACH_TINY, "weight": WEIGHT_LIGHT, "material": "iron", "two_handed": false},
		"club": {"damage": 6.0, "skill": WeaponSkill.MACE, "type": DamageType.BLUNT, "name": "Porra", "category": WeaponCategory.MACES, "reach": REACH_SHORT, "weight": WEIGHT_MEDIUM, "material": "wood", "two_handed": false},
		"quarterstaff": {"damage": 5.0, "skill": WeaponSkill.MACE, "type": DamageType.BLUNT, "name": "Bastón", "category": WeaponCategory.IMPROVISED, "reach": REACH_MEDIUM, "weight": WEIGHT_MEDIUM, "material": "wood", "two_handed": true},
	}
	return weapons.get(weapon_name, weapons["fist"])

static func get_armor_protection(armor_name: String) -> float:
	var armors = {
		"breastplate_steel": 12.0,
		"breastplate_iron": 10.0,
		"breastplate": 8.0,
		"mail_shirt_steel": 8.0,
		"mail_shirt_iron": 6.0,
		"mail_shirt": 5.0,
		"leather_armor": 4.0,
		"leather": 3.0,
		"coat": 2.0,
		"shirt": 0.5,
		"cloak": 1.0,
		"tunic": 1.0,
		"robe": 0.5,
		"plate_armor": 10.0,
		"helmet_steel": 6.0,
		"helmet_iron": 5.0,
		"helmet": 4.0,
		"cap": 2.0,
		"hood": 1.0,
		"greaves": 5.0,
		"leggings": 3.0,
		"gauntlets": 3.0,
		"gloves": 1.0,
		"boots": 2.0,
		"high_boots": 3.0,
		"shield_steel": 12.0,
		"shield_iron": 10.0,
		"shield_wood": 5.0,
		"shield_metal": 8.0,
		"buckler": 4.0,
	}
	return armors.get(armor_name, 0.0)

static func get_armor_slot(armor_name: String) -> int:
	var slots = {
		"breastplate": ArmorSlot.TORSO, "breastplate_steel": ArmorSlot.TORSO,
		"breastplate_iron": ArmorSlot.TORSO, "mail_shirt": ArmorSlot.TORSO,
		"plate_armor": ArmorSlot.TORSO, "leather_armor": ArmorSlot.TORSO,
		"helmet": ArmorSlot.HEAD, "helmet_steel": ArmorSlot.HEAD,
		"helmet_iron": ArmorSlot.HEAD, "cap": ArmorSlot.HEAD,
		"greaves": ArmorSlot.LEGS, "leggings": ArmorSlot.LEGS,
		"gauntlets": ArmorSlot.HANDS, "boots": ArmorSlot.FEET,
		"high_boots": ArmorSlot.FEET, "shield_wood": ArmorSlot.SHIELD,
		"shield_metal": ArmorSlot.SHIELD, "shield_steel": ArmorSlot.SHIELD,
		"shield_iron": ArmorSlot.SHIELD
	}
	return slots.get(armor_name, ArmorSlot.OVERALL)

func get_creature_combat_ai(creature_size: String) -> Dictionary:
	match creature_size:
		"tiny":
			return {
				"aggression": 0.1,
				"flee_threshold": 0.3,
				"attack_interval": 4.0,
				"prefers_weak": true,
				"pack_mentality": true,
				"ambush": false
			}
		"small":
			return {
				"aggression": 0.3,
				"flee_threshold": 0.2,
				"attack_interval": 3.0,
				"prefers_weak": true,
				"pack_mentality": false,
				"ambush": false
			}
		"medium":
			return {
				"aggression": 0.6,
				"flee_threshold": 0.1,
				"attack_interval": 2.0,
				"prefers_weak": true,
				"pack_mentality": true,
				"ambush": false
			}
		"large":
			return {
				"aggression": 0.8,
				"flee_threshold": 0.05,
				"attack_interval": 1.5,
				"prefers_weak": false,
				"pack_mentality": false,
				"ambush": true
			}
		"giant":
			return {
				"aggression": 0.9,
				"flee_threshold": 0.02,
				"attack_interval": 1.2,
				"prefers_weak": false,
				"pack_mentality": false,
				"ambush": false
			}
		"megabeast":
			return {
				"aggression": 1.0,
				"flee_threshold": 0.0,
				"attack_interval": 1.0,
				"prefers_weak": false,
				"pack_mentality": false,
				"ambush": false
			}
		_:
			return {
				"aggression": 0.5,
				"flee_threshold": 0.15,
				"attack_interval": 2.0,
				"prefers_weak": true,
				"pack_mentality": false,
				"ambush": false
			}

func get_stance_modifiers(stance: int) -> Dictionary:
	return STANCE_MODIFIERS.get(stance, STANCE_MODIFIERS[CombatStance.NORMAL])

func calculate_momentum_bonus(attacker_pos: Vector3i, defender_pos: Vector3i, attacker_speed: float, weapon_weight: float) -> float:
	var dist = abs(attacker_pos.x - defender_pos.x) + abs(attacker_pos.z - defender_pos.z)
	if dist <= 1:
		return 0.0
	var momentum = attacker_speed * weapon_weight * 0.15
	return clampf(momentum, 0.0, 15.0)

func get_material_quality_modifier(material: String) -> float:
	var props = DFMaterialProperties.compute_by_id(material.to_upper())
	var h = props.get("hardness", 5.0) / 10.0
	var ts = props.get("tensile_strength", 0.0) / 500.0
	var ifv = props.get("impact_fracture", 0.0) / 10.0
	return clampf(h * 0.5 + ts * 0.3 + ifv * 0.2, 0.1, 3.0)

func calculate_fatigue_cost(weapon_weight: float, attack_type: int) -> float:
	var base_cost = weapon_weight * 0.15
	match attack_type:
		AttackType.CHARGE, AttackType.LUNGE, AttackType.SWEEP:
			base_cost *= 1.5
		AttackType.COMBO, AttackType.VICIOUS:
			base_cost *= 2.0
		AttackType.THRUST, AttackType.STAB:
			base_cost *= 0.8
	return base_cost

func get_combat_style_description(style: int) -> String:
	match style:
		CombatStance.AGGRESSIVE: return "Agresivo"
		CombatStance.NORMAL: return "Normal"
		CombatStance.DEFENSIVE: return "Defensivo"
		CombatStance.RECKLESS: return "Imprudente"
		CombatStance.CAUTIOUS: return "Cauteloso"
		CombatStance.BERSERK: return "Berserker"
		_: return "Normal"
