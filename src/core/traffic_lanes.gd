class_name TrafficLanes
extends RefCounted
## Flying cars in the major lanes (spec flying-traffic / Cars in the major lanes): positions are a
## pure function of lane, track and time, so nothing is simulated away from the player.

const SALT_TRAFFIC := 180
const SPEED := 24.0
const SPACING := 80.0
## Offset of each direction from the middle of the lane's gap, and of the two heights from the
## middle of the layer.
const LATERAL := 6.0
const HEIGHT := 10.0
const TRACKS := 4
const CAR_SIZE := Vector3(2.2, 1.6, 4.4)

var layout: CityLayout


func _init(p_layout: CityLayout) -> void:
	layout = p_layout


## Cars within `radius` of the centre of `center_cell` at real time `seconds`, as dictionaries
## {position (relative to the cell centre), velocity, id (Array)}.
func cars_near(center_cell: Vector3i, radius: float, seconds: float) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var cs := layout.config.cell_size
	var seed_value := layout.config.world_seed
	var rows := ceili(radius / cs.y)
	for lane_axis in CityLayout.BRIDGE_AXES:
		var along_axis := Vector3.AXIS_Z if lane_axis == Vector3.AXIS_X else Vector3.AXIS_X
		var centre := (float(center_cell[lane_axis]) + 0.5) * cs[lane_axis]
		var centre_along := (float(center_cell[along_axis]) + 0.5) * cs[along_axis]
		var first := ceili((centre - radius) / cs[lane_axis])
		var last := floori((centre + radius) / cs[lane_axis])
		for boundary in range(first, last + 1):
			if not layout.is_lane(lane_axis, boundary):
				continue
			var plane := float(boundary) * cs[lane_axis] - centre
			for row in range(center_cell.y - rows, center_cell.y + rows + 1):
				var row_y := float(row - center_cell.y) * cs.y
				for track in TRACKS:
					var direction := 1.0 if track % 2 == 0 else -1.0
					var height := -HEIGHT if track < 2 else HEIGHT
					var phase := DetHash.u01(DetHash.hash4(seed_value, SALT_TRAFFIC, lane_axis, boundary, row, track)) * SPACING
					var moved := phase + direction * SPEED * seconds
					var n0 := ceili((centre_along - radius - moved) / SPACING)
					var n1 := floori((centre_along + radius - moved) / SPACING)
					for n in range(n0, n1 + 1):
						var along := moved + float(n) * SPACING - centre_along
						var position := Vector3.ZERO
						position[lane_axis] = plane + direction * LATERAL
						position[along_axis] = along
						position.y = row_y + height
						var velocity := Vector3.ZERO
						velocity[along_axis] = direction * SPEED
						result.append({"position": position, "velocity": velocity, "id": [lane_axis, boundary, row, track, n]})
	return result


## Whether a point (relative to the centre of `center_cell`) touches a car of the list.
static func hits(cars: Array[Dictionary], point: Vector3, margin: float = 0.3) -> bool:
	for car in cars:
		var offset: Vector3 = point - (car["position"] as Vector3)
		var velocity: Vector3 = car["velocity"]
		var half := CAR_SIZE * 0.5 + Vector3.ONE * margin
		var along_x := absf(velocity.x) > absf(velocity.z)
		var extent := Vector3(half.z, half.y, half.x) if along_x else half
		if absf(offset.x) <= extent.x and absf(offset.y) <= extent.y and absf(offset.z) <= extent.z:
			return true
	return false
