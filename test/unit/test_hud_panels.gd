extends GutTest
## Spec hud-panels: Messages.


func test_messages_show_briefly() -> void:
	var queue := MessageQueue.new()
	queue.push("shop", "Bought: scanner", 0.0)
	queue.push("shop", "Bought: scanner", 1.0)
	queue.push("tools", "Scanner: out of range", 2.0)
	assert_eq(queue.lines(2.5), PackedStringArray(["Bought: scanner", "Scanner: out of range"]))
	assert_eq(queue.lines(7.0), PackedStringArray(["Scanner: out of range"]), "older messages fade")
	assert_eq(queue.lines(9.0).size(), 0)
	for i in 6:
		queue.push("hazards", "Rescue %d" % i, 10.0)
	assert_eq(queue.lines(10.0).size(), MessageQueue.MAX_LINES)
	assert_eq(queue.lines(10.0)[-1], "Rescue 5")


func test_one_city_per_process() -> void:
	assert_same(SharedCity.population(), SharedCity.population())
	assert_same(SharedCity.population().layout, SharedCity.layout())
