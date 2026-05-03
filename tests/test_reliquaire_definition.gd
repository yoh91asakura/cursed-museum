extends "res://addons/gdUnit4/src/core/GdUnitTestSuite.gd"

const SCRIPTS_PATH := "res://scripts/"
const DATA_PATH := "res://data/reliquaires/"

var _definition_script: GDScript
var _common: ReliquaireDefinition
var _uncommon: ReliquaireDefinition
var _rare: ReliquaireDefinition
var _epic: ReliquaireDefinition
var _mythical: ReliquaireDefinition


func before() -> void:
	_definition_script = load(SCRIPTS_PATH + "ReliquaireDefinition.gd")
	_common = load(DATA_PATH + "reliquaire_common.tres")
	_uncommon = load(DATA_PATH + "reliquaire_uncommon.tres")
	_rare = load(DATA_PATH + "reliquaire_rare.tres")
	_epic = load(DATA_PATH + "reliquaire_epic.tres")
	_mythical = load(DATA_PATH + "reliquaire_mythical.tres")


func test_reliquaire_definition_is_resource() -> void:
	assert_object(_common).is_instance_of(ReliquaireDefinition)
	assert_object(_common).is_instance_of(Resource)


func test_common_costs_match_spec() -> void:
	assert_int(_common.essence_cost).is_equal(100)
	assert_int(_common.fame_cost).is_equal(0)


func test_uncommon_costs_match_spec() -> void:
	assert_int(_uncommon.essence_cost).is_equal(500)
	assert_int(_uncommon.fame_cost).is_equal(0)


func test_rare_costs_match_spec() -> void:
	assert_int(_rare.essence_cost).is_equal(2500)
	assert_int(_rare.fame_cost).is_equal(0)


func test_epic_costs_match_spec() -> void:
	assert_int(_epic.essence_cost).is_equal(12500)
	assert_int(_epic.fame_cost).is_equal(0)


func test_mythical_costs_match_spec() -> void:
	assert_int(_mythical.essence_cost).is_equal(50000)
	assert_int(_mythical.fame_cost).is_equal(5)


func test_common_min_rarity() -> void:
	assert_int(_common.min_rarity).is_equal(0)


func test_uncommon_min_rarity() -> void:
	assert_int(_uncommon.min_rarity).is_equal(1)


func test_rare_min_rarity() -> void:
	assert_int(_rare.min_rarity).is_equal(2)


func test_epic_min_rarity() -> void:
	assert_int(_epic.min_rarity).is_equal(3)


func test_mythical_min_rarity() -> void:
	assert_int(_mythical.min_rarity).is_equal(5)


func test_common_has_no_guarantee() -> void:
	assert_int(_common.guaranteed_rarity).is_equal(-1)


func test_uncommon_guarantees_uncommon() -> void:
	assert_int(_uncommon.guaranteed_rarity).is_equal(1)


func test_rare_guarantees_rare() -> void:
	assert_int(_rare.guaranteed_rarity).is_equal(2)


func test_epic_guarantees_epic() -> void:
	assert_int(_epic.guaranteed_rarity).is_equal(3)


func test_mythical_guarantees_mythical() -> void:
	assert_int(_mythical.guaranteed_rarity).is_equal(5)


func test_epic_has_legendary_pity() -> void:
	assert_int(_epic.pity_count).is_equal(10)
	assert_int(_epic.pity_rarity).is_equal(4)


func test_non_epic_have_no_pity() -> void:
	assert_int(_common.pity_count).is_equal(0)
	assert_int(_uncommon.pity_count).is_equal(0)
	assert_int(_rare.pity_count).is_equal(0)
	assert_int(_mythical.pity_count).is_equal(0)


func test_all_five_ids_are_unique() -> void:
	var ids := PackedStringArray([_common.id, _uncommon.id, _rare.id, _epic.id, _mythical.id])
	var seen: Dictionary
	for id in ids:
		seen[id] = seen.get(id, 0) + 1
	assert_int(seen.size()).is_equal(5)


func test_essence_cost_increases_with_rarity() -> void:
	assert_bool(_common.essence_cost < _uncommon.essence_cost).is_true()
	assert_bool(_uncommon.essence_cost < _rare.essence_cost).is_true()
	assert_bool(_rare.essence_cost < _epic.essence_cost).is_true()
	assert_bool(_epic.essence_cost < _mythical.essence_cost).is_true()
