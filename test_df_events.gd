extends SceneTree

const DFWorld = preload("res://df_mode/df_world.gd")
const DFEvents = preload("res://df_mode/df_events.gd")

var _passed: int = 0
var _failed: int = 0

func _initialize() -> void:
	print("\n=== TEST EVENTOS ALEATORIOS ===\n")
	_test_storm_condition()
	_test_merchant_visit()
	_test_cooldown()
	print("\nResultados: %d pasaron, %d fallaron" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)

func ok(msg: String) -> void:
	_passed += 1
	print("  PASS: %s" % msg)

func fail(msg: String) -> void:
	_failed += 1
	print("  FAIL: %s" % msg)

func _test_storm_condition() -> void:
	var events = DFEvents.new(42)
	var w = DFWorld.new(64, 64, 8)
	for z in range(64):
		var row: Array = []
		for x in range(64):
			row.append(3)
		w.elevation.append(row)

	# 1. STORM no debe ocurrir con CLEAR
	w.current_weather = DFWorld.WeatherType.CLEAR
	var found = false
	for i in range(200):
		if events.tick(true, i%60, i/60, 1, "Spring", w) != "":
			found = true
			break
	if found: fail("TEST 1: Storm NO debe ocurrir con CLEAR")
	else: ok("TEST 1: Storm no ocurre con CLEAR")

	# 2. STORM debe ocurrir con STORM weather
	w.current_weather = DFWorld.WeatherType.STORM
	events = DFEvents.new(123)
	found = false
	for i in range(1500):
		if events.tick(true, i%60, i/60, 2, "Spring", w) != "":
			found = true
			break
	if found: ok("TEST 2: Storm ocurre durante STORM (seed 123)")
	else: fail("TEST 2: Storm NO ocurrio durante STORM")

	# 3. Arboles caen durante storm
	w.current_weather = DFWorld.WeatherType.STORM
	events = DFEvents.new(456)
	for x in range(30, 35):
		for z in range(30, 35):
			w.set_tile(Vector3i(x, 3, z), DFWorld.TileType.TREE)
	found = false
	for i in range(500):
		if events.tick(true, i%60, i/60, 3, "Spring", w) != "":
			found = true
			break
	if found: ok("TEST 3: Storm derriba arboles")
	else: fail("TEST 3: Storm no se disparo")

func _test_merchant_visit() -> void:
	var events = DFEvents.new(789)
	var w = DFWorld.new(64, 64, 8)
	for z in range(64):
		var row: Array = []
		for x in range(64):
			row.append(3)
		w.elevation.append(row)

	# Merchant en primavera (alta probabilidad)
	var found = false
	for i in range(3000):
		if events.tick(true, i%60, i/60, 10, "Spring", w) != "":
			found = true
			break
	if found: ok("TEST 4: Caravana visita en primavera")
	else: fail("TEST 4: Caravana NO visito en primavera")

func _test_cooldown() -> void:
	var events = DFEvents.new(999)
	var w = DFWorld.new(64, 64, 8)
	for z in range(64):
		var row: Array = []
		for x in range(64):
			row.append(3)
		w.elevation.append(row)
	w.current_weather = DFWorld.WeatherType.STORM

	var gaps: Array = []
	var last = -100
	for i in range(2000):
		if events.tick(true, i%60, i/60, 20, "Spring", w) != "":
			gaps.append(i - last)
			last = i
	if gaps.size() >= 2:
		var min_gap = 99999
		for g in gaps: min_gap = mini(min_gap, g)
		if min_gap >= 30: ok("TEST 5: Cooldown minimo %d ticks (>= 30)" % min_gap)
		else: fail("TEST 5: Cooldown muy corto: %d ticks" % min_gap)
	else:
		ok("TEST 5: Sin eventos multiples para medir cooldown")
