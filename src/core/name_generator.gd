class_name NameGenerator
extends RefCounted
## Deterministic names from naming cultures (spec content-data / Generated names). Given names come
## from each culture's list; family names are built from its syllables and endings.

const SALT_NAME := 101
const MAX_LETTERS := 14

var world_seed: int
var _cultures: Array = []


func _init(p_world_seed: int) -> void:
	world_seed = p_world_seed
	var table := DataTables.load_table("names")
	if table.data != null:
		_cultures = table.data["cultures"]


func culture_count() -> int:
	return _cultures.size()


func culture_name(culture: int) -> String:
	return _cultures[culture]["name"]


func given_name(culture: int, id: int) -> String:
	var rng := _rng(culture, id, 1)
	var list: Array = _cultures[culture]["given"]
	return list[rng.next_int(list.size())]


func family_name(culture: int, id: int) -> String:
	var entry: Dictionary = _cultures[culture]
	var rng := _rng(culture, id, 2)
	for attempt in 8:
		var syllables := 1 if rng.next_int(3) > 0 else 2
		var text := ""
		for i in syllables:
			var onset := _pick(entry["onsets"], rng).to_lower()
			if i > 0 and onset.length() > 1:
				onset = onset.substr(onset.length() - 1)
			text += onset + _pick(entry["vowels"], rng)
			if rng.next_int(3) == 0:
				text += _pick(entry["codas"], rng)
		var ending := _pick(entry["endings"], rng)
		if _is_vowel(text[text.length() - 1]) and _is_vowel(ending[0]):
			text = text.substr(0, text.length() - 1)
		text += ending
		if text.length() >= 2 and text.length() <= MAX_LETTERS:
			return text[0].to_upper() + text.substr(1)
	return _pick(entry["onsets"], rng) + "o"


func full_name(culture: int, id: int) -> String:
	return "%s %s" % [given_name(culture, id), family_name(culture, id)]


func _rng(culture: int, id: int, part: int) -> CellRandom:
	return CellRandom.new(DetHash.hash4(world_seed, SALT_NAME, id & 0x7fffffff, id >> 31, culture, part))


static func _pick(list: Array, rng: CellRandom) -> String:
	return list[rng.next_int(list.size())]


static func _is_vowel(letter: String) -> bool:
	return "aeiouy".contains(letter)
