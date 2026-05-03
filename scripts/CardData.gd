class_name CardData
extends Resource

@export var id: StringName            # "ancient_copypasta"
@export var display_name: String      # "Ancient Copypasta"
@export var rarity: Rarity.Value      # enum
@export var aspect: Aspect.Value       # enum (Chaos/Cursed/GalaxyBrain/Sigma/Void)
@export_range(1, 50) var level: int = 1
@export var base_hp: int
@export var base_attack: int
@export var base_defense: int
@export var base_speed: int
@export_range(0.0, 1.0) var crit_chance: float = 0.05
@export_range(1.0, 4.0) var crit_multiplier: float = 1.5
@export var passive: PassiveEffect    # Resource
@export var ultimate: UltimateAbility # Resource
@export var portrait: Texture2D
@export var animation_set: SpriteFrames
