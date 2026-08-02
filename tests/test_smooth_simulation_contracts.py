"""Contratos que evitan picos periódicos y movimiento animal entrecortado."""

from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]


class SmoothSimulationContracts(unittest.TestCase):
    def read(self, relative_path: str) -> str:
        return (ROOT / relative_path).read_text(encoding="utf-8")

    def test_frame_catchup_is_bounded(self) -> None:
        main = self.read("df_mode/df_main.gd")
        self.assertIn("MAX_CATCHUP_TICKS_PER_FRAME", main)
        self.assertIn(
            "catchup_ticks < MAX_CATCHUP_TICKS_PER_FRAME",
            main,
        )
        self.assertIn("_time_accum = minf(_time_accum, tick_interval)", main)

    def test_economy_does_not_share_the_minute_boundary(self) -> None:
        main = self.read("df_mode/df_main.gd")
        self.assertNotIn("if minute_ticked:\n\t\t_maintain_autonomous_economy()", main)
        self.assertIn("_simulation_tick_clock == 6", main)

    def test_creature_heavy_updates_are_bucketed(self) -> None:
        main = self.read("df_mode/df_main.gd")
        self.assertIn("last_simulated_minute", main)
        self.assertIn("posmod(int(e6.id), 7)", main)
        self.assertIn("creature_minute_bucket", main)

    def test_animals_continue_committed_actions_between_decisions(self) -> None:
        creature = self.read("df_mode/df_creature.gd")
        self.assertIn("func _continue_current_behavior", creature)
        self.assertIn("_continue_current_behavior(world)", creature)
        self.assertIn("AIState.HUNT, AIState.STALK, AIState.ATTACK", creature)
        self.assertIn(
            "AIState.WANDER, AIState.SEEK_FOOD, AIState.SEEK_WATER",
            creature,
        )

    def test_wandering_has_a_persistent_destination(self) -> None:
        creature = self.read("df_mode/df_creature.gd")
        start = creature.index("func _wander(world)")
        section = creature[start : start + 900]
        self.assertIn("ai_target_pos", section)
        self.assertIn("tile_pos == ai_target_pos", section)
        self.assertNotIn("Vector3i(tile_pos.x, tile_pos.y, tile_pos.z)", section)


if __name__ == "__main__":
    unittest.main()
