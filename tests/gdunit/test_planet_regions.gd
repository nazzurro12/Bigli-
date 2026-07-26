class_name TestPlanetRegions
extends GdUnitTestSuite

const PlanetRegions = preload("res://df_mode/df_planet_regions.gd")

func test_neighbor_regions_remain_signed_and_unbounded() -> void:
	var origin := Vector2i.ZERO
	assert_that(PlanetRegions.neighbor(origin, Vector2i.LEFT, 771, 771)).is_equal(Vector2i(-1, 0))
	assert_that(PlanetRegions.neighbor(origin, Vector2i.UP, 771, 771)).is_equal(Vector2i(0, -1))
	assert_bool(PlanetRegions.can_cross(Vector2i(-999, -999), Vector2i.UP, 771)).is_true()

func test_atlas_projection_is_separate_from_playable_coordinates() -> void:
	var projected := PlanetRegions.atlas_region(Vector2i(-1, -1), 771, 771)
	assert_that(projected).is_equal(Vector2i(770, 770))
