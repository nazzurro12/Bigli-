from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
MAIN = ROOT / "df_mode" / "df_main.gd"
RENDERER = ROOT / "df_mode" / "df_renderer.gd"


class GodModeEmbarkContracts(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.main = MAIN.read_text(encoding="utf-8")
        cls.renderer = RENDERER.read_text(encoding="utf-8")

    def test_only_god_mode_is_reachable(self):
        self.assertNotIn("current_state = GameState.MODE_SELECT", self.main)
        self.assertNotIn("adventure_mode_pending", self.main)
        self.assertNotIn("MODO AVENTURA", self.main)
        self.assertNotIn("func _draw_mode_select_menu()", self.renderer)
        self.assertNotIn('_draw_fullscreen_desktop_shell("Bigli - Seleccionar modo"', self.renderer)
        self.assertIn('"  MODO DIOS · %s"', self.main)

    def test_generated_world_enters_embark_directly(self):
        self.assertIn("current_state = GameState.EMBARK_MAP_SELECT", self.main)
        self.assertIn("embark_cursor = _resolve_habitable_embark_region(embark_cursor)", self.main)

    def test_ocean_is_never_an_accepted_fallback(self):
        self.assertIn('push_error("El mundo generado no contiene una región habitable para desembarcar.")', self.main)
        self.assertIn("return Vector2i(-1, -1)", self.main)
        self.assertIn("world.is_water(local_center_surface)", self.main)
        self.assertIn('load_status = "Error: no se encontró terreno firme para iniciar"', self.main)


if __name__ == "__main__":
    unittest.main()
