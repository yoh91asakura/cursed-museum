class_name RelicData
extends Resource

enum RelicRarity {
	COMMON,
	UNCOMMON,
	RARE,
	BOSS,
	CURSED,
}

enum RelicTrigger {
	ON_RUN_START,
	ON_NODE_ENTER,
	ON_DRAFT,
	ON_SHOP_ENTER,
	ON_BATTLE_START,
	ON_HIT,
	ON_KILL,
	ON_TURN_END,
	ON_STAGGER,
}

@export var id: StringName
@export var display_name: String
@export var rarity: RelicRarity = RelicRarity.COMMON
@export_multiline var description: String
@export var triggers: Array[RelicTrigger] = []
@export var actions: Array[EffectAction] = []
@export var icon: Texture2D
