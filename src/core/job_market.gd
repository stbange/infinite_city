class_name JobMarket
extends RefCounted
## Who works where in one district (spec workplaces / Job market). Every non-housing unit is a
## workplace; a share of them is active (with its full staff), chosen so that the active slots
## cover 90% of the working-age adults, the rest stand vacant. Every adult then draws a workplace
## deterministically. Workplaces are kept in packed arrays; records are built on demand.

const SALT_MARKET := 135
const COVERAGE := 0.9
const NOT_LOOKING := 0.05
const WORK_AGE_MIN := 18
const WORK_AGE_MAX := 67
const DRAWS := 4

var district: Vector3i
var working_age: int = 0
var employed: int = 0
var total_slots: int = 0

## Weak, so a population caching this market does not form a reference cycle with it.
var _population_ref: WeakRef
var _origin: Vector3i
var _w_local := PackedInt32Array()     # packed unit id (slot 0)
var _w_kind := PackedInt32Array()
var _w_slots := PackedInt32Array()
var _index_of: Dictionary = {}         # unit local id -> workplace index
var _assigned: Dictionary = {}         # person local id -> workplace index
var _staff: Dictionary = {}            # workplace index -> PackedInt32Array of person local ids
var _records: Dictionary = {}          # workplace index -> WorkplaceInfo


func _init(population: Population, p_district: Vector3i) -> void:
	_population_ref = weakref(population)
	district = p_district
	var layout := population.layout
	_origin = layout.district_origin_cell(district)
	var adults := PackedInt32Array()
	var adult_hashes := PackedInt64Array()
	var raw := PackedFloat32Array()
	var activation := PackedFloat32Array()
	var wanted_by_kind: Dictionary = {}
	var skill_index := {}
	for i in population.skills.size():
		skill_index[population.skills[i]] = i
	var culture := population.culture_of(district)
	for i in 512:
		var local_cell := Vector3i(i / 64, (i / 8) % 8, i % 8)
		var block := layout.block_at(_origin + local_cell)
		if block == null:
			continue
		var plan := population.plan_of(block)
		if block.kind == BlockTypes.Kind.HOUSING:
			for k in plan.floors:
				for unit in plan.units:
					if unit.is_core:
						continue
					var house := population.household_in(block, plan, k, unit.index, culture)
					for slot in house.ages.size():
						var age := house.ages[slot]
						if age >= WORK_AGE_MIN and age <= WORK_AGE_MAX:
							var local := PersonId.pack(local_cell, k, unit.index, slot)
							adults.append(local)
							adult_hashes.append(population.work_hash_local(district, local))
			continue
		var spec := population.work_kind(block.kind)
		var per_worker := float(spec.get("m2_per_worker", 20.0))
		if not wanted_by_kind.has(block.kind):
			var wanted := PackedInt32Array()
			for s: String in spec.get("skills", []):
				wanted.append(skill_index.get(s, -1))
			wanted_by_kind[block.kind] = wanted
		var block_rng := CellRandom.new(DetHash.hash_cell(population.world_seed(), SALT_MARKET, block.cell))
		for k in plan.floors:
			for unit in plan.units:
				if unit.is_core:
					continue
				activation.append(block_rng.next_float())
				var local := PersonId.pack(local_cell, k, unit.index, 0)
				_index_of[local] = _w_local.size()
				_w_local.append(local)
				_w_kind.append(block.kind)
				raw.append(maxf(1.0, roundf(unit.rect.get_area() / per_worker)))
	working_age = adults.size()
	_assign_slots(raw, activation)
	_assign_jobs(adults, adult_hashes, wanted_by_kind)


func _assign_slots(raw: PackedFloat32Array, activation: PackedFloat32Array) -> void:
	var total_raw := 0.0
	for r in raw:
		total_raw += r
	var active := minf(1.0, COVERAGE * working_age / total_raw) if total_raw > 0.0 else 0.0
	var target := int(COVERAGE * working_age)
	_w_slots.resize(raw.size())
	for i in raw.size():
		var slots := int(raw[i]) if activation[i] < active else 0
		if total_slots + slots > target:
			slots = maxi(0, target - total_slots)
		_w_slots[i] = slots
		total_slots += slots


func _assign_jobs(adults: PackedInt32Array, adult_hashes: PackedInt64Array, wanted_by_kind: Dictionary) -> void:
	var active := PackedInt32Array()
	var cumulative := PackedFloat32Array()
	var free := PackedInt32Array()
	var total := 0.0
	for i in _w_slots.size():
		if _w_slots[i] > 0:
			active.append(i)
			total += _w_slots[i]
			cumulative.append(total)
			free.append(_w_slots[i])
	if active.is_empty():
		return
	var count := active.size()
	var skill_count := _pop().skills.size()
	var cursor := 0   # first workplace that may still have a free slot (only moves forward)
	for a in adults.size():
		var h := adult_hashes[a]
		var skill := h % skill_count
		var rng := CellRandom.new(h)
		if rng.next_float() < NOT_LOOKING:
			continue
		var chosen := -1
		for attempt in DRAWS:
			var j := mini(cumulative.bsearch(rng.next_float() * total, false), count - 1)
			if free[j] <= 0:
				continue
			var wanted: PackedInt32Array = wanted_by_kind[_w_kind[active[j]]]
			if wanted.has(skill) or rng.next_float() < 0.4:
				chosen = j
				break
		if chosen < 0:
			while cursor < count and free[cursor] <= 0:
				cursor += 1
			if cursor < count:
				chosen = cursor
		if chosen < 0:
			continue
		free[chosen] -= 1
		var index := active[chosen]
		_assigned[adults[a]] = index
		var staff: PackedInt32Array = _staff.get(index, PackedInt32Array())
		staff.append(adults[a])
		_staff[index] = staff
		employed += 1


func attach(population: Population) -> void:
	_population_ref = weakref(population)


func _pop() -> Population:
	return _population_ref.get_ref() as Population


func workplace_count() -> int:
	return _w_local.size()


## Packed unit id (slot 0) of the workplace at an index.
func local_of(index: int) -> int:
	return _w_local[index]


func slots_of(index: int) -> int:
	return _w_slots[index]


## The workplace record at an index (built on first use).
func workplace(index: int) -> WorkplaceInfo:
	if _records.has(index):
		return _records[index]
	var id := PersonId.new(district, _w_local[index])
	var population := _pop()
	var layout := population.layout
	var block := layout.block_at(id.cell(layout))
	var w := population.make_workplace(block, population.plan_of(block), id.floor_index(), id.unit_index())
	w.slots = _w_slots[index]
	_records[index] = w
	return w


## Indices of the workplaces with at least one slot.
func active_indices() -> PackedInt32Array:
	var result := PackedInt32Array()
	for i in _w_slots.size():
		if _w_slots[i] > 0:
			result.append(i)
	return result


## The workplace record of a unit in this district, or null.
func workplace_at(unit_id: PersonId) -> WorkplaceInfo:
	if unit_id.district != district:
		return null
	var local := unit_id.local & ~7
	var index: int = _index_of.get(local, -1)
	return workplace(index) if index >= 0 else null


func workplace_of(id: PersonId) -> WorkplaceInfo:
	if id.district != district or not _assigned.has(id.local):
		return null
	return workplace(_assigned[id.local])


func staff_of(w: WorkplaceInfo) -> Array[PersonId]:
	var result: Array[PersonId] = []
	if w == null or w.id.district != district:
		return result
	var index: int = _index_of.get(w.id.local, -1)
	if index < 0 or not _staff.has(index):
		return result
	for local in (_staff[index] as PackedInt32Array):
		result.append(PersonId.new(district, local))
	return result


func employees() -> Array[PersonId]:
	var result: Array[PersonId] = []
	for local: int in _assigned:
		result.append(PersonId.new(district, local))
	return result
