import pathlib
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[1]


class StorageLogisticsContracts(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.dwarf = (ROOT / "df_mode/df_dwarf.gd").read_text(encoding="utf-8")
        cls.stockpile = (ROOT / "df_mode/df_stockpile.gd").read_text(encoding="utf-8")

    def test_stockpile_queries_use_the_spatial_index(self):
        contains = self.stockpile.split("func _tile_contains_item_type", 1)[1].split("\nfunc ", 1)[0]
        count = self.stockpile.split("func _count_items_at", 1)[1].split("\nfunc ", 1)[0]
        self.assertIn("world.get_items_at(pos)", contains)
        self.assertIn("world.get_items_at(pos)", count)
        self.assertNotIn("world.entities", contains)
        self.assertNotIn("world.entities", count)

    def test_stockpiles_prioritize_physical_containers(self):
        candidates = self.stockpile.split("func get_candidate_tiles", 1)[1].split("\nfunc ", 1)[0]
        self.assertIn("_is_container_tile(world, container_pos)", candidates)
        self.assertLess(
            candidates.index("_is_container_tile(world, container_pos)"),
            candidates.index("_tile_contains_item_type(world, same_type_pos"),
        )
        container = self.stockpile.split("func _is_container_tile", 1)[1].split("\nfunc ", 1)[0]
        self.assertIn("entity.is_container", container)
        self.assertIn("entity.contained_volume < entity.container_volume", container)

    def test_collectors_reserve_one_physical_item(self):
        collect = self.dwarf.split("func _execute_collect_job", 1)[1].split("\nfunc ", 1)[0]
        self.assertIn("world_item.is_reserved_for_other(id, current_tick)", collect)
        self.assertIn("target_item.reserve_for(id, current_tick + 600)", collect)
        self.assertIn("target_item.release_reservation(id)", collect)
        self.assertIn("target_item.carried_by_id = id", collect)
        self.assertLess(collect.index("world.remove_entity(target_item)"), collect.index("inventory.append(target_item)"))

    def test_collectors_do_not_start_without_storage(self):
        collect = self.dwarf.split("func _execute_collect_job", 1)[1].split("\nfunc ", 1)[0]
        self.assertIn('get_free_tile(world, item_type_to_collect)', collect)
        self.assertIn('_cancel_current_job("no hay espacio en ningún almacén")', collect)
        self.assertNotIn("por falta de espacio", collect)
        self.assertNotIn("Dejo " , collect)

    def test_collection_deposit_reports_container_or_stockpile(self):
        collect = self.dwarf.split("func _execute_collect_job", 1)[1].split("\nfunc ", 1)[0]
        self.assertIn("stored_in_container: bool = _put_item_in_container_at", collect)
        self.assertIn("dentro de un cofre", collect)
        self.assertIn("Apiló %s en el almacén", collect)

    def test_food_is_not_dropped_when_a_chest_fills_during_transit(self):
        store = self.dwarf.split("func _execute_store_in_container_job", 1)[1].split("\nfunc ", 1)[0]
        self.assertIn("if not _put_item_in_container_at(world, carried_food, best_fs_pos):", store)
        self.assertIn('current_task = "Buscando otro cofre con espacio"', store)
        failure = store.split("if not _put_item_in_container_at", 1)[1].split("return false", 1)[0]
        self.assertIn("carried_food.carried_by_id = id", failure)
        self.assertNotIn("world.add_entity(carried_food)", failure)


if __name__ == "__main__":
    unittest.main()
