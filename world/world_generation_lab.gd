@tool
class_name WorldGenerationLab
extends Control
## Laboratorio visual independiente: permite probar proporciones antes de crear una partida.

@export_group("Mapa")
@export var seed := 20260721:
	set(value):
		seed = value
		regenerate_preview()
		_persist_settings()
@export_range(32, 256, 1) var preview_resolution := 128:
	set(value):
		preview_resolution = value
		regenerate_preview()
@export_range(0.0, 1.0, 0.01) var sea_level := 0.30:
	set(value):
		sea_level = value
		regenerate_preview()
		_persist_settings()
@export_range(0.0, 2.0, 0.01) var mountain_strength := 0.75:
	set(value):
		mountain_strength = value
		regenerate_preview()
		_persist_settings()
@export_group("Clima y recursos")
@export_range(0.0, 2.0, 0.01) var rainfall := 1.0:
	set(value):
		rainfall = value
		regenerate_preview()
		_persist_settings()
@export_range(0.0, 3.0, 0.01) var tree_density := 1.0:
	set(value):
		tree_density = value
		regenerate_preview()
		_persist_settings()
@export_range(0.5, 5.0, 0.01) var ore_density := 1.0:
	set(value):
		ore_density = value
		regenerate_preview()
		_persist_settings()
@export_range(0.0, 1.0, 0.01) var hidden_caves_chance := 0.30:
	set(value):
		hidden_caves_chance = value
		regenerate_preview()
		_persist_settings()
@export_tool_button("Generar vista previa") var generate_preview_action = regenerate_preview

var _cells: PackedColorArray = PackedColorArray()
var _settings: WorldGenerationSettings

func _ready() -> void:
	custom_minimum_size = Vector2(680, 680)
	_settings = load("res://world/world_generation_settings.tres") as WorldGenerationSettings
	if _settings != null:
		seed = _settings.seed
		sea_level = _settings.sea_level
		mountain_strength = _settings.mountain_strength
		rainfall = _settings.rainfall
		tree_density = _settings.tree_density
		ore_density = _settings.ore_density
		hidden_caves_chance = _settings.hidden_caves_chance
	regenerate_preview()

func regenerate_preview() -> void:
	if preview_resolution < 1:
		return
	_cells.resize(preview_resolution * preview_resolution)
	for z in range(preview_resolution):
		for x in range(preview_resolution):
			_cells[z * preview_resolution + x] = _biome_color(x, z)
	queue_redraw()

func _draw() -> void:
	if _cells.is_empty():
		return
	var side := minf(size.x, size.y - 90.0)
	var origin := Vector2((size.x - side) * 0.5, 90.0 + (size.y - 90.0 - side) * 0.5)
	var cell_size := side / float(preview_resolution)
	for z in range(preview_resolution):
		for x in range(preview_resolution):
			draw_rect(Rect2(origin + Vector2(x * cell_size, z * cell_size), Vector2(cell_size + 0.25, cell_size + 0.25)), _cells[z * preview_resolution + x])
	draw_rect(Rect2(origin, Vector2(side, side)), Color("#d6d6d6"), false, 2.0)

func _biome_color(x: int, z: int) -> Color:
	var nx := float(x) / float(preview_resolution)
	var nz := float(z) / float(preview_resolution)
	var continent := _noise(nx * 5.0, nz * 5.0, 17) * 0.55 + 0.45
	var ridge := absf(_noise(nx * 12.0, nz * 12.0, 83))
	var elevation := clampf(continent + ridge * 0.30 * mountain_strength, 0.0, 1.0)
	var moisture := clampf((_noise(nx * 7.0, nz * 7.0, 211) * 0.5 + 0.5) * rainfall, 0.0, 1.0)
	var tree_noise := _noise(nx * 28.0, nz * 28.0, 401) * 0.5 + 0.5
	var ore_noise := _noise(nx * 36.0, nz * 36.0, 647) * 0.5 + 0.5
	var cave_noise := _noise(nx * 20.0, nz * 20.0, 919) * 0.5 + 0.5
	if elevation < sea_level:
		return Color("#2458a6")
	if elevation > 0.84:
		return Color("#e7e8e8")
	if cave_noise > 0.94 - hidden_caves_chance * 0.12:
		return Color("#5c486b") # zona con cuevas
	if ore_noise > 0.985 / ore_density:
		return Color("#c99a33") # veta rica
	if moisture < 0.24:
		return Color("#c9b467")
	if moisture > 0.78:
		return Color("#31734a")
	if tree_noise < 0.45 * tree_density:
		return Color("#23613b")
	return Color("#7ca84d")

func _noise(x: float, z: float, salt: int) -> float:
	var xi := int(floor(x * 1000.0))
	var zi := int(floor(z * 1000.0))
	var n := xi * 374761393 + zi * 668265263 + seed * 31 + salt
	n = (n ^ (n >> 13)) * 1274126177
	return float(n & 0x7fffffff) / 1073741823.5 - 1.0

func _persist_settings() -> void:
	if _settings == null:
		return
	_settings.seed = seed
	_settings.sea_level = sea_level
	_settings.mountain_strength = mountain_strength
	_settings.rainfall = rainfall
	_settings.tree_density = tree_density
	_settings.ore_density = ore_density
	_settings.hidden_caves_chance = hidden_caves_chance
	ResourceSaver.save(_settings)
