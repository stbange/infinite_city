extends GutTest
## Spec city-zoning: Block functions, Districts, Essential services, Depth-dependent mix.

const R := 0
const S := 4
const D := 8

var layout: CityLayout


func before_each() -> void:
	layout = CityLayout.new(CityConfig.new())


func _service_counts(lay: CityLayout, district: Vector3i) -> Dictionary:
	var counts := {}
	var blocks := 0
	var origin := lay.district_origin_cell(district)
	for lx in D:
		for ly in D:
			for lz in D:
				var kind := lay.block_kind_at(origin + Vector3i(lx, ly, lz))
				if kind == BlockTypes.NONE:
					continue
				blocks += 1
				if BlockTypes.is_service(kind):
					counts[kind] = counts.get(kind, 0) + 1
	counts["blocks"] = blocks
	return counts


func test_every_block_has_one_function() -> void:
	var rng := CellRandom.new(5)
	var valid := BlockTypes.Kind.values()
	for i in 5000:
		var cell := Vector3i(rng.range_int(-300, 300), rng.range_int(R - 200, R), rng.range_int(-300, 300))
		var kind := layout.block_kind_at(cell)
		if layout.is_solid(cell):
			assert_true(valid.has(kind), "solid cell %s has invalid function %d" % [cell, kind])
		else:
			assert_eq(kind, BlockTypes.NONE)


func test_district_membership() -> void:
	var top := layout.district_of(Vector3i(0, R, 0))
	assert_eq(layout.district_of(Vector3i(7, R - 7, 7)), top)
	assert_ne(layout.district_of(Vector3i(0, R - 8, 0)), top)
	assert_ne(layout.district_of(Vector3i(-1, R, 0)), top)
	assert_ne(layout.district_of(Vector3i(0, R + 1, 0)), top)
	assert_eq(top, Vector3i(0, -1, 0))


func test_services_in_ordinary_districts() -> void:
	for dy: int in [-1, -2, -50]:
		for dx in range(-3, 4):
			for dz in range(-3, 4):
				var district := Vector3i(dx, dy, dz)
				var counts := _service_counts(layout, district)
				for service in BlockTypes.SERVICES:
					assert_eq(counts.get(service, 0), 1,
							"district %s has %d x %s" % [district, counts.get(service, 0), BlockTypes.display_name(service)])


func test_services_in_very_sparse_districts() -> void:
	var config := CityConfig.new()
	config.base_density = 0.03
	config.roof_density = 0.03
	var sparse := CityLayout.new(config)
	var checked := 0
	for dx in range(0, 6):
		for dz in range(0, 6):
			var counts := _service_counts(sparse, Vector3i(dx, -2, dz))
			if counts["blocks"] < BlockTypes.SERVICES.size():
				continue
			checked += 1
			for service in BlockTypes.SERVICES:
				assert_eq(counts.get(service, 0), 1)
	assert_gt(checked, 10, "expected most sparse districts to have at least 7 blocks")


func test_no_services_in_the_sky() -> void:
	for x in range(0, 10 * D):
		for z in range(0, 10 * D):
			for k in range(1, S + 1):
				assert_false(BlockTypes.is_service(layout.block_kind_at(Vector3i(x, R + k, z))))


func _general_share(min_depth: int, max_depth: int, kinds: Array[int], samples: int) -> float:
	var rng := CellRandom.new(min_depth + 17)
	var counted := 0
	var hits := 0
	while counted < samples:
		var cell := Vector3i(rng.range_int(-500, 500), R - rng.range_int(min_depth, max_depth), rng.range_int(-500, 500))
		var kind := layout.block_kind_at(cell)
		if kind == BlockTypes.NONE or BlockTypes.is_service(kind):
			continue
		counted += 1
		if kinds.has(kind):
			hits += 1
	return float(hits) / samples


func test_farms_and_industry_dominate_the_deep() -> void:
	var farm_industry: Array[int] = [BlockTypes.Kind.FARM, BlockTypes.Kind.INDUSTRY]
	var market_office: Array[int] = [BlockTypes.Kind.MARKET, BlockTypes.Kind.OFFICE]
	assert_gte(_general_share(96, 400, farm_industry, 3000), 2.0 * _general_share(0, 23, farm_industry, 3000))
	assert_gte(_general_share(0, 23, market_office, 3000), 2.0 * _general_share(96, 400, market_office, 3000))


func test_sky_blocks_are_homes_parks_or_markets() -> void:
	var allowed := [BlockTypes.Kind.HOUSING, BlockTypes.Kind.PARK, BlockTypes.Kind.MARKET]
	var seen := 0
	for x in range(0, 20 * D):
		for z in range(0, 20 * D):
			for k in range(1, S + 1):
				var kind := layout.block_kind_at(Vector3i(x, R + k, z))
				if kind != BlockTypes.NONE:
					seen += 1
					assert_true(allowed.has(kind), "sky block of kind %s" % BlockTypes.display_name(kind))
	assert_gt(seen, 0)
