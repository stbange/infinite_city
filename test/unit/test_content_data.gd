extends GutTest
## Spec content-data: Data tables, Generated names, Text templates, Unique salts.


func test_all_tables_are_valid() -> void:
	for table: String in DataTables.TABLES:
		var result := DataTables.load_table(table)
		assert_eq(result.problems, PackedStringArray(), "table %s" % table)
		assert_not_null(result.data, "table %s" % table)


func test_problems_are_reported() -> void:
	var schema := {"name": "string", "size": "int"}
	var missing := DataTables.check({"name": "x"}, schema)
	assert_eq(missing.size(), 1)
	assert_string_contains(missing[0], "size")
	var wrong := DataTables.check([{"name": "x", "size": "big"}], schema)
	assert_eq(wrong.size(), 1)
	assert_string_contains(wrong[0], "size")
	assert_eq(DataTables.check([{"name": "x", "size": 3}], schema), PackedStringArray())


func test_same_id_same_name() -> void:
	var a := NameGenerator.new(1337)
	var b := NameGenerator.new(1337)
	for id in 1000:
		var culture := id % a.culture_count()
		assert_eq(a.full_name(culture, id), b.full_name(culture, id))


func test_varied_names() -> void:
	var names := NameGenerator.new(1337)
	var seen := {}
	var letters := RegEx.create_from_string("^[A-Za-z' -]+$")
	for id in 1000:
		var given := names.given_name(0, id)
		var family := names.family_name(0, id)
		for part: String in [given, family]:
			assert_between(part.length(), 2, 14, part)
			assert_not_null(letters.search(part), part)
		seen[given + " " + family] = true
	assert_gte(seen.size(), 600)


func test_cultures_differ() -> void:
	var names := NameGenerator.new(1337)
	assert_gte(names.culture_count(), 4)
	var first := {}
	var second := {}
	for id in 200:
		first[names.family_name(0, id)] = true
		second[names.family_name(1, id)] = true
	var shared := 0
	for name: String in first:
		if second.has(name):
			shared += 1
	assert_lt(shared, 20)


func test_slots_and_variants() -> void:
	var values := {"who": {"first": "Ma"}}
	for seed: int in [1, 2, 3, 4]:
		var text := TextTemplate.fill("[Hi|Hello] {who.first}", values, seed)
		assert_true(text == "Hi Ma" or text == "Hello Ma", text)
		assert_eq(TextTemplate.fill("[Hi|Hello] {who.first}", values, seed), text)
	var all := {}
	for seed: int in 20:
		all[TextTemplate.fill("[a|b|c]", {}, seed)] = true
	assert_eq(all.size(), 3)
	assert_eq(TextTemplate.fill("{missing.key}!", {}, 0), "?!")


func test_no_two_salts_agree() -> void:
	var seen := {}
	var dir := DirAccess.open("res://src/core")
	for file in dir.get_files():
		if not file.ends_with(".gd"):
			continue
		var script := load("res://src/core/" + file) as Script
		var constants := script.get_script_constant_map()
		for key: String in constants:
			if key.begins_with("SALT_"):
				var value: int = constants[key]
				assert_false(seen.has(value), "%s.%s = %d also used by %s" % [file, key, value, seen.get(value, "")])
				seen[value] = "%s.%s" % [file, key]
	assert_gt(seen.size(), 8)
