class_name ShopCatalogue
extends RefCounted
## Tools for sale (spec courier-progression / Shop).

const TOOLS := {
	"scanner": {"licence": "bronze", "consumable": false, "label": "Scanner (R: beacon at the next door)"},
	"flare": {"licence": "bronze", "consumable": true, "label": "Flare (X: end a chase)"},
	"glider": {"licence": "silver", "consumable": false, "label": "Glider (hold Space while falling)"},
	"grapple": {"licence": "silver", "consumable": false, "label": "Grapple (G: pull up to 20 m)"},
	"transit_pass": {"licence": "bronze", "consumable": false, "label": "Transit pass (ride the hubs for free)"},
}
const ORDER: Array[String] = ["scanner", "flare", "glider", "grapple", "transit_pass"]


static func can_buy(tool: String, licence: String, credits: int, owned: Dictionary) -> bool:
	if not TOOLS.has(tool):
		return false
	var spec: Dictionary = TOOLS[tool]
	if Licence.LEVELS.find(licence) < Licence.LEVELS.find(spec["licence"]):
		return false
	if credits < price(tool):
		return false
	return bool(spec["consumable"]) or not owned.has(tool)


## Price from the economy table (spec economy-tables).
static func price(tool: String) -> int:
	return Economy.whole("shop", tool)
