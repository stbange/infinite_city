extends GutTest
## Spec courier-progression (Shop, Upgrading the licence) through the shop panel.

var jobs: JobManager
var panel: DialoguePanel
var shop: CourierShop


func before_each() -> void:
	var root := Node.new()
	jobs = JobManager.new()
	jobs.name = "JobManager"
	root.add_child(jobs)
	panel = DialoguePanel.new()
	panel.name = "ShopPanel"
	root.add_child(panel)
	shop = CourierShop.new()
	shop.name = "CourierShop"
	root.add_child(shop)
	shop.jobs_path = NodePath("../JobManager")
	shop.panel_path = NodePath("../ShopPanel")
	add_child_autofree(root)


func test_buying_through_the_shop() -> void:
	var start := ShopCatalogue.price("scanner") + 40
	jobs.courier.wallet.credits = start
	shop.open()
	assert_true(panel.is_open())
	assert_string_contains(panel.text(), "Scanner")
	panel.choose(ShopCatalogue.ORDER.find("scanner"))
	assert_true(jobs.courier.has_tool("scanner"))
	assert_eq(jobs.courier.wallet.credits, 40)
	assert_lt(jobs.courier.wallet.credits, ShopCatalogue.price("glider"))
	shop.open()
	panel.choose(ShopCatalogue.ORDER.find("glider"))
	assert_false(jobs.courier.has_tool("glider"))
	assert_string_contains(shop.last_message, "glider")


func test_licence_upgrade_through_the_shop() -> void:
	jobs.courier.wallet.credits = Licence.fee("bronze") + 50
	shop.open()
	panel.choose(ShopCatalogue.ORDER.size())
	assert_eq(jobs.courier.licence, "bronze")
	jobs.courier.reputation.add(Reputation.MUTUAL, Licence.REQUIREMENTS["silver"]["mutual"])
	shop.open()
	panel.choose(ShopCatalogue.ORDER.size())
	assert_eq(jobs.courier.licence, "silver")
	assert_eq(jobs.courier.wallet.credits, 50)


func test_progress_is_saved() -> void:
	jobs.courier.reputation.add(Reputation.MUTUAL, 12)
	jobs.courier.licence = "silver"
	jobs.courier.tools["flare"] = 3
	var data := JSON.parse_string(JSON.stringify(jobs.courier.to_dict())) as Dictionary
	jobs.courier = CourierState.new()
	jobs.courier.from_dict(data)
	assert_eq(jobs.courier.reputation.of(Reputation.MUTUAL), 12)
	assert_eq(jobs.courier.licence, "silver")
	assert_eq(jobs.courier.tools["flare"], 3)


func test_version_2_courier_parts_still_load() -> void:
	var old := {"wallet": {"credits": 321}, "carried": [], "completed": 4,
		"reputation": {"mutual": 9}, "licence": "silver", "tools": {"scanner": 1}}
	jobs.from_dict(old)
	assert_eq(jobs.completed, 4)
	assert_eq(jobs.courier.wallet.credits, 321)
	assert_eq(jobs.courier.reputation.of(Reputation.MUTUAL), 9)
	assert_eq(jobs.courier.licence, "silver")
	assert_true(jobs.courier.has_tool("scanner"))
