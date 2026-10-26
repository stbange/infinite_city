extends GutTest
## Spec free-flight: Starting point.

var layout: CityLayout


func before_each() -> void:
	layout = CityLayout.new(CityConfig.new())


func test_start_at_a_shaft() -> void:
	var spawn := SpawnFinder.find(layout)
	assert_not_null(spawn)
	assert_eq(spawn.cell.y, layout.config.roof_layer + 2)
	assert_false(layout.is_solid(spawn.cell), "spawn cell must be open air")
	# within 2 cells (horizontally) of a shaft cell
	var near_shaft := false
	for dx in range(-2, 3):
		for dz in range(-2, 3):
			if layout.in_shaft(spawn.cell + Vector3i(dx, 0, dz)):
				near_shaft = true
	assert_true(near_shaft, "spawn %s is not next to a shaft" % spawn.cell)
	# looking down, towards the shaft centre
	assert_lt(spawn.pitch, 0.0)
	var forward := Basis.from_euler(Vector3(spawn.pitch, spawn.yaw, 0)) * Vector3(0, 0, -1)
	var camera := Vector3(spawn.cell) * layout.config.cell_size + spawn.offset
	var to_centre := spawn.shaft_center - camera
	var flat_forward := Vector2(forward.x, forward.z).normalized()
	var flat_to_centre := Vector2(to_centre.x, to_centre.z).normalized()
	assert_gt(flat_forward.dot(flat_to_centre), 0.95)


func test_spawn_is_deterministic() -> void:
	var a := SpawnFinder.find(layout)
	var b := SpawnFinder.find(CityLayout.new(CityConfig.new()))
	assert_eq(a.cell, b.cell)
	assert_eq(a.yaw, b.yaw)


func test_absolute_metres_of_spawn() -> void:
	var spawn := SpawnFinder.find(layout)
	var absolute := spawn.absolute_metres(layout.config.cell_size)
	for axis in 3:
		assert_almost_eq(absolute[axis], spawn.cell[axis] * 64.0 + spawn.offset[axis], 1e-6)
