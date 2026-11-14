class_name SharedCity
extends RefCounted
## One default city per test process (spec test-suite / Shared city): layout, chronicle and
## population built once, so unit tests stop rebuilding the same districts and job markets.
## Tests that compare fresh generators for determinism still build their own.

static var _layout: CityLayout
static var _chronicle: CityChronicle
static var _population: Population


static func layout() -> CityLayout:
	if _layout == null:
		_layout = CityLayout.new(CityConfig.new())
	return _layout


static func chronicle() -> CityChronicle:
	if _chronicle == null:
		_chronicle = CityChronicle.new(layout().config)
	return _chronicle


static func population() -> Population:
	if _population == null:
		_population = Population.new(layout(), chronicle())
	return _population
