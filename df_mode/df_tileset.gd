extends RefCounted
class_name DFTileset

const TILESET_PATH = "res://assets/df_tileset.png"

const TILE_SIZE = 16
const GRID_COLS = 16
const GRID_ROWS = 16

var texture: Texture2D = null
var _char_map: Dictionary = {}

func _init():
	texture = load(TILESET_PATH) as Texture2D
	_build_char_map()

# Builds a mapping from game Unicode characters to tileset grid positions.
# Standard ASCII maps directly. Special Unicode chars are mapped to CP437 positions.
func _build_char_map() -> void:
	for c in range(32, 127):
		_char_map[char(c)] = c

	_char_map["\u2588"] = 0xDB  # FULL BLOCK -> CP437 █
	_char_map["\u2591"] = 0xB0  # LIGHT SHADE -> CP437 ░
	_char_map["\u2592"] = 0xB1  # MEDIUM SHADE -> CP437 ▒
	_char_map["\u2593"] = 0xB2  # DARK SHADE -> CP437 ▓
	_char_map["\u25A3"] = 0x04  # Z NOTATION SPOT -> CP437 ♦
	_char_map["\u25A1"] = 0xFE  # WHITE SQUARE -> CP437 ■
	_char_map["\u2022"] = 0x07  # BULLET -> CP437 •
	_char_map["\u2219"] = 0xF9  # BULLET OPERATOR -> CP437 ∙
	_char_map["\u2581"] = 0xDF  # LOWER 1/8 BLOCK -> CP437 ▀
	_char_map["\u25B2"] = 0x1E  # BLACK UP-POINTING TRIANGLE -> CP437 ▲
	_char_map["\u25BC"] = 0x1F  # BLACK DOWN-POINTING TRIANGLE -> CP437 ▼
	_char_map["\u25C0"] = 0x11  # BLACK LEFT-POINTING TRIANGLE -> CP437 ◄
	_char_map["\u25B6"] = 0x10  # BLACK RIGHT-POINTING TRIANGLE -> CP437 ►
	_char_map["\u25CB"] = 0x09  # WHITE CIRCLE -> CP437 ○
	_char_map["\u25CF"] = 0x0C  # BLACK CIRCLE -> CP437 ♀
	_char_map["\u2660"] = 0x06  # BLACK SPADE SUIT -> CP437 ♠
	_char_map["\u2663"] = 0x05  # BLACK CLUB SUIT -> CP437 ♣
	_char_map["\u2665"] = 0x03  # BLACK HEART SUIT -> CP437 ♥
	_char_map["\u2666"] = 0x04  # BLACK DIAMOND SUIT -> CP437 ♦
	_char_map["\u263A"] = 0x01  # WHITE SMILING FACE -> CP437 ☺
	_char_map["\u263B"] = 0x02  # BLACK SMILING FACE -> CP437 ☻
	_char_map["\u2190"] = 0x1B  # LEFTWARDS ARROW -> CP437 ←
	_char_map["\u2191"] = 0x18  # UPWARDS ARROW -> CP437 ↑
	_char_map["\u2192"] = 0x1A  # RIGHTWARDS ARROW -> CP437 →
	_char_map["\u2193"] = 0x19  # DOWNWARDS ARROW -> CP437 ↓
	_char_map["\u21E8"] = 0x1A  # RIGHTWARDS WHITE ARROW -> CP437 →
	_char_map["\u2502"] = 0xB3  # BOX DRAWINGS VERTICAL -> CP437 │
	_char_map["\u2500"] = 0xC4  # BOX DRAWINGS HORIZONTAL -> CP437 ─
	_char_map["\u2550"] = 0xCD  # BOX DRAWINGS DOUBLE HORIZONTAL -> CP437 ═
	_char_map["\u2551"] = 0xBA  # BOX DRAWINGS DOUBLE VERTICAL -> CP437 ║
	_char_map["\u256C"] = 0xCE  # BOX DRAWINGS DOUBLE CROSS -> CP437 ╬
	_char_map["\u2714"] = 0x04  # CHECK MARK -> CP437 ♦
	_char_map["\u2716"] = 0x0D  # HEAVY MULTIPLICATION X -> CP437 ♪
	_char_map["\u266A"] = 0x0D  # EIGHTH NOTE -> CP437 ♪
	_char_map["\u266B"] = 0x0E  # BEAMED EIGHTH NOTES -> CP437 ♫
	_char_map["\u00B0"] = 0xF8  # DEGREE SIGN -> CP437 °
	_char_map["\u00B1"] = 0xF1  # PLUS-MINUS SIGN -> CP437 ±
	_char_map["\u00A9"] = 0x42  # COPYRIGHT SIGN -> CP437 B (fallback)
	_char_map["\u00AE"] = 0xAE  # REGISTERED SIGN -> CP437 «
	_char_map["\u00AB"] = 0xAE  # LEFT-POINTING DOUBLE ANGLE -> CP437 «
	_char_map["\u00BB"] = 0xAF  # RIGHT-POINTING DOUBLE ANGLE -> CP437 »
	_char_map["\u00A3"] = 0x9C  # POUND SIGN -> CP437 £
	_char_map["\u0022"] = 0x22  # QUOTATION MARK (")
	_char_map["\u0060"] = 0x60  # GRAVE ACCENT (`)
	_char_map["\u00B7"] = 0xF9  # MIDDLE DOT -> CP437 ∙

func get_tile_code(char_str: String) -> int:
	return _char_map.get(char_str, 0x20)  # Default to space


func get_tile_region(char_str: String) -> Rect2:
	var code = get_tile_code(char_str)
	var col = code % GRID_COLS
	var row = code / GRID_COLS
	return Rect2(col * TILE_SIZE, row * TILE_SIZE, TILE_SIZE, TILE_SIZE)


func has_char(char_str: String) -> bool:
	return _char_map.has(char_str)
