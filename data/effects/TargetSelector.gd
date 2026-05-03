class_name TargetSelector
extends Resource

enum TargetMode {
	SELF,
	CURRENT_TARGET,
	ENEMY_RANDOM,
	ALL_ALLIES,
	ALL_ENEMIES,
	ALL_CARDS,
}

@export var mode: TargetMode = TargetMode.SELF
@export_range(0, 16) var max_targets: int = 1
@export var include_defeated: bool = false


func resolve(context: Variant) -> Array:
	if context is Object and context.has_method("resolve_targets"):
		return _as_array(context.call("resolve_targets", self))

	var targets: Array = []

	match mode:
		TargetMode.SELF:
			targets = _context_array(context, &"self")
		TargetMode.CURRENT_TARGET:
			targets = _context_array(context, &"target")
		TargetMode.ENEMY_RANDOM:
			targets = _context_array(context, &"enemies")
		TargetMode.ALL_ALLIES:
			targets = _context_array(context, &"allies")
		TargetMode.ALL_ENEMIES:
			targets = _context_array(context, &"enemies")
		TargetMode.ALL_CARDS:
			targets = _context_array(context, &"allies")
			targets.append_array(_context_array(context, &"enemies"))

	return _limit_targets(targets)


func _context_array(context: Variant, key: StringName) -> Array:
	if context is Dictionary:
		if context.has(key):
			return _as_array(context[key])

		var string_key := String(key)
		if context.has(string_key):
			return _as_array(context[string_key])

	if context is Object:
		var getter := "get_%s" % String(key)
		if context.has_method(getter):
			return _as_array(context.call(getter))

	return []


func _as_array(value: Variant) -> Array:
	if value == null:
		return []

	if value is Array:
		var result: Array = []
		result.append_array(value)
		return result

	return [value]


func _limit_targets(targets: Array) -> Array:
	var valid_targets: Array = []
	for target in targets:
		if include_defeated or not _is_defeated(target):
			valid_targets.append(target)

	if max_targets == 0:
		return valid_targets

	var limited: Array = []
	var limit := min(max_targets, valid_targets.size())

	for index in range(limit):
		limited.append(valid_targets[index])

	return limited


func _is_defeated(target: Variant) -> bool:
	if target is Dictionary:
		if target.has(&"is_defeated"):
			return bool(target[&"is_defeated"])
		if target.has("is_defeated"):
			return bool(target["is_defeated"])

	if target is Object:
		if target.has_method("is_defeated"):
			return bool(target.call("is_defeated"))
		var defeated_value: Variant = target.get("is_defeated")
		if defeated_value != null:
			return bool(defeated_value)

	return false
