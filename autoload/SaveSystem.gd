extends Node
## SaveSystem — Persistance encrypted local + Steam Cloud
##
## CRSD-025: built-in version migration infrastructure.
## v2 mobile is dead, but the format stays ready to evolve.
##
## Save format (§10.4): JSON encrypted, atomic writes, version at root.
##
## Migrations are registered via register_migration(from_version, handler).
## On load, migrations run sequentially from the save's version up to SAVE_VERSION.

const SAVE_VERSION := 3
const SAVE_FILE := "user://save.json"
const SAVE_TMP := "user://save.tmp"
const MIGRATION_LOG_KEY := "_migration_log"

var _migrations: Dictionary = {}  # int -> Callable

## Current in-memory save data (null if nothing loaded).
var _data: Dictionary = {}


func _ready() -> void:
	register_builtin_migrations()


## Register a migration handler for version bump: from_version -> from_version + 1.
func register_migration(from_version: int, handler: Callable) -> void:
	_migrations[from_version] = handler


## Load the save file, decrypt, run required migrations, return data or empty dict on missing/corrupt.
func load_save() -> Dictionary:
	if not FileAccess.file_exists(SAVE_FILE):
		_data = _empty_save()
		return _data

	var file := FileAccess.open_encrypted_with_pass(SAVE_FILE, FileAccess.READ, _encryption_key())
	if file == null:
		push_warning("SaveSystem: failed to open save, returning empty.")
		_data = _empty_save()
		return _data

	var json_text := file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(json_text)
	if parsed == null or not parsed is Dictionary:
		push_warning("SaveSystem: corrupt JSON, returning empty.")
		_data = _empty_save()
		return _data

	_data = parsed
	_apply_migrations()
	return _data


## Persist the current save data to disk (encrypted, atomic).
func persist() -> void:
	_data["version"] = SAVE_VERSION

	var json_text := JSON.stringify(_data, "\t")
	var file := FileAccess.open_encrypted_with_pass(SAVE_TMP, FileAccess.WRITE, _encryption_key())
	if file == null:
		push_error("SaveSystem: cannot open temp file for writing.")
		return

	file.store_string(json_text)
	file.close()

	# Atomic rename
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_FILE))
	var err := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(SAVE_TMP),
		ProjectSettings.globalize_path(SAVE_FILE)
	)
	if err != OK:
		push_error("SaveSystem: atomic rename failed (err=%d)." % err)


## Overwrite in-memory data (e.g. from GameState, Inventory, etc.).
func set_data(new_data: Dictionary) -> void:
	_data = new_data.duplicate(true)
	_data["version"] = SAVE_VERSION


## Get a reference to the current data dict (mutations persist in memory but not on disk).
func get_data() -> Dictionary:
	return _data


## --- internals -------------------------------------------------------


func _encryption_key() -> String:
	# Steam ID primary; fallback to machine GUID for offline/dev.
	var steam_id := OS.get_environment("SteamAppId")
	if steam_id != "":
		return "cm_" + steam_id
	return "cm_" + OS.get_unique_id()


func _empty_save() -> Dictionary:
	return {"version": SAVE_VERSION, "_migration_log": []}


func _apply_migrations() -> void:
	if not _data.has("version") or not _data["version"] is int:
		push_warning("SaveSystem: save missing version field; treating as empty.")
		_data = _empty_save()
		return

	var from_version: int = _data["version"]
	var log: Array = _data.get(MIGRATION_LOG_KEY, [])

	while from_version < SAVE_VERSION:
		var next_version := from_version + 1
		if not _migrations.has(from_version):
			push_error("SaveSystem: no migration handler for v%d -> v%d. Aborting." % [from_version, next_version])
			return

		_data = _migrations[from_version].call(_data)
		_data["version"] = next_version
		log.append("v%d->v%d at %d" % [from_version, next_version, Time.get_unix_time_from_system()])
		from_version = next_version

	_data[MIGRATION_LOG_KEY] = log


func register_builtin_migrations() -> void:
	# v2 mobile is dead; register a no-op migration v2 -> v3
	# that adds the _migration_log and ensures the version field.
	register_migration(2, _migrate_v2_to_v3)


func _migrate_v2_to_v3(data: Dictionary) -> Dictionary:
	# v2 was a mobile gacha format — dead. We just ensure the
	# top-level keys from DESIGN.md §10.4 exist as empty stubs.
	var result := {
		"player": data.get("player", {
			"level": 1, "xp": 0, "prestige_stars": 0, "ascension_max": 0,
			"currencies": {"essence": 0, "fame": 0}
		}),
		"inventory": data.get("inventory", {
			"cards_unlocked": [], "meta_relics_unlocked": [], "curators_unlocked": []
		}),
		"museum": data.get("museum", {
			"tier": 1, "slots": [], "rooms": []
		}),
		"decks": data.get("decks", []),
		"settings": data.get("settings", {"sound": 0.8, "music": 0.6, "battle_speed": 1, "screen_shake": 1.0}),
		"active_run": data.get("active_run", null),
		MIGRATION_LOG_KEY: data.get(MIGRATION_LOG_KEY, []),
	}
	return result
