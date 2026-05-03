class_name PassiveEffect
extends Resource

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var effects: Array[CardEffect] = []


func resolve(trigger: int, context: Variant) -> void:
	for effect in get_effects_for_trigger(trigger):
		effect.resolve(context)


func get_effects_for_trigger(trigger: int) -> Array[CardEffect]:
	var matching_effects: Array[CardEffect] = []

	for effect in effects:
		if effect != null and effect.trigger == trigger:
			matching_effects.append(effect)

	return matching_effects
