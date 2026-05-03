class_name RoomTemplate
extends Resource

enum Aspect {
	CHAOS,
	SIGMA,
	GALAXY_BRAIN,
	CURSED,
	VOID,
}

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export_range(1, 6) var unlock_tier: int = 3
@export_range(4, 8) var slot_count: int = 4
@export_range(1, 8) var grid_width: int = 2
@export_range(1, 8) var grid_height: int = 2

@export var default_aspect: Aspect = Aspect.CHAOS
@export var supports_theme_assignment: bool = true
@export var theme_change_cost_essence: int = 1000
@export var synchronized_income_multiplier: float = 2.0

@export var slot_positions: Array[Vector2i] = []
@export var preview_texture: Texture2D
