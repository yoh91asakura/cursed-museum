extends "res://addons/gdUnit4/src/core/GdUnitTestSuite.gd"


func test_level_1_xp_zero() -> void:
	assert_int(GameState.xp_for_level(1)).is_equal(0)


func test_xp_curve_increases_monotonically() -> void:
	var prev := 0
	for lvl in range(2, 51):
		var cost := GameState.xp_for_level(lvl) - GameState.xp_for_level(lvl - 1)
		assert_int(cost).is_greater(prev)
		prev = cost


func test_xp_for_next_level_sanity() -> void:
	# Fresh state, level 1
	var state := autoload_fresh()
	assert_int(state.xp_for_next_level()).is_equal(int(round(100.0 * pow(1.15, 0))))


func test_add_xp_levels_up() -> void:
	var state := autoload_fresh()
	var to_level_2 := state.xp_for_next_level()
	# Add exactly enough XP to level up
	var leveled := state.add_xp(to_level_2)
	assert_bool(leveled).is_true()
	assert_int(state.level).is_equal(2)
	assert_int(state.xp).is_equal(to_level_2)


func test_add_xp_multi_level() -> void:
	var state := autoload_fresh()
	# Add enough to reach level 5
	var needed := GameState.xp_for_level(5) + 10
	var leveled := state.add_xp(needed)
	assert_bool(leveled).is_true()
	assert_int(state.level).is_greater_equal(5)


func test_get_level_progress_at_zero() -> void:
	var state := autoload_fresh()
	assert_float(state.get_level_progress()).is_equal(0.0)


func test_get_level_progress_mid() -> void:
	var state := autoload_fresh()
	var half := int(round(state.xp_for_next_level() * 0.5))
	state.add_xp(half)
	var progress := state.get_level_progress()
	assert_float(progress).is_greater(0.0).is_less(1.0)


func test_essence_add_and_spend() -> void:
	var state := autoload_fresh()
	state.add_essence(500)
	assert_int(state.essence).is_equal(500)
	assert_bool(state.spend_essence(300)).is_true()
	assert_int(state.essence).is_equal(200)
	assert_bool(state.spend_essence(999)).is_false()
	assert_int(state.essence).is_equal(200)


func test_fame_add_and_spend() -> void:
	var state := autoload_fresh()
	state.add_fame(50)
	assert_int(state.fame).is_equal(50)
	assert_bool(state.spend_fame(50)).is_true()
	assert_int(state.fame).is_equal(0)
	assert_bool(state.spend_fame(1)).is_false()


func test_serialization_roundtrip() -> void:
	var state := autoload_fresh()
	state.level = 12
	state.xp = 1450
	state.prestige_stars = 2
	state.ascension_max = 5
	state.essence = 18500
	state.fame = 24

	var saved := state.to_dict()
	assert_int(saved.level).is_equal(12)
	assert_int(saved.currencies.essence).is_equal(18500)

	# Load into a fresh instance
	var restored := autoload_fresh()
	restored.from_dict(saved)
	assert_int(restored.level).is_equal(12)
	assert_int(restored.xp).is_equal(1450)
	assert_int(restored.prestige_stars).is_equal(2)
	assert_int(restored.ascension_max).is_equal(5)
	assert_int(restored.essence).is_equal(18500)
	assert_int(restored.fame).is_equal(24)


func test_can_prestige_false_when_not_max_level() -> void:
	var state := autoload_fresh()
	state.level = 49
	assert_bool(state.can_prestige(5, true)).is_false()


func test_can_prestige_true_when_all_conditions_met() -> void:
	var state := autoload_fresh()
	state.level = 50
	assert_bool(state.can_prestige(5, true)).is_true()


func test_can_prestige_false_without_ascension_5_win() -> void:
	var state := autoload_fresh()
	state.level = 50
	assert_bool(state.can_prestige(5, false)).is_false()


func test_prestige_resets_essence_and_level() -> void:
	var state := autoload_fresh()
	state.level = 50
	state.xp = 99999
	state.essence = 10_000_000
	state.prestige()
	assert_int(state.essence).is_equal(0)
	assert_int(state.level).is_equal(1)
	assert_int(state.xp).is_equal(0)
	assert_int(state.prestige_stars).is_equal(1)


func test_prestige_preserves_fame_and_ascension() -> void:
	var state := autoload_fresh()
	state.fame = 200
	state.ascension_max = 8
	state.level = 50
	state.prestige()
	assert_int(state.fame).is_equal(200)
	assert_int(state.ascension_max).is_equal(8)


func test_from_dict_handles_partial_data() -> void:
	var state := autoload_fresh()
	state.from_dict({"level": 5})
	assert_int(state.level).is_equal(5)
	assert_int(state.xp).is_equal(0)      # defaults
	assert_int(state.essence).is_equal(0) # defaults


# -- helpers ----------------------------------------------------------------

func autoload_fresh() -> GameState:
	var gs := GameState.new()
	gs.level = 1
	gs.xp = 0
	gs.essence = 0
	gs.fame = 0
	gs.prestige_stars = 0
	gs.ascension_max = 0
	return gs
