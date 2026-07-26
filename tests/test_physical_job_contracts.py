import pathlib
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[1]


class PhysicalJobContracts(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.main = (ROOT / "df_mode/df_main.gd").read_text(encoding="utf-8")
        cls.dwarf = (ROOT / "df_mode/df_dwarf.gd").read_text(encoding="utf-8")

    def test_world_exposes_authoritative_clock_to_inhabitants(self):
        self.assertIn('world.set_meta("game_hour", _game_hour)', self.main)
        self.assertIn('world.set_meta("game_minute", _game_minute)', self.main)
        self.assertIn('world.get_meta("game_hour", 12)', self.dwarf)
        self.assertNotIn('world.get_parent() if world.has_method("get_parent")', self.dwarf)

    def test_daily_schedule_matches_the_design(self):
        self.assertIn("hour >= 22 or hour < 6", self.dwarf)
        self.assertIn("hour >= 14 and hour < 22", self.dwarf)
        self.assertIn("not is_sleep_time and not is_recreation_time", self.dwarf)

    def test_sleep_requires_attempting_to_reach_claimed_bed(self):
        sleep = self.dwarf.split("func _try_sleep", 1)[1].split("\nfunc ", 1)[0]
        self.assertIn("_find_unclaimed_bed(world)", sleep)
        self.assertIn("_claim_bed(world, bed_pos)", sleep)
        self.assertIn('current_task = "Yendo a su cama"', sleep)
        self.assertLess(sleep.index("_move_toward(world, preferred_bed)"), sleep.index("is_sleeping = true"))


if __name__ == "__main__":
    unittest.main()
