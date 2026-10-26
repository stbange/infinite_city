class_name CityLighting
extends RefCounted
## Artificial light of the city (spec city-lighting): neon signs on facades and lamps along
## bridges. Pure function of the seed and the generated blocks/bridges.

const SALT_SIGNS := 31
const SALT_LAMPS := 32
## Half width of the band around a face's cell centre line kept free for bridges and entrances.
const BAND := 8.0
const MARGIN := 1.0
## Signs hang this far in front of the face.
const OFFSET := 0.3
const ATTEMPTS := 8
const FLICKER_SHARE := 0.15
const LAMP_SPACING := 12.0
const LAMP_START := 2.0
const LAMP_HEIGHT := 3.2
const LAMP_INSET := 0.3

const NEON_PALETTE: Array[Color] = [
	Color(1.0, 0.16, 0.62),   # hot pink
	Color(0.1, 0.92, 1.0),    # cyan
	Color(0.62, 0.3, 1.0),    # violet
	Color(1.0, 0.62, 0.12),   # amber
	Color(0.45, 1.0, 0.3),    # acid green
	Color(1.0, 0.25, 0.25),   # red
]
const LAMP_COLORS: Array[Color] = [Color(1.0, 0.72, 0.42), Color(0.55, 0.85, 1.0), Color(1.0, 0.4, 0.85)]

var city: CityLayout


func _init(city_layout: CityLayout) -> void:
	city = city_layout


static func lateral_axis(axis: int) -> int:
	return Vector3.AXIS_Z if axis == Vector3.AXIS_X else Vector3.AXIS_X


## How many signs a block wants.
static func _wanted_signs(kind: int, rng: CellRandom) -> int:
	if BlockTypes.is_service(kind):
		return 1
	match kind:
		BlockTypes.Kind.MARKET:
			return rng.range_int(2, 3)
		BlockTypes.Kind.OFFICE:
			return rng.range_int(1, 2)
		_:
			return 1 if rng.next_float() < 0.6 else 0


## Signs of a block; `doorway` (may be null) is its magic doorway, which signs keep clear of.
func signs_of(block: BlockInfo, doorway: DoorwayInfo) -> Array[SignInfo]:
	var rng := CellRandom.new(DetHash.hash_cell(city.config.world_seed, SALT_SIGNS, block.cell))
	var wanted := _wanted_signs(block.kind, rng)
	var signs: Array[SignInfo] = []
	for i in wanted:
		for attempt in ATTEMPTS:
			var sign := _try_sign(block, rng)
			if sign != null and _fits(sign, doorway, signs):
				signs.append(sign)
				break
	return signs


func _try_sign(block: BlockInfo, rng: CellRandom) -> SignInfo:
	var face := rng.next_int(4)
	var axis := Vector3.AXIS_X if face < 2 else Vector3.AXIS_Z
	var face_sign := 1 if face % 2 == 0 else -1
	var lat := lateral_axis(axis)
	var vertical := rng.next_float() < 0.6
	var size := Vector2(rng.range_float(1.5, 3.0), rng.range_float(6.0, 14.0)) if vertical \
			else Vector2(rng.range_float(6.0, 14.0), rng.range_float(1.5, 3.0))
	var right_side := rng.next_int(2) == 1
	var colour_roll := rng.next_int(NEON_PALETTE.size())
	var flicker := rng.next_float() < FLICKER_SHARE
	var pattern := rng.next_float()
	var along := rng.next_float()
	var up := rng.next_float()

	var lo: float
	var hi: float
	if right_side:
		lo = BAND + size.x * 0.5
		hi = block.max_local()[lat] - MARGIN - size.x * 0.5
	else:
		lo = block.min_local()[lat] + MARGIN + size.x * 0.5
		hi = -BAND - size.x * 0.5
	var y_lo := block.min_local().y + MARGIN + size.y * 0.5
	var y_hi := block.max_local().y - MARGIN - size.y * 0.5
	if hi < lo or y_hi < y_lo:
		return null
	var centre := Vector3()
	centre[axis] = (block.max_local()[axis] if face_sign > 0 else block.min_local()[axis]) + face_sign * OFFSET
	centre[lat] = lerpf(lo, hi, along)
	centre.y = lerpf(y_lo, y_hi, up)
	var color := BlockTypes.color(block.kind) if BlockTypes.is_service(block.kind) else NEON_PALETTE[colour_roll]
	return SignInfo.new(block.cell, axis, face_sign, centre, size, color, flicker, pattern)


static func _fits(sign: SignInfo, doorway: DoorwayInfo, placed: Array[SignInfo]) -> bool:
	var lat := lateral_axis(sign.face_axis)
	var rect := Rect2(sign.centre[lat] - sign.size.x * 0.5, sign.centre.y - sign.size.y * 0.5, sign.size.x, sign.size.y)
	if doorway != null and doorway.face_axis == sign.face_axis and doorway.face_sign == sign.face_sign:
		var door := Rect2(doorway.door.origin[lat] - PocketLayout.DOOR_SIZE.x * 0.5, doorway.door.origin.y,
				PocketLayout.DOOR_SIZE.x, PocketLayout.DOOR_SIZE.y).grow(MARGIN)
		if rect.intersects(door):
			return false
	for other in placed:
		if other.face_axis != sign.face_axis or other.face_sign != sign.face_sign:
			continue
		var other_rect := Rect2(other.centre[lat] - other.size.x * 0.5, other.centre.y - other.size.y * 0.5,
				other.size.x, other.size.y)
		if rect.intersects(other_rect):
			return false
	return true


## Lamps along both edges of a bridge, relative to cell_a's centre.
func lamps_of(bridge: BridgeInfo) -> Array[LampInfo]:
	var rng := CellRandom.new(DetHash.hash4(city.config.world_seed, SALT_LAMPS,
			bridge.cell_a.x, bridge.cell_a.y, bridge.cell_a.z, bridge.axis))
	var color := LAMP_COLORS[rng.next_int(LAMP_COLORS.size())]
	var lat := lateral_axis(bridge.axis)
	var per_edge := maxi(1, floori((bridge.length() - 2.0 * LAMP_START) / LAMP_SPACING) + 1)
	var lamps: Array[LampInfo] = []
	for side: float in [-1.0, 1.0]:
		for i in per_edge:
			var p := bridge.start
			p[bridge.axis] = bridge.start[bridge.axis] + LAMP_START + LAMP_SPACING * i
			p[lat] = bridge.start[lat] + side * (bridge.width * 0.5 - LAMP_INSET)
			p.y = bridge.start.y + LAMP_HEIGHT
			lamps.append(LampInfo.new(bridge.cell_a, p, color))
	return lamps
