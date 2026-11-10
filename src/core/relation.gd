class_name Relation
extends RefCounted
## A relation from one person to another (spec relations).

## partner, parent, child, sibling, relative_parent, relative_child, flatmate, neighbour,
## colleague, friend, lover, rival, enemy.
var kind: String
var other: PersonId
var secret: bool = false


func _init(p_kind: String, p_other: PersonId, p_secret: bool = false) -> void:
	kind = p_kind
	other = p_other
	secret = p_secret


## The kind the other person has towards this one.
static func mirror(value: String) -> String:
	match value:
		"parent":
			return "child"
		"child":
			return "parent"
		"relative_parent":
			return "relative_child"
		"relative_child":
			return "relative_parent"
	return value
