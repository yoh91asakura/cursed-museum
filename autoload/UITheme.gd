extends Node
class_name UIThemeManager

const THEME_PATH := "res://data/ui/CursedMuseumTheme.tres"

const BASE_VIEWPORT := Vector2i(1920, 1080)
const MIN_VIEWPORT := Vector2i(1280, 720)
const STEAM_DECK_VIEWPORT := Vector2i(1280, 800)

const PALETTE := {
	&"ink": Color(0.055, 0.062, 0.082, 1.0),
	&"panel": Color(0.105, 0.117, 0.145, 1.0),
	&"panel_raised": Color(0.155, 0.172, 0.205, 1.0),
	&"bone": Color(0.925, 0.898, 0.805, 1.0),
	&"muted": Color(0.675, 0.672, 0.615, 1.0),
	&"gold": Color(0.945, 0.690, 0.240, 1.0),
	&"curse": Color(0.620, 0.330, 0.855, 1.0),
	&"void": Color(0.145, 0.655, 0.715, 1.0),
	&"danger": Color(0.835, 0.220, 0.250, 1.0),
	&"success": Color(0.360, 0.745, 0.390, 1.0),
	&"focus": Color(1.000, 0.835, 0.360, 1.0),
}

const FONT_SIZES := {
	&"caption": 18,
	&"body": 24,
	&"button": 26,
	&"heading": 34,
	&"title": 48,
}

const CONTROL_SIZES := {
	&"focus_width": 3,
	&"button_min_height": 56,
	&"touch_target": 56,
	&"panel_corner_radius": 8,
	&"button_corner_radius": 6,
	&"content_margin": 16,
}

var current_theme: Theme


func _ready() -> void:
	apply_theme()


func apply_theme() -> void:
	current_theme = load(THEME_PATH) as Theme
	if current_theme == null:
		push_error("Unable to load global UI theme at %s" % THEME_PATH)
		return

	get_tree().root.theme = current_theme


func get_color(token: StringName) -> Color:
	return PALETTE.get(token, Color.MAGENTA)


func get_font_size(token: StringName) -> int:
	return int(FONT_SIZES.get(token, FONT_SIZES[&"body"]))


func get_control_size(token: StringName) -> int:
	return int(CONTROL_SIZES.get(token, 0))
