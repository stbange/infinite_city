class_name CourierWaypoint
extends RefCounted
## The next door to go to (spec courier-jobs / Waypoint): the first carried order's drop-off, or the
## patron's counter, as {position, label, floor, address}.


static func of(jobs: JobManager, world: CityWorld) -> Dictionary:
	if world == null:
		return {}
	if not jobs.carried.is_empty():
		var job := jobs.carried[0]
		return {"position": DoorPlaces.scene_position(world, job.dropoff_cell, job.dropoff_floor, job.dropoff_unit),
			"label": "%s: %s" % [job.customer_name, job.cargo], "floor": job.dropoff_floor,
			"address": Address.format(jobs.names, job.dropoff_cell, job.dropoff_floor, job.dropoff_unit)}
	if jobs.patron != null:
		return {"position": DoorPlaces.scene_position(world, jobs.patron.cell, jobs.patron.floor_index, jobs.patron.unit),
			"label": "Jobs at %s" % jobs.patron.name, "floor": jobs.patron.floor_index,
			"address": Address.format(jobs.names, jobs.patron.cell, jobs.patron.floor_index, jobs.patron.unit)}
	return {}


