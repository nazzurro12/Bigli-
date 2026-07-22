extends RefCounted
class_name DFNamegen

const DwarfLang = preload("res://df_mode/languages/df_lang_dwarf.gd")
const ElfLang = preload("res://df_mode/languages/df_lang_elf.gd")
const GoblinLang = preload("res://df_mode/languages/df_lang_goblin.gd")
const HumanLang = preload("res://df_mode/languages/df_lang_human.gd")

var rng: RandomNumberGenerator

# Word lists by semantic category (populated from DF language data)
var dwarf_words: Dictionary = {}
var elf_words: Dictionary = {}
var goblin_words: Dictionary = {}
var human_words: Dictionary = {}

# Cached word lists
var _dwarf_translations: Dictionary = {}
var _all_dwarf_words: Array = []
var _all_elf_words: Array = []
var _all_goblin_words: Array = []
var _all_human_words: Array = []

# Words good for prefix/suffix of names
var _prefix_pool: Array = []
var _suffix_pool: Array = []


func _init(seed_value: int = -1):
	rng = RandomNumberGenerator.new()
	rng.seed = seed_value if seed_value >= 0 else randi()
	_load_words()


func _load_words() -> void:
	dwarf_words = DwarfLang.get_dwarf_words()
	elf_words = ElfLang.get_elf_words()
	goblin_words = GoblinLang.get_goblin_words()
	human_words = HumanLang.get_human_words()

	for eng in dwarf_words:
		var dw = dwarf_words[eng]
		_dwarf_translations[eng] = dw
		_all_dwarf_words.append(dw)

	for eng_46 in elf_words:
		_all_elf_words.append(elf_words[eng_46])

	for eng_49 in goblin_words:
		_all_goblin_words.append(goblin_words[eng_49])

	for eng_52 in human_words:
		_all_human_words.append(human_words[eng_52])

	_build_prefix_suffix_pools()


func _build_prefix_suffix_pools() -> void:
	var seen_prefixes = {}
	var seen_suffixes = {}

	for w in _all_dwarf_words:
		var lower = w.to_lower()
		if lower.length() >= 3:
			var prefix = lower.substr(0, 3).capitalize()
			var suffix = lower.substr(lower.length() - 3, 3)

			if not seen_prefixes.has(prefix) and prefix.length() == 3:
				_prefix_pool.append(prefix)
				seen_prefixes[prefix] = true

			if not seen_suffixes.has(suffix) and suffix.length() == 3:
				_suffix_pool.append(suffix)
				seen_suffixes[suffix] = true


func get_random_word(lang: String) -> String:
	match lang.to_lower():
		"dwarf":
			return _all_dwarf_words[rng.randi() % _all_dwarf_words.size()]
		"elf":
			return _all_elf_words[rng.randi() % _all_elf_words.size()]
		"goblin":
			return _all_goblin_words[rng.randi() % _all_goblin_words.size()]
		"human":
			return _all_human_words[rng.randi() % _all_human_words.size()]
	return _all_dwarf_words[rng.randi() % _all_dwarf_words.size()]


func translate_word(english: String, lang: String = "DWARF") -> String:
	match lang.to_lower():
		"dwarf":
			return dwarf_words.get(english.to_upper(), "")
		"elf":
			return elf_words.get(english.to_upper(), "")
		"goblin":
			return goblin_words.get(english.to_upper(), "")
		"human":
			return human_words.get(english.to_upper(), "")
	return ""


func generate_world_name() -> String:
	var attempts = 0
	while attempts < 20:
		var prefix = get_random_word("dwarf")
		var suffix = get_random_word("dwarf")

		prefix = prefix.capitalize()
		suffix = suffix.to_lower()

		if prefix.length() >= 2 and suffix.length() >= 2:
			var name = prefix + suffix
			if name.length() >= 4 and name.length() <= 16:
				return name
		attempts += 1

	var p = _prefix_pool[rng.randi() % _prefix_pool.size()]
	var s = _suffix_pool[rng.randi() % _suffix_pool.size()]
	return p + s


func generate_dwarf_name() -> String:
	var w1 = ""
	var w2 = ""
	var use_format = rng.randi() % 4
	match use_format:
		0:
			w1 = get_random_word("dwarf")
			return w1.substr(0, 3).capitalize() + w1.substr(1, 3).to_lower()
		1:
			return get_random_word("dwarf").capitalize()
		2:
			w1 = get_random_word("dwarf")
			w2 = get_random_word("dwarf")
			return w1.substr(0, ceil(float(w1.length()) / 2.0)).capitalize() + \
				w2.substr(0, floor(float(w2.length()) / 2.0)).to_lower()
		3:
			return _prefix_pool[rng.randi() % _prefix_pool.size()] + \
				_suffix_pool[rng.randi() % _suffix_pool.size()]
	return get_random_word("dwarf").capitalize()


func generate_site_name(lang: String = "dwarf") -> String:
	var w1 = get_random_word(lang)
	var w2 = get_random_word(lang)
	var w3 = get_random_word(lang)

	var formats = [
		func(): return w1.capitalize() + w2.to_lower(),
		func(): return w1.capitalize() + w2.to_lower() + w3.to_lower(),
		func(): return w1.capitalize() + w2.substr(0, 2),
		func(): return w1.substr(0, ceil(float(w1.length()) / 2.0)).capitalize() + w2.to_lower(),
	]
	return formats[rng.randi() % formats.size()].call()


func generate_artifact_name(english_concept: String = "") -> String:
	var prefix = ""
	var suffix = ""

	if english_concept != "":
		var translation = translate_word(english_concept, "dwarf")
		if translation != "":
			prefix = translation.capitalize()

	if prefix == "":
		prefix = get_random_word("dwarf").capitalize()

	suffix = get_random_word("goblin").to_lower()

	var i = rng.randi() % 4
	match i:
		0:
			return "%s %s" % [prefix, suffix]
		1:
			return "%s de %s" % [prefix, get_random_word("elf").to_lower()]
		2:
			return "El %s de %s" % [prefix, suffix]
		3:
			return prefix + suffix
	return prefix + suffix


func get_meaning(english_word: String) -> String:
	var dw = dwarf_words.get(english_word.to_upper(), "")
	if dw != "":
		return dw
	var el = elf_words.get(english_word.to_upper(), "")
	if el != "":
		return el
	var go = goblin_words.get(english_word.to_upper(), "")
	if go != "":
		return go
	var hu = human_words.get(english_word.to_upper(), "")
	if hu != "":
		return hu
	return ""


func get_word_count(lang: String) -> int:
	match lang.to_lower():
		"dwarf": return _all_dwarf_words.size()
		"elf": return _all_elf_words.size()
		"goblin": return _all_goblin_words.size()
		"human": return _all_human_words.size()
	return 0


func get_all_languages() -> Dictionary:
	return {
		"DWARF": _all_dwarf_words.size(),
		"ELF": _all_elf_words.size(),
		"GOBLIN": _all_goblin_words.size(),
		"HUMAN": _all_human_words.size(),
	}
