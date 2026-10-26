class_name PocketSpaceInfo
extends RefCounted
## The bigger-on-the-inside space behind a doorway (spec pocket-spaces).
## Interior coordinates: origin at the floor centre, x in [-W/2, W/2], y in [0, H],
## z in [-D/2, D/2]; the inner door stands at (0, 0, -D/2) facing +Z into the room.

enum Kind { HALL, GARDEN, BAZAAR, CONCOURSE }

const _NAMES := {
	Kind.HALL: "Hall",
	Kind.GARDEN: "Garden",
	Kind.BAZAAR: "Bazaar",
	Kind.CONCOURSE: "Concourse",
}

## Half width of the free aisle running from the inner door through the room.
const AISLE := 14.0
## Depth in front of the inner door that stays free.
const ENTRANCE_CLEAR := 40.0

## Cell of the block whose doorway leads here.
var cell: Vector3i
var kind: int
## Width (x), height (y) and depth (z) in metres.
var size: Vector3
var inner_door: Transform3D
var contents_seed: int


func _init(p_cell: Vector3i, p_kind: int, p_size: Vector3, p_inner_door: Transform3D, p_contents_seed: int) -> void:
	cell = p_cell
	kind = p_kind
	size = p_size
	inner_door = p_inner_door
	contents_seed = p_contents_seed


static func kind_name(p_kind: int) -> String:
	return _NAMES.get(p_kind, "Space")


func volume() -> float:
	return size.x * size.y * size.z


## Deterministic furnishing expanded from contents_seed.
func contents() -> PocketContents:
	var rng := CellRandom.new(contents_seed)
	var c := PocketContents.new()
	var half_w := size.x * 0.5
	var half_d := size.z * 0.5
	var h := size.y
	var first_z := -half_d + ENTRANCE_CLEAR

	# Colonnades on both sides of the aisle.
	var x := AISLE + 12.0
	while x + 2.0 < half_w - 6.0:
		var z := first_z + 6.0
		while z + 2.0 < half_d - 8.0:
			for side: float in [-1.0, 1.0]:
				c.pillars.append(AABB(Vector3(side * x - 2.0, 0.0, z - 2.0), Vector3(4.0, h, 4.0)))
			z += 36.0
		x += 40.0

	# Ceiling light panels above the aisle.
	var lz := -half_d + 20.0
	while lz + 3.0 < half_d - 6.0:
		c.lights.append(AABB(Vector3(-10.0, h - 1.5, lz - 3.0), Vector3(20.0, 0.6, 6.0)))
		lz += 30.0

	c.monument = AABB(Vector3(-6.0, 0.0, half_d * 0.35 - 6.0), Vector3(12.0, h * 0.6, 12.0))

	match kind:
		Kind.BAZAAR:
			_add_stalls(c, rng, half_w, half_d)
		Kind.GARDEN:
			_add_trees(c, rng, half_w, half_d)
		Kind.CONCOURSE:
			_add_platforms(c, rng, half_w, half_d, h)
		_:
			_add_statues(c, rng, half_d)
	return c


func _add_stalls(c: PocketContents, rng: CellRandom, half_w: float, half_d: float) -> void:
	var palette := [Color(0.95, 0.45, 0.2), Color(0.95, 0.75, 0.25), Color(0.85, 0.25, 0.35), Color(0.3, 0.75, 0.7)]
	for row_x: float in [AISLE + 4.0, AISLE + 30.0]:
		if row_x + 4.0 > half_w - 4.0:
			continue
		var z := -half_d + ENTRANCE_CLEAR + 2.0
		while z + 7.0 < half_d - 6.0:
			for side: float in [-1.0, 1.0]:
				c.props.append(AABB(Vector3(side * row_x - 3.0, 0.0, z), Vector3(6.0, 3.5, 7.0)))
				c.prop_colors.append(palette[rng.next_int(palette.size())])
			z += 11.0


func _add_trees(c: PocketContents, rng: CellRandom, half_w: float, half_d: float) -> void:
	for i in 70:
		var side := -1.0 if rng.next_int(2) == 0 else 1.0
		var tx := side * rng.range_float(AISLE + 6.0, half_w - 8.0)
		var tz := rng.range_float(-half_d + ENTRANCE_CLEAR + 5.0, half_d - 8.0)
		var crown := rng.range_float(6.0, 11.0)
		c.props.append(AABB(Vector3(tx - 0.8, 0.0, tz - 0.8), Vector3(1.6, 8.0, 1.6)))
		c.prop_colors.append(Color(0.35, 0.24, 0.15))
		c.props.append(AABB(Vector3(tx - crown * 0.5, 6.0, tz - crown * 0.5), Vector3(crown, crown * 0.8, crown)))
		c.prop_colors.append(Color(0.15, rng.range_float(0.45, 0.7), rng.range_float(0.2, 0.35)))


func _add_platforms(c: PocketContents, rng: CellRandom, half_w: float, half_d: float, h: float) -> void:
	var z := -half_d + ENTRANCE_CLEAR + 10.0
	while z + 12.0 < half_d - 6.0:
		for side: float in [-1.0, 1.0]:
			var y := rng.range_float(h * 0.3, h * 0.65)
			# Platform centre, keeping the 20 m wide platform clear of the aisle and the walls.
			var px := minf(AISLE + 10.0 + rng.range_float(0.0, 20.0), half_w - 12.0)
			c.props.append(AABB(Vector3(side * px - 10.0, y, z), Vector3(20.0, 1.5, 12.0)))
			c.prop_colors.append(Color(0.3, 0.85, 1.0))
		z += 26.0


func _add_statues(c: PocketContents, rng: CellRandom, half_d: float) -> void:
	var z := -half_d + ENTRANCE_CLEAR + 4.0
	while z + 5.0 < half_d - 6.0:
		for side: float in [-1.0, 1.0]:
			var sx := side * (AISLE + 2.5)
			c.props.append(AABB(Vector3(sx - 2.5, 0.0, z), Vector3(5.0, 2.0, 5.0)))
			c.prop_colors.append(Color(0.75, 0.72, 0.68))
			var tall := rng.range_float(4.0, 9.0)
			c.props.append(AABB(Vector3(sx - 1.0, 2.0, z + 1.5), Vector3(2.0, tall, 2.0)))
			c.prop_colors.append(Color(0.85, 0.8, 0.95))
		z += 24.0
