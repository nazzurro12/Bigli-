#!/usr/bin/env python3
"""Contratos de aparición residencial y ocupación física de camas."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
MAIN = (ROOT / "df_mode/df_main.gd").read_text(encoding="utf-8")
SITES = (ROOT / "df_mode/df_world_sites.gd").read_text(encoding="utf-8")
DWARF = (ROOT / "df_mode/df_dwarf.gd").read_text(encoding="utf-8")


class ResidentialSpawnContracts(unittest.TestCase):
    def test_initial_residents_are_moved_to_assigned_beds(self):
        self.assertIn("world.move_entity(assigned_resident, bed_offset_pos)", MAIN)
        self.assertIn("assigned_resident.claimed_bed = bed_offset_pos", MAIN)
        self.assertNotIn("assigned_resident.tile_pos = bed_offset_pos", MAIN)

    def test_historical_houses_create_one_bed_per_resident(self):
        self.assertIn('structure["resident_capacity"]', SITES)
        self.assertIn("for bed_index in range(bed_count)", SITES)
        self.assertIn('"beds": beds', SITES)

    def test_each_resident_consumes_one_unique_bed_slot(self):
        self.assertIn("next_bed_by_home", SITES)
        self.assertIn("next_bed_index + 1", SITES)
        self.assertIn("resident.preferred_bed = assigned_bed", SITES)

    def test_marriage_never_aliases_the_same_bed(self):
        marriage = DWARF[DWARF.index("func _marry"):DWARF.index("func _try_conceive")]
        self.assertNotIn("preferred_bed = partner.preferred_bed", marriage)
        self.assertIn("partner.household_id = shared_household", marriage)


if __name__ == "__main__":
    unittest.main()
