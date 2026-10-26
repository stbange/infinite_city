class_name CityConfig
extends Resource
## All tunables of the city generator. Defaults are the values the specs refer to.

@export var world_seed: int = 1337

@export_group("Lattice")
## Size of one cell in metres (x, y, z).
@export var cell_size: Vector3 = Vector3(64, 64, 64)
## Cells per district edge.
@export var district_size: int = 8
## Cells per chunk edge.
@export var chunk_cells: int = 4

@export_group("Boundary")
## y index of the roof layer, the city's only border.
@export var roof_layer: int = 0
## Number of sparse layers of floating blocks above the roof.
@export var sky_layers: int = 4

@export_group("Density")
@export_range(0.0, 1.0) var base_density: float = 0.62
@export_range(0.0, 1.0) var roof_density: float = 0.85
## Density of the lowest sky layer; higher sky layers thin out linearly.
@export_range(0.0, 1.0) var sky_density: float = 0.08

@export_group("Canyons")
@export_range(0.0, 1.0) var shaft_chance: float = 0.25
@export_range(0.0, 1.0) var canyon_chance: float = 0.2
@export_range(0.0, 1.0) var plaza_chance: float = 0.35

@export_group("Blocks")
@export_range(0.05, 1.0) var block_fill_min: float = 0.55
@export_range(0.05, 1.0) var block_fill_max: float = 0.85
## Minimum distance between two neighbouring blocks, in metres.
@export var min_street_gap: float = 8.0

@export_group("Bridges")
@export_range(0.0, 1.0) var bridge_chance: float = 0.3
@export var bridge_width: float = 6.0

## Largest canyon/shaft/plaza extent in cells; districts must be larger.
const MAX_CARVE_CELLS := 3


## Half-extent around the cell centre that every block is guaranteed to cover.
func guaranteed_core_half_extent() -> Vector3:
	var smallest := cell_size * block_fill_min
	return (smallest * 2.0 - cell_size + Vector3.ONE * min_street_gap) * 0.5


## Returns human-readable problems; empty when the configuration is usable.
func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	for pair: Array in [["base_density", base_density], ["roof_density", roof_density],
			["sky_density", sky_density], ["shaft_chance", shaft_chance],
			["canyon_chance", canyon_chance], ["plaza_chance", plaza_chance],
			["bridge_chance", bridge_chance]]:
		var value: float = pair[1]
		if value < 0.0 or value > 1.0:
			errors.append("%s must be within [0, 1], got %s" % [pair[0], value])
	if block_fill_min <= 0.0 or block_fill_max > 1.0 or block_fill_min > block_fill_max:
		errors.append("block fill range must satisfy 0 < min <= max <= 1")
	if cell_size.x <= min_street_gap or cell_size.y <= min_street_gap or cell_size.z <= min_street_gap:
		errors.append("cell_size must exceed min_street_gap on every axis")
	if district_size <= MAX_CARVE_CELLS:
		errors.append("district_size must be greater than %d" % MAX_CARVE_CELLS)
	if chunk_cells < 1:
		errors.append("chunk_cells must be at least 1")
	if sky_layers < 0:
		errors.append("sky_layers must not be negative")
	var core := guaranteed_core_half_extent()
	if core.x <= 0.0 or core.y <= 0.0 or core.z <= 0.0:
		errors.append("block_fill_min too small: blocks would not be guaranteed to contain the cell centre")
	elif bridge_width > 2.0 * minf(core.x, core.z):
		errors.append("bridge_width %s exceeds the guaranteed block overlap %s" % [bridge_width, 2.0 * minf(core.x, core.z)])
	return errors
