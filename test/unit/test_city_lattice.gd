extends GutTest
## Spec city-layout / Requirement: Cell lattice.

var layout: CityLayout


func before_each() -> void:
	layout = CityLayout.new(CityConfig.new())


func test_cell_bounds() -> void:
	var bounds := layout.cell_bounds(Vector3i(1, -2, 3))
	assert_eq(bounds.position, Vector3(64, -128, 192))
	assert_eq(bounds.end, Vector3(128, -64, 256))


func test_negative_positions_map_to_negative_cells() -> void:
	assert_eq(layout.cell_of_position(Vector3(-0.5, -0.5, -0.5)), Vector3i(-1, -1, -1))


func test_position_on_cell_boundary_belongs_to_upper_cell() -> void:
	assert_eq(layout.cell_of_position(Vector3(64, 0, -64)), Vector3i(1, 0, -1))


func test_cell_center() -> void:
	assert_eq(layout.cell_center(Vector3i(0, -1, 2)), Vector3(32, -32, 160))


func test_chunk_of_cell() -> void:
	assert_eq(layout.chunk_of(Vector3i(0, 0, 0)), Vector3i(0, 0, 0))
	assert_eq(layout.chunk_of(Vector3i(3, -1, -4)), Vector3i(0, -1, -1))
	assert_eq(layout.chunk_of(Vector3i(4, -5, -5)), Vector3i(1, -2, -2))


func test_chunk_origin_cell() -> void:
	assert_eq(layout.chunk_origin_cell(Vector3i(-2, -1, 3)), Vector3i(-8, -4, 12))
