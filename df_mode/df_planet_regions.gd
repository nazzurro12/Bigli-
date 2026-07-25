extends RefCounted
class_name DFPlanetRegions

## Conversión pura entre la frontera procedural y el atlas histórico.
## Las coordenadas jugables son firmadas y no tienen borde. El atlas finito solo
## aporta clima, geología e historia mediante una proyección periódica.

static func normalize_region(region: Vector2i, planet_width: int, planet_depth: int) -> Vector2i:
	if planet_width <= 0 or planet_depth <= 0:
		return Vector2i.ZERO
	return region

static func atlas_region(region: Vector2i, planet_width: int, planet_depth: int) -> Vector2i:
	if planet_width <= 0 or planet_depth <= 0:
		return Vector2i.ZERO
	return Vector2i(posmod(region.x, planet_width), posmod(region.y, planet_depth))

static func neighbor(region: Vector2i, direction: Vector2i, planet_width: int, planet_depth: int) -> Vector2i:
	if planet_width <= 0 or planet_depth <= 0:
		return region
	return region + direction

static func can_cross(region: Vector2i, direction: Vector2i, planet_depth: int) -> bool:
	if planet_depth <= 0:
		return false
	return direction != Vector2i.ZERO

static func region_key(region: Vector2i) -> String:
	return "%d:%d" % [region.x, region.y]

static func entry_tile(direction: Vector2i, local_width: int, local_depth: int, margin: int = 3) -> Vector2i:
	var center := Vector2i(local_width / 2, local_depth / 2)
	if direction.x > 0:
		return Vector2i(margin, center.y)
	if direction.x < 0:
		return Vector2i(local_width - margin - 1, center.y)
	if direction.y > 0:
		return Vector2i(center.x, margin)
	if direction.y < 0:
		return Vector2i(center.x, local_depth - margin - 1)
	return center

static func planet_tile(region: Vector2i, local_tile: Vector2i, local_width: int, local_depth: int) -> Vector2i:
	return Vector2i(region.x * local_width + local_tile.x, region.y * local_depth + local_tile.y)
