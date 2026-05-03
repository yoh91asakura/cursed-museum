extends GdUnitTestSuite
## Unit tests for SaveSystem migration & version handling (CRSD-025)

const SCRIPT_PATH := "res://autoload/SaveSystem.gd"

var _save_system: Node


func before() -> void:
	var script := load(SCRIPT_PATH) as Script
	assert_not_null(script, "SaveSystem script must load")
	_save_system = Node.new()
	_save_system.set_script(script)
	_save_system._ready()


func after() -> void:
	if _save_system != null:
		_save_system.free()


func test_empty_save_returns_v3() -> void:
	var data := _save_system.get_data()
	assert_int(data["version"]).is_equal(SaveSystem.SAVE_VERSION)
	assert_bool(data.has("_migration_log")).is_true()


func test_set_data_bumps_version() -> void:
	_save_system.set_data({"some": "payload"})
	assert_int(_save_system.get_data()["version"]).is_equal(SaveSystem.SAVE_VERSION)
	assert_str(_save_system.get_data()["some"]).is_equal("payload")


func test_migration_v2_to_v3_structure() -> void:
	var raw := {
		"version": 2,
		"_migration_log": ["v1->v2 at 123456"],
	}
	_save_system.set_data(raw)
	_save_system._apply_migrations()
	var data := _save_system.get_data()
	assert_int(data["version"]).is_equal(3)
	assert_int(data["player"]["level"]).is_equal(1)
	assert_array(data["inventory"]["cards_unlocked"]).is_empty()
	assert_int(data["museum"]["tier"]).is_equal(1)
	assert_bool(data["active_run"] == null).is_true()
	assert_int(data["_migration_log"].size()).is_equal(2)


func test_no_version_field_defaults_to_empty() -> void:
	_save_system.set_data({"junk": true})
	_save_system._apply_migrations()
	var data := _save_system.get_data()
	assert_int(data["version"]).is_equal(3)
	assert_bool(data.has("junk")).is_false()


func test_already_at_v3_skips_migration() -> void:
	_save_system.set_data({"version": 3, "_migration_log": ["v2->v3 at 99"], "player": {}})
	_save_system._apply_migrations()
	assert_int(_save_system.get_data()["_migration_log"].size()).is_equal(1)


func test_missing_handler_does_not_crash() -> void:
	_save_system._migrations = {}
	_save_system.set_data({"version": 2, "_migration_log": []})
	_save_system._apply_migrations()
	assert_int(_save_system.get_data()["version"]).is_equal(2)
