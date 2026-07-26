import pathlib
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[1]


class RuntimePerformanceContracts(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.main = (ROOT / "df_mode/df_main.gd").read_text(encoding="utf-8")
        cls.world = (ROOT / "df_mode/df_world.gd").read_text(encoding="utf-8")
        cls.pathfinding = (ROOT / "df_mode/df_pathfinding.gd").read_text(encoding="utf-8")

    def test_tick_does_not_force_full_spatial_rebuild(self):
        tick_body = self.main.split("func _tick()", 1)[1].split("\nfunc ", 1)[0]
        self.assertNotIn("world._grid_version = -1", tick_body)
        self.assertIn("func move_entity", self.world)
        self.assertIn("_unindex_entity(entity_value)", self.world)
        self.assertIn("_index_entity(entity_value)", self.world)

    def test_pathfinding_budget_scales_with_distance(self):
        self.assertIn("direct_distance", self.pathfinding)
        self.assertIn("clampi(256 + direct_distance * 48, 512, 4096)", self.pathfinding)
        self.assertNotIn("var max_iter = 5000", self.pathfinding)

    def test_spatial_queries_use_the_incremental_grid(self):
        for method in ("get_entity_at", "get_items_at", "is_actor_occupied"):
            method_body = self.world.split("func " + method, 1)[1].split("\nfunc ", 1)[0]
            self.assertIn("_rebuild_grid_if_needed()", method_body)


if __name__ == "__main__":
    unittest.main()
