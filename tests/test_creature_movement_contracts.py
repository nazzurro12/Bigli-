from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
CREATURE = ROOT / "df_mode" / "df_creature.gd"
WORLD = ROOT / "df_mode" / "df_world.gd"


class CreatureMovementContracts(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.creature = CREATURE.read_text(encoding="utf-8")
        cls.world = WORLD.read_text(encoding="utf-8")

    def test_creature_uses_existing_occupancy_api(self):
        self.assertIn("func is_actor_occupied(pos: Vector3i, exclude = null) -> bool:", self.world)
        self.assertNotIn("is_blocked_by_entity", self.creature)
        self.assertIn("world.is_actor_occupied(next_step, self)", self.creature)
        self.assertIn("world.is_actor_occupied(alt, self)", self.creature)

    def test_creature_movement_updates_spatial_index(self):
        self.assertIn("world.move_entity(self, next_step)", self.creature)
        self.assertIn("world.move_entity(self, alt)", self.creature)


if __name__ == "__main__":
    unittest.main()
