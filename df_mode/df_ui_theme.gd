extends RefCounted
class_name DFUITheme

# Base grid and spacing. Every interface measurement should derive from GRID.
const GRID := 4.0
const SPACE_XS := GRID
const SPACE_SM := GRID * 2.0
const SPACE_MD := GRID * 3.0
const SPACE_LG := GRID * 4.0
const SPACE_XL := GRID * 6.0

const TITLE_HEIGHT := 24.0
const STATUS_HEIGHT := 20.0
const ROW_HEIGHT := 24.0
const BUTTON_HEIGHT := 32.0
const PANEL_RADIUS := 0.0

# Windows 2000/XP Classic chrome.
const WIN_FACE := Color("#D4D0C8")
const WIN_FACE_WARM := Color("#ECE9D8")
const WIN_WINDOW := Color("#FFFFFF")
const WIN_LIGHT := Color("#FFFFFF")
const WIN_HIGHLIGHT := Color("#DFDFDF")
const WIN_SHADOW := Color("#808080")
const WIN_DARK_SHADOW := Color("#404040")
const WIN_TITLE_START := Color("#0A246A")
const WIN_TITLE_END := Color("#3A6EA5")
const WIN_INACTIVE := Color("#7A96B8")
const SELECTION := Color("#0A246A")

# Simulation surfaces and semantic colors.
const SURFACE_0 := Color("#111923")
const SURFACE_1 := Color("#192534")
const SURFACE_2 := Color("#243548")
const BORDER := Color("#51677D")
const BORDER_SOFT := Color("#34495D")
const TEXT := Color("#E9EFF5")
const TEXT_MUTED := Color("#9EADBC")
const TEXT_DISABLED := Color("#697887")
const ACCENT := Color("#5AA9E6")
const GOLD := Color("#E5BC58")
const SUCCESS := Color("#64C982")
const WARNING := Color("#E4A94F")
const DANGER := Color("#D85C5C")
const ARCANE := Color("#B27ACB")

# Cinematic menu palette. It shares the Windows blue and gold, avoiding purple.
const MENU_SKY_TOP := Color("#07111E")
const MENU_SKY_BOTTOM := Color("#15283A")
const MENU_MIST := Color("#6C879A")
const MENU_PANEL := Color("#101A24")

const FONT_XS := 8
const FONT_SM := 10
const FONT_MD := 12
const FONT_LG := 16
const FONT_XL := 24

static func snap(value: float) -> float:
	return roundf(value / GRID) * GRID

static func snapped_rect(rect: Rect2) -> Rect2:
	return Rect2(
		snap(rect.position.x),
		snap(rect.position.y),
		maxf(GRID, snap(rect.size.x)),
		maxf(GRID, snap(rect.size.y))
	)

static func responsive_scale(viewport: Vector2) -> float:
	var width_scale := viewport.x / 1920.0
	var height_scale := viewport.y / 1080.0
	return clampf(minf(width_scale, height_scale), 0.75, 1.35)

static func content_width(viewport: Vector2, preferred: float, margin: float = 32.0) -> float:
	return snap(minf(preferred, maxf(320.0, viewport.x - margin * 2.0)))
