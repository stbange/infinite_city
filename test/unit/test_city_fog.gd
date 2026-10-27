extends GutTest
## Spec city-fog: Drifting fog banks (anchored to the world).

const PERIOD := 1024.0


func test_banks_stay_put_when_the_origin_moves() -> void:
	var config := CityConfig.new()
	var absolute: Array[float] = [1234.5, -98765.25, 4321.0]
	var reference: Array[float] = []
	for chunk: Vector3i in [Vector3i(0, 0, 0), Vector3i(3, -7, 12), Vector3i(5, -2500001, -9)]:
		var origin := FloatingOrigin.for_config(config)
		origin.origin_chunk = chunk
		var offset := CityFog.noise_offset(origin)
		var size := origin.chunk_size()
		var anchored: Array[float] = []
		for axis in 3:
			var scene := absolute[axis] - float(chunk[axis]) * size[axis]
			assert_between(offset[axis], 0.0, PERIOD)
			anchored.append(fposmod(scene + offset[axis], PERIOD))
		if reference.is_empty():
			reference = anchored
		for axis in 3:
			assert_almost_eq(anchored[axis], reference[axis], 1e-6, "axis %d with the origin at %s" % [axis, chunk])
