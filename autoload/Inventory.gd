extends Node
## Inventory — Meta progress tracker for unlocked cards, relics, and curators.
##
## DESIGN.md §7.4, §10.2, §10.4
## Singleton autoload. No run-scoped state here — this is permanent meta progression.

signal card_unlocked(card_id: String)
signal relic_unlocked(relic_id: String)
signal curator_unlocked(curator_id: String)

var cards_unlocked: Array[String] = []
var meta_relics_unlocked: Array[String] = []
var curators_unlocked: Array[String] = []


func add_card(card_id: String) -> void:
	if not has_card(card_id):
		cards_unlocked.append(card_id)
		card_unlocked.emit(card_id)


func has_card(card_id: String) -> bool:
	return card_id in cards_unlocked


func add_relic(relic_id: String) -> void:
	if not has_relic(relic_id):
		meta_relics_unlocked.append(relic_id)
		relic_unlocked.emit(relic_id)


func has_relic(relic_id: String) -> bool:
	return relic_id in meta_relics_unlocked


func add_curator(curator_id: String) -> void:
	if not has_curator(curator_id):
		curators_unlocked.append(curator_id)
		curator_unlocked.emit(curator_id)


func has_curator(curator_id: String) -> bool:
	return curator_id in curators_unlocked


## open_reliquaire stub — full implementation deferred to CRSD-054 / Inventory.open_reliquaire.
## DESIGN.md §7.5 defines reliquaire tiers, costs, guarantees, and RNG.
func open_reliquaire(_reliquaire_id: String) -> String:
	push_warning("Inventory.open_reliquaire is a stub — implement per CRSD-054 / DESIGN.md §7.5")
	return ""


## Serialization for SaveSystem (DESIGN.md §10.4).
func to_dict() -> Dictionary:
	return {
		"cards_unlocked": cards_unlocked.duplicate(),
		"meta_relics_unlocked": meta_relics_unlocked.duplicate(),
		"curators_unlocked": curators_unlocked.duplicate(),
	}


func from_dict(data: Dictionary) -> void:
	cards_unlocked.clear()
	for cid in data.get("cards_unlocked", []):
		cards_unlocked.append(cid)

	meta_relics_unlocked.clear()
	for rid in data.get("meta_relics_unlocked", []):
		meta_relics_unlocked.append(rid)

	curators_unlocked.clear()
	for cid in data.get("curators_unlocked", []):
		curators_unlocked.append(cid)
