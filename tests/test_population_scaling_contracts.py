#!/usr/bin/env python3
"""Contratos para evitar IA cuadrática con poblaciones de miles."""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
MAIN = (ROOT / "df_mode/df_main.gd").read_text(encoding="utf-8")
WORLD = (ROOT / "df_mode/df_world.gd").read_text(encoding="utf-8")
DWARF = (ROOT / "df_mode/df_dwarf.gd").read_text(encoding="utf-8")


class PopulationScalingContracts(unittest.TestCase):
    def test_remote_residents_use_bounded_batches(self):
        match = re.search(r"SETTLEMENT_RESIDENT_TICK_BUCKETS: int = (\d+)", MAIN)
        self.assertIsNotNone(match)
        self.assertGreaterEqual(int(match.group(1)), 256)

    def test_world_spatial_query_uses_entity_grid(self):
        section = WORLD[WORLD.index("func get_dwarves_near"):WORLD.index("func get_hostile_entities_at")]
        self.assertIn("_entity_grid.get", section)
        self.assertNotIn("for e in entities", section)

    def test_local_social_ai_avoids_global_population_scan(self):
        sections = (
            DWARF[DWARF.index("func tick_social"):DWARF.index("func _exchange_social_belief")],
            DWARF[DWARF.index("func _find_nearby_master_for_skill"):DWARF.index("func _find_nearby_building_type")],
            DWARF[DWARF.index("func _try_socialize"):DWARF.index("func _try_create_art")],
        )
        for section in sections:
            self.assertIn("get_dwarves_near", section)
            self.assertNotIn("world.dwarves", section)


if __name__ == "__main__":
    unittest.main()
