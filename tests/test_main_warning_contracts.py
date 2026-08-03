from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[1]
MAIN = ROOT / "df_mode" / "df_main.gd"
EXECUTOR = ROOT / "core" / "actions" / "df_actor_action_executor.gd"


class MainWarningContracts(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.main = MAIN.read_text(encoding="utf-8")
        cls.executor = EXECUTOR.read_text(encoding="utf-8")

    def test_main_does_not_shadow_registered_global_classes(self):
        redundant = re.findall(
            r'^const\s+(\w+)\s*=\s*preload\("([^"]+)"\)',
            self.main,
            re.M,
        )
        allowed_aliases = {"DFQuestSystem", "DFWorldSimulationScript"}
        self.assertEqual([], [name for name, _ in redundant if name not in allowed_aliases])

    def test_removed_private_fields_do_not_return(self):
        self.assertNotIn("_mouse_tile_pos", self.main)
        self.assertNotIn("_generation_phase", self.main)

    def test_control_position_is_not_shadowed(self):
        self.assertNotRegex(self.main, r"func\s+\w+\([^)]*\bposition\s*:")

    def test_removed_empty_tile_constant_does_not_return(self):
        self.assertNotIn("TileType.EMPTY", self.executor)


if __name__ == "__main__":
    unittest.main()
