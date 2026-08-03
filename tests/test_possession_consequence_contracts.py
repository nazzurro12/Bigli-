from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
SYSTEM = ROOT / "df_mode" / "df_consequence_system.gd"
DWARF = ROOT / "df_mode" / "df_dwarf.gd"


class PossessionConsequenceContracts(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = SYSTEM.read_text(encoding="utf-8")
        cls.dwarf = DWARF.read_text(encoding="utf-8")

    def test_dwarf_declares_complete_social_state(self):
        required_fields = (
            "life_history",
            "reputation",
            "known_reputations",
            "rumors",
            "legal_record",
            "career_offers",
            "life_decisions",
            "social_roles",
            "possession_count",
            "last_possession_event_id",
        )
        for field in required_fields:
            self.assertRegex(self.dwarf, rf"var\\s+{field}\\s*:")

    def test_events_use_persistent_world_time(self):
        self.assertIn('"world_minute": _world_minute()', self.source)
        self.assertNotIn('"time": Time.get_ticks_msec()', self.source)

    def test_events_expose_a_readable_causal_report(self):
        for field in (
            '"witness_names"',
            '"interpretations"',
            '"immediate_results"',
            '"future_hooks"',
            '"caused_by_event_id"',
            '"status"',
        ):
            self.assertIn(field, self.source)
        self.assertIn("func get_event_report(event_id: int) -> Dictionary:", self.source)
        self.assertIn("func _build_causal_chain(event: Dictionary) -> Array:", self.source)

    def test_rumors_keep_world_time(self):
        self.assertIn('"heard_at": event.get("world_minute", _world_minute())', self.source)


if __name__ == "__main__":
    unittest.main()
