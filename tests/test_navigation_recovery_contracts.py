import pathlib
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[1]


class NavigationRecoveryContracts(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.dwarf = (ROOT / "df_mode/df_dwarf.gd").read_text(encoding="utf-8")

    def test_short_traffic_jams_replan_before_abandoning_work(self):
        move = self.dwarf.split("func _move_toward", 1)[1].split("\nfunc ", 1)[0]
        self.assertIn("path_replan_count += 1", move)
        self.assertIn("if path_replan_count < 2:", move)
        self.assertIn('current_task = "Recalculando ruta (1/2)"', move)
        self.assertLess(
            move.index("if path_replan_count < 2:"),
            move.index('_release_current_job(world, "destino inaccesible después de dos intentos")'),
        )

    def test_successful_movement_resets_replan_failures(self):
        move = self.dwarf.split("func _move_toward", 1)[1].split("\nfunc ", 1)[0]
        moving_branch = move.split("else:", 1)[1]
        self.assertIn("path_replan_count = 0", moving_branch)

    def test_impossible_job_keeps_a_visible_failure_reason(self):
        move = self.dwarf.split("func _move_toward", 1)[1].split("\nfunc ", 1)[0]
        self.assertIn("var abandoned_job: bool = current_job != null", move)
        self.assertIn('_release_current_job(world, "destino inaccesible después de dos intentos")', move)
        final_fallback = move.split("if not abandoned_job and not abandoned_workshop and not abandoned_plan:", 1)[1]
        self.assertIn('current_task = "Sin ruta accesible"', final_fallback)

    def test_bed_failure_is_detected_by_target_not_transient_label(self):
        move = self.dwarf.split("func _move_toward", 1)[1].split("\nfunc ", 1)[0]
        self.assertIn("if preferred_bed.x >= 0 and target == preferred_bed:", move)
        self.assertNotIn('if current_task == "Yendo a su cama":', move)
        self.assertIn('current_task = "Durmiendo sin cama"', move)

    def test_side_step_invalidates_the_old_path(self):
        move = self.dwarf.split("func _move_toward", 1)[1].split("\nfunc ", 1)[0]
        detour = move.split("if not alt_blocked:", 1)[1].split("if not found_alt:", 1)[0]
        self.assertIn("world.move_entity(self, alt)", detour)
        self.assertIn("path.clear()", detour)
        self.assertIn("path_index = 0", detour)
        self.assertIn("has_moved_this_tick = true", detour)
        self.assertIn('stats_tracker["distance_traveled"] += 1', detour)

    def test_navigation_occupancy_uses_the_spatial_index(self):
        move = self.dwarf.split("func _move_toward", 1)[1].split("\nfunc ", 1)[0]
        self.assertIn("world.is_actor_occupied(next_step, self)", move)
        self.assertIn("world.is_actor_occupied(alt, self)", move)
        self.assertNotIn("for ent in world.entities", move)


if __name__ == "__main__":
    unittest.main()
