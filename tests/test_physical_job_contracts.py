import pathlib
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[1]


class PhysicalJobContracts(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.main = (ROOT / "df_mode/df_main.gd").read_text(encoding="utf-8")
        cls.dwarf = (ROOT / "df_mode/df_dwarf.gd").read_text(encoding="utf-8")
        cls.world = (ROOT / "df_mode/df_world.gd").read_text(encoding="utf-8")

    def test_world_exposes_authoritative_clock_to_inhabitants(self):
        self.assertIn('world.set_meta("game_hour", _game_hour)', self.main)
        self.assertIn('world.set_meta("game_minute", _game_minute)', self.main)
        self.assertIn('world.get_meta("game_hour", 12)', self.dwarf)
        self.assertNotIn('world.get_parent() if world.has_method("get_parent")', self.dwarf)

    def test_daily_schedule_matches_the_design(self):
        self.assertIn("hour >= 22 or hour < 6", self.dwarf)
        self.assertIn("hour >= 14 and hour < 22", self.dwarf)
        self.assertIn("not is_sleep_time and not is_recreation_time", self.dwarf)

    def test_physical_jobs_cannot_bypass_progress(self):
        work = self.dwarf.split("func _work_on_job", 1)[1].split("\nfunc ", 1)[0]
        self.assertIn("not _job_requires_physical_progress", work)
        self.assertIn("task_progress += ", work)
        self.assertIn("if task_progress >= 1.0:", work)
        self.assertLess(work.index("task_progress += "), work.index("_execute_job(world)", work.index("task_progress += ")))
        physical = self.dwarf.split("func _job_requires_physical_progress", 1)[1].split("\nfunc ", 1)[0]
        for job_name in ("DIG", "CHOP_TREE", "BUILD_WALL", "BUILD_FLOOR", "BUILD_WORKSHOP"):
            self.assertIn("DFJob.JobType." + job_name, physical)

    def test_construction_changes_authoritative_tiles(self):
        for method, tile_name in (
            ("build_wall", "CONSTRUCTED_WALL"),
            ("build_floor", "CONSTRUCTED_FLOOR"),
        ):
            body = self.world.split("func " + method, 1)[1].split("\nfunc ", 1)[0]
            self.assertIn("set_tile(pos, TileType." + tile_name + ")", body)
            self.assertIn("set_material(pos, mat_id)", body)
            self.assertIn("return true", body)

    def test_digging_creates_a_real_floor_and_resource(self):
        dig = self.world.split("func dig_tile", 1)[1].split("\nfunc ", 1)[0]
        self.assertIn("set_tile(pos,", dig)
        self.assertIn("_spawn_item(pos, item_name, item_type", dig)
        self.assertIn("return true", dig)

    def test_sleep_requires_attempting_to_reach_claimed_bed(self):
        sleep = self.dwarf.split("func _try_sleep", 1)[1].split("\nfunc ", 1)[0]
        self.assertIn("_find_unclaimed_bed(world)", sleep)
        self.assertIn("_claim_bed(world, bed_pos)", sleep)
        self.assertIn('current_task = "Yendo a su cama"', sleep)
        self.assertLess(sleep.index("_move_toward(world, preferred_bed)"), sleep.index("is_sleeping = true"))


if __name__ == "__main__":
    unittest.main()
