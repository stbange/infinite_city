class_name TraceLayout
extends RefCounted
## How the history shows in the city (spec faction-traces): gang tags at turf edges, memorials in
## damaged districts, ruined blocks.

const SALT_TAGS := 120
const SALT_MEMORIAL := 121
const SALT_RUIN := 122
const RUIN_SHARE := 0.25
const MEMORIAL_COLOR := Color(0.92, 0.95, 1.0)
const ATTEMPTS := 24

var chronicle: CityChronicle
var layout: CityLayout
var _damaged: Dictionary = {}   # Reach -> Dictionary(district -> true)


func _init(p_chronicle: CityChronicle, p_layout: CityLayout) -> void:
	chronicle = p_chronicle
	layout = p_layout


## True when a raid or blackout struck the district.
func is_damaged(district: Vector3i) -> bool:
	var reach := CityChronicle.reach_of(district)
	if not _damaged.has(reach):
		var set := {}
		for event in chronicle.reach(reach).events:
			if event.has_district and (event.kind == "raid" or event.kind == "blackout"):
				set[event.district] = true
		_damaged[reach] = set
	return (_damaged[reach] as Dictionary).has(district)


func memorial_cell(district: Vector3i) -> Vector3i:
	var size := layout.config.district_size
	var h := DetHash.hash3(layout.config.world_seed, SALT_MEMORIAL, district.x, district.y, district.z)
	return layout.district_origin_cell(district) + Vector3i(h % size, (h / size) % size, (h / (size * size)) % size)


func is_ruined(cell: Vector3i) -> bool:
	if not is_damaged(layout.district_of(cell)):
		return false
	return DetHash.u01(DetHash.hash_cell(layout.config.world_seed, SALT_RUIN, cell)) < RUIN_SHARE


## The gang whose turf edge the block lies on, or null.
func edge_gang(block: BlockInfo) -> FactionInfo:
	var district := layout.district_of(block.cell)
	var owner := chronicle.faction(chronicle.owner_of_district(district))
	if owner == null or owner.type != "gang":
		return null
	var size := layout.config.district_size
	var local := layout.local_in_district(block.cell)
	for axis in 3:
		for direction: int in [-1, 1]:
			if local[axis] != (0 if direction < 0 else size - 1):
				continue
			var step := Vector3i.ZERO
			step[axis] = direction
			if chronicle.owner_of_district(district + step) != owner.key:
				return owner
	return null


## All traces of a block: tags and memorials.
func traces_of(block: BlockInfo, doorway: DoorwayInfo, existing: Array[SignInfo]) -> Array[SignInfo]:
	var placed: Array[SignInfo] = existing.duplicate()
	var result := tags_of(block, doorway, placed)
	placed.append_array(result)
	result.append_array(memorials_of(block, doorway, placed))
	return result


func tags_of(block: BlockInfo, doorway: DoorwayInfo, existing: Array[SignInfo]) -> Array[SignInfo]:
	var result: Array[SignInfo] = []
	var gang := edge_gang(block)
	if gang == null:
		return result
	var rng := CellRandom.new(DetHash.hash_cell(layout.config.world_seed, SALT_TAGS, block.cell))
	var wanted := 1 + rng.next_int(3)
	var placed: Array[SignInfo] = existing.duplicate()
	for i in wanted:
		for attempt in ATTEMPTS:
			var size := Vector2(rng.range_float(1.2, 2.4), rng.range_float(0.6, 1.4))
			var sign := _place(block, size, rng.range_float(1.5, 12.0), FactionPalette.display(gang.color), rng)
			if sign != null and CityLighting.fits(sign, doorway, placed):
				result.append(sign)
				placed.append(sign)
				break
	return result


func memorials_of(block: BlockInfo, doorway: DoorwayInfo, existing: Array[SignInfo]) -> Array[SignInfo]:
	var result: Array[SignInfo] = []
	var district := layout.district_of(block.cell)
	if block.cell != memorial_cell(district) or not is_damaged(district):
		return result
	var rng := CellRandom.new(DetHash.hash_cell(layout.config.world_seed, SALT_MEMORIAL, block.cell))
	for attempt in ATTEMPTS * 2:
		var sign := _place(block, Vector2(6.0, 2.5), rng.range_float(1.5, 8.0), MEMORIAL_COLOR, rng)
		if sign != null and CityLighting.fits(sign, doorway, existing):
			sign.flicker = false
			result.append(sign)
			return result
	# Every damaged district's memorial block gets its memorial: smaller, wherever it fits.
	for attempt in ATTEMPTS * 2:
		var fallback := _place(block, Vector2(3.0, 1.5), rng.range_float(0.5, 20.0), MEMORIAL_COLOR, rng)
		if fallback != null:
			fallback.flicker = false
			result.append(fallback)
			return result
	return result


## A sign of `size` on a random side face, `height` metres above the block's bottom, clear of
## the bridge band around the cell centre line.
func _place(block: BlockInfo, size: Vector2, height: float, color: Color, rng: CellRandom) -> SignInfo:
	var face := rng.next_int(4)
	var axis := Vector3.AXIS_X if face < 2 else Vector3.AXIS_Z
	var face_sign := 1 if face % 2 == 0 else -1
	var lat := CityLighting.lateral_axis(axis)
	var right := rng.next_int(2) == 1
	var lo: float
	var hi: float
	if right:
		lo = CityLighting.BAND + size.x * 0.5
		hi = block.max_local()[lat] - CityLighting.MARGIN - size.x * 0.5
	else:
		lo = block.min_local()[lat] + CityLighting.MARGIN + size.x * 0.5
		hi = -CityLighting.BAND - size.x * 0.5
	if hi < lo:
		return null
	var centre := Vector3()
	centre[axis] = (block.max_local()[axis] if face_sign > 0 else block.min_local()[axis]) + face_sign * CityLighting.OFFSET
	centre[lat] = rng.range_float(lo, hi)
	centre.y = minf(block.min_local().y + height + size.y * 0.5, block.max_local().y - size.y)
	return SignInfo.new(block.cell, axis, face_sign, centre, size, color, rng.next_float() < 0.2, rng.next_float())
