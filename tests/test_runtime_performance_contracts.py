import pathlib
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[1]


class RuntimePerformanceContracts(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.main = (ROOT / "df_mode/df_main.gd").read_text(encoding="utf-8")
        cls.world = (ROOT / "df_mode/df_world.gd").read_text(encoding="utf-8")
        cls.pathfinding = (ROOT / "df_mode/df_pathfinding.gd").read_text(encoding="utf-8")
        cls.dwarf = (ROOT / "df_mode/df_dwarf.gd").read_text(encoding="utf-8")

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

    def test_new_path_requests_are_distributed_without_sliding_existing_paths(self):
        self.assertIn("PATH_REQUEST_BUCKETS: int = 4", self.dwarf)
        self.assertIn("func _path_request_slot_is_due", self.dwarf)
        movement = self.dwarf.split("func _move_toward", 1)[1].split("\nfunc ", 1)[0]
        throttle = movement.index("needs_new_path and not _path_request_slot_is_due")
        movement_timer = movement.index("if move_tick_counter > 0")
        stuck = movement.index("if tile_pos == last_pos")
        path_search = movement.index("DFPathfinding.find_path")
        self.assertLess(throttle, movement_timer)
        self.assertLess(movement_timer, stuck)
        self.assertLess(stuck, path_search)
        self.assertIn("if is_possessed:", self.dwarf)
        self.assertIn('has_meta("is_follower")', self.dwarf)

    def test_item_searches_do_not_scan_every_world_entity(self):
        for method in (
            "_find_nearest_item_on_ground_matching",
            "_find_nearest_item_matching_type",
            "_find_material_on_ground",
            "_execute_store_in_container_job",
            "_find_container_at",
            "_detach_item_from_container",
            "_execute_collect_job",
            "_pick_up_nearby_item_by_types",
            "_pick_up_items",
            "_find_best_item_slot",
        ):
            body = self.dwarf.split("func " + method, 1)[1].split("\nfunc ", 1)[0]
            self.assertNotIn("in world.entities:", body, method)
            self.assertIn("world.items", body, method)

    def test_stockpile_need_search_uses_spatial_item_lookup(self):
        needs = self.dwarf.split("func _satisfy_needs", 1)[1].split("\nfunc ", 1)[0]
        self.assertIn("world.get_items_at(stock_tile)", needs)
        self.assertNotIn("for ent in world.entities", needs)

    def test_social_searches_only_visit_inhabitants(self):
        for method in (
            "_find_nearby_master_for_skill",
            "_try_socialize",
            "tick_social",
            "_try_find_partner",
            "_try_conceive",
            "_give_birth",
            "_get_parent_from_world",
            "_complete_strange_mood",
        ):
            body = self.dwarf.split("func " + method, 1)[1].split("\nfunc ", 1)[0]
            self.assertNotIn("in world.entities:", body, method)
            if method in ("_find_nearby_master_for_skill", "_try_socialize", "tick_social"):
                self.assertIn("world.get_dwarves_near", body, method)
            else:
                self.assertIn("world.dwarves", body, method)

    def test_hunting_uses_creature_and_item_collections(self):
        hunt = self.dwarf.split("func _execute_hunt_job", 1)[1].split("\nfunc ", 1)[0]
        behavior = self.dwarf.split("func _tick_hunting_behavior", 1)[1].split("\nfunc ", 1)[0]
        self.assertNotIn("in world.entities:", hunt)
        self.assertIn("world.creatures", hunt)
        self.assertNotIn("in world.entities:", behavior)
        self.assertIn("world.creatures", behavior)
        self.assertIn("world.items", behavior)

    def test_inhabitant_ai_has_no_general_entity_scans(self):
        self.assertNotIn("in world.entities:", self.dwarf)
        self.assertIn("world.get_items_at(stock_tile)", self.dwarf)
        self.assertIn("world.get_items_at(p)", self.dwarf)

    def test_spatial_queries_use_the_incremental_grid(self):
        for method in ("get_entity_at", "get_items_at", "is_actor_occupied"):
            method_body = self.world.split("func " + method, 1)[1].split("\nfunc ", 1)[0]
            self.assertIn("_rebuild_grid_if_needed()", method_body)


if __name__ == "__main__":
    unittest.main()
