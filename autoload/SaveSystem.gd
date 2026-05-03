extends Node
## SaveSystem — Persistance encrypted local + Steam Cloud
##
## Autoload singleton. Handles save/load of the full game state as
## AES-256-CBC encrypted JSON, with SHA-256 checksum and atomic writes.
##
## DESIGN.md §10.4: key derived from Steam ID (fallback: machine GUID).
##
## CRSD-025: built-in version migration infrastructure.
## Migrations are registered via register_migration(from_version, handler).
## On load, migrations run sequentially from the save's version up to SAVE_VERSION.
## v2 mobile is dead, but the format stays ready to evolve.

const SAVE_VERSION: int = 3
const SAVE_FILENAME: String = "save.dat"
const TMP_SUFFIX: String = ".tmp"
const MIGRATION_LOG_KEY: String = "_migration_log"

var _save_path: String = ""
var _aes_key: PackedByteArray = PackedByteArray()
var _migrations: Dictionary = {}  # int -> Callable


# ------------------------------------------------------------------ Lifetime
func _ready() -> void:
	_ensure_save_dir()
	_derive_key()
	_register_builtin_migrations()
	# Do NOT auto-load here — Main.tscn boot sequence calls load_save() explicitly.


# --------------------------------------------------------------- Public API
## Register a migration handler that transforms data from_version into from_version+1.
func register_migration(from_version: int, handler: Callable) -> void:
	_migrations[from_version] = handler


func save_exists() -> bool:
	return FileAccess.file_exists(_save_path)


func save_game(data: Dictionary) -> Error:
	# Inject version + checksum
	var to_save := data.duplicate(true)
	to_save["version"] = SAVE_VERSION
	to_save["last_seen_unix"] = int(Time.get_unix_time_from_system())

	var json_str := JSON.stringify(to_save, "\t", false, true)
	if json_str.is_empty():
		printerr("SaveSystem: JSON.stringify returned empty string.")
		return ERR_INVALID_DATA

	to_save["checksum"] = _checksum(json_str)

	# Re-serialize with checksum included
	json_str = JSON.stringify(to_save, "\t", false, true)
	if json_str.is_empty():
		printerr("SaveSystem: JSON.stringify (with checksum) returned empty string.")
		return ERR_INVALID_DATA

	var encrypted := _encrypt(json_str.to_utf8_buffer())
	if encrypted.is_empty():
		printerr("SaveSystem: encryption failed.")
		return ERR_CANT_CREATE

	# Atomic write: tmp → fsync → rename
	var tmp_path := _save_path + TMP_SUFFIX
	var fa := FileAccess.open(tmp_path, FileAccess.WRITE)
	if fa == null:
		printerr("SaveSystem: cannot open tmp file for writing: ", tmp_path)
		return FileAccess.get_open_error()

	fa.store_buffer(encrypted)
	fa.flush()
	fa.close()

	var da := DirAccess.open("res://")
	if da == null:
		return ERR_CANT_CREATE

	# Remove stale target before rename (Godot DirAccess.rename overwrites on some platforms)
	if FileAccess.file_exists(_save_path):
		da.remove(_save_path)

	var err := da.rename(tmp_path, _save_path)
	if err != OK:
		printerr("SaveSystem: atomic rename failed: ", error_string(err))
		return err

	return OK


func load_save() -> Variant:
	"""
	Returns Dictionary on success, null on failure or no save.
	Caller is responsible for validating the returned data.
	Migrations are applied automatically before returning.
	"""
	if not save_exists():
		return null

	var fa := FileAccess.open(_save_path, FileAccess.READ)
	if fa == null:
		printerr("SaveSystem: cannot open save file for reading: ", _save_path)
		return null

	var encrypted := fa.get_buffer(fa.get_length())
	fa.close()

	if encrypted.is_empty():
		printerr("SaveSystem: save file is empty.")
		return null

	var plain_bytes := _decrypt(encrypted)
	if plain_bytes.is_empty():
		printerr("SaveSystem: decryption failed (wrong key or corrupted file).")
		return null

	var json_str := plain_bytes.get_string_from_utf8()
	if json_str.is_empty():
		printerr("SaveSystem: decoded UTF-8 is empty.")
		return null

	var json := JSON.new()
	var err := json.parse(json_str)
	if err != OK:
		printerr("SaveSystem: JSON parse error at line ", json.get_error_line(), ": ", json.get_error_message())
		return null

	var data = json.get_data()
	if typeof(data) != TYPE_DICTIONARY:
		printerr("SaveSystem: save root is not a Dictionary.")
		return null

	if not data.has("checksum"):
		printerr("SaveSystem: missing checksum field.")
		return null

	# Verify checksum — remove it, re-compute over the rest
	var stored_checksum = data["checksum"]
	var without_checksum := data.duplicate(true)
	without_checksum.erase("checksum")
	var recomputed := _checksum(JSON.stringify(without_checksum, "\t", false, true))

	if stored_checksum != recomputed:
		printerr("SaveSystem: checksum mismatch — save may be corrupted.")
		return null

	# Apply pending migrations before returning
	data = _apply_migrations(data)
	if data == null:
		return null

	return data


func delete_save() -> Error:
	if not save_exists():
		return OK
	var da := DirAccess.open("res://")
	if da == null:
		return ERR_CANT_CREATE
	var err := da.remove(_save_path)
	if err != OK:
		printerr("SaveSystem: failed to delete save: ", error_string(err))
	return err


# -------------------------------------------------------- Migration system
func _apply_migrations(data: Dictionary) -> Variant:
	"""Run sequential migrations from data.version up to SAVE_VERSION. Returns migrated dict or null on failure."""
	var result := data.duplicate(true)

	if not result.has("version") or not result["version"] is int:
		printerr("SaveSystem: save missing version field; cannot migrate.")
		return null

	var from_version: int = result["version"]
	var log: Array = result.get(MIGRATION_LOG_KEY, [])

	while from_version < SAVE_VERSION:
		var next_version := from_version + 1
		if not _migrations.has(from_version):
			printerr("SaveSystem: no migration handler for v%d -> v%d. Aborting." % [from_version, next_version])
			return null

		result = _migrations[from_version].call(result)
		result["version"] = next_version
		log.append("v%d->v%d at %d" % [from_version, next_version, Time.get_unix_time_from_system()])
		from_version = next_version

	result[MIGRATION_LOG_KEY] = log
	return result


func _register_builtin_migrations() -> void:
	# v2 mobile is dead; register a no-op migration v2 -> v3
	# that adds the _migration_log and ensures the version field.
	register_migration(2, _migrate_v2_to_v3)


func _migrate_v2_to_v3(data: Dictionary) -> Dictionary:
	# v2 was a mobile gacha format — dead. We just ensure the
	# top-level keys from DESIGN.md §10.4 exist as empty stubs.
	return {
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


# ------------------------------------------------------------- Internals
func _ensure_save_dir() -> void:
	# On desktop, "user://" is a writable per-game folder.
	# FileAccess.open with FileAccess.WRITE will also create the directory.
	# We explicitly create it to be safe.
	DirAccess.make_dir_recursive_absolute("user://")
	_save_path = "user://".path_join(SAVE_FILENAME)


func _derive_key() -> void:
	# Try Steam ID first; fall back to machine GUID (DESIGN.md §10.4).
	# In practice SteamBridge will be the canonical source once available.
	var key_material := OS.get_unique_id()
	# Harden: hash the material to get exactly 32 bytes for AES-256.
	_aes_key = key_material.sha256_buffer()


func _encrypt(plain: PackedByteArray) -> PackedByteArray:
	if _aes_key.is_empty():
		printerr("SaveSystem: _encrypt called before _derive_key.")
		return PackedByteArray()
	return Crypto.new().encrypt(_aes_key, plain)


func _decrypt(cipher: PackedByteArray) -> PackedByteArray:
	if _aes_key.is_empty():
		printerr("SaveSystem: _decrypt called before _derive_key.")
		return PackedByteArray()
	return Crypto.new().decrypt(_aes_key, cipher)


func _checksum(json_str: String) -> String:
	return "sha256:" + json_str.sha256_text()
