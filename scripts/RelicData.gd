class_name RelicData
extends Resource

@export var id: StringName              # "echo_chamber"
@export var display_name: String        # "Echo Chamber"
@export var rarity: RelicRarity.Value   # Common/Uncommon/Rare/Boss/Cursed
@export var description: String         # "Cursed cards trigger their passive twice."
@export var triggers: Array[RelicTrigger.Value]  # When to fire
@export var actions: Array[EffectAction]          # What to do
@export var icon: Texture2D
