class_name TextTemplate
extends RefCounted
## Fills "{path.to.value}" slots and picks one option of each "[a|b|c]" group (spec content-data
## / Text templates). Missing values become "?".

const SALT_TEXT := 102

static var _slot := RegEx.create_from_string("\\{([A-Za-z0-9_.]+)\\}")
static var _group := RegEx.create_from_string("\\[([^\\[\\]]*\\|[^\\[\\]]*)\\]")


static func fill(text: String, values: Dictionary, seed_value: int) -> String:
	var result := ""
	var cursor := 0
	var index := 0
	for found in _group.search_all(text):
		result += text.substr(cursor, found.get_start() - cursor)
		var options := found.get_string(1).split("|")
		var rng := CellRandom.new(DetHash.hash2(seed_value, SALT_TEXT, index, options.size()))
		result += options[rng.next_int(options.size())]
		cursor = found.get_end()
		index += 1
	result += text.substr(cursor)
	var filled := ""
	cursor = 0
	for found in _slot.search_all(result):
		filled += result.substr(cursor, found.get_start() - cursor) + str(_lookup(values, found.get_string(1)))
		cursor = found.get_end()
	return filled + result.substr(cursor)


static func _lookup(values: Dictionary, path: String) -> Variant:
	var current: Variant = values
	for key in path.split("."):
		if current is Dictionary and (current as Dictionary).has(key):
			current = current[key]
		else:
			return "?"
	return current
