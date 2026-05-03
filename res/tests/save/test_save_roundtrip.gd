extends "res://addons/gdUnit4/src/core/GdUnitTestSuite.gd"

# CRSD-026: Tests unitaires save → quit → load → state intact, y compris run en cours
# See DESIGN.md §10.4 for save format specification

const SAVE_DIR := "user://test_saves"
const TEST_SAVE_NAME := "test_roundtrip"
const TEST_SAVE_NAME_RUN := "test_roundtrip_run"


func before() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	_reset_all_state()


func after() -> void:
	_reset_all_state()


func after_all() -> void:
	_cleanup_test_files()


func _reset_all_state() -> void:
	GameState.reset()
	Inventory.reset()
	MuseumState.reset()
	RunState.clear()


func _cleanup_test_files() -> void:
	var dir := DirAccess.open(SAVE_DIR)
	if dir:
		dir.include_hidden = true
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if file_name.begins_with("test_"):
				dir.remove(file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
		DirAccess.remove_absolute(SAVE_DIR)


# ── Round-trip sans run actif ────────────────────────────────────────────────

func test_save_load_roundtrip_no_active_run() -> void:
	# Populate state per DESIGN.md §10.4 save format fields
	GameState.set_level(12)
	GameState.set_xp(1450)
	GameState.set_prestige_stars(0)
	GameState.set_ascension_max(5)
	GameState.set_essence(18500)
	GameState.set_fame(24)

	Inventory.unlock_card("ancient_copypasta")
	Inventory.unlock_card("quantum_cat")
	Inventory.unlock_meta_relic("echo_chamber")
	Inventory.unlock_curator("the_archivist")

	MuseumState.set_tier(3)
	MuseumState.add_slot(0, 0, "ancient_copypasta")
	MuseumState.add_room(0, "chaos")

	assert_bool(RunState.is_active()).is_false()

	var save_path := _save_path(TEST_SAVE_NAME)
	var saved := SaveSystem.save_game(save_path)
	assert_bool(saved).is_true("Save should succeed without active run")
	assert_file(save_path).exists()

	# Simulate quit: reset all state
	_reset_all_state()

	# Verify state cleared
	assert_int(GameState.get_level()).is_equal(1)
	assert_int(GameState.get_xp()).is_equal(0)
	assert_int(GameState.get_essence()).is_equal(0)
	assert_int(GameState.get_fame()).is_equal(0)
	assert_bool(RunState.is_active()).is_false()

	# Load
	var loaded := SaveSystem.load_game(save_path)
	assert_bool(loaded).is_true("Load should succeed")

	# Assert all state restored intact
	assert_int(GameState.get_level()).is_equal(12)
	assert_int(GameState.get_xp()).is_equal(1450)
	assert_int(GameState.get_prestige_stars()).is_equal(0)
	assert_int(GameState.get_ascension_max()).is_equal(5)
	assert_int(GameState.get_essence()).is_equal(18500)
	assert_int(GameState.get_fame()).is_equal(24)

	assert_bool(Inventory.is_card_unlocked("ancient_copypasta")).is_true()
	assert_bool(Inventory.is_card_unlocked("quantum_cat")).is_true()
	assert_bool(Inventory.is_meta_relic_unlocked("echo_chamber")).is_true()
	assert_bool(Inventory.is_curator_unlocked("the_archivist")).is_true()

	assert_int(MuseumState.get_tier()).is_equal(3)
	assert_str(MuseumState.get_card_at(0, 0)).is_equal("ancient_copypasta")

	assert_bool(RunState.is_active()).is_false()


# ── Round-trip avec run actif ─────────────────────────────────────────────────

func test_save_load_roundtrip_with_active_run() -> void:
	# Set up idle state
	GameState.set_level(5)
	GameState.set_essence(5000)
	Inventory.unlock_card("meme_blade")
	Inventory.unlock_meta_relic("overclock_core")

	# Set up active run state (simulate mid-run)
	RunState.start_new_run(
		"the_glitch",       # curator
		["meme_blade"],     # starting deck
		["overclock_core"], # starting relics
		3,                  # zone
		[]                  # map nodes
	)

	assert_bool(RunState.is_active()).is_true()
	assert_str(RunState.get_curator()).is_equal("the_glitch")

	var save_path := _save_path(TEST_SAVE_NAME_RUN)
	var saved := SaveSystem.save_game(save_path)
	assert_bool(saved).is_true("Save with active run should succeed")

	# Simulate quit
	_reset_all_state()

	assert_bool(RunState.is_active()).is_false()
	assert_int(GameState.get_level()).is_equal(1)

	# Load
	var loaded := SaveSystem.load_game(save_path)
	assert_bool(loaded).is_true()

	# Assert idle state restored
	assert_int(GameState.get_level()).is_equal(5)
	assert_int(GameState.get_essence()).is_equal(5000)
	assert_bool(Inventory.is_card_unlocked("meme_blade")).is_true()
	assert_bool(Inventory.is_meta_relic_unlocked("overclock_core")).is_true()

	# Assert active run restored
	assert_bool(RunState.is_active()).is_true("Active run must be restored after load")
	assert_str(RunState.get_curator()).is_equal("the_glitch")


# ── Save version field ───────────────────────────────────────────────────────

func test_save_version_field_present() -> void:
	GameState.set_level(1)
	var save_path := _save_path("test_version")
	SaveSystem.save_game(save_path)
	assert_file(save_path).exists()

	var raw := SaveSystem.read_raw_save_data(save_path)
	assert_dict(raw).contains_key("version")
	assert_int(raw["version"]).is_greater_equal(3)


# ── Atomic write ─────────────────────────────────────────────────────────────

func test_save_atomic_write_no_partial_file() -> void:
	GameState.set_essence(99999)
	var save_path := _save_path("test_atomic")
	var tmp_path := save_path + ".tmp"

	# Clean any prior leftovers
	DirAccess.remove_absolute(tmp_path)
	DirAccess.remove_absolute(save_path)

	var saved := SaveSystem.save_game(save_path)
	assert_bool(saved).is_true()

	# Atomic write must not leave .tmp behind
	assert_bool(FileAccess.file_exists(tmp_path)).is_false(
		"Atomic write must not leave a .tmp file behind"
	)
	assert_bool(FileAccess.file_exists(save_path)).is_true(
		"Final save file must exist after atomic write"
	)

	# Load to verify data is intact
	_reset_all_state()
	SaveSystem.load_game(save_path)
	assert_int(GameState.get_essence()).is_equal(99999)


# ── Checksum integrity ───────────────────────────────────────────────────────

func test_save_checksum_detects_tampering() -> void:
	GameState.set_essence(12345)
	var save_path := _save_path("test_checksum")
	SaveSystem.save_game(save_path)

	# Tamper with the file
	var f := FileAccess.open(save_path, FileAccess.READ_WRITE)
	f.seek(0)
	f.store_string("tampered data")
	f.close()

	var loaded := SaveSystem.load_game(save_path)
	assert_bool(loaded).is_false("Load should fail when checksum is invalid")


# ── Graceful error handling ──────────────────────────────────────────────────

func test_load_missing_file_returns_false() -> void:
	var loaded := SaveSystem.load_game(_save_path("nonexistent"))
	assert_bool(loaded).is_false("Loading nonexistent file should return false")
	assert_bool(RunState.is_active()).is_false("RunState must remain inactive on failed load")


func test_load_corrupted_json_returns_false() -> void:
	var save_path := _save_path("test_corrupt")
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	var f := FileAccess.open(save_path, FileAccess.WRITE)
	f.store_string("{ not valid json !!!")
	f.close()

	var loaded := SaveSystem.load_game(save_path)
	assert_bool(loaded).is_false("Loading corrupted JSON should return false")


# ── MuseumIdleClock pause during run ─────────────────────────────────────────

func test_idle_clock_paused_during_active_run() -> void:
	# DESIGN.md §3.2 rule 1: MuseumIdleClock MUST be paused while run is active
	# This test belongs here because save→load must preserve the pause state

	MuseumIdleClock.resume()
	assert_bool(MuseumIdleClock.is_running()).is_true()

	RunState.start_new_run("the_archivist", ["ancient_copypasta"], [], 1, [])
	assert_bool(RunState.is_active()).is_true()

	# Save with run active
	var save_path := _save_path("test_idle_pause")
	SaveSystem.save_game(save_path)

	# Reload
	_reset_all_state()
	SaveSystem.load_game(save_path)

	# Reload of a run in progress must not resume idle clock
	assert_bool(RunState.is_active()).is_true("Run must be active after load")
	assert_bool(MuseumIdleClock.is_running()).is_false(
		"MuseumIdleClock MUST NOT tick while RunState has active run (DESIGN.md §3.2 rule 1)"
	)


# ── Helpers ──────────────────────────────────────────────────────────────────

func _save_path(name: String) -> String:
	return SAVE_DIR.path_join(name + ".sav")
