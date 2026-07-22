class_name WorldGenerationSettings
extends Resource
## Configuración persistente usada por cada mundo nuevo.

@export var seed: int = 20260721
@export_enum("Pequeño:128", "Estándar:256", "Grande:512", "Gigantesco:1024") var default_world_size_index: int = 3
@export_range(0.0, 1.0, 0.01) var sea_level: float = 0.30
@export_range(0.0, 2.0, 0.01) var mountain_strength: float = 0.95
@export_range(0.0, 2.0, 0.01) var rainfall: float = 1.0
@export_range(0.25, 3.0, 0.05) var river_density: float = 1.15
@export_range(0.25, 3.0, 0.05) var site_density: float = 1.0
@export_range(0.0, 3.0, 0.01) var tree_density: float = 1.0
@export_range(0.5, 5.0, 0.01) var ore_density: float = 1.0
@export_range(0.0, 1.0, 0.01) var hidden_caves_chance: float = 0.30
@export_range(32, 128, 1) var world_chunk_size: int = 64
@export_range(128, 384, 1) var local_map_size: int = 256
