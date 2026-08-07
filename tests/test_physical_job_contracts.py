import pathlib
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[1]


class PhysicalJobContracts(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.main = (ROOT / "df_mode/df_main.gd").read_text(encoding="utf-8")
        cls.dwarf = (ROOT / "df_mode/df_dwarf.gd").read_text(encoding="utf-8")
        cls.world = (ROOT / "df_mode/df_world.gd").read_text(encoding="utf-8")
        cls.workshop = (ROOT / "df_mode/df_workshop.gd").read_text(encoding="utf-8")

    def test_world_exposes_authoritative_clock_to_inhabitants(self):
        self.assertIn('world.set_meta("game_hour", _game_hour)', self.main)
        self.assertIn('world.set_meta("game_minute", _game_minute)', self.main)
        self.assertIn('world.get_meta("game_hour", 12)', self.dwarf)
        self.assertNotIn('world.get_parent() if world.has_method("get_parent")', self.dwarf)

    def test_daily_schedule_matches_the_design(self):
        self.assertIn("hour >= 22 or hour < 6", self.dwarf)
        self.assertIn("hour >= 14 and hour < 22", self.dwarf)
        self.assertIn("not is_sleep_time and not is_recreation_time", self.dwarf)

    def test_physical_jobs_cannot_bypass_progress(self):
        work = self.dwarf.split("func _work_on_job", 1)[1].split("\nfunc ", 1)[0]
        self.assertIn("not _job_requires_physical_progress", work)
        self.assertIn("task_progress += ", work)
        self.assertIn("if task_progress >= 1.0:", work)
        self.assertLess(work.index("task_progress += "), work.index("_execute_job(world)", work.index("task_progress += ")))
        physical = self.dwarf.split("func _job_requires_physical_progress", 1)[1].split("\nfunc ", 1)[0]
        for job_name in ("DIG", "CHOP_TREE", "BUILD_WALL", "BUILD_FLOOR", "BUILD_WORKSHOP"):
            self.assertIn("DFJob.JobType." + job_name, physical)

    def test_construction_materials_are_reserved_and_not_duplicated(self):
        work = self.dwarf.split("func _work_on_job", 1)[1].split("\nfunc ", 1)[0]
        self.assertIn("material_item.is_reserved_for_other(id, current_tick)", work)
        self.assertIn("material_item.is_inside_container or material_item.carried_by_id >= 0", work)
        self.assertIn("selected_material.reserve_for(id, current_tick + 180)", work)
        self.assertIn("selected_material.release_reservation(id)", work)
        self.assertIn("selected_material.carried_by_id = id", work)
        self.assertLess(work.index("world.remove_entity(selected_material)"), work.index("inventory.append(selected_material)"))

    def test_failed_physical_jobs_explain_why_they_stopped(self):
        cancel = self.dwarf.split("func _cancel_current_job", 1)[1].split("\nfunc ", 1)[0]
        self.assertIn("current_job.cancel_reason = reason", cancel)
        self.assertIn("current_job.assigned_dwarf_id = -1", cancel)
        self.assertIn('"Trabajo cancelado: %s" % reason', cancel)
        work = self.dwarf.split("func _work_on_job", 1)[1].split("\nfunc ", 1)[0]
        self.assertIn('_release_current_job(world, "no hay piedra o madera alcanzable", 300)', work)

    def test_completed_construction_does_not_consume_material_twice(self):
        execute = self.dwarf.split("func _execute_job", 1)[1].split("\nfunc ", 1)[0]
        self.assertIn("wall_was_complete", execute)
        self.assertIn("floor_was_complete", execute)
        self.assertIn("workshop_was_complete", execute)
        self.assertIn("not wall_was_complete and wall_material_index >= 0", execute)
        self.assertIn("not floor_was_complete and floor_material_index >= 0", execute)
        self.assertIn("not workshop_was_complete and workshop_material_index >= 0", execute)

    def test_construction_changes_authoritative_tiles(self):
        for method, tile_name in (
            ("build_wall", "CONSTRUCTED_WALL"),
            ("build_floor", "CONSTRUCTED_FLOOR"),
        ):
            body = self.world.split("func " + method, 1)[1].split("\nfunc ", 1)[0]
            self.assertIn("set_tile(pos, TileType." + tile_name + ")", body)
            self.assertIn("set_material(pos, mat_id)", body)
            self.assertIn("return true", body)

    def test_digging_creates_a_real_floor_and_resource(self):
        dig = self.world.split("func dig_tile", 1)[1].split("\nfunc ", 1)[0]
        self.assertIn("set_tile(pos,", dig)
        self.assertIn("_spawn_item(pos, item_name, item_type", dig)
        self.assertIn("return true", dig)

    def test_workshops_wait_for_inputs_before_progressing(self):
        tick = self.workshop.split("func tick", 1)[1].split("\nfunc ", 1)[0]
        self.assertIn("if current_recipe.is_empty():", tick)
        self.assertIn('"waiting_for_inputs": true', tick)
        self.assertLess(tick.index("if current_recipe.is_empty():"), tick.index("recipe_progress +="))

    def test_workshop_operator_collects_and_consumes_real_inputs(self):
        prepare = self.dwarf.split("func _prepare_workshop_inputs", 1)[1].split("\nfunc ", 1)[0]
        self.assertIn('recipe.get("inputs", [])', prepare)
        self.assertIn("ground_item.is_reserved_for_other(id, current_tick)", prepare)
        self.assertIn("nearest_item.reserve_for(id, current_tick + 180)", prepare)
        self.assertIn("inventory.remove_at(inventory_index)", prepare)
        self.assertIn("operating_workshop.current_recipe = recipe.duplicate(true)", prepare)

    def test_workshop_outputs_keep_provenance(self):
        produce = self.dwarf.split("func _produce_workshop_outputs", 1)[1].split("\nfunc ", 1)[0]
        self.assertIn("world._spawn_item(", produce)
        self.assertIn("produced.created_by_entity_id = id", produce)
        self.assertIn("produced.production_recipe_id", produce)
        self.assertIn("produced.production_site", produce)
        operate = self.dwarf.split("func _operate_workshop", 1)[1].split("\nfunc ", 1)[0]
        self.assertIn("operating_workshop.tick(1.0)", operate)
        self.assertIn("_produce_workshop_outputs(world, completed_recipe)", operate)

    def test_workshop_orders_queue_recipes_instead_of_spawning_free_items(self):
        execute = self.dwarf.split("func _execute_job", 1)[1].split("\nfunc ", 1)[0]
        reaction = execute.split("DFJob.JobType.WORKSHOP_REACTION:", 1)[1].split("\n\t\tDFJob.JobType.", 1)[0]
        self.assertIn("world.get_workshop_at(current_job.tile_pos)", reaction)
        self.assertIn("target_workshop.queue_recipe(reaction_id)", reaction)
        self.assertNotIn("world._spawn_item", reaction)

    def test_sleep_requires_attempting_to_reach_claimed_bed(self):
        sleep = self.dwarf.split("func _try_sleep", 1)[1].split("\nfunc ", 1)[0]
        self.assertIn("_find_unclaimed_bed(world)", sleep)
        self.assertIn("_claim_bed(world, bed_pos)", sleep)
        self.assertIn('current_task = "Yendo a su cama"', sleep)
        self.assertLess(sleep.index("_move_toward(world, preferred_bed)"), sleep.index("is_sleeping = true"))


if __name__ == "__main__":
    unittest.main()
