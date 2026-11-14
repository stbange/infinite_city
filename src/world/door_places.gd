class_name DoorPlaces
extends RefCounted
## Where doors are in the scene (spec courier-jobs / Waypoint): a unit's door, 1.1 m above its floor.


static func scene_position(world: CityWorld, cell: Vector3i, floor_index: int, unit_index: int) -> Vector3:
	var block := world.layout.block_at(cell)
	var plan := world.population.plan_of(block)
	var unit := plan.units[unit_index]
	return world.origin.scene_position_of_cell_center(cell) + Vector3(unit.door_x, plan.floor_y(floor_index) + 1.1, unit.front_z())
