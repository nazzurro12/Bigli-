extends Node

## Test de integracion para DF Mode
## Usa printerr() para evitar buffering de stdout en modo headless.
## Mapa 16x16 (~7-9 enanos), 200 frames, ~200-400 game-ticks.
## Verifica al menos 5 trabajos completados y pico de trabajos > 0.

const DFJob = preload("res://df_mode/df_job.gd")

const SETTINGS_MENU := 0
const GENERATING_WORLD := 1
const PLAYING := 5
const LOADING_PLAYING := 6
const TIMEOUT_FRAMES := 18000
const TARGET_FRAMES := 200
const MIN_JOBS := 5

var _game_main: Node = null
var _phase := "WAITING_SETTINGS"
var _phase_frames := 0
var _frame_count := 0
var _completed_jobs: Array[int] = []
var _observed: Dictionary = {}
var _peak_jobs := 0

func _ready() -> void:
	printerr("[TEST] Integration test - 200 frames, 16x16 map")
	var scene: PackedScene = load("res://df_mode/df_main.tscn")
	if scene == null: _quit(1, "Cannot load df_main.tscn")
	_game_main = scene.instantiate()
	add_child(_game_main)

func _process(_d: float) -> void:
	if _game_main == null: return
	_phase_frames += 1
	var st: int = int(_game_main.current_state)
	
	match _phase:
		"WAITING_SETTINGS":
			if st == SETTINGS_MENU:
				_game_main.generation_seed = 424242
				_game_main.setting_size = 0
				var gs = load("res://world/world_generation_settings.tres")
				gs.local_map_size = 16
				_game_main.set_meta("quick_start_pending", true)
				_game_main.current_state = GENERATING_WORLD
				_change("GENERATING")
				printerr("[TEST] Quick Start sent (16x16)")
			elif _phase_frames > 300: _quit(1, "No settings menu")
		
		"GENERATING":
			if st == PLAYING: _start_ticking()
			elif st == LOADING_PLAYING: _change("WAITING_LOAD")
			elif _phase_frames > TIMEOUT_FRAMES: _quit(1, "Gen timeout")
		
		"WAITING_LOAD":
			if st == PLAYING: printerr("[TEST] Loaded"); _start_ticking()
			elif _phase_frames > TIMEOUT_FRAMES: _quit(1, "Load timeout")
		
		"TICKING":
			if _phase_frames > TIMEOUT_FRAMES: _quit(1, "Tick timeout")
			_count()
			_frame_count += 1
			if _frame_count % 50 == 0:
				printerr("[TEST] Frame %d/%d jobs=%d" % [_frame_count, TARGET_FRAMES, _completed_jobs.size()])
			if _frame_count >= TARGET_FRAMES: _verify()

func _start_ticking() -> void:
	if _game_main.world == null: _quit(1, "No world")
	if _game_main.designation == null: _quit(1, "No designations")
	_game_main.tick_interval = 0.01
	printerr("[TEST] Dwarves: %d Starting %d frames" % [_game_main.world.dwarves.size(), TARGET_FRAMES])
	_change("TICKING")
	_count()

func _count() -> void:
	if _game_main.designation == null: return
	var jobs = _game_main.designation.job_queue
	_peak_jobs = maxi(_peak_jobs, jobs.size())
	var cur: Dictionary = {}
	for j in jobs:
		var jid: int = j.get_instance_id()
		cur[jid] = true
		_observed[jid] = j.state
		if j.state == DFJob.JobState.COMPLETED and not jid in _completed_jobs:
			_completed_jobs.append(jid)
			printerr("[TEST] Job completed: %s (#%d)" % [j.get_description(), _completed_jobs.size()])
	for k in _observed.keys():
		if cur.has(k): continue
		if _observed[k] == DFJob.JobState.COMPLETED and not k in _completed_jobs:
			_completed_jobs.append(int(k))
			printerr("[TEST] Job completed (cleaned): #%d" % _completed_jobs.size())
		_observed.erase(k)

func _verify() -> void:
	printerr("[TEST] === RESULTS ===")
	printerr("[TEST] Frames: %d Jobs: %d Peak: %d" % [_frame_count, _completed_jobs.size(), _peak_jobs])
	if _completed_jobs.size() >= MIN_JOBS and _peak_jobs > 0:
		printerr("[TEST] PASS")
		get_tree().quit(0)
	else:
		printerr("[TEST] FAIL: jobs=%d (need %d) peak=%d" % [_completed_jobs.size(), MIN_JOBS, _peak_jobs])
		get_tree().quit(1)

func _change(p: String) -> void: _phase = p; _phase_frames = 0
func _quit(code: int, msg: String) -> void: printerr("[TEST] FAIL: %s" % msg); get_tree().quit(code)
