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
@export_range(0.0, 1.0) var base_density: float = 0.9
@export_range(0.0, 1.0) var roof_density: float = 0.96
## Density of the lowest sky layer; higher sky layers thin out linearly.
@export_range(0.0, 1.0) var sky_density: float = 0.08

@export_group("Canyons")
@export_range(0.0, 1.0) var shaft_chance: float = 0.25
@export_range(0.0, 1.0) var canyon_chance: float = 0.2
@export_range(0.0, 1.0) var plaza_chance: float = 0.35

@export_group("Streets and lanes")
## How far a block face sits back from its cell face across an ordinary street (horizontal), in
## metres; two neighbours are therefore 2 × min … 2 × max apart. Vertical setbacks are whole
## floors (0 or 4 m at the bottom, 4 or 8 m at the top).
@export var street_setback_min: float = 2.0
@export var street_setback_max: float = 6.0
## Share of cell boundaries (per axis) that are major traffic lanes.
@export_range(0.0, 1.0) var lane_chance: float = 0.16
## Setback of block faces from a lane (vertically rounded up to whole floors), plus up to
## `lane_setback_jitter` horizontally.
@export var lane_setback: float = 16.0
@export var lane_setback_jitter: float = 2.0

@export_group("Bridges")
@export_range(0.0, 1.0) var bridge_chance: float = 0.3
@export var bridge_width: float = 6.0

## Largest canyon/shaft/plaza extent in cells; districts must be larger.
const MAX_CARVE_CELLS := 3


## Half-extent around the cell centre that every block is guaranteed to cover.
func guaranteed_core_half_extent() -> Vector3:
	var horizontal := maxf(lane_setback + lane_setback_jitter, street_setback_max)
	var vertical := maxf(lane_vertical_setback(), 8.0)
	return Vector3(cell_size.x * 0.5 - horizontal, cell_size.y * 0.5 - vertical, cell_size.z * 0.5 - horizontal)


## Lane setback rounded up to whole 4 m floors (used vertically).
func lane_vertical_setback() -> float:
	return ceilf(lane_setback / 4.0 - 1e-6) * 4.0


## Returns human-readable problems; empty when the configuration is usable.
func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	for pair: Array in [["base_density", base_density], ["roof_density", roof_density],
			["sky_density", sky_density], ["shaft_chance", shaft_chance],
			["canyon_chance", canyon_chance], ["plaza_chance", plaza_chance],
			["bridge_chance", bridge_chance], ["lane_chance", lane_chance]]:
		var value: float = pair[1]
		if value < 0.0 or value > 1.0:
			errors.append("%s must be within [0, 1], got %s" % [pair[0], value])
	if street_setback_min <= 0.0 or street_setback_min > street_setback_max:
		errors.append("street setbacks must satisfy 0 < min <= max")
	if lane_setback < street_setback_max or lane_setback_jitter < 0.0:
		errors.append("lane setback must be at least the street setback, jitter not negative")
	if district_size <= MAX_CARVE_CELLS:
		errors.append("district_size must be greater than %d" % MAX_CARVE_CELLS)
	if chunk_cells < 1:
		errors.append("chunk_cells must be at least 1")
	if sky_layers < 0:
		errors.append("sky_layers must not be negative")
	var core := guaranteed_core_half_extent()
	if core.x <= 0.0 or core.y <= 0.0 or core.z <= 0.0:
		errors.append("setbacks too large: blocks would not be guaranteed to contain the cell centre")
	elif bridge_width > 2.0 * minf(core.x, core.z):
		errors.append("bridge_width %s exceeds the guaranteed block overlap %s" % [bridge_width, 2.0 * minf(core.x, core.z)])
	return errors
