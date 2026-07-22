extends RefCounted
class_name DFAnatomy

class BodyPart:
	var name: String
	var is_vital: bool = false
	var is_severed: bool = false
	var parent_part: BodyPart = null
	var connected_parts: Array = []
	
	# Damage percentages (0.0 to 1.0)
	var skin_damage: float = 0.0
	var fat_damage: float = 0.0
	var muscle_damage: float = 0.0
	var bone_damage: float = 0.0
	var organ_damage: float = 0.0
	
	var has_bone: bool = true
	var has_organ: bool = false
	var can_grasp: bool = false
	var can_stand: bool = false
	
	# Recubrimiento de fluidos en la parte anatómica
	var coatings: Dictionary = {}
	
	func _init(p_name: String, p_vital: bool = false):
		name = p_name
		is_vital = p_vital

	func add_child(part: BodyPart) -> void:
		connected_parts.append(part)
		part.parent_part = self

class Body:
	var parts: Array[BodyPart] = []
	var root: BodyPart
	var blood_level: float = 100.0
	var bleed_rate: float = 0.0
	var is_dead: bool = false
	
	# Ingestión, metabolismo y enfermedades
	var ingested_substances: Dictionary = {}
	var ebriety: float = 0.0
	var disease_type: String = ""
	var nausea: float = 0.0
	var is_vomiting: bool = false
	
	func _init(template: String = "humanoid"):
		if template == "humanoid":
			_build_humanoid()
		elif template == "quadruped":
			_build_quadruped()
		elif template == "insect":
			_build_insect()
		else:
			_build_humanoid()

	func _build_humanoid() -> void:
		root = BodyPart.new("Torso Superior", false)
		root.has_organ = true # Corazon/Pulmones
		parts.append(root)
		
		var head = BodyPart.new("Cabeza", true)
		head.has_organ = true # Cerebro
		root.add_child(head)
		parts.append(head)
		
		var l_arm = BodyPart.new("Brazo Izquierdo", false)
		var l_hand = BodyPart.new("Mano Izquierda", false)
		l_hand.can_grasp = true
		l_hand.has_bone = true
		l_arm.add_child(l_hand)
		root.add_child(l_arm)
		parts.append(l_arm)
		parts.append(l_hand)
		
		var r_arm = BodyPart.new("Brazo Derecho", false)
		var r_hand = BodyPart.new("Mano Derecha", false)
		r_hand.can_grasp = true
		r_hand.has_bone = true
		r_arm.add_child(r_hand)
		root.add_child(r_arm)
		parts.append(r_arm)
		parts.append(r_hand)
		
		var lower_torso = BodyPart.new("Torso Inferior", false)
		lower_torso.has_organ = true
		root.add_child(lower_torso)
		parts.append(lower_torso)
		
		var l_leg = BodyPart.new("Pierna Izquierda", false)
		var l_foot = BodyPart.new("Pie Izquierdo", false)
		l_foot.can_stand = true
		l_leg.add_child(l_foot)
		lower_torso.add_child(l_leg)
		parts.append(l_leg)
		parts.append(l_foot)
		
		var r_leg = BodyPart.new("Pierna Derecha", false)
		var r_foot = BodyPart.new("Pie Derecho", false)
		r_foot.can_stand = true
		r_leg.add_child(r_foot)
		lower_torso.add_child(r_leg)
		parts.append(r_leg)
		parts.append(r_foot)

	func _build_quadruped() -> void:
		root = BodyPart.new("Cuerpo", true)
		parts.append(root)
		var head = BodyPart.new("Cabeza", true)
		root.add_child(head)
		parts.append(head)
		for leg_name in ["Pata Delantera Izq", "Pata Delantera Der", "Pata Trasera Izq", "Pata Trasera Der"]:
			var leg = BodyPart.new(leg_name, false)
			leg.can_stand = true
			root.add_child(leg)
			parts.append(leg)

	func _build_insect() -> void:
		root = BodyPart.new("Torax", true)
		parts.append(root)
		var head = BodyPart.new("Cabeza", true)
		root.add_child(head)
		parts.append(head)
		var abdomen = BodyPart.new("Abdomen", false)
		root.add_child(abdomen)
		parts.append(abdomen)

	func get_random_target() -> BodyPart:
		var available = []
		for p in parts:
			if not p.is_severed:
				available.append(p)
		if available.is_empty():
			return null
		return available[randi() % available.size()]

	func tick_bleeding() -> void:
		if is_dead: return
		if bleed_rate > 0:
			blood_level -= bleed_rate
			if blood_level <= 0:
				is_dead = true

	func check_vital_organs() -> void:
		if is_dead: return
		for p in parts:
			if p.is_vital and (p.is_severed or p.organ_damage >= 1.0):
				is_dead = true
				return
		
		var standing_parts = 0
		for p_153 in parts:
			if p_153.can_stand and not p_153.is_severed:
				standing_parts += 1
		# Fall down logic would go here
