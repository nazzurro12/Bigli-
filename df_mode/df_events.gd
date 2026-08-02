extends RefCounted
class_name DFEvents

const DFCreature = preload("res://df_mode/df_creature.gd")
const DFDwarf = preload("res://df_mode/df_dwarf.gd")

# Tipos de eventos
enum EventType {
	NONE,
	CAVE_IN,         # Derrumbe en mina
	WORKSHOP_FIRE,   # Incendio en taller
	FLASH_FLOOD,     # Inundación por tormenta
	WILD_BEAST,      # Bestia salvaje acecha
	CROP_BLIGHT,     # Plaga en cultivos
	MIGRANT_WAVE,    # Llegan migrantes
	NOBLE_VISIT,     # Noble visita la fortaleza
	MINOR_FLOOD,     # Inundación menor
	BABY_BOOM,       # Nacimiento múltiple
	FUNGUS_OUTBREAK, # Hongos en las cavernas
	STORM,           # Tormenta severa con rayos
	MERCHANT_VISIT,  # Caravana de comerciantes
}

const EVENT_NAMES = {
	EventType.CAVE_IN: "¡DERRUMBE!",
	EventType.WORKSHOP_FIRE: "¡INCENDIO!",
	EventType.FLASH_FLOOD: "¡INUNDACIÓN!",
	EventType.WILD_BEAST: "¡BESTIA SALVAJE!",
	EventType.CROP_BLIGHT: "PLAGA EN CULTIVOS",
	EventType.MIGRANT_WAVE: "¡LLEGAN MIGRANTES!",
	EventType.NOBLE_VISIT: "VISITA DEL NOBLE",
	EventType.MINOR_FLOOD: "Inundación menor",
	EventType.BABY_BOOM: "¡Nacimiento múltiple!",
	EventType.FUNGUS_OUTBREAK: "HONGOS EN CAVERNAS",
	EventType.STORM: "¡TORMENTA SEVERA!",
	EventType.MERCHANT_VISIT: "¡CARAVANA DE COMERCIANTES!",
}

var rng: RandomNumberGenerator
var events_this_day: int = 0
var last_event_tick: int = -1000
var event_cooldown: int = 0

func _init(seed_val: int = -1):
	rng = RandomNumberGenerator.new()
	rng.seed = seed_val if seed_val >= 0 else randi()
	events_this_day = 0
	event_cooldown = 0

func tick(minute_ticked: bool, game_minute: int, game_hour: int, game_day: int, season: String, world) -> String:
	"""Returns a notification message if an event occurred, empty string otherwise."""
	if not minute_ticked:
		return ""
	
	# Reset daily event counter at midnight
	if game_hour == 0 and game_minute == 0:
		events_this_day = 0
	
	# Max 2 events per day to avoid spam
	if events_this_day >= 2:
		return ""
	
	# Cooldown between events (30+ minutes)
	if event_cooldown > 0:
		event_cooldown -= 1
		return ""
	
	# Each check returns true if event fired (only one event per tick)
	if _check_cave_in(world):
		events_this_day += 1
		event_cooldown = 30
		return EVENT_NAMES[EventType.CAVE_IN]
	
	if _check_workshop_fire(world):
		events_this_day += 1
		event_cooldown = 30
		return EVENT_NAMES[EventType.WORKSHOP_FIRE]
	
	if _check_storm(world, season):
		events_this_day += 1
		event_cooldown = 40
		return EVENT_NAMES[EventType.STORM]
	
	if _check_crop_blight(world):
		events_this_day += 1
		event_cooldown = 45
		return EVENT_NAMES[EventType.CROP_BLIGHT]
	
	if _check_flash_flood(world, season):
		events_this_day += 1
		event_cooldown = 30
		return EVENT_NAMES[EventType.FLASH_FLOOD]
	
	if _check_wild_beast(world):
		events_this_day += 1
		event_cooldown = 40
		return EVENT_NAMES[EventType.WILD_BEAST]
	
	if _check_migrant_wave(world, game_day, season):
		events_this_day += 1
		event_cooldown = 60
		return EVENT_NAMES[EventType.MIGRANT_WAVE]
	
	if _check_merchant_visit(world, season):
		events_this_day += 1
		event_cooldown = 60
		return EVENT_NAMES[EventType.MERCHANT_VISIT]
	
	if _check_noble_visit(world, game_day, season):
		events_this_day += 1
		event_cooldown = 60
		return EVENT_NAMES[EventType.NOBLE_VISIT]
	
	return ""

func _check_cave_in(world) -> bool:
	"""Derrumbe en areas minadas sin soporte. Probabilidad baja por minuto."""
	if rng.randf() > 0.002:
		return false
	
	# Buscar tiles excavados que puedan derrumbarse
	var candidates: Array = []
	for tile_key in world.tiles:
		var tile_val = world.tiles[tile_key]
		if tile_val == DFWorld.TileType.CAVE_FLOOR or tile_val == DFWorld.TileType.STAIRS_DOWN or tile_val == DFWorld.TileType.STAIRS_UPDOWN:
			var pos: Vector3i = tile_key if tile_key is Vector3i else Vector3i(tile_key.x, tile_key.y, tile_key.z)
			# Solo en profundidad (y < 2)
			if pos.y < 2:
				candidates.append(pos)
	
	if candidates.is_empty():
		return false
	
	# Elegir un tile al azar y derrumbarlo (convertir a escombros)
	var collapse_pos = candidates[rng.randi() % candidates.size()]
	world.set_tile(collapse_pos, DFWorld.TileType.SOIL)
	world.messages.append("⚠ ¡DERRUMBE! El techo se ha venido abajo en (%d,%d,%d)" % [collapse_pos.x, collapse_pos.y, collapse_pos.z])
	
	# Dano a enanos cercanos
	if world.combat_system != null:
		for dwarf in world.dwarves:
			if dwarf.get("is_alive") == true:
				var d = abs(dwarf.tile_pos.x - collapse_pos.x) + abs(dwarf.tile_pos.z - collapse_pos.z)
				if d <= 1:
					dwarf.take_damage(15.0 + rng.randf() * 15.0, 2, false)
					dwarf.add_thought("¡Quedó atrapado en un derrumbe! El techo cayó sobre él.", -0.2)
	
	return true

func _check_workshop_fire(world) -> bool:
	"""Incendio en talleres que usan fuego (forja, horno, cocina)."""
	if rng.randf() > 0.003:
		return false
	
	# Buscar talleres con riesgo de incendio (forja, horno, cocina)
	var fire_workshops: Array = []
	for ws in world.buildings:
		if ws is DFWorkshop:
			if ws.workshop_type in [DFWorkshop.WorkshopType.FORGE, DFWorkshop.WorkshopType.KILN, DFWorkshop.WorkshopType.SMELTER, DFWorkshop.WorkshopType.KITCHEN]:
				if ws.is_active or ws.dwarf_assigned >= 0:
					fire_workshops.append(ws)
	
	if fire_workshops.is_empty():
		return false
	
	var target_ws = fire_workshops[rng.randi() % fire_workshops.size()]
	
	# Marcar tile como en fuego visualmente
	world.fire_tiles[target_ws.tile_pos] = 5  # Duration
	
	# Dano al operador del taller
	if target_ws.dwarf_assigned >= 0:
		for dwarf in world.dwarves:
			if dwarf.get("id") == target_ws.dwarf_assigned and dwarf.get("is_alive") == true:
				dwarf.take_damage(5.0 + rng.randf() * 10.0, 2, false)
				dwarf.add_thought("¡El taller se incendió mientras trabajaba! Sufrió quemaduras.", -0.15)
				break
	
	# Destruir items cercanos
	var destroyed_count: int = 0
	for item in world.entities:
		if item is DFItem:
			var d = abs(item.tile_pos.x - target_ws.tile_pos.x) + abs(item.tile_pos.z - target_ws.tile_pos.z)
			if d <= 1 and rng.randf() < 0.5:
				world.remove_entity(item)
				destroyed_count += 1
	
	world.messages.append("⚠ ¡INCENDIO en %s! %d materiales destruidos." % [target_ws.name, destroyed_count])
	return true

func _check_crop_blight(world) -> bool:
	"""Plaga que arruina cultivos. Mas probable en verano."""
	if rng.randf() > 0.002:
		return false
	
	var blighted: int = 0
	for tile_key in world.tile_data:
		if world.tile_data[tile_key] is Dictionary:
			var data = world.tile_data[tile_key]
			if data.get("crop_type", "") != "" and data.get("growth", 0) > 0.3:
				data["growth"] = maxf(0.0, data["growth"] - 0.5)
				data["blighted"] = true
				blighted += 1
				if blighted >= 5:
					break
	
	if blighted > 0:
		world.messages.append("⚠ PLAGA: %d cultivos han sido infectados por hongos." % blighted)
		return true
	return false

func _check_flash_flood(world, season: String) -> bool:
	"""Inundación repentina durante tormenta o deshielo."""
	if rng.randf() > 0.001:
		return false
	
	# Solo durante lluvia/tormenta o primavera (deshielo)
	var is_storm = world.current_weather == DFWorld.WeatherType.STORM or world.current_weather == DFWorld.WeatherType.HEAVY_RAIN
	var is_spring = season == "Spring"
	
	if not is_storm and not is_spring:
		return false
	
	# Encontrar zonas bajas cerca del asentamiento
	var low_tiles: Array = []
	for x in range(64, 192):
		for z in range(64, 192):
			var pos = Vector3i(x, 0, z)
			var h = world.get_surface_height(x, z)
			if h <= 1:  # Muy cerca del agua
				low_tiles.append(Vector3i(x, h, z))
	
	if low_tiles.is_empty():
		return false
	
	# Inundar 3-8 tiles
	var flood_count = 3 + rng.randi() % 6
	for _f in range(flood_count):
		if low_tiles.is_empty():
			break
		var idx = rng.randi() % low_tiles.size()
		var flood_pos = low_tiles[idx]
		low_tiles.remove_at(idx)
		world.set_tile(flood_pos, DFWorld.TileType.WATER_SHALLOW)
		world.set_material(flood_pos, DFWorld.MatType.WATER)
	
	world.messages.append("⚠ INUNDACIÓN: El agua ha cubierto %d tiles cerca del asentamiento." % flood_count)
	return true

func _check_wild_beast(world) -> bool:
	"""Una bestia salvaje se acerca a la colonia."""
	if rng.randf() > 0.0015:
		return false
	
	# Crear una criatura hostil cerca del borde del asentamiento
	var center = Vector3i(128, 3, 128)
	var spawn_offset = Vector3i(
		-20 + rng.randi() % 41,
		0,
		-20 + rng.randi() % 41
	)
	var spawn_pos = Vector3i(
		clampi(center.x + spawn_offset.x, 5, 250),
		3,
		clampi(center.z + spawn_offset.z, 5, 250)
	)
	
	var beast_types = [
		{"name": "Oso Salvaje", "char": "O", "color": Color("#884422"), "size": "large", "damage": 8},
		{"name": "Lobo Hambriento", "char": "w", "color": Color("#664444"), "size": "medium", "damage": 5},
		{"name": "Jabalí Gigante", "char": "b", "color": Color("#664422"), "size": "large", "damage": 6},
		{"name": "Serpiente Venenosa", "char": "s", "color": Color("#448844"), "size": "small", "damage": 4},
		{"name": "Pantera Sombría", "char": "p", "color": Color("#222222"), "size": "medium", "damage": 7},
	]
	
	var beast = beast_types[rng.randi() % beast_types.size()]
	
	if world.combat_system != null:
		var creature = DFCreature.new(spawn_pos, beast["name"], beast["char"], beast["color"], beast["size"])
		creature.is_hostile = true
		creature.set_meta("is_wild_beast", true)
		creature.set_meta("damage", beast["damage"])
		world.add_entity(creature)
	
	world.messages.append("⚠ ¡Un %s salvaje se acerca a la colonia desde el %s!" % [beast["name"], "este" if spawn_pos.x > center.x else "oeste"])
	return true

func _check_migrant_wave(world, game_day: int, season: String) -> bool:
	"""Llegan migrantes a la fortaleza. Mas probable en primavera/verano."""
	if season not in ["Spring", "Summer"]:
		return false
	if rng.randf() > 0.003:
		return false
	
	# 1-3 migrantes
	var migrant_count = 1 + rng.randi() % 3
	var center = Vector3i(128, 3, 128)
	
	for _m in range(migrant_count):
		var migrant_name = "Migrante_%d" % (rng.randi() % 1000)
		var spawn_pos = _find_spawn_edge(world, center)
		if spawn_pos.x < 0:
			continue
		var migrant = DFDwarf.new(spawn_pos, migrant_name)
		migrant.add_thought("Acaba de llegar a la fortaleza buscando una nueva vida.", 0.1)
		world.add_entity(migrant)
		var current_migrants = int(world.get_meta("total_migrants", 0))
		world.set_meta("total_migrants", current_migrants + 1)
	
	world.messages.append("✅ ¡Han llegado %d migrantes a la fortaleza! Buscan un hogar y trabajo." % migrant_count)
	return true

func _check_noble_visit(world, game_day: int, season: String) -> bool:
	"""Visita de un noble/examinador. Evento social."""
	if rng.randf() > 0.001:
		return false
	
	# Buscar un enano con liderazgo/nobleza para recibir al visitante
	var host = null
	for dwarf in world.dwarves:
		if dwarf.get("is_noble") == true and dwarf.get("is_alive") == true:
			host = dwarf
			break
	
	var noble_name = "Lord Examinador" if host == null else "Lord " + host.name.split(" ")[0]
	
	# El noble trae noticias del exterior
	var news_items = [
		"La capital ha incrementado los impuestos este año.",
		"Se rumorea que hay una guerra civil en las montañas del norte.",
		"Un nuevo yacimiento de gemas fue descubierto al este.",
		"La cosecha en las planicies vecinas fue excelente este año.",
		"El rey ha convocado a todos los nobles a la corte.",
	]
	var news = news_items[rng.randi() % news_items.size()]
	
	# Efecto social: los enanos se enteran de las noticias
	for dwarf2 in world.dwarves:
		if dwarf2.get("is_alive") == true and rng.randf() < 0.3:
			dwarf2.add_thought("Escuchó las noticias del exterior: '%s'" % news, 0.02)
	
	world.messages.append("👑 %s visita la fortaleza. Trae noticias: \"%s\"" % [noble_name, news])
	return true

func _check_storm(world, season: String) -> bool:
	"""Tormenta severa con rayos, vientos fuertes y daños a estructuras exteriores."""
	# Solo durante tormenta activa o clima húmedo
	if world.current_weather != DFWorld.WeatherType.STORM and world.current_weather != DFWorld.WeatherType.HEAVY_RAIN:
		return false
	if rng.randf() > 0.004:
		return false
	
	var damage_count: int = 0
	var tree_falls: int = 0
	var center_v = Vector3i(128, 3, 128)
	
	# El viento derriba árboles cercanos y daña cultivos
	for x in range(maxi(0, center_v.x - 40), mini(world.width, center_v.x + 41)):
		for z in range(maxi(0, center_v.z - 40), mini(world.depth, center_v.z + 41)):
			if rng.randf() > 0.03:
				continue
			var pos = Vector3i(x, world.get_surface_height(x, z), z)
			var tile = world.get_tile(pos)
			if tile == DFWorld.TileType.TREE:
				world.set_tile(pos, DFWorld.TileType.FLOOR)
				# Dejar un tronco caído como item
				world._spawn_item(pos, "Tronco Caído", "wood", 4, "/", Color("#6B4226"))
				tree_falls += 1
			elif world.tile_data.has(pos) and world.tile_data[pos] is Dictionary:
				var data = world.tile_data[pos]
				if data.get("crop_type", "") != "":
					data["growth"] = maxf(0.0, data["growth"] - 0.3)
					damage_count += 1
	
	# Rayo: impacto aleatorio que puede prender fuego o dañar enanos
	var strike_x = center_v.x + rng.randi_range(-30, 30)
	var strike_z = center_v.z + rng.randi_range(-30, 30)
	var strike_pos = Vector3i(strike_x, world.get_surface_height(strike_x, strike_z), strike_z)
	world.lightning_flash = true
	if rng.randf() < 0.3:
		world.fire_tiles[strike_pos] = 3
	
	# Mensaje vívido
	var msg = "⛈ ¡TORMENTA SEVERA! Vientos huracanados azotan la fortaleza."
	if tree_falls > 0:
		msg += " %d árboles caídos." % tree_falls
	if damage_count > 0:
		msg += " %d cultivos dañados por el granizo." % damage_count
	world.messages.append(msg)
	return true

func _check_merchant_visit(world, season: String) -> bool:
	"""Una caravana de comerciantes llega a la fortaleza con bienes para intercambiar."""
	if rng.randf() > 0.002:
		return false
	# Más probable en primavera/verano
	if season in ["Winter", "Otoño"] and rng.randf() > 0.3:
		return false
	
	# Generar mercadería variada
	var merchant_goods = [
		{"name": "Daggers de Hierro", "count": 3 + rng.randi() % 4, "type": "weapon"},
		{"name": "Hachas de Mano", "count": 2 + rng.randi() % 3, "type": "weapon"},
		{"name": "Escudos de Madera", "count": 2 + rng.randi() % 3, "type": "armor"},
		{"name": "Armaduras de Cuero", "count": 1 + rng.randi() % 3, "type": "armor"},
		{"name": "Telas Finas", "count": 3 + rng.randi() % 5, "type": "cloth"},
		{"name": "Especias Exóticas", "count": 2 + rng.randi() % 4, "type": "food"},
		{"name": "Vino de la Capital", "count": 3 + rng.randi() % 6, "type": "drink"},
		{"name": "Gemas Sin Tallar", "count": 1 + rng.randi() % 3, "type": "gem"},
		{"name": "Piedras Afiladas", "count": 5 + rng.randi() % 10, "type": "stone"},
		{"name": "Ropaje de Seda", "count": 1 + rng.randi() % 2, "type": "cloth"},
		{"name": "Botas de Montar", "count": 2 + rng.randi() % 3, "type": "armor"},
		{"name": "Ballestas Ligeras", "count": 1 + rng.randi() % 2, "type": "weapon"},
	]
	
	# Seleccionar 3-5 items para ofrecer
	var offer_count = 3 + rng.randi() % 3
	var selected: Array = []
	for _o in range(offer_count):
		var idx = rng.randi() % merchant_goods.size()
		selected.append(merchant_goods[idx])
		merchant_goods.remove_at(idx)
		if merchant_goods.is_empty():
			break
	
	# Generar items en el suelo cerca del centro del asentamiento
	var spawned: int = 0
	var center_v = Vector3i(128, 3, 128)
	for good in selected:
		for _i in range(good["count"]):
			var offset_x = -3 + rng.randi() % 7
			var offset_z = -3 + rng.randi() % 7
			var pos = Vector3i(
				clampi(center_v.x + offset_x, 2, world.width - 2),
				center_v.y,
				clampi(center_v.z + offset_z, 2, world.depth - 2)
			)
			var glyph = "∞"
			var color = Color("#FFD700")
			match good["type"]:
				"weapon": glyph = "↑"; color = Color("#CC4444")
				"armor": glyph = "["; color = Color("#4488CC")
				"cloth": glyph = "≈"; color = Color("#AA88DD")
				"food": glyph = "%"; color = Color("#66AA44")
				"drink": glyph = "~"; color = Color("#DDAA33")
				"gem": glyph = "♦"; color = Color("#44DDFF")
				"stone": glyph = "■"; color = Color("#888888")
			world._spawn_item(pos, good["name"], good["type"], 0, glyph, color)
			spawned += 1
	
	var merchant_names = [
		"Mercader Gundar", "Comerciante Brom", "Vendedora Helga",
		"Trader Magnus", "Negociante Urist", "Caravana del Norte"
	]
	var merchant_name = merchant_names[rng.randi() % merchant_names.size()]
	
	world.messages.append("💰 %s ha llegado con una caravana cargada de bienes! %d items disponibles para intercambiar." % [merchant_name, spawned])
	return true

func _find_spawn_edge(world, center: Vector3i) -> Vector3i:
	"""Busca una posicion valida en el borde del asentamiento."""
	for attempt in range(20):
		var angle = rng.randf() * PI * 2.0
		var radius = 8 + rng.randf() * 12.0
		var x = clampi(int(center.x + cos(angle) * radius), 3, world.width - 3)
		var z = clampi(int(center.z + sin(angle) * radius), 3, world.depth - 3)
		var y = world.get_surface_height(x, z)
		var pos = Vector3i(x, y, z)
		if not world.is_blocked(pos) and not world.is_water(pos):
			return pos
	return Vector3i(-1, -1, -1)
