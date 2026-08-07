#!/usr/bin/env python3
"""Contratos estáticos del modelo unificado y explicable de habitantes."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
DWARF = (ROOT / "df_mode/df_dwarf.gd").read_text(encoding="utf-8")
SAVE = (ROOT / "df_mode/df_save_load.gd").read_text(encoding="utf-8")
RENDERER = (ROOT / "df_mode/df_renderer.gd").read_text(encoding="utf-8")


class LifeModelContracts(unittest.TestCase):
    def test_unified_state_is_initialized_and_ticked_by_minute(self):
        for token in ("life_drives", "aspiration", "decision_reason", "status_effects", "household_id"):
            self.assertIn(token, DWARF)
        self.assertIn("_init_life_model()", DWARF)
        self.assertIn("tick_life_model()", DWARF)

    def test_personality_emotion_and_leadership_score_work(self):
        for token in ("PersonalityTrait.INDUSTRY", "PersonalityTrait.AMBITION", "current_emotion", "leader_score"):
            self.assertIn(token, DWARF)
        self.assertIn('"factors": factors', DWARF)

    def test_decisions_are_explainable_and_visible(self):
        self.assertIn('decision_reason = "Eligió', DWARF)
        self.assertIn('"reason": decision_reason', DWARF)
        self.assertIn('"  por qué: %s"', RENDERER)

    def test_life_and_generational_state_round_trips(self):
        for token in ("life_drives", "aspiration_progress", "status_effects", "leader_id", "household_id", "life_history", "life_decisions"):
            self.assertGreaterEqual(SAVE.count(f'"{token}"'), 2, token)


if __name__ == "__main__":
    unittest.main()
