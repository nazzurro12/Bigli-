from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
DWARF = (ROOT / "df_mode" / "df_dwarf.gd").read_text(encoding="utf-8")
RENDERER = (ROOT / "df_mode" / "df_renderer.gd").read_text(encoding="utf-8")


class ActivityTruthContracts(unittest.TestCase):
    def test_idle_label_is_stable_instead_of_random(self):
        task = DWARF.split("func get_task_string", 1)[1].split("\nfunc ", 1)[0]
        self.assertIn('return "Disponible%s"', task)
        self.assertNotIn("randi()", task)

    def test_activity_report_exposes_physical_evidence(self):
        report = DWARF.split("func get_activity_report", 1)[1].split("\nfunc _format_activity_target", 1)[0]
        for token in (
            '"phase"',
            '"target"',
            '"evidence"',
            '"progress"',
            'current_job.get_meta("carried_item_id"',
            'current_job.get_meta("construction_material_id"',
            '"ruta %d/%d"',
        ):
            self.assertIn(token, report)

    def test_management_panel_uses_report_not_free_text(self):
        refresh = RENDERER.split("func _refresh_management_pages", 1)[1].split("\nfunc ", 1)[0]
        self.assertIn("dwarf.get_activity_report()", refresh)
        self.assertIn("ACCIONES COMPROBABLES", refresh)
        self.assertIn("TRABAJOS FÍSICOS", refresh)
        self.assertIn('activity["evidence"]', refresh)


if __name__ == "__main__":
    unittest.main()
