extends GdUnitTestSuite
## CRSD-025 — SaveSystem version migration tests (DESIGN.md §10.4, §13)


# --------------------------------------------------------------- Tests
func test_apply_migrations_v2_to_v3_structure() -> void:
	var raw := {
		"version": 2,
		"_migration_log": ["v1->v2 at 123456"],
	}
	var result = SaveSystem._apply_migrations(raw)
	assert_that(result).is_not_null()

	var data := result as Dictionary
	assert_int(data["version"]).is_equal(3)
	assert_int(data["player"]["level"]).is_equal(1)
	assert_array(data["inventory"]["cards_unlocked"]).is_empty()
	assert_int(data["museum"]["tier"]).is_equal(1)
	assert_bool(data["active_run"] == null).is_true()
	assert_int(data["_migration_log"].size()).is_equal(2)


func test_apply_migrations_missing_version_returns_null() -> void:
	# No version field means we can't determine the migration path.
	var raw := {"junk": true}
	var result = SaveSystem._apply_migrations(raw)
	assert_that(result).is_null()


func test_apply_migrations_already_at_v3_is_noop() -> void:
	var raw := {"version": 3, "_migration_log": ["v2->v3 at 99"], "player": {}}
	var result = SaveSystem._apply_migrations(raw)
	assert_that(result).is_not_null()

	assert_int((result as Dictionary)["_migration_log"].size()).is_equal(1)
	assert_int((result as Dictionary)["version"]).is_equal(3)


func test_apply_migrations_missing_handler_returns_null() -> void:
	var old_migrations := SaveSystem._migrations.duplicate()
	SaveSystem._migrations = {}

	var raw := {"version": 2, "_migration_log": []}
	var result = SaveSystem._apply_migrations(raw)

	assert_that(result).is_null()

	SaveSystem._migrations = old_migrations
