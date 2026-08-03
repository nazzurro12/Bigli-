from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[1]
PATHFINDING = (ROOT / "df_mode" / "df_pathfinding.gd").read_text(encoding="utf-8")
DWARF = (ROOT / "df_mode" / "df_dwarf.gd").read_text(encoding="utf-8")
JOB = (ROOT / "df_mode" / "df_job.gd").read_text(encoding="utf-8")
MAIN = (ROOT / "df_mode" / "df_main.gd").read_text(encoding="utf-8")
WORKSHOP = (ROOT / "df_mode" / "df_workshop.gd").read_text(encoding="utf-8")


class LaborPipelineContracts(unittest.TestCase):
    def test_reconstructed_path_removes_actor_origin(self):
        function = re.search(
            r"static func _reconstruct_path\b.*?(?=\nstatic func |\Z)",
            PATHFINDING,
            re.S,
        )
        self.assertIsNotNone(function)
        self.assertIn("p.pop_front()", function.group(0))

    def test_physical_jobs_use_adjacent_work_paths(self):
        self.assertIn("static func find_adjacent_path", PATHFINDING)
        self.assertIn(
            "DFPathfinding.find_adjacent_path(world, tile_pos, selected_job.tile_pos, true)",
            DWARF,
        )
        self.assertIn("selected_job.approach_pos", DWARF)

    def test_job_selection_checks_profession_skill_and_reachability(self):
        self.assertIn("func _profession_can_do_job", DWARF)
        self.assertIn("job_candidate.can_dwarf_perform(self)", DWARF)
        self.assertIn("mini(8, ranked_jobs.size())", DWARF)
        self.assertIn("retry_after_tick", JOB)
        self.assertIn("path_failure_count", JOB)

    def test_blocked_job_is_released_instead_of_permanently_owned(self):
        release = re.search(
            r"func _release_current_job\b.*?(?=\nfunc |\Z)",
            DWARF,
            re.S,
        )
        self.assertIsNotNone(release)
        self.assertIn("DFJob.JobState.UNASSIGNED", release.group(0))
        self.assertIn("assigned_dwarf_id = -1", release.group(0))
        self.assertIn("retry_after_tick", release.group(0))

    def test_furniture_recipes_consume_real_wood(self):
        for recipe_id in ["bed", "wood_table", "wood_chair"]:
            self.assertIn(f'"id": "{recipe_id}"', WORKSHOP)
        self.assertGreaterEqual(WORKSHOP.count('"material": ["wood"]'), 3)

    def test_crafted_furniture_gets_functional_flags(self):
        self.assertIn('produced.is_bed = furniture_kind == "bed"', DWARF)
        self.assertIn('produced.is_table = furniture_kind == "table"', DWARF)
        self.assertIn('produced.is_chair = furniture_kind == "chair"', DWARF)

    def test_colony_queues_missing_furniture_by_population(self):
        self.assertIn("func _queue_needed_colony_furniture", DWARF)
        self.assertIn("var bed_target: int = living_count", DWARF)
        self.assertIn("var chair_target: int = living_count", DWARF)
        self.assertIn('carpentry.queue_recipe("wood_table")', DWARF)

    def test_initial_collection_jobs_never_use_random_coordinates(self):
        self.assertNotIn("var haul_pos = Vector3i", MAIN)
        self.assertIn('_queue_resource_collection_jobs("wood"', MAIN)
        self.assertIn('_queue_resource_collection_jobs("stone"', MAIN)

    def test_collection_follows_the_exact_target_item_id(self):
        self.assertIn("func _find_collection_target_by_id", DWARF)
        self.assertIn('current_job.get_meta("target_item_id", -1)', DWARF)
        self.assertIn('current_job.set_meta("carried_item_id", target_item.id)', DWARF)
        self.assertIn("world.add_entity(carried_item)", DWARF)
        self.assertIn("inventory.erase(carried_item)", DWARF)

    def test_loaded_resources_choose_reachable_stockpile_tiles(self):
        self.assertIn(
            "get_candidate_tiles(world, carried_item.item_type, 8)",
            DWARF,
        )
        self.assertIn('"drop_pos"', DWARF)
        self.assertIn("No existe almacén alcanzable", DWARF)

    def test_workshop_inputs_use_world_tick_and_reachable_paths(self):
        self.assertIn(
            'var current_tick: int = int(world.get_meta("simulation_tick_total", 0))',
            DWARF,
        )
        self.assertIn("Sin insumos alcanzables", DWARF)
        self.assertIn("item_path.duplicate()", DWARF)

    def test_food_hauling_checks_both_pickup_and_storage_routes(self):
        self.assertIn("la provisión no es alcanzable", DWARF)
        self.assertIn("No existe almacén de comida alcanzable", DWARF)
        self.assertIn("best_fs_path", DWARF)


if __name__ == "__main__":
    unittest.main()
