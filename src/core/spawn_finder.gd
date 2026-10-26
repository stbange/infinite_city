class_name SpawnFinder
extends RefCounted
## Finds the starting point: 2 layers above the roof at the rim of the shaft nearest the
## origin, looking down into it (spec free-flight / Starting point).

const START_PITCH_DEGREES := -35.0
const ON_FOOT_PITCH_DEGREES := -12.0
## How far from the roof edge facing the shaft the on-foot start stands, in metres.
const EDGE_DISTANCE := 3.0


static func find(layout: CityLayout, max_ring: int = 16) -> SpawnPoint:
	var d := layout.config.district_size
	var cs := layout.config.cell_size
	var y := layout.config.roof_layer + 2
	for ring in max_ring + 1:
		for column in _ring_columns(ring):
			var rect := layout.shaft_rect(column.x, column.y)
			if not rect.has_area():
				continue
			var min_x := column.x * d + rect.position.x
			var min_z := column.y * d + rect.position.y
			var w := rect.size.x
			var mid_x := min_x + w / 2
			var mid_z := min_z + w / 2
			var centre := Vector3((min_x + w * 0.5) * cs.x, y * cs.y, (min_z + w * 0.5) * cs.z)
			for candidate: Vector3i in [Vector3i(min_x - 1, y, mid_z), Vector3i(min_x + w, y, mid_z),
					Vector3i(mid_x, y, min_z - 1), Vector3i(mid_x, y, min_z + w)]:
				if layout.is_solid(candidate):
					continue
				var offset := cs * 0.5
				var camera := Vector3(candidate) * cs + offset
				var to_centre := centre - camera
				var yaw := atan2(-to_centre.x, -to_centre.z)
				return SpawnPoint.new(candidate, offset, yaw, deg_to_rad(START_PITCH_DEGREES), centre)
	return null


## District columns at Chebyshev distance `ring` from (0, 0), nearest first.
static func _ring_columns(ring: int) -> Array[Vector2i]:
	var columns: Array[Vector2i] = []
	for dx in range(-ring, ring + 1):
		for dz in range(-ring, ring + 1):
			if maxi(absi(dx), absi(dz)) == ring:
				columns.append(Vector2i(dx, dz))
	columns.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var la := a.length_squared()
		var lb := b.length_squared()
		return la < lb if la != lb else (a.x < b.x if a.x != b.x else a.y < b.y))
	return columns


## On-foot start: standing on the roof of a roof-layer block at the rim of the shaft nearest
## the origin, facing the shaft (spec on-foot-movement / Starting on foot).
static func find_on_foot(layout: CityLayout, max_ring: int = 16) -> SpawnPoint:
	var d := layout.config.district_size
	var cs := layout.config.cell_size
	var y := layout.config.roof_layer
	for ring in max_ring + 1:
		for column in _ring_columns(ring):
			var rect := layout.shaft_rect(column.x, column.y)
			if not rect.has_area():
				continue
			var min_x := column.x * d + rect.position.x
			var min_z := column.y * d + rect.position.y
			var w := rect.size.x
			var mid_x := min_x + w / 2
			var mid_z := min_z + w / 2
			var centre := Vector3((min_x + w * 0.5) * cs.x, (y + 1) * cs.y, (min_z + w * 0.5) * cs.z)
			# Rim cells and the direction from each towards the shaft.
			var rims: Array = [[Vector3i(min_x - 1, y, mid_z), Vector3(1, 0, 0)], [Vector3i(min_x + w, y, mid_z), Vector3(-1, 0, 0)],
					[Vector3i(mid_x, y, min_z - 1), Vector3(0, 0, 1)], [Vector3i(mid_x, y, min_z + w), Vector3(0, 0, -1)]]
			for rim: Array in rims:
				var cell: Vector3i = rim[0]
				var towards: Vector3 = rim[1]
				var block := layout.block_at(cell)
				if block == null:
					continue
				var local := Vector3(block.offset.x, block.max_local().y, block.offset.z)
				var axis := Vector3.AXIS_X if towards.x != 0.0 else Vector3.AXIS_Z
				local[axis] = (block.max_local()[axis] if towards[axis] > 0.0 else block.min_local()[axis]) \
						- towards[axis] * EDGE_DISTANCE
				var offset := cs * 0.5 + local
				var position := Vector3(cell) * cs + offset
				var to_centre := centre - position
				var yaw := atan2(-to_centre.x, -to_centre.z)
				return SpawnPoint.new(cell, offset, yaw, deg_to_rad(ON_FOOT_PITCH_DEGREES), centre)
	return null
