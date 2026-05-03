extends Node
## RunState — autoload singleton tracking the active roguelite run.
##
## Null / empty state when no run is active. While a run is in progress this
## holds the live deck, relics, map graph, current position, and all run-scoped
## metadata so every system can query the current run without coupling.
##
## DESIGN.md §5 – Spécification du Run (Roguelite)

# ------------------------------------------------------------------ signals
signal run_started()
signal run_ended(outcome: String)   # "victory", "death", "abandoned"

# ------------------------------------------------------------------ enums
enum RunMode   { STANDARD, DAILY_SEED, WEEKLY_SEED }
enum RunOutcome { VICTORY, DEATH, ABANDONED }

# ================================================================== public API

## Returns true when a run is active (started and not yet ended).
func is_in_run() -> bool:
	return _active


## Start a new run. All parameters are mandatory, validated on entry.
## Call this from RunEngine or the pre-run setup flow.
func start_run(params: Dictionary) -> void:
	assert(not _active, "RunState.start_run: a run is already active")
	assert(params.has("seed"),         "RunState.start_run: missing 'seed'")
	assert(params.has("curator_id"),   "RunState.start_run: missing 'curator_id'")
	assert(params.has("difficulty"),   "RunState.start_run: missing 'difficulty'")
	assert(params.has("mode"),         "RunState.start_run: missing 'mode'")
	assert(params.has("deck"),         "RunState.start_run: missing 'deck'")
	assert(params.has("relics"),       "RunState.start_run: missing 'relics'")
	assert(params.has("map_graph"),    "RunState.start_run: missing 'map_graph'")
	assert(params.has("start_node"),   "RunState.start_run: missing 'start_node'")
	assert(params.has("zone_count"),   "RunState.start_run: missing 'zone_count'")

	_seed         = params["seed"]
	_curator_id   = params["curator_id"]
	_difficulty   = params["difficulty"]
	_mode         = params["mode"]
	_deck         = params["deck"].duplicate(true)
	_relics       = params["relics"].duplicate(true)
	_map_graph    = params["map_graph"].duplicate(true)
	_current_node = params["start_node"]
	_zone_count   = params["zone_count"]
	_current_zone = 0
	_gold         = params.get("gold", 0)
	_hp           = params.get("hp", _default_hp())
	_max_hp       = params.get("max_hp", _hp)
	_active       = true

	run_started.emit()


## End the current run and return summary data for the post-run screen.
## The RunOutcome determines how rewards are calculated (see §5.6).
func end_run(outcome: RunOutcome, hp: int = -1) -> Dictionary:
	assert(_active, "RunState.end_run: no active run to end")

	var summary := {
		"outcome":       outcome,
		"curator_id":    _curator_id,
		"difficulty":    _difficulty,
		"mode":          _mode,
		"seed":          _seed,
		"zones_cleared": _current_zone,
		"gold":          _gold,
		"hp":            hp if hp >= 0 else _hp,
		"deck":          _deck.duplicate(true),
		"relics":        _relics.duplicate(true),
	}

	_clear()
	run_ended.emit(_outcome_name(outcome))
	return summary


## Abandon the current run without rewards (see §5.6 — Abandon volontaire).
func abandon() -> Dictionary:
	return end_run(RunOutcome.ABANDONED, _hp)

# ================================================================== accessors

func get_seed()         -> int:        return _seed
func get_curator_id()   -> StringName: return _curator_id
func get_difficulty()   -> int:        return _difficulty
func get_mode()         -> RunMode:    return _mode
func get_deck()         -> Array:      return _deck
func get_relics()       -> Array:      return _relics
func get_map_graph()    -> Dictionary: return _map_graph
func get_current_node() -> StringName: return _current_node
func get_current_zone() -> int:        return _current_zone
func get_zone_count()   -> int:        return _zone_count
func get_gold()         -> int:        return _gold
func get_hp()           -> int:        return _hp
func get_max_hp()       -> int:        return _max_hp

# ================================================================ mutators

func set_current_node(node_id: StringName) -> void:
	assert(_active, "RunState.set_current_node: no active run")
	_current_node = node_id

func set_current_zone(zone: int) -> void:
	assert(_active, "RunState.set_current_zone: no active run")
	_current_zone = zone

func add_gold(amount: int) -> void:
	assert(_active, "RunState.add_gold: no active run")
	_gold += amount

func spend_gold(amount: int) -> bool:
	assert(_active, "RunState.spend_gold: no active run")
	if _gold < amount:
		return false
	_gold -= amount
	return true

func take_damage(amount: int) -> void:
	assert(_active, "RunState.take_damage: no active run")
	_hp = max(0, _hp - amount)

func heal(amount: int) -> void:
	assert(_active, "RunState.heal: no active run")
	_hp = min(_max_hp, _hp + amount)

func set_max_hp(value: int) -> void:
	assert(_active, "RunState.set_max_hp: no active run")
	_max_hp = value
	_hp = min(_hp, _max_hp)

func add_card(card: Resource) -> void:
	assert(_active, "RunState.add_card: no active run")
	_deck.append(card)

func remove_card(card: Resource) -> void:
	assert(_active, "RunState.remove_card: no active run")
	_deck.erase(card)

func add_relic(relic: Resource) -> void:
	assert(_active, "RunState.add_relic: no active run")
	_relics.append(relic)

func remove_relic(relic: Resource) -> void:
	assert(_active, "RunState.remove_relic: no active run")
	_relics.erase(relic)

# ================================================================== serialisation

## Export the current state to a serializable dictionary (save system).
func serialize() -> Dictionary:
	if not _active:
		return { "active": false }

	return {
		"active":       true,
		"seed":         _seed,
		"curator_id":   _curator_id,
		"difficulty":   _difficulty,
		"mode":         _mode,
		"deck":         _deck.duplicate(true),
		"relics":       _relics.duplicate(true),
		"map_graph":    _map_graph.duplicate(true),
		"current_node": _current_node,
		"current_zone": _current_zone,
		"zone_count":   _zone_count,
		"gold":         _gold,
		"hp":           _hp,
		"max_hp":       _max_hp,
	}


## Restore a previously saved run state (save system load path).
func deserialize(data: Dictionary) -> void:
	_clear()
	if not data.get("active", false):
		return

	_seed         = data["seed"]
	_curator_id   = data["curator_id"]
	_difficulty   = data["difficulty"]
	_mode         = data["mode"]
	_deck         = data["deck"].duplicate(true)
	_relics       = data["relics"].duplicate(true)
	_map_graph    = data["map_graph"].duplicate(true)
	_current_node = data["current_node"]
	_current_zone = data["current_zone"]
	_zone_count   = data["zone_count"]
	_gold         = data["gold"]
	_hp           = data["hp"]
	_max_hp       = data["max_hp"]
	_active       = true
	# Intentionally do NOT emit run_started on restore — the run was
	# already in progress; systems should just poll is_in_run().

# ================================================================== private

var _active:       bool       = false
var _seed:         int        = 0
var _curator_id:   StringName = &""
var _difficulty:   int        = 0
var _mode:         RunMode    = RunMode.STANDARD
var _deck:         Array      = []   # Array[CardData]
var _relics:       Array      = []   # Array[RelicData]
var _map_graph:    Dictionary = {}   # { nodes, edges, … }
var _current_node: StringName = &""
var _current_zone: int        = 0
var _zone_count:   int        = 0
var _gold:         int        = 0
var _hp:           int        = 20
var _max_hp:       int        = 20


func _clear() -> void:
	_active       = false
	_seed         = 0
	_curator_id   = &""
	_difficulty   = 0
	_mode         = RunMode.STANDARD
	_deck         = []
	_relics       = []
	_map_graph    = {}
	_current_node = &""
	_current_zone = 0
	_zone_count   = 0
	_gold         = 0
	_hp           = 20
	_max_hp       = 20


func _default_hp() -> int:
	return 20


func _outcome_name(outcome: RunOutcome) -> String:
	match outcome:
		RunOutcome.VICTORY:   return "victory"
		RunOutcome.DEATH:     return "death"
		RunOutcome.ABANDONED: return "abandoned"
	return "unknown"
