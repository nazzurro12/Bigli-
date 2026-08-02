extends RefCounted
class_name DFDwarfNeeds

static func process_metabolism(dwarf, world: RefCounted) -> void:
	var bm: float = dwarf.body_mass_kg * (dwarf.genome.size_multiplier if dwarf.genome else 1.0)
	var met_rate: float = dwarf.genome.metabolic_rate if dwarf.genome else 1.0
	var alc_tol: float = dwarf.genome.alcohol_tolerance if dwarf.genome else 1.0

	var food_stored: float = dwarf.body.ingested_substances.get("food", 0.0)
	if food_stored > 0.0:
		var digest = 0.002 * met_rate
		var absorbed = minf(food_stored, digest)
		dwarf.hunger = maxf(0.0, dwarf.hunger - absorbed * 10.0)
		dwarf.body.ingested_substances["food"] = food_stored - absorbed
		if dwarf.body.ingested_substances["food"] <= 0.0:
			dwarf.body.ingested_substances.erase("food")

	var water_stored: float = dwarf.body.ingested_substances.get("water", 0.0)
	if water_stored > 0.0:
		var absorb_water = minf(water_stored, 0.003 * met_rate)
		dwarf.thirst = maxf(0.0, dwarf.thirst - absorb_water * 10.0)
		dwarf.body.ingested_substances["water"] = water_stored - absorb_water
		if dwarf.body.ingested_substances["water"] <= 0.0:
			dwarf.body.ingested_substances.erase("water")

	var alc: float = dwarf.body.ingested_substances.get("beer", 0.0)
	if alc > 0.0:
		var bac: float = alc / bm
		dwarf.body.ebriety = clampf(bac / (0.1 * alc_tol), 0.0, 4.0)
		var burned: float = 0.004 * met_rate
		dwarf.body.ingested_substances["beer"] = maxf(0.0, alc - burned)
		if dwarf.body.ingested_substances["beer"] <= 0.0:
			dwarf.body.ingested_substances.erase("beer")
