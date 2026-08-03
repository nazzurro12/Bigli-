from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[1]
WORLD = ROOT / "df_mode" / "df_world.gd"
EXECUTOR = ROOT / "core" / "actions" / "df_actor_action_executor.gd"


class TileTypeActionContracts(unittest.TestCase):
    def test_actor_actions_only_reference_declared_tile_types(self):
        world = WORLD.read_text(encoding="utf-8")
        executor = EXECUTOR.read_text(encoding="utf-8")
        enum_match = re.search(r"enum TileType\s*\{([^}]*)\}", world, re.S)
        self.assertIsNotNone(enum_match)
        declared = set(re.findall(r"\b([A-Z][A-Z0-9_]*)\b", enum_match.group(1)))
        used = set(re.findall(r"TileType\.([A-Z][A-Z0-9_]*)", executor))
        self.assertEqual(set(), used - declared)

    def test_removed_empty_tile_name_does_not_return(self):
        executor = EXECUTOR.read_text(encoding="utf-8")
        self.assertNotIn("TileType.EMPTY", executor)
        self.assertIn("world.TileType.FLOOR", executor)


if __name__ == "__main__":
    unittest.main()
