class_name EnemyData
extends Resource

enum Aspect {
	CHAOS,
	SIGMA,
	GALAXY_BRAIN,
	CURSED,
	VOID,
}

enum EnemyRank {
	NORMAL,
	ELITE,
	BOSS,
}

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var rank: EnemyRank = EnemyRank.NORMAL
@export var aspect: Aspect = Aspect.CHAOS

@export_range(1, 50) var level: int = 1
@export var base_hp: int
@export var base_attack: int
@export var base_defense: int
@export var base_speed: int
@export_range(0.0, 1.0) var crit_chance: float = 0.05
@export_range(1.0, 4.0) var crit_multiplier: float = 1.5

@export_range(1, 4) var team_size: int = 1
@export var behavior_tree_id: StringName
@export var ability_ids: Array[StringName] = []
@export var drop_table_id: StringName

@export var portrait: Texture2D
@export var animation_set: SpriteFrames
