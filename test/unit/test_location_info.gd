extends GutTest
## Spec free-flight: Location read-out.

var layout: CityLayout


func before_each() -> void:
	layout = CityLayout.new(CityConfig.new())


func test_read_out_content() -> void:
	var text := LocationInfo.describe(layout, Vector3i(3, -12, 5), BlockTypes.NONE)
	assert_string_contains(text, "Cell 3, -12, 5")
	assert_string_contains(text, "Depth 12 layers (768 m)")
	assert_string_contains(text, "District 0, -2, 0")
	assert_string_contains(text, "Open air")


func test_read_out_names_the_block() -> void:
	var text := LocationInfo.describe(layout, Vector3i(3, -12, 5), BlockTypes.Kind.HOSPITAL)
	assert_string_contains(text, "Hospital")
	assert_false(text.contains("Open air"))


func test_above_the_roof() -> void:
	var text := LocationInfo.describe(layout, Vector3i(0, 2, 0), BlockTypes.NONE)
	assert_string_contains(text, "Altitude 2 layers above the roof")
	assert_false(text.contains("Depth"))


func test_on_the_roof_layer() -> void:
	var text := LocationInfo.describe(layout, Vector3i(0, 0, 0), BlockTypes.NONE)
	assert_string_contains(text, "Depth 0 layers (0 m)")


func test_read_out_inside_a_pocket_space() -> void:
	var pocket := PocketSpaceInfo.new(Vector3i(4, -3, 7), PocketSpaceInfo.Kind.BAZAAR, Vector3(240, 90, 420),
			Transform3D(Basis.IDENTITY, Vector3(0, 0, -210)), 5)
	var text := LocationInfo.describe_pocket(pocket)
	assert_string_contains(text, "Bazaar")
	assert_string_contains(text, "240 × 90 × 420 m")
	assert_string_contains(text, "behind cell 4, -3, 7")
