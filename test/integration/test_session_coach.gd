extends GutTest
## Specs first-night-guide (Guide in play) and economy-tables (Session stats) through the coach node.

var session: GameSession
var jobs: JobManager
var panel: DialoguePanel
var shop: CourierShop
var coach: SessionCoach


func before_each() -> void:
	var root := Node.new()
	session = GameSession.new()
	session.name = "GameSession"
	session.running = false
	root.add_child(session)
	jobs = JobManager.new()
	jobs.name = "JobManager"
	root.add_child(jobs)
	panel = DialoguePanel.new()
	panel.name = "DialoguePanel"
	root.add_child(panel)
	shop = CourierShop.new()
	shop.name = "CourierShop"
	root.add_child(shop)
	shop.jobs_path = NodePath("../JobManager")
	shop.panel_path = NodePath("../DialoguePanel")
	coach = SessionCoach.new()
	coach.name = "SessionCoach"
	root.add_child(coach)
	coach.session_path = NodePath("../GameSession")
	coach.jobs_path = NodePath("../JobManager")
	coach.panel_path = NodePath("../DialoguePanel")
	coach.shop_path = NodePath("../CourierShop")
	add_child_autofree(root)


func test_guide_in_play() -> void:
	coach.update()
	assert_string_contains("\n".join(coach.hud_lines()), "take an order")
	var job := DeliveryJob.new()
	job.id = "a"
	job.base_pay = 20
	job.picked_minute = session.clock.total_minutes
	jobs.carried.append(job)
	coach.update()
	assert_eq(coach.stats.orders_taken, 1)
	assert_string_contains("\n".join(coach.hud_lines()), "deliver")
	jobs.carried.clear()
	jobs.delivered.emit(job)
	assert_eq(coach.stats.deliveries, 1)
	assert_gt(coach.stats.earnings, 0)
	panel.open("A scene", PackedStringArray(["ok"]))
	panel.choose(0)
	shop.open()
	coach.update()
	assert_true(coach.guide.is_finished())
	coach.stats_visible = true
	assert_string_contains("\n".join(coach.hud_lines()), "delivered 1")
