class_name ShopCatalogue
extends RefCounted
## Tools for sale (spec courier-progression / Shop).

const TOOLS := {
	"scanner": {"price": 60, "licence": "bronze", "consumable": false, "label": "Scanner (R: beacon at the next door)"},
	"flare": {"price": 20, "licence": "bronze", "consumable": true, "label": "Flare (X: end a chase)"},
	"glider": {"price": 180, "licence": "silver", "consumable": false, "label": "Glider (hold Space while falling)"},
	"grapple": {"price": 240, "licence": "silver", "consumable": false, "label": "Grapple (G: pull up to 20 m)"},
}
const ORDER: Array[String] = ["scanner", "flare", "glider", "grapple"]


static func can_buy(tool: String, licence: String, credits: int, owned: Dictionary) -> bool:
	if not TOOLS.has(tool):
		return false
	var spec: Dictionary = TOOLS[tool]
	if Licence.LEVELS.find(licence) < Licence.LEVELS.find(spec["licence"]):
		return false
	if credits < int(spec["price"]):
		return false
	return bool(spec["consumable"]) or not owned.has(tool)
