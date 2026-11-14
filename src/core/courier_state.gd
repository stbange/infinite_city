class_name CourierState
extends RefCounted
## What the courier owns and is (spec courier-state): wallet, standing with each faction, licence
## and tools, with the shop and licence rules that change them. Saved as its own session part.

var wallet := Wallet.new()
var reputation := Reputation.new()
var licence: String = "bronze"
## Tool -> count (1 for tools that are kept, any number for consumables).
var tools: Dictionary = {}


## Buys a tool from the shop; false when refused.
func buy(tool: String) -> bool:
	if not ShopCatalogue.can_buy(tool, licence, wallet.credits, tools):
		return false
	wallet.credits -= ShopCatalogue.price(tool)
	tools[tool] = int(tools.get(tool, 0)) + 1
	return true


## Upgrades the licence when standing and credits allow; false when refused.
func upgrade_licence() -> bool:
	if not Licence.can_upgrade(licence, reputation, wallet.credits):
		return false
	wallet.credits -= Licence.fee(licence)
	licence = Licence.next_level(licence)
	return true


func has_tool(tool: String) -> bool:
	return int(tools.get(tool, 0)) > 0


## Uses up one consumable; false when none is left.
func use_tool(tool: String) -> bool:
	if not has_tool(tool):
		return false
	tools[tool] = int(tools[tool]) - 1
	if int(tools[tool]) <= 0:
		tools.erase(tool)
	return true


func to_dict() -> Dictionary:
	return {"wallet": wallet.to_dict(), "reputation": reputation.to_dict(), "licence": licence, "tools": tools.duplicate()}


## Also reads the version 2 layout, where these fields sat in the courier part.
func from_dict(data: Dictionary) -> void:
	wallet.from_dict(data.get("wallet", {}))
	reputation.from_dict(data.get("reputation", {}))
	licence = str(data.get("licence", "bronze"))
	tools.clear()
	var owned: Dictionary = data.get("tools", {})
	for tool: String in owned:
		tools[tool] = int(owned[tool])
