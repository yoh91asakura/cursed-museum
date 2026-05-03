extends GdUnitTestSuite
## CRSD-020 — SaveSystem round-trip tests (DESIGN.md §10.4)


# --------------------------------------------------------------- Fixtures
func before() -> void:
	# Ensure clean slate each test
	if SaveSystem.save_exists():
		var err := SaveSystem.delete_save()
		if err != OK:
			printerr("before(): delete_save returned ", error_string(err))


func after() -> void:
	SaveSystem.delete_save()


# --------------------------------------------------------------- Tests
func test_save_and_load_roundtrip() -> void:
	var original := {
		"player": {
			"level": 5,
			"xp": 420,
			"currencies": {"essence": 1000, "fame": 3},
		},
		"active_run": null,
	}

	var save_err := SaveSystem.save_game(original)
	assert_that(save_err).is_equal(OK)
	assert_bool(SaveSystem.save_exists()).is_true()

	var loaded = SaveSystem.load_save()
	assert_that(loaded).is_not_null()
	assert_that((loaded as Dictionary).get("player", {}).get("level")).is_equal(5)
	assert_that((loaded as Dictionary).get("player", {}).get("xp")).is_equal(420)
	assert_that((loaded as Dictionary).get("active_run")).is_equal(null)


func test_version_injected() -> void:
	var save_err := SaveSystem.save_game({"dummy": true})
	assert_that(save_err).is_equal(OK)

	var loaded = SaveSystem.load_save()
	assert_that(loaded).is_not_null()
	assert_that((loaded as Dictionary).get("version")).is_equal(3)


func test_checksum_field_present() -> void:
	SaveSystem.save_game({"a": 1})
	var data = SaveSystem.load_save()
	assert_that(data).is_not_null()
	assert_that((data as Dictionary).has("checksum")).is_true()
	var cs := (data as Dictionary).get("checksum", "") as String
	assert_bool(cs.begins_with("sha256:")).is_true()


func test_load_with_no_save_returns_null() -> void:
	assert_bool(SaveSystem.save_exists()).is_false()
	var loaded = SaveSystem.load_save()
	assert_that(loaded).is_null()


func test_delete_save() -> void:
	SaveSystem.save_game({"a": 1})
	assert_bool(SaveSystem.save_exists()).is_true()

	var err := SaveSystem.delete_save()
	assert_that(err).is_equal(OK)
	assert_bool(SaveSystem.save_exists()).is_false()


func test_active_run_persisted() -> void:
	var run_data := {
		"map_seed": 42,
		"position": 7,
		"deck": ["card_a", "card_b"],
	}
	SaveSystem.save_game({"active_run": run_data})

	var loaded = SaveSystem.load_save()
	assert_that(loaded).is_not_null()
	var active_run = (loaded as Dictionary).get("active_run")
	assert_that(active_run).is_not_null()
	assert_that((active_run as Dictionary).get("map_seed")).is_equal(42)
	assert_that((active_run as Dictionary).get("position")).is_equal(7)
	assert_that((active_run as Dictionary).get("deck")).is_equal(["card_a", "card_b"])
