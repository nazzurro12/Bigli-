extends Control
class_name DFRenderer

const DFItem = preload("res://df_mode/df_item.gd")
const DFWorld = preload("res://df_mode/df_world.gd")
const DFDesignation = preload("res://df_mode/df_designation.gd")
const DFTileset = preload("res://df_mode/df_tileset.gd")
const DFJob = preload("res://df_mode/df_job.gd")
const SUBSTANCE_COLORS: Dictionary = {
	"blood":    Color(0.55, 0.0,  0.0,  1.0),
	"beer":     Color(0.70, 0.55, 0.05, 1.0),
	"vomit":    Color(0.45, 0.50, 0.08, 1.0),
	"pathogen": Color(0.10, 0.60, 0.15, 1.0),
	"poison":   Color(0.45, 0.05, 0.65, 1.0),
}

var world = null
var camera_pos: Vector3i = Vector3i(64, 3, 64)
var view_width: int = 80
var view_height: int = 25
var show_sidebar: bool = true
var sidebar_width: int = 32
var follow_dwarf: int = -1
var paused: bool = false
var designation: DFDesignation = null
var show_help: bool = false
var show_job_overlay: bool = true

var game_hour: int = 6
var game_day: int = 1
var game_season: String = "Spring"
var game_year: int = 1
var paused_ticks: int = 0
var total_ticks: int = 0

var _tileset: DFTileset = null
var _font: Font = null
var _char_size: Vector2 = Vector2(16, 16)
var _sidebar_text: String = ""
var _message_log: Array = []
var _tick_count: int = 0
var _designation_mode_name: String = "View"
var _designation_mode_color: Color = Color.WHITE
var _job_pending: int = 0
var _job_active: int = 0
var _highlighted_tile: Vector3i = Vector3i(-1, -1, -1)
var _world_curse: String = ""
var _world_curse_desc: String = ""
var _biome_at_cursor: String = ""
var _layer_at_cursor: String = ""
var _aquifer_at_cursor: bool = false
var _magma_at_cursor: bool = false
var _invasion_status: Dictionary = {}
var _military_summary: Dictionary = {}
var _combat_log: Array = []
var _legend_text: String = ""
var _legend_page: String = ""
var _legend_mode: int = 0
var _family_tree_data: Dictionary = {}
var _caravan_info: Array = []

# ---- DIALOGUE STATE ----
var _dialogue_active: bool = false
var _dialogue_state: int = 0
var _dialogue_topics: Array = []
var _dialogue_topic_selected: int = 0
var _dialogue_response: String = ""
var _dialogue_greeting: String = ""
var _dialogue_target_name: String = ""

# ---- FAST TRAVEL STATE ----
var _fast_travel_active: bool = false
var _fast_travel_phase: int = 0
var _fast_travel_distance: int = 0
var _fast_travel_progress: float = 0.0
var _fast_travel_current_message: String = ""
var _fast_travel_biome: String = ""
var _fast_travel_dest_x: int = 0
var _fast_travel_dest_z: int = 0

var _quest_log_open: bool = false
var _quest_active_quests: Array = []
var _quest_completed_count: int = 0
var _quest_active_count: int = 0
var _quest_notification: String = ""
var _quest_selected: int = 0

var _weather_name: String = "Despejado"
var _weather_color: Color = Color("#87CEEB")
var _temperature: float = 0.5
var _season_name: String = "Primavera"
var _wind_strength: float = 0.5
var _is_daytime: bool = true

# Biome colors for terrain tinting
const BIOME_COLORS = {
	"grassland": Color(0.25, 0.55, 0.15),
	"temperate_forest": Color(0.15, 0.45, 0.10),
	"taiga": Color(0.10, 0.35, 0.20),
	"tundra": Color(0.65, 0.70, 0.75),
	"desert": Color(0.75, 0.65, 0.30),
	"savanna": Color(0.60, 0.55, 0.20),
	"swamp": Color(0.20, 0.30, 0.15),
	"jungle": Color(0.10, 0.40, 0.05),
	"ocean": Color(0.10, 0.20, 0.40),
	"mountains": Color(0.50, 0.45, 0.40),
	"wasteland": Color(0.40, 0.35, 0.30)
}
var _biome_map_cache: Dictionary = {}
var _last_biome_refresh: int = 0

# ---- CACHÉ DEL MAPA MUNDIAL ----
# Un mundo de 1024² contiene más de un millón de regiones. Dibujarlas como
# rectángulos cada frame bloquearía la interfaz, así que el minimapa global se
# rasteriza una sola vez a una textura compacta y luego se reutiliza.
const WORLD_MINIMAP_CACHE_RESOLUTION: int = 192
var _world_minimap_texture: ImageTexture = null
var _world_minimap_cache_key: String = ""

# El juego puede procesar a más de 60 FPS, pero reconstruir miles de tiles,
# entidades y paneles 120 veces por segundo no aporta información nueva.
const MAP_REDRAW_INTERVAL: float = 1.0 / 60.0
var _map_redraw_accumulator: float = 0.0

func invalidate_world_minimap_cache() -> void:
	_world_minimap_texture = null
	_world_minimap_cache_key = ""

func _world_biome_color(biome: String) -> Color:
	match biome:
		"ocean_deep": return Color("#173b7a")
		"ocean_shallow": return Color("#285da8")
		"lake": return Color("#367fc6")
		"beach": return Color("#d7c47b")
		"glacier": return Color("#e5f5f5")
		"mountain": return Color("#777777")
		"mountain_forest": return Color("#355f43")
		"alpine_meadow": return Color("#7f9c62")
		"tundra": return Color("#aab9b8")
		"taiga": return Color("#2f5e50")
		"desert": return Color("#d7bd68")
		"badlands": return Color("#a96743")
		"savanna": return Color("#a2a544")
		"grassland": return Color("#68a34d")
		"temperate_forest": return Color("#2f7b43")
		"dense_temperate_forest": return Color("#1f6038")
		"tropical_forest": return Color("#25733c")
		"rainforest": return Color("#174f31")
		"swamp": return Color("#4f6a45")
		_: return Color("#73865a")

func _ensure_world_minimap_texture(world_gen: Object) -> Texture2D:
	if world_gen == null or world_gen.biome_map.is_empty():
		return null
	var key: String = "%s:%d:%d:%d:%d" % [
		str(world_gen.world_name),
		int(world_gen.world_width),
		int(world_gen.world_depth),
		world_gen.sites.size(),
		world_gen.road_map.size()
	]
	if _world_minimap_texture != null and _world_minimap_cache_key == key:
		return _world_minimap_texture

	var image := Image.create(
		WORLD_MINIMAP_CACHE_RESOLUTION,
		WORLD_MINIMAP_CACHE_RESOLUTION,
		false,
		Image.FORMAT_RGBA8
	)
	var map_w: int = int(world_gen.world_width)
	var map_h: int = int(world_gen.world_depth)
	for py in range(WORLD_MINIMAP_CACHE_RESOLUTION):
		var wz: int = clampi(int((float(py) + 0.5) / float(WORLD_MINIMAP_CACHE_RESOLUTION) * float(map_h)), 0, map_h - 1)
		for px in range(WORLD_MINIMAP_CACHE_RESOLUTION):
			var wx: int = clampi(int((float(px) + 0.5) / float(WORLD_MINIMAP_CACHE_RESOLUTION) * float(map_w)), 0, map_w - 1)
			var color: Color = _world_biome_color(str(world_gen.biome_map[wz][wx]))
			if world_gen.is_lake(wx, wz):
				color = Color("#3b8fd1")
			elif world_gen.is_river(wx, wz):
				var order: int = world_gen.get_river_order(wx, wz)
				color = Color("#62b7ef").lightened(clampf(float(order - 1) * 0.04, 0.0, 0.16))
			if world_gen.is_road(wx, wz):
				var road_value: int = int(world_gen.road_map[wz][wx])
				color = Color("#d6b56c") if road_value == 1 else Color("#e8ddbb")
			image.set_pixel(px, py, color)
	_world_minimap_texture = ImageTexture.create_from_image(image)
	_world_minimap_cache_key = key
	return _world_minimap_texture

func _world_label(value: String) -> String:
	var labels: Dictionary = {
		"ocean_deep": "Océano profundo",
		"ocean_shallow": "Océano costero",
		"lake": "Lago",
		"beach": "Playa",
		"glacier": "Glaciar",
		"tundra": "Tundra",
		"taiga": "Taiga",
		"mountain": "Montaña",
		"mountain_forest": "Bosque montañoso",
		"alpine_meadow": "Prado alpino",
		"grassland": "Pradera",
		"temperate_forest": "Bosque templado",
		"dense_temperate_forest": "Bosque templado denso",
		"tropical_forest": "Bosque tropical",
		"rainforest": "Selva lluviosa",
		"savanna": "Sabana",
		"desert": "Desierto",
		"badlands": "Tierras áridas",
		"swamp": "Pantano"
	}
	return str(labels.get(value, value.replace("_", " ").capitalize()))

func _nearest_world_civilizations(world_gen: Object, position: Vector2i, limit: int = 3) -> Array:
	var candidates: Array = []
	if world_gen == null:
		return candidates
	for civ_variant in world_gen.civs:
		if not civ_variant is Dictionary:
			continue
		var civ: Dictionary = civ_variant
		if bool(civ.get("is_dead", false)):
			continue
		var capital := Vector2i(int(civ.get("capital_x", 0)), int(civ.get("capital_z", 0)))
		candidates.append({"civ": civ, "distance": position.distance_to(capital)})
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["distance"]) < float(b["distance"]))
	if candidates.size() > limit:
		candidates.resize(limit)
	return candidates

# ---- ENTITY CACHE (spatial hash para performance) ----
var _entity_cache: Dictionary = {}
var _dwarf_animation_tick: int = 0
var _animation_phase: bool = false

# ---- TUTORIAL / ONBOARDING ----
var _tutorial_step: int = 0       # 0-5: which hint is shown; -1: finished
var _tutorial_timer: float = 0.0  # seconds this step has been shown
const TUTORIAL_DURATION: float = 8.0  # seconds per hint
const TUTORIAL_STEPS: Array = [
	{"icon": "👁", "text": "Mantén WASD o usa las FLECHAS para mover la cámara y explorar el mundo."},
	{"icon": "F",  "text": "Presiona F para seguir a un enano. Presiona P para poseer al aldeano seguido."},
	{"icon": "⚔",  "text": "Con un enano poseído, usa WASD para moverlo. ¡Explora cuevas y bosques!"},
	{"icon": "⛏",  "text": "Presiona 1 para designar tiles para EXCAVAR. Tus enanos cavan solos."},
	{"icon": "⏸",  "text": "ESPACIO = Pausar · H = Ayuda completa · ESC = Menú. ¡Construye tu fortaleza!"},
]


var legend_panel: Panel = null
var legend_btn: Button = null


func _ready() -> void:
	_tileset = DFTileset.new()
	_font = ThemeDB.fallback_font
	_char_size = Vector2(16, 16)

	# Creacion de Leyenda interactiva (Lado Izquierdo)
	legend_panel = Panel.new()
	legend_panel.name = "LegendPanel"
	legend_panel.anchor_left = 0.0
	legend_panel.anchor_top = 0.1
	legend_panel.anchor_right = 0.0
	legend_panel.anchor_bottom = 0.9
	legend_panel.offset_right = 250
	legend_panel.visible = false
	add_child(legend_panel)
	
	var legend_lbl = Label.new()
	legend_lbl.text = "LEYENDA\n\n# : Muro (Gris)\n. : Suelo\n= : Agua\nT : Arbol\n\nITEMS & RECURSOS\nb : Cama de madera\nc : Cofre / Almacen\n¤ : Fogata encendida\n* : Cenizas de fogata\n% : Plump Helmet (Comida)\n~ : Alcohol / Bebida\n═ : Tronco de Madera\n■ : Bloque de Piedra\n/ : Pico de Minero\n\\ : Hacha de Leñador\n\nCONTROLES (Dios)\nFlechas: Camara\n1: Minar\n2: Talar\n3: Muro\n4: Suelo\nF: Seguir aldeano\nP: Poseer aldeano seguido\nQ: Salir de posesión\nESC: Cerrar una capa / Opciones"
	legend_lbl.position = Vector2(10, 10)
	legend_panel.add_child(legend_lbl)
	
	legend_btn = Button.new()
	legend_btn.name = "LegendBtn"
	legend_btn.text = "|||"
	legend_btn.anchor_left = 0.0
	legend_btn.anchor_top = 0.5
	legend_btn.anchor_bottom = 0.5
	legend_btn.offset_left = 0
	legend_btn.offset_top = -40
	legend_btn.offset_right = 30
	legend_btn.offset_bottom = 40
	legend_btn.pressed.connect(func(): legend_panel.visible = not legend_panel.visible)
	add_child(legend_btn)

	# Arreglar el boton: darle tamano fijo con anchor correcto
	legend_btn.anchor_left = 0.0
	legend_btn.anchor_top = 0.5
	legend_btn.anchor_right = 0.0
	legend_btn.anchor_bottom = 0.5
	legend_btn.offset_left = 0
	legend_btn.offset_top = -60
	legend_btn.offset_right = 26
	legend_btn.offset_bottom = 60

func _apply_night_lighting(color: Color) -> Color:
	# Sin filtro global de noche. La hora sigue visible en el HUD, pero los
	# colores del mapa permanecen nítidos y con su brillo original.
	return color

func _is_daytime_alt() -> float:
	# Returns 0.0 (midnight) to 1.0 (noon)
	var hour = float(game_hour % 24)
	if hour >= 6 and hour < 18:
		return 1.0 - abs(hour - 12.0) / 12.0 * 0.3
	elif hour >= 18 and hour < 20:
		return 0.4 - (hour - 18.0) * 0.2
	elif hour >= 5 and hour < 6:
		return 0.0 + (hour - 5.0) * 0.4
	else:
		return 0.1

func _draw_tile(pos: Vector2, char_str: String, fg: Color, bg: Color) -> void:
	# Apply night lighting
	fg = _apply_night_lighting(fg)
	bg = _apply_night_lighting(bg)
	
	if bg != Color.BLACK and bg.a > 0.01:
		var bg_rect = Rect2(pos.x, pos.y, _char_size.x, _char_size.y)
		draw_rect(bg_rect, bg, true)

	if char_str != " " and _tileset != null and _tileset.texture != null:
		var region = _tileset.get_tile_region(char_str)
		if region.size.x > 0:
			var mod = Color(fg.r, fg.g, fg.b, 1.0)
			draw_texture_rect_region(_tileset.texture, Rect2(pos, Vector2(16, 16)), region, mod)

func _process(delta: float) -> void:
	# El estado lógico sigue actualizándose cada frame, pero el mapa se redibuja
	# como máximo a 60 Hz. Esto elimina el doble redibujado que hundía los FPS al
	# materializar aldeas con muchas casas, muebles y residentes.
	_map_redraw_accumulator += delta
	if _map_redraw_accumulator >= MAP_REDRAW_INTERVAL:
		_map_redraw_accumulator = fmod(_map_redraw_accumulator, MAP_REDRAW_INTERVAL)
		queue_redraw()
	
	# Sync data del mundo al renderer cada frame
	if world != null:
		# Tiempo desde el nodo principal
		var main_nd = get_parent()
		if main_nd != null:
			if "_game_hour" in main_nd:
				game_hour = main_nd._game_hour
				game_day = main_nd._game_day
				game_year = main_nd._game_year
		
		# Clima desde el mundo
		if world.current_season != null:
			_season_name = DFWorld.SEASON_NAMES.get(world.current_season, "Primavera")
		if world.current_weather != null:
			_weather_name = DFWorld.WEATHER_NAMES.get(world.current_weather, "Despejado")
		_weather_color = world.get_weather_color()
		_temperature = world.ambient_temperature
		_wind_strength = world.wind_strength
		_is_daytime = world.is_daytime
		
		# Animacion: alternar fase cada ~0.5 segundos
		_dwarf_animation_tick += 1
		if _dwarf_animation_tick >= 30:  # ~30 frames a 60fps = 0.5s
			_dwarf_animation_tick = 0
			_animation_phase = not _animation_phase
			
		# Calcular tile bajo el cursor del raton
		var mouse_pos = get_local_mouse_position()
		var cs_x = maxf(_char_size.x, 1.0)
		var cs_y = maxf(_char_size.y, 1.0)
		var viewport_size = get_viewport_rect().size
		var max_chars_x = int(viewport_size.x / cs_x)
		var max_chars_y = int(viewport_size.y / cs_y)
		var vw = max_chars_x - sidebar_width - 2 if max_chars_x > sidebar_width + 10 else 40
		var vh = max_chars_y - 6 if max_chars_y > 8 else 20
		
		var cam_x = camera_pos.x - vw / 2
		var cam_z = camera_pos.z - vh / 2
		var cam_y = camera_pos.y
		var border_x = _draw_border(vw, vh)
		
		var vx_x = int((mouse_pos.x - border_x) / cs_x)
		var vz_z = int(mouse_pos.y / cs_y)
		
		if vx_x >= 0 and vx_x < vw and vz_z >= 0 and vz_z < vh:
			_highlighted_tile = Vector3i(cam_x + vx_x, cam_y, cam_z + vz_z)
		else:
			_highlighted_tile = Vector3i(-1, -1, -1)

func set_world(w) -> void:
	world = w
	camera_pos = Vector3i(w.width / 2, 3, w.depth / 2)

func add_message(msg: String) -> void:
	_message_log.append(msg)
	if _message_log.size() > 200:
		_message_log.pop_front()

func _draw() -> void:
	if _tileset == null:
		return

	var main_node = get_parent()
	if main_node != null and "current_state" in main_node:
		var state = main_node.current_state
		match state:
			0: # GameState.SETTINGS_MENU
				_draw_settings_menu()
				return
			1: # GameState.GENERATING_WORLD
				_draw_generating_screen()
				return
			2: # GameState.MODE_SELECT
				_draw_mode_select_menu()
				return
			3: # GameState.EMBARK_MAP_SELECT
				_draw_embark_map_select()
				return
			4: # GameState.EMBARK_PREPARE
				_draw_embark_prepare()
				return
			6: # GameState.LOADING_PLAYING
				_draw_loading_playing_screen()
				return

	var legends_active = false
	if main_node != null and "legends_mode" in main_node:
		legends_active = main_node.legends_mode

	if world == null and not legends_active:
		return

	# Dynamically compute view size based on window size
	var viewport_size = get_viewport_rect().size
	var max_chars_x = int(viewport_size.x / _char_size.x)
	var max_chars_y = int(viewport_size.y / _char_size.y)
	
	if max_chars_x > sidebar_width + 10:
		view_width = max_chars_x - sidebar_width - 2
	else:
		view_width = 40
		
	if max_chars_y > 8:
		view_height = max_chars_y - 6
	else:
		view_height = 20

	var vw = view_width
	var vh = view_height
	var cam_x = camera_pos.x - vw / 2
	var cam_z = camera_pos.z - vh / 2
	var cam_y = camera_pos.y
	var border_x = _draw_border(vw, vh)

	# Solo se indexan las entidades visibles. Antes se recorría y convertía todo
	# el mundo local en cada redibujado aunque la cámara mostrara una fracción.
	var visible_entities: Array = _rebuild_entity_cache(cam_x, cam_z, vw, vh, cam_y)

	# Cache espacial para talleres, edificios y almacenes (O(1) por tile)
	var _workshop_at_pos: Dictionary = {}
	var _building_at_pos: Dictionary = {}
	var _stockpile_at_pos: Dictionary = {}
	var _artifact_glow_at: Dictionary = {}
	if world != null:
		for e in visible_entities:
			if e is DFItem and e.get("is_artifact") == true:
				_artifact_glow_at[e.tile_pos] = e
				
	# Build entity HP cache
	var _entity_hp_cache: Dictionary = {}
	if world != null:
		for e2 in visible_entities:
			var e_alive = e2.get("is_alive")
			if e_alive != null and e_alive == false: continue
			var health_val = null
			if e2.get("health") != null:
				health_val = e2.health
			elif e2.get("hp") != null:
				health_val = float(e2.hp) / float(e2.hp_max) if e2.hp_max > 0 else 1.0
			if health_val != null:
				_entity_hp_cache[e2.tile_pos] = health_val
				
	if world != null and world.workshops != null:
		for ws_item in world.workshops:
			# Precompute 3x3 area around workshop for background darkening
			for dx2 in [-1, 0, 1]:
				for dz2 in [-1, 0, 1]:
					var area_pos = ws_item.tile_pos + Vector3i(dx2, 0, dz2)
					if not _workshop_at_pos.has(area_pos):
						_workshop_at_pos[area_pos] = ws_item
						
	if world != null and world.buildings != null:
		for bld_item in world.buildings:
			var bpos: Vector3i = bld_item.tile_pos
			if bpos.x < cam_x - 4 or bpos.x > cam_x + vw + 4 or bpos.z < cam_z - 4 or bpos.z > cam_z + vh + 4:
				continue
			# Los buildings pueden ocupar varios tiles
			if bld_item.has_method("get_tiles"):
				for t in bld_item.get_tiles():
					_building_at_pos[t] = bld_item
			else:
				_building_at_pos[bpos] = bld_item

	if world != null and world.stockpiles != null:
		for stockpile_value: Variant in world.stockpiles:
			var stockpile_tiles: Variant = stockpile_value.get("tiles")
			if not (stockpile_tiles is Array):
				continue
			for stockpile_tile_value: Variant in stockpile_tiles:
				if not (stockpile_tile_value is Vector3i):
					continue
				var stockpile_pos: Vector3i = stockpile_tile_value
				if stockpile_pos.x >= cam_x and stockpile_pos.x < cam_x + vw and stockpile_pos.z >= cam_z and stockpile_pos.z < cam_z + vh:
					_stockpile_at_pos[stockpile_pos] = stockpile_value

	if world != null:
		for z in range(vh):
			for x in range(vw):
				var wx = cam_x + x
				var wz = cam_z + z
				var pos = Vector3i(wx, cam_y, wz)
				var ch = " "
				var fg = Color.WHITE
				var bg = Color.BLACK
				var char_pos = Vector2(border_x + x * _char_size.x, z * _char_size.y)

				if wx >= 0 and wx < world.width and wz >= 0 and wz < world.depth:
					var tile_type = world.get_tile(pos)
					var tile_char = world.get_tile_char(pos)
					if tile_char != " ":
						ch = tile_char
						if tile_type == DFWorld.TileType.MAGMA:
							ch = "≈" if (wx + wz + _dwarf_animation_tick / 6) % 3 != 0 else "≡"
							var magma_wave = cos((wx * 0.3) - (wz * 0.4) + (Time.get_ticks_msec() * 0.002)) * 0.5 + 0.5
							fg = Color(1.3, 0.35, 0.0).lerp(Color(1.5, 1.0, 0.0), magma_wave)
							bg = Color(0.25, 0.0, 0.0).lerp(Color(0.4, 0.05, 0.0), magma_wave * 0.5)
							var glow_r = 30.0 + 8.0 * sin(Time.get_ticks_msec() * 0.003 + wx + wz)
							var glow_alpha = 0.15 + 0.1 * magma_wave
							draw_circle(char_pos + _char_size / 2.0, glow_r, Color(1.0, 0.3, 0.0, glow_alpha))
						elif tile_type in [DFWorld.TileType.WATER_DEEP, DFWorld.TileType.WATER_SHALLOW, DFWorld.TileType.BROOK, DFWorld.TileType.MURKY_POOL]:
							var water_chars = ["~", "≈", "~", "≈", ";", "~", "≈", ";"]
							var wi = (wx * 3 + wz * 7 + _dwarf_animation_tick / 6) % water_chars.size()
							ch = water_chars[wi]
							var wave1 = sin((wx * 0.4) + (wz * 0.3) + (Time.get_ticks_msec() * 0.003)) * 0.5 + 0.5
							var wave2 = sin((wx * 0.7) - (wz * 0.5) + (Time.get_ticks_msec() * 0.005)) * 0.5 + 0.5
							var combined = wave1 * 0.7 + wave2 * 0.3
							fg = Color(0.1, 0.2, 0.8).lerp(Color(0.25, 0.7, 1.3), combined)
							bg = Color(0.01, 0.05, 0.15)
							if tile_type == DFWorld.TileType.WATER_SHALLOW:
								if wz > 0 and not world.is_blocked(Vector3i(wx, cam_y, wz - 1)) and world.get_tile_char(Vector3i(wx, cam_y, wz - 1)) not in ["~", "≈", ";", " "]:
									draw_line(Vector2(char_pos.x, char_pos.y), Vector2(char_pos.x + _char_size.x, char_pos.y), Color(0.6, 0.8, 1.0, 0.25), 1.0)
								if wz < world.depth - 1 and not world.is_blocked(Vector3i(wx, cam_y, wz + 1)) and world.get_tile_char(Vector3i(wx, cam_y, wz + 1)) not in ["~", "≈", ";", " "]:
									draw_line(Vector2(char_pos.x, char_pos.y + _char_size.y), Vector2(char_pos.x + _char_size.x, char_pos.y + _char_size.y), Color(0.6, 0.8, 1.0, 0.25), 1.0)
						else:
							fg = world.get_tile_color(pos)
							bg = world.get_tile_bg_color(pos)
					else:
						var found = false
						var scan_start = max(cam_y - 1, 0)
						var scan_end = -1
						for check_y in range(scan_start, scan_end, -1):
							var check_pos = Vector3i(wx, check_y, wz)
							var c = world.get_tile_char(check_pos)
							if c != " ":
								ch = c
								var check_type = world.get_tile(check_pos)
								if check_type == DFWorld.TileType.MAGMA:
									fg = Color(0.7, 0.2, 0.0)
									bg = Color(0.1, 0.0, 0.0)
								elif check_type in [DFWorld.TileType.WATER_DEEP, DFWorld.TileType.WATER_SHALLOW, DFWorld.TileType.BROOK, DFWorld.TileType.MURKY_POOL]:
									fg = Color(0.1, 0.15, 0.5)
									bg = Color(0.0, 0.02, 0.08)
								else:
									fg = world.get_tile_color(check_pos)
									bg = world.get_tile_bg_color(check_pos)
								fg = fg.darkened(0.4)
								bg = bg.darkened(0.4)
								found = true
								break
						if not found:
							ch = " "
							fg = Color(0.15, 0.15, 0.2)
				else:
					ch = " "
					fg = Color(0.15, 0.15, 0.2)
					
				if world != null and world.splatters != null and world.splatters.has(pos):
					var tile_subs: Dictionary = world.splatters[pos]
					var blend_color: Color = Color(0, 0, 0, 0)
					var total_vol: float = 0.0
					for s in tile_subs.keys():
						total_vol += tile_subs[s]
					for sub in tile_subs.keys():
						var sub_color: Color = SUBSTANCE_COLORS.get(sub, Color(0.5, 0.5, 0.5, 1.0))
						var weight: float = tile_subs[sub] / maxf(0.001, total_vol)
						blend_color = blend_color.lerp(sub_color, weight)
					var alpha: float = clampf(total_vol * 6.0, 0.15, 0.85)
					blend_color.a = alpha
					bg = bg.blend(blend_color)


				# Workshop rendering via spatial hash (O(1))
				if world != null and world.workshops != null and _workshop_at_pos.has(pos):
					var w = _workshop_at_pos[pos]
					bg = bg.blend(Color(0.2, 0.2, 0.2, 0.5))
					if pos == w.tile_pos:
						ch = w.get_display_char()
						fg = w.get_display_color()

				# Stockpile zone rendering mediante cache espacial O(1).
				if _stockpile_at_pos.has(pos):
					var visible_stockpile: Variant = _stockpile_at_pos[pos]
					bg = bg.blend(visible_stockpile.display_color)

				# Building rendering via spatial hash (O(1))
				if world != null and world.buildings != null and _building_at_pos.has(pos):
					var b = _building_at_pos[pos]
					ch = b.get_display_char()
					fg = b.get_display_color()
					if not b.is_constructed:
						fg.a = 0.5

				# Artifact glow overlay (pulsating aura beneath artifact items)
				if _artifact_glow_at.has(pos):
					var art_pulse = 0.3 + 0.2 * sin(Time.get_ticks_msec() * 0.004 + pos.x * 1.7 + pos.z * 2.3)
					var art_glow = Color(1.0, 0.75, 0.2, art_pulse)
					bg = bg.blend(art_glow)

				var entity_data = _get_entity_at(wx, cam_y, wz)
				if entity_data[0] != "":
					ch = entity_data[0]
					fg = entity_data[1]

				if show_job_overlay and designation != null:
					var job_overlay = _get_job_overlay_at(wx, cam_y, wz)
					if job_overlay[0] != "":
						if ch == " " or ch == ".":
							ch = job_overlay[0]
							fg = job_overlay[1]
						else:
							bg = job_overlay[1]
							bg.a = 0.4

				if designation != null and designation.is_in_selection(pos):
					var sel_color = designation.get_mode_color()
					bg = sel_color
					bg.a = 0.25

				# Sin viñeta ni oscurecimiento artificial: colores completos en toda la vista.

				char_pos = Vector2(border_x + x * _char_size.x, z * _char_size.y)
				_draw_tile(char_pos, ch, fg, bg)

				# Draw ambient occlusion (3D wall shadows) on floor tiles next to walls
				if wx >= 0 and wx < world.width and wz >= 0 and wz < world.depth and not world.is_blocked(pos):
					var cell_rect = Rect2(char_pos.x, char_pos.y, _char_size.x, _char_size.y)
					if wz > 0 and world.is_blocked(Vector3i(wx, cam_y, wz - 1)):
						draw_line(Vector2(cell_rect.position.x, cell_rect.position.y), Vector2(cell_rect.end.x, cell_rect.position.y), Color(0.0, 0.0, 0.0, 0.55), 1.2)
					if wz < world.depth - 1 and world.is_blocked(Vector3i(wx, cam_y, wz + 1)):
						draw_line(Vector2(cell_rect.position.x, cell_rect.end.y), Vector2(cell_rect.end.x, cell_rect.end.y), Color(0.0, 0.0, 0.0, 0.55), 1.2)
					if wx > 0 and world.is_blocked(Vector3i(wx - 1, cam_y, wz)):
						draw_line(Vector2(cell_rect.position.x, cell_rect.position.y), Vector2(cell_rect.position.x, cell_rect.end.y), Color(0.0, 0.0, 0.0, 0.55), 1.2)
					if wx < world.width - 1 and world.is_blocked(Vector3i(wx + 1, cam_y, wz)):
						draw_line(Vector2(cell_rect.end.x, cell_rect.position.y), Vector2(cell_rect.end.x, cell_rect.end.y), Color(0.0, 0.0, 0.0, 0.55), 1.2)

				# Draw pulsating miasma gas cloud particles on top
				if world != null and world.splatters != null and world.splatters.has(pos):
					var tile_subs_miasma = world.splatters[pos]
					if tile_subs_miasma.has("miasma"):
						var pulse_miasma = 0.15 + 0.3 * sin(Time.get_ticks_msec() * 0.0035 + (wx * 7.0 + wz * 3.0))
						draw_circle(char_pos + _char_size / 2.0, _char_size.x * 0.45, Color(0.55, 0.15, 0.9, pulse_miasma))

				# Entity HP bar (small bar below creatures with health data)
				if _entity_hp_cache.has(pos):
					var ehp = _entity_hp_cache[pos]
					if ehp < 0.95:
						var bar_w = _char_size.x - 2
						var bar_h = 2
						var bar_x = char_pos.x + 1
						var bar_y = char_pos.y + _char_size.y - 3
						draw_rect(Rect2(bar_x, bar_y, bar_w, bar_h), Color(0.0, 0.0, 0.0, 0.7), true)
						draw_rect(Rect2(bar_x, bar_y, bar_w * ehp, bar_h), Color(0.8, 0.15, 0.15).lerp(Color(0.3, 0.85, 0.3), ehp), true)

				# Cursor highlight with animated glow
				if pos == _highlighted_tile:
					var pulse = 0.3 + 0.3 * sin(Time.get_ticks_msec() * 0.006)
					draw_rect(Rect2(char_pos.x - 1, char_pos.y - 1, _char_size.x + 2, _char_size.y + 2), Color(1.0, 1.0, 1.0, pulse), false, 1.5)
					draw_rect(Rect2(char_pos.x - 1, char_pos.y - 1, _char_size.x + 2, 1), Color(0.8, 0.9, 1.0, pulse * 0.5), true)

	if _dialogue_active:
		_draw_dialogue_overlay()
	_draw_quest_notification()
	if _quest_log_open:
		_draw_quest_log_overlay()
	if _fast_travel_active:
		_draw_fast_travel_overlay()
	if show_help:
		_draw_help_overlay()
	elif _legend_text != "":
		_draw_legends_overlay()
	elif show_sidebar and world != null:
		var side_x = border_x + vw * _char_size.x + 8
		_draw_sidebar(side_x)

	# Draw glowing retro terminal outer border around the map + sidebar
	if world != null and not show_help:
		var outline_w = vw * _char_size.x
		if show_sidebar:
			outline_w += sidebar_width * _char_size.x + 8
		var outline_rect = Rect2(border_x - 4, 2, outline_w + 8, vh * _char_size.y + 4)
		
		# Draw top & bottom dashed lines
		var ds_x = outline_rect.position.x
		while ds_x < outline_rect.end.x:
			draw_line(Vector2(ds_x, outline_rect.position.y), Vector2(minf(ds_x + 5, outline_rect.end.x), outline_rect.position.y), Color(0.0, 2.5, 0.0, 0.9), 1.5)
			draw_line(Vector2(ds_x, outline_rect.end.y), Vector2(minf(ds_x + 5, outline_rect.end.x), outline_rect.end.y), Color(0.0, 2.5, 0.0, 0.9), 1.5)
			ds_x += 10
		# Draw left & right dashed lines
		var ds_y = outline_rect.position.y
		while ds_y < outline_rect.end.y:
			draw_line(Vector2(outline_rect.position.x, ds_y), Vector2(outline_rect.position.x, minf(ds_y + 5, outline_rect.end.y)), Color(0.0, 2.5, 0.0, 0.9), 1.5)
			draw_line(Vector2(outline_rect.end.x, ds_y), Vector2(outline_rect.end.x, minf(ds_y + 5, outline_rect.end.y)), Color(0.0, 2.5, 0.0, 0.9), 1.5)
			ds_y += 10

	var msg_y = vh * _char_size.y + 4
	_draw_message_log(msg_y)

	# In-game tutorial overlay (first few minutes, for new players)
	var main_nd = get_parent()
	if main_nd != null and main_nd.get("current_state") == 5: # GameState.PLAYING
		if _tutorial_step >= 0 and _tutorial_step < TUTORIAL_STEPS.size():
			_draw_tutorial_overlay()
		_draw_context_bar()


func _draw_border(vw: int, vh: int) -> int:
	var total_w = vw * _char_size.x
	if show_sidebar and not show_help:
		total_w += sidebar_width * _char_size.x + 8
	total_w += 20
	var start_x = maxf((size.x - total_w) / 2, 4)
	return int(start_x)

func _get_entity_at(wx: int, wy: int, wz: int) -> Array:
	if world == null:
		return ["", Color.WHITE]
	# Usar cache espacial O(1) en vez de iterar todas las entidades
	var pos = Vector3i(wx, wy, wz)
	if _entity_cache.has(pos):
		return _entity_cache[pos]
	return ["", Color.WHITE]

func _rebuild_entity_cache(cam_x: int, cam_z: int, vw: int, vh: int, cam_y: int) -> Array:
	_entity_cache.clear()
	var visible_entities: Array = []
	if world == null:
		return visible_entities
	var min_x: int = cam_x - 2
	var max_x: int = cam_x + vw + 2
	var min_z: int = cam_z - 2
	var max_z: int = cam_z + vh + 2
	for e in world.entities:
		var is_alive: Variant = e.get("is_alive")
		if is_alive != null and is_alive == false:
			continue
		var pos: Vector3i = e.tile_pos
		if pos.x < min_x or pos.x > max_x or pos.z < min_z or pos.z > max_z:
			continue
		if absi(pos.y - cam_y) > 1:
			continue
		visible_entities.append(e)
		if not _entity_cache.has(pos):
			var ch: String = e.get_display_char()
			var col: Color = e.get_display_color()
			# Animación básica solo para lo que realmente aparece en pantalla.
			if e.get("creature_type") == "dwarf":
				if _animation_phase:
					ch = "☻"
					col = col.lightened(0.1)
				else:
					ch = "☺"
			elif e is DFItem:
				if e.is_food:
					ch = "%" if not _animation_phase else "§"
				elif e.is_drink:
					ch = "~" if not _animation_phase else "≈"
				elif e.is_weapon:
					ch = "/" if not _animation_phase else "↑"
				elif e.is_armor:
					ch = "[" if not _animation_phase else "]"
				elif e.is_corpse:
					ch = "%"
				elif e.get("is_artifact") == true:
					ch = "✦" if _animation_phase else "◆"
					var art_pulse: float = 0.6 + 0.4 * sin(Time.get_ticks_msec() * 0.005)
					col = Color(1.0, 0.85, 0.3, 1.0).lerp(Color(1.0, 1.0, 0.6, 1.0), art_pulse)
				elif _animation_phase:
					ch = "•"
					col = col.lightened(0.2)
			_entity_cache[pos] = [ch, col]
	return visible_entities

func _get_job_overlay_at(wx: int, wy: int, wz: int) -> Array:
	if designation == null:
		return ["", Color.WHITE]
	var pos = Vector3i(wx, wy, wz)
	var job = designation.get_job_at(pos)
	if job != null and job.state != DFJob.JobState.COMPLETED:
		match job.state:
			DFJob.JobState.ASSIGNED:
				return [job.get_display_char(), job.get_display_color().darkened(0.3)]
			DFJob.JobState.IN_PROGRESS:
				return [job.get_display_char(), job.get_display_color().lightened(0.3)]
			_:
				return [job.get_display_char(), job.get_display_color()]
	return ["", Color.WHITE]

func _draw_sidebar(side_x: int) -> void:
	if world == null:
		return

	var lh  = int(_char_size.y)
	var x   = side_x
	var mw  = sidebar_width * _char_size.x
	var y   = 2
	var sh = size.y
	draw_rect(Rect2(x + 3, 3, mw, sh), Color(0.0, 0.0, 0.0, 0.2), true)
	draw_rect(Rect2(x, 0, mw, sh), Color(0.01, 0.04, 0.01, 0.92), true)
	
	# Draw glowing dotted vertical separator
	var sep_y = 0.0
	while sep_y < sh:
		draw_rect(Rect2(x - 2, sep_y, 2, 4), Color(0.0, 2.5, 0.0, 0.8), true)
		sep_y += 8

	# ── helper: draw section header with underline ──────────────────────────
	# (GDScript closures can't modify outer y; we handle y inline after each call)

	# ═══════════════════════════════════════════════
	# 1. GAME TITLE
	# ═══════════════════════════════════════════════
	var title_col = Color(0.85, 0.72, 0.20)
	if _designation_mode_name not in ["View","Vista",""]:
		title_col = _designation_mode_color
	draw_string(_font, Vector2(x, y + lh), "▓ BIGLI", HORIZONTAL_ALIGNMENT_LEFT, mw, 14, title_col)
	y += lh
	draw_string(_font, Vector2(x, y + lh), "  World Creation", HORIZONTAL_ALIGNMENT_LEFT, mw, 9, Color(0.50, 0.45, 0.65))
	y += int(lh * 1.5)

	# ═══════════════════════════════════════════════
	# 2. PAUSE STATUS
	# ═══════════════════════════════════════════════
	var pause_col = Color(1.0, 0.85, 0.0) if paused else Color(0.3, 0.9, 0.4)
	var pause_str = "■ PAUSADO" if paused else "▶ ACTIVO"
	draw_rect(Rect2(x, y + 2, mw - 4, lh + 2), Color(0.06, 0.05, 0.12), true)
	draw_string(_font, Vector2(x + 4, y + lh), pause_str, HORIZONTAL_ALIGNMENT_LEFT, mw, 10, pause_col)
	y += int(lh * 1.6)

	# ═══════════════════════════════════════════════
	# 3. TIME / SEASON
	# ═══════════════════════════════════════════════
	var season_col_map = {
		"Primavera": Color(0.4,0.9,0.4), "Verano": Color(1.0,0.9,0.3),
		"Otoño": Color(0.9,0.55,0.2),    "Invierno": Color(0.7,0.85,1.0),
		"Spring": Color(0.4,0.9,0.4),    "Summer": Color(1.0,0.9,0.3),
		"Autumn": Color(0.9,0.55,0.2),   "Winter": Color(0.7,0.85,1.0)
	}
	var day_icon = "☀" if _is_daytime else "☽"
	var s_col = season_col_map.get(_season_name, Color(0.8,0.8,0.8))
	draw_string(_font, Vector2(x, y + lh),
		" %s %02d:%02d  Día %d" % [day_icon, game_hour % 24, _tick_count, game_day],
		HORIZONTAL_ALIGNMENT_LEFT, mw, 10, Color(0.75, 0.90, 0.75))
	y += lh
	draw_string(_font, Vector2(x, y + lh),
		"  %s  Año %d" % [_season_name, game_year],
		HORIZONTAL_ALIGNMENT_LEFT, mw, 9, s_col)
	y += lh
	var schedule_name: String = "Sueño"
	var schedule_end: int = 6
	var schedule_color: Color = Color(0.55, 0.65, 1.0)
	if game_hour >= 6 and game_hour < 14:
		schedule_name = "Trabajo"
		schedule_end = 14
		schedule_color = Color(0.95, 0.75, 0.25)
	elif game_hour >= 14 and game_hour < 22:
		schedule_name = "Ocio"
		schedule_end = 22
		schedule_color = Color(0.35, 0.90, 0.50)
	draw_string(_font, Vector2(x, y + lh),
		"  Turno: %s hasta %02d:00" % [schedule_name, schedule_end],
		HORIZONTAL_ALIGNMENT_LEFT, mw, 8, schedule_color)
	y += int(lh * 1.2)

	# Temperature bar
	var temp_filled = int(clampf(_temperature * 10.0, 0, 10))
	var temp_bar = "█".repeat(temp_filled) + "░".repeat(10 - temp_filled)
	var temp_col: Color
	if _temperature < 0.3:
		temp_col = Color(0.4, 0.6, 1.0)
	elif _temperature > 0.7:
		temp_col = Color(1.0, 0.5, 0.1)
	else:
		temp_col = Color(0.5, 0.8, 0.5)
	draw_string(_font, Vector2(x, y + lh), "  %s" % temp_bar, HORIZONTAL_ALIGNMENT_LEFT, mw, 8, temp_col)
	y += lh
	draw_string(_font, Vector2(x, y + lh),
		"  %s  Viento: %d%%" % [_weather_name, int(_wind_strength * 100)],
		HORIZONTAL_ALIGNMENT_LEFT, mw, 8, _weather_color)
	y += int(lh * 1.4)

	# ═══════════════════════════════════════════════
	# 4. CAMERA / Z-LEVEL
	# ═══════════════════════════════════════════════
	var zlevel_names = {0:"Cavernas",1:"Sub",2:"Superficie",3:"Cielo",4:"Alto",5:"Cima"}
	var zname = zlevel_names.get(camera_pos.y, "Z:%d" % camera_pos.y)
	draw_string(_font, Vector2(x, y + lh),
		"  [%d,%d]  %s" % [camera_pos.x, camera_pos.z, zname],
		HORIZONTAL_ALIGNMENT_LEFT, mw, 9, Color(0.5, 0.5, 0.65))
	y += int(lh * 1.3)

	# ═══════════════════════════════════════════════
	# 5. DESIGNATION MODE (only if active)
	# ═══════════════════════════════════════════════
	if _designation_mode_name not in ["View","Vista",""]:
		draw_rect(Rect2(x, y, mw - 4, lh + 4), Color(0.08,0.05,0.15), true)
		draw_rect(Rect2(x, y, mw - 4, lh + 4), _designation_mode_color.darkened(0.3), false, 1.0)
		draw_string(_font, Vector2(x + 4, y + lh),
			"⚒  %s" % _designation_mode_name,
			HORIZONTAL_ALIGNMENT_LEFT, mw, 10, _designation_mode_color)
		y += int(lh * 1.7)

	# ═══════════════════════════════════════════════
	# 6. JOBS
	# ═══════════════════════════════════════════════
	draw_string(_font, Vector2(x, y + lh), "TRABAJOS", HORIZONTAL_ALIGNMENT_LEFT, mw, 10, Color(0.65,0.65,0.25))
	draw_line(Vector2(x, y + lh + 2), Vector2(x + mw - 4, y + lh + 2), Color(0.35,0.35,0.15), 1.0)
	y += int(lh * 1.3)
	var jcol = Color(0.4,0.85,0.4) if _job_active > 0 else Color(0.5,0.5,0.5)
	draw_string(_font, Vector2(x + 4, y + lh),
		"  Act: %d   Cola: %d" % [_job_active, _job_pending],
		HORIZONTAL_ALIGNMENT_LEFT, mw, 9, jcol)
	y += int(lh * 1.6)

	# ═══════════════════════════════════════════════
	# 7. TILE UNDER CURSOR
	# ═══════════════════════════════════════════════
	if _highlighted_tile.x >= 0:
		draw_string(_font, Vector2(x, y + lh), "TERRENO", HORIZONTAL_ALIGNMENT_LEFT, mw, 10, Color(0.45,0.55,0.75))
		draw_line(Vector2(x, y + lh + 2), Vector2(x + mw - 4, y + lh + 2), Color(0.22,0.28,0.42), 1.0)
		y += int(lh * 1.3)

		var tile_name = world.get_tile_name(_highlighted_tile)
		var mat_idx   = world.get_material(_highlighted_tile)
		var mat_name  = DFWorld.MatType.keys()[mat_idx].to_lower().capitalize()
		var th_str = tile_name if tile_name.length() <= 24 else tile_name.substr(0, 21) + "..."
		draw_string(_font, Vector2(x + 4, y + lh), "  %s" % th_str,
			HORIZONTAL_ALIGNMENT_LEFT, mw, 9, Color(0.70,0.70,0.90))
		y += lh

		if _biome_at_cursor != "":
			draw_string(_font, Vector2(x + 4, y + lh), "  %s" % _biome_at_cursor.capitalize(),
				HORIZONTAL_ALIGNMENT_LEFT, mw, 8, Color(0.40,0.65,0.40))
			y += lh
		else:
			draw_string(_font, Vector2(x + 4, y + lh), "  Mat: %s" % mat_name,
				HORIZONTAL_ALIGNMENT_LEFT, mw, 8, Color(0.50,0.50,0.70))
			y += lh

		var tags = []
		if _aquifer_at_cursor: tags.append("Acuífero")
		if _magma_at_cursor:   tags.append("Magma")
		if _layer_at_cursor != "": tags.append(_layer_at_cursor)
		if not tags.is_empty():
			draw_string(_font, Vector2(x + 4, y + lh), "  " + " · ".join(tags),
				HORIZONTAL_ALIGNMENT_LEFT, mw, 8, Color(0.80,0.55,0.20))
			y += lh

		# Workshop at cursor
		if world.workshops != null:
			for w in world.workshops:
				var workshop_near_x: bool = abs(w.tile_pos.x - _highlighted_tile.x) <= 1
				var workshop_near_z: bool = abs(w.tile_pos.z - _highlighted_tile.z) <= 1
				var workshop_same_level: bool = w.tile_pos.y == _highlighted_tile.y
				if workshop_near_x and workshop_near_z and workshop_same_level:
					var ws_str = "%s - %s" % [w.name, w.get_status_string()]
					ws_str = ws_str if ws_str.length() <= 26 else ws_str.substr(0,23) + "..."
					draw_string(_font, Vector2(x + 4, y + lh), "  " + ws_str,
						HORIZONTAL_ALIGNMENT_LEFT, mw, 9, w.get_display_color())
					y += lh
					if w.production_queue.size() > 0:
						draw_string(_font, Vector2(x + 4, y + lh),
							"  Cola: %d" % w.production_queue.size(),
							HORIZONTAL_ALIGNMENT_LEFT, mw, 8, Color(0.6,0.8,0.6))
						y += lh
					break

		# Items at cursor (compact)
		var items_here: Array = []
		for ent in world.entities:
			if ent is DFItem and ent.tile_pos == _highlighted_tile and not ent.is_decayed:
				items_here.append(ent)
		if not items_here.is_empty():
			draw_string(_font, Vector2(x + 4, y + lh),
				"  Items: %d en suelo" % items_here.size(),
				HORIZONTAL_ALIGNMENT_LEFT, mw, 8, Color(0.80,0.65,0.35))
			y += lh
			for it in items_here.slice(0, 3):
				var itlabel = it.get_full_name()
				if it.stack_size > 1: itlabel += " x%d" % it.stack_size
				itlabel = itlabel if itlabel.length() <= 22 else itlabel.substr(0,19)+"..."
				draw_string(_font, Vector2(x + 8, y + lh),
					"  %s %s" % [it.get_display_char(), itlabel],
					HORIZONTAL_ALIGNMENT_LEFT, mw, 8, it.get_display_color())
				y += lh
				if it.has_meta("is_artifact") or it.get("is_artifact") == true:
					var desc = it.get_meta("artifact_lore") if it.has_meta("artifact_lore") else (it.get("artifact_lore") if "artifact_lore" in it else "Reliquia legendaria.")
					var wrap_lines = _wrap_text(desc, 30)
					for line in wrap_lines:
						draw_string(_font, Vector2(x + 12, y + lh), "   " + line, HORIZONTAL_ALIGNMENT_LEFT, mw - 16, 7, Color(1.0, 0.85, 0.4))
						y += lh
				elif it.has_meta("is_beast_bones"):
					var bdesc = it.get_meta("beast_desc")
					var bwrap_lines = _wrap_text(bdesc, 30)
					for bline in bwrap_lines:
						draw_string(_font, Vector2(x + 12, y + lh), "   " + bline, HORIZONTAL_ALIGNMENT_LEFT, mw - 16, 7, Color(0.9, 0.7, 0.6))
						y += lh
		y += int(lh * 0.5)

	# ═══════════════════════════════════════════════
	# 8. ALDEANO SEGUIDO: inventario, carga y trabajo real
	# ═══════════════════════════════════════════════
	var followed_entity: Variant = null
	if follow_dwarf >= 0:
		for followed_candidate: Variant in world.entities:
			if followed_candidate is DFItem:
				continue
			var followed_type_value: Variant = followed_candidate.get("creature_type")
			if str(followed_type_value) != "dwarf":
				continue
			var followed_id_value: Variant = followed_candidate.get("id")
			var followed_alive_value: Variant = followed_candidate.get("is_alive")
			if followed_id_value != null and int(followed_id_value) == follow_dwarf and followed_alive_value != false:
				followed_entity = followed_candidate
				break

	if followed_entity != null:
		draw_string(_font, Vector2(x, y + lh), "SEGUIDO CON F", HORIZONTAL_ALIGNMENT_LEFT, mw, 10, Color(0.35,0.75,1.0))
		draw_line(Vector2(x, y + lh + 2), Vector2(x + mw - 4, y + lh + 2), Color(0.20,0.45,0.70), 1.0)
		y += int(lh * 1.3)

		var followed_name_value: Variant = followed_entity.get("name")
		var followed_name: String = str(followed_name_value) if followed_name_value != null else "Aldeano"
		var followed_profession: String = ""
		if followed_entity.has_method("get_profession_title"):
			followed_profession = str(followed_entity.call("get_profession_title"))
		var followed_header: String = followed_name if followed_profession.is_empty() else "%s · %s" % [followed_name, followed_profession]
		if followed_header.length() > 27:
			followed_header = followed_header.substr(0, 24) + "..."
		draw_string(_font, Vector2(x + 4, y + lh), followed_header, HORIZONTAL_ALIGNMENT_LEFT, mw - 8, 9, followed_entity.get_display_color())
		y += lh

		var followed_task_value: Variant = followed_entity.get("current_task")
		var followed_task: String = str(followed_task_value) if followed_task_value != null else "idle"
		if followed_task == "idle" or followed_task.is_empty():
			followed_task = "Ocioso"
		if followed_task.length() > 27:
			followed_task = followed_task.substr(0, 24) + "..."
		draw_string(_font, Vector2(x + 4, y + lh), "Tarea: " + followed_task, HORIZONTAL_ALIGNMENT_LEFT, mw - 8, 8, Color(0.80,0.80,0.65))
		y += lh

		var current_job_value: Variant = followed_entity.get("current_job")
		if current_job_value != null:
			var job_text: String = "Trabajo asignado"
			if current_job_value is Object and current_job_value.has_method("get_description"):
				job_text = str(current_job_value.call("get_description"))
			var progress_value: Variant = followed_entity.get("task_progress")
			var progress_percent: int = int(clampf(float(progress_value if progress_value != null else 0.0), 0.0, 1.0) * 100.0)
			if job_text.length() > 20:
				job_text = job_text.substr(0, 17) + "..."
			draw_string(_font, Vector2(x + 4, y + lh), "Job: %s %d%%" % [job_text, progress_percent], HORIZONTAL_ALIGNMENT_LEFT, mw - 8, 8, Color(0.90,0.68,0.30))
			y += lh

		var destination_text: String = ""
		var haul_destination_value: Variant = followed_entity.get("haul_destination")
		if haul_destination_value is Vector3i and haul_destination_value.y >= 0:
			var haul_destination_position: Vector3i = haul_destination_value
			destination_text = "Destino: %d,%d" % [haul_destination_position.x, haul_destination_position.z]
		elif current_job_value != null and current_job_value is Object:
			var job_position_value: Variant = current_job_value.get("tile_pos")
			if job_position_value is Vector3i:
				var job_position: Vector3i = job_position_value
				destination_text = "Destino: %d,%d" % [job_position.x, job_position.z]
		if not destination_text.is_empty():
			draw_string(_font, Vector2(x + 4, y + lh), destination_text, HORIZONTAL_ALIGNMENT_LEFT, mw - 8, 8, Color(0.60,0.78,0.90))
			y += lh

		var equipment_text: String = "Sin equipo"
		if followed_entity.has_method("get_equipment_string"):
			equipment_text = str(followed_entity.call("get_equipment_string"))
		if equipment_text.length() > 24:
			equipment_text = equipment_text.substr(0, 21) + "..."
		draw_string(_font, Vector2(x + 4, y + lh), "Equipo: " + equipment_text, HORIZONTAL_ALIGNMENT_LEFT, mw - 8, 8, Color(0.65,0.75,0.90))
		y += lh

		var followed_inventory_value: Variant = followed_entity.get("inventory")
		var followed_inventory: Array = followed_inventory_value if followed_inventory_value is Array else []
		var food_count: int = 0
		var drink_count: int = 0
		var wood_count: int = 0
		var stone_count: int = 0
		for inventory_count_entry: Variant in followed_inventory:
			if not (inventory_count_entry is Object):
				continue
			var inventory_type_value: Variant = inventory_count_entry.get("item_type")
			var inventory_type: String = str(inventory_type_value) if inventory_type_value != null else ""
			var stack_value: Variant = inventory_count_entry.get("stack_size")
			var stack_amount: int = maxi(1, int(stack_value if stack_value != null else 1))
			match inventory_type:
				"food", "meat": food_count += stack_amount
				"drink": drink_count += stack_amount
				"wood": wood_count += stack_amount
				"stone": stone_count += stack_amount
		draw_string(_font, Vector2(x + 4, y + lh), "Inv: %d  C:%d B:%d M:%d P:%d" % [followed_inventory.size(), food_count, drink_count, wood_count, stone_count], HORIZONTAL_ALIGNMENT_LEFT, mw - 8, 8, Color(0.75,0.88,0.75))
		y += lh

		var visible_inventory_items: int = mini(4, followed_inventory.size())
		for inventory_index: int in range(visible_inventory_items):
			var inventory_entry: Variant = followed_inventory[inventory_index]
			var inventory_label: String = str(inventory_entry)
			if inventory_entry is Object:
				var inventory_name_value: Variant = inventory_entry.get("name")
				if inventory_name_value != null:
					inventory_label = str(inventory_name_value)
				var inventory_stack_value: Variant = inventory_entry.get("stack_size")
				if inventory_stack_value != null and int(inventory_stack_value) > 1:
					inventory_label += " x%d" % int(inventory_stack_value)
			if inventory_label.length() > 23:
				inventory_label = inventory_label.substr(0, 20) + "..."
			draw_string(_font, Vector2(x + 8, y + lh), "· " + inventory_label, HORIZONTAL_ALIGNMENT_LEFT, mw - 12, 7, Color(0.68,0.68,0.75))
			y += lh
		if followed_inventory.size() > visible_inventory_items:
			draw_string(_font, Vector2(x + 8, y + lh), "+ %d objetos más" % (followed_inventory.size() - visible_inventory_items), HORIZONTAL_ALIGNMENT_LEFT, mw - 12, 7, Color(0.50,0.50,0.60))
			y += lh

		var stored_items: int = 0
		for stored_candidate: Variant in world.entities:
			if stored_candidate is DFItem and stored_candidate.get("is_in_stockpile") == true:
				stored_items += 1
		var growing_crops_value: Variant = world.get("growing_crops")
		var crop_count: int = growing_crops_value.size() if growing_crops_value is Dictionary else 0
		var warehouse_center_value: Variant = world.get_meta("warehouse_center", Vector3i(-1, -1, -1))
		var warehouse_text: String = "Almacén: %d objetos" % stored_items
		if warehouse_center_value is Vector3i:
			var warehouse_center_position: Vector3i = warehouse_center_value
			if warehouse_center_position.x >= 0:
				warehouse_text += " @ %d,%d" % [warehouse_center_position.x, warehouse_center_position.z]
		draw_string(_font, Vector2(x + 4, y + lh), warehouse_text, HORIZONTAL_ALIGNMENT_LEFT, mw - 8, 8, Color(0.45,0.85,0.55))
		y += lh
		draw_string(_font, Vector2(x + 4, y + lh), "Cultivos activos: %d" % crop_count, HORIZONTAL_ALIGNMENT_LEFT, mw - 8, 8, Color(0.50,0.85,0.45))
		y += int(lh * 1.4)

	# ═══════════════════════════════════════════════
	# 9. DWARVES LIST
	# ═══════════════════════════════════════════════
	draw_string(_font, Vector2(x, y + lh), "ENANOS", HORIZONTAL_ALIGNMENT_LEFT, mw, 10, Color(0.25,0.75,0.90))
	draw_line(Vector2(x, y + lh + 2), Vector2(x + mw - 4, y + lh + 2), Color(0.12,0.38,0.48), 1.0)
	y += int(lh * 1.3)

	var living_dwarves: Array = []
	for ent2 in world.entities:
		if ent2.get("creature_type") == "dwarf" and ent2.get("is_alive") != false:
			living_dwarves.append(ent2)

	if living_dwarves.is_empty():
		draw_string(_font, Vector2(x + 4, y + lh), "  ¡Sin supervivientes!", HORIZONTAL_ALIGNMENT_LEFT, mw, 9, Color(1.0,0.3,0.3))
		y += lh
	else:
		var dcount: int = 0
		var max_visible_dwarves: int = 2 if followed_entity != null else 7
		for dwarf in living_dwarves:
			if dcount >= max_visible_dwarves:
				draw_string(_font, Vector2(x + 4, y + lh),
					"  ...y %d más" % (living_dwarves.size() - max_visible_dwarves),
					HORIZONTAL_ALIGNMENT_LEFT, mw, 8, Color(0.4,0.4,0.5))
				y += lh
				break

			var is_followed = (follow_dwarf == dwarf.id)

			# Row background for followed dwarf
			if is_followed:
				draw_rect(Rect2(x, y + 1, mw - 4, lh * 2 + 4), Color(0.06,0.10,0.18), true)
				draw_rect(Rect2(x, y + 1, mw - 4, lh * 2 + 4), Color(0.20,0.40,0.70,0.5), false, 1.0)

			# Name row
			var tag   = "▶ " if is_followed else "  "
			var dname = dwarf.get_name_and_skill() if dwarf.has_method("get_name_and_skill") else dwarf.name
			dname = dname if dname.length() <= 22 else dname.substr(0, 19) + "..."
			draw_string(_font, Vector2(x + 4, y + lh), tag + dname,
				HORIZONTAL_ALIGNMENT_LEFT, mw, 10, dwarf.get_display_color())
			y += lh

			# HP bar + task on one line
			var hp_bar  = dwarf.get_health_bar() if dwarf.has_method("get_health_bar") else ""
			var task_s  = dwarf.get_task_string() if dwarf.has_method("get_task_string") else ""
			task_s = task_s if task_s.length() <= 14 else task_s.substr(0,11) + "..."
			draw_string(_font, Vector2(x + 8, y + lh),
				"  %s  %s" % [hp_bar, task_s],
				HORIZONTAL_ALIGNMENT_LEFT, mw, 8, Color(0.58,0.58,0.65))
			y += lh

			# Needs string (hambre/sed/salud)
			if dwarf.has_method("get_needs_string"):
				var needs_str = dwarf.get_needs_string()
				var needs_col = Color(0.4,0.8,0.4)
				if needs_str.contains("MORIBUNDO") or needs_str.contains("INANICION"):
					needs_col = Color(1.0,0.2,0.2)
				elif needs_str.contains("Herido grave") or needs_str.contains("Agotado"):
					needs_col = Color(1.0,0.6,0.1)
				needs_str = needs_str if needs_str.length() <= 22 else needs_str.substr(0,19) + "..."
				draw_string(_font, Vector2(x + 8, y + lh),
					"  " + needs_str,
					HORIZONTAL_ALIGNMENT_LEFT, mw, 7, needs_col)
				y += lh

			# Status badges
			var badges: Array = []
			if dwarf.get("is_bleeding") == true:  badges.append(["SANGRA", Color(0.9,0.2,0.2)])
			if dwarf.get("is_in_pain") == true:   badges.append(["DOLOR",  Color(0.9,0.5,0.1)])
			if dwarf.get("has_infection") == true: badges.append(["INFEC",  Color(0.2,0.9,0.3)])
			var dwarf_mood = dwarf.get("mood") if dwarf.get("mood") != null else 0
			var dwarf_sm_phase = dwarf.get("strange_mood_phase") if dwarf.get("strange_mood_phase") != null else 0
			if dwarf_mood >= 7 and dwarf_mood <= 10:
				var sm_types = ["POSEÍDO", "FÉERICO", "MACABRO", "SINIESTRO", "SECRETO"]
				var smt = dwarf.get("strange_mood_type") if dwarf.get("strange_mood_type") != null else 0
				badges.append([sm_types[smt] if smt < sm_types.size() else "¡MOOD!", Color(1.0, 0.4, 0.9)])
			var bref = dwarf.get("body")
			if bref != null:
				var ebr = bref.get("ebriety") if bref.get("ebriety") != null else 0.0
				if ebr > 0.5: badges.append(["EBRIO", Color(1.0,0.80,0.0)])
				if bref.get("is_vomiting") == true: badges.append(["VOMITO", Color(0.5,0.65,0.1)])
				if bref.get("disease_type") not in [null,""]: badges.append(["ENFERM", Color(0.2,0.85,0.3)])
				var ing = bref.get("ingested_substances")
				if ing and ing.has("poison") and ing["poison"] > 0.0:
					badges.append(["VENENO", Color(0.6,0.1,0.8)])
				if ing and ing.has("pathogen") and ing["pathogen"] > 0.0:
					badges.append(["CONTAM", Color(0.1,0.8,0.3)])

			if not badges.is_empty():
				var bx = x + 8
				for bdg in badges:
					var bw = int(bdg[0].length() * 5.5 + 8)
					draw_rect(Rect2(bx, y + 3, bw, lh - 2), bdg[1].darkened(0.6), true)
					draw_rect(Rect2(bx, y + 3, bw, lh - 2), bdg[1], false, 1.0)
					draw_string(_font, Vector2(bx + bw / 2, y + lh - 1), bdg[0],
						HORIZONTAL_ALIGNMENT_CENTER, bw, 7, Color.WHITE)
					bx += bw + 3
				y += lh

			# Wounds (compact, severe only)
			if dwarf.get("wounds") != null:
				var mortal_ct = 0
				var grave_ct  = 0
				for wound in dwarf.wounds:
					var sev = wound.get("severity","leve")
					if sev == "mortal": mortal_ct += 1
					elif sev == "grave": grave_ct += 1
				if mortal_ct > 0 or grave_ct > 0:
					var wstr = ""
					if mortal_ct > 0: wstr += "%d mortal " % mortal_ct
					if grave_ct  > 0: wstr += "%d grave" % grave_ct
					draw_string(_font, Vector2(x + 8, y + lh), "  Heridas: " + wstr,
						HORIZONTAL_ALIGNMENT_LEFT, mw, 8, Color(1.0,0.3,0.3))
					y += lh

			# Thoughts (followed dwarf only, last thought)
			if is_followed and dwarf.get("thoughts") != null and not dwarf.thoughts.is_empty():
				var th = dwarf.thoughts[dwarf.thoughts.size() - 1]
				th = th if th.length() <= 24 else th.substr(0, 21) + "..."
				draw_string(_font, Vector2(x + 8, y + lh), "  - " + th,
					HORIZONTAL_ALIGNMENT_LEFT, mw, 8, Color(0.80,0.78,0.55))
				y += lh

			y += int(lh * 0.4)
			dcount += 1

	# ═══════════════════════════════════════════════
	# 9. INVASION ALERT (pinned near bottom)
	# ═══════════════════════════════════════════════
	var bottom_y = view_height * lh - int(lh * 5)
	if _invasion_status.get("active", false):
		draw_rect(Rect2(x, bottom_y - 4, mw - 4, lh + 6), Color(0.3,0.02,0.02), true)
		draw_rect(Rect2(x, bottom_y - 4, mw - 4, lh + 6), Color(0.9,0.1,0.1), false, 1.5)
		draw_string(_font, Vector2(x + 4, bottom_y + lh),
			"⚠ %s" % _invasion_status.get("name","¡ATAQUE!"),
			HORIZONTAL_ALIGNMENT_LEFT, mw, 11, Color(1.0,0.3,0.3))
		bottom_y += int(lh * 1.5)
		draw_string(_font, Vector2(x + 4, bottom_y + lh),
			"  %d/%d enemigos" % [_invasion_status.get("spawned",0), _invasion_status.get("force",0)],
			HORIZONTAL_ALIGNMENT_LEFT, mw, 9, Color(1.0,0.55,0.55))
		bottom_y += lh

	# ═══════════════════════════════════════════════
	# 10. CARAVAN INFO
	# ═══════════════════════════════════════════════
	if not _caravan_info.is_empty():
		var car_count = _caravan_info.size()
		var car_title = "CARAVANAS" if car_count > 1 else "CARAVANA"
		draw_string(_font, Vector2(x + 4, bottom_y + lh), car_title,
			HORIZONTAL_ALIGNMENT_LEFT, mw, 9, Color(0.9,0.75,0.25))
		bottom_y += lh
		for cv in _caravan_info.slice(0, 3):
			var cv_name = cv.get("name", "Mercaderes")
			var cv_wealth = cv.get("wealth", 0)
			var c_str = "  %s" % cv_name
			if cv_wealth > 0:
				c_str += " (%dg)" % cv_wealth
			draw_string(_font, Vector2(x + 4, bottom_y + lh), c_str,
				HORIZONTAL_ALIGNMENT_LEFT, mw, 8, Color(0.7,0.6,0.2))
			bottom_y += lh
			# Estado de la caravana
			var state_name = {
				0: "acercándose", 1: "acampada", 
				2: "comerciando", 3: "partiendo"
			}.get(cv.get("state", 0), "")
			if state_name != "":
				var status_col = Color(0.5,0.85,0.5) if state_name == "comerciando" else Color(0.8,0.8,0.5)
				draw_string(_font, Vector2(x + 4, bottom_y + lh), "  - " + state_name,
					HORIZONTAL_ALIGNMENT_LEFT, mw, 7, status_col)
				bottom_y += lh

	# Combat log
	if not _combat_log.is_empty():
		draw_string(_font, Vector2(x + 4, bottom_y + lh), "Combate:", HORIZONTAL_ALIGNMENT_LEFT, mw, 9, Color(0.9,0.4,0.4))
		bottom_y += lh
		for msg in _combat_log:
			var dm = msg if msg.length() <= 26 else msg.substr(0,23) + "..."
			draw_string(_font, Vector2(x + 8, bottom_y + lh), dm, HORIZONTAL_ALIGNMENT_LEFT, mw, 8, Color(0.75,0.45,0.45))
			bottom_y += lh

	# Footer hint strip
	draw_string(_font, Vector2(x, view_height * lh - 2),
		"  H=Ayuda  F=Seguir  ESC=Menú",
		HORIZONTAL_ALIGNMENT_LEFT, mw, 8, Color(0.30,0.28,0.42))



func _draw_message_log(start_y: int) -> void:
	if _message_log.is_empty():
		return
	var bx  = _draw_border(view_width, view_height)
	var mw  = view_width * _char_size.x
	var lh  = int(_char_size.y)
	var num = mini(5, _message_log.size())

	var msg_h = num * int(lh * 1.18) + 6
	_draw_rounded_rect(Rect2(bx, start_y - 2, mw, msg_h),
		Color(0.02, 0.02, 0.06, 0.85), 4)
	draw_line(Vector2(bx, start_y - 2), Vector2(bx + mw, start_y - 2),
		Color(0.25, 0.22, 0.40), 1.0)

	var y = start_y
	for i in range(num):
		var idx = _message_log.size() - num + i
		var msg = _message_log[idx]
		# Pixel-based truncation (approx 7px per char at size 10)
		var max_chars = int(mw / 7)
		if msg.length() > max_chars:
			msg = msg.substr(0, max_chars - 3) + "..."
		# Older messages fade, newest is fully bright
		var alpha = 0.45 + 0.55 * float(i + 1) / float(num)
		var col = Color(0.82, 0.80, 0.65, alpha)
		if i == num - 1:
			col = Color(1.0, 0.97, 0.80, 1.0)  # Most recent: full brightness
		draw_string(_font, Vector2(bx + 4, y + lh), msg,
			HORIZONTAL_ALIGNMENT_LEFT, mw - 8, 10, col)
		y += int(lh * 1.18)


func _draw_help_overlay() -> void:
	var vw = view_width
	var vh = view_height
	var border_x = _draw_border(vw, vh)

	var box_x = border_x + 10
	var box_y = 10
	var box_w = (vw - 2) * _char_size.x - 20
	var box_h = (vh - 1) * _char_size.y - 20

	if box_w > 0 and box_h > 0:
		var rad = 10
		_draw_rounded_rect(Rect2(box_x, box_y, box_w, box_h), Color(0.0, 0.0, 0.0, 0.25), rad)
		_draw_rounded_rect(Rect2(box_x - 5, box_y - 5, box_w + 10, box_h + 10), Color(0.05, 0.05, 0.1, 0.95), rad)
		_draw_rounded_rect(Rect2(box_x - 5, box_y - 5, box_w + 10, box_h + 10), Color(0.3, 0.3, 0.4, 0.7), rad, false, 1.5)
		draw_rect(Rect2(box_x - 5, box_y - 3, box_w + 10, 3), Color(0.4, 0.4, 0.6, 0.8), true)

	var lines = [
		["== WORLD CREATION BIGLI - HELP ==", Color.GOLD],
		["", Color.WHITE],
		["MOVEMENT", Color.CYAN],
		["  Arrow keys    Move camera", Color.WHITE],
		["  [ / ]         Z-level down/up", Color.WHITE],
		["  Home          Center on surface", Color.WHITE],
		["", Color.WHITE],
		["GAME CONTROLS", Color.CYAN],
		["  Space         Pause/Resume", Color.WHITE],
		["  1-9           Speed (1=slow, 9=insane)", Color.WHITE],
		["  F             Follow dwarf (cycle)", Color.WHITE],
		["  G             Generate new world", Color.WHITE],
		["", Color.WHITE],
		["DESIGNATION MODE", Color.CYAN],
		["  1             Dig mode (Excavar)", Color.WHITE],
		["  2             Chop tree mode (Talar)", Color.WHITE],
		["  3             Smooth stone mode (Alisar)", Color.WHITE],
		["  4             Build wall mode (Muro)", Color.WHITE],
		["  5             Build floor mode (Suelo)", Color.WHITE],
		["  6             Deconstruct mode (Desmantelar)", Color.WHITE],
		["  Enter         Confirm selection", Color.WHITE],
		["  Esc           Cancel / exit mode", Color.WHITE],
		["  Mouse click   Start/end selection", Color.WHITE],
		["", Color.WHITE],
		["SAVE / LOAD", Color.CYAN],
		["  F5            Save slot 0", Color.WHITE],
		["  F6            Save slot 1", Color.WHITE],
		["  F7            Save slot 2", Color.WHITE],
		["  F9            Load slot 0", Color.WHITE],
		["  F10           Load slot 1", Color.WHITE],
		["  F11           Load slot 2", Color.WHITE],
		["", Color.WHITE],
		["MISCELLANEOUS", Color.CYAN],
		["  H / ?         Toggle this help", Color.WHITE],
		["  Esc*2         Return to Amphibia", Color.WHITE],
		["", Color.WHITE],
		["TIPS", Color.GREEN],
		["  1. Pause the game (Space) before designating", Color(0.7, 0.7, 0.7)],
		["  2. Press D, then click to mark tiles for digging", Color(0.7, 0.7, 0.7)],
		["  3. Unpause and dwarves will do the work", Color(0.7, 0.7, 0.7)],
		["  4. Use [ and ] to see different Z-levels", Color(0.7, 0.7, 0.7)],
		["", Color.WHITE],
		["Press H or ? to close", Color.GRAY],
	]

	var y = box_y + 8
	for line in lines:
		var text = line[0] as String
		var color = line[1] as Color
		var font_size = 12 if text.begins_with("==") else 10 if text.begins_with("  ") else 11
		draw_string(_font, Vector2(box_x + 8, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
		y += int(_char_size.y * (1.0 if text == "" else 1.0))

func _zlevel_name(y: int) -> String:
	if y >= 5: return "Peak"
	elif y == 4: return "High"
	elif y == 3: return "Open Sky"
	elif y == 2: return "Ground"
	elif y == 1: return "Sub"
	elif y == 0: return "Caves"
	else: return "Deep"

func _draw_legends_overlay() -> void:
	if _legend_text == "":
		return

	# === PANEL LATERAL DERECHO (35% del ancho de pantalla) ===
	# El mapa sigue visible a la izquierda. Las crónicas van a la derecha.
	var vp_w = size.x
	var vp_h = size.y

	var panel_w = int(vp_w * 0.37)
	var panel_x = vp_w - panel_w
	var panel_y = 0
	var panel_h = vp_h

	var shadow_offset = 4
	draw_rect(Rect2(panel_x + shadow_offset, panel_y + shadow_offset, panel_w, panel_h), Color(0.0, 0.0, 0.0, 0.3), true)
	draw_rect(Rect2(panel_x, panel_y, panel_w, panel_h), Color(0.02, 0.04, 0.08, 0.94), true)
	draw_rect(Rect2(panel_x, panel_y, 3, panel_h), Color(0.2, 0.7, 0.9, 0.85), true)
	var border_color = Color(0.15, 0.25, 0.35, 0.6)
	draw_rect(Rect2(panel_x, panel_y, panel_w, 1), border_color, true)
	draw_rect(Rect2(panel_x, panel_y + panel_h - 1, panel_w, 1), border_color, true)

	var px = panel_x + 10
	var py = 8
	var font_sz = 10

	var mode_names = {
		1: "RESUMEN",
		2: "CRONOLOGIA",
		3: "CIVILIZACIONES",
		4: "FIGURAS",
		5: "BESTIAS",
		6: "ARTEFACTOS",
		7: "ASENTAMIENTOS",
		8: "GUERRAS",
		9: "DINASTIAS",
		10: "DETALLE FIGURA"
	}
	var mode_title = mode_names.get(_legend_mode, "CRONICAS")
	var mode_colors = {
		1: Color(0.3, 0.9, 1.0), 2: Color(0.6, 0.8, 0.4), 3: Color(0.9, 0.7, 0.3),
		4: Color(0.4, 0.8, 0.9), 5: Color(0.9, 0.3, 0.3), 6: Color(0.9, 0.6, 0.1),
		7: Color(0.5, 0.8, 0.5), 8: Color(0.9, 0.4, 0.2), 9: Color(0.7, 0.5, 0.9),
		10: Color(0.3, 0.9, 1.0)
	}
	var mode_col = mode_colors.get(_legend_mode, Color(0.3, 0.9, 1.0))
	draw_rect(Rect2(panel_x, py + 16, panel_w, 2), mode_col, true)
	var title_text = " %s " % mode_title
	draw_string(_font, Vector2(px, py + 12), title_text,
		HORIZONTAL_ALIGNMENT_LEFT, panel_w - 20, 12, mode_col)
	py += 22
	draw_rect(Rect2(panel_x + 4, py, panel_w - 8, 1), Color(0.2, 0.4, 0.5, 0.4), true)
	py += 6

	if _legend_page != "":
		var page_col = mode_col.lightened(0.3)
		draw_string(_font, Vector2(px, py + 10), _legend_page,
			HORIZONTAL_ALIGNMENT_LEFT, panel_w - 20, 9, page_col)
		py += 14

	if _legend_mode == 10 and not _family_tree_data.is_empty():
		_draw_family_tree_content(panel_x, panel_y, panel_w, panel_h, px, py)
	else:
		var lines = _legend_text.split("\n")
		var max_lines_visible = int((panel_h - py - 40) / int(_char_size.y))
		var line_count = min(lines.size(), max_lines_visible)

		for li in range(line_count):
			var line = lines[li]
			var color = Color(0.88, 0.88, 0.80)
			if line.begins_with("===") or line.begins_with("---"):
				color = mode_col
				draw_rect(Rect2(panel_x + 4, py + 4, panel_w - 8, 1), mode_col * Color(1,1,1,0.3), true)
			elif line.begins_with("  ►") or line.begins_with("  -"):
				color = Color(0.75, 0.95, 0.75)
			elif line.begins_with("    *"):
				color = Color(0.55, 0.55, 0.65)
			elif line.begins_with("  "):
				color = Color(0.65, 0.65, 0.65)
			elif line.begins_with("- "):
				draw_rect(Rect2(px - 2, py + 4, 4, 4), mode_col * Color(1,1,1,0.6), true)
			draw_string(_font, Vector2(px + 4, py + int(_char_size.y)),
				line, HORIZONTAL_ALIGNMENT_LEFT, panel_w - 28, font_sz, color)
			py += int(_char_size.y)

	var ctrl_y = panel_y + panel_h - 30
	draw_rect(Rect2(panel_x + 4, ctrl_y - 4, panel_w - 8, 1), Color(0.25, 0.5, 0.6, 0.5), true)
	var legend_ctrl_text = "[1-9] Categorias  [PgUp/PgDn] Paginas  [L/ESC] Cerrar"
	if _legend_mode == 10:
		legend_ctrl_text = "[0] Volver a figuras  [L/ESC] Cerrar"
	draw_string(_font, Vector2(px, ctrl_y + 10),
		legend_ctrl_text,
		HORIZONTAL_ALIGNMENT_LEFT, panel_w - 20, 9, Color(0.4, 0.7, 0.8, 0.9))
	draw_string(_font, Vector2(px + panel_w - 20, ctrl_y + 10),
		mode_title,
		HORIZONTAL_ALIGNMENT_RIGHT, panel_w - 20, 7, mode_col * Color(1,1,1,0.4))


func _draw_family_tree_content(panel_x: int, panel_y: int, panel_w: int, panel_h: int, px: int, py: int) -> void:
	var data = _family_tree_data
	if data.is_empty():
		return

	var box_w = int(panel_w * 0.42)
	var box_h = 50
	var gap = 6
	var rad = 4
	var dyn_col = Color(0.3, 0.5, 0.7)
	if "dynasty_color" in data and data.dynasty_color is Color:
		dyn_col = data.dynasty_color

	var center_x = px + panel_w / 2 - 10
	var line_col = Color(0.35, 0.55, 0.65, 0.5)

	# ── Dynasty title bar ──
	var dyn_name = data.get("dynasty_name", "")
	if dyn_name != "":
		var title_fg = dyn_col.lightened(0.5)
		draw_string(_font, Vector2(px, py + 12), "⬥ %s" % dyn_name.to_upper(),
			HORIZONTAL_ALIGNMENT_LEFT, panel_w - 20, 10, title_fg)
		py += 4
		_draw_rounded_rect(Rect2(px, py + 2, panel_w - 20, 4), dyn_col * Color(1,1,1,0.6), 2)
		py += 10

	# ── Figure header card ──
	var hf_name = data.get("name", "?")
	var title_str = data.get("title", "")
	var alive_flag = data.get("alive", false)
	var ruler_flag = data.get("is_ruler", false)
	var age = data.get("age", 0)
	var prof = data.get("profession", "")
	var race_es = _translate_race_fast(data.get("race", ""))

	var age_str = "%d ★" % age if alive_flag else "%d ☠" % age
	var ruler_icon = " ♔" if ruler_flag else ""
	var header_h = 36
	_draw_person_box(px + 4, py, panel_w - 28, header_h, data, dyn_col, true, rad)
	var name_display = "%s%s" % [hf_name, ruler_icon]
	draw_string(_font, Vector2(px + 8, py + 12), name_display,
		HORIZONTAL_ALIGNMENT_LEFT, panel_w - 40, 9, Color(1.0, 1.0, 0.85))
	draw_string(_font, Vector2(px + 8, py + header_h - 8), "%s %s • %s" % [race_es, prof, age_str],
		HORIZONTAL_ALIGNMENT_LEFT, panel_w - 40, 7, Color(0.65, 0.65, 0.6))
	py += header_h + 8

	# ── Parents ──
	var parents = data.get("parents", [])
	if not parents.is_empty():
		draw_string(_font, Vector2(px, py + 10), "PADRES", HORIZONTAL_ALIGNMENT_LEFT, panel_w - 20, 8, Color(0.55, 0.75, 0.55))
		draw_rect(Rect2(px, py + 12, panel_w - 20, 1), Color(0.25, 0.45, 0.25, 0.4), true)
		py += 15
		var parent_y = py
		var total_pw = parents.size() * (box_w + gap) - gap
		var p_start_x = center_x - total_pw / 2
		for pi in range(parents.size()):
			var p = parents[pi]
			var bx = int(p_start_x + pi * (box_w + gap))
			_draw_person_box(bx, parent_y, box_w, box_h, p, dyn_col, false, rad)
		var line_y = parent_y + box_h
		for pi2 in range(parents.size()):
			var bx2 = int(p_start_x + pi2 * (box_w + gap))
			_draw_curved_line(bx2 + box_w / 2, line_y, center_x, line_y + 14, line_col, 1)
		draw_line(Vector2(p_start_x + box_w / 2, line_y + 14), Vector2(p_start_x + total_pw - box_w / 2 + box_w, line_y + 14), line_col, 1)
		py = line_y + 18
	else:
		draw_string(_font, Vector2(px, py + 10), "▸ Origen desconocido", HORIZONTAL_ALIGNMENT_LEFT, panel_w - 20, 8, Color(0.45, 0.45, 0.5))
		py += 14

	# ── Current figure + Spouse ──
	var spouse = data.get("spouse", {})
	var has_spouse = not spouse.is_empty()
	var fig_y = py
	var half_box_w = box_w if not has_spouse else int(box_w * 0.48)
	var total_fig_w = half_box_w * (1 + int(has_spouse)) + gap * int(has_spouse)
	var fig_start_x = center_x - total_fig_w / 2

	if has_spouse:
		_draw_person_box(fig_start_x, fig_y, half_box_w, box_h, spouse, dyn_col, false, rad)
		var sp_mid_x = fig_start_x + half_box_w / 2
		var self_mid_x = fig_start_x + half_box_w + gap + half_box_w / 2
		draw_line(Vector2(sp_mid_x, fig_y - 4), Vector2(self_mid_x, fig_y - 4), line_col, 1)
		draw_line(Vector2(sp_mid_x, fig_y - 8), Vector2(sp_mid_x, fig_y), line_col, 1)
		draw_line(Vector2(self_mid_x, fig_y - 8), Vector2(self_mid_x, fig_y), line_col, 1)
		draw_line(Vector2(sp_mid_x, fig_y - 8), Vector2(self_mid_x, fig_y - 8), line_col, 1)

	var self_x = fig_start_x + half_box_w + gap if has_spouse else fig_start_x
	_draw_person_box(self_x, fig_y, half_box_w, box_h, data, dyn_col, true, rad)
	py = fig_y + box_h + 8

	# ── Children ──
	var children = data.get("children", [])
	if not children.is_empty():
		_draw_curved_line(center_x, fig_y - 4, center_x, py - 2, line_col, 1)
		draw_string(_font, Vector2(px, py + 10), "HIJOS", HORIZONTAL_ALIGNMENT_LEFT, panel_w - 20, 8, Color(0.55, 0.75, 0.55))
		draw_rect(Rect2(px, py + 12, panel_w - 20, 1), Color(0.25, 0.45, 0.25, 0.4), true)
		py += 15
		var max_show = mini(children.size(), 4)
		var child_w = int((panel_w - 20 - (max_show - 1) * gap) / max_show)
		var total_cw = max_show * (child_w + gap) - gap
		var c_start_x = center_x - total_cw / 2
		var child_y = py
		for ci in range(max_show):
			var c = children[ci]
			var bx_child = int(c_start_x + ci * (child_w + gap))
			_draw_person_box(bx_child, child_y, child_w, box_h, c, dyn_col, false, rad)
			_draw_curved_line(center_x, py - 3, bx_child + child_w / 2, child_y, line_col, 1)
		draw_line(Vector2(c_start_x + child_w / 2, child_y), Vector2(c_start_x + total_cw - child_w / 2 + child_w, child_y), line_col, 1)
		if children.size() > max_show:
			draw_string(_font, Vector2(px, child_y + box_h + 2), "  +%d mas en cronicas" % (children.size() - max_show),
				HORIZONTAL_ALIGNMENT_LEFT, panel_w - 20, 7, Color(0.45, 0.45, 0.5))
		py = child_y + box_h + 12
	else:
		draw_string(_font, Vector2(px, py + 10), "▸ Sin descendencia", HORIZONTAL_ALIGNMENT_LEFT, panel_w - 20, 8, Color(0.45, 0.45, 0.5))
		py += 14

	# ── Siblings ──
	var sibs = data.get("siblings", [])
	if not sibs.is_empty():
		draw_string(_font, Vector2(px, py + 10), "HERMANOS", HORIZONTAL_ALIGNMENT_LEFT, panel_w - 20, 8, Color(0.65, 0.65, 0.55))
		draw_rect(Rect2(px, py + 12, panel_w - 20, 1), Color(0.35, 0.35, 0.25, 0.3), true)
		py += 15
		var max_s = mini(sibs.size(), 6)
		for si in range(max_s):
			var s = sibs[si]
			var icon = "♔" if s.get("is_ruler", false) else "•"
			var salive_col = Color(0.7, 0.9, 0.7) if s.get("alive", false) else Color(0.5, 0.5, 0.5)
			var sname = s.get("name", "?")
			if sname.length() > 14:
				sname = sname.substr(0, 13) + ".."
			draw_string(_font, Vector2(px + 8, py + 10), "%s %s  %d %s" % [icon, sname, s.get("age", 0), "★" if s.get("alive", false) else "☠"],
				HORIZONTAL_ALIGNMENT_LEFT, panel_w - 28, 7, salive_col)
			py += 10
		if sibs.size() > max_s:
			draw_string(_font, Vector2(px + 8, py + 10), "+%d mas" % (sibs.size() - max_s),
				HORIZONTAL_ALIGNMENT_LEFT, panel_w - 28, 7, Color(0.4, 0.4, 0.45))
			py += 10
		py += 2

	# ── Deeds ──
	var deeds = data.get("notable_deeds", [])
	if not deeds.is_empty():
		var space_left = panel_h - py - 50
		if space_left > 50:
			draw_string(_font, Vector2(px, py + 10), "HAZANAS", HORIZONTAL_ALIGNMENT_LEFT, panel_w - 20, 8, Color(0.75, 0.75, 0.45))
			draw_rect(Rect2(px, py + 12, panel_w - 20, 1), Color(0.45, 0.45, 0.25, 0.3), true)
			py += 15
			var max_d = mini(deeds.size(), 3)
			for di in range(max_d):
				var d_text = deeds[di]
				var deed_col = Color(0.75, 0.75, 0.65)
				if "mató" in d_text or "asesinó" in d_text or "ejecutó" in d_text:
					deed_col = Color(0.85, 0.45, 0.4)
				elif "fundó" in d_text or "creó" in d_text or "forjó" in d_text:
					deed_col = Color(0.5, 0.85, 0.6)
				elif "venció" in d_text or "derrotó" in d_text:
					deed_col = Color(0.85, 0.7, 0.3)
				if d_text.length() > 30:
					d_text = d_text.substr(0, 29) + "..."
				draw_string(_font, Vector2(px + 8, py + 10), "▪ %s" % d_text,
					HORIZONTAL_ALIGNMENT_LEFT, panel_w - 28, 7, deed_col)
				py += 10
			if deeds.size() > max_d:
				draw_string(_font, Vector2(px + 8, py + 10), "▪ +%d mas en cronicas" % (deeds.size() - max_d),
					HORIZONTAL_ALIGNMENT_LEFT, panel_w - 28, 7, Color(0.45, 0.45, 0.45))

func _draw_person_box(x: int, y: int, w: int, h: int, person: Dictionary, dyn_color: Color, highlighted: bool, radius: int = 4) -> void:
	var alive = person.get("alive", false)
	var is_ruler = person.get("is_ruler", false)

	var bg_color = Color(0.08, 0.08, 0.14)
	var border_color = dyn_color.darkened(0.2)
	if highlighted:
		border_color = Color(0.3, 0.9, 1.0)
		bg_color = Color(0.1, 0.12, 0.22)
		_draw_rounded_rect(Rect2(x - 1, y - 1, w + 2, h + 2), Color(0.3, 0.9, 1.0, 0.15), radius + 2)
	elif not alive:
		border_color = Color(0.3, 0.3, 0.35)
		bg_color = Color(0.06, 0.06, 0.08)

	_draw_rounded_rect(Rect2(x, y, w, h), bg_color, radius)
	_draw_rounded_rect(Rect2(x, y, w, h), border_color, radius, false, 1.5)

	var status_icon = "★" if alive else "☠"
	var name_text = person.get("name", "?")
	if is_ruler:
		name_text = "♔ " + name_text
	if name_text.length() > 11:
		name_text = name_text.substr(0, 10) + "."

	var age = person.get("age", 0)
	var name_col = Color(0.92, 0.92, 0.85) if alive else Color(0.5, 0.5, 0.5)

	draw_string(_font, Vector2(x + 4, y + 12), name_text,
		HORIZONTAL_ALIGNMENT_LEFT, w - 8, 8, name_col)
	draw_string(_font, Vector2(x + 4, y + h - 7), "%d %s" % [age, status_icon],
		HORIZONTAL_ALIGNMENT_LEFT, w - 8, 7, Color(0.6, 0.6, 0.5))

	if alive:
		var health_dot_x = x + w - 10
		var health_dot_y = y + h - 8
		draw_circle(Vector2(health_dot_x, health_dot_y), 2.5, Color(0.3, 0.85, 0.3))

func _translate_race_fast(race: String) -> String:
	match race.to_lower():
		"dwarf": return "Enano"
		"elf": return "Elfo"
		"human": return "Humano"
		"goblin": return "Goblin"
		"megabeast": return "Bestia"
	return race

func _draw_settings_menu() -> void:
	var main_node = get_parent()
	if main_node == null: return

	var line_h = _char_size.y
	var center_x = size.x / 2
	var vp = size

	# ---- Premium background ----
	_draw_premium_background(vp)

	# Subtle top gradient bar
	draw_rect(Rect2(0, 0, vp.x, 6), Color(0.15, 0.10, 0.30, 0.8), true)
	draw_rect(Rect2(0, vp.y - 6, vp.x, 6), Color(0.15, 0.10, 0.30, 0.8), true)

	# ---- ASCII LOGO (centered near top) ----
	var logo_lines = [
		"██████╗ ██╗ ██████╗ ██╗     ██╗",
		"██╔══██╗██║██╔════╝ ██║     ██║",
		"██████╔╝██║██║  ███╗██║     ██║",
		"██╔══██╗██║██║   ██║██║     ██║",
		"██████╔╝██║╚██████╔╝███████╗██║",
		"╚═════╝ ╚═╝ ╚═════╝ ╚══════╝╚═╝"
	]
	var logo_y = 30
	for logo_line in logo_lines:
		draw_string(_font, Vector2(center_x, logo_y), logo_line,
			HORIZONTAL_ALIGNMENT_CENTER, -1, 13, Color(0.55, 0.35, 0.90))
		logo_y += int(line_h * 1.1)

	# Subtitle
	logo_y += 4
	draw_string(_font, Vector2(center_x, logo_y), "Un simulador de mundo vivo — inspirado en Dwarf Fortress",
		HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color(0.60, 0.55, 0.75))
	logo_y += int(line_h * 0.9)
	draw_string(_font, Vector2(center_x, logo_y), "~ Donde cada historia emerge de la simulación, no del guión ~",
		HORIZONTAL_ALIGNMENT_CENTER, -1, 9, Color(0.40, 0.38, 0.55))

	# Horizontal divider
	logo_y += int(line_h * 1.2)
	draw_line(Vector2(center_x - 260, logo_y), Vector2(center_x + 260, logo_y), Color(0.30, 0.25, 0.55), 1.0)

	# ---- QUICK START BOX (prominent) ----
	var qs_y = logo_y + 14
	var qs_w = 380
	var qs_h = 64
	var qs_x = center_x - qs_w / 2
	_draw_rounded_rect(Rect2(qs_x - 2, qs_y - 2, qs_w + 4, qs_h + 4), Color(0.0, 0.0, 0.0, 0.2), 6)
	_draw_rounded_rect(Rect2(qs_x, qs_y, qs_w, qs_h), Color(0.08, 0.05, 0.18), 6)
	_draw_rounded_rect(Rect2(qs_x, qs_y, qs_w, qs_h), Color(0.55, 0.40, 0.90), 6, false, 2.0)
	draw_string(_font, Vector2(center_x, qs_y + 18), "▶  INICIO RÁPIDO  ◀",
		HORIZONTAL_ALIGNMENT_CENTER, -1, 15, Color(0.90, 0.80, 1.0))
	draw_string(_font, Vector2(center_x, qs_y + 40), "Presiona  Q  o Haz Click para jugar ahora mismo",
		HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color(0.65, 0.60, 0.80))

	# ---- CONFIG SECTION ----
	var cfg_y = qs_y + qs_h + 18
	draw_string(_font, Vector2(center_x, cfg_y), "── CONFIGURACIÓN DEL MUNDO ──",
		HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color(0.50, 0.45, 0.65))
	cfg_y += int(line_h * 1.4)

	var box_w = 520
	var box_h = 145
	var box_x = center_x - box_w / 2
	_draw_rounded_rect(Rect2(box_x, cfg_y, box_w, box_h), Color(0.03, 0.03, 0.08, 0.9), 6)
	_draw_rounded_rect(Rect2(box_x, cfg_y, box_w, box_h), Color(0.25, 0.20, 0.45), 6, false, 1.5)

	var options = [
		["Semilla del Mundo",     "%s" % ("Aleatoria" if main_node.generation_seed == -1 else str(main_node.generation_seed))],
		["Tamaño del Continente", ["Pequeño (128²)", "Estándar (256²)", "Grande (512²)", "Gigantesco (1024²)"][clampi(main_node.setting_size, 0, 3)]],
		["Duración de Historia",  "%d años" % main_node.setting_history_options[main_node.setting_history_idx]],
		["Civilizaciones",        ["Baja", "Media", "Alta"][main_node.setting_civ_density]],
		["Megabestias",           ["Pocas", "Moderadas", "Abundantes"][main_node.setting_beast_density]],
	]

	var opt_y = cfg_y + 10
	for i in range(options.size()):
		var is_sel = (main_node.setting_selected_index == i)
		var key_col  = Color(0.80, 0.78, 0.90) if is_sel else Color(0.55, 0.52, 0.65)
		var val_col  = Color(1.0, 0.90, 0.40) if is_sel else Color(0.75, 0.70, 0.85)
		var arrow    = "▸ " if is_sel else "  "
		
		if is_sel:
			_draw_rounded_rect(Rect2(box_x + 10, opt_y - 2, box_w - 20, 18), Color(0.20, 0.15, 0.40, 0.4), 4)

		draw_string(_font, Vector2(box_x + 22, opt_y + 10), arrow + options[i][0],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 10, key_col)
		draw_string(_font, Vector2(box_x + box_w - 22, opt_y + 10), options[i][1],
			HORIZONTAL_ALIGNMENT_RIGHT, -1, 10, val_col)
		opt_y += int(line_h * 1.25)

	# ---- DESCRIPTION OF SELECTED SETTING ----
	var s_desc_y = cfg_y + box_h + 8
	var s_desc_w = 520
	var s_desc_h = 38
	var s_desc_x = center_x - s_desc_w / 2
	_draw_rounded_rect(Rect2(s_desc_x, s_desc_y, s_desc_w, s_desc_h), Color(0.02, 0.02, 0.05, 0.85), 5)
	_draw_rounded_rect(Rect2(s_desc_x, s_desc_y, s_desc_w, s_desc_h), Color(0.20, 0.16, 0.35, 0.6), 5, false, 1.0)
	
	var s_desc = ""
	match main_node.setting_selected_index:
		0: s_desc = "Semilla del Mundo: Establece el valor inicial generador. Si es aleatorio, cada partida generará un continente totalmente diferente."
		1: s_desc = "Tamaño del Continente: Controla el ancho del mapa. El modo Gigantesco contiene 1.048.576 regiones globales. Usa simulación abstracta y solo materializa en detalle la zona jugada; tarda más al crear el mundo."
		2: s_desc = "Duración de Historia: Años simulados antes de jugar. A mayor historia, habrá más ruinas, reyes muertos, reliquias y megabestias."
		3: s_desc = "Civilizaciones: Determina la densidad de reinos de enanos, elfos, humanos y goblins en el continente."
		4: s_desc = "Megabestias: Cantidad de dragones y monstruos gigantescos iniciales. Afecta los ataques históricos a aldeas."
	
	var s_desc_lines = _wrap_text(s_desc, 65)
	var s_dy = s_desc_y + 14
	for s_line in s_desc_lines:
		draw_string(_font, Vector2(center_x, s_dy), s_line, HORIZONTAL_ALIGNMENT_CENTER, s_desc_w - 20, 8, Color(0.70, 0.68, 0.80))
		s_dy += int(line_h * 1.05)

	# ---- Footer help bar ----
	var foot_y = s_desc_y + s_desc_h + 20
	var help_items = [
		["↑↓", "Seleccionar"],
		["←→", "Cambiar valor"],
		["R", "Semilla aleatoria"],
		["ENTER", "Crear Mundo"],
		["Q", "Inicio Rápido"],
	]
	var help_x = center_x - 300
	for hi in help_items:
		_draw_rounded_rect(Rect2(help_x, foot_y - 10, 42, 16), Color(0.18, 0.15, 0.32), 3)
		_draw_rounded_rect(Rect2(help_x, foot_y - 10, 42, 16), Color(0.40, 0.35, 0.65), 3, false, 1.0)
		draw_string(_font, Vector2(help_x + 21, foot_y), hi[0],
			HORIZONTAL_ALIGNMENT_CENTER, 42, 9, Color(0.90, 0.88, 1.0))
		draw_string(_font, Vector2(help_x + 48, foot_y), hi[1],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.55, 0.52, 0.65))
		help_x += 120

	# Version tag
	draw_string(_font, Vector2(vp.x - 10, vp.y - 10), "BIGLI alpha v0.1",
		HORIZONTAL_ALIGNMENT_RIGHT, -1, 8, Color(0.25, 0.22, 0.38))



func _draw_generating_screen() -> void:
	_draw_premium_background(size)

	var main_node = get_parent()
	if main_node == null:
		return

	var line_h: int = int(_char_size.y)
	var center_x: float = size.x / 2.0
	var box_w: int = 680
	var box_h: int = 470
	var box_x: float = center_x - float(box_w) / 2.0
	var box_y: float = (size.y - float(box_h)) / 2.0
	var building_terrain: bool = int(main_node.gen_year) <= 0 and float(main_node.load_progress) < 0.18

	draw_rect(Rect2(box_x, box_y, box_w, box_h), Color(0.0, 0.04, 0.01, 0.9), true)
	_draw_dashed_border(Rect2(box_x, box_y, box_w, box_h), Color(0.0, 2.5, 0.0), 4.0)

	var y: float = box_y + 35.0
	var pulse: float = 0.8 + 0.2 * sin(Time.get_ticks_msec() * 0.005)
	var phase_title: String = "GENERANDO MUNDO FÍSICO" if building_terrain else "SIMULANDO HISTORIA Y CIVILIZACIONES"
	draw_string(_font, Vector2(center_x, y), "◆ %s: %s ◆" % [phase_title, str(main_node.world_name).to_upper()], HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color(0.0, 2.5 * pulse, 0.0))
	y += float(line_h) * 2.0

	var pct: float = clampf(float(main_node.load_progress), 0.0, 1.0)
	if not building_terrain and int(main_node.gen_max_years) > 0:
		pct = maxf(pct, 0.18 + (float(main_node.gen_year) / float(main_node.gen_max_years)) * 0.70)
	var bar_w: int = 520
	var bar_h: int = 18
	var bar_x: float = center_x - float(bar_w) / 2.0
	draw_rect(Rect2(bar_x, y, bar_w, bar_h), Color(0.0, 0.1, 0.02), true)
	draw_rect(Rect2(bar_x, y, bar_w, bar_h), Color(0.0, 1.2, 0.0), false, 1.0)
	if pct > 0.0:
		draw_rect(Rect2(bar_x + 2.0, y + 2.0, float(bar_w - 4) * pct, bar_h - 4), Color(0.0, 2.5, 0.0), true)
	var pct_str: String = "%d%%" % int(pct * 100.0)
	draw_string(_font, Vector2(center_x, y + 14.0), pct_str, HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color.BLACK if pct > 0.5 else Color(0.0, 2.5, 0.0))
	y += float(line_h) * 2.1

	var status_text: String = str(main_node.load_status)
	draw_string(_font, Vector2(center_x, y), status_text, HORIZONTAL_ALIGNMENT_CENTER, box_w - 70, 10, Color(0.65, 1.0, 0.68))
	y += float(line_h) * 1.8

	var world_width: int = 0
	var world_depth: int = 0
	if main_node.world_gen != null:
		world_width = int(main_node.world_gen.world_width)
		world_depth = int(main_node.world_gen.world_depth)
	var stats: Array = [
		["MAPA GLOBAL:", "%d × %d" % [world_width, world_depth]],
		["REGIONES:", "%s" % _format_world_region_count(world_width * world_depth)],
		["AÑO HISTÓRICO:", "%d / %d" % [main_node.gen_year, main_node.gen_max_years]],
		["ERA ACTUAL:", str(main_node.gen_current_age).to_upper()],
		["PERSONAJES:", "%d" % main_node.gen_historical_figures],
		["ASENTAMIENTOS:", "%d" % main_node.gen_active_sites],
		["CONFLICTOS:", "%d" % main_node.gen_active_wars],
		["BESTIAS VIVAS:", "%d" % main_node.gen_beasts_alive]
	]

	var col_x1: float = box_x + 40.0
	var col_x2: float = box_x + float(box_w) / 2.0 + 20.0
	var col_w: float = float(box_w) / 2.0 - 60.0
	for stat_index in range(stats.size()):
		var stat: Array = stats[stat_index]
		var sx: float = col_x1 if stat_index % 2 == 0 else col_x2
		var sy: float = y + float(int(stat_index / 2)) * float(line_h) * 1.5
		draw_string(_font, Vector2(sx, sy), str(stat[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.0, 1.2, 0.0, 0.7))
		draw_string(_font, Vector2(sx + col_w, sy), str(stat[1]), HORIZONTAL_ALIGNMENT_RIGHT, -1, 10, Color(0.0, 2.5, 0.0))
	y += float(int((stats.size() + 1) / 2) + 1) * float(line_h) * 1.5

	draw_string(_font, Vector2(box_x + 40.0, y), "❯ CRÓNICA CAUSAL DEL MUNDO:", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.0, 2.0, 0.0))
	y += float(line_h) * 1.2
	var ev_box_h: int = 105
	draw_rect(Rect2(box_x + 40.0, y, box_w - 80, ev_box_h), Color(0.0, 0.02, 0.0, 0.95), true)
	draw_rect(Rect2(box_x + 40.0, y, box_w - 80, ev_box_h), Color(0.0, 1.5, 0.0), false, 1.0)
	var ev_y: float = y + 18.0
	if main_node.gen_rolling_events.is_empty():
		draw_string(_font, Vector2(box_x + 50.0, ev_y), "░ Preparando topografía, cuencas y civilizaciones...", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.0, 1.8, 0.0, 0.95))
	else:
		for event_variant in main_node.gen_rolling_events:
			var event_text: String = str(event_variant)
			var display_event: String = event_text if event_text.length() <= 72 else event_text.substr(0, 69) + "..."
			draw_string(_font, Vector2(box_x + 50.0, ev_y), "░ " + display_event, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.0, 1.8, 0.0, 0.95))
			ev_y += float(line_h) * 0.82

	var spinner: String = ["|", "/", "-", "\\"][int(Time.get_ticks_msec() / 150) % 4]
	y = box_y + float(box_h) - 24.0
	var footer: String = "PROCESANDO REGIONES... %s" % spinner if building_terrain else "SIMULANDO CRONOLOGÍA... %s  [ENTER: terminar en el año actual]" % spinner
	draw_string(_font, Vector2(center_x, y), footer, HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color(0.0, 1.5, 0.0, 0.7))

func _format_world_region_count(region_count: int) -> String:
	if region_count >= 1000000:
		return "%.2f millones" % (float(region_count) / 1000000.0)
	if region_count >= 1000:
		return "%.1f mil" % (float(region_count) / 1000.0)
	return str(region_count)

func _draw_mode_select_menu() -> void:
	# Deep space background (matches title screen)
	draw_rect(Rect2(0, 0, size.x, size.y), Color(0.01, 0.01, 0.03), true)

	var main_node = get_parent()
	if main_node == null: return

	var line_h = int(_char_size.y)
	var center_x = size.x / 2

	var box_w = 460
	var box_h = 265
	var box_x = center_x - box_w / 2
	var box_y = (size.y - box_h) / 2 - 30
	
	_draw_rounded_rect(Rect2(box_x - 2, box_y - 2, box_w + 4, box_h + 4), Color(0.0, 0.0, 0.0, 0.2), 8)
	_draw_rounded_rect(Rect2(box_x, box_y, box_w, box_h), Color(0.04, 0.03, 0.10), 8)
	_draw_rounded_rect(Rect2(box_x, box_y, box_w, box_h), Color(0.55, 0.40, 0.90), 8, false, 2.0)
	draw_rect(Rect2(box_x, box_y + 2, box_w, 3), Color(0.55, 0.40, 0.90, 0.6), true)

	var y = box_y + 35
	draw_string(_font, Vector2(center_x, y), "=== MUNDO GENERADO CON ÉXITO ===", HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color.GOLD)
	y += int(line_h * 2.2)

	var options = [
		"Jugar Modo Fortaleza (Gestión)",
		"Jugar Modo Aventura (Roguelike)",
		"Explorar Modo Leyendas (Crónica)"
	]

	for i in range(options.size()):
		var is_sel = (main_node.setting_selected_index == i)
		var color = Color(0.95, 0.85, 1.0) if is_sel else Color(0.60, 0.55, 0.70)
		var prefix = "▸  [ " if is_sel else "   [ "
		var suffix = " ]"
		
		if is_sel:
			_draw_rounded_rect(Rect2(box_x + 20, y - 10, box_w - 40, 24), Color(0.20, 0.14, 0.38, 0.6), 4)
			_draw_rounded_rect(Rect2(box_x + 20, y - 10, box_w - 40, 24), Color(0.45, 0.30, 0.80, 0.8), 4, false, 1.0)

		draw_string(_font, Vector2(center_x, y + 6), prefix + options[i] + suffix, HORIZONTAL_ALIGNMENT_CENTER, -1, 12, color)
		y += int(line_h * 2.0)

	y = box_y + box_h - 30
	draw_string(_font, Vector2(center_x, y), "↑↓ o Click: Seleccionar  |  ENTER o Doble Click: Confirmar", HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color(0.45, 0.40, 0.55))

	# ---- DESCRIPTION TOOLTIP CARD ----
	var desc_y = box_y + box_h + 20
	var desc_w = 460
	var desc_h = 75
	var desc_x = center_x - desc_w / 2
	
	_draw_rounded_rect(Rect2(desc_x, desc_y, desc_w, desc_h), Color(0.02, 0.02, 0.06, 0.85), 6)
	_draw_rounded_rect(Rect2(desc_x, desc_y, desc_w, desc_h), Color(0.25, 0.30, 0.55, 0.7), 6, false, 1.5)
	draw_rect(Rect2(desc_x, desc_y + 2, desc_w, 3), Color(0.25, 0.30, 0.55, 0.5), true)
	
	var desc_text = ""
	match main_node.setting_selected_index:
		0:
			desc_text = "MODO FORTALEZA:\nLidera a un grupo de 7 enanos para excavar, forjar, cultivar, comerciar y construir defensas contra invasiones y peligros subterráneos en modo simulación."
		1:
			desc_text = "MODO AVENTURA:\nPosesión de un héroe en tercera persona. Explora el mundo persistente, entabla diálogos con NPCs, viaja por biomas y recluta aliados en modo Roguelike."
		2:
			desc_text = "MODO LEYENDAS:\nConsulta el compendio histórico generado por la simulación de historia: civilizaciones, guerras, héroes, megabestias y reliquias perdidas del mundo."
	
	var desc_lines = _wrap_text(desc_text, 50)
	var dy = desc_y + 18
	for line in desc_lines:
		draw_string(_font, Vector2(center_x, dy), line, HORIZONTAL_ALIGNMENT_CENTER, desc_w - 20, 9, Color(0.75, 0.72, 0.85))
		dy += int(line_h * 1.15)

func _draw_embark_map_select() -> void:
	_draw_premium_background(size)

	var main_node = get_parent()
	if main_node == null or main_node.world_gen == null:
		return

	var line_h: int = int(_char_size.y)
	var map_grid_w: int = 40
	var map_grid_h: int = 25
	var panel_w: int = 380
	var spacing: int = 24
	var total_w: float = float(map_grid_w) * _char_size.x + float(spacing + panel_w)
	var total_h: float = float(map_grid_h) * _char_size.y
	var start_x: int = int((size.x - total_w) / 2.0)
	var start_y: int = int((size.y - total_h) / 2.0 + 10.0)

	var cursor: Vector2i = main_node.embark_cursor
	var map_w: int = int(main_node.world_gen.world_width)
	var map_h: int = int(main_node.world_gen.world_depth)
	var offset_x: int = cursor.x - int(map_grid_w / 2)
	var offset_y: int = cursor.y - int(map_grid_h / 2)

	var map_rect := Rect2(start_x - 6, start_y - 6, map_grid_w * _char_size.x + 12, map_grid_h * _char_size.y + 12)
	_draw_rounded_rect(Rect2(start_x - 4, start_y - 4, map_grid_w * _char_size.x + 8, map_grid_h * _char_size.y + 8), Color(0.0, 0.0, 0.0, 0.2), 6)
	_draw_rounded_rect(map_rect, Color(0.05, 0.04, 0.12), 6)
	_draw_rounded_rect(map_rect, Color(0.35, 0.25, 0.60), 6, false, 1.5)
	draw_rect(Rect2(start_x - 6, start_y - 4, map_grid_w * _char_size.x + 12, 3), Color(0.35, 0.25, 0.60, 0.6), true)

	var b_chars: Dictionary = {
		"ocean_deep": ["~", Color("#3154a4")],
		"ocean_shallow": ["~", Color("#4778c6")],
		"lake": ["≈", Color("#4c9cdb")],
		"beach": ["·", Color("#dfcb83")],
		"glacier": ["*", Color("#e0ffff")],
		"tundra": ["·", Color("#b9c8c8")],
		"taiga": ["♣", Color("#3d7661")],
		"mountain": ["^", Color("#8c8c8c")],
		"mountain_forest": ["♣", Color("#426b4c")],
		"alpine_meadow": ["'", Color("#91ad6e")],
		"grassland": [".", Color("#73b359")],
		"temperate_forest": ["♣", Color("#3a8c4d")],
		"dense_temperate_forest": ["♣", Color("#276f40")],
		"tropical_forest": ["♣", Color("#2c8246")],
		"rainforest": ["♣", Color("#1d6439")],
		"savanna": [".", Color("#a7ad4c")],
		"desert": ["·", Color("#eedc82")],
		"badlands": ["x", Color("#c07c4c")],
		"swamp": ["s", Color("#718a58")]
	}

	for grid_z in range(map_grid_h):
		for grid_x in range(map_grid_w):
			var wx: int = offset_x + grid_x
			var wz: int = offset_y + grid_z
			if wx < 0 or wx >= map_w or wz < 0 or wz >= map_h:
				continue
			var biome: String = str(main_node.world_gen.biome_map[wz][wx])
			var b_data: Array = b_chars.get(biome, [".", Color("#888888")])
			var ch: String = str(b_data[0])
			var fg: Color = b_data[1]

			if main_node.world_gen.is_lake(wx, wz):
				ch = "≈"
				fg = Color("#58b5eb")
			elif main_node.world_gen.is_river(wx, wz):
				var river_order: int = main_node.world_gen.get_river_order(wx, wz)
				ch = "≋" if river_order >= 3 else "≈"
				fg = Color("#63c2f4")
			if main_node.world_gen.is_road(wx, wz):
				var road_kind: int = int(main_node.world_gen.road_map[wz][wx])
				ch = "#" if road_kind == 2 else "="
				fg = Color("#ead28f")

			var site: Dictionary = main_node.world_gen.get_site_at(wx, wz)
			if not site.is_empty():
				var ruined: bool = str(site.get("site_type", "")).begins_with("ruina") or bool(site.get("is_sacked", false))
				ch = "†" if ruined else "◆" if bool(site.get("is_capital", false)) else "●"
				fg = Color("#d78964") if ruined else Color("#fff1a3")

			var inside_embark: bool = absi(wx - cursor.x) <= 1 and absi(wz - cursor.y) <= 1
			var flash: bool = int(main_node.embark_flash_timer * 3.0) % 2 == 0
			var draw_pos := Vector2(start_x + grid_x * _char_size.x, start_y + grid_z * _char_size.y)
			if inside_embark and flash:
				draw_rect(Rect2(draw_pos, _char_size), Color(0.12, 0.45, 0.12, 0.75), true)
				draw_string(_font, draw_pos + Vector2(0, _char_size.y * 0.8), ch, HORIZONTAL_ALIGNMENT_CENTER, _char_size.x, 11, Color.WHITE)
			else:
				draw_string(_font, draw_pos + Vector2(0, _char_size.y * 0.8), ch, HORIZONTAL_ALIGNMENT_CENTER, _char_size.x, 11, fg)

	draw_string(_font, Vector2(size.x / 2.0, start_y - 28), "=== SELECCIONA EL SITIO DE EMBARQUE ===", HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color.GOLD)

	var panel_x: int = int(start_x + map_grid_w * _char_size.x + spacing)
	var panel_y: int = start_y
	var panel_rect := Rect2(panel_x - 6, panel_y - 6, panel_w + 12, map_grid_h * _char_size.y + 12)
	_draw_rounded_rect(Rect2(panel_x - 4, panel_y - 4, panel_w + 8, map_grid_h * _char_size.y + 8), Color(0.0, 0.0, 0.0, 0.2), 6)
	_draw_rounded_rect(panel_rect, Color(0.04, 0.03, 0.10, 0.9), 6)
	_draw_rounded_rect(panel_rect, Color(0.40, 0.30, 0.70), 6, false, 1.5)
	draw_rect(Rect2(panel_rect.position.x, panel_rect.position.y + 2, panel_rect.size.x, 3), Color(0.40, 0.30, 0.70, 0.6), true)

	var py: int = panel_y + 20
	draw_string(_font, Vector2(panel_x + 18, py), "DATOS DE LA REGIÓN", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.GOLD)
	draw_line(Vector2(panel_x + 18, py + 4), Vector2(panel_x + panel_w - 18, py + 4), Color(0.4, 0.3, 0.6, 0.6), 1.0)
	py += int(line_h * 1.55)

	var cur_biome: String = str(main_node.world_gen.biome_map[cursor.y][cursor.x])
	var cur_elev: int = int(main_node.world_gen.elevation_map[cursor.y][cursor.x])
	var cur_aquifer: bool = int(main_node.world_gen.aquifer_map[cursor.y][cursor.x]) != 0
	var cur_magma: bool = int(main_node.world_gen.magma_map[cursor.y][cursor.x]) != 0
	var cur_sav: float = float(main_node.world_gen.savagery_map[cursor.y][cursor.x])
	var cur_evil: float = float(main_node.world_gen.evil_map[cursor.y][cursor.x])
	var cur_site: Dictionary = main_node.world_gen.get_site_at(cursor.x, cursor.y)
	var sav_str: String = "Dócil" if cur_sav < 0.33 else "Salvaje" if cur_sav > 0.66 else "Neutral"
	var evil_str: String = "Benigno" if cur_evil < 0.33 else "Maligno" if cur_evil > 0.66 else "Neutral"
	var water_str: String = "Sin cauce"
	if main_node.world_gen.is_lake(cursor.x, cursor.y):
		water_str = "Lago"
	elif main_node.world_gen.is_river(cursor.x, cursor.y):
		water_str = "Río orden %d" % main_node.world_gen.get_river_order(cursor.x, cursor.y)
	var route_str: String = "Ninguna"
	if main_node.world_gen.is_road(cursor.x, cursor.y):
		route_str = "Puente" if int(main_node.world_gen.road_map[cursor.y][cursor.x]) == 2 else "Camino"

	var landmass_id: int = main_node.world_gen.get_landmass_id(cursor.x, cursor.y)
	var landmass_text: String = "Océano"
	if landmass_id >= 0:
		landmass_text = "#%d · %d regiones" % [landmass_id, main_node.world_gen.get_landmass_size(landmass_id)]
	var details: Array = [
		["Coordenada", "[%d, %d]" % [cursor.x, cursor.y], Color.WHITE],
		["Bioma", _world_label(cur_biome), Color(0.55, 0.85, 0.55)],
		["Elevación", "%d m" % int(cur_elev * 65), Color.WHITE],
		["Masa terrestre", landmass_text, Color("#c7b38a")],
		["Agua", water_str, Color("#67baf0")],
		["Ruta", route_str, Color("#e2c67d")],
		["Acuífero", "Sí" if cur_aquifer else "No", Color(0.4, 0.6, 1.0) if cur_aquifer else Color.GRAY],
		["Magma profundo", "Sí" if cur_magma else "No", Color(1.0, 0.4, 0.1) if cur_magma else Color.GRAY],
		["Salvajismo", sav_str, Color(1.0, 0.6, 0.2) if cur_sav > 0.66 else Color.WHITE],
		["Alineación", evil_str, Color(1.0, 0.3, 0.3) if cur_evil > 0.66 else Color(0.4, 0.9, 0.4) if cur_evil < 0.33 else Color.WHITE]
	]
	if not cur_site.is_empty():
		details.insert(1, ["Asentamiento", str(cur_site.get("name", "Sitio")), Color("#ffe79a")])

	for detail_variant in details:
		var detail: Array = detail_variant
		draw_string(_font, Vector2(panel_x + 18, py), str(detail[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.65, 0.6, 0.75))
		draw_string(_font, Vector2(panel_x + panel_w - 18, py), str(detail[1]), HORIZONTAL_ALIGNMENT_RIGHT, panel_w - 150, 9, detail[2])
		py += int(line_h * 1.12)

	py += 2
	draw_string(_font, Vector2(panel_x + 18, py), "CIVILIZACIONES CERCANAS", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.GOLD)
	py += int(line_h * 1.18)
	var nearby_civs: Array = _nearest_world_civilizations(main_node.world_gen, cursor, 3)
	for entry_variant in nearby_civs:
		var entry: Dictionary = entry_variant
		var civ: Dictionary = entry["civ"]
		var race: String = str(civ.get("race", "human"))
		var race_color: Color = Color("#d2b48c")
		match race:
			"dwarf": race_color = Color("#d7c28b")
			"elf": race_color = Color("#77d987")
			"goblin": race_color = Color("#df6d6d")
			"human": race_color = Color("#8fc8ef")
		var civ_name: String = str(civ.get("name", "Civilización"))
		draw_string(_font, Vector2(panel_x + 18, py), civ_name, HORIZONTAL_ALIGNMENT_LEFT, panel_w - 105, 8, race_color)
		draw_string(_font, Vector2(panel_x + panel_w - 18, py), "%d reg." % roundi(float(entry["distance"])), HORIZONTAL_ALIGNMENT_RIGHT, -1, 8, Color(0.72, 0.68, 0.80))
		py += int(line_h * 1.0)

	var minimap_size: int = 120
	var minimap_x: int = panel_x + int((panel_w - minimap_size) / 2)
	var minimap_y: int = panel_y + int(map_grid_h * _char_size.y) - minimap_size - 8
	var minimap_rect := Rect2(minimap_x - 3, minimap_y - 3, minimap_size + 6, minimap_size + 6)
	_draw_rounded_rect(minimap_rect, Color(0.01, 0.01, 0.03, 0.8), 4)
	_draw_rounded_rect(minimap_rect, Color(0.40, 0.30, 0.70), 4, false, 1.5)
	var world_texture: Texture2D = _ensure_world_minimap_texture(main_node.world_gen)
	if world_texture != null:
		draw_texture_rect(world_texture, Rect2(minimap_x, minimap_y, minimap_size, minimap_size), false)

	for site_variant in main_node.world_gen.sites:
		if not site_variant is Dictionary:
			continue
		var minimap_site: Dictionary = site_variant
		var sx: float = float(minimap_site.get("x", 0)) / maxf(1.0, float(map_w - 1))
		var sz: float = float(minimap_site.get("z", 0)) / maxf(1.0, float(map_h - 1))
		var site_pos := Vector2(minimap_x + sx * minimap_size, minimap_y + sz * minimap_size)
		var minimap_ruined: bool = str(minimap_site.get("site_type", "")).begins_with("ruina") or bool(minimap_site.get("is_sacked", false))
		var dot_color: Color = Color("#b85f55") if minimap_ruined else Color("#fff0a4")
		var dot_radius: float = 2.0 if bool(minimap_site.get("is_capital", false)) else 1.0
		draw_circle(site_pos, dot_radius, dot_color)

	var cur_px_x: float = minimap_x + float(cursor.x) / maxf(1.0, float(map_w - 1)) * minimap_size
	var cur_px_y: float = minimap_y + float(cursor.y) / maxf(1.0, float(map_h - 1)) * minimap_size
	var pulse: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.008)
	draw_rect(Rect2(cur_px_x - 2, cur_px_y - 2, 5, 5), Color(1.0, 1.0, 1.0, pulse), true)

	draw_string(_font, Vector2(size.x / 2.0, start_y + total_h + 24), "Flechas: 1 región  |  SHIFT+Flechas: 16 regiones  |  Click minimapa: salto  |  ENTER: embarcar  |  ESC: volver", HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color(0.5, 0.45, 0.6))

func _draw_embark_prepare() -> void:
	# Premium animated background
	_draw_premium_background(size)

	var main_node = get_parent()
	if main_node == null: return

	var line_h = _char_size.y
	var center_x = size.x / 2

	# Title
	draw_string(_font, Vector2(center_x, 35), "=== PREPARATIVOS DE EMBARQUE ===", HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color.GOLD)

	if main_node.embark_prepare_step == 0:
		# Choose Quick vs Custom
		var box_w = 440
		var box_h = 240
		var box_x = center_x - box_w / 2
		var box_y = (size.y - box_h) / 2
		
		# Box con rounded corners
		_draw_rounded_rect(Rect2(box_x - 2, box_y - 2, box_w + 4, box_h + 4), Color(0.0, 0.0, 0.0, 0.25), 8)
		_draw_rounded_rect(Rect2(box_x, box_y, box_w, box_h), Color(0.04, 0.03, 0.10), 8)
		_draw_rounded_rect(Rect2(box_x, box_y, box_w, box_h), Color(0.55, 0.40, 0.90), 8, false, 2.0)
		draw_rect(Rect2(box_x, box_y + 2, box_w, 3), Color(0.55, 0.40, 0.90, 0.6), true)

		var y = box_y + 35
		draw_string(_font, Vector2(center_x, y), "¿Cómo quieres equipar la expedición?", HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color.WHITE)
		y += int(line_h * 2.2)

		var options = [
			"Jugar Ya! (Embarque Rápido)",
			"Preparar Cuidadosamente (Personalizar)"
		]

		for i in range(options.size()):
			var is_sel = (main_node.setting_selected_index == i)
			var color = Color(0.95, 0.85, 1.0) if is_sel else Color(0.60, 0.55, 0.70)
			var prefix = "▸  [ " if is_sel else "   [ "
			var suffix = " ]"
			
			if is_sel:
				_draw_rounded_rect(Rect2(box_x + 20, y - 10, box_w - 40, 24), Color(0.20, 0.14, 0.38, 0.6), 4)
				_draw_rounded_rect(Rect2(box_x + 20, y - 10, box_w - 40, 24), Color(0.45, 0.30, 0.80, 0.8), 4, false, 1.0)

			draw_string(_font, Vector2(center_x, y + 6), prefix + options[i] + suffix, HORIZONTAL_ALIGNMENT_CENTER, -1, 12, color)
			y += int(line_h * 2.0)

		y = box_y + box_h - 35
		draw_string(_font, Vector2(center_x, y), "↑↓: Mover  |  ENTER: Confirmar  |  ESC: Volver al Mapa", HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color(0.45, 0.40, 0.55))

	elif main_node.embark_prepare_step == 1:
		# Custom points allocation
		var box2_w = 780
		var box2_h = 440
		var box2_x = center_x - box2_w / 2
		var box2_y = (size.y - box2_h) / 2 + 15
		
		# Purple/violet glow effect
		draw_rect(Rect2(box2_x - 2, box2_y - 2, box2_w + 4, box2_h + 4), Color(0.45, 0.30, 0.80, 0.5), false, 2.0)
		draw_rect(Rect2(box2_x, box2_y, box2_w, box2_h), Color(0.04, 0.03, 0.10), true)
		draw_rect(Rect2(box2_x, box2_y, box2_w, box2_h), Color(0.55, 0.40, 0.90), false, 1.5)

		# Points count
		draw_string(_font, Vector2(box2_x + 30, box2_y + 30), "PUNTOS DISPONIBLES: %d" % main_node.embark_prepare_points, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.GOLD)

		var skill_keys = main_node.embark_custom_skills.keys()
		var item_keys = main_node.embark_custom_items.keys()
		var total_opts = skill_keys.size() + item_keys.size()

		# Split display: Left column = Skills, Right column = Items
		var y_skills = box2_y + 70
		var y_items = box2_y + 70
		var col_w = box2_w / 2 - 40

		# Draw skills (Indexes 0 to 6)
		draw_string(_font, Vector2(box2_x + 30, y_skills), "Habilidades del Grupo (Exp/Nivel):", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.CYAN)
		y_skills += int(line_h * 1.3)
		for i1 in range(skill_keys.size()):
			var sk_name = skill_keys[i1]
			var val = main_node.embark_custom_skills[sk_name]
			var idx = i1
			var is_sel_skill = (main_node.setting_selected_index == idx)
			var scolor = Color(0.95, 0.85, 1.0) if is_sel_skill else Color(0.70, 0.67, 0.80)
			var sprefix = "▸ " if is_sel_skill else "  "
			
			if is_sel_skill:
				draw_rect(Rect2(box2_x + 20, y_skills - 2, col_w, 18), Color(0.20, 0.14, 0.38, 0.6), true)
				draw_rect(Rect2(box2_x + 20, y_skills - 2, col_w, 18), Color(0.45, 0.30, 0.80, 0.7), false, 1.0)
			
			var bars = ""
			for b in range(5):
				bars += "■" if b < val else "□"
				
			var s_line = "%s%-16s: %s (%d)" % [sprefix, sk_name, bars, val]
			draw_string(_font, Vector2(box2_x + 30, y_skills + 11), s_line, HORIZONTAL_ALIGNMENT_LEFT, col_w, 10, scolor)
			y_skills += int(line_h * 1.4)

		# Draw items (Indexes 7 to 11)
		draw_string(_font, Vector2(box2_x + box2_w/2 + 20, y_items), "Bienes y Herramientas (Cantidad):", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.CYAN)
		y_items += int(line_h * 1.3)
		for i2 in range(item_keys.size()):
			var it_name = item_keys[i2]
			var ival = main_node.embark_custom_items[it_name]
			var iidx = i2 + skill_keys.size()
			var is_sel_item = (main_node.setting_selected_index == iidx)
			var icolor = Color(0.95, 0.85, 1.0) if is_sel_item else Color(0.70, 0.67, 0.80)
			var iprefix = "▸ " if is_sel_item else "  "
			
			if is_sel_item:
				draw_rect(Rect2(box2_x + box2_w/2 + 10, y_items - 2, col_w, 18), Color(0.20, 0.14, 0.38, 0.6), true)
				draw_rect(Rect2(box2_x + box2_w/2 + 10, y_items - 2, col_w, 18), Color(0.45, 0.30, 0.80, 0.7), false, 1.0)
			
			var cost = 1
			if "Ale" in it_name or "Plump Helmet" in it_name and not "Seed" in it_name:
				cost = 2
			elif "Pickaxe" in it_name or "Axe" in it_name:
				cost = 15

			var i_line = "%s%-22s: %3d  (coste %2d)" % [iprefix, it_name, ival, cost]
			draw_string(_font, Vector2(box2_x + box2_w/2 + 20, y_items + 11), i_line, HORIZONTAL_ALIGNMENT_LEFT, col_w, 10, icolor)
			y_items += int(line_h * 1.4)

		# Footer instructions
		var instruct_y = box2_y + box2_h - 35
		draw_string(_font, Vector2(center_x, instruct_y), "↑↓: Mover  |  ←→: Modificar  |  ENTER: Embarcar Expedición  |  ESC: Atrás", HORIZONTAL_ALIGNMENT_CENTER, -1, 11, Color(0.5, 0.45, 0.60))



# =============================================================================
# TUTORIAL OVERLAY — Animated hint cards for new players
# Timer is advanced by the main node calling renderer.tick_tutorial(delta)
# =============================================================================
func tick_tutorial(delta: float) -> void:
	if _tutorial_step < 0 or _tutorial_step >= TUTORIAL_STEPS.size():
		return
	_tutorial_timer += delta
	if _tutorial_timer >= TUTORIAL_DURATION:
		_tutorial_timer = 0.0
		_tutorial_step += 1

func _draw_tutorial_overlay() -> void:
	if _tutorial_step < 0 or _tutorial_step >= TUTORIAL_STEPS.size():
		return

	var step = TUTORIAL_STEPS[_tutorial_step]
	var progress = clampf(_tutorial_timer / TUTORIAL_DURATION, 0.0, 1.0)

	var vp = size
	var card_w = 520
	var card_h = 54
	var card_x = (vp.x - card_w) / 2
	var card_y = vp.y - 110
	var alpha = clampf(_tutorial_timer / 0.5, 0.0, 1.0)

	_draw_rounded_rect(Rect2(card_x, card_y, card_w, card_h),
		Color(0.04, 0.03, 0.10, 0.88 * alpha), 6)
	_draw_rounded_rect(Rect2(card_x, card_y, card_w, card_h),
		Color(0.55, 0.40, 0.90, 0.9 * alpha), 6, false, 1.5)

	# Progress bar (shrinks as time passes)
	var bar_w = card_w * (1.0 - progress)
	draw_rect(Rect2(card_x, card_y + card_h - 3, bar_w, 3),
		Color(0.55, 0.40, 0.90, 0.7 * alpha), true)

	# Icon badge
	var icon_x = card_x + 14
	_draw_rounded_rect(Rect2(icon_x - 4, card_y + 10, 28, 28),
		Color(0.20, 0.14, 0.38, alpha), 4)
	draw_string(_font, Vector2(icon_x + 10, card_y + 30), step["icon"],
		HORIZONTAL_ALIGNMENT_CENTER, 28, 14, Color(0.90, 0.80, 1.0, alpha))

	# Hint text
	var hint_x = card_x + 50
	var hint_y = card_y + 22
	draw_string(_font, Vector2(hint_x, hint_y), step["text"],
		HORIZONTAL_ALIGNMENT_LEFT, card_w - 60, 11, Color(0.88, 0.85, 0.95, alpha))

	# "Consejo N/N" label
	var count_str = "Consejo %d / %d" % [_tutorial_step + 1, TUTORIAL_STEPS.size()]
	draw_string(_font, Vector2(card_x + card_w - 8, card_y + 12), count_str,
		HORIZONTAL_ALIGNMENT_RIGHT, -1, 8, Color(0.45, 0.40, 0.60, alpha))

	# Skip label
	draw_string(_font, Vector2(card_x + card_w - 8, card_y + 24), "T: Saltar",
		HORIZONTAL_ALIGNMENT_RIGHT, -1, 8, Color(0.35, 0.32, 0.50, alpha))

# =============================================================================
# CONTEXT BAR — Always-visible bottom strip showing current active controls
# =============================================================================
func _draw_context_bar() -> void:
	var vp = size
	var bar_h = 18
	var bar_y = vp.y - bar_h

	_draw_rounded_rect(Rect2(0, bar_y, vp.x, bar_h), Color(0.04, 0.03, 0.10, 0.92), 4)
	draw_rect(Rect2(0, bar_y, vp.x, 1), Color(0.30, 0.25, 0.50, 0.8), true)

	var main_nd = get_parent()
	var is_possessed = main_nd != null and main_nd.get("possessed_dwarf") != null
	var desg_mode = ""
	if main_nd != null and main_nd.get("designation") != null:
		desg_mode = main_nd.designation.get_mode_name() if main_nd.designation.has_method("get_mode_name") else ""

	var controls: Array = []
	if _fast_travel_active:
		match _fast_travel_phase:
			0:
				controls = [["↑↓←→", "Destino"], ["TAB", "Viajar"], ["ESC", "Cancelar"]]
			1:
				controls = [["Viajando...", ""]]
			2, 3:
				controls = [["ENTER", "Continuar"], ["ESC", "Cerrar"]]
	elif _dialogue_active:
		controls = [["↑↓", "Tema"], ["ENTER", "Seleccionar"], ["T", "Cerrar"]]
	elif is_possessed:
		controls = [["WASD", "Mover enano"], ["L", "Liberar"], ["ESPACIO", "Pausar"], ["H", "Ayuda"]]
	elif desg_mode != "" and desg_mode != "View" and desg_mode != "Vista":
		controls = [["Clic", "Marcar"], ["ESC", "Cancelar"], ["ESPACIO", "Pausar"], ["H", "Ayuda"]]
	else:
		# Check if there is a talkable entity near the cursor
		var talk_nearby = false
		if world != null and _highlighted_tile.x >= 0:
			for e3 in world.entities:
				var ht2 = _highlighted_tile
				if e3.get("creature_type") == "dwarf" and e3.get("is_alive") != false:
					var d2 = abs(e3.tile_pos.x - ht2.x) + abs(e3.tile_pos.z - ht2.z)
					if d2 <= 2 and e3.tile_pos.y == ht2.y:
						talk_nearby = true
						break
		if talk_nearby:
			controls = [["Flechas", "Cámara"], ["T", "Hablar"], ["F", "Seguir enano"], ["1-6", "Designar"], ["ESPACIO", "Pausar"], ["H", "Ayuda"]]
		else:
			controls = [["Flechas", "Cámara"], ["F", "Seguir enano"], ["1-6", "Designar"], ["ESPACIO", "Pausar"], ["H", "Ayuda"], ["ESC", "Menú"]]

	var cx = 12
	for ctrl in controls:
		var kw = int(ctrl[0].length() * 6 + 10)
		_draw_rounded_rect(Rect2(cx, bar_y + 3, kw, bar_h - 6), Color(0.16, 0.13, 0.28), 3)
		_draw_rounded_rect(Rect2(cx, bar_y + 3, kw, bar_h - 6), Color(0.38, 0.32, 0.60), 3, false, 1.0)
		draw_string(_font, Vector2(cx + kw / 2, bar_y + bar_h - 4), ctrl[0],
			HORIZONTAL_ALIGNMENT_CENTER, kw, 8, Color(0.90, 0.88, 1.0))
		cx += kw + 4
		# Label
		draw_string(_font, Vector2(cx, bar_y + bar_h - 4), ctrl[1],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.50, 0.47, 0.62))
		cx += int(ctrl[1].length() * 5.5 + 16)

func _draw_loading_playing_screen() -> void:
	_draw_premium_background(size)

	var main_node = get_parent()
	if main_node == null: return

	var line_h = int(_char_size.y)
	var center_x = size.x / 2

	var box_w = 640
	var box_h = 260
	var box_x = center_x - box_w / 2
	var box_y = (size.y - box_h) / 2
	
	draw_rect(Rect2(box_x, box_y, box_w, box_h), Color(0.0, 0.04, 0.01, 0.9), true)
	_draw_dashed_border(Rect2(box_x, box_y, box_w, box_h), Color(0.0, 2.5, 0.0), 4.0)

	var y = box_y + 35
	var pulse = 0.8 + 0.2 * sin(Time.get_ticks_msec() * 0.005)
	draw_string(_font, Vector2(center_x, y), "◆ DESEMBARCANDO EN %s ◆" % main_node.world_name.to_upper(), HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color(0.0, 2.5 * pulse, 0.0))
	y += int(line_h * 2.0)

	var pct = main_node.load_progress
	var bar_w = 480
	var bar_h = 18
	var bar_x = center_x - bar_w / 2
	
	draw_rect(Rect2(bar_x, y, bar_w, bar_h), Color(0.0, 0.1, 0.02), true)
	draw_rect(Rect2(bar_x, y, bar_w, bar_h), Color(0.0, 1.2, 0.0), false, 1.0)
	
	if pct > 0.0:
		draw_rect(Rect2(bar_x + 2, y + 2, (bar_w - 4) * pct, bar_h - 4), Color(0.0, 2.5, 0.0), true)
		
	var pct_str = "%d%%" % int(pct * 100.0)
	draw_string(_font, Vector2(center_x, y + 14), pct_str, HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color(0.0, 0.0, 0.0) if pct > 0.5 else Color(0.0, 2.5, 0.0))
	y += int(line_h * 2.5)

	var spinner = ["▖", "▘", "▝", "▗"][int(Time.get_ticks_msec() / 120) % 4]
	var status_text = "❯ %s... %s" % [main_node.load_status, spinner]
	draw_string(_font, Vector2(center_x, y), status_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 11, Color(0.0, 2.5, 0.0))

func _draw_dialogue_overlay() -> void:
	if not _dialogue_active:
		return
	var vw = view_width
	var vh = view_height
	var border_x = _draw_border(vw, vh)

	var box_x = border_x + 10
	var box_y = 20
	var box_w = (vw - 2) * _char_size.x - 20
	var box_h = (vh - 2) * _char_size.y - 40

	if box_w <= 0 or box_h <= 0:
		return

	var rad = 8
	_draw_rounded_rect(Rect2(box_x + 4, box_y + 4, box_w, box_h), Color(0.0, 0.0, 0.0, 0.25), rad)
	_draw_rounded_rect(Rect2(box_x, box_y, box_w, box_h), Color(0.03, 0.03, 0.08, 0.97), rad)
	_draw_rounded_rect(Rect2(box_x, box_y, box_w, box_h), Color(0.35, 0.25, 0.55, 0.7), rad, false, 2.0)
	draw_rect(Rect2(box_x, box_y + 2, box_w, 3), Color(0.45, 0.35, 0.65, 0.6), true)

	var lh = int(_char_size.y)
	var y = box_y + 10
	var name_col = Color(0.85, 0.72, 0.20)

	# Title with NPC name
	draw_string(_font, Vector2(box_x + 10, y), "== DIALOGO: %s ==" % _dialogue_target_name,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, name_col)
	y += int(lh * 1.8)

	# Greeting
	draw_string(_font, Vector2(box_x + 10, y), _dialogue_greeting,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.80, 0.78, 0.90))
	y += int(lh * 1.5)

	# Separator
	draw_line(Vector2(box_x + 10, y), Vector2(box_x + box_w - 10, y), Color(0.35, 0.28, 0.45), 1.0)
	y += int(lh * 0.8)

	match _dialogue_state:
		1:  # TOPIC_SELECT
			draw_string(_font, Vector2(box_x + 10, y), "SELECCIONA UN TEMA:",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.55, 0.72, 0.90))
			y += int(lh * 1.5)
			for i in range(_dialogue_topics.size()):
				var topic = _dialogue_topics[i]
				var is_sel = (i == _dialogue_topic_selected)
				var prefix = "▸ " if is_sel else "  "
				var col = Color(0.90, 0.85, 1.0) if is_sel else Color(0.55, 0.50, 0.65)
				var bg = Color(0.12, 0.09, 0.20) if is_sel else Color(0, 0, 0, 0)
				if is_sel:
					draw_rect(Rect2(box_x + 8, y - 2, box_w - 16, lh + 4), bg, true)
				draw_string(_font, Vector2(box_x + 16, y + lh), "%s %s %s" % [prefix, topic.get("icon", ""), topic.get("label", "")],
					HORIZONTAL_ALIGNMENT_LEFT, -1, 11, col)
				y += int(lh * 1.3)

			draw_line(Vector2(box_x + 10, y), Vector2(box_x + box_w - 10, y), Color(0.25, 0.20, 0.35), 1.0)
			y += int(lh * 0.6)
			draw_string(_font, Vector2(box_x + 10, y + lh), "Presiona T para cerrar",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.40, 0.38, 0.50))

		2:  # SHOW_RESPONSE
			draw_string(_font, Vector2(box_x + 10, y), "RESPUESTA:",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.50, 0.85, 0.50))
			y += int(lh * 1.5)

			# Draw response text with word wrap
			var response_lines = _wrap_text(_dialogue_response, int(box_w / 7.5))
			for rl in response_lines:
				draw_string(_font, Vector2(box_x + 10, y + lh), rl,
					HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.75, 0.73, 0.85))
				if y + lh > box_y + box_h - 30:
					draw_string(_font, Vector2(box_x + 10, y + lh + 4), "...",
						HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.40, 0.38, 0.50))
					break
				y += int(lh * 1.1)

			draw_string(_font, Vector2(box_x + 10, box_y + box_h - 14),
				"T = Volver / Cerrar",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.40, 0.38, 0.50))

func _wrap_text(text: String, max_chars: int) -> Array:
	var lines: Array = []
	if text.length() <= max_chars:
		lines.append(text)
		return lines
	var words = text.split(" ")
	var current_line = ""
	for word in words:
		if current_line.length() + word.length() + 1 > max_chars:
			if current_line != "":
				lines.append(current_line)
			current_line = word
		else:
			if current_line != "":
				current_line += " "
			current_line += word
	if current_line != "":
		lines.append(current_line)
	return lines


func _draw_fast_travel_overlay() -> void:
	if not _fast_travel_active:
		return
	var vw = view_width
	var vh = view_height
	var border_x = _draw_border(vw, vh)
	match _fast_travel_phase:
		0:
			_draw_fast_travel_selection(border_x, vw, vh)
		1:
			_draw_fast_travel_traveling(border_x, vw, vh)
		2:
			_draw_fast_travel_encounter(border_x, vw, vh)
		3:
			_draw_fast_travel_complete(border_x, vw, vh)
	if _fast_travel_phase == 0:
		var cam_x = camera_pos.x - view_width / 2
		var cam_z = camera_pos.z - view_height / 2
		var sx = _fast_travel_dest_x - cam_x
		var sz = _fast_travel_dest_z - cam_z
		if sx >= 0 and sx < view_width and sz >= 0 and sz < view_height:
			var px = border_x + int(sx * _char_size.x)
			var py = int(sz * _char_size.y)
			var cross_color = Color(0.0, 1.0, 0.0, 0.8 + sin(float(_dwarf_animation_tick) * 0.05) * 0.2)
			draw_line(Vector2(px - 6, py), Vector2(px + 6, py), cross_color, 2.0)
			draw_line(Vector2(px, py - 6), Vector2(px, py + 6), cross_color, 2.0)
			draw_rect(Rect2(px - _char_size.x/2, py - _char_size.y/2, _char_size.x, _char_size.y), Color(0, 1, 0, 0.15), true)

func _draw_fast_travel_selection(border_x: int, vw: int, vh: int) -> void:
	var box_x = border_x + 10
	var box_y = 10
	var box_w = (vw - 2) * _char_size.x - 20
	var box_h = 160
	var lh = int(_char_size.y)
	draw_rect(Rect2(box_x - 5, box_y - 5, box_w + 10, box_h + 10), Color(0.03, 0.03, 0.08, 0.95), true)
	draw_rect(Rect2(box_x - 5, box_y - 5, box_w + 10, box_h + 10), Color(0.25, 0.40, 0.25, 0.8), false, 1.5)
	var y = box_y + 10
	draw_string(_font, Vector2(box_x + 10, y), ">= VIAJE RAPIDO +=", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.55, 0.85, 0.55))
	y += int(lh * 1.8)
	draw_string(_font, Vector2(box_x + 10, y), "Usa las FLECHAS para mover el destino.", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.70, 0.70, 0.80))
	y += int(lh * 1.3)
	var biome_name = _fast_travel_biome
	if biome_name != "":
		var display_name = DFWorld.BIOME_NAMES.get(biome_name, biome_name.capitalize())
		draw_string(_font, Vector2(box_x + 10, y), "Bioma destino: %s" % display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.50, 0.85, 0.50))
		y += int(lh * 1.3)
	draw_string(_font, Vector2(box_x + 10, y), "Distancia: %d pasos" % _fast_travel_distance, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.75, 0.75, 0.85))
	y += int(lh * 1.3)
	draw_string(_font, Vector2(box_x + 10, y), "Coordenadas: [%d, %d]" % [_fast_travel_dest_x, _fast_travel_dest_z], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.60, 0.60, 0.70))
	y += int(lh * 1.5)
	draw_line(Vector2(box_x + 10, y), Vector2(box_x + box_w - 10, y), Color(0.25, 0.30, 0.25), 1.0)
	y += int(lh * 0.6)
	draw_string(_font, Vector2(box_x + 10, y + lh), "FLECHAS = Mover destino | TAB = Viajar | ESC = Cancelar", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.45, 0.45, 0.55))

func _draw_fast_travel_traveling(border_x: int, vw: int, vh: int) -> void:
	var box_x = border_x + 10
	var box_y = vh * int(_char_size.y) / 2 - 50
	var box_w = (vw - 2) * _char_size.x - 20
	var box_h = 80
	var lh = int(_char_size.y)
	draw_rect(Rect2(box_x - 5, box_y - 5, box_w + 10, box_h + 10), Color(0.02, 0.02, 0.06, 0.95), true)
	draw_rect(Rect2(box_x - 5, box_y - 5, box_w + 10, box_h + 10), Color(0.30, 0.30, 0.45, 0.8), false, 1.5)
	var y = box_y + 10
	draw_string(_font, Vector2(box_x + 10, y), "VIAJANDO...", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.55, 0.85, 0.55))
	y += int(lh * 1.6)
	var bar_w = box_w - 40
	var bar_h = 14
	var pct = clampf(_fast_travel_progress, 0.0, 1.0)
	draw_rect(Rect2(box_x + 10, y, bar_w, bar_h), Color(0.05, 0.05, 0.10), true)
	draw_rect(Rect2(box_x + 10, y, bar_w * pct, bar_h), Color(0.3, 0.8, 0.4), true)
	draw_rect(Rect2(box_x + 10, y, bar_w, bar_h), Color(0.35, 0.30, 0.55, 0.6), false, 1.0)
	y += int(lh * 1.5)
	draw_string(_font, Vector2(box_x + box_w / 2, y + lh), "%.0f%%" % (pct * 100), HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color(0.75, 0.75, 0.85))

func _draw_fast_travel_encounter(border_x: int, vw: int, vh: int) -> void:
	_draw_fast_travel_message_box(border_x, vw, vh, Color(0.30, 0.25, 0.15))

func _draw_fast_travel_complete(border_x: int, vw: int, vh: int) -> void:
	_draw_fast_travel_message_box(border_x, vw, vh, Color(0.15, 0.30, 0.15))

func _draw_fast_travel_message_box(border_x: int, vw: int, vh: int, accent: Color) -> void:
	var box_x = border_x + 10
	var box_y = vh * int(_char_size.y) / 3
	var box_w = (vw - 2) * _char_size.x - 20
	var box_h = vh * int(_char_size.y) / 3
	var lh = int(_char_size.y)
	_draw_rounded_rect(Rect2(box_x, box_y, box_w, box_h), Color(0.0, 0.0, 0.0, 0.2), 8)
	_draw_rounded_rect(Rect2(box_x - 5, box_y - 5, box_w + 10, box_h + 10), Color(0.02, 0.02, 0.06, 0.95), 8)
	_draw_rounded_rect(Rect2(box_x - 5, box_y - 5, box_w + 10, box_h + 10), accent, 8, false, 2.0)
	draw_rect(Rect2(box_x - 5, box_y - 3, box_w + 10, 3), accent, true)
	var y = box_y + 15
	var lines = _wrap_text(_fast_travel_current_message, int((box_w - 20) / 7.5))
	for ln in lines:
		draw_string(_font, Vector2(box_x + 15, y + lh), ln, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.80, 0.78, 0.85))
		y += int(lh * 1.2)
	draw_string(_font, Vector2(box_x + 15, box_y + box_h - 14), "ENTER = Continuar | ESC = Cerrar", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.40, 0.40, 0.50))



# ---- Quest Log Overlay ----
func _draw_quest_log_overlay() -> void:
	var vw = int(size.x)
	var vh = int(size.y)
	var border_x = int(vw * 0.15)
	var panel_w = int(vw * 0.7)
	var panel_h = int(vh * 0.75)
	var panel_x = border_x
	var panel_y = int(vh * 0.08)
	var rad = 8
	
	_draw_rounded_rect(Rect2(panel_x + 4, panel_y + 4, panel_w, panel_h), Color(0.0, 0.0, 0.0, 0.25), rad)
	_draw_rounded_rect(Rect2(panel_x, panel_y, panel_w, panel_h), Color(0.02, 0.02, 0.08, 0.92), rad)
	_draw_rounded_rect(Rect2(panel_x, panel_y, panel_w, panel_h), Color(0.4, 0.3, 0.15, 0.8), rad, false, 2.0)
	draw_rect(Rect2(panel_x, panel_y + 2, panel_w, 3), Color(0.6, 0.45, 0.2, 0.8), true)
	
	draw_string(_font, Vector2(panel_x + 14, panel_y + 26), "REGISTRO DE MISIONES", HORIZONTAL_ALIGNMENT_LEFT, panel_w - 20, 16, Color(1.0, 0.8, 0.3))
	
	var header = "Activas: %d  |  Completadas: %d" % [_quest_active_count, _quest_completed_count]
	draw_string(_font, Vector2(panel_x + 14, panel_y + 50), header, HORIZONTAL_ALIGNMENT_LEFT, panel_w - 20, 14, Color(0.8, 0.8, 0.8))
	
	var content_y = panel_y + 68
	var line_h = 20
	var idx = 0
	
	if _quest_active_quests.size() > 0:
		draw_string(_font, Vector2(panel_x + 14, content_y), "ACTIVAS", HORIZONTAL_ALIGNMENT_LEFT, panel_w - 24, 14, Color(0.6, 1.0, 0.6))
		draw_line(Vector2(panel_x + 14, content_y + 4), Vector2(panel_x + panel_w - 14, content_y + 4), Color(0.3, 0.5, 0.3, 0.4), 1.0)
		content_y += line_h
		for q in _quest_active_quests:
			if content_y > panel_y + panel_h - 24:
				break
			var is_selected = idx == _quest_selected
			var type_name = "?"
			var qtype = q.get("type", -1)
			match qtype:
				0: type_name = "Eliminar"
				1: type_name = "Recolectar"
				2: type_name = "Explorar"
				3: type_name = "Construir"
				4: type_name = "Entregar"
			var ttl = q.get("title", "?")
			var tgt = q.get("target_count", 0)
			var cur = q.get("current_count", 0)
			var line_color = Color(0.9, 0.9, 0.9)
			if is_selected:
				_draw_rounded_rect(Rect2(panel_x + 6, content_y - 14, panel_w - 12, line_h), Color(0.25, 0.25, 0.4, 0.5), 4)
				line_color = Color(1.0, 1.0, 0.5)
			var line_str = "%s - %s [%d/%d]" % [type_name, ttl, cur, tgt]
			draw_string(_font, Vector2(panel_x + 16, content_y), line_str, HORIZONTAL_ALIGNMENT_LEFT, panel_w - 40, 13, line_color)
			content_y += line_h
			idx += 1
	else:
		draw_string(_font, Vector2(panel_x + 14, content_y + 4), "(No hay misiones activas)", HORIZONTAL_ALIGNMENT_LEFT, panel_w - 30, 13, Color(0.6, 0.6, 0.6))
	
	if _quest_completed_count > 0 and content_y < panel_y + panel_h - 30:
		content_y += 16
		draw_string(_font, Vector2(panel_x + 14, content_y), "COMPLETADAS (%d)" % _quest_completed_count, HORIZONTAL_ALIGNMENT_LEFT, panel_w - 24, 14, Color(0.6, 0.6, 1.0))
		draw_line(Vector2(panel_x + 14, content_y + 4), Vector2(panel_x + panel_w - 14, content_y + 4), Color(0.3, 0.3, 0.5, 0.4), 1.0)
	
	draw_string(_font, Vector2(panel_x + 14, panel_y + panel_h - 6), "Flechas: Navegar  |  J/ESC: Cerrar", HORIZONTAL_ALIGNMENT_LEFT, panel_w - 20, 12, Color(0.6, 0.6, 0.6))
func _draw_quest_notification() -> void:
	if _quest_notification == "":
		return
	var vw = int(size.x)
	var vh = int(size.y)
	var notif_w = int(vw * 0.5)
	var notif_x = int((vw - notif_w) / 2)
	var notif_y = 4
	var notif_h = 28
	
	_draw_rounded_rect(Rect2(notif_x, notif_y, notif_w, notif_h), Color(0.0, 0.0, 0.0, 0.7), 5)
	_draw_rounded_rect(Rect2(notif_x, notif_y, notif_w, notif_h), Color(0.6, 0.5, 0.2, 0.9), 5, false, 1.5)
	draw_string(_font, Vector2(notif_x + 8, notif_y + 18), _quest_notification, HORIZONTAL_ALIGNMENT_LEFT, notif_w - 16, 14, Color(1.0, 0.9, 0.5))

func _draw_premium_background(vp: Vector2) -> void:
	# 1. Dark deep night sky background
	draw_rect(Rect2(0, 0, vp.x, vp.y), Color(0.01, 0.01, 0.03), true)
	
	# 2. Glowing organic space nebulae (Soft circular spots)
	var time_ticks = Time.get_ticks_msec()
	# Left spot (Pulsating Blue-Violet)
	var pulse_size1 = 180.0 + 15.0 * sin(time_ticks * 0.001)
	draw_circle(Vector2(vp.x * 0.2, vp.y * 0.3), pulse_size1, Color(0.18, 0.06, 0.36, 0.12))
	# Right spot (Pulsating Deep Purple)
	var pulse_size2 = 240.0 + 20.0 * cos(time_ticks * 0.0008)
	draw_circle(Vector2(vp.x * 0.8, vp.y * 0.7), pulse_size2, Color(0.04, 0.12, 0.32, 0.14))
	# Center soft gold highlight
	var pulse_size3 = 130.0 + 10.0 * sin(time_ticks * 0.0015)
	draw_circle(Vector2(vp.x * 0.5, vp.y * 0.45), pulse_size3, Color(0.24, 0.16, 0.05, 0.06))
	
	# 3. Dynamic starfield (Twinkling stars)
	var rand_gen = RandomNumberGenerator.new()
	rand_gen.seed = 98765 # Deterministic positions
	for s_idx in range(45):
		var star_x = rand_gen.randf() * vp.x
		var star_y = rand_gen.randf() * vp.y
		# Twinkle effect
		var offset_phase = rand_gen.randf() * 12.0
		var star_alpha = 0.25 + 0.45 * sin(time_ticks * 0.0018 + offset_phase)
		var star_color = Color(0.85, 0.90, 1.0, star_alpha)
		draw_circle(Vector2(star_x, star_y), rand_gen.randf_range(0.8, 1.5), star_color)

# ============================================================================
# ROUNDED RECT HELPER
# ============================================================================
func _draw_rounded_rect(rect: Rect2, color: Color, radius: float, filled: bool = true, width: float = 1.0) -> void:
	var r = mini(radius, mini(rect.size.x, rect.size.y) / 2.0)
	if not filled:
		var inset = Rect2(rect.position.x + r, rect.position.y, rect.size.x - 2.0 * r, rect.size.y)
		var topbot = Rect2(rect.position.x, rect.position.y + r, rect.size.x, rect.size.y - 2.0 * r)
		draw_rect(inset, color, false, width)
		draw_rect(topbot, color, false, width)
		# Outline arcs (simplified: just draw small corner markers)
		draw_rect(Rect2(rect.position.x + r, rect.position.y, r, r), color, false, width)
		draw_rect(Rect2(rect.position.x + rect.size.x - 2.0 * r, rect.position.y, r, r), color, false, width)
		draw_rect(Rect2(rect.position.x + r, rect.position.y + rect.size.y - r, r, r), color, false, width)
		draw_rect(Rect2(rect.position.x + rect.size.x - 2.0 * r, rect.position.y + rect.size.y - r, r, r), color, false, width)
		return
	var inner = Rect2(rect.position.x + r, rect.position.y, rect.size.x - 2.0 * r, rect.size.y)
	var topbot_fill = Rect2(rect.position.x, rect.position.y + r, rect.size.x, rect.size.y - 2.0 * r)
	draw_rect(inner, color, true)
	draw_rect(topbot_fill, color, true)
	draw_circle(Vector2(rect.position.x + r, rect.position.y + r), r, color)
	draw_circle(Vector2(rect.position.x + rect.size.x - r, rect.position.y + r), r, color)
	draw_circle(Vector2(rect.position.x + r, rect.position.y + rect.size.y - r), r, color)
	draw_circle(Vector2(rect.position.x + rect.size.x - r, rect.position.y + rect.size.y - r), r, color)

func _draw_curved_line(x1: float, y1: float, x2: float, y2: float, color: Color, width: float = 1.0) -> void:
	var mid_y = (y1 + y2) / 2.0
	var steps = 12
	var prev = Vector2(x1, y1)
	for i in range(1, steps + 1):
		var t = float(i) / float(steps)
		var t_inv = 1.0 - t
		var cx = x1 * t_inv + x2 * t
		var cy = y1 * t_inv + y2 * t + 4.0 * t * t_inv * (mid_y - y1)  # slight curve
		draw_line(prev, Vector2(cx, cy), color, width)
		prev = Vector2(cx, cy)

func _draw_dashed_border(rect: Rect2, color: Color, step: float = 6.0) -> void:
	var x = rect.position.x
	while x < rect.end.x:
		var draw_w = minf(step, rect.end.x - x)
		draw_line(Vector2(x, rect.position.y), Vector2(x + draw_w, rect.position.y), color, 1.5)
		draw_line(Vector2(x, rect.end.y), Vector2(x + draw_w, rect.end.y), color, 1.5)
		x += step * 2.0
	var y = rect.position.y
	while y < rect.end.y:
		var draw_h = minf(step, rect.end.y - y)
		draw_line(Vector2(rect.position.x, y), Vector2(rect.position.x, y + draw_h), color, 1.5)
		draw_line(Vector2(rect.end.x, y), Vector2(rect.end.x, y + draw_h), color, 1.5)
		y += step * 2.0
