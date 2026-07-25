import pathlib
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[1]


class ColonyConsistencyContracts(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.dwarf = (ROOT / "df_mode/df_dwarf.gd").read_text(encoding="utf-8")
        cls.world = (ROOT / "df_mode/df_world.gd").read_text(encoding="utf-8")
        cls.main = (ROOT / "df_mode/df_main.gd").read_text(encoding="utf-8")
        cls.save = (ROOT / "df_mode/df_save_load.gd").read_text(encoding="utf-8")
        cls.item = (ROOT / "df_mode/df_item.gd").read_text(encoding="utf-8")

    def test_crises_require_time_and_sustained_pressure(self):
        self.assertIn("CRISIS_GRACE_MINUTES: int = 1440", self.dwarf)
        self.assertIn("CRISIS_PRESSURE_REQUIRED: float = 360.0", self.dwarf)
        self.assertIn(
            "simulation_minute == last_crisis_evaluation_minute", self.dwarf
        )
        self.assertNotIn("randi() % 2 == 0 else MoodState.BESERK", self.dwarf)

    def test_berserk_bonus_is_not_accumulated_each_frame(self):
        self.assertIn("if not berserk_bonus_applied:", self.dwarf)
        self.assertIn("berserk_bonus_applied = false", self.dwarf)

    def test_eating_and_drinking_update_authoritative_needs(self):
        self.assertIn("hunger = maxf(0.0, hunger - item.nutrition)", self.dwarf)
        self.assertIn(
            "thirst = maxf(0.0, thirst - maxf(0.35, item.nutrition))",
            self.dwarf,
        )

    def test_warehouse_contains_real_containers(self):
        self.assertIn('"Cofre de Almacén"', self.main)
        self.assertIn("chest.is_container = true", self.main)
        self.assertIn("spawned_item.put_in_container(possible_container)", self.main)

    def test_hauling_tracks_container_and_carrier_state(self):
        self.assertIn("_put_item_in_container_at(world, carried_food", self.dwarf)
        self.assertIn("carried_food.carried_by_id = -1", self.dwarf)
        self.assertIn("target_food.carried_by_id = id", self.dwarf)

    def test_snow_is_winter_and_temperature_gated(self):
        self.assertIn("weather_weights[wt] = 0.0", self.world)
        self.assertIn("current_season != Season.WINTER", self.world)
        self.assertIn("ambient_temperature > 0.42", self.world)

    def test_crisis_state_survives_save_load(self):
        for field in (
            "crisis_pressure",
            "last_crisis_evaluation_minute",
            "crisis_reason",
            "berserk_bonus_applied",
        ):
            self.assertGreaterEqual(self.save.count(field), 2)

    def test_old_saves_rebuild_real_container_state(self):
        self.assertIn("func _reconcile_storage_containers()", self.main)
        self.assertIn("existing_container.container_contents.clear()", self.main)
        self.assertIn("stored_item.put_in_container(target_container)", self.main)
        self.assertIn("main._reconcile_storage_containers()", self.save)

    def test_storage_jobs_honor_and_reserve_their_target(self):
        self.assertIn('current_job.get_meta("target_item_id", -1)', self.dwarf)
        self.assertIn("target_food.reserve_for(id, current_tick + 600)", self.dwarf)
        self.assertIn("carried_food.release_reservation(id)", self.dwarf)

    def test_non_winter_saves_remove_legacy_snow(self):
        self.assertIn("func reconcile_seasonal_weather()", self.world)
        self.assertIn("w.reconcile_seasonal_weather()", self.save)

    def test_container_linking_is_idempotent(self):
        self.assertIn("container.container_contents.has(self)", self.item)


if __name__ == "__main__":
    unittest.main()
