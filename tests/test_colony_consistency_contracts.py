import pathlib
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[1]


class ColonyConsistencyContracts(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.dwarf = (ROOT / "df_mode/df_dwarf.gd").read_text(encoding="utf-8")
        cls.world = (ROOT / "df_mode/df_world.gd").read_text(encoding="utf-8")
        cls.world_gen = (ROOT / "df_mode/df_world_gen.gd").read_text(encoding="utf-8")
        cls.main = (ROOT / "df_mode/df_main.gd").read_text(encoding="utf-8")
        cls.save = (ROOT / "df_mode/df_save_load.gd").read_text(encoding="utf-8")
        cls.item = (ROOT / "df_mode/df_item.gd").read_text(encoding="utf-8")
        cls.building = (ROOT / "df_mode/df_building.gd").read_text(encoding="utf-8")
        cls.renderer = (ROOT / "df_mode/df_renderer.gd").read_text(encoding="utf-8")
        cls.job = (ROOT / "df_mode/df_job.gd").read_text(encoding="utf-8")
        cls.planet = (ROOT / "df_mode/df_planet_regions.gd").read_text(encoding="utf-8")
        cls.pathfinding = (ROOT / "df_mode/df_pathfinding.gd").read_text(
            encoding="utf-8"
        )
        cls.story_director = (ROOT / "df_mode/df_story_director.gd").read_text(
            encoding="utf-8"
        )

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
        for current_symbol in ('♣  árbol', '@  habitante', 'O  cofre', 'F3            diagnóstico'):
            self.assertIn(current_symbol, self.renderer)
        self.assertNotIn("T : Arbol", self.renderer)

    def test_unavailable_menus_are_disabled_instead_of_silently_inert(self):
        self.assertIn("func _sync_classic_control_availability", self.renderer)
        self.assertIn("classic_menu_buttons[2].disabled = not playing", self.renderer)
        self.assertIn("classic_menu_buttons[3].disabled = not playing", self.renderer)
        self.assertIn("file_popup.set_item_disabled(0, not playing)", self.renderer)

    def test_missing_bed_returns_a_vector_sentinel_instead_of_null(self):
        finder = self.dwarf.split("func _find_unclaimed_bed", 1)[1].split(
            "func _is_bed_claimed", 1
        )[0]
        self.assertIn("-> Vector3i", finder)
        self.assertIn("Vector3i(-1, -1, -1)", finder)
        self.assertNotIn("return null", finder)
        self.assertIn("for item_value in world.items", finder)

    def test_settlement_residents_use_the_distributed_ai_branch(self):
        tick = self.main.split("func _tick()", 1)[1].split(
            "func _record_performance_sample", 1
        )[0]
        self.assertIn("if is_dwarf4 and not is_settlement_resident:", tick)
        self.assertIn('set_meta("settlement_minute_pending", true)', tick)
        self.assertIn("resident_minute_due", tick)
        self.assertNotIn("if minute_ticked or posmod(_absolute_simulation_tick", tick)
        self.assertIn("SETTLEMENT_RESIDENT_TICK_BUCKETS: int = 12", self.main)

    def test_planet_regions_wrap_longitude_but_keep_real_poles(self):
        self.assertIn("posmod(region.x, planet_width)", self.planet)
        self.assertIn("clampi(region.y, 0, planet_depth - 1)", self.planet)
        self.assertIn("if direction.y < 0 and region.y <= 0", self.planet)
        self.assertIn("if direction.y > 0 and region.y >= planet_depth - 1", self.planet)

    def test_crossing_a_local_edge_streams_a_neighbor_region(self):
        for token in (
            "func _request_planet_transition",
            "func _build_planet_region",
            "func _poll_planet_transition",
            "func _activate_planet_region",
            "_planet_transition_thread.start",
            "planet_region_cache[old_key] = world",
            "planet_designation_cache[old_key] = designation",
        ):
            self.assertIn(token, self.main)
        movement = self.main.split("func _try_move_possessed", 1)[1].split(
            "func _planet_dimensions", 1
        )[0]
        self.assertIn("_request_planet_transition(direction)", movement)
        self.assertIn("BORDER_EXIT_MARGIN", movement)
        self.assertIn("leaving_through_border", movement)

    def test_blocked_work_targets_choose_a_reachable_same_level_neighbor(self):
        blocked_target = self.pathfinding.split("if target_blocked:", 1)[1].split(
            "var key = _cache_key", 1
        )[0]
        self.assertIn("var candidates: Array[Vector3i]", blocked_target)
        self.assertIn("for candidate in candidates:", blocked_target)
        self.assertIn("_find_path_internal(world, from, candidate", blocked_target)
        self.assertIn("return shortest_path", blocked_target)
        self.assertNotIn("Vector3i(0,1,0)", blocked_target)
        self.assertNotIn("Vector3i(0,-1,0)", blocked_target)

    def test_planet_region_is_visible_and_saved(self):
        self.assertIn('"active_planet_region"', self.save)
        self.assertIn("Planeta [%d,%d]", self.renderer)
        self.assertIn("Región %d,%d", self.renderer)

    def test_inactive_planet_regions_survive_save_and_load(self):
        for token in (
            "static func serialize_region_world",
            "static func deserialize_region_world",
            "static func _serialize_planet_region_cache",
            "static func _restore_planet_region_cache",
            'data["planet_regions"] = _serialize_planet_region_cache(main)',
            '_restore_planet_region_cache(main, data.get("planet_regions", {}))',
        ):
            self.assertIn(token, self.save)
        self.assertEqual(
            self.save.count('data["planet_regions"] = _serialize_planet_region_cache(main)'),
            2,
        )
        self.assertEqual(
            self.save.count('_restore_planet_region_cache(main, data.get("planet_regions", {}))'),
            2,
        )

    def test_restored_region_rebuilds_typed_entity_indexes_and_jobs(self):
        restore = self.save.split("static func deserialize_region_world", 1)[1].split(
            "static func _serialize_planet_region_cache", 1
        )[0]
        self.assertIn("restored_world.add_entity(entity)", restore)
        self.assertIn("restored_world.buildings.append", restore)
        self.assertIn("restored_world.workshops.append", restore)
        self.assertIn("restored_world.stockpiles.append", restore)
        self.assertIn("restored_designation.job_queue.append", restore)

    def test_streamed_regions_receive_biome_fauna_and_history_once(self):
        for token in (
            "func _populate_region_fauna",
            "func _populate_streamed_planet_region",
            "history_gen.materialize_near_embark(target_world, world_gen, region)",
            'target_world.set_meta("regional_population_complete", true)',
            'target_world.get_meta("regional_population_complete", false)',
        ):
            self.assertIn(token, self.main)
        fauna = self.main.split("func _populate_region_fauna", 1)[1].split(
            "func _populate_streamed_planet_region", 1
        )[0]
        self.assertIn("desired_count", fauna)
        self.assertIn("attempt_budget", fauna)
        self.assertNotIn("for z in range(target_world.depth)", fauna)

    def test_region_population_marker_survives_both_save_formats(self):
        self.assertGreaterEqual(
            self.save.count('"regional_population_complete"'),
            6,
        )
        self.assertEqual(
            self.save.count('data["world"]["regional_population_complete"]'),
            2,
        )
        self.assertEqual(
            self.save.count('w.set_meta("regional_population_complete"'),
            2,
        )

    def test_ocean_embark_is_relocated_to_a_land_dominated_region(self):
        for token in (
            "func _region_is_habitable",
            "func _resolve_habitable_embark_region",
            "world_gen.is_ocean",
            "world_gen.is_lake",
            ">= 0.72",
            "_resolve_habitable_embark_region(embark_cursor)",
        ):
            self.assertIn(token, self.main)

    def test_camera_uses_visible_region_bounds_before_streaming(self):
        for token in (
            "func _camera_region_limits",
            "func _clamp_camera_to_region_view",
            "_clamp_camera_to_region_view()",
            "_request_planet_transition(direction)",
        ):
            self.assertIn(token, self.main)
        held = self.main.split("func _process_held_movement", 1)[1].split(
            "func _move_planet_camera", 1
        )[0]
        self.assertIn("_move_planet_camera(direction, 2)", held)

    def test_renderer_never_exposes_the_gray_control_outside_a_region(self):
        self.assertIn(
            "Rect2(border_x, UI_CONTENT_TOP, vw * _char_size.x, vh * _char_size.y), Color.BLACK, true",
            self.renderer,
        )
        draw_tile = self.renderer.split("func _draw_tile", 1)[1].split(
            "func _process", 1
        )[0]
        self.assertIn("if bg.a > 0.01:", draw_tile)
        self.assertNotIn("bg != Color.BLACK", draw_tile)

    def test_actor_movement_uses_the_spatial_grid(self):
        self.assertIn("func is_actor_occupied", self.world)
        self.assertIn("func move_entity", self.world)
        movement = self.dwarf.split("func _move_toward", 1)[1].split(
            "func get_display_char", 1
        )[0]
        self.assertIn("world.is_actor_occupied(next_step, self)", movement)
        self.assertIn("world.move_entity(self, next_step)", movement)
        self.assertNotIn("for e in world.entities:", movement)

    def test_carpentry_project_is_unique_and_announced_once(self):
        for token in (
            "func _find_open_colony_project_job",
            '_find_open_colony_project_job("carpentry_chain")',
            '"carpentry_project_announced"',
        ):
            self.assertIn(token, self.main)

    def test_refcounted_items_do_not_use_dictionary_default_get(self):
        self.assertNotIn('e.get("material_name", "")', self.dwarf)
        self.assertIn("e.material_name.to_lower()", self.dwarf)
        self.assertNotIn('hunting_target.get("name", "presa")', self.dwarf)
        self.assertNotIn('target.get("name", "presa")', self.dwarf)

    def test_planetary_size_matches_the_largest_df_horizontal_scale(self):
        for token in (
            "DF_LARGE_MACRO_REGIONS: int = 257",
            "DF_BLOCKS_PER_MACRO_REGION: int = 16",
            "DF_TILES_PER_BLOCK: int = 48",
            "STREAMED_REGION_TILES: int = 256",
            "MAX_PLANET_REGIONS_PER_AXIS",
            "MAX_PLANET_TILES_PER_AXIS",
        ):
            self.assertIn(token, self.world_gen)
        self.assertIn(
            "DFWorldGen.MAX_PLANET_REGIONS_PER_AXIS",
            self.main,
        )
        self.assertIn("Planetario (771²)", self.renderer)
        self.assertIn("197.376 casillas por eje", self.renderer)

    def test_surface_geology_creates_visible_mineable_outcrops(self):
        self.assertIn("_place_surface_rock_outcrops(world)", self.world_gen)
        outcrops = self.world_gen.split(
            "func _place_surface_rock_outcrops", 1
        )[1].split("func _place_trees_in_local", 1)[0]
        self.assertIn("DFWorld.TileType.WALL", outcrops)
        self.assertIn('"natural_outcrop": true', outcrops)
        self.assertIn("_geo_to_material(rock_layer)", outcrops)

    def test_expensive_autonomous_decisions_are_distributed(self):
        self.assertIn("posmod(simulation_tick + id, 12) == 0", self.dwarf)
        self.assertIn("if autonomous_decision_due:", self.dwarf)
        self.assertIn("_move_toward(world, path.back())", self.dwarf)

    def test_ascii_language_is_semantic_and_low_noise(self):
        self.assertIn('TileType.TREE: "\\u2663"', self.world)
        self.assertIn('TileType.GRASS: ","', self.world)
        self.assertIn('"natural_outcrop", false', self.world)
        self.assertIn('return "\\u25B2"', self.world)
        self.assertIn('return "@"', self.dwarf)
        self.assertIn('return "&"', self.dwarf)
        self.assertIn("▲  afloramiento de roca minable", self.renderer)
        self.assertIn("EDIFICIOS", self.renderer)

    def test_constructed_walls_autoconnect_and_items_have_distinct_glyphs(self):
        self.assertIn("func _connected_wall_char", self.world)
        for glyph in ("\\u250C", "\\u2510", "\\u2514", "\\u2518", "\\u253C"):
            self.assertIn(glyph, self.world)
        for item_rule in (
            'if item_type == "door": return "+"',
            'if is_bed: return "="',
            'if item_type in ["stone", "ore", "bar"]: return "*"',
            'if item_type == "wood": return "|"',
            'if item_type == "seed": return ";"',
        ):
            self.assertIn(item_rule, self.item)
        self.assertIn("muros construidos conectados", self.renderer)

    def test_floor_construction_replaces_natural_ground_and_consumes_on_success(self):
        build_floor = self.world.split("func build_floor", 1)[1].split(
            "func build_stairs_up", 1
        )[0]
        self.assertIn("or is_floor(pos)", build_floor)
        self.assertIn("TileType.CONSTRUCTED_FLOOR", build_floor)
        execute = self.dwarf.split("func _execute_job", 1)[1].split(
            "func _execute_empty_latrine_job", 1
        )[0]
        self.assertIn("if success and floor_material_index >= 0:", execute)
        self.assertIn("if success and wall_material_index >= 0:", execute)
        self.assertIn("if success and workshop_material_index >= 0:", execute)

    def test_story_director_turns_real_state_into_visible_hooks(self):
        for token in (
            "func _find_best_hook",
            "func _build_hook",
            '"desire"',
            '"problem"',
            '"stakes"',
            "hunger * 32.0",
            "thirst * 36.0",
            "stress * 28.0",
        ):
            self.assertIn(token, self.story_director)
        self.assertIn("active_story_hook", self.main)
        self.assertIn('"HISTORIA EN CURSO"', self.renderer)

    def test_possession_has_a_before_after_consequence_report(self):
        for token in (
            "func begin_possession",
            "func end_possession",
            "func _snapshot",
            "func _count_relationship_changes",
            "func _interpret_possession",
            '"consequences"',
        ):
            self.assertIn(token, self.story_director)
        self.assertIn("story_director.begin_possession", self.main)
        self.assertIn("story_director.end_possession", self.main)
        self.assertIn("renderer.follow_dwarf = released_dwarf.id", self.main)
        self.assertIn("func _focus_story_hook", self.main)
        self.assertIn("KEY_Y", self.main)
        self.assertIn('"CONSECUENCIAS"', self.renderer)

    def test_possession_supports_actions_and_resolvable_objectives(self):
        for token in (
            '"objective"',
            '"objective_type"',
            "func record_action",
            "func _objective_was_resolved",
            '"objective_resolved"',
        ):
            self.assertIn(token, self.story_director)
        for token in (
            "func _possessed_context_action",
            "func _consume_possessed_need_item",
            "func _possessed_drop_item",
            "KEY_E",
            "KEY_R",
            "story_director.record_action",
        ):
            self.assertIn(token, self.main)
        self.assertIn('"E", "Actuar/usar"', self.renderer)
        self.assertIn('"OBJETIVO CUMPLIDO"', self.renderer)

    def test_manual_pickup_and_drop_keep_world_indexes_consistent(self):
        actions = (ROOT / "core/actions/df_actor_action_executor.gd").read_text(
            encoding="utf-8"
        )
        self.assertIn("world.remove_entity(found)", actions)
        self.assertIn("world.add_entity(item)", actions)
        self.assertNotIn("world.entities.erase(found)", actions)
        self.assertNotIn("world.entities.append(item)", actions)

    def test_management_window_uses_the_real_inhabitant_name_api(self):
        management = self.renderer.split("func _refresh_management_pages", 1)[1].split(
            "func _build_current_legend_text", 1
        )[0]
        self.assertIn('dwarf.has_method("get_entity_name")', management)
        self.assertIn('dwarf.get("name")', management)
        self.assertNotIn("dwarf.entity_name", management)

    def test_neighbor_regions_do_not_overlap_or_repeat_local_noise(self):
        self.assertIn("var local_region_span: float = 1.0", self.world_gen)
        self.assertIn("func _get_global_tile_sample", self.world_gen)
        self.assertIn("func _local_tile_random", self.world_gen)
        for global_sample in (
            "global_tile.x + seed_offset",
            "global_tile.y - seed_offset",
            "global_cave_tile.x",
            "global_cave_tile.y",
            "global_rock_tile.x",
            "global_rock_tile.y",
        ):
            self.assertIn(global_sample, self.world_gen)
        self.assertNotIn(
            "_octave_noise(float(x) + seed_offset, float(z) - seed_offset",
            self.world_gen,
        )
        self.assertIn("_local_tile_random(x, z, world.width, world.depth, 301)", self.world_gen)


if __name__ == "__main__":
    unittest.main()
