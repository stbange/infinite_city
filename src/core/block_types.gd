class_name BlockTypes
extends RefCounted
## Block functions, their display data and the depth-dependent mix.

enum Kind {
	HOUSING,
	FARM,
	MARKET,
	OFFICE,
	INDUSTRY,
	PARK,
	HOSPITAL,
	FIRE_STATION,
	SECURITY,
	SCHOOL,
	POWER_PLANT,
	WATER_WORKS,
	TRANSIT_HUB,
}

enum DepthBand { SKY, UPPER, MIDDLE, DEEP }

const NONE := -1

## Essential services: exactly one of each per district (spec city-zoning).
const SERVICES: Array[int] = [
	Kind.HOSPITAL, Kind.FIRE_STATION, Kind.SECURITY, Kind.SCHOOL,
	Kind.POWER_PLANT, Kind.WATER_WORKS, Kind.TRANSIT_HUB,
]

## Functions every other block draws from, in the order of the weight tables below.
const GENERAL: Array[int] = [
	Kind.HOUSING, Kind.FARM, Kind.MARKET, Kind.OFFICE, Kind.INDUSTRY, Kind.PARK,
]

## Depth bands (layers below the roof): UPPER 0..23, MIDDLE 24..95, DEEP 96+.
const UPPER_MAX_DEPTH := 23
const MIDDLE_MAX_DEPTH := 95

## Weights aligned with GENERAL: housing, farm, market, office, industry, park.
const _WEIGHTS := {
	DepthBand.SKY: [40.0, 0.0, 25.0, 0.0, 0.0, 35.0],
	DepthBand.UPPER: [38.0, 8.0, 18.0, 18.0, 6.0, 12.0],
	DepthBand.MIDDLE: [32.0, 20.0, 10.0, 14.0, 16.0, 8.0],
	DepthBand.DEEP: [22.0, 30.0, 6.0, 6.0, 30.0, 6.0],
}

const _NAMES := {
	Kind.HOUSING: "Housing",
	Kind.FARM: "Farm",
	Kind.MARKET: "Market",
	Kind.OFFICE: "Office",
	Kind.INDUSTRY: "Industry",
	Kind.PARK: "Park",
	Kind.HOSPITAL: "Hospital",
	Kind.FIRE_STATION: "Fire station",
	Kind.SECURITY: "Security station",
	Kind.SCHOOL: "School",
	Kind.POWER_PLANT: "Power plant",
	Kind.WATER_WORKS: "Water works",
	Kind.TRANSIT_HUB: "Transit hub",
}

const _COLORS := {
	Kind.HOUSING: Color(0.78, 0.70, 0.62),
	Kind.FARM: Color(0.35, 0.75, 0.40),
	Kind.MARKET: Color(0.95, 0.62, 0.25),
	Kind.OFFICE: Color(0.45, 0.62, 0.85),
	Kind.INDUSTRY: Color(0.55, 0.50, 0.48),
	Kind.PARK: Color(0.30, 0.85, 0.55),
	Kind.HOSPITAL: Color(0.96, 0.96, 0.98),
	Kind.FIRE_STATION: Color(0.90, 0.20, 0.15),
	Kind.SECURITY: Color(0.20, 0.35, 0.90),
	Kind.SCHOOL: Color(0.95, 0.85, 0.30),
	Kind.POWER_PLANT: Color(0.85, 0.40, 0.95),
	Kind.WATER_WORKS: Color(0.25, 0.80, 0.90),
	Kind.TRANSIT_HUB: Color(0.70, 0.40, 1.00),
}


static func is_service(kind: int) -> bool:
	return SERVICES.has(kind)


static func display_name(kind: int) -> String:
	return _NAMES.get(kind, "Open air")


static func color(kind: int) -> Color:
	return _COLORS.get(kind, Color.BLACK)


## Band of a layer given its offset from the roof (y - roof_layer).
static func depth_band(y_rel: int) -> int:
	if y_rel > 0:
		return DepthBand.SKY
	var depth := -y_rel
	if depth <= UPPER_MAX_DEPTH:
		return DepthBand.UPPER
	if depth <= MIDDLE_MAX_DEPTH:
		return DepthBand.MIDDLE
	return DepthBand.DEEP


## Weights aligned with GENERAL for the given band.
static func general_weights(band: int) -> PackedFloat32Array:
	return PackedFloat32Array(_WEIGHTS[band])
