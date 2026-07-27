extends RefCounted
class_name DFDwarfPsychology

## Lógica psicológica de un habitante.
## Opera sobre el actor recibido para conservar compatibilidad con DFDwarf
## mientras el modelo monolítico se divide en componentes especializados.

static func update_emotions(actor, emotion: Dictionary, mood_state: Dictionary) -> void:
	var need_penalty: float = 0.0
	for need_value: Variant in actor.needs.values():
		var value: float = float(need_value)
		if value > 0.7:
			need_penalty += value * 0.1

	var total_unhappiness: float = (
		float(actor.stress) * 0.3
		+ need_penalty
		+ (1.0 - float(actor.happiness)) * 0.5
	)
	if total_unhappiness > 0.8:
		actor.current_emotion = emotion.ANGRY
		actor.emotion_intensity = total_unhappiness
		if actor.mood != mood_state.BESERK and randi() % 100 < int(total_unhappiness * 30):
			actor.mood = mood_state.TANTRUM if randi() % 2 == 0 else mood_state.BESERK
			actor.mood_counter = 50 + randi() % 100
	elif total_unhappiness > 0.5:
		actor.current_emotion = emotion.SAD
		actor.emotion_intensity = total_unhappiness
		if randi() % 100 < 5:
			actor.mood = mood_state.MELANCHOLY
			actor.mood_counter = 100 + randi() % 200
	elif total_unhappiness < 0.2 and actor.happiness > 0.7:
		actor.current_emotion = emotion.HAPPY
		actor.emotion_intensity = 1.0 - total_unhappiness
	else:
		actor.current_emotion = emotion.CONTENT
		actor.emotion_intensity = 0.5

	if actor.stress < 0.1 and actor.mood != mood_state.NORMAL:
		actor.mood = mood_state.NORMAL
		actor.mood_counter = 0

static func update_stress(
	actor,
	delta: float,
	personality_trait: Dictionary,
	mood_state: Dictionary
) -> void:
	var stress_change: float = 0.0
	var has_violent_trait: bool = actor.get_trait(personality_trait.VIOLENCE) > 0.6
	var has_anxious_trait: bool = actor.get_trait(personality_trait.FEAR) > 0.6

	for need_key: Variant in actor.needs:
		var need_value: float = float(actor.needs[need_key])
		if need_value > 0.8:
			stress_change += need_value * 0.02
		elif need_value < 0.2:
			stress_change -= 0.005

	if has_violent_trait and actor.kill_count > 0:
		stress_change -= 0.01 * min(actor.kill_count, 10)
	if has_anxious_trait:
		stress_change += 0.01
	if actor.mood == mood_state.STRANGE_MOOD or actor.mood == mood_state.FELL_MOOD:
		stress_change += 0.05

	stress_change -= float(actor.room_quality) * 0.01
	actor.stress = clampf(float(actor.stress) + stress_change * delta, 0.0, 1.0)

static func update_needs(actor, delta: float, need: Dictionary) -> void:
	_increase_need(actor.needs, need.FOOD, 0.0002 * delta * 60.0)
	_increase_need(actor.needs, need.DRINK, 0.0003 * delta * 60.0)
	_increase_need(actor.needs, need.SLEEP, 0.0004 * delta * 60.0)
	_increase_need(actor.needs, need.COMFORT, 0.0001 * delta * 60.0)

	if actor.relationships.size() > 0:
		_increase_need(actor.needs, need.SOCIAL, 0.0001 * delta * 60.0)
	if actor.is_military:
		_increase_need(actor.needs, need.SECURITY, 0.0002 * delta * 60.0)
	if actor.is_noble:
		_increase_need(actor.needs, need.ESTEEM, 0.0003 * delta * 60.0)
	if actor.religious_fervor > 0.6:
		_increase_need(actor.needs, need.RELIGION, 0.0002 * delta * 60.0)

	_increase_need(actor.needs, need.SECURITY, 0.0001 * delta * 60.0)
	_increase_need(actor.needs, need.ORDER, 0.00005 * delta * 60.0)

static func get_most_pressing_need(needs: Dictionary, fallback_need: int) -> int:
	var highest: int = fallback_need
	var highest_value: float = -1.0
	for need_key: Variant in needs:
		var value: float = float(needs[need_key])
		if value > highest_value:
			highest_value = value
			highest = int(need_key)
	return highest

static func _increase_need(needs: Dictionary, need_key: int, amount: float) -> void:
	needs[need_key] = minf(1.0, float(needs.get(need_key, 0.0)) + amount)
