extends RefCounted
class_name DFQuest

var world_ref = null
var main_ref = null

# ---- Quest Data ----
var active_quests: Array = []
var completed_quests: Array = []
var quest_log_open: bool = false
var quest_log_scroll: int = 0
var quest_log_selected: int = 0
var notification_queue: Array = []
var notification_timer: float = 0.0

# ---- Quest Generation State ----
var generation_cooldown: int = 0
var total_quests_generated: int = 0

enum QuestType {
	KILL,
	GATHER,
	EXPLORE,
	BUILD,
	DELIVER
}

enum QuestDifficulty {
	TRIVIAL,
	EASY,
	MEDIUM,
	HARD,
	EPIC
}

enum QuestStatus {
	ACTIVE,
	COMPLETED,
	FAILED
}

const DIFFICULTY_NAMES = {
	QuestDifficulty.TRIVIAL: "Trivial",
	QuestDifficulty.EASY: "Facil",
	QuestDifficulty.MEDIUM: "Media",
	QuestDifficulty.HARD: "Dificil",
	QuestDifficulty.EPIC: "Epica"
}

const DIFFICULTY_COLORS = {
	QuestDifficulty.TRIVIAL: Color("#AAAAAA"),
	QuestDifficulty.EASY: Color("#44CC44"),
	QuestDifficulty.MEDIUM: Color("#CCCC44"),
	QuestDifficulty.HARD: Color("#CC6644"),
	QuestDifficulty.EPIC: Color("#CC44CC")
}

# ---- Reward Tables ----
const KILL_REWARDS = {
	QuestDifficulty.TRIVIAL: {"coin": 5, "food": 1},
	QuestDifficulty.EASY: {"coin": 15, "food": 2, "drink": 1},
	QuestDifficulty.MEDIUM: {"coin": 40, "food": 3, "ore": 2},
	QuestDifficulty.HARD: {"coin": 100, "food": 5, "ore": 5, "stone": 5},
	QuestDifficulty.EPIC: {"coin": 300, "food": 10, "ore": 10, "stone": 10, "drink": 5}
}

const GATHER_REWARDS = {
	QuestDifficulty.TRIVIAL: {"coin": 3, "food": 1},
	QuestDifficulty.EASY: {"coin": 10, "drink": 2},
	QuestDifficulty.MEDIUM: {"coin": 30, "food": 3, "ore": 1},
	QuestDifficulty.HARD: {"coin": 80, "ore": 4, "stone": 3},
	QuestDifficulty.EPIC: {"coin": 200, "ore": 8, "stone": 8, "food": 5}
}

const EXPLORE_REWARDS = {
	QuestDifficulty.TRIVIAL: {"coin": 8, "food": 1},
	QuestDifficulty.EASY: {"coin": 20, "drink": 2},
	QuestDifficulty.MEDIUM: {"coin": 50, "stone": 3, "food": 2},
	QuestDifficulty.HARD: {"coin": 120, "ore": 3, "stone": 5, "coin_bonus": 50},
	QuestDifficulty.EPIC: {"coin": 250, "ore": 6, "stone": 8, "drink": 5}
}

const BUILD_REWARDS = {
	QuestDifficulty.TRIVIAL: {"coin": 5, "food": 1},
	QuestDifficulty.EASY: {"coin": 15, "stone": 2},
	QuestDifficulty.MEDIUM: {"coin": 35, "stone": 5, "ore": 1},
	QuestDifficulty.HARD: {"coin": 90, "stone": 8, "ore": 3, "food": 3},
	QuestDifficulty.EPIC: {"coin": 250, "stone": 12, "ore": 6, "drink": 4}
}

# ---- Quest Templates ----
const KILL_TARGETS = [
	{"name": "Lobos", "creature": "wolf", "count_min": 1, "count_max": 5, "difficulty": "auto"},
	{"name": "Goblins", "creature": "goblin", "count_min": 1, "count_max": 5, "difficulty": "auto"},
	{"name": "Osos", "creature": "bear", "count_min": 1, "count_max": 3, "difficulty": "auto"},
	{"name": "Jabalies", "creature": "boar", "count_min": 2, "count_max": 6, "difficulty": "auto"},
	{"name": "Araanas", "creature": "spider", "count_min": 3, "count_max": 8, "difficulty": "auto"},
	{"name": "Criaturas del bosque", "creature": "forest", "count_min": 2, "count_max": 5, "difficulty": "auto"},
	{"name": "Bandidos", "creature": "bandit", "count_min": 2, "count_max": 5, "difficulty": "auto"},
]

const GATHER_TARGETS = [
	{"name": "Plump Helmets", "item": "Plump Helmet", "count_min": 3, "count_max": 10, "difficulty": "auto"},
	{"name": "Troncos de Madera", "item": "Tronco de Madera", "count_min": 3, "count_max": 8, "difficulty": "auto"},
	{"name": "Piedras", "item": "Piedras", "count_min": 5, "count_max": 15, "difficulty": "auto"},
	{"name": "Mineral de Hierro", "item": "Mena de Hierro", "count_min": 2, "count_max": 6, "difficulty": "auto"},
	{"name": "Dwarven Ale", "item": "Dwarven Ale", "count_min": 3, "count_max": 10, "difficulty": "auto"},
	{"name": "Cerveza", "item": "Cerveza", "count_min": 3, "count_max": 8, "difficulty": "auto"},
]

const EXPLORE_TARGETS = [
	{"name": "el centro del bosque", "biome": "temperate_forest", "dist_min": 20, "dist_max": 60, "difficulty": "auto"},
	{"name": "las montanas", "biome": "mountains", "dist_min": 30, "dist_max": 80, "difficulty": "auto"},
	{"name": "el desierto", "biome": "desert", "dist_min": 40, "dist_max": 100, "difficulty": "auto"},
	{"name": "el pantano", "biome": "swamp", "dist_min": 30, "dist_max": 70, "difficulty": "auto"},
	{"name": "el lago del norte", "biome": "taiga", "dist_min": 40, "dist_max": 90, "difficulty": "auto"},
	{"name": "la sabana", "biome": "savanna", "dist_min": 50, "dist_max": 120, "difficulty": "auto"},
	{"name": "las ruinas antiguas", "biome": "badlands", "dist_min": 30, "dist_max": 80, "difficulty": "auto"},
]

const BUILD_TARGETS = [
	{"name": "Muros de piedra", "count_min": 3, "count_max": 10, "difficulty": "auto"},
	{"name": "Pisos de madera", "count_min": 5, "count_max": 15, "difficulty": "auto"},
	{"name": "Escaleras", "count_min": 1, "count_max": 4, "difficulty": "auto"},
	{"name": "Puentes", "count_min": 1, "count_max": 2, "difficulty": "auto"},
]

# ---- Quest Object ----
class Quest:
	var id: int
	var type: int
	var difficulty: int
	var status: int
	var title: String
	var description: String
	var target_name: String
	var target_count: int
	var current_count: int
	var target_pos: Vector3i
	var rewards: Dictionary
	var created_tick: int
	var time_limit: int
	var giver_name: String
	
	func _init(qid: int, qtype: int, qdiff: int, qtitle: String, qdesc: String,
		tname: String, tcount: int, rewards_dict: Dictionary, qpos: Vector3i,
		qloc_name: String = "", created: int = 0, limit: int = 0):
		id = qid
		type = qtype
		difficulty = qdiff
		status = QuestStatus.ACTIVE
		title = qtitle
		description = qdesc
		target_name = tname
		target_count = tcount
		current_count = 0
		target_pos = qpos
		rewards = rewards_dict.duplicate()
		created_tick = created
		time_limit = limit
		giver_name = qloc_name

# ---- Initialization ----
func _init(world, main_node):
	world_ref = world
	main_ref = main_node

# ---- Main API ----
func open_quest_log() -> void:
	quest_log_open = true
	quest_log_selected = 0
	quest_log_scroll = 0

func close_quest_log() -> void:
	quest_log_open = false

func toggle_quest_log() -> void:
	quest_log_open = not quest_log_open
	if quest_log_open:
		quest_log_selected = 0
		quest_log_scroll = 0

func is_open() -> bool:
	return quest_log_open

func get_formatted_quest(quest: Quest) -> String:
	var type_name = ""
	match quest.type:
		QuestType.KILL: type_name = "Eliminar"
		QuestType.GATHER: type_name = "Recolectar"
		QuestType.EXPLORE: type_name = "Explorar"
		QuestType.BUILD: type_name = "Construir"
		QuestType.DELIVER: type_name = "Entregar"
	var progress = "%d/%d" % [quest.current_count, quest.target_count]
	var diff_name = DIFFICULTY_NAMES.get(quest.difficulty, "?")
	return "%s [%s] %s — %s (%s)" % [diff_name, type_name, quest.title, quest.description, progress]

# ---- Procedural Quest Generation ----
func generate_quest() -> Quest:
	var rng = RandomNumberGenerator.new()
	rng.seed = randi()
	
	# Pick random quest type
	var types = [QuestType.KILL, QuestType.GATHER, QuestType.EXPLORE, QuestType.BUILD]
	var qtype = types[rng.randi() % types.size()]
	
	# Generate world-appropriate quest
	match qtype:
		QuestType.KILL: return _generate_kill_quest(rng)
		QuestType.GATHER: return _generate_gather_quest(rng)
		QuestType.EXPLORE: return _generate_explore_quest(rng)
		QuestType.BUILD: return _generate_build_quest(rng)
	
	return null

func _generate_kill_quest(rng: RandomNumberGenerator) -> Quest:
	var target = KILL_TARGETS[rng.randi() % KILL_TARGETS.size()]
	var count = rng.randi_range(target["count_min"], target["count_max"])
	
	# Determine difficulty from count
	var difficulty = QuestDifficulty.TRIVIAL
	if count >= 5: difficulty = QuestDifficulty.EASY
	if count >= 8: difficulty = QuestDifficulty.MEDIUM
	if count >= 12: difficulty = QuestDifficulty.HARD
	if count >= 20: difficulty = QuestDifficulty.EPIC
	
	if target["difficulty"] == "auto":
		pass # already calculated
	
	var title = "Cazar %s" % target["name"]
	var desc = "Elimina %d %s en la naturaleza salvaje." % [count, target["name"].to_lower()]
	var rewards = KILL_REWARDS.get(difficulty, KILL_REWARDS[QuestDifficulty.TRIVIAL])
	var pos = Vector3i(64, 3, 64)
	if world_ref != null:
		pos.x = rng.randi_range(20, world_ref.width - 20)
		pos.z = rng.randi_range(20, world_ref.depth - 20)
	
	total_quests_generated += 1
	return Quest.new(total_quests_generated, QuestType.KILL, difficulty, title, desc,
		target["creature"], count, rewards, pos, "", _get_game_tick(), _get_time_limit(difficulty))

func _generate_gather_quest(rng: RandomNumberGenerator) -> Quest:
	var target = GATHER_TARGETS[rng.randi() % GATHER_TARGETS.size()]
	var count = rng.randi_range(target["count_min"], target["count_max"])
	
	var difficulty = QuestDifficulty.TRIVIAL
	if count >= 6: difficulty = QuestDifficulty.EASY
	if count >= 10: difficulty = QuestDifficulty.MEDIUM
	if count >= 15: difficulty = QuestDifficulty.HARD
	if count >= 25: difficulty = QuestDifficulty.EPIC
	
	var title = "Recolectar %s" % target["name"]
	var desc = "Reune %d unidades de %s para los almacenes." % [count, target["name"].to_lower()]
	var rewards = GATHER_REWARDS.get(difficulty, GATHER_REWARDS[QuestDifficulty.TRIVIAL])
	
	total_quests_generated += 1
	return Quest.new(total_quests_generated, QuestType.GATHER, difficulty, title, desc,
		target["item"], count, rewards, Vector3i.ZERO, "", _get_game_tick(), _get_time_limit(difficulty))

func _generate_explore_quest(rng: RandomNumberGenerator) -> Quest:
	var target = EXPLORE_TARGETS[rng.randi() % EXPLORE_TARGETS.size()]
	var dist = rng.randi_range(target["dist_min"], target["dist_max"])
	
	var difficulty = QuestDifficulty.EASY
	if dist >= 50: difficulty = QuestDifficulty.MEDIUM
	if dist >= 80: difficulty = QuestDifficulty.HARD
	if dist >= 120: difficulty = QuestDifficulty.EPIC
	
	var title = "Explorar %s" % target["name"]
	var desc = "Viaja hacia %s, a %d pasos de distancia." % [target["name"], dist]
	
	# Create target position in that biome direction
	var pos = Vector3i(64, 3, 64)
	if world_ref != null and main_ref != null and main_ref.world_gen != null:
		var wg = main_ref.world_gen
		var attempts = 0
		while attempts < 50:
			var angle = rng.randf() * PI * 2
			var dx = int(cos(angle) * dist)
			var dz = int(sin(angle) * dist)
			var tx = clampi(64 + dx, 10, world_ref.width - 10)
			var tz = clampi(64 + dz, 10, world_ref.depth - 10)
			var gx = int(float(tx) / float(world_ref.width) * wg.world_width)
			var gz = int(float(tz) / float(world_ref.depth) * wg.world_depth)
			if gx >= 0 and gx < wg.world_width and gz >= 0 and gz < wg.world_depth:
				if wg.biome_map[gz][gx] == target["biome"]:
					pos = Vector3i(tx, 3, tz)
					break
			attempts += 1
	
	var rewards = EXPLORE_REWARDS.get(difficulty, EXPLORE_REWARDS[QuestDifficulty.EASY])
	
	total_quests_generated += 1
	return Quest.new(total_quests_generated, QuestType.EXPLORE, difficulty, title, desc,
		target["biome"], 1, rewards, pos, target["name"], _get_game_tick(), _get_time_limit(difficulty))

func _generate_build_quest(rng: RandomNumberGenerator) -> Quest:
	var target = BUILD_TARGETS[rng.randi() % BUILD_TARGETS.size()]
	var count = rng.randi_range(target["count_min"], target["count_max"])
	
	var difficulty = QuestDifficulty.TRIVIAL
	if count >= 5: difficulty = QuestDifficulty.EASY
	if count >= 8: difficulty = QuestDifficulty.MEDIUM
	if count >= 12: difficulty = QuestDifficulty.HARD
	
	var title = "Construir %s" % target["name"]
	var desc = "Construye %d %s en la fortaleza." % [count, target["name"].to_lower()]
	var rewards = BUILD_REWARDS.get(difficulty, BUILD_REWARDS[QuestDifficulty.TRIVIAL])
	
	total_quests_generated += 1
	return Quest.new(total_quests_generated, QuestType.BUILD, difficulty, title, desc,
		target["name"], count, rewards, Vector3i.ZERO, "", _get_game_tick(), _get_time_limit(difficulty))

func _get_time_limit(difficulty: int) -> int:
	match difficulty:
		QuestDifficulty.TRIVIAL: return 1000  # ~10 min de juego
		QuestDifficulty.EASY: return 2000
		QuestDifficulty.MEDIUM: return 4000
		QuestDifficulty.HARD: return 7000
		QuestDifficulty.EPIC: return 12000
	return 2000

func _get_game_tick() -> int:
	if main_ref != null:
		return main_ref._game_minute + main_ref._game_hour * 60 + main_ref._game_day * 1440
	return 0

# ---- Quest Generation Tick ----
func tick(minute_ticked: bool) -> void:
	if not minute_ticked:
		return
	if world_ref == null or main_ref == null:
		return
	
	generation_cooldown -= 1
	if generation_cooldown <= 0 and active_quests.size() < 5:
		var quest = generate_quest()
		if quest != null:
			active_quests.append(quest)
			_add_notification("Nueva mision: %s" % quest.title)
			generation_cooldown = 500 + randi() % 500  # 5-10 min de juego
	
	# Check time limits
	var to_fail = []
	for q in active_quests:
		if q.time_limit > 0:
			var elapsed = _get_game_tick() - q.created_tick
			if elapsed > q.time_limit:
				q.status = QuestStatus.FAILED
				to_fail.append(q)
				_add_notification("Mision fallida: %s (tiempo agotado)" % q.title)
	for q_352 in to_fail:
		active_quests.erase(q_352)
		completed_quests.append(q_352)
		if completed_quests.size() > 100:
			completed_quests.pop_front()
	
	# Process notifications (1 per tick = ~0.1s real time)
	if notification_timer > 0:
		notification_timer -= 1
		if notification_timer <= 0 and notification_queue.size() > 0:
			notification_queue.pop_front()

func _add_notification(msg: String) -> void:
	notification_queue.append({"msg": msg, "timer": 50})
	notification_timer = 50
	main_ref.add_message("[MISION] %s" % msg)

# ---- Quest Progress Tracking ----
func report_kill(creature_type: String) -> void:
	var to_complete = []
	for q in active_quests:
		if q.type == QuestType.KILL and creature_type.contains(q.target_name):
			q.current_count += 1
			if q.current_count >= q.target_count:
				q.status = QuestStatus.COMPLETED
				to_complete.append(q)
				_complete_quest(q)
	for q_379 in to_complete:
		active_quests.erase(q_379)

func report_gather(item_name: String, count: int = 1) -> void:
	var to_complete = []
	for q in active_quests:
		if q.type == QuestType.GATHER and item_name.contains(q.target_name):
			q.current_count += count
			if q.current_count >= q.target_count:
				q.status = QuestStatus.COMPLETED
				to_complete.append(q)
				_complete_quest(q)
	for q_391 in to_complete:
		active_quests.erase(q_391)

func report_explore(pos: Vector3i) -> void:
	var to_complete = []
	for q in active_quests:
		if q.type == QuestType.EXPLORE:
			var dist = abs(q.target_pos.x - pos.x) + abs(q.target_pos.z - pos.z)
			if dist <= 5:
				q.current_count = q.target_count
				q.status = QuestStatus.COMPLETED
				to_complete.append(q)
				_complete_quest(q)
	for q_404 in to_complete:
		active_quests.erase(q_404)

func report_build() -> void:
	var to_complete = []
	for q in active_quests:
		if q.type == QuestType.BUILD:
			q.current_count += 1
			if q.current_count >= q.target_count:
				q.status = QuestStatus.COMPLETED
				to_complete.append(q)
				_complete_quest(q)
	for q_416 in to_complete:
		active_quests.erase(q_416)

func _complete_quest(quest: Quest) -> void:
	completed_quests.append(quest)
	if completed_quests.size() > 100:
		completed_quests.pop_front()
	
	# Spawn rewards
	if world_ref != null:
		var spawn_pos = Vector3i(64, 3, 64)
		if main_ref != null:
			spawn_pos = main_ref.camera_pos
		
		var reward_msg = ""
		for reward_type in quest.rewards.keys():
			var count = quest.rewards[reward_type]
			var item_data = _get_reward_item_data(reward_type)
			if item_data != null:
				for i in range(count):
					world_ref._spawn_item(spawn_pos, item_data[2], item_data[1], 0, item_data[0], item_data[3])
				var bonus_str = "+%d %s" % [count, item_data[2]]
				if reward_msg != "":
					reward_msg += ", "
				reward_msg += bonus_str
		
		var msg = "Mision completada: %s! Recompensa: %s" % [quest.title, reward_msg]
		_add_notification(msg)

func _get_reward_item_data(reward_type: String) -> Array:
	match reward_type:
		"coin": return ["$", "coin", "Monedas", Color("#FFD700")]
		"food": return ["%", "food", "Provisiones", Color("#FF8844")]
		"drink": return ["~", "drink", "Agua Fresca", Color("#FFCC00")]
		"stone": return ["*", "stone", "Piedras", Color("#808080")]
		"ore": return ["*", "ore", "Mineral", Color("#CC6633")]
		"coin_bonus": return ["$", "coin", "Monedas Extra", Color("#FFD700")]
	return []

# ---- Quest Log Navigation ----
func scroll_up() -> void:
	if quest_log_selected > 0:
		quest_log_selected -= 1
		if quest_log_selected < quest_log_scroll:
			quest_log_scroll = quest_log_selected

func scroll_down() -> void:
	var max_idx = active_quests.size() + completed_quests.size() - 1
	if quest_log_selected < max_idx:
		quest_log_selected += 1
		var visible = 15
		if quest_log_selected >= quest_log_scroll + visible:
			quest_log_scroll = quest_log_selected - visible + 1

func get_current_notification() -> String:
	if notification_queue.size() > 0:
		return notification_queue[0]["msg"]
	return ""

func get_active_count() -> int:
	return active_quests.size()

func get_completed_count() -> int:
	return completed_quests.size()
