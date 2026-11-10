extends GutTest
## Spec game-time: Game clock, The Light's day and night.


func test_calendar_fields() -> void:
	var clock := GameClock.new_game()
	assert_eq(clock.year(), 517)
	assert_eq(clock.day(), 1)
	assert_eq(clock.hour(), 7)
	var weekday := clock.weekday()
	clock.add_minutes(1000)
	assert_eq([clock.year(), clock.day(), clock.hour(), clock.minute()], [517, 1, 23, 40])
	assert_eq(clock.weekday(), weekday)
	clock.add_minutes(30)
	assert_eq([clock.day(), clock.hour(), clock.minute()], [2, 0, 10])
	assert_eq(clock.weekday(), (weekday + 1) % 7)


func test_year_rollover() -> void:
	var clock := GameClock.new_game()
	clock.add_minutes(365 * GameClock.MINUTES_PER_DAY)
	assert_eq(clock.year(), 518)
	assert_eq(clock.day(), 1)


func test_default_speed() -> void:
	var clock := GameClock.new_game()
	var start := clock.total_minutes
	clock.advance_real(60.0)
	assert_eq(clock.total_minutes - start, 30)
	for i in 120:
		clock.advance_real(0.5)
	assert_eq(clock.total_minutes - start, 60, "fractions accumulate")


func test_brightness_over_a_day() -> void:
	assert_eq(GameClock.light_at(12 * 60), 1.0)
	assert_eq(GameClock.light_at(2 * 60), 0.0)
	assert_between(GameClock.light_at(22 * 60), 0.01, 0.99)
	assert_between(GameClock.light_at(6 * 60), 0.01, 0.99)
	assert_eq(GameClock.light_at(7 * 60), 1.0)
	assert_eq(GameClock.light_at(23 * 60), 0.0)


func test_text_form() -> void:
	var clock := GameClock.new_game()
	assert_string_contains(clock.describe(), "07:00")
	assert_string_contains(clock.describe(), "517")
