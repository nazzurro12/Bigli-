class_name CombatMath
extends RefCounted
## Cálculos sin efectos secundarios para combate configurable.

static func roll_attack_damage(base_damage: float, variation: float = 1.0) -> float:
	return maxf(0.0, base_damage + randf_range(-variation, variation))

static func health_after_damage(health_ratio: float, raw_damage: float, scale: float = 0.05) -> float:
	return clampf(health_ratio - raw_damage * scale, 0.0, 1.0)
