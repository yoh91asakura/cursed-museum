extends Node
## GameState autoload — singleton holding player persistent state.
##
## Fields per DESIGN.md §9.1-9.3 and save format §10.4:
##   level, xp, essence, fame, prestige_stars, ascension_max
##
## XP curve: exponential 1.15× per level (DESIGN.md §9.2).
## Prestige: DESIGN.md §9.3 — resets Essence/level/museum but preserves Fame/collection/ascension_max.

const BASE_XP := 100.0
const XP_GROWTH_RATE := 1.15
const MAX_LEVEL_V1 := 50
const MAX_PRESTIGE := 20
const MAX_ASCENSION := 20

# -- Signals ----------------------------------------------------------------

signal essence_changed(new_value: int)
signal fame_changed(new_value: int)
signal xp_changed(new_value: int)
signal level_up(new_level: int)
signal prestige_occurred(new_stars: int)

# -- Persistent player state ------------------------------------------------

var level: int = 1
var xp: int = 0
var essence: int = 0
var fame: int = 0
var prestige_stars: int = 0
var ascension_max: int = 0


# -- XP / Leveling ----------------------------------------------------------

## Total XP required to *reach* the given level (cumulative from level 1).
static func xp_for_level(target_level: int) -> int:
	if target_level <= 1:
		return 0
	var total := 0.0
	for lvl in range(1, target_level):
		total += BASE_XP * pow(XP_GROWTH_RATE, lvl - 1)
	return int(round(total))


## XP required to advance from current level to current_level + 1.
func xp_for_next_level() -> int:
	return _xp_to_next(level)


## Return 0.0 - 1.0 progress through current level.
func get_level_progress() -> float:
	var current_level_total := xp_for_level(level)
	var next_level_total := xp_for_level(level + 1)
	var needed := next_level_total - current_level_total
	if needed <= 0:
		return 1.0
	var into_level := xp - current_level_total
	return clampf(float(into_level) / float(needed), 0.0, 1.0)


## Add XP. Emits signals if a level-up fires. Returns true if at least one
## level was gained.
func add_xp(amount: int) -> bool:
	xp += amount
	xp_changed.emit(xp)
	var leveled := false
	while level < MAX_LEVEL_V1 and xp >= xp_for_level(level + 1):
		level += 1
		level_up.emit(level)
		leveled = true
	return leveled


# -- Currencies (DESIGN.md §9.1) --------------------------------------------

func add_essence(amount: int) -> void:
	essence += amount
	essence_changed.emit(essence)


## Returns true if the spend succeeded (player had enough Essence).
func spend_essence(amount: int) -> bool:
	if essence < amount:
		return false
	essence -= amount
	essence_changed.emit(essence)
	return true


func add_fame(amount: int) -> void:
	fame += amount
	fame_changed.emit(fame)


## Returns true if the spend succeeded (player had enough Fame).
func spend_fame(amount: int) -> bool:
	if fame < amount:
		return false
	fame -= amount
	fame_changed.emit(fame)
	return true


# -- Prestige (DESIGN.md §9.3) ----------------------------------------------

## Check whether the player meets prestige requirements.
func can_prestige(tier_reached: int, has_ascension_5_win: bool) -> bool:
	return (
		level >= MAX_LEVEL_V1
		and tier_reached >= 5
		and has_ascension_5_win
		and prestige_stars < MAX_PRESTIGE
	)


## Execute a prestige reset. The caller (MuseumState / SaveSystem) is
## responsible for resetting museum slots and tiers.
func prestige() -> void:
	# Reset what DESIGN.md §9.3 says must reset
	essence = 0
	essence_changed.emit(essence)
	level = 1
	xp = 0
	xp_changed.emit(xp)
	# Note: museum slots/tiers are reset by MuseumState, not GameState.

	# Gain
	prestige_stars += 1
	prestige_occurred.emit(prestige_stars)


# -- Serialization helpers (used by SaveSystem) -----------------------------

## Dump state to a Dictionary matching the §10.4 "player" schema.
func to_dict() -> Dictionary:
	return {
		level = level,
		xp = xp,
		prestige_stars = prestige_stars,
		ascension_max = ascension_max,
		currencies = {
			essence = essence,
			fame = fame,
		},
	}


## Load state from a Dictionary matching the §10.4 "player" schema.
func from_dict(data: Dictionary) -> void:
	level = data.get("level", 1)
	xp = data.get("xp", 0)
	prestige_stars = data.get("prestige_stars", 0)
	ascension_max = data.get("ascension_max", 0)
	var currencies: Dictionary = data.get("currencies", {})
	essence = currencies.get("essence", 0)
	fame = currencies.get("fame", 0)


# -- Private helpers ---------------------------------------------------------

static func _xp_to_next(lvl: int) -> int:
	return xp_for_level(lvl + 1) - xp_for_level(lvl)
