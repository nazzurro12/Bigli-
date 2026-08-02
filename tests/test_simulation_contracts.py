"""Contratos estructurales del núcleo de simulación.

Estas pruebas no reemplazan las pruebas headless de Godot. Protegen invariantes
arquitectónicos que antes se rompían silenciosamente y pueden ejecutarse con
Python en CI sin instalar el motor.
"""

from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]


class SimulationContracts(unittest.TestCase):
    def read(self, relative_path: str) -> str:
        return (ROOT / relative_path).read_text(encoding="utf-8")

    def test_only_canonical_world_simulation_exists(self) -> None:
        self.assertFalse((ROOT / "df_mode/world_simulation.gd").exists())
        self.assertTrue(
            (ROOT / "df_mode/core/simulation/world_simulation.gd").exists()
        )

    def test_world_layer_does_not_duplicate_dwarf_needs(self) -> None:
        source = self.read("df_mode/core/simulation/world_simulation.gd")
        self.assertNotIn('set_meta("simulation_needs"', source)
        self.assertIn('entity.get("creature_type") == "dwarf"', source)
        self.assertIn('"needs"', source)

    def test_settlement_counts_physical_resource_locations(self) -> None:
        source = self.read("df_mode/core/simulation/settlement_controller.gd")
        for required_bucket in (
            "available_resources",
            "reserved_resources",
            "carried_resources",
        ):
            self.assertIn(required_bucket, source)
        self.assertIn("stack_size", source)
        self.assertIn("reserved_by_job_id", source)

    def test_simulation_state_is_saved_and_restored(self) -> None:
        source = self.read("df_mode/df_save_load.gd")
        self.assertGreaterEqual(source.count('data["world_simulation"]'), 2)
        self.assertIn("serialize_state()", source)
        self.assertIn("restore_state(", source)

    def test_world_initializes_consequence_system(self) -> None:
        source = self.read("df_mode/df_world.gd")
        self.assertIn('const DFConsequenceSystem = preload("res://df_mode/df_consequence_system.gd")', source)
        self.assertIn("var consequence_system: DFConsequenceSystem = null", source)
        self.assertIn("consequence_system = DFConsequenceSystem.new(self)", source)

    def test_memories_use_world_time(self) -> None:
        source = self.read("df_mode/df_dwarf.gd")
        self.assertNotIn("return Time.get_ticks_msec()", source)
        self.assertIn("return simulation_minute", source)


if __name__ == "__main__":
    unittest.main()
