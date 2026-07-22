extends RefCounted
class_name DFMilitary

# Posiciones militares
enum SquadRole {
	RECRUIT,      # Recluta - entrenamiento básico
	SOLDIER,      # Soldado - servicio activo
	VETERAN,      # Veterano - experiencia en combate
	ELITE,        # Élite - la flor de la fortaleza
	CAPTAIN,      # Capitán - líder de escuadra
	GENERAL       # General - líder militar
}

const ROLE_NAMES = {
	SquadRole.RECRUIT: "Recluta",
	SquadRole.SOLDIER: "Soldado",
	SquadRole.VETERAN: "Veterano",
	SquadRole.ELITE: "Élite",
	SquadRole.CAPTAIN: "Capitán",
	SquadRole.GENERAL: "General"
}

const ROLE_SKILL_MIN = {
	SquadRole.RECRUIT: 0,
	SquadRole.SOLDIER: 5,
	SquadRole.VETERAN: 15,
	SquadRole.ELITE: 30,
	SquadRole.CAPTAIN: 20,
	SquadRole.GENERAL: 35
}

# Uniforme por rol
const ROLE_UNIFORM = {
	SquadRole.RECRUIT: {"weapon": "fist", "armor": "shirt"},
	SquadRole.SOLDIER: {"weapon": "spear", "armor": "leather", "shield": "shield_wood"},
	SquadRole.VETERAN: {"weapon": "sword_short", "armor": "mail_shirt", "shield": "shield_metal", "helmet": "helmet"},
	SquadRole.ELITE: {"weapon": "sword_long", "armor": "breastplate", "shield": "shield_metal", "helmet": "helmet"},
	SquadRole.CAPTAIN: {"weapon": "sword_long", "armor": "breastplate", "shield": "shield_metal", "helmet": "helmet"},
	SquadRole.GENERAL: {"weapon": "axe_battle", "armor": "breastplate", "helmet": "helmet"},
}

# ---------- ESCUADRA ----------
class Squad:
	var id: int
	var name: String
	var members: Array = []  # Array de IDs de enanos
	var role: int = SquadRole.SOLDIER
	var formation: Vector3i = Vector3i(-1, -1, -1)  # Posición de reunión
	var is_active: bool = false
	var is_patrolling: bool = false
	var patrol_points: Array = []  # Ruta de patrulla
	var patrol_index: int = 0
	var alert_level: int = 0  # 0=normal, 1=alerta, 2=combate

	func _init(squad_id: int, squad_name: String, squad_role: int):
		id = squad_id
		name = squad_name
		role = squad_role

	func add_member(dwarf_id: int) -> void:
		if not members.has(dwarf_id):
			members.append(dwarf_id)

	func remove_member(dwarf_id: int) -> void:
		members.erase(dwarf_id)

	func get_strength() -> int:
		return members.size()

	func get_average_skill() -> float:
		if members.is_empty():
			return 0.0
		# This is called from the main system, which passes skill data
		return 0.0  # Placeholder - actual calculation happens in the military system

	func set_patrol(points: Array) -> void:
		patrol_points = points
		patrol_index = 0
		is_patrolling = true

	func get_next_patrol_point() -> Vector3i:
		if patrol_points.is_empty():
			return formation
		var pt = patrol_points[patrol_index]
		patrol_index = (patrol_index + 1) % patrol_points.size()
		return pt

# ---------- SISTEMA MILITAR ----------
var squads: Array = []  # Array de Squad
var _next_squad_id: int = 1
var _rng: RandomNumberGenerator
var dwarves_in_military: Dictionary = {}  # dwarf_id -> Squad
var alert_level: int = 0  # 0=paz, 1=alerta, 2=asedio

func _init(seed_val: int = -1):
	_rng = RandomNumberGenerator.new()
	_rng.seed = seed_val if seed_val >= 0 else randi()

# ---------- GESTION DE ESCUADRAS ----------
func create_squad(name: String, role: int = SquadRole.SOLDIER) -> Squad:
	var squad = Squad.new(_next_squad_id, name, role)
	_next_squad_id += 1
	squads.append(squad)
	return squad

func disband_squad(squad_id: int) -> void:
	for i in range(squads.size()):
		if squads[i].id == squad_id:
			# Liberar miembros
			for member_id in squads[i].members:
				dwarves_in_military.erase(member_id)
			squads.remove_at(i)
			return

func assign_dwarf_to_squad(dwarf_id: int, squad_id: int) -> bool:
	# Remover de escuadra anterior si estaba
	if dwarves_in_military.has(dwarf_id):
		var old_squad = dwarves_in_military[dwarf_id]
		old_squad.remove_member(dwarf_id)

	# Encontrar nueva escuadra
	for squad in squads:
		if squad.id == squad_id:
			squad.add_member(dwarf_id)
			dwarves_in_military[dwarf_id] = squad
			return true
	return false

func remove_dwarf_from_military(dwarf_id: int) -> void:
	if dwarves_in_military.has(dwarf_id):
		var squad = dwarves_in_military[dwarf_id]
		squad.remove_member(dwarf_id)
		dwarves_in_military.erase(dwarf_id)

func get_squad_of(dwarf_id: int):
	return dwarves_in_military.get(dwarf_id, null)

func is_in_military(dwarf_id: int) -> bool:
	return dwarves_in_military.has(dwarf_id)

# ---------- ALERTAS ----------
func set_alert(level: int) -> void:
	alert_level = level
	match level:
		0: # Paz
			for squad in squads:
				squad.is_active = false
		1: # Alerta
			for squad_149 in squads:
				squad_149.is_active = true
		2: # Asedio/Combate
			for squad_152 in squads:
				squad_152.is_active = true
				squad_152.alert_level = 2

func get_alert_name() -> String:
	match alert_level:
		0: return "PAZ"
		1: return "ALERTA"
		2: return "ASEDIO"
	return "PAZ"

# ---------- EQUIPAMIENTO ----------
func get_equipment_for(dwarf_id: int) -> Dictionary:
	var squad = get_squad_of(dwarf_id)
	if squad == null:
		return {"weapon": "fist", "armor": "shirt", "shield": "", "helmet": ""}
	
	var uniform = ROLE_UNIFORM.get(squad.role, ROLE_UNIFORM[SquadRole.RECRUIT])
	return {
		"weapon": uniform.get("weapon", "fist"),
		"armor": uniform.get("armor", "shirt"),
		"shield": uniform.get("shield", ""),
		"helmet": uniform.get("helmet", "")
	}

func get_role_name(role: int) -> String:
	return ROLE_NAMES.get(role, "Desconocido")

func get_role_for_skill(skill_level: int) -> int:
	var best_role = SquadRole.RECRUIT
	for role in [SquadRole.GENERAL, SquadRole.CAPTAIN, SquadRole.ELITE, SquadRole.VETERAN, SquadRole.SOLDIER, SquadRole.RECRUIT]:
		if skill_level >= ROLE_SKILL_MIN[role]:
			best_role = role
			break
	return best_role

# ---------- ENTRENAMIENTO ----------
func get_training_progress(dwarf_id: int, current_skill: float) -> float:
	if not is_in_military(dwarf_id):
		return 0.0
	
	# Los reclutas ganan más habilidad en entrenamiento
	var squad = get_squad_of(dwarf_id)
	if squad == null:
		return 0.5
	
	var base_progress = 0.5
	match squad.role:
		SquadRole.RECRUIT: base_progress = 1.5
		SquadRole.SOLDIER: base_progress = 1.0
		SquadRole.VETERAN: base_progress = 0.6
		SquadRole.ELITE: base_progress = 0.3
		SquadRole.CAPTAIN: base_progress = 0.2
		SquadRole.GENERAL: base_progress = 0.1
	
	# Penalización por habilidad alta (más difícil mejorar)
	var skill_penalty = maxf(0.1, 1.0 - current_skill / 50.0)
	return base_progress * skill_penalty

func get_military_summary() -> Dictionary:
	var total = 0
	var by_squad = []
	for squad in squads:
		var info = {
			"name": squad.name,
			"count": squad.members.size(),
			"role": ROLE_NAMES.get(squad.role, "?"),
			"alert": squad.alert_level,
			"active": squad.is_active
		}
		by_squad.append(info)
		total += squad.members.size()
	
	return {
		"total": total,
		"squads": by_squad,
		"alert": get_alert_name(),
		"alert_level": alert_level
	}

func get_squad_by_id(squad_id: int):
	for squad in squads:
		if squad.id == squad_id:
			return squad
	return null
