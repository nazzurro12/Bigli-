extends RefCounted
class_name DFEducationSystem

## Sistema de educación y transmisión de conocimiento.
## Los enanos con nivel alto en una skill pueden enseñar a aprendices.
## Las escuelas se designan como edificios especiales donde la enseñanza es más efectiva.

const STUDENT_CAP_PER_TEACHER: int = 3
const TEACH_DISTANCE: int = 2
const TEACH_XP_BASE: int = 4
const SCHOOL_TEACH_BONUS: int = 3
const AUTO_LEARN_XP: int = 1
const SCAN_INTERVAL_TICKS: int = 12
const MAX_SCHOOLS: int = 12

## Edificios registrados como escuelas (posición -> {name, quality})
var schools: Dictionary = {}
## Pares activos teacher_id -> {skill, student_ids, quality_timer}
var active_lessons: Dictionary = {}
var scan_counter: int = 0
var main_ref = null


func _init(p_world, p_main) -> void:
	# p_world se ignora intencionadamente; tick(world) recibe el mundo como parámetro
	main_ref = p_main


## Registra una posición como escuela
func register_school(pos: Vector3i, name: String = "Escuela") -> bool:
	if schools.size() >= MAX_SCHOOLS:
		return false
	var key: String = "%d:%d:%d" % [pos.x, pos.y, pos.z]
	if schools.has(key):
		return false
	schools[key] = {
		"position": [pos.x, pos.y, pos.z],
		"name": name,
		"quality": 1.0,
		"teacher_count": 0,
		"student_count": 0,
	}
	return true


## Elimina una escuela
func unregister_school(pos: Vector3i) -> void:
	var key: String = "%d:%d:%d" % [pos.x, pos.y, pos.z]
	if schools.has(key):
		var school: Dictionary = schools[key]
		# Liberar a los maestros asignados
		for teacher_id: Variant in active_lessons.keys():
			var lesson: Dictionary = active_lessons[teacher_id]
			if lesson.get("school_key", "") == key:
				active_lessons.erase(teacher_id)
		schools.erase(key)


func is_school_at(pos: Vector3i) -> bool:
	var key: String = "%d:%d:%d" % [pos.x, pos.y, pos.z]
	return schools.has(key)


func get_school_at(pos: Vector3i) -> Dictionary:
	var key: String = "%d:%d:%d" % [pos.x, pos.y, pos.z]
	return schools.get(key, {})


## TICK principal: procesa enseñanza y aprendizaje
func tick(world) -> Array[String]:
	if world == null:
		return []
	var messages: Array[String] = []
	scan_counter += 1
	if scan_counter < SCAN_INTERVAL_TICKS:
		return messages
	scan_counter = 0
	
	# 1. Asignar maestros automáticos (enanos con skill >= 5)
	_auto_assign_teachers(world)
	
	# 2. Procesar lecciones activas
	var expired_lessons: Array = []
	for teacher_id: Variant in active_lessons.keys():
		var lesson: Dictionary = active_lessons[teacher_id]
		var teacher = _find_dwarf_by_id(world, int(teacher_id))
		if teacher == null or not teacher.is_alive:
			expired_lessons.append(teacher_id)
			continue
		lesson["quality_timer"] = int(lesson.get("quality_timer", 0)) + 1
		
		var students_alive: Array = []
		for student_id: Variant in lesson.get("student_ids", []):
			var student = _find_dwarf_by_id(world, int(student_id))
			if student != null and student.is_alive:
				students_alive.append(student_id)
				_apply_teaching(teacher, student, lesson, world)
		lesson["student_ids"] = students_alive
		
		if students_alive.is_empty():
			expired_lessons.append(teacher_id)
	
	for expired_id: Variant in expired_lessons:
		active_lessons.erase(expired_id)
	
	# 3. Estimular aprendizaje autónomo en jóvenes
	_tick_autonomous_learning(world)
	
	return messages


func _auto_assign_teachers(world) -> void:
	if world.dwarves.is_empty():
		return
	
	# Recopilar maestros potenciales (skill >= 5) y estudiantes
	var potential_teachers: Dictionary = {}  # dwarf_id -> {skill_id, level}
	var students: Array = []
	
	for dwarf in world.dwarves:
		if not dwarf.is_alive or dwarf.is_possessed:
			continue
		
		var best_skill: int = -1
		var best_level: int = 0
		for skill_key: Variant in dwarf.skills:
			var level: int = int(dwarf.skills[skill_key])
			if level > best_level:
				best_level = level
				best_skill = int(skill_key)
		
		if best_level >= 5 and best_skill >= 0:
			# No reasignar si ya está enseñando y tiene alumnos
			if active_lessons.has(dwarf.id):
				var existing: Dictionary = active_lessons[dwarf.id]
				if int(existing.get("student_ids", []).size()) > 0:
					continue
			potential_teachers[dwarf.id] = {"skill_id": best_skill, "level": best_level}
		
		# Estudiante ideal: skill baja o joven (< 3 en su mejor skill)
		var age_bonus: float = 0.0
		if dwarf.age < 18:
			age_bonus = 1.0
		elif dwarf.age < 30:
			age_bonus = 0.5
		elif dwarf.age > 50:
			age_bonus = -0.3
		if best_level <= 3 or (best_level <= 4 and dwarf.age < 30):
			students.append({"dwarf": dwarf, "need": 1.0 - float(best_level) * 0.2 + age_bonus})
	
	if potential_teachers.is_empty() or students.is_empty():
		return
	
	# Ordenar estudiantes por necesidad (mayor necesidad primero)
	students.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["need"]) > float(b["need"])
	)
	
	# Asignar estudiantes a maestros
	for student_entry: Dictionary in students:
		var student = student_entry["dwarf"]
		if student == null:
			continue
		# Ya tiene maestro asignado
		var already_taught: bool = false
		for lesson_v: Variant in active_lessons.values():
			var lesson_dict: Dictionary = lesson_v if lesson_v is Dictionary else {}
			if int(student.id) in lesson_dict.get("student_ids", []):
				already_taught = true
				break
		if already_taught:
			continue
		
		var student_age_factor: float = 1.0
		if student.age < 18:
			student_age_factor = 2.0
		elif student.age > 50:
			student_age_factor = 0.5
		
		# Encontrar mejor maestro para este estudiante
		var best_teacher_id: int = -1
		var best_match_score: float = 0.0
		for teacher_id: Variant in potential_teachers.keys():
			var t_info: Dictionary = potential_teachers[teacher_id]
			var lesson: Dictionary = active_lessons.get(int(teacher_id), {"student_ids": []})
			var current_students: Array = lesson.get("student_ids", [])
			if current_students.size() >= STUDENT_CAP_PER_TEACHER:
				continue
			
			var teacher = _find_dwarf_by_id(world, int(teacher_id))
			if teacher == null:
				continue
			var distance: int = abs(teacher.tile_pos.x - student.tile_pos.x) + abs(teacher.tile_pos.z - student.tile_pos.z)
			var proximity_score: float = maxf(0.0, 1.0 - float(distance) / 40.0)
			var need_match: float = student_entry["need"]
			var personality_match: float = 0.5
			if teacher.personality.has(DFDwarf.PersonalityTrait.SOCIABILITY):
				personality_match = float(teacher.personality[DFDwarf.PersonalityTrait.SOCIABILITY])
			# Preferir maestros con paciencia
			if teacher.personality.has(DFDwarf.PersonalityTrait.PATIENCE):
				personality_match = maxf(personality_match, float(teacher.personality[DFDwarf.PersonalityTrait.PATIENCE]))
			
			var score: float = need_match * 0.3 + proximity_score * 0.3 + personality_match * 0.2 + student_age_factor * 0.2
			if score > best_match_score:
				best_match_score = score
				best_teacher_id = int(teacher_id)
		
		if best_teacher_id >= 0:
			if not active_lessons.has(best_teacher_id):
				var t_info2: Dictionary = potential_teachers[best_teacher_id]
				var school_pos: Vector3i = _find_nearest_school(world, _find_dwarf_by_id(world, best_teacher_id))
				active_lessons[best_teacher_id] = {
					"skill": t_info2["skill_id"],
					"student_ids": [],
					"quality_timer": 0,
					"school_key": "%d:%d:%d" % [school_pos.x, school_pos.y, school_pos.z] if school_pos.x >= 0 else "",
				}
			var lesson_data: Dictionary = active_lessons[best_teacher_id]
			var current_students_list: Array = lesson_data.get("student_ids", [])
			if current_students_list.size() < STUDENT_CAP_PER_TEACHER:
				current_students_list.append(student.id)
				lesson_data["student_ids"] = current_students_list
				active_lessons[best_teacher_id] = lesson_data
				if main_ref != null and main_ref.has_method("add_message"):
					var t_name: String = _find_dwarf_by_id(world, best_teacher_id).name if _find_dwarf_by_id(world, best_teacher_id) != null else "Alguien"
					main_ref.add_message("%s ahora enseña a %s." % [t_name, student.name])


func _apply_teaching(teacher, student, lesson: Dictionary, world) -> void:
	if teacher == null or student == null:
		return
	var skill_id: int = int(lesson.get("skill", 0))
	var student_level: int = student.get_skill_level(skill_id)
	var teacher_level: int = teacher.get_skill_level(skill_id)
	
	if teacher_level <= student_level:
		return
	
	# La calidad de la enseñanza depende del nivel del maestro y la escuela
	var quality: float = 1.0
	var school_key: String = str(lesson.get("school_key", ""))
	if not school_key.is_empty() and schools.has(school_key):
		quality = float(schools[school_key].get("quality", 1.0))
	
	# Efectos sociales y de movimiento
	var distance: int = abs(teacher.tile_pos.x - student.tile_pos.x) + abs(teacher.tile_pos.z - student.tile_pos.z)
	
	# Solo se gana XP cuando el estudiante está cerca del maestro
	if distance <= TEACH_DISTANCE:
		var xp_gain: int = TEACH_XP_BASE + maxi(0, teacher_level - student_level) + int(quality * 2.0)
		student.add_skill_xp(skill_id, xp_gain)
		# El maestro también aprende enseñando
		teacher.add_skill_xp(DFDwarf.Skill.LEADERSHIP, 1)
		# Alternar entre "aprendiendo" y el nombre de la skill que estudia
		var skill_name: String = DFDwarf.Skill.keys()[skill_id].to_lower().capitalize()
		student.current_task = "Aprendiendo %s de %s" % [skill_name, teacher.name]
		if randi() % 20 == 0:
			teacher.modify_relationship(student.id, 0.01)
			student.modify_relationship(teacher.id, 0.02)
	else:
		# El estudiante se mueve hacia el maestro
		student._move_toward(world, teacher.tile_pos)
		student.current_task = "Yendo a clase con %s" % teacher.name


func _tick_autonomous_learning(world) -> void:
	if world.dwarves.is_empty():
		return
	for dwarf in world.dwarves:
		if not dwarf.is_alive or dwarf.is_possessed:
			continue
		if dwarf.current_job != null or dwarf.operating_workshop != null:
			continue
		if dwarf.is_child and randi() % 2 == 0:
			# Los niños aprenden más rápido
			var child_skill: int = randi() % 7
			dwarf.add_skill_xp(child_skill, AUTO_LEARN_XP * 2)
			if randi() % 10 == 0:
				var skill_name: String = DFDwarf.Skill.keys()[child_skill].to_lower().capitalize()
				dwarf.current_task = "Jugando y aprendiendo %s" % skill_name


func _find_dwarf_by_id(world, dwarf_id: int):
	if world == null:
		return null
	for dwarf in world.dwarves:
		if dwarf.id == dwarf_id:
			return dwarf
	return null


func _find_nearest_school(world, teacher) -> Vector3i:
	if teacher == null or schools.is_empty():
		return Vector3i(-1, -1, -1)
	var best_pos: Vector3i = Vector3i(-1, -1, -1)
	var best_dist: int = 30
	for school_key: Variant in schools.keys():
		var school: Dictionary = schools[school_key]
		var pos_data: Array = school.get("position", [])
		if pos_data.size() >= 3:
			var school_pos: Vector3i = Vector3i(int(pos_data[0]), int(pos_data[1]), int(pos_data[2]))
			var dist: int = abs(teacher.tile_pos.x - school_pos.x) + abs(teacher.tile_pos.z - school_pos.z)
			if dist < best_dist:
				best_dist = dist
				best_pos = school_pos
	return best_pos


## Exporta el estado para persistencia
func export_state() -> Dictionary:
	var schools_data: Dictionary = {}
	for school_key: Variant in schools:
		schools_data[str(school_key)] = schools[school_key].duplicate(true)
	
	var lessons_data: Dictionary = {}
	for teacher_id: Variant in active_lessons:
		lessons_data[str(teacher_id)] = active_lessons[teacher_id].duplicate(true)
	
	return {
		"schools": schools_data,
		"active_lessons": lessons_data,
		"scan_counter": scan_counter,
	}


## Importa el estado desde persistencia
func import_state(data: Dictionary) -> void:
	schools.clear()
	var schools_raw: Variant = data.get("schools", {})
	if schools_raw is Dictionary:
		for key: Variant in schools_raw:
			schools[str(key)] = (schools_raw[key] as Dictionary).duplicate(true)
	
	active_lessons.clear()
	var lessons_raw: Variant = data.get("active_lessons", {})
	if lessons_raw is Dictionary:
		for key2: Variant in lessons_raw:
			active_lessons[int(key2) if str(key2).is_valid_int() else str(key2)] = (lessons_raw[key2] as Dictionary).duplicate(true)
	
	scan_counter = int(data.get("scan_counter", 0))
