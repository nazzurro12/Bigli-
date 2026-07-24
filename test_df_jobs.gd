extends Node

var _game_main = null
var _phase = "INIT"
var _tick_count = 0
var _state_wait_frames = 0
var _pos_snapshot = []

func _ready():
    var df_main_scene = preload("res://df_mode/df_main.tscn")
    var instance = df_main_scene.instantiate()
    add_child(instance)
    _game_main = instance
    _game_main.set_meta("quick_start_pending", true)
    _state_wait_frames = 0
    _phase = "WAITING_SETTINGS"

func _process(delta):
    if _game_main == null:
        return
    
    match _phase:
        "WAITING_SETTINGS":
            if _game_main.current_state == 5:
                _phase = "GENERATING"
            _state_wait_frames += 1
            if _state_wait_frames > 300:
                _phase = "TIMEOUT"
        
        "GENERATING":
            _state_wait_frames += 1
            if _state_wait_frames > 600:
                _phase = "TIMEOUT"
        
        "CHECKING_JOBS":
            _check_jobs()
            get_tree().quit()
        
        "TIMEOUT":
            print("[TEST] TIMEOUT - game didn't reach playing state")
            get_tree().quit()

func _check_jobs():
    var world = _game_main.world
    var designation = _game_main.designation
    if designation == null:
        print("[TEST] ERROR: designation is null")
        return
    
    var jobs = designation.job_queue
    print("[TEST] Total jobs in queue: " + str(jobs.size()))
    
    var unassigned = 0
    var assigned = 0
    var in_progress = 0
    var completed = 0
    var cancelled = 0
    
    for j in jobs:
        var s = j.state
        if s == 0: unassigned += 1
        elif s == 1: assigned += 1
        elif s == 2: in_progress += 1
        elif s == 3: completed += 1
        elif s == 4: cancelled += 1
    
    print("[TEST] UNASSIGNED: " + str(unassigned))
    print("[TEST] ASSIGNED: " + str(assigned))
    print("[TEST] IN_PROGRESS: " + str(in_progress))
    print("[TEST] COMPLETED: " + str(completed))
    print("[TEST] CANCELLED: " + str(cancelled))
    
    # Check dwarves
    var dwarves_with_jobs = 0
    for e in world.entities:
        var ct = e.get("creature_type")
        if ct == "dwarf" and e.get("is_alive") != false:
            if e.current_job != null:
                dwarves_with_jobs += 1
                print("[TEST]   Dwarf " + e.name + " has job: " + e.current_task)
    
    print("[TEST] Dwarves with jobs: " + str(dwarves_with_jobs))
    
    if jobs.size() > 0:
        print("[TEST] TEST OK: Jobs found in queue")
    else:
        print("[TEST] TEST FAILED: No jobs generated")
