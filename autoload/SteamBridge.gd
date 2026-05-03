extends Node

signal steam_initialized
signal steam_initialization_failed(status: int, message: String)
signal steam_shutdown

const STEAM_INIT_OK := 0
const STEAM_INIT_UNAVAILABLE := -1
const STEAM_INIT_FAILED := 1

var _steam: Object
var _initialized := false
var _init_result: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	initialize()


func _process(_delta: float) -> void:
	if _initialized and _steam != null and _steam.has_method("run_callbacks"):
		_steam.call("run_callbacks")


func _exit_tree() -> void:
	shutdown()


func initialize(app_id: int = 0, embed_callbacks: bool = false) -> bool:
	if _initialized:
		return true

	_steam = _get_steam_singleton()
	if _steam == null:
		_record_init_failure(
			STEAM_INIT_UNAVAILABLE,
			"GodotSteam singleton is unavailable; continuing in offline Steam mode."
		)
		set_process(false)
		return false

	set_process(true)

	var result: Variant
	if _steam.has_method("steamInitEx"):
		result = _steam.call("steamInitEx", app_id, embed_callbacks)
	elif _steam.has_method("steamInit"):
		result = _steam.call("steamInit", app_id, embed_callbacks)
	else:
		_record_init_failure(STEAM_INIT_UNAVAILABLE, "GodotSteam init method is unavailable.")
		set_process(false)
		return false

	return _handle_init_result(result)


func shutdown() -> void:
	if _steam != null and _initialized and _steam.has_method("steamShutdown"):
		_steam.call("steamShutdown")

	_initialized = false
	set_process(false)
	steam_shutdown.emit()


func is_available() -> bool:
	return _steam != null or Engine.has_singleton("Steam")


func is_initialized() -> bool:
	return _initialized


func get_init_result() -> Dictionary:
	return _init_result.duplicate(true)


func get_steam_id() -> int:
	if not _initialized or _steam == null or not _steam.has_method("getSteamID"):
		return 0

	return int(_steam.call("getSteamID"))


func _get_steam_singleton() -> Object:
	if Engine.has_singleton("Steam"):
		return Engine.get_singleton("Steam")

	return null


func _handle_init_result(result: Variant) -> bool:
	var status := STEAM_INIT_FAILED
	var message := "Steam initialization failed."

	if result is Dictionary:
		_init_result = result
		status = int(_init_result.get("status", STEAM_INIT_FAILED))
		message = str(_init_result.get("verbal", message))
	elif result is bool:
		_initialized = bool(result)
		status = STEAM_INIT_OK if _initialized else STEAM_INIT_FAILED
		message = "Steam initialized." if _initialized else message
		_init_result = {
			"status": status,
			"verbal": message,
		}
	else:
		_init_result = {
			"status": status,
			"verbal": "GodotSteam returned an unexpected init result.",
		}
		message = str(_init_result["verbal"])

	_initialized = status == STEAM_INIT_OK

	if _initialized:
		steam_initialized.emit()
		return true

	_record_init_failure(status, message)
	set_process(false)
	return false


func _record_init_failure(status: int, message: String) -> void:
	_init_result = {
		"status": status,
		"verbal": message,
	}
	push_warning(message)
	steam_initialization_failed.emit(status, message)
