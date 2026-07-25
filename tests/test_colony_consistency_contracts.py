import pathlib
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[1]


class ColonyConsistencyContracts(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.dwarf = (ROOT / "df_mode/df_dwarf.gd").read_text(encoding="utf-8")
        cls.world = (ROOT / "df_mode/df_world.gd").read_text(encoding="utf-8")
        cls.main = (ROOT / "df_mode/df_main.gd").read_text(encoding="utf-8")
        cls.save = (ROOT / "df_mode/df_save_load.gd").read_text(encoding="utf-8")
        cls.item = (ROOT / "df_mode/df_item.gd").read_text(encoding="utf-8")
        cls.building = (ROOT / "df_mode/df_building.gd").read_text(encoding="utf-8")
        cls.renderer = (ROOT / "df_mode/df_renderer.gd").read_text(encoding="utf-8")
        cls.job = (ROOT / "df_mode/df_job.gd").read_text(encoding="utf-8")

    def test_crises_require_time_and_sustained_pressure(self):
        self.assertIn("CRISIS_GRACE_MINUTES: int = 1440", self.dwarf)
        self.assertIn("CRISIS_PRESSURE_REQUIRED: float = 360.0", self.dwarf)
        self.assertIn(
            "simulation_minute == last_crisis_evaluation_minute", self.dwarf
        )
        self.assertNotIn("randi() % 2 == 0 else MoodState.BESERK", self.dwarf)

    def test_berserk_bonus_is_not_accumulated_each_frame(self):
        self.assertIn("if not berserk_bonus_applied:", self.dwarf)
        self.assertIn("berserk_bonus_applied = false", self.dwarf)

    def test_eating_and_drinking_update_authoritative_needs(self):
        self.assertIn("hunger = maxf(0.0, hunger - item.nutrition)", self.dwarf)
        self.assertIn(
            "thirst = maxf(0.0, thirst - maxf(0.35, item.hydration))",
            self.dwarf,
        )

    def test_warehouse_contains_real_containers(self):
        self.assertIn('"Cofre de Almacén"', self.main)
        self.assertIn("chest.is_container = true", self.main)
        self.assertIn("spawned_item.put_in_container(possible_container)", self.main)

    def test_hauling_tracks_container_and_carrier_state(self):
        self.assertIn("_put_item_in_container_at(world, carried_food", self.dwarf)
        self.assertIn("carried_food.carried_by_id = -1", self.dwarf)
        self.assertIn("target_food.carried_by_id = id", self.dwarf)

    def test_snow_is_winter_and_temperature_gated(self):
        self.assertIn("weather_weights[wt] = 0.0", self.world)
        self.assertIn("current_season != Season.WINTER", self.world)
        self.assertIn("ambient_temperature > 0.42", self.world)

    def test_crisis_state_survives_save_load(self):
        for field in (
            "crisis_pressure",
            "last_crisis_evaluation_minute",
            "crisis_reason",
            "berserk_bonus_applied",
        ):
            self.assertGreaterEqual(self.save.count(field), 2)

    def test_old_saves_rebuild_real_container_state(self):
        self.assertIn("func _reconcile_storage_containers()", self.main)
        self.assertIn("existing_container.container_contents.clear()", self.main)
        self.assertIn("stored_item.put_in_container(target_container)", self.main)
        self.assertIn("main._reconcile_storage_containers()", self.save)

    def test_storage_jobs_honor_and_reserve_their_target(self):
        self.assertIn('current_job.get_meta("target_item_id", -1)', self.dwarf)
        self.assertIn("target_food.reserve_for(id, current_tick + 600)", self.dwarf)
        self.assertIn("carried_food.release_reservation(id)", self.dwarf)

    def test_non_winter_saves_remove_legacy_snow(self):
        self.assertIn("func reconcile_seasonal_weather()", self.world)
        self.assertIn("w.reconcile_seasonal_weather()", self.save)

    def test_container_linking_is_idempotent(self):
        self.assertIn("container.container_contents.has(self)", self.item)

    def test_humanoid_physiology_runs_once_per_game_minute(self):
        self.assertIn("if minute_ticked:", self.dwarf)
        self.assertIn("tick_humanoid_physiology(world)", self.dwarf)
        self.assertEqual(self.dwarf.count("tick_humanoid_physiology(world)"), 1)

    def test_three_meals_and_minimum_water_have_daily_consequences(self):
        self.assertIn("float(meals_today) / 3.0", self.dwarf)
        self.assertIn("water_liters_today / 1.0", self.dwarf)
        self.assertIn("nutrition_quality = lerpf", self.dwarf)

    def test_digestion_generates_waste_needs(self):
        self.assertIn("bladder_fill = minf", self.dwarf)
        self.assertIn("bowel_fill = minf", self.dwarf)
        self.assertIn('var waste_type: String = "urine"', self.dwarf)
        self.assertIn('else "feces"', self.dwarf)

    def test_food_has_balanced_nutrition_dimensions(self):
        for field in (
            "protein_value",
            "carbohydrate_value",
            "fat_value",
            "fiber_value",
            "micronutrient_value",
        ):
            self.assertIn(field, self.item)
            self.assertGreaterEqual(self.save.count(field), 2)

    def test_condition_controls_load_capacity_and_movement(self):
        self.assertIn("func get_carrying_capacity()", self.dwarf)
        self.assertIn("physical_condition", self.dwarf)
        self.assertIn("carried_ratio > 1.0", self.dwarf)

    def test_latrines_are_physical_capacity_limited_buildings(self):
        self.assertIn("LATRINE", self.building)
        self.assertIn("sanitation_capacity", self.building)
        self.assertIn("func _ensure_basic_sanitation()", self.main)
        self.assertIn("existing_latrines >= 4", self.main)

    def test_old_saves_receive_sanitation_and_preserve_fill(self):
        self.assertIn("main._ensure_basic_sanitation()", self.save)
        self.assertGreaterEqual(self.save.count("sanitation_load"), 2)
        self.assertGreaterEqual(self.save.count("sanitation_capacity"), 2)

    def test_humanoids_seek_latrines_before_emergency(self):
        self.assertIn('current_task = "Yendo a la letrina"', self.dwarf)
        self.assertIn("var emergency: bool", self.dwarf)
        self.assertIn("nearest_latrine.add_sanitation_waste", self.dwarf)

    def test_uncontained_waste_has_environmental_consequences(self):
        self.assertIn('add_splatter_substance(tile_pos, "pathogen"', self.dwarf)
        self.assertIn('puddle.has("feces")', self.world)
        self.assertIn('"urine":', self.renderer)
        self.assertIn('"feces":', self.renderer)

    def test_disease_is_a_staged_minute_tick_simulation(self):
        self.assertIn("enum DiseasePhase", self.dwarf)
        self.assertIn("tick_health_cycle(world)", self.dwarf)
        self.assertEqual(self.dwarf.count("tick_health_cycle(world)"), 1)
        for phase in ("INCUBATING", "SYMPTOMATIC", "RECOVERING"):
            self.assertIn(phase, self.dwarf)

    def test_recovery_depends_on_living_conditions(self):
        for factor in (
            "nutrition_quality",
            "chronic_health",
            "sleep_quality",
            "hydration_support",
            "is_resting_medical",
        ):
            self.assertIn(factor, self.dwarf)
        self.assertIn("acquired_immunity = 1.0", self.dwarf)

    def test_disease_uses_environment_not_entity_pair_scans(self):
        health_cycle = self.dwarf.split("func tick_health_cycle", 1)[1].split(
            "func get_disease_status", 1
        )[0]
        self.assertIn('tile_substances.get("pathogen"', health_cycle)
        self.assertNotIn("for e in world.entities", health_cycle)
        self.assertIn("simulation_minute % 60 == id % 60", health_cycle)

    def test_health_cycle_is_persistent_and_visible(self):
        for field in (
            "disease_phase",
            "disease_progress",
            "disease_severity",
            "pathogen_exposure",
            "immune_strength",
            "acquired_immunity",
            "recovery_streak",
            "fever",
        ):
            self.assertGreaterEqual(self.save.count(field), 2)
        self.assertIn('"INCUBA"', self.renderer)
        self.assertIn('"RECUP"', self.renderer)

    def test_cleaning_jobs_are_generated_and_executed(self):
        self.assertIn("func _queue_sanitation_jobs", self.main)
        self.assertIn("DFJob.JobType.CLEAN", self.main)
        self.assertIn("world.clean_sanitary_tile", self.dwarf)
        self.assertIn("func clean_sanitary_tile", self.world)
        self.assertIn("clean_limit", self.main)

    def test_latrines_are_emptied_into_remote_compost(self):
        self.assertIn("EMPTY_LATRINE", self.job)
        self.assertIn("get_sanitation_fill_ratio", self.building)
        self.assertIn("remove_sanitation_waste", self.building)
        self.assertIn("_find_sanitary_disposal_position", self.main)
        self.assertIn('"compost"', self.world)

    def test_sanitation_job_destination_survives_save_load(self):
        self.assertGreaterEqual(self.save.count("disposal_pos"), 2)
        self.assertIn("var disposal_pos: Vector3i", self.job)

    def test_dirty_water_has_health_consequences_at_constant_cost(self):
        contamination = self.world.split("func get_water_contamination", 1)[1]
        self.assertIn('sample.get("pathogen"', contamination)
        self.assertIn('sample.get("feces"', contamination)
        self.assertIn("sample_positions", contamination)
        self.assertNotIn("for entity in entities", contamination.split("return clampf", 1)[0])
        self.assertIn("world.get_water_contamination(tile_pos)", self.dwarf)

    def test_medical_care_supports_recovery_instead_of_curing_instantly(self):
        self.assertIn("patient.disease_severity = maxf", self.dwarf)
        self.assertIn("patient.recovery_streak +=", self.dwarf)
        self.assertNotIn("patient.has_infection = false", self.dwarf)

    def test_water_wells_are_physical_limited_buildings(self):
        self.assertIn("WATER_WELL", self.building)
        self.assertIn("func draw_water", self.building)
        self.assertIn("water_volume -= amount", self.building)
        self.assertIn("func _ensure_basic_water_supply", self.main)
        self.assertIn("existing_wells >= 2", self.main)

    def test_old_saves_receive_wells_and_keep_water_quality(self):
        self.assertIn("main._ensure_basic_water_supply()", self.save)
        for field in ("water_volume", "water_capacity", "water_contamination"):
            self.assertGreaterEqual(self.save.count(field), 2)

    def test_thirsty_humanoids_prefer_wells_to_floor_water(self):
        satisfy = self.dwarf.split("func _satisfy_needs", 1)[1].split(
            "func _drink_from_water_well", 1
        )[0]
        self.assertLess(
            satisfy.index("_drink_from_water_well"),
            satisfy.index("_drink_from_splatters"),
        )
        self.assertIn('current_task = "Yendo al pozo"', self.dwarf)
        self.assertIn("nearest_well.draw_water(0.35)", self.dwarf)

    def test_wells_recharge_slowly_and_inherit_local_pollution(self):
        self.assertIn("func _tick_water_infrastructure", self.main)
        self.assertIn("world.get_water_contamination(well.tile_pos)", self.main)
        self.assertIn("well.recharge_water(0.12", self.main)
        self.assertIn("pathogen_exposure = minf", self.dwarf)

    def test_social_information_has_sources_confidence_and_contradictions(self):
        for field in (
            '"confidence"',
            '"sources"',
            '"subject_id"',
            '"witnessed"',
            '"last_heard_minute"',
        ):
            self.assertIn(field, self.dwarf)
        self.assertIn("Dos afirmaciones diferentes", self.dwarf)
        self.assertIn("existing[\"confidence\"] = maxf", self.dwarf)

    def test_social_memory_is_bounded_and_decays_off_hot_path(self):
        self.assertIn("MAX_SOCIAL_BELIEFS: int = 24", self.dwarf)
        self.assertIn("BELIEF_FORGET_DAYS: int = 30", self.dwarf)
        self.assertIn("simulation_minute % 60 != id % 60", self.dwarf)
        self.assertIn("social_beliefs = retained.slice", self.dwarf)

    def test_relationships_are_normalized_and_have_threshold_consequences(self):
        self.assertIn("func _normalized_relationship_value", self.dwarf)
        self.assertIn("(value - 50.0) / 50.0", self.dwarf)
        self.assertIn("if updated >= 0.55:", self.dwarf)
        self.assertIn("elif updated <= -0.45:", self.dwarf)
        self.assertIn("randf_range(0.60, 0.95)", self.main)
        self.assertNotIn("60 + (randi() % 40)", self.main)

    def test_social_cognition_survives_save_load(self):
        for field in (
            "social_beliefs",
            "social_reputation",
            "last_belief_decay_day",
            "conversations_held",
        ):
            self.assertGreaterEqual(self.save.count(field), 2)

    def test_conversation_uses_trust_personality_and_reciprocity(self):
        social = self.dwarf.split("func tick_social", 1)[1].split(
            "# ---- INSPECT ----", 1
        )[0]
        self.assertIn("_social_compatibility_with", social)
        self.assertIn("speaker_honesty", social)
        self.assertIn("modify_relationship(e.id", social)
        self.assertIn("e.modify_relationship(id", social)

    def test_interface_uses_a_reusable_2004_desktop_visual_language(self):
        for token in (
            "UI_CLASSIC_FACE",
            "UI_CLASSIC_TITLE",
            "UI_CLASSIC_SHADOW",
            "func _draw_classic_bevel",
            "func _draw_classic_titlebar",
            "func _draw_application_frame",
        ):
            self.assertIn(token, self.renderer)

    def test_real_godot_controls_share_the_classic_theme(self):
        self.assertIn("func _apply_classic_control_theme", self.renderer)
        self.assertIn('set_stylebox("normal", "Button"', self.renderer)
        self.assertIn('set_stylebox("pressed", "Button"', self.renderer)
        self.assertIn('set_stylebox("panel", "Panel"', self.renderer)

    def test_main_hud_is_presented_as_a_desktop_application(self):
        self.assertIn('"Bigli World Simulator"', self.renderer)
        self.assertIn('"Archivo   Ver   Simulación', self.renderer)
        self.assertIn('"Propiedades de la colonia"', self.renderer)
        self.assertIn('"Registro de sucesos"', self.renderer)

    def test_desktop_chrome_reserves_space_and_preserves_mouse_targeting(self):
        self.assertIn("UI_CONTENT_TOP: int = 44", self.renderer)
        self.assertGreaterEqual(self.renderer.count("UI_CONTENT_TOP + z * _char_size.y"), 2)
        self.assertIn("mouse_pos.y - UI_CONTENT_TOP", self.renderer)
        frame = self.renderer.split("func _draw_application_frame", 1)[1].split(
            "func _apply_night_lighting", 1
        )[0]
        self.assertNotIn("_draw_classic_bevel(outer", frame)

    def test_weather_effects_use_a_fixed_surface_budget(self):
        self.assertIn("WEATHER_SURFACE_BUDGET: int = 1024", self.world)
        self.assertIn("func _take_weather_surface_batch", self.world)
        rain = self.world.split("func _apply_rain", 1)[1].split(
            "func _apply_snow", 1
        )[0]
        self.assertNotIn("for z in range(depth)", rain)
        self.assertIn("for pos_value in surface_batch", rain)

    def test_job_housekeeping_is_not_repeated_every_simulation_tick(self):
        tick = self.main.split("func _tick()", 1)[1].split(
            "func _recover_orphaned_jobs", 1
        )[0]
        housekeeping = tick.split("_recover_orphaned_jobs()", 1)[0]
        self.assertIn("_simulation_tick_clock % 10 == 0", housekeeping)
        self.assertIn("if minute_ticked and e4.get(\"is_resting_medical\")", tick)

    def test_every_pregame_screen_receives_obvious_classic_chrome(self):
        self.assertIn("func _draw_fullscreen_desktop_shell", self.renderer)
        self.assertEqual(
            self.renderer.count("_draw_fullscreen_desktop_shell("),
            7,
        )

    def test_classic_chrome_uses_real_interactive_controls(self):
        for token in (
            "func _create_functional_classic_chrome",
            "MenuButton.new()",
            "popup.id_pressed.connect",
            "window_button.pressed.connect",
            "DisplayServer.window_set_mode",
            "get_tree().quit()",
        ):
            self.assertIn(token, self.renderer)

    def test_classic_menus_dispatch_existing_game_actions(self):
        for key in ("KEY_F5", "KEY_F9", "KEY_SPACE", "KEY_H", "KEY_J", "KEY_L", "KEY_T"):
            self.assertIn(key, self.renderer)
        self.assertIn("main_node._handle_key(event)", self.renderer)

    def test_legend_matches_current_runtime_symbols(self):
        self.assertIn("func _build_current_legend_text", self.renderer)
        for current_symbol in ('▣  árbol', 'd / w  habitante', 'O  cofre', 'F3            diagnóstico'):
            self.assertIn(current_symbol, self.renderer)
        self.assertNotIn("T : Arbol", self.renderer)


if __name__ == "__main__":
    unittest.main()
