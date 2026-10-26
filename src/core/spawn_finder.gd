class_name SpawnFinder
extends RefCounted
## Finds the starting point: 2 layers above the roof at the rim of the shaft nearest the
## origin, looking down into it (spec free-flight / Starting point).

const START_PITCH_DEGREES := -35.0


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
