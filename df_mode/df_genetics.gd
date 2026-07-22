extends RefCounted
class_name DFGenetics

class Genome extends RefCounted:
	var size_multiplier: float = 1.0
	var metabolic_rate: float = 1.0
	var alcohol_tolerance: float = 1.0
	var pathogen_resistance: float = 1.0

	func _init(p_size: float = 1.0, p_met: float = 1.0, p_alc: float = 1.0, p_path: float = 1.0):
		size_multiplier = p_size
		metabolic_rate = p_met
		alcohol_tolerance = p_alc
		pathogen_resistance = p_path

	func mutate(rate: float = 0.1, volatility: float = 0.1) -> Genome:
		var size = size_multiplier
		var met = metabolic_rate
		var alc = alcohol_tolerance
		var path_res = pathogen_resistance

		if randf() < rate:
			size = clampf(size * randf_range(1.0 - volatility, 1.0 + volatility), 0.1, 10.0)
		if randf() < rate:
			met = clampf(met * randf_range(1.0 - volatility, 1.0 + volatility), 0.1, 5.0)
		if randf() < rate:
			alc = clampf(alc * randf_range(1.0 - volatility, 1.0 + volatility), 0.1, 5.0)
		if randf() < rate:
			path_res = clampf(path_res * randf_range(1.0 - volatility, 1.0 + volatility), 0.1, 5.0)

		return Genome.new(size, met, alc, path_res)

	static func crossbreed(parent_a: Genome, parent_b: Genome) -> Genome:
		# Mendelian-style crossbreeding
		var size_35 = parent_a.size_multiplier if randf() < 0.5 else parent_b.size_multiplier
		var met_36 = parent_a.metabolic_rate if randf() < 0.5 else parent_b.metabolic_rate
		var alc_37 = parent_a.alcohol_tolerance if randf() < 0.5 else parent_b.alcohol_tolerance
		var path_res_38 = parent_a.pathogen_resistance if randf() < 0.5 else parent_b.pathogen_resistance

		var child = Genome.new(size_35, met_36, alc_37, path_res_38)
		# 10% chance to mutate with 15% volatility
		return child.mutate(0.1, 0.15)
