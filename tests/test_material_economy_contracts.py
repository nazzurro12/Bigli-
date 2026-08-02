"""Contratos de conservación, reserva y procedencia material."""

from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]


class MaterialEconomyContracts(unittest.TestCase):
    def read(self, relative_path: str) -> str:
        return (ROOT / relative_path).read_text(encoding="utf-8")

    def test_items_have_persistent_provenance(self) -> None:
        item = self.read("df_mode/df_item.gd")
        save = self.read("df_mode/df_save_load.gd")
        fields = (
            "created_at_minute",
            "created_by_entity_id",
            "source_item_ids",
            "production_recipe_id",
            "production_site",
        )
        for field in fields:
            self.assertIn(f"var {field}", item)
            self.assertGreaterEqual(save.count(f'"{field}"'), 2)

    def test_recipe_selection_is_atomic_and_stack_aware(self) -> None:
        main = self.read("df_mode/df_main.gd")
        self.assertIn("func _select_recipe_inputs", main)
        self.assertIn("selected_amounts", main)
        self.assertIn("candidate_item.stack_size - already_selected", main)
        self.assertIn('{"valid": false, "entries": []}', main)

    def test_workshop_reserves_before_work_and_consumes_by_identity(self) -> None:
        main = self.read("df_mode/df_main.gd")
        self.assertIn("item.reserve_for(operator_id", main)
        self.assertIn('recipe["_reserved_inputs"]', main)
        self.assertIn("func _find_recipe_item", main)
        self.assertTrue(
            "item.stack_size -= amount" in main
            or "consumed_item.stack_size -= consumed_amount" in main
        )
        self.assertIn("world_ref.entities.erase(item)", main)

    def test_reservations_are_released_when_assignment_breaks(self) -> None:
        main = self.read("df_mode/df_main.gd")
        self.assertIn("func _release_recipe_reservations", main)
        release = main.index("_release_recipe_reservations")
        unassign = main.index("workshop.unassign_dwarf()", release)
        self.assertLess(release, unassign)

    def test_outputs_reference_consumed_inputs_and_event(self) -> None:
        main = self.read("df_mode/df_main.gd")
        self.assertIn('recipe["_consumed_input_ids"]', main)
        self.assertIn("spawned.source_item_ids", main)
        self.assertIn('"production"', main)
        self.assertIn("world_simulation.record(", main)

    def test_settlement_reads_real_item_reservations(self) -> None:
        settlement = self.read(
            "df_mode/core/simulation/settlement_controller.gd"
        )
        self.assertIn('item.get("reserved_by_id")', settlement)


if __name__ == "__main__":
    unittest.main()
