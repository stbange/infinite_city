extends GutTest
## Spec addresses: Place names, Addresses.

var layout: CityLayout
var names: PlaceNames


func before_all() -> void:
	layout = CityLayout.new(CityConfig.new())
	names = PlaceNames.new(layout)


func test_unique_district_names() -> void:
	var rng := CellRandom.new(1)
	for r in 20:
		var reach := Vector3i(rng.range_int(-50, 50), -rng.range_int(1, 40), rng.range_int(-50, 50))
		var seen := {}
		for district in ReachHistory.districts_of(layout.config, reach):
			var name := names.district_name(district)
			assert_false(seen.has(name), "%s twice in reach %s" % [name, reach])
			seen[name] = true


func test_block_and_layer_names() -> void:
	var cell := Vector3i(5, -19, -3)
	var block_name := names.block_name(cell)
	assert_true(block_name.begins_with(names.district_name(layout.district_of(cell)) + "-"))
	var number := int(block_name.split("-")[-1])
	assert_between(number, 1, 512)
	assert_eq(names.layer_label(cell.y), "L-19")
	assert_eq(names.layer_label(0), "L0")


func test_round_trip() -> void:
	var interiors := InteriorLayout.new(layout, PocketLayout.new(layout))
	var rng := CellRandom.new(2)
	var checked := 0
	while checked < 2000:
		var cell := Vector3i(rng.range_int(-400, 400), -rng.range_int(0, 200), rng.range_int(-400, 400))
		var block := layout.block_at(cell)
		if block == null:
			continue
		var plan := interiors.plan_of(block)
		var k := rng.next_int(plan.floors)
		var unit := rng.next_int(plan.units.size())
		var text := Address.format(names, cell, k, unit)
		var parsed := Address.parse(text)
		assert_eq(parsed.get("floor"), k)
		assert_eq(parsed.get("unit"), unit)
		var near := cell + Vector3i(rng.range_int(-12, 12), 0, rng.range_int(-12, 12))
		var resolved := Address.resolve_near(text, names, near)
		assert_eq(resolved.get("cell"), cell, text)
		assert_eq(resolved.get("floor"), k)
		assert_eq(resolved.get("unit"), unit)
		checked += 1
