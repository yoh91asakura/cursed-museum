class_name CuratorData
extends Resource

const MIN_STARTER_DECK_SIZE := 4
const MAX_STARTER_DECK_SIZE := 6

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export_range(1, 50) var unlock_level: int = 1
@export var starter_deck: Array[CardData] = []
@export var global_run_passive: PassiveEffect
@export var portrait: Texture2D
