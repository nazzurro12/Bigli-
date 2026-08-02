extends RefCounted
class_name DFAutonomousPlan

const MAX_STEP_FAILURES: int = 3

static func create(goal: String, reason: String, steps: Array, target: Vector3i = Vector3i(-1, -1, -1)) -> Dictionary:
	return {
		"goal": goal,
		"reason": reason,
		"steps": steps.duplicate(true),
		"step_index": 0,
		"target": target,
		"state": "active",
		"failures": 0,
		"last_failure": "",
		"created_tick": Time.get_ticks_msec(),
	}

static func is_active(plan: Dictionary) -> bool:
	return not plan.is_empty() and plan.get("state", "") == "active"

static func is_complete(plan: Dictionary) -> bool:
	return not plan.is_empty() and plan.get("state", "") == "completed"

static func is_failed(plan: Dictionary) -> bool:
	return not plan.is_empty() and plan.get("state", "") == "failed"

static func current_step(plan: Dictionary) -> Dictionary:
	if plan.is_empty():
		return {}
	var steps: Array = plan.get("steps", [])
	var index: int = int(plan.get("step_index", 0))
	if index < 0 or index >= steps.size():
		return {}
	var value: Variant = steps[index]
	return value if value is Dictionary else {}

static func advance(plan: Dictionary) -> void:
	if plan.is_empty():
		return
	var next_index: int = int(plan.get("step_index", 0)) + 1
	plan["step_index"] = next_index
	var steps: Array = plan.get("steps", [])
	if next_index >= steps.size():
		plan["state"] = "completed"

static func fail_step(plan: Dictionary, reason: String) -> void:
	if plan.is_empty():
		return
	plan["failures"] = int(plan.get("failures", 0)) + 1
	plan["last_failure"] = reason
	if int(plan["failures"]) >= MAX_STEP_FAILURES:
		plan["state"] = "failed"

static func replace_target(plan: Dictionary, target: Vector3i) -> void:
	if plan.is_empty():
		return
	plan["target"] = target
	var step: Dictionary = current_step(plan)
	if not step.is_empty():
		step["target"] = target

static func summary(plan: Dictionary) -> String:
	if plan.is_empty():
		return "Sin plan"
	var goal: String = str(plan.get("goal", "Sin meta"))
	var step: Dictionary = current_step(plan)
	var step_name: String = str(step.get("label", step.get("action", "Terminado")))
	return "%s → %s" % [goal, step_name]
