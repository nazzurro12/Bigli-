extends Node
class_name DFAudio

const AMBIENT_PATH = "res://assets/df_sounds/ambient/"
const SFX_PATH = "res://assets/df_sounds/sfx/"
const MUSIC_PATH = "res://assets/df_sounds/music/"

var _music_player: AudioStreamPlayer = null
var _ambient_player: AudioStreamPlayer = null
var _sfx_players: Array = []

var _current_music: String = ""
var _current_ambient: String = ""
var _music_volume: float = -10.0
var _ambient_volume: float = -5.0
var _sfx_volume: float = 0.0

var _music_enabled: bool = true
var _ambient_enabled: bool = true
var _sfx_enabled: bool = true

# Ambient tracks by biome
var _ambient_map: Dictionary = {
	"grassland": "grasslands",
	"savanna": "grasslands",
	"temperate_forest": "forest",
	"dense_temperate_forest": "forest",
	"pine_forest": "forest",
	"taiga": "forest",
	"swamp": "swamp",
	"desert": "desert",
	"badlands": "desert",
	"tundra": "glacier",
	"alpine_meadow": "glacier",
	"ocean_shallow": "outside",
	"ocean_deep": "outside",
	"caves": "cavern",
	"magma": "magma_far",
	"river": "river_medium",
}

# Music albums
var _music_albums: Dictionary = {
	"game_start": "first_year",
	"calm": "mountainhome",
	"exploration": "expansive_cavern",
	"mining": "strike_the_earth",
	"crafting": "craftsdwarfship",
	"tavern": "drink_and_industry",
	"danger": "vile_force_of_darkness",
	"boss": "forgotten_beast",
	"winter": "winter_entombs_you",
	"death": "death_spiral",
	"victory": "hill_dwarf",
	"new_year": "another_year",
	"cards": "cards",
	"dark_temple": "koganusan",
	"strange_mood": "strange_moods",
	"main_theme": "dwarf_fortress",
}


func _ready() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	_music_player.volume_db = _music_volume
	add_child(_music_player)

	_ambient_player = AudioStreamPlayer.new()
	_ambient_player.name = "AmbientPlayer"
	_ambient_player.volume_db = _ambient_volume
	add_child(_ambient_player)

	for i in range(4):
		var p = AudioStreamPlayer.new()
		p.name = "SFXPlayer%d" % i
		p.volume_db = _sfx_volume
		add_child(p)
		_sfx_players.append(p)


func _get_audio_files(path: String) -> Array:
	var dir = DirAccess.open(path)
	if dir == null:
		return []
	var files = []
	dir.list_dir_begin()
	var f = dir.get_next()
	while f != "":
		if f.ends_with(".ogg") or f.ends_with(".wav") or f.ends_with(".mp3"):
			files.append(f)
		f = dir.get_next()
	dir.list_dir_end()
	return files


func play_music(album: String) -> void:
	if not _music_enabled:
		return

	var album_name = _music_albums.get(album, album)
	var album_path = MUSIC_PATH + album_name + "/"

	if album_name == _current_music:
		return

	var files = _get_audio_files(album_path)
	if files.is_empty():
		return

	var track = files[randi() % files.size()]
	var stream = load(album_path + track)
	if stream == null:
		return

	_music_player.stop()
	_music_player.stream = stream
	_music_player.play()
	_current_music = album_name


func play_ambient(biome: String) -> void:
	if not _ambient_enabled:
		return

	var amb = _ambient_map.get(biome, "outside")
	if amb == _current_ambient:
		return

	var path = AMBIENT_PATH + amb + ".ogg"
	var stream = load(path)
	if stream == null:
		return

	_ambient_player.stop()
	_ambient_player.stream = stream
	_ambient_player.play()
	_current_ambient = amb


func play_sfx(name: String) -> void:
	if not _sfx_enabled:
		return

	var path = SFX_PATH + name + ".ogg"
	var stream = load(path)
	if stream == null:
		return

	for p in _sfx_players:
		if not p.playing:
			p.stream = stream
			p.play()
			return

	var p_156 = _sfx_players[0]
	p_156.stream = stream
	p_156.play()


func stop_music() -> void:
	_music_player.stop()
	_current_music = ""


func stop_ambient() -> void:
	_ambient_player.stop()
	_current_ambient = ""


func stop_all() -> void:
	stop_music()
	stop_ambient()
	for p in _sfx_players:
		p.stop()


func set_music_volume(db: float) -> void:
	_music_volume = db
	_music_player.volume_db = db


func set_ambient_volume(db: float) -> void:
	_ambient_volume = db
	_ambient_player.volume_db = db


func set_sfx_volume(db: float) -> void:
	_sfx_volume = db
	for p in _sfx_players:
		p.volume_db = db


func toggle_music() -> void:
	_music_enabled = not _music_enabled
	if not _music_enabled:
		stop_music()


func toggle_ambient() -> void:
	_ambient_enabled = not _ambient_enabled
	if not _ambient_enabled:
		stop_ambient()


func toggle_sfx() -> void:
	_sfx_enabled = not _sfx_enabled
