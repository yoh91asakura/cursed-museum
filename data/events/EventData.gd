class_name EventData
extends Resource

enum EventRarity {
	COMMON,
	UNCOMMON,
	RARE,
	BOSS,
}

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var rarity: EventRarity = EventRarity.COMMON
@export var zone_ids: Array[StringName] = []
@export var tags: Array[StringName] = []

@export_multiline var intro_text: String
@export_multiline var resolve_text: String

# Each choice dictionary is data-only and resolved by the event engine.
# Expected keys: id, label, body, requirements, rewards, next_event_id.
@export var choices: Array[Dictionary] = []

@export var illustration: Texture2D
@export var music: AudioStream
