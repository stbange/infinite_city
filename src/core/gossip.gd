class_name Gossip
extends RefCounted
## What a resident tells about the people they know and the district's past (spec relations /
## Gossip): up to three lines, the same for the same person every time.

const SALT_GOSSIP := 141

var population: Population
var relations: Relations
var _templates: Dictionary = {}


func _init(p_population: Population, p_relations: Relations) -> void:
	population = p_population
	relations = p_relations
	_templates = DataTables.load_table("gossip").data["templates"]


func about(id: PersonId) -> PackedStringArray:
	var lines := PackedStringArray()
	var seed_value := DetHash.hash4(population.world_seed(), SALT_GOSSIP, id.district.x, id.district.y, id.district.z, id.local)
	var known := relations.relations_of(id)
	# A friend's secret lover.
	for r in known:
		if r.kind != "friend" or lines.size() >= 1:
			continue
		for fr in relations.relations_of(r.other):
			if fr.kind == "lover" and not fr.other.equals(id):
				lines.append(_fill("lover", {"friend": _name(r.other), "other": _name(fr.other)}, seed_value))
				break
	# A secret membership of someone they know.
	for r in known:
		if r.kind in ["friend", "neighbour", "colleague", "rival", "enemy"]:
			var other := population.person(r.other)
			if other != null and other.membership_secret:
				var faction := population.chronicle.faction(other.membership)
				if faction != null:
					lines.append(_fill("member", {"other": other.full_name(), "faction": faction.name}, seed_value + 1))
					break
	# Where a friend or relative works.
	if lines.size() < 3:
		for r in known:
			if r.kind in ["friend", "sibling", "relative_child", "relative_parent", "neighbour"]:
				var workplace := population.workplace_of(r.other)
				if workplace != null:
					lines.append(_fill("work", {"other": _name(r.other), "workplace": workplace.name}, seed_value + 2))
					break
	if lines.size() < 3:
		lines.append(_history_line(id, seed_value + 3))
	return lines.slice(0, 3)


func _history_line(id: PersonId, seed_value: int) -> String:
	var chronicle := population.chronicle
	var reach := chronicle.reach(CityChronicle.reach_of(id.district))
	for i in range(reach.events.size() - 1, -1, -1):
		var event := reach.events[i]
		if event.kind == "takeover" and event.has_district and event.district == id.district and event.actors.size() >= 2:
			var faction := chronicle.faction(event.actors[0])
			var owner := chronicle.faction(event.actors[1])
			if faction != null and owner != null:
				return _fill("history", {"faction": faction.name, "owner": owner.name, "place": "this district",
						"year": str(event.year)}, seed_value)
	var last := reach.events[-1] if not reach.events.is_empty() else null
	if last == null:
		return "Nothing much ever happens around here."
	return _fill("event", {"year": str(last.year), "text": last.text}, seed_value)


func _name(id: PersonId) -> String:
	var p := population.person(id)
	return p.full_name() if p != null else "someone"


func _fill(kind: String, values: Dictionary, seed_value: int) -> String:
	var text := TextTemplate.fill(String(_templates[kind]), values, seed_value)
	return text[0].to_upper() + text.substr(1)
