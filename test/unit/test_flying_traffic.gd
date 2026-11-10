extends GutTest
## Spec flying-traffic: Cars in the major lanes.

var layout: CityLayout
var traffic: TrafficLanes
var centres: Array[Vector3i] = []


func before_all() -> void:
	layout = CityLayout.new(CityConfig.new())
	traffic = TrafficLanes.new(layout)
	var spawn := SpawnFinder.find_on_foot(layout)
	for i in 6:
		centres.append(spawn.cell + Vector3i(i * 7 - 20, (i % 3) - 1, 11 - i * 5))


func after_all() -> void:
	traffic = null
	layout = null


func test_cars_only_in_lanes_never_in_blocks() -> void:
	var cs := layout.config.cell_size
	var total := 0
	for centre in centres:
		var cars := traffic.cars_near(centre, 300.0, 123456.7)
		total += cars.size()
		for car in cars:
			var position: Vector3 = car["position"]
			var id: Array = car["id"]
			var lane_axis: int = id[0]
			assert_true(layout.is_lane(lane_axis, id[1]))
			# In the lane's gap: within the setbacks of the boundary plane.
			var plane := float(id[1]) * cs[lane_axis] - (centre[lane_axis] + 0.5) * cs[lane_axis]
			assert_lt(absf(position[lane_axis] - plane), layout.config.lane_setback - TrafficLanes.CAR_SIZE.x)
			# Inside no block: test the cells around the car.
			var absolute := (Vector3(centre) + Vector3(0.5, 0.5, 0.5)) * cs + position
			var cell := layout.cell_of_position(absolute)
			for dx in range(-1, 2):
				for dz in range(-1, 2):
					var block := layout.block_at(cell + Vector3i(dx, 0, dz))
					if block != null and layout.block_aabb(block).grow(1.0).has_point(absolute):
						fail_test("car %s inside block %s" % [id, block.cell])
						return
	assert_gt(total, 50)


func test_continuous_and_deterministic() -> void:
	var t := 98765.4321
	var before := traffic.cars_near(centres[0], 250.0, t)
	var after := traffic.cars_near(centres[0], 250.0, t + 0.1)
	var by_id := {}
	for car in after:
		by_id[str(car["id"])] = car
	var matched := 0
	for car in before:
		var key := str(car["id"])
		if not by_id.has(key):
			continue
		matched += 1
		var expected: Vector3 = (car["position"] as Vector3) + (car["velocity"] as Vector3) * 0.1
		assert_almost_eq(by_id[key]["position"], expected, Vector3.ONE * 0.01)
	assert_gt(matched, 20)
	var other := TrafficLanes.new(CityLayout.new(CityConfig.new()))
	var again := other.cars_near(centres[0], 250.0, t)
	assert_eq(again.size(), before.size())
	for i in before.size():
		assert_eq(str(again[i]["id"]), str(before[i]["id"]))
		assert_almost_eq(again[i]["position"], before[i]["position"], Vector3.ONE * 0.001)
