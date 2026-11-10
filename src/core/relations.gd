class_name Relations
extends RefCounted
## The social graph (spec relations), never stored: family from households and family lines,
## neighbours, colleagues, and friends, lovers, rivals and enemies decided per pair within social
## circles (the floor, the block, the workplace), so every relation is mutual.

const SALT_PAIR := 140
const MAX_COLLEAGUES := 12
const ELDER_AGE := 68
## Expected friends per circle (k), lovers and rivals per person.
const FRIENDS_FLOOR := 1.2
const FRIENDS_BLOCK := 2.0
const FRIENDS_WORK := 1.2
const LOVERS_BLOCK := 0.075
## Chance that two block-mates of feuding factions are enemies.
const ENEMY_CHANCE := 0.15
## History events that make two factions' members enemies.
const HOSTILE_EVENTS: Array[String] = ["feud", "border_feud", "takeover", "strike", "split", "buyout"]
const RIVALS_WORK := 0.25
const CIRCLE_FLOOR := 1
const CIRCLE_BLOCK := 2
const CIRCLE_WORK := 3

var population: Population
var _feuds: Dictionary = {}   # Reach -> Dictionary("a|b" -> true)


func _init(p_population: Population) -> void:
	population = p_population


func relations_of(id: PersonId) -> Array[Relation]:
	var result: Array[Relation] = []
	var layout := population.layout
	var block := layout.block_at(id.cell(layout))
	if block == null or block.kind != BlockTypes.Kind.HOUSING:
		return result
	var people := population.block_people(block)
	var me := people.index_of(id)
	if me < 0:
		return result
	var seen := {}   # other local id -> true for circle relations (one per kind group)
	_household(people, me, result)
	_relatives(people, me, result)
	if people.ages[me] < 18:
		return result
	_neighbours(people, me, result)
	var staff := _colleagues(id, result)
	_circles(people, me, staff, result, seen)
	return result


# --- Family --------------------------------------------------------------------------------

func _household_members(people: BlockPeople, me: int) -> Array[int]:
	var members: Array[int] = []
	for i in people.size():
		if people.floors[i] == people.floors[me] and people.units[i] == people.units[me]:
			members.append(i)
	return members


## Partners: the two oldest adults (an elder of a family household excluded).
func _partners_and_parents(people: BlockPeople, members: Array[int]) -> Array[int]:
	var type := people.types[members[0]]
	var adults: Array[int] = []
	for i in members:
		if people.ages[i] >= 18 and not (type == "family" and people.ages[i] >= ELDER_AGE):
			adults.append(i)
	adults.sort_custom(func(a: int, b: int) -> bool:
		return people.ages[a] > people.ages[b] or (people.ages[a] == people.ages[b] and people.slots[a] < people.slots[b]))
	return adults


func _household(people: BlockPeople, me: int, result: Array[Relation]) -> void:
	var members := _household_members(people, me)
	var type := people.types[me]
	if type == "flatmates":
		for i in members:
			if i != me:
				result.append(Relation.new("flatmate", people.ids[i]))
		return
	if type != "couple" and type != "family":
		return
	var adults := _partners_and_parents(people, members)
	var partners: Array[int] = adults.slice(0, 2)
	if partners.size() == 2 and partners.has(me):
		result.append(Relation.new("partner", people.ids[partners[1] if partners[0] == me else partners[0]]))
	for i in members:
		if i == me:
			continue
		var my_age := people.ages[me]
		var their_age := people.ages[i]
		if their_age < 18 and adults.has(me):
			result.append(Relation.new("child", people.ids[i]))
		elif my_age < 18 and adults.has(i):
			result.append(Relation.new("parent", people.ids[i]))
		elif type == "family" and their_age >= ELDER_AGE and not adults.has(i) and adults.size() > 0 and adults[0] == me:
			result.append(Relation.new("parent", people.ids[i]))
		elif type == "family" and my_age >= ELDER_AGE and not adults.has(me) and adults.size() > 0 and adults[0] == i:
			result.append(Relation.new("child", people.ids[i]))


## Heads of households in the block that share the family line.
func _relatives(people: BlockPeople, me: int, result: Array[Relation]) -> void:
	var line := people.lines[me]
	if line < 0:
		return
	var my_members := _household_members(people, me)
	var my_adults := _partners_and_parents(people, my_members)
	if my_adults.is_empty() or my_adults[0] != me:
		return
	var heads := {}
	for i in people.size():
		if people.lines[i] != line or (people.floors[i] == people.floors[me] and people.units[i] == people.units[me]):
			continue
		var flat := people.floors[i] * 128 + people.units[i]
		if heads.has(flat):
			continue
		var adults := _partners_and_parents(people, _household_members(people, i))
		if adults.is_empty():
			continue
		var head: int = adults[0]
		heads[flat] = true
		var difference := people.ages[head] - people.ages[me]
		if difference >= 18:
			result.append(Relation.new("relative_parent", people.ids[head]))
		elif difference <= -18:
			result.append(Relation.new("relative_child", people.ids[head]))
		else:
			result.append(Relation.new("sibling", people.ids[head]))


# --- Neighbours and colleagues -------------------------------------------------------------

func _neighbours(people: BlockPeople, me: int, result: Array[Relation]) -> void:
	for i in people.size():
		if people.floors[i] != people.floors[me] or people.ages[i] < 18:
			continue
		if absi(people.units[i] - people.units[me]) == 1:
			result.append(Relation.new("neighbour", people.ids[i]))


## Adds colleagues and returns the whole staff of the person's workplace (for the work circle).
func _colleagues(id: PersonId, result: Array[Relation]) -> Array[PersonId]:
	var workplace := population.workplace_of(id)
	if workplace == null:
		return []
	var market := population.job_market(id.district)
	var staff := market.staff_of(market.workplace_at(workplace.id))
	var others := staff.size() - 1
	for other in staff:
		if other.equals(id):
			continue
		if others <= MAX_COLLEAGUES or _pair_u(CIRCLE_WORK + 10, workplace.id.local, id.local, other.local, 0) < float(MAX_COLLEAGUES) / others:
			result.append(Relation.new("colleague", other))
	return staff


# --- Circles -------------------------------------------------------------------------------

func _circles(people: BlockPeople, me: int, staff: Array[PersonId], result: Array[Relation], seen: Dictionary) -> void:
	var id := people.ids[me]
	var my_faction := people.memberships[me]
	var block_cell := id.local >> 15
	var floor_n := 0
	var block_n := 0
	for i in people.size():
		if people.ages[i] >= 18:
			block_n += 1
			if people.floors[i] == people.floors[me]:
				floor_n += 1
	var household := people.floors[me] * 128 + people.units[me]
	for i in people.size():
		if i == me or people.ages[i] < 18:
			continue
		var other := people.ids[i]
		var same_household := people.floors[i] * 128 + people.units[i] == household
		var h := _pair_hash(CIRCLE_BLOCK, block_cell, id.local, other.local)
		var u_friend := float(h & 0xffff) / 65536.0
		var u_lover := float((h >> 16) & 0xffff) / 65536.0
		var friend := not same_household and u_friend < FRIENDS_BLOCK / block_n
		if people.floors[i] == people.floors[me] and not same_household:
			var hf := _pair_hash(CIRCLE_FLOOR, block_cell * 32 + people.floors[me], id.local, other.local)
			friend = friend or float(hf & 0xffff) / 65536.0 < FRIENDS_FLOOR / floor_n
		if not my_faction.is_empty() and not people.memberships[i].is_empty() \
				and factions_feuded(my_faction, people.memberships[i]):
			var he := _pair_hash(CIRCLE_BLOCK + 20, block_cell, id.local, other.local)
			if float(he & 0xffff) / 65536.0 < ENEMY_CHANCE:
				result.append(Relation.new("enemy", other))
		if friend:
			result.append(Relation.new("friend", other))
			seen[other.local] = true
		if not same_household and u_lover < LOVERS_BLOCK / block_n:
			result.append(Relation.new("lover", other, true))
	var work_n := staff.size()
	if work_n < 2:
		return
	var workplace_local := population.workplace_of(id).id.local
	for other in staff:
		if other.equals(id):
			continue
		var h := _pair_hash(CIRCLE_WORK, workplace_local, id.local, other.local)
		if not seen.has(other.local) and float(h & 0xffff) / 65536.0 < FRIENDS_WORK / work_n:
			result.append(Relation.new("friend", other))
			seen[other.local] = true
		if float((h >> 16) & 0xffff) / 65536.0 < RIVALS_WORK / work_n:
			result.append(Relation.new("rival", other))


## True when two factions have a hostile event (feud, takeover, strike, split, buyout) in the
## history of the first one's Reach.
func factions_feuded(a: String, b: String) -> bool:
	if a == b or not a.begins_with("R"):
		return false
	var reach := CityChronicle.reach_of_key(a)
	if not _feuds.has(reach):
		var pairs := {}
		for event in population.chronicle.reach(reach).events:
			if event.kind in HOSTILE_EVENTS and event.actors.size() >= 2:
				pairs["%s|%s" % [event.actors[0], event.actors[1]]] = true
				pairs["%s|%s" % [event.actors[1], event.actors[0]]] = true
		_feuds[reach] = pairs
	return (_feuds[reach] as Dictionary).has("%s|%s" % [a, b])


func _pair_hash(circle: int, circle_id: int, a: int, b: int) -> int:
	return DetHash.hash4(population.world_seed(), SALT_PAIR + circle, circle_id, mini(a, b), maxi(a, b), 0)


func _pair_u(circle: int, circle_id: int, a: int, b: int, part: int) -> float:
	return DetHash.u01(DetHash.hash4(population.world_seed(), SALT_PAIR + circle, circle_id, mini(a, b), maxi(a, b), part))
