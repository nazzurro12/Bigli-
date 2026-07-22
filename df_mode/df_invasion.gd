extends RefCounted
class_name DFInvasion

# ===========================================================================================
# SISTEMA DE INVASIONES - Estilo Dwarf Fortress
# Soporta: Incursiones simultáneas, Asedios prolongados, Bestias Olvidadas, No-Muertos,
# Facciones con moral y jefes de guerra, Maquinaria de guerra goblin.
# ===========================================================================================

enum InvasionType {
	GOBLIN_RAID,       # Incursión goblin - común, débil
	GOBLIN_SIEGE,      # Asedio goblin - raro, con máquinas de guerra
	WILD_BEAST,        # Bestia salvaje - ocasional, media
	UNDEAD_HORDE,      # Horda de no-muertos - raro, fuerte
	FORGOTTEN_BEAST,   # Bestia olvidada - muy raro, extremo
	KOBOLD_SWARM,      # Enjambre kobold - común, muy débil, ladrones
	HUMAN_BANDITS,     # Bandidos humanos - ocasional, medio
	NECROMANCER_ARMY,  # Ejército nigromante - muy raro, resurrector
	ELVEN_PARTY,       # Expedición élfica - diplomática/hostil
	DEMON_INVADER,     # Demonio del inframundo
}

const INVASION_NAMES = {
	InvasionType.GOBLIN_RAID:      "¡Incursión Goblin!",
	InvasionType.GOBLIN_SIEGE:     "¡¡ASEDIO GOBLIN!! ¡Hay catapultas!",
	InvasionType.WILD_BEAST:       "¡Bestia Salvaje!",
	InvasionType.UNDEAD_HORDE:     "¡Horda de No-Muertos!",
	InvasionType.FORGOTTEN_BEAST:  "¡¡BESTIA OLVIDADA!!",
	InvasionType.KOBOLD_SWARM:     "¡Enjambre de Kobolds! ¡Ladrones!",
	InvasionType.HUMAN_BANDITS:    "¡Bandidos Humanos!",
	InvasionType.NECROMANCER_ARMY: "¡¡EJÉRCITO NIGROMANTE!!",
	InvasionType.ELVEN_PARTY:      "¡Delegación Élfica! (¿Hostil?)",
	InvasionType.DEMON_INVADER:    "¡¡¡UN DEMONIO DEL INFRAMUNDO!!!",
}

const INVASION_FLAVOR = {
	InvasionType.GOBLIN_RAID:      ["Los goblins atacan desde las sombras.", "¡Una banda de goblins armados emerge del bosque!"],
	InvasionType.GOBLIN_SIEGE:     ["Los ingenieros goblins montan una catapulta al norte.", "El jefe goblin Ugor grita órdenes desde la retaguardia."],
	InvasionType.WILD_BEAST:       ["La bestia huele la sangre y carga furiosa.", "Un rugido ensordecedor sacude los árboles del bosque."],
	InvasionType.UNDEAD_HORDE:     ["Los muertos caminan. Sus ojos brillan con un fuego frío.", "El silencio solo lo rompe el crujir de los huesos."],
	InvasionType.FORGOTTEN_BEAST:  ["La tierra tiembla bajo sus pasos. Una criatura de la era antigua desciende.", "Su aliento corroe el metal. Sus ojos ven en la oscuridad."],
	InvasionType.KOBOLD_SWARM:     ["¡Kobolds! ¡Se están llevando los almacenes!", "Pequeñas figuras furtivas se deslizan entre las sombras."],
	InvasionType.HUMAN_BANDITS:    ["'¡Entregad vuestro oro!' grita el líder bandido.", "Los bandidos blanden hachas y espadas oxidadas."],
	InvasionType.NECROMANCER_ARMY: ["El Nigromante grita conjuros desde una colina lejana.", "Los caídos de batallas pasadas se levantan para luchar de nuevo."],
	InvasionType.ELVEN_PARTY:      ["Los elfos exigen que se pare de talar los árboles.", "Un delegado élfico entrega un ultimátum escrito en corteza."],
	InvasionType.DEMON_INVADER:    ["El suelo se agrieta. Una silueta ardiente emerge del magma.", "Los enanos huyen despavoridos. El Demonio ha llegado."],
}

const PREP_TICKS = 40
const WAVE_INTERVAL = 15

# ===========================================================================================
# CLASE OLEADA INVASORA
# ===========================================================================================
class InvasionWave:
	var invasion_type: int
	var force: int
	var enemy_type: String
	var remaining: int
	var spawned: int = 0
	var prep_ticks: int = PREP_TICKS
	var wave_ticks: int = 0
	var active: bool = false
	var complete: bool = false
	var spawn_interval: int = 3
	var spawn_counter: int = 0
	var has_commander: bool = false
	var commander_name: String = ""
	var morale: float = 1.0  # 0.0 = huyen, 1.0 = combaten
	var kills_by_invaders: int = 0
	var losses: int = 0
	var is_siege: bool = false
	var siege_engines: int = 0  # Catapultas, arietes
	var necromancer_id: int = -1  # Id del nigromante si aplica
	
	func _init(type: int, f: int, enemy: String):
		invasion_type = type
		force = f
		enemy_type = enemy
		remaining = f
		is_siege = (type == InvasionType.GOBLIN_SIEGE)
		if is_siege:
			siege_engines = randi() % 3 + 1

# ===========================================================================================
# VARIABLES PRINCIPALES
# ===========================================================================================
var _rng: RandomNumberGenerator
var _current_invasion: InvasionWave = null
var _invasion_cooldown: int = 0
var _ticks_since_last: int = 0
var _invasions_defeated: int = 0
var _invasions_survived: int = 0
var _season_tick: int = 0
var _last_season: String = "Primavera"
var active_invasions: Array = []  # Múltiples oleadas simultáneas
var pending_invasions: Array = []  # Cola de futuras invasiones
var historical_invasions: Array = []  # Registro histórico

var notification: String = ""
var threat_level: int = 0  # 0=Pacífico, 1=Baja, 2=Media, 3=Alta, 4=Crítica, 5=APOCALIPSIS
var fortress_kills: int = 0  # Enemigos eliminados totales

# ===========================================================================================
# INICIALIZACIÓN
# ===========================================================================================
func _init(seed_val: int = -1):
	_rng = RandomNumberGenerator.new()
	_rng.seed = seed_val if seed_val >= 0 else randi()

# ===========================================================================================
# CHECK Y DISPATCH DE INVASIÓN
# ===========================================================================================
func check_invasion(minutes: int, season: String, dwarves_count: int, military_strength: float) -> void:
	_ticks_since_last += 1
	_season_tick += 1
	
	# No invadir si hay una invasión activa demasiado grande
	var active_count = active_invasions.size()
	if active_count >= 2:
		return
	
	# Cooldown mínimo (escalado a dificultad)
	var min_cooldown = 600 - (_invasions_defeated * 30) - (dwarves_count * 4)
	min_cooldown = clampi(min_cooldown, 80, 600)
	
	if _ticks_since_last < min_cooldown:
		return
	
	# Probabilidad estacional
	var base_chance = 0.0015
	match season:
		"Primavera": base_chance = 0.001
		"Verano":    base_chance = 0.002
		"Otoño":     base_chance = 0.003
		"Invierno":  base_chance = 0.005  # El invierno trae monstruos

	# Escalado por fama/riqueza (más enanos = más conocidos = más peligrosos)
	if dwarves_count > 15: base_chance *= 1.5
	if dwarves_count > 30: base_chance *= 2.0
	if fortress_kills > 20: base_chance *= 1.3  # La fortaleza tiene fama de guerrera

	if _rng.randf() < base_chance:
		_start_invasion(dwarves_count, military_strength)

func _start_invasion(dwarves_count: int, military_strength: float) -> void:
	var roll = _rng.randf()
	var inv_type: int
	
	# Escalar por derrotas previas y población
	if dwarves_count < 8:
		if roll < 0.45: inv_type = InvasionType.KOBOLD_SWARM
		elif roll < 0.75: inv_type = InvasionType.GOBLIN_RAID
		else: inv_type = InvasionType.WILD_BEAST
	elif dwarves_count < 20:
		if roll < 0.25: inv_type = InvasionType.GOBLIN_RAID
		elif roll < 0.45: inv_type = InvasionType.WILD_BEAST
		elif roll < 0.60: inv_type = InvasionType.HUMAN_BANDITS
		elif roll < 0.75: inv_type = InvasionType.KOBOLD_SWARM
		elif roll < 0.88: inv_type = InvasionType.UNDEAD_HORDE
		elif roll < 0.95: inv_type = InvasionType.ELVEN_PARTY
		else: inv_type = InvasionType.NECROMANCER_ARMY
	else:
		# Fortaleza madura - peligros máximos
		if roll < 0.15: inv_type = InvasionType.GOBLIN_RAID
		elif roll < 0.30: inv_type = InvasionType.GOBLIN_SIEGE
		elif roll < 0.45: inv_type = InvasionType.WILD_BEAST
		elif roll < 0.60: inv_type = InvasionType.UNDEAD_HORDE
		elif roll < 0.72: inv_type = InvasionType.HUMAN_BANDITS
		elif roll < 0.82: inv_type = InvasionType.NECROMANCER_ARMY
		elif roll < 0.90: inv_type = InvasionType.KOBOLD_SWARM
		elif roll < 0.97: inv_type = InvasionType.FORGOTTEN_BEAST
		else: inv_type = InvasionType.DEMON_INVADER
	
	var force = _calculate_force(inv_type, dwarves_count, military_strength)
	var enemy = _get_enemy_type(inv_type)
	
	var new_wave = InvasionWave.new(inv_type, force, enemy)
	new_wave.active = true
	new_wave.prep_ticks = PREP_TICKS
	
	# Comandante para invasiones grandes
	if force >= 4:
		new_wave.has_commander = true
		new_wave.commander_name = _generate_commander_name(inv_type)
	
	active_invasions.append(new_wave)
	_current_invasion = new_wave
	
	var flavor_arr = INVASION_FLAVOR.get(inv_type, [])
	var flavor = ""
	if not flavor_arr.is_empty():
		flavor = flavor_arr[_rng.randi() % flavor_arr.size()]
	
	notification = "¡PELIGRO! %s\n%s" % [INVASION_NAMES.get(inv_type, "Invasión"), flavor]
	_ticks_since_last = 0
	
	historical_invasions.append({
		"type": inv_type,
		"force": force,
		"enemy": enemy,
		"result": "en_curso"
	})
	
	_update_threat_level()

func _calculate_force(inv_type: int, dwarves: int, mil_strength: float) -> int:
	var base_force = 0
	match inv_type:
		InvasionType.KOBOLD_SWARM:     base_force = 4
		InvasionType.GOBLIN_RAID:      base_force = 4
		InvasionType.GOBLIN_SIEGE:     base_force = 8
		InvasionType.WILD_BEAST:       base_force = 1
		InvasionType.HUMAN_BANDITS:    base_force = 4
		InvasionType.UNDEAD_HORDE:     base_force = 7
		InvasionType.NECROMANCER_ARMY: base_force = 6
		InvasionType.ELVEN_PARTY:      base_force = 2
		InvasionType.FORGOTTEN_BEAST:  base_force = 1
		InvasionType.DEMON_INVADER:    base_force = 1
	
	var pop_factor = 0.5 + float(dwarves) * 0.04
	base_force = max(1, int(base_force * pop_factor))
	
	if mil_strength < 10:  base_force = max(1, base_force - 1)
	elif mil_strength > 30: base_force += 2
	elif mil_strength > 50: base_force += 4
	
	# Escalar por historial de derrotas
	base_force += int(_invasions_defeated * 0.3)
	
	return base_force

func _get_enemy_type(inv_type: int) -> String:
	match inv_type:
		InvasionType.GOBLIN_RAID:      return "Goblin"
		InvasionType.GOBLIN_SIEGE:     return "Goblin Guerrero"
		InvasionType.WILD_BEAST:
			var beasts = ["Tejón Gigante", "Oso Pardo", "Lince Gigante", "Jaguar Gigante", "Serpiente Masiva", "Lobo Alfa"]
			return beasts[_rng.randi() % beasts.size()]
		InvasionType.UNDEAD_HORDE:     return "Zombie"
		InvasionType.FORGOTTEN_BEAST:
			var prefix = ["Enorme", "Ancestral", "Mutante", "Iridiscente"]
			var body = ["Serpiente", "Sapo", "Araña", "Cangrejo", "Escorpión", "Babosa"]
			return "%s %s del Subsuelo" % [prefix[_rng.randi() % prefix.size()], body[_rng.randi() % body.size()]]
		InvasionType.KOBOLD_SWARM:     return "Kobold"
		InvasionType.HUMAN_BANDITS:    return "Bandido"
		InvasionType.NECROMANCER_ARMY: return "Esqueleto"
		InvasionType.ELVEN_PARTY:      return "Elfo"
		InvasionType.DEMON_INVADER:
			var demons = ["Balrog", "Demonio de Fuego", "Señor Oscuro", "Ángel Caído", "Dios Maligno"]
			return demons[_rng.randi() % demons.size()]
	return "Goblin"

func _generate_commander_name(inv_type: int) -> String:
	var first = ["Ugr", "Mord", "Shriek", "Drot", "Krag", "Narg", "Brul", "Skrag"]
	var suffix = ["ak", "ot", "ax", "ul", "ash", "ek", "org"]
	var name_str = first[_rng.randi() % first.size()] + suffix[_rng.randi() % suffix.size()]
	match inv_type:
		InvasionType.GOBLIN_SIEGE:     return "El Gran Señor de Guerra %s" % name_str
		InvasionType.NECROMANCER_ARMY: return "El Nigromante %s" % name_str
		InvasionType.DEMON_INVADER:    return "El Archidemonio %s" % name_str
		_:                             return "El Jefe %s" % name_str

# ===========================================================================================
# TICK DE INVASIÓN
# ===========================================================================================
func tick(world, entities: Array, dwarves: Array) -> Dictionary:
	var result = {
		"new_enemies": [],
		"notification": "",
		"ended": false,
		"victory": false,
		"siege_damage": 0
	}
	
	result["notification"] = notification
	notification = ""
	
	# Procesar todas las oleadas activas
	var ended_waves = []
	for inv in active_invasions:
		var wave_result = _tick_wave(inv, world, entities, dwarves)
		for e in wave_result.get("new_enemies", []):
			result["new_enemies"].append(e)
		if wave_result.get("ended", false):
			ended_waves.append(inv)
			if wave_result.get("victory", false):
				result["ended"] = true
				result["victory"] = true
				_invasions_defeated += 1
				notification = "¡Invasión derrotada! ¡Los enanos celebran la victoria! Bajas enemigas: %d" % inv.force
		result["siege_damage"] += wave_result.get("siege_damage", 0)
	
	for w in ended_waves:
		active_invasions.erase(w)
	
	if active_invasions.is_empty():
		_current_invasion = null
	
	_update_threat_level()
	return result

func _tick_wave(inv: InvasionWave, world, entities: Array, dwarves: Array) -> Dictionary:
	var result = {"new_enemies": [], "ended": false, "victory": false, "siege_damage": 0}
	
	if not inv.active:
		return result
	
	# Fase de preparación
	if inv.prep_ticks > 0:
		inv.prep_ticks -= 1
		return result
	
	# Chequeo de moral (huida)
	if inv.losses > 0 and inv.force > 0:
		var loss_ratio = float(inv.losses) / float(inv.force)
		if loss_ratio > 0.6 and _rng.randf() < 0.02:
			inv.morale -= 0.1
		if inv.morale < 0.2:
			notification = "¡Los %s están huyendo! ¡La fortaleza ha resistido!" % inv.enemy_type
			result["ended"] = true
			result["victory"] = true
			return result
	
	# Daño de catapultas (asedios)
	if inv.is_siege and inv.siege_engines > 0:
		inv.wave_ticks += 1
		if inv.wave_ticks % 20 == 0:
			var catapult_dmg = inv.siege_engines * _rng.randi_range(2, 6)
			result["siege_damage"] = catapult_dmg
			notification = "¡Las catapultas goblin impactan la fortaleza! Daño estructural: %d" % catapult_dmg
	
	# Spawneo gradual de enemigos
	inv.spawn_counter += 1
	if inv.spawn_counter >= inv.spawn_interval and inv.spawned < inv.force:
		inv.spawn_counter = 0
		inv.spawned += 1
		inv.remaining = inv.force - inv.spawned
		
		var enemy = _create_invader(inv.enemy_type, inv.invasion_type, world, inv)
		if enemy != null:
			result["new_enemies"].append(enemy)
	
	# Verificar si todos spawneados y eliminados
	if inv.spawned >= inv.force:
		var alive = 0
		for e in entities:
			var _einv = e.get("is_invader")
			var _eal = e.get("is_alive")
			if (_einv != null and _einv == true) and (_eal != null and _eal == true):
				alive += 1
		if alive == 0:
			result["ended"] = true
			result["victory"] = true
	
	return result

# ===========================================================================================
# CREACIÓN DE INVASORES
# ===========================================================================================
func _create_invader(enemy_type: String, inv_type: int, world, wave: InvasionWave = null) -> Dictionary:
	var spawn_pos = _find_spawn_edge(world)
	if spawn_pos.x < 0:
		return {}
	
	var size = "medium"
	var hp = 15
	var damage = 5
	var armor = 0
	var color = Color("#FF4444")
	var glyph = "g"
	var speed = 1.0
	var is_commander = false
	var can_reanimate = false  # Nigromantes pueden reanimar caídos
	
	match inv_type:
		InvasionType.GOBLIN_RAID:
			size = "small"; hp = 12; damage = 4; armor = 1; color = Color("#88AA44"); glyph = "g"; speed = 1.0
		InvasionType.GOBLIN_SIEGE:
			size = "medium"; hp = 18; damage = 6; armor = 3; color = Color("#558800"); glyph = "G"; speed = 0.8
		InvasionType.KOBOLD_SWARM:
			size = "tiny"; hp = 6; damage = 2; armor = 0; color = Color("#886622"); glyph = "k"; speed = 1.3
		InvasionType.WILD_BEAST:
			size = "large"; hp = 40; damage = 12; armor = 2; color = Color("#884422"); glyph = "b"; speed = 1.2
		InvasionType.HUMAN_BANDITS:
			size = "medium"; hp = 22; damage = 7; armor = 2; color = Color("#CC8844"); glyph = "B"; speed = 1.0
		InvasionType.UNDEAD_HORDE:
			size = "medium"; hp = 20; damage = 6; armor = 1; color = Color("#444444"); glyph = "Z"; speed = 0.7
		InvasionType.NECROMANCER_ARMY:
			size = "small"; hp = 14; damage = 5; armor = 0; color = Color("#6644AA"); glyph = "S"; speed = 0.8
			can_reanimate = (enemy_type == "Nigromante")
		InvasionType.ELVEN_PARTY:
			size = "medium"; hp = 25; damage = 8; armor = 2; color = Color("#44AA44"); glyph = "e"; speed = 1.1
		InvasionType.FORGOTTEN_BEAST:
			size = "megabeast"; hp = 300; damage = 35; armor = 12; color = Color("#FF00FF"); glyph = "F"; speed = 0.9
		InvasionType.DEMON_INVADER:
			size = "megabeast"; hp = 500; damage = 55; armor = 20; color = Color("#FF2200"); glyph = "D"; speed = 0.8
	
	# Comandante tiene stats mejorados
	if wave != null and wave.has_commander and wave.spawned == 1:
		is_commander = true
		hp = int(hp * 2.5)
		damage = int(damage * 1.5)
		armor += 4
		color = color.lightened(0.3)
		glyph = glyph.to_upper()
	
	return {
		"name": (wave.commander_name if (is_commander and wave != null) else enemy_type),
		"tile_pos": spawn_pos,
		"creature_type": enemy_type.to_lower().replace(" ", "_"),
		"size": size,
		"hp": hp,
		"hp_max": hp,
		"damage": damage,
		"armor": armor,
		"display_char": glyph,
		"display_color": color,
		"is_alive": true,
		"is_invader": true,
		"is_hostile": true,
		"is_commander": is_commander,
		"can_reanimate": can_reanimate,
		"invasion_type": inv_type,
		"speed": speed,
		"tick_interval": int(2.0 / speed),
		"_tick_counter": 0,
		"_ai_type": "invader",
		"morale": 1.0
	}

# ===========================================================================================
# PATHFINDING AL SPAWN
# ===========================================================================================
func _find_spawn_edge(world) -> Vector3i:
	if world == null:
		return Vector3i(-1, -1, -1)
	
	var margin = 3
	var edge_tiles = []
	
	# Norte y sur
	for x in range(margin, world.width - margin, 4):
		for z in [margin, world.depth - margin - 1]:
			var h = world.get_surface_height(x, z)
			var pos = Vector3i(x, h, z)
			if not world.is_water(pos) and not world.is_blocked(pos):
				edge_tiles.append(pos)
	
	# Este y oeste
	for z_451 in range(margin, world.depth - margin, 4):
		for x_452 in [margin, world.width - margin - 1]:
			var h_453 = world.get_surface_height(x_452, z_451)
			var pos_454 = Vector3i(x_452, h_453, z_451)
			if not world.is_water(pos_454) and not world.is_blocked(pos_454):
				edge_tiles.append(pos_454)
	
	if edge_tiles.is_empty():
		return Vector3i(-1, -1, -1)
	
	return edge_tiles[_rng.randi() % edge_tiles.size()]

# ===========================================================================================
# NOTIFICACIÓN DE BAJAS (llamado desde df_main cuando muere un invasor)
# ===========================================================================================
func register_invader_kill() -> void:
	fortress_kills += 1
	if _current_invasion != null:
		_current_invasion.losses += 1

# ===========================================================================================
# NIVEL DE AMENAZA
# ===========================================================================================
func _update_threat_level() -> void:
	var total_invaders = 0
	for inv in active_invasions:
		total_invaders += (inv.force - inv.losses)
	
	if total_invaders == 0:         threat_level = 0
	elif total_invaders < 4:        threat_level = 1
	elif total_invaders < 8:        threat_level = 2
	elif total_invaders < 15:       threat_level = 3
	elif total_invaders < 30:       threat_level = 4
	else:                           threat_level = 5

func get_threat_level_name() -> String:
	match threat_level:
		0: return "Pacífico"
		1: return "Alerta Baja"
		2: return "Alerta Media"
		3: return "Peligro"
		4: return "¡PELIGRO CRÍTICO!"
		5: return "¡¡¡APOCALIPSIS!!!"
	return "Pacífico"

func get_threat_color() -> Color:
	match threat_level:
		0: return Color(0.4, 0.8, 0.4)
		1: return Color(0.8, 0.8, 0.2)
		2: return Color(0.9, 0.6, 0.1)
		3: return Color(1.0, 0.4, 0.1)
		4: return Color(1.0, 0.1, 0.1)
		5: return Color(1.0, 0.0, 0.5)
	return Color.WHITE

# ===========================================================================================
# STATUS Y HELPERS
# ===========================================================================================
func is_invasion_active() -> bool:
	return not active_invasions.is_empty()

func get_invasion_status() -> Dictionary:
	if active_invasions.is_empty():
		return {
			"active": false,
			"threat_level": threat_level,
			"threat_name": get_threat_level_name(),
			"threat_color": get_threat_color(),
			"total_defeated": _invasions_defeated,
			"fortress_kills": fortress_kills
		}
	
	var inv = _current_invasion if _current_invasion != null else active_invasions[0]
	return {
		"active": true,
		"type": inv.invasion_type,
		"name": INVASION_NAMES.get(inv.invasion_type, "Invasión"),
		"force": inv.force,
		"spawned": inv.spawned,
		"remaining": inv.force - inv.losses,
		"losses": inv.losses,
		"enemy_type": inv.enemy_type,
		"commander": inv.commander_name if inv.has_commander else "",
		"prep": inv.prep_ticks > 0,
		"prep_remaining": inv.prep_ticks,
		"morale": inv.morale,
		"is_siege": inv.is_siege,
		"siege_engines": inv.siege_engines if inv.is_siege else 0,
		"threat_level": threat_level,
		"threat_name": get_threat_level_name(),
		"threat_color": get_threat_color(),
		"total_defeated": _invasions_defeated,
		"fortress_kills": fortress_kills
	}

func get_invasion_history_summary() -> String:
	if historical_invasions.is_empty():
		return "La fortaleza nunca ha sido atacada."
	var text = "=== Historial de Invasiones ===\n"
	for i in range(historical_invasions.size()):
		var rec = historical_invasions[i]
		var name = INVASION_NAMES.get(rec["type"], "Invasión")
		text += "  %d. %s - %s\n" % [i + 1, name, rec["result"]]
	text += "Total derrotadas: %d | Bajas de la fortaleza: %d" % [_invasions_defeated, fortress_kills]
	return text
