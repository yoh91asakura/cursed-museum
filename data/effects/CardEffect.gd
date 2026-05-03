class_name CardEffect
extends Resource

enum Trigger {
	ON_BATTLE_START,
	ON_HIT,
	ON_KILL,
	ON_TURN_END,
	ON_STAGGER,
}

@export var trigger: Trigger = Trigger.ON_BATTLE_START
@export var target: TargetSelector
@export var actions: Array[EffectAction] = []


func resolve(context: Variant) -> void:
	var targets: Array = []

	if target != null:
		targets = target.resolve(context)

	for action in actions:
		if action != null:
			action.execute(targets, context)
