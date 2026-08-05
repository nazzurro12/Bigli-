from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
DWARF = (ROOT / "df_mode" / "df_dwarf.gd").read_text(encoding="utf-8")
EDUCATION = (ROOT / "df_mode" / "df_education.gd").read_text(encoding="utf-8")
MAIN = (ROOT / "df_mode" / "df_main.gd").read_text(encoding="utf-8")
RENDERER = (ROOT / "df_mode" / "df_renderer.gd").read_text(encoding="utf-8")


class ColonyLifeContracts(unittest.TestCase):
    def test_wood_collection_is_restricted_to_woodcutters(self):
        self.assertIn(
            "DFJob.JobType.CHOP_TREE, DFJob.JobType.COLLECT_WOOD:",
            DWARF,
        )

    def test_unreachable_paths_have_a_bounded_retry(self):
        self.assertIn('current_task = "Recalculando ruta (1/2)"', DWARF)
        self.assertIn('_release_current_job(world, "destino inaccesible")', DWARF)
        self.assertNotIn('current_task = "Buscando una ruta alternativa"', DWARF)

    def test_dwarf_idle_fallback_does_not_grant_fake_study_xp(self):
        self.assertNotIn('current_task = "Estudiando de %s"', DWARF)
        self.assertNotIn("Estudiando de forma autodidacta", DWARF)

    def test_lessons_require_demonstration_and_practice(self):
        self.assertIn('"phase": "demonstration"', EDUCATION)
        self.assertIn('teacher.current_task = "Demostrando %s a %s"', EDUCATION)
        self.assertIn('student.current_task = "Practicando %s con %s"', EDUCATION)
        observation = EDUCATION.index('student.current_task = "Observando cómo se hace %s"')
        practice_xp = EDUCATION.index("student.add_skill_xp(skill_id, xp_gain)")
        self.assertLess(observation, practice_xp)

    def test_survival_needs_preempt_lessons(self):
        self.assertIn("float(dwarf.hunger) > 0.55", EDUCATION)
        self.assertIn("float(dwarf.thirst) > 0.55", EDUCATION)
        self.assertIn("float(dwarf.fatigue) > 0.70", EDUCATION)

    def test_starting_settlement_has_functional_furniture(self):
        self.assertIn("table_item.is_table = true", MAIN)
        self.assertIn("chair_item.is_chair = true", MAIN)
        self.assertIn("bed_item.is_bed = true", MAIN)

    def test_hud_does_not_duplicate_native_window_chrome(self):
        self.assertIn("classic_title_label.visible = false", RENDERER)
        self.assertIn("legend_btn.visible = false", RENDERER)
        self.assertIn("const UI_CONTENT_TOP: int = 24", RENDERER)

    def test_renderer_keeps_required_input_and_theme_helpers(self):
        required = [
            "_apply_classic_control_theme",
            "_dispatch_main_key",
            "_on_classic_popup_id_pressed",
            "_on_classic_menu_pressed",
            "_on_classic_window_button",
            "_make_classic_style",
        ]
        for function_name in required:
            self.assertIn(f"func {function_name}", RENDERER)


if __name__ == "__main__":
    unittest.main()
