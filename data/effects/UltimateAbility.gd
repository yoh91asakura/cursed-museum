class_name UltimateAbility
extends Resource

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export_range(0, 1000) var energy_cost: int = 100
@export var starts_charged: bool = false
@export var effects: Array[CardEffect] = []


func can_activate(context: Variant) -> bool:
	if context is Object and context.has_method("can_activate_ultimate"):
		return bool(context.call("can_activate_ultimate", self))

	if context is Dictionary:
		if context.has("available_energy"):
			return int(context["available_energy"]) >= energy_cost
		if context.has(&"available_energy"):
			return int(context[&"available_energy"]) >= energy_cost

	return starts_charged or energy_cost <= 0


func resolve(context: Variant) -> void:
	for effect in effects:
		if effect != null:
			effect.resolve(context)
