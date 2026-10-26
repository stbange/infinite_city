extends GutTest
## Spec city-layout: Vertical shafts, Horizontal canyons, Plazas.

const R := 0
const S := 4
const D := 8

var layout: CityLayout


func before_each() -> void:
	layout = CityLayout.new(CityConfig.new())


func _find_cells(predicate: Callable, y: int, max_count: int) -> Array[Vector3i]:
	var found: Array[Vector3i] = []
	for x in range(-80, 80):
		for z in range(-80, 80):
			var cell := Vector3i(x, y, z)
			if predicate.call(cell):
				found.append(cell)
				if found.size() >= max_count:
					return found
	return found


func test_shaft_runs_without_end() -> void:
	var cells := _find_cells(layout.in_shaft, R, 12)
	assert_gt(cells.size(), 0, "expected at least one shaft near the origin")
	for top in cells:
		var layers: Array[int] = [R + S]
		for y in range(R, R - 5001, -37):
			layers.append(y)
		for y in layers:
			var cell := Vector3i(top.x, y, top.z)
			assert_true(layout.in_shaft(cell), "shaft broken at %s" % cell)
			assert_false(layout.is_solid(cell), "block inside shaft at %s" % cell)


func test_shaft_frequency() -> void:
	var with_shaft := 0
	for dx in 20:
		for dz in 20:
			if layout.has_shaft(dx, dz):
				with_shaft += 1
	assert_between(with_shaft / 400.0, 0.15, 0.35)


func test_shaft_width_is_two_or_three_cells() -> void:
	for dx in 20:
		for dz in 20:
			if layout.has_shaft(dx, dz):
				var rect := layout.shaft_rect(dx, dz)
				assert_between(rect.size.x, 2, 3)
				assert_eq(rect.size.x, rect.size.y)


func _assert_runs_along(cells: Array[Vector3i], axis: Vector3i, predicate: Callable) -> void:
	assert_gt(cells.size(), 0, "expected at least one canyon cell near the origin")
	for cell in cells:
		for shift: int in [1, -1, 8, -8, 1000, -1000, 10000000, -10000000]:
			var moved: Vector3i = cell + axis * shift
			assert_true(predicate.call(moved), "canyon broken at %s" % moved)
			assert_false(layout.is_solid(moved), "block inside canyon at %s" % moved)


func test_x_canyon_runs_without_end() -> void:
	var cells: Array[Vector3i] = []
	for y in range(R, R - 40, -1):
		cells.append_array(_find_cells(layout.in_canyon_x, y, 2))
		if cells.size() >= 8:
			break
	_assert_runs_along(cells, Vector3i(1, 0, 0), layout.in_canyon_x)


func test_z_canyon_runs_without_end() -> void:
	var cells: Array[Vector3i] = []
	for y in range(R, R - 40, -1):
		cells.append_array(_find_cells(layout.in_canyon_z, y, 2))
		if cells.size() >= 8:
			break
	_assert_runs_along(cells, Vector3i(0, 0, 1), layout.in_canyon_z)


func test_no_horizontal_canyons_in_the_sky() -> void:
	var hits := 0
	for x in range(0, 20 * D):
		for z in range(0, 20 * D):
			for k in range(1, S + 1):
				var cell := Vector3i(x, R + k, z)
				if layout.in_canyon_x(cell) or layout.in_canyon_z(cell):
					hits += 1
	assert_eq(hits, 0)


func test_plaza_frequency_and_emptiness() -> void:
	var with_plaza := 0
	for dx in 20:
		for dz in 20:
			var district := Vector3i(dx, -3, dz)
			if not layout.has_plaza(district):
				continue
			with_plaza += 1
			var origin := layout.district_origin_cell(district)
			for lx in D:
				for ly in D:
					for lz in D:
						var cell := origin + Vector3i(lx, ly, lz)
						if layout.in_plaza(cell):
							assert_false(layout.is_solid(cell), "block inside plaza at %s" % cell)
	assert_between(with_plaza / 400.0, 0.20, 0.50)


func test_carved_cells_are_never_solid() -> void:
	var rng := CellRandom.new(9)
	var carved := 0
	for i in 20000:
		var cell := Vector3i(rng.range_int(-300, 300), rng.range_int(R - 300, R + S), rng.range_int(-300, 300))
		if layout.is_carved(cell):
			carved += 1
			assert_false(layout.is_solid(cell))
	assert_gt(carved, 0)
