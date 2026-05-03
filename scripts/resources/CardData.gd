class_name CardData
extends Resource

enum Rarity {
	COMMON,
	UNCOMMON,
	RARE,
	EPIC,
	LEGENDARY,
	MYTHICAL,
}

enum Aspect {
	CHAOS,
	SIGMA,
	GALAXY_BRAIN,
	CURSED,
	VOID,
}

@export var id: StringName
@export var display_name: String
@export var rarity: Rarity = Rarity.COMMON
@export var aspect: Aspect = Aspect.CHAOS
@export_range(1, 50) var level: int = 1
@export var base_hp: int
@export var base_attack: int
@export var base_defense: int
@export var base_speed: int
@export_range(0.0, 1.0) var crit_chance: float = 0.05
@export_range(1.0, 4.0) var crit_multiplier: float = 1.5
@export var passive: PassiveEffect
@export var ultimate: UltimateAbility
@export var portrait: Texture2D
@export var animation_set: SpriteFrames
