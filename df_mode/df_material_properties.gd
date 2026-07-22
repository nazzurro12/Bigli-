extends RefCounted
class_name DFMaterialProperties

enum State { SOLID, LIQUID, GAS }

static func get_schema() -> Dictionary:
	return {
		"density": 0.0,              # g/cm³
		"melting_point": 0.0,        # K (0 = no funde)
		"boiling_point": 0.0,        # K
		"specific_heat": 0.0,        # J/(kg·K)
		"conductivity": 0.0,         # W/(m·K)
		"hardness": 0.0,             # Mohs 0-10
		"tensile_strength": 0.0,     # MPa
		"compressive_strength": 0.0, # MPa
		"impact_fracture": 0.0,      # kJ/m²
		"shear_fracture": 0.0,       # kJ/m²
		"porosity": 0.0,             # 0-1
		"flammability": 0.0,         # 0-1
		"elasticity": 0.0,           # GPa (Young's modulus)
		"yield_strength": 0.0,       # MPa
		"magical_resonance": 0.0,    # 0-1
		"edible": false,
		"nutrition": 0.0,
		"state": State.SOLID,
	}

static func type_defaults() -> Dictionary:
	return {
		"metal": {
			"density": 7.5, "melting_point": 1500.0, "boiling_point": 2800.0,
			"specific_heat": 450.0, "conductivity": 60.0, "hardness": 4.0,
			"tensile_strength": 300.0, "compressive_strength": 400.0,
			"impact_fracture": 150.0, "shear_fracture": 120.0,
			"porosity": 0.0, "flammability": 0.0, "elasticity": 150.0,
			"yield_strength": 200.0, "magical_resonance": 0.2,
			"edible": false, "nutrition": 0.0, "state": State.SOLID,
		},
		"stone": {
			"density": 2.6, "melting_point": 1500.0, "boiling_point": 2800.0,
			"specific_heat": 800.0, "conductivity": 2.0, "hardness": 4.0,
			"tensile_strength": 10.0, "compressive_strength": 100.0,
			"impact_fracture": 5.0, "shear_fracture": 8.0,
			"porosity": 0.05, "flammability": 0.0, "elasticity": 50.0,
			"yield_strength": 2.0, "magical_resonance": 0.1,
			"edible": false, "nutrition": 0.0, "state": State.SOLID,
		},
		"gem": {
			"density": 3.5, "melting_point": 2000.0, "boiling_point": 3500.0,
			"specific_heat": 700.0, "conductivity": 10.0, "hardness": 7.0,
			"tensile_strength": 5.0, "compressive_strength": 200.0,
			"impact_fracture": 2.0, "shear_fracture": 4.0,
			"porosity": 0.0, "flammability": 0.0, "elasticity": 100.0,
			"yield_strength": 1.0, "magical_resonance": 0.5,
			"edible": false, "nutrition": 0.0, "state": State.SOLID,
		},
		"wood": {
			"density": 0.6, "melting_point": 0.0, "boiling_point": 0.0,
			"specific_heat": 1700.0, "conductivity": 0.15, "hardness": 1.5,
			"tensile_strength": 40.0, "compressive_strength": 10.0,
			"impact_fracture": 20.0, "shear_fracture": 5.0,
			"porosity": 0.4, "flammability": 0.8, "elasticity": 10.0,
			"yield_strength": 5.0, "magical_resonance": 0.3,
			"edible": false, "nutrition": 0.0, "state": State.SOLID,
		},
		"food": {
			"density": 1.0, "melting_point": 0.0, "boiling_point": 0.0,
			"specific_heat": 3000.0, "conductivity": 0.3, "hardness": 0.0,
			"tensile_strength": 0.0, "compressive_strength": 0.0,
			"impact_fracture": 0.0, "shear_fracture": 0.0,
			"porosity": 0.5, "flammability": 0.3, "elasticity": 0.0,
			"yield_strength": 0.0, "magical_resonance": 0.0,
			"edible": true, "nutrition": 0.5, "state": State.SOLID,
		},
		"drink": {
			"density": 1.0, "melting_point": 273.0, "boiling_point": 373.0,
			"specific_heat": 4180.0, "conductivity": 0.6, "hardness": 0.0,
			"tensile_strength": 0.0, "compressive_strength": 0.0,
			"impact_fracture": 0.0, "shear_fracture": 0.0,
			"porosity": 0.0, "flammability": 0.0, "elasticity": 0.0,
			"yield_strength": 0.0, "magical_resonance": 0.0,
			"edible": true, "nutrition": 0.3, "state": State.LIQUID,
		},
		"soil": {
			"density": 1.3, "melting_point": 0.0, "boiling_point": 0.0,
			"specific_heat": 1500.0, "conductivity": 0.5, "hardness": 0.5,
			"tensile_strength": 0.0, "compressive_strength": 1.0,
			"impact_fracture": 0.0, "shear_fracture": 0.0,
			"porosity": 0.6, "flammability": 0.0, "elasticity": 0.0,
			"yield_strength": 0.0, "magical_resonance": 0.0,
			"edible": false, "nutrition": 0.0, "state": State.SOLID,
		},
	}

static func get_overrides() -> Dictionary:
	return {
		"IRON": { "density": 7.87, "melting_point": 1811, "boiling_point": 3134, "specific_heat": 449, "conductivity": 80, "hardness": 4.0, "tensile_strength": 370, "compressive_strength": 500, "impact_fracture": 200, "shear_fracture": 165, "elasticity": 211, "yield_strength": 200, "magical_resonance": 0.1 },
		"STEEL": { "density": 7.85, "melting_point": 1640, "boiling_point": 3000, "specific_heat": 490, "conductivity": 50, "hardness": 5.5, "tensile_strength": 860, "compressive_strength": 700, "impact_fracture": 350, "shear_fracture": 280, "elasticity": 200, "yield_strength": 450, "magical_resonance": 0.05 },
		"PIG_IRON": { "density": 7.2, "melting_point": 1420, "boiling_point": 2900, "specific_heat": 460, "conductivity": 55, "hardness": 4.5, "tensile_strength": 200, "compressive_strength": 400, "elasticity": 180, "yield_strength": 100, "magical_resonance": 0.1 },
		"COPPER": { "density": 8.96, "melting_point": 1358, "boiling_point": 2835, "specific_heat": 385, "conductivity": 401, "hardness": 3.0, "tensile_strength": 220, "compressive_strength": 330, "impact_fracture": 300, "shear_fracture": 200, "elasticity": 130, "yield_strength": 70, "magical_resonance": 0.25 },
		"BRONZE": { "density": 8.7, "melting_point": 1220, "boiling_point": 2600, "specific_heat": 380, "conductivity": 50, "hardness": 4.0, "tensile_strength": 350, "compressive_strength": 400, "impact_fracture": 280, "shear_fracture": 220, "elasticity": 120, "yield_strength": 150, "magical_resonance": 0.3 },
		"BRASS": { "density": 8.5, "melting_point": 1170, "boiling_point": 2500, "specific_heat": 380, "conductivity": 120, "hardness": 3.5, "tensile_strength": 300, "compressive_strength": 350, "elasticity": 110, "yield_strength": 120, "magical_resonance": 0.2 },
		"GOLD": { "density": 19.32, "melting_point": 1337, "boiling_point": 3243, "specific_heat": 129, "conductivity": 318, "hardness": 2.5, "tensile_strength": 100, "compressive_strength": 150, "impact_fracture": 50, "shear_fracture": 30, "elasticity": 78, "yield_strength": 30, "magical_resonance": 0.8 },
		"ROSE_GOLD": { "density": 17.5, "melting_point": 1270, "boiling_point": 3100, "specific_heat": 200, "conductivity": 200, "hardness": 3.0, "tensile_strength": 150, "compressive_strength": 200, "elasticity": 90, "yield_strength": 50, "magical_resonance": 0.7 },
		"SILVER": { "density": 10.49, "melting_point": 1235, "boiling_point": 2485, "specific_heat": 235, "conductivity": 429, "hardness": 2.5, "tensile_strength": 140, "compressive_strength": 180, "impact_fracture": 60, "shear_fracture": 40, "elasticity": 83, "yield_strength": 40, "magical_resonance": 0.7 },
		"STERLING_SILVER": { "density": 10.4, "melting_point": 1200, "boiling_point": 2400, "specific_heat": 240, "conductivity": 380, "hardness": 2.7, "tensile_strength": 160, "compressive_strength": 200, "elasticity": 85, "yield_strength": 50, "magical_resonance": 0.65 },
		"PLATINUM": { "density": 21.45, "melting_point": 2041, "boiling_point": 4098, "specific_heat": 133, "conductivity": 72, "hardness": 4.5, "tensile_strength": 180, "compressive_strength": 250, "impact_fracture": 80, "shear_fracture": 60, "elasticity": 168, "yield_strength": 60, "magical_resonance": 0.5 },
		"TIN": { "density": 7.27, "melting_point": 505, "boiling_point": 2875, "specific_heat": 227, "conductivity": 67, "hardness": 1.5, "tensile_strength": 45, "compressive_strength": 60, "impact_fracture": 30, "shear_fracture": 20, "elasticity": 50, "yield_strength": 15, "magical_resonance": 0.15 },
		"LEAD": { "density": 11.34, "melting_point": 600, "boiling_point": 2022, "specific_heat": 129, "conductivity": 35, "hardness": 1.5, "tensile_strength": 18, "compressive_strength": 25, "impact_fracture": 10, "shear_fracture": 8, "elasticity": 16, "yield_strength": 8, "magical_resonance": 0.3 },
		"NICKEL": { "density": 8.91, "melting_point": 1728, "boiling_point": 3186, "specific_heat": 444, "conductivity": 91, "hardness": 4.0, "tensile_strength": 420, "compressive_strength": 500, "impact_fracture": 250, "shear_fracture": 200, "elasticity": 200, "yield_strength": 150, "magical_resonance": 0.1 },
		"ZINC": { "density": 7.14, "melting_point": 693, "boiling_point": 1180, "specific_heat": 388, "conductivity": 116, "hardness": 2.5, "tensile_strength": 110, "compressive_strength": 140, "elasticity": 100, "yield_strength": 50, "magical_resonance": 0.15 },
		"ADAMANTINE": { "density": 3.5, "melting_point": 5000, "boiling_point": 8000, "specific_heat": 2000, "conductivity": 5, "hardness": 10.0, "tensile_strength": 5000, "compressive_strength": 8000, "impact_fracture": 5000, "shear_fracture": 4000, "elasticity": 1000, "yield_strength": 3000, "magical_resonance": 1.0 },
		"RAW_ADAMANTINE": { "density": 3.2, "melting_point": 5000, "boiling_point": 8000, "hardness": 8.0, "tensile_strength": 4000, "compressive_strength": 6000, "magical_resonance": 1.0 },
		"BISMUTH": { "density": 9.78, "melting_point": 544, "boiling_point": 1837, "specific_heat": 122, "conductivity": 8, "hardness": 2.25, "tensile_strength": 20, "compressive_strength": 30, "elasticity": 32, "yield_strength": 10, "magical_resonance": 0.4 },
		"BISMUTH_BRONZE": { "density": 8.6, "melting_point": 1150, "boiling_point": 2550, "specific_heat": 370, "conductivity": 45, "hardness": 4.2, "tensile_strength": 400, "compressive_strength": 450, "impact_fracture": 300, "shear_fracture": 240, "elasticity": 115, "yield_strength": 180, "magical_resonance": 0.35 },
		"BLACK_BRONZE": { "density": 8.5, "melting_point": 1180, "boiling_point": 2580, "specific_heat": 375, "conductivity": 40, "hardness": 4.5, "tensile_strength": 450, "compressive_strength": 500, "impact_fracture": 320, "shear_fracture": 260, "elasticity": 125, "yield_strength": 200, "magical_resonance": 0.4 },
		"ELECTRUM": { "density": 14.0, "melting_point": 1280, "boiling_point": 2900, "specific_heat": 180, "conductivity": 350, "hardness": 2.8, "tensile_strength": 120, "compressive_strength": 160, "elasticity": 80, "yield_strength": 35, "magical_resonance": 0.75 },
		"BILLON": { "density": 9.5, "melting_point": 1200, "boiling_point": 2600, "specific_heat": 300, "conductivity": 300, "hardness": 2.8, "tensile_strength": 130, "compressive_strength": 170, "elasticity": 82, "yield_strength": 38, "magical_resonance": 0.6 },
		"PEWTER_FINE": { "density": 7.2, "melting_point": 520, "boiling_point": 2600, "specific_heat": 240, "conductivity": 50, "hardness": 1.8, "tensile_strength": 50, "compressive_strength": 70, "elasticity": 48, "yield_strength": 18, "magical_resonance": 0.2 },
		"PEWTER_TRIFLE": { "density": 7.1, "melting_point": 510, "boiling_point": 2580, "hardness": 1.7, "tensile_strength": 48, "compressive_strength": 65, "yield_strength": 16 },
		"PEWTER_LAY": { "density": 7.0, "melting_point": 500, "boiling_point": 2560, "hardness": 1.6, "tensile_strength": 45, "compressive_strength": 60, "yield_strength": 15 },
		"NICKEL_SILVER": { "density": 8.5, "melting_point": 1500, "boiling_point": 2900, "specific_heat": 400, "conductivity": 30, "hardness": 3.5, "tensile_strength": 350, "compressive_strength": 400, "elasticity": 140, "yield_strength": 160, "magical_resonance": 0.2 },
		"ALUMINUM": { "density": 2.7, "melting_point": 933, "boiling_point": 2792, "specific_heat": 897, "conductivity": 237, "hardness": 2.75, "tensile_strength": 90, "compressive_strength": 120, "elasticity": 69, "yield_strength": 35, "magical_resonance": 0.3 },
		"NATIVE_ALUMINUM": { "density": 2.7, "melting_point": 933, "conductivity": 237, "hardness": 2.75, "tensile_strength": 90, "magical_resonance": 0.3 },
		"GRANITE": { "density": 2.7, "melting_point": 1480, "specific_heat": 790, "conductivity": 3.0, "hardness": 6.0, "tensile_strength": 15, "compressive_strength": 200, "impact_fracture": 8, "shear_fracture": 12, "elasticity": 60, "yield_strength": 5, "porosity": 0.02, "magical_resonance": 0.15 },
		"DIORITE": { "density": 2.8, "melting_point": 1500, "specific_heat": 800, "conductivity": 2.5, "hardness": 6.0, "tensile_strength": 14, "compressive_strength": 190, "porosity": 0.02, "magical_resonance": 0.1 },
		"GABBRO": { "density": 2.9, "melting_point": 1520, "specific_heat": 800, "conductivity": 2.5, "hardness": 6.5, "tensile_strength": 16, "compressive_strength": 210, "porosity": 0.01, "magical_resonance": 0.1 },
		"OBSIDIAN": { "density": 2.4, "melting_point": 1100, "specific_heat": 750, "conductivity": 1.5, "hardness": 5.5, "tensile_strength": 12, "compressive_strength": 150, "impact_fracture": 3, "shear_fracture": 5, "elasticity": 50, "yield_strength": 3, "porosity": 0.0, "magical_resonance": 0.6 },
		"MARBLE": { "density": 2.6, "melting_point": 1450, "specific_heat": 880, "conductivity": 2.8, "hardness": 3.5, "tensile_strength": 10, "compressive_strength": 130, "porosity": 0.04, "magical_resonance": 0.3 },
		"LIMESTONE": { "density": 2.5, "melting_point": 1300, "specific_heat": 850, "conductivity": 2.5, "hardness": 3.0, "tensile_strength": 8, "compressive_strength": 95, "porosity": 0.08, "magical_resonance": 0.05 },
		"SANDSTONE": { "density": 2.3, "melting_point": 1400, "specific_heat": 800, "conductivity": 2.0, "hardness": 4.0, "tensile_strength": 6, "compressive_strength": 80, "porosity": 0.12, "magical_resonance": 0.05 },
		"QUARTZITE": { "density": 2.6, "melting_point": 1650, "specific_heat": 750, "conductivity": 3.0, "hardness": 7.0, "tensile_strength": 18, "compressive_strength": 250, "porosity": 0.01, "magical_resonance": 0.2 },
		"SLATE": { "density": 2.7, "melting_point": 1500, "hardness": 5.5, "tensile_strength": 12, "compressive_strength": 170, "porosity": 0.03, "magical_resonance": 0.1 },
		"GNEISS": { "density": 2.7, "melting_point": 1480, "hardness": 6.0, "tensile_strength": 14, "compressive_strength": 190, "porosity": 0.02, "magical_resonance": 0.1 },
		"SCHIST": { "density": 2.6, "melting_point": 1460, "hardness": 4.0, "tensile_strength": 8, "compressive_strength": 110, "porosity": 0.05, "magical_resonance": 0.1 },
		"BASALT": { "density": 2.9, "melting_point": 1080, "specific_heat": 840, "conductivity": 2.0, "hardness": 6.0, "tensile_strength": 16, "compressive_strength": 200, "porosity": 0.02, "magical_resonance": 0.25 },
		"RHYOLITE": { "density": 2.5, "melting_point": 1150, "hardness": 5.5, "tensile_strength": 12, "compressive_strength": 160, "porosity": 0.03, "magical_resonance": 0.15 },
		"ANDESITE": { "density": 2.6, "melting_point": 1250, "hardness": 5.5, "tensile_strength": 13, "compressive_strength": 170, "porosity": 0.03, "magical_resonance": 0.15 },
		"DACITE": { "density": 2.7, "melting_point": 1300, "hardness": 5.5, "tensile_strength": 14, "compressive_strength": 180, "porosity": 0.02, "magical_resonance": 0.15 },
		"HEMATITE": { "density": 5.3, "melting_point": 1830, "specific_heat": 600, "conductivity": 10, "hardness": 6.0, "tensile_strength": 20, "compressive_strength": 250, "porosity": 0.01, "magical_resonance": 0.3, "value_mult": 3.0 },
		"LIMONITE": { "density": 4.0, "melting_point": 1650, "hardness": 5.0, "tensile_strength": 15, "compressive_strength": 180, "magical_resonance": 0.2, "value_mult": 2.0 },
		"MAGNETITE": { "density": 5.2, "melting_point": 1800, "specific_heat": 600, "conductivity": 12, "hardness": 6.0, "tensile_strength": 18, "compressive_strength": 240, "magical_resonance": 0.5, "value_mult": 3.0 },
		"MALACHITE": { "density": 4.0, "melting_point": 1500, "hardness": 3.5, "tensile_strength": 5, "compressive_strength": 100, "magical_resonance": 0.4, "value_mult": 2.0 },
		"GALENA": { "density": 7.6, "melting_point": 1400, "hardness": 2.5, "tensile_strength": 3, "compressive_strength": 50, "magical_resonance": 0.2, "value_mult": 2.0 },
		"CASSITERITE": { "density": 7.0, "melting_point": 1650, "hardness": 6.5, "tensile_strength": 10, "compressive_strength": 150, "magical_resonance": 0.15, "value_mult": 2.0 },
		"COAL_BITUMINOUS": { "density": 1.3, "melting_point": 0, "specific_heat": 1400, "conductivity": 0.3, "hardness": 2.0, "tensile_strength": 2, "compressive_strength": 20, "porosity": 0.3, "flammability": 0.9, "magical_resonance": 0.0, "value_mult": 0.5 },
		"LIGNITE": { "density": 1.2, "melting_point": 0, "hardness": 1.5, "porosity": 0.4, "flammability": 0.85, "magical_resonance": 0.0, "value_mult": 0.3 },
		"COAL": { "density": 1.3, "melting_point": 0, "hardness": 2.0, "porosity": 0.3, "flammability": 0.9, "magical_resonance": 0.0 },
		"NATIVE_COPPER": { "density": 8.9, "melting_point": 1358, "hardness": 3.0, "tensile_strength": 200, "compressive_strength": 300, "magical_resonance": 0.25, "value_mult": 2.0 },
		"NATIVE_GOLD": { "density": 19.3, "melting_point": 1337, "hardness": 2.5, "tensile_strength": 80, "compressive_strength": 120, "magical_resonance": 0.8, "value_mult": 3.0 },
		"NATIVE_SILVER": { "density": 10.5, "melting_point": 1235, "hardness": 2.5, "tensile_strength": 120, "compressive_strength": 160, "magical_resonance": 0.7, "value_mult": 2.0 },
		"NATIVE_PLATINUM": { "density": 21.4, "melting_point": 2041, "hardness": 4.5, "tensile_strength": 160, "compressive_strength": 220, "magical_resonance": 0.5, "value_mult": 3.0 },
		"SPHALERITE": { "density": 4.0, "melting_point": 1300, "hardness": 3.5, "tensile_strength": 5, "compressive_strength": 80, "magical_resonance": 0.2, "value_mult": 1.5 },
		"GARNIERITE": { "density": 3.5, "melting_point": 1500, "hardness": 4.0, "tensile_strength": 8, "compressive_strength": 120, "magical_resonance": 0.15, "value_mult": 1.5 },
		"CINNABAR": { "density": 8.1, "melting_point": 1200, "hardness": 2.5, "magical_resonance": 0.5, "value_mult": 2.0 },
		"COBALTITE": { "density": 6.3, "melting_point": 1600, "hardness": 5.5, "tensile_strength": 12, "compressive_strength": 160, "magical_resonance": 0.3, "value_mult": 2.0 },
		"TETRAHEDRITE": { "density": 5.0, "melting_point": 1400, "hardness": 4.0, "magical_resonance": 0.25, "value_mult": 2.0 },
		"HORN_SILVER": { "density": 5.5, "melting_point": 1000, "hardness": 2.0, "magical_resonance": 0.7, "value_mult": 3.0 },
		"KIMBERLITE": { "density": 3.3, "melting_point": 1500, "hardness": 6.0, "tensile_strength": 10, "compressive_strength": 180, "magical_resonance": 0.4, "value_mult": 2.0 },
		"BISMUTHINITE": { "density": 6.8, "melting_point": 800, "hardness": 2.0, "magical_resonance": 0.4, "value_mult": 1.5 },
		"PYROLUSITE": { "density": 5.0, "melting_point": 1500, "hardness": 6.0, "tensile_strength": 8, "compressive_strength": 100, "magical_resonance": 0.1 },
		"PITCHBLENDE": { "density": 9.0, "melting_point": 1800, "hardness": 5.0, "magical_resonance": 0.9, "value_mult": 5.0 },
		"BAUXITE": { "density": 2.5, "melting_point": 1600, "hardness": 3.0, "tensile_strength": 5, "compressive_strength": 80, "magical_resonance": 0.1, "value_mult": 1.5 },
		"ILMENITE": { "density": 4.8, "melting_point": 1600, "hardness": 6.0, "magical_resonance": 0.2 },
		"RUTILE": { "density": 4.2, "melting_point": 1840, "hardness": 6.5, "magical_resonance": 0.3 },
		"CHROMITE": { "density": 4.8, "melting_point": 1700, "hardness": 5.5, "magical_resonance": 0.2 },
		"SLADE": { "density": 5.0, "melting_point": 3000, "hardness": 9.0, "compressive_strength": 500, "magical_resonance": 0.8 },
		"CLAY": { "density": 1.6, "melting_point": 0, "specific_heat": 1400, "conductivity": 0.5, "hardness": 0.5, "tensile_strength": 0, "compressive_strength": 1, "porosity": 0.5, "flammability": 0.0, "magical_resonance": 0.1 },
		"FIRE_CLAY": { "density": 1.8, "melting_point": 1800, "specific_heat": 1200, "conductivity": 1.0, "hardness": 0.5, "tensile_strength": 0, "compressive_strength": 2, "porosity": 0.3, "magical_resonance": 0.3 },
		"PEAT": { "density": 0.4, "melting_point": 0, "hardness": 0.3, "porosity": 0.7, "flammability": 0.8, "magical_resonance": 0.1 },
		"SOIL": { "density": 1.2, "melting_point": 0, "specific_heat": 1500, "conductivity": 0.5, "hardness": 0.3, "tensile_strength": 0, "compressive_strength": 0.5, "porosity": 0.6, "flammability": 0.0, "magical_resonance": 0.0 },
		"SAND": { "density": 1.5, "melting_point": 1700, "specific_heat": 800, "conductivity": 0.5, "hardness": 6.0, "tensile_strength": 0, "compressive_strength": 0.5, "porosity": 0.3, "flammability": 0.0, "magical_resonance": 0.0 },
		"WOOD": { "density": 0.6, "melting_point": 0, "specific_heat": 1700, "conductivity": 0.15, "hardness": 1.5, "tensile_strength": 40, "compressive_strength": 10, "impact_fracture": 20, "shear_fracture": 5, "elasticity": 10, "yield_strength": 5, "porosity": 0.4, "flammability": 0.8, "magical_resonance": 0.3 },
		"WATER": { "density": 1.0, "melting_point": 273, "boiling_point": 373, "specific_heat": 4180, "conductivity": 0.6, "hardness": 0.0, "tensile_strength": 0, "compressive_strength": 0, "porosity": 0.0, "flammability": 0.0, "magical_resonance": 0.05, "state": State.LIQUID, "edible": true, "nutrition": 0.0 },
		"MAGMA": { "density": 2.5, "melting_point": 0, "boiling_point": 0, "specific_heat": 1200, "conductivity": 2.0, "hardness": 0.0, "tensile_strength": 0, "compressive_strength": 0, "porosity": 0.0, "flammability": 0.0, "magical_resonance": 0.8, "state": State.LIQUID, "temperature": 1300.0 },
		"BONE": { "density": 1.5, "melting_point": 0, "specific_heat": 1300, "conductivity": 0.3, "hardness": 3.5, "tensile_strength": 80, "compressive_strength": 120, "impact_fracture": 15, "shear_fracture": 10, "elasticity": 15, "yield_strength": 5, "porosity": 0.1, "flammability": 0.6, "magical_resonance": 0.3 },
		"LEATHER": { "density": 0.8, "melting_point": 0, "specific_heat": 1500, "conductivity": 0.2, "hardness": 0.5, "tensile_strength": 20, "compressive_strength": 5, "impact_fracture": 40, "shear_fracture": 15, "elasticity": 2, "yield_strength": 2, "porosity": 0.5, "flammability": 0.7, "magical_resonance": 0.1 },
		"SILK": { "density": 0.3, "melting_point": 0, "specific_heat": 1600, "conductivity": 0.1, "hardness": 0.2, "tensile_strength": 500, "compressive_strength": 1, "impact_fracture": 30, "shear_fracture": 40, "elasticity": 8, "yield_strength": 1, "porosity": 0.6, "flammability": 0.8, "magical_resonance": 0.5 },
		"CLOTH": { "density": 0.2, "melting_point": 0, "specific_heat": 1400, "conductivity": 0.08, "hardness": 0.1, "tensile_strength": 10, "compressive_strength": 1, "impact_fracture": 20, "shear_fracture": 5, "elasticity": 1, "yield_strength": 0.5, "porosity": 0.7, "flammability": 0.9, "magical_resonance": 0.05 },
		"GLASS": { "density": 2.5, "melting_point": 1700, "boiling_point": 2500, "specific_heat": 750, "conductivity": 1.0, "hardness": 5.5, "tensile_strength": 7, "compressive_strength": 50, "impact_fracture": 1, "shear_fracture": 3, "elasticity": 70, "yield_strength": 0.5, "porosity": 0.0, "flammability": 0.0, "magical_resonance": 0.3 },
		"CRYSTAL": { "density": 2.6, "melting_point": 2000, "boiling_point": 3000, "specific_heat": 700, "conductivity": 5.0, "hardness": 7.0, "tensile_strength": 5, "compressive_strength": 100, "impact_fracture": 0.5, "shear_fracture": 2, "elasticity": 100, "yield_strength": 0.5, "porosity": 0.0, "flammability": 0.0, "magical_resonance": 0.8 },
		"IVORY": { "density": 1.8, "melting_point": 0, "specific_heat": 1200, "conductivity": 0.3, "hardness": 3.0, "tensile_strength": 60, "compressive_strength": 100, "impact_fracture": 10, "shear_fracture": 8, "elasticity": 12, "yield_strength": 4, "porosity": 0.05, "flammability": 0.5, "magical_resonance": 0.4 },
		"SHELL": { "density": 2.0, "melting_point": 0, "specific_heat": 900, "conductivity": 1.5, "hardness": 3.5, "tensile_strength": 30, "compressive_strength": 80, "impact_fracture": 5, "shear_fracture": 4, "elasticity": 40, "yield_strength": 2, "porosity": 0.02, "flammability": 0.0, "magical_resonance": 0.2 },
		"CERAMIC": { "density": 2.0, "melting_point": 1800, "boiling_point": 2500, "specific_heat": 850, "conductivity": 1.5, "hardness": 6.0, "tensile_strength": 5, "compressive_strength": 80, "impact_fracture": 0.5, "shear_fracture": 1, "elasticity": 60, "yield_strength": 0.5, "porosity": 0.02, "flammability": 0.0, "magical_resonance": 0.15 },
		"GREEN_GLASS": { "density": 2.4, "melting_point": 1600, "boiling_point": 2400, "specific_heat": 780, "conductivity": 1.0, "hardness": 5.0, "tensile_strength": 8, "compressive_strength": 60, "impact_fracture": 0.8, "shear_fracture": 2.5, "elasticity": 65, "yield_strength": 0.5, "porosity": 0.0, "flammability": 0.0, "magical_resonance": 0.25 },
		"CLEAR_GLASS": { "density": 2.5, "melting_point": 1700, "boiling_point": 2500, "specific_heat": 750, "conductivity": 1.0, "hardness": 5.5, "tensile_strength": 7, "compressive_strength": 50, "impact_fracture": 0.5, "shear_fracture": 2, "elasticity": 70, "yield_strength": 0.5, "porosity": 0.0, "flammability": 0.0, "magical_resonance": 0.35 },
		"CRYSTAL_GLASS": { "density": 2.4, "melting_point": 1650, "boiling_point": 2450, "specific_heat": 760, "conductivity": 1.2, "hardness": 5.5, "tensile_strength": 6, "compressive_strength": 45, "impact_fracture": 0.4, "shear_fracture": 1.5, "elasticity": 68, "yield_strength": 0.5, "porosity": 0.0, "flammability": 0.0, "magical_resonance": 0.6 },
		"MILK": { "density": 1.03, "melting_point": 273, "boiling_point": 373, "specific_heat": 3930, "conductivity": 0.56, "hardness": 0.0, "porosity": 0.0, "flammability": 0.0, "magical_resonance": 0.05, "edible": true, "nutrition": 0.3, "state": State.LIQUID },
		"CHEESE": { "density": 1.0, "melting_point": 0, "specific_heat": 2500, "conductivity": 0.3, "hardness": 0.5, "porosity": 0.3, "flammability": 0.3, "magical_resonance": 0.0, "edible": true, "nutrition": 0.6, "state": State.SOLID },
		"EGG": { "density": 1.0, "melting_point": 0, "specific_heat": 3200, "conductivity": 0.4, "hardness": 0.5, "porosity": 0.0, "flammability": 0.0, "magical_resonance": 0.0, "edible": true, "nutrition": 0.5, "state": State.SOLID },
		"HONEY": { "density": 1.4, "melting_point": 280, "boiling_point": 380, "specific_heat": 2500, "conductivity": 0.5, "hardness": 0.0, "porosity": 0.0, "flammability": 0.0, "magical_resonance": 0.1, "edible": true, "nutrition": 0.7, "state": State.LIQUID },
	}

static func compute(material: Dictionary) -> Dictionary:
	var result = get_schema().duplicate()
	var mat_type = material.get("type", "stone")
	var mat_id = material.get("id", "")
	var mat_value = material.get("value", 1)
	var defaults = type_defaults().get(mat_type, type_defaults()["stone"])

	for key in defaults:
		result[key] = defaults[key]

	result["nutrition"] = 0.0
	result["edible"] = false

	if mat_type == "food":
		result["edible"] = true
		result["nutrition"] = 0.5
	elif mat_type == "drink":
		result["edible"] = true
		result["nutrition"] = 0.3
		result["state"] = State.LIQUID

	var overrides = get_overrides().get(mat_id, {})
	for key in overrides:
		if result.has(key):
			result[key] = overrides[key]

	_result_magical_resonance(result, mat_id, mat_type, mat_value)
	_result_porosity(result, mat_type)
	_result_flammability(result, mat_type)
	_result_hardness_from_value(result, mat_value)

	return result

static func _result_magical_resonance(r: Dictionary, id: String, type: String, value: int) -> void:
	var magical_names = ["ADAMANTINE", "RAW_ADAMANTINE", "PITCHBLENDE", "OBSIDIAN",
		"GOLD", "SILVER", "ELECTRUM", "ROSE_GOLD", "STERLING_SILVER",
		"MOONSTONE", "STAR_SAPPHIRE", "DIAMOND"]
	if id in magical_names:
		return
	if type == "gem":
		r["magical_resonance"] = maxf(r["magical_resonance"], 0.3 + float(value) / 200.0)

static func _result_porosity(r: Dictionary, type: String) -> void:
	if type == "stone" or type == "gem":
		r["porosity"] = clampf(r["porosity"], 0.0, 0.15)

static func _result_flammability(r: Dictionary, type: String) -> void:
	if type == "metal" or type == "stone" or type == "gem":
		r["flammability"] = 0.0

static func _result_hardness_from_value(r: Dictionary, value: int) -> void:
	if value > 0 and r["hardness"] <= 0.0:
		r["hardness"] = clampf(0.5 + log(float(value)) * 0.5, 0.5, 8.0)

static func get_weight(volume_cm3: float, material: Dictionary) -> float:
	var props = compute(material)
	return volume_cm3 * props["density"] / 1000.0

static func get_buoyancy(material_density: float, fluid_density: float = 1.0) -> float:
	if material_density <= 0: return 1.0
	return 1.0 - (fluid_density / material_density)

static func get_strength_factor(props: Dictionary) -> float:
	var h = props.get("hardness", 1.0) / 10.0
	var ts = props.get("tensile_strength", 0.0) / 500.0
	var cs = props.get("compressive_strength", 0.0) / 500.0
	var result = h * 0.3 + ts * 0.4 + cs * 0.3
	return clampf(result, 0.05, 3.0)

static func get_value_factor(props: Dictionary, base_value: int) -> float:
	var h = props.get("hardness", 1.0) / 5.0
	var mr = props.get("magical_resonance", 0.0) * 2.0
	return clampf(h + mr + float(base_value) / 20.0, 0.1, 5.0)

static func enum_to_id(imat_enum: int) -> String:
	match imat_enum:
		0: return "STONE"
		1: return "GRANITE"
		2: return "LIMESTONE"
		3: return "SANDSTONE"
		4: return "DIORITE"
		5: return "OBSIDIAN"
		6: return "MARBLE"
		7: return "GABBRO"
		8: return "SOIL"
		9: return "CLAY"
		10: return "SAND"
		11: return "COAL"
		12: return "IRON"
		13: return "GOLD"
		14: return "SILVER"
		15: return "COPPER"
		16: return "TIN"
		17: return "PLATINUM"
		18: return "WOOD"
		19: return "WATER"
		20: return "MAGMA"
		21: return "CONSTRUCTION"
	return "STONE"

static func compute_for_enum(imat_enum: int) -> Dictionary:
	var id = enum_to_id(imat_enum)
	return _compute_from_id_or_fallback(id)

static func compute_by_id(id: String) -> Dictionary:
	if id.is_empty():
		return compute({"id": "STONE", "type": "stone", "value": 1})
	return _compute_from_id_or_fallback(id)

static func _compute_from_id_or_fallback(id: String) -> Dictionary:
	var inferred_type = "stone"
	var inferred_value = 1
	match id:
		"IRON", "STEEL", "PIG_IRON", "COPPER", "BRONZE", "BRASS", "GOLD", "SILVER", "PLATINUM", "TIN", "LEAD", "NICKEL", "ZINC", "ADAMANTINE", "BISMUTH", "BISMUTH_BRONZE", "BLACK_BRONZE", "ELECTRUM", "BILLON", "PEWTER_FINE", "PEWTER_TRIFLE", "PEWTER_LAY", "NICKEL_SILVER", "ALUMINUM", "NATIVE_ALUMINUM", "STERLING_SILVER", "ROSE_GOLD":
			inferred_type = "metal"
			inferred_value = 5
		"GOLD", "PLATINUM", "ADAMANTINE":
			inferred_value = 30
		"GRANITE", "DIORITE", "GABBRO", "OBSIDIAN", "MARBLE", "LIMESTONE", "SANDSTONE", "BASALT", "RHYOLITE", "ANDESITE", "DACITE", "QUARTZITE", "SLATE", "GNEISS", "SCHIST", "PHYLLITE", "CHERT", "CHALK", "DOLOMITE", "CONGLOMERATE", "SHALE", "MUDSTONE", "SILTSTONE", "CLAYSTONE", "ROCK_SALT", "GYPSUM", "TALC", "JET", "PUDDINGSTONE", "PETRIFIED_WOOD", "GRAPHITE", "BRIMSTONE", "SLADE":
			inferred_type = "stone"
			inferred_value = 1
		"HEMATITE", "LIMONITE", "MAGNETITE", "MALACHITE", "GALENA", "SPHALERITE", "GARNIERITE", "CASSITERITE", "COBALTITE", "TETRAHEDRITE", "HORN_SILVER", "BISMUTHINITE", "ILMENITE", "RUTILE", "CHROMITE", "PYROLUSITE", "PITCHBLENDE", "BAUXITE", "CINNABAR", "KIMBERLITE":
			inferred_type = "stone"
			inferred_value = 2
		"COAL_BITUMINOUS", "LIGNITE":
			inferred_type = "stone"
			inferred_value = 1
		"CLAY", "FIRE_CLAY":
			inferred_type = "soil"
			inferred_value = 1
		"PEAT":
			inferred_type = "soil"
			inferred_value = 1
		"SOIL", "SAND":
			inferred_type = "soil"
			inferred_value = 0
		"WOOD":
			inferred_type = "wood"
			inferred_value = 1
		"WATER", "MILK":
			inferred_type = "drink"
			inferred_value = 0
		"MAGMA":
			inferred_type = "stone"
			inferred_value = 0
		"BONE", "IVORY", "SHELL":
			inferred_type = "stone"
			inferred_value = 3
		"LEATHER", "SILK", "CLOTH":
			inferred_type = "wood"
			inferred_value = 2
		"GLASS", "CRYSTAL", "GREEN_GLASS", "CLEAR_GLASS", "CRYSTAL_GLASS", "CERAMIC":
			inferred_type = "stone"
			inferred_value = 5
		"CHEESE", "EGG", "HONEY":
			inferred_type = "food"
			inferred_value = 2
	var fallback = get_overrides().get(id, {})
	if not fallback.is_empty():
		var result = get_schema().duplicate()
		for key in result:
			result[key] = fallback.get(key, result[key])
		if not fallback.has("density"):
			result["density"] = type_defaults().get(inferred_type, type_defaults()["stone"]).get("density", 2.5)
		return result
	return compute({"id": id, "type": inferred_type, "value": inferred_value})
