class_name EffectAction
extends Resource

enum ActionType {
	DAMAGE,
	HEAL,
	APPLY_BUFF,
	REMOVE_BUFF,
	GAIN_ENERGY,
	SUMMON,
}

@export var action_type: ActionType = ActionType.DAMAGE
@export var amount: int = 0
@export var effect_id: StringName
@export var duration_seconds: float = 0.0
@export var parameters: Dictionary = {}


func execute(targets: Array, context: Variant) -> void:
	if context is Object and context.has_method("execute_effect_action"):
		context.call("execute_effect_action", self, targets)
		return

	if context is Dictionary:
		if context.has("action_log") and context["action_log"] is Array:
			context["action_log"].append(to_log_entry(targets))
		elif context.has(&"action_log") and context[&"action_log"] is Array:
			context[&"action_log"].append(to_log_entry(targets))


func to_log_entry(targets: Array) -> Dictionary:
	return {
		"action_type": action_type,
		"amount": amount,
		"effect_id": effect_id,
		"duration_seconds": duration_seconds,
		"parameters": parameters.duplicate(true),
		"target_count": targets.size(),
	}
