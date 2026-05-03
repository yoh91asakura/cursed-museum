class_name ZoneData
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
@export_range(1, 3) var zone_number: int = 1
@export var dominant_aspect: Aspect = Aspect.CHAOS

@export_range(12, 16) var min_depth: int = 12
@export_range(12, 16) var max_depth: int = 16
@export_range(5, 7) var min_width: int = 5
@export_range(5, 7) var max_width: int = 7

@export_range(0.0, 1.0) var combat_weight: float = 0.50
@export_range(0.0, 1.0) var elite_weight: float = 0.12
@export_range(0.0, 1.0) var event_weight: float = 0.15
@export_range(0.0, 1.0) var shop_weight: float = 0.10
@export_range(0.0, 1.0) var rest_weight: float = 0.10
@export_range(0.0, 1.0) var treasure_weight: float = 0.03

@export_range(0, 4) var min_shops: int = 1
@export_range(0, 4) var min_rests: int = 1
@export_range(0, 4) var min_elites: int = 1

@export var normal_enemy_pool: Array[EnemyData] = []
@export var elite_enemy_pool: Array[EnemyData] = []
@export var boss: EnemyData
@export var event_pool: Array[Resource] = []
@export var background: Texture2D
@export var music: AudioStream
