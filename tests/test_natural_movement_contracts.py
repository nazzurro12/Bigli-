from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
DWARF = (ROOT / "df_mode" / "df_dwarf.gd").read_text(encoding="utf-8")


class NaturalMovementContracts(unittest.TestCase):
    def test_population_starts_on_different_movement_phases(self):
        init = DWARF.split("func _init", 1)[1].split("\nfunc ", 1)[0]
        self.assertIn("move_tick_counter = id % 3", init)

    def test_congestion_waits_before_detouring(self):
        move = DWARF.split("func _move_toward", 1)[1].split("\nfunc ", 1)[0]
        self.assertIn("traffic_wait_ticks += 1", move)
        self.assertIn("if traffic_wait_ticks < 2:", move)
        self.assertNotIn("dirs.shuffle()", move)

    def test_detour_is_deterministic_and_goal_directed(self):
        move = DWARF.split("func _move_toward", 1)[1].split("\nfunc ", 1)[0]
        self.assertIn("dirs.sort_custom", move)
        self.assertIn("score_a", move)
        self.assertIn("score_b", move)
        self.assertIn("world.move_entity(self, alt)", move)


if __name__ == "__main__":
    unittest.main()
