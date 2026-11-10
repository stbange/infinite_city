class_name DataTables
extends RefCounted
## Content tables as JSON in res://data/ with a small schema check (spec content-data / Data
## tables). A schema maps keys to a type name ("string", "int", "float", "number", "bool",
## "array", "dict"), to a nested schema (Dictionary) or to [entry schema] for arrays of records.

## Every table and its schema.
const TABLES := {
	"names": {
		"cultures": [{
			"name": "string", "given": "array", "onsets": "array", "vowels": "array",
			"codas": "array", "endings": "array",
		}],
	},
	"eras": {
		"eras": [{
			"kind": "string", "names": "array", "min_years": "int", "max_years": "int",
			"roles": "array", "deeds": "array",
		}],
		"war_names": "dict",
	},
	"factions": {
		"authority_names": "array", "goods": "array", "company_suffix": "dict", "faith_names": "array",
		"society_names": "array", "gang_first": "array", "gang_second": "array", "party_names": "array",
		"guild_names": "array", "local_faith_names": "array", "local_company_suffix": "array",
		"colors": "array", "reach_words": "array",
	},
	"events": {"templates": "dict"},
}

static var _cache: Dictionary = {}


class TableResult:
	extends RefCounted
	var data: Variant = null
	var problems := PackedStringArray()


static func load_table(table: String) -> TableResult:
	if _cache.has(table):
		return _cache[table]
	var result := TableResult.new()
	var path := "res://data/%s.json" % table
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		result.problems.append("%s: missing or empty" % path)
		return result
	var json := JSON.new()
	if json.parse(text) != OK:
		result.problems.append("%s: line %d: %s" % [path, json.get_error_line(), json.get_error_message()])
		return result
	result.data = json.data
	result.problems = check(json.data, TABLES.get(table, {}))
	_cache[table] = result
	return result


## Problems of `data` against `schema`; `data` may be a record or an array of records.
static func check(data: Variant, schema: Dictionary, where: String = "") -> PackedStringArray:
	var problems := PackedStringArray()
	if data is Array:
		var i := 0
		for entry: Variant in data:
			problems.append_array(check(entry, schema, "%s[%d]" % [where, i]))
			i += 1
		return problems
	if not data is Dictionary:
		problems.append("%s: expected a record" % where)
		return problems
	var record: Dictionary = data
	for key: String in schema:
		var path := "%s.%s" % [where, key] if not where.is_empty() else key
		if not record.has(key):
			problems.append("%s: missing" % path)
			continue
		var expected: Variant = schema[key]
		var value: Variant = record[key]
		if expected is Dictionary:
			problems.append_array(check(value, expected, path))
		elif expected is Array:
			if not value is Array:
				problems.append("%s: expected an array" % path)
			else:
				problems.append_array(check(value, (expected as Array)[0], path))
		elif not _is_type(value, expected):
			problems.append("%s: expected %s, got %s" % [path, expected, type_string(typeof(value))])
	return problems


static func _is_type(value: Variant, type_name: String) -> bool:
	match type_name:
		"string":
			return value is String
		"int":
			return value is int or (value is float and is_equal_approx(value, roundf(value)))
		"float", "number":
			return value is float or value is int
		"bool":
			return value is bool
		"array":
			return value is Array
		"dict":
			return value is Dictionary
	return false
