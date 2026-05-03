extends Node
## MuseumState — autoload singleton
##
## Manages the museum: tier progression, slot grid, and thematic rooms.
## Source: DESIGN.md §8 (Museum & Idle)

# -- Aspect enum (DESIGN.md §6.6, §8.5) ----------------------------------------
# Order matters for matchup graph: Chaos > Sigma > Galaxy Brain > Cursed > Void > Chaos
enum Aspect { CHAOS, SIGMA, GALAXY_BRAIN, CURSED, VOID }


# -- Tier definitions (DESIGN.md §8.2) -----------------------------------------
class TierDef:
	var name: String
	var max_slots: int
	var cost_essence: int
	var cost_fame: int
	var level_required: int
	var prestige_required: int

	func _init(p_name: String, p_slots: int, p_essence: int, p_fame: int, p_level: int, p_prestige: int) -> void:
		name = p_name
		max_slots = p_slots
		cost_essence = p_essence
		cost_fame = p_fame
		level_required = p_level
		prestige_required = p_prestige

const TIER_DEFS: Dictionary = {
	1: TierDef.new("Starter Hall", 4, 0, 0, 1, 0),
	2: TierDef.new("Curator's Office", 8, 1500, 0, 3, 0),
	3: TierDef.new("Gallery", 16, 15000, 0, 10, 0),
	4: TierDef.new("Forbidden Wing", 32, 150000, 10, 20, 0),
	5: TierDef.new("Cursed Vault", 64, 1500000, 50, 35, 0),
	6: TierDef.new("Eternal Archive", 128, 15000000, 200, 50, 1),
}


# -- Room constants (DESIGN.md §8.5) -------------------------------------------
const SLOTS_PER_ROOM_MIN: int = 4
const SLOTS_PER_ROOM_MAX: int = 8
const ROOM_THEME_CHANGE_COST: int = 1000

# -- Adjacency constants (DESIGN.md §8.4) --------------------------------------
const ADJACENCY_BONUS_PER_NEIGHBOR: float = 0.10
const ADJACENCY_MAX_MULTIPLIER: float = 1.4


# -- Slot data -----------------------------------------------------------------
class SlotData:
	var slot_id: int
	var tier: int                   # which tier this slot belongs to (1..6)
	var grid_x: int                 # horizontal position in the museum grid
	var grid_y: int                 # vertical position in the museum grid
	var placed_card_id: StringName  # card id placed here, empty if vacant
	var room_id: int                # room this slot belongs to (-1 for tiers 1-2)

	func _init(p_id: int, p_tier: int, p_x: int, p_y: int, p_room_id: int = -1) -> void:
		slot_id = p_id
		tier = p_tier
		grid_x = p_x
		grid_y = p_y
		placed_card_id = &""
		room_id = p_room_id

	func is_empty() -> bool:
		return placed_card_id == &""

	func clear() -> void:
		placed_card_id = &""


# -- Room data (DESIGN.md §8.5) ------------------------------------------------
class RoomData:
	var room_id: int
	var name: String
	var slot_ids: Array[int]        # slots belonging to this room
	var assigned_aspect: int        # Aspect enum value, -1 = unassigned

	func _init(p_id: int, p_name: String, p_slot_ids: Array[int] = []) -> void:
		room_id = p_id
		name = p_name
		slot_ids = p_slot_ids.duplicate()
		assigned_aspect = -1

	func is_sync_assigned() -> bool:
		return assigned_aspect >= 0


# =============================================================================
# State
# =============================================================================

var current_tier: int = 1          # highest unlocked tier
var unlocked_tiers: Array[int] = [1]
var slots: Dictionary = {}         # int -> SlotData
var rooms: Dictionary = {}         # int -> RoomData
var _next_slot_id: int = 1
var _next_room_id: int = 1

# -- Signals -------------------------------------------------------------------
signal tier_unlocked(tier: int)
signal card_placed(slot_id: int, card_id: StringName)
signal card_removed(slot_id: int)
signal room_theme_changed(room_id: int, new_aspect: int)


# =============================================================================
# Lifetime
# =============================================================================

func _ready() -> void:
	_initialize_tier(1)


# =============================================================================
# Tier management (DESIGN.md §8.2)
# =============================================================================

## Returns the TierDef for [param tier] or null.
func get_tier_def(tier: int) -> TierDef:
	return TIER_DEFS.get(tier, null)


## Returns the total number of unlocked slots across all unlocked tiers.
func total_unlocked_slots() -> int:
	var count: int = 0
	for tier: int in unlocked_tiers:
		var defn: TierDef = TIER_DEFS.get(tier, null)
		if defn:
			count += defn.max_slots
	return count


## Returns the number of unlocked slots that are currently empty.
func empty_slot_count() -> int:
	var count: int = 0
	for slot: SlotData in slots.values():
		if slot.is_empty() and slot.tier in unlocked_tiers:
			count += 1
	return count


## Returns the first empty slot id, or -1 if none available.
func find_empty_slot() -> int:
	for slot: SlotData in slots.values():
		if slot.is_empty() and slot.tier in unlocked_tiers:
			return slot.slot_id
	return -1


## Returns true if all prerequisites for [param tier] are met.
func can_unlock_tier(tier: int, player_level: int, player_essence: int, player_fame: int, player_prestige: int) -> bool:
	if tier <= current_tier:
		return false
	if tier - 1 != current_tier:  # tiers must be unlocked sequentially
		return false
	var defn: TierDef = TIER_DEFS.get(tier, null)
	if not defn:
		return false
	return (player_level >= defn.level_required
		and player_essence >= defn.cost_essence
		and player_fame >= defn.cost_fame
		and player_prestige >= defn.prestige_required)


## Unlocks [param tier] and creates its slots and rooms (Tier 3+).
## Returns true on success, false if prerequisites are not met.
func unlock_tier(tier: int, player_level: int, player_essence: int, player_fame: int, player_prestige: int) -> bool:
	if not can_unlock_tier(tier, player_level, player_essence, player_fame, player_prestige):
		return false
	unlocked_tiers.append(tier)
	current_tier = tier
	_initialize_tier(tier)
	tier_unlocked.emit(tier)
	return true


## Returns the cost of a tier unlock as {essence: int, fame: int}.
func tier_unlock_cost(tier: int) -> Dictionary:
	var defn: TierDef = TIER_DEFS.get(tier, null)
	if not defn:
		return {"essence": 0, "fame": 0}
	return {"essence": defn.cost_essence, "fame": defn.cost_fame}


# =============================================================================
# Slot management
# =============================================================================

## Gets SlotData for [param slot_id], or null.
func get_slot(slot_id: int) -> SlotData:
	return slots.get(slot_id, null)


## Places [param card_id] into [param slot_id]. Emits card_placed.
## Returns true on success.
func place_card(slot_id: int, card_id: StringName) -> bool:
	var slot: SlotData = slots.get(slot_id, null)
	if not slot or not slot.is_empty():
		return false
	if slot.tier not in unlocked_tiers:
		return false
	slot.placed_card_id = card_id
	card_placed.emit(slot_id, card_id)
	return true


## Removes the card from [param slot_id]. Emits card_removed.
## Returns the removed card_id, or empty string if slot was empty.
func remove_card(slot_id: int) -> StringName:
	var slot: SlotData = slots.get(slot_id, null)
	if not slot:
		return &""
	var card_id: StringName = slot.placed_card_id
	slot.clear()
	if card_id != &"":
		card_removed.emit(slot_id)
	return card_id


## Returns all slot ids for a given tier.
func get_slots_for_tier(tier: int) -> Array[int]:
	var result: Array[int] = []
	for slot: SlotData in slots.values():
		if slot.tier == tier:
			result.append(slot.slot_id)
	return result


## Returns all slot ids for a given room.
func get_slots_for_room(room_id: int) -> Array[int]:
	var room: RoomData = rooms.get(room_id, null)
	if not room:
		return []
	return room.slot_ids.duplicate()


## Returns the set of card aspects present across all placed cards,
## keyed by Aspect enum value → unique card count.
func count_aspect_set() -> Dictionary:
	var counts: Dictionary = {}
	for slot: SlotData in slots.values():
		if slot.is_empty():
			continue
		# The actual aspect lookup requires CardData; callers must pass it.
		# MuseumState stores only card_id, not aspect — aspect lookups are done by Economy.
		# We provide the raw slot data so Economy can compute set bonuses.
		pass
	return counts


## Returns all non-empty slots (for income computation).
func populated_slots() -> Array[SlotData]:
	var result: Array[SlotData] = []
	for slot: SlotData in slots.values():
		if not slot.is_empty():
			result.append(slot)
	return result


# =============================================================================
# Room management (DESIGN.md §8.5)
# =============================================================================

## Gets RoomData for [param room_id] or null.
func get_room(room_id: int) -> RoomData:
	return rooms.get(room_id, null)


## Assigns [param aspect] to [param room_id]. Emits room_theme_changed.
## Returns true on success.
func set_room_theme(room_id: int, aspect: int) -> bool:
	var room: RoomData = rooms.get(room_id, null)
	if not room:
		return false
	room.assigned_aspect = aspect
	room_theme_changed.emit(room_id, aspect)
	return true


## Returns all room ids for a given tier (empty for tiers 1-2).
func get_rooms_for_tier(tier: int) -> Array[int]:
	var result: Array[int] = []
	for room: RoomData in rooms.values():
		for sid: int in room.slot_ids:
			var slot: SlotData = slots.get(sid, null)
			if slot and slot.tier == tier:
				result.append(room.room_id)
				break
	return result


# =============================================================================
# Adjacency helpers (DESIGN.md §8.4)
# =============================================================================

## Returns the slot ids of horizontal/vertical neighbours of [param slot_id].
func get_adjacent_slots(slot_id: int) -> Array[int]:
	var slot: SlotData = slots.get(slot_id, null)
	if not slot:
		return []
	var result: Array[int] = []
	var directions: Array = [[0, -1], [0, 1], [-1, 0], [1, 0]]
	for dir in directions:
		for other: SlotData in slots.values():
			if other.slot_id == slot_id:
				continue
			if other.grid_x == slot.grid_x + dir[0] and other.grid_y == slot.grid_y + dir[1]:
				result.append(other.slot_id)
	return result


# =============================================================================
# Serialization (for SaveSystem)
# =============================================================================

## Serializes full museum state to a Dictionary for persistence.
func serialize() -> Dictionary:
	var slot_dicts: Array[Dictionary] = []
	for slot: SlotData in slots.values():
		slot_dicts.append({
			"slot_id": slot.slot_id,
			"tier": slot.tier,
			"grid_x": slot.grid_x,
			"grid_y": slot.grid_y,
			"placed_card_id": slot.placed_card_id,
			"room_id": slot.room_id,
		})

	var room_dicts: Array[Dictionary] = []
	for room: RoomData in rooms.values():
		room_dicts.append({
			"room_id": room.room_id,
			"name": room.name,
			"slot_ids": room.slot_ids,
			"assigned_aspect": room.assigned_aspect,
		})

	return {
		"current_tier": current_tier,
		"unlocked_tiers": unlocked_tiers.duplicate(),
		"slots": slot_dicts,
		"rooms": room_dicts,
		"next_slot_id": _next_slot_id,
		"next_room_id": _next_room_id,
	}


## Deserializes from a Dictionary produced by [method serialize].
func deserialize(data: Dictionary) -> void:
	current_tier = data.get("current_tier", 1)
	unlocked_tiers = (data.get("unlocked_tiers", [1]) as Array).duplicate()
	_next_slot_id = data.get("next_slot_id", 1)
	_next_room_id = data.get("next_room_id", 1)

	slots.clear()
	for sd in (data.get("slots", []) as Array):
		var s: SlotData = SlotData.new(sd["slot_id"], sd["tier"], sd["grid_x"], sd["grid_y"], sd.get("room_id", -1))
		s.placed_card_id = sd.get("placed_card_id", &"")
		slots[s.slot_id] = s

	rooms.clear()
	for rd in (data.get("rooms", []) as Array):
		var r: RoomData = RoomData.new(rd["room_id"], rd["name"], rd.get("slot_ids", []))
		r.assigned_aspect = rd.get("assigned_aspect", -1)
		rooms[r.room_id] = r


# =============================================================================
# Internal helpers
# =============================================================================

func _initialize_tier(tier: int) -> void:
	var defn: TierDef = TIER_DEFS.get(tier, null)
	if not defn:
		return
	var start_x: int = 0
	if tier > 1:
		var prev: TierDef = TIER_DEFS.get(tier - 1)
		if prev:
			start_x = prev.max_slots

	for i: int in range(defn.max_slots):
		var sid: int = _next_slot_id
		_next_slot_id += 1
		slots[sid] = SlotData.new(sid, tier, start_x + i, 0, -1)

	if tier >= 3:
		_create_rooms_for_tier(tier)


func _create_rooms_for_tier(tier: int) -> void:
	var tier_slots: Array[int] = get_slots_for_tier(tier)
	var slot_count: int = tier_slots.size()
	if slot_count == 0:
		return

	# Split slots into rooms of 4-8 each, balancing as evenly as possible.
	var room_capacity: int = clampi(ceilf(float(slot_count) / ceilf(float(slot_count) / SLOTS_PER_ROOM_MAX)), SLOTS_PER_ROOM_MIN, SLOTS_PER_ROOM_MAX)
	var idx: int = 0

	while idx < slot_count:
		var batch: Array[int] = []
		for j: int in range(mini(room_capacity, slot_count - idx)):
			batch.append(tier_slots[idx + j])

		var rid: int = _next_room_id
		_next_room_id += 1
		var room_name: String = TIER_DEFS[tier].name + " Room " + str(rooms.size() + 1)
		var room: RoomData = RoomData.new(rid, room_name, batch)
		rooms[rid] = room

		for sid: int in batch:
			var slot: SlotData = slots.get(sid)
			if slot:
				slot.room_id = rid

		idx += batch.size()
