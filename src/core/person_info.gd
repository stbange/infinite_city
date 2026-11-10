class_name PersonInfo
extends RefCounted
## A resident of the city (spec residents / Person attributes).

var id: PersonId
var given_name: String
var family_name: String
var age: int
var pronoun: String
var traits := PackedStringArray()
var skill: String
var wealth: float
var health: float
## Faction key of a membership, or "".
var membership: String = ""
var membership_secret: bool = false


func full_name() -> String:
	return "%s %s" % [given_name, family_name]
