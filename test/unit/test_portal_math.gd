extends GutTest
## Spec portal-traversal: Doorway pairing, Crossing a doorway, Doorways are one-sided (pure math).

const SIZE := Vector2(4, 6)

var outer := Transform3D(Basis(Vector3.UP, 0.7), Vector3(10, 5, -3))
var inner := Transform3D(Basis(Vector3.UP, -2.1), Vector3(100, 1200, 40))


func test_points_in_front_map_behind() -> void:
	var mapped := PortalMath.pair(outer, inner) * (outer * Vector3(0, 1, 2))
	assert_almost_eq(mapped, inner * Vector3(0, 1, -2), Vector3.ONE * 0.001)


func test_points_behind_map_in_front() -> void:
	var mapped := PortalMath.pair(outer, inner) * (outer * Vector3(0.5, 2, -1))
	assert_almost_eq(mapped, inner * Vector3(-0.5, 2, 1), Vector3.ONE * 0.001)


func test_mapping_back_and_forth_is_the_identity() -> void:
	var there := PortalMath.pair(outer, inner)
	var back := PortalMath.pair(inner, outer)
	var rng := CellRandom.new(3)
	for i in 50:
		var pose := Transform3D(Basis.from_euler(Vector3(rng.range_float(-1.5, 1.5), rng.range_float(-3, 3), 0)),
				Vector3(rng.range_float(-200, 200), rng.range_float(-200, 200), rng.range_float(-200, 200)))
		var round_trip := back * (there * pose)
		assert_almost_eq(round_trip.origin, pose.origin, Vector3.ONE * 0.001)
		for axis in 3:
			assert_almost_eq(round_trip.basis[axis], pose.basis[axis], Vector3.ONE * 0.001)


func test_motion_into_the_doorway_continues_into_the_room() -> void:
	var into_outer := outer.basis * Vector3(0, 0, -1)
	var mapped := PortalMath.pair(outer, inner).basis * into_outer
	assert_almost_eq(mapped, inner.basis * Vector3(0, 0, 1), Vector3.ONE * 0.001)


func test_map_pose_matches_pair() -> void:
	var pose := Transform3D(Basis(Vector3.UP, 0.3), Vector3(12, 6, -1))
	var expected := PortalMath.pair(outer, inner) * pose
	var actual := PortalMath.map_pose(outer, inner, pose)
	assert_almost_eq(actual.origin, expected.origin, Vector3.ONE * 0.001)


func test_crossing_front_to_back_through_the_opening() -> void:
	assert_true(PortalMath.crossed(outer, SIZE, outer * Vector3(0, 1, 1), outer * Vector3(0, 1, -1)))
	assert_true(PortalMath.crossed(outer, SIZE, outer * Vector3(1.9, 5.9, 0.3), outer * Vector3(1.9, 5.9, -0.3)))


func test_crossing_from_behind_does_nothing() -> void:
	assert_false(PortalMath.crossed(outer, SIZE, outer * Vector3(0, 1, -1), outer * Vector3(0, 1, 1)))


func test_crossing_beside_the_opening_does_nothing() -> void:
	assert_false(PortalMath.crossed(outer, SIZE, outer * Vector3(5, 1, 1), outer * Vector3(5, 1, -1)))
	assert_false(PortalMath.crossed(outer, SIZE, outer * Vector3(0, 7, 1), outer * Vector3(0, 7, -1)))
	assert_false(PortalMath.crossed(outer, SIZE, outer * Vector3(0, -0.5, 1), outer * Vector3(0, -0.5, -1)))


func test_staying_on_one_side_does_nothing() -> void:
	assert_false(PortalMath.crossed(outer, SIZE, outer * Vector3(0, 1, 3), outer * Vector3(0, 1, 0.5)))


func test_diagonal_crossing_uses_the_intersection_point() -> void:
	# Starts beside the opening but crosses the plane inside it.
	assert_true(PortalMath.crossed(outer, SIZE, outer * Vector3(4, 1, 1), outer * Vector3(-2, 1, -1)))
	# Starts inside the opening's outline but crosses the plane beside it.
	assert_false(PortalMath.crossed(outer, SIZE, outer * Vector3(0, 1, 1), outer * Vector3(8, 1, -1)))


func test_yaw_and_pitch_from_basis() -> void:
	var basis := Basis.from_euler(Vector3(-0.4, 2.5, 0))
	var look := PortalMath.yaw_pitch_of(basis)
	assert_almost_eq(look.x, 2.5, 1e-5)
	assert_almost_eq(look.y, -0.4, 1e-5)
