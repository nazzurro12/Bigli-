class_name CreatureBehaviorRules
extends RefCounted
## Reglas puras reutilizables: no conocen el mapa ni la interfaz.

static func is_target_prey(prey_ids: PackedStringArray, target_id: String) -> bool:
	if prey_ids.is_empty():
		return true
	var normalized_target := normalize_id(target_id)
	for prey_id in prey_ids:
		if normalize_id(prey_id) == normalized_target:
			return true
	return false

static func should_flee(health_ratio: float, threshold: float) -> bool:
	return threshold > 0.0 and health_ratio <= threshold

static func normalize_id(value: String) -> String:
	return value.strip_edges().to_lower().replace(" ", "_")
