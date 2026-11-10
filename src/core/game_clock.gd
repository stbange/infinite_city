class_name GameClock
extends RefCounted
## Game time (spec game-time): whole game minutes since year 0, 365-day years, 7-day weeks.
## The Light is bright from 07:00 to 21:00, dark from 23:00 to 05:00, fading in between.

const MINUTES_PER_DAY := 1440
const DAYS_PER_YEAR := 365
const MINUTES_PER_YEAR := MINUTES_PER_DAY * DAYS_PER_YEAR
const START_YEAR := 517
const START_MINUTE_OF_DAY := 7 * 60
## Default speed: one game day per 48 real minutes.
const DEFAULT_SPEED := 0.5
const WEEKDAYS: Array[String] = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

var total_minutes: int = 0
## Game minutes per real second.
var speed: float = DEFAULT_SPEED
var _fraction: float = 0.0


static func new_game() -> GameClock:
	var clock := GameClock.new()
	clock.total_minutes = START_YEAR * MINUTES_PER_YEAR + START_MINUTE_OF_DAY
	return clock


static func at(minutes: int) -> GameClock:
	var clock := GameClock.new()
	clock.total_minutes = minutes
	return clock


func year() -> int:
	return total_minutes / MINUTES_PER_YEAR


## Day of the year, counted from 1.
func day() -> int:
	return (total_minutes % MINUTES_PER_YEAR) / MINUTES_PER_DAY + 1


func minute_of_day() -> int:
	return total_minutes % MINUTES_PER_DAY


func hour() -> int:
	return minute_of_day() / 60


func minute() -> int:
	return minute_of_day() % 60


## 0 = Mon … 6 = Sun.
func weekday() -> int:
	return (total_minutes / MINUTES_PER_DAY) % 7


## Whole days since year 0 (useful as a seed for daily events).
func day_number() -> int:
	return total_minutes / MINUTES_PER_DAY


func add_minutes(minutes: int) -> void:
	total_minutes += minutes


## Advances by real seconds at the clock's speed; fractions of a minute carry over.
func advance_real(seconds: float) -> void:
	_fraction += seconds * speed
	var whole := floori(_fraction)
	total_minutes += whole
	_fraction -= whole


func light_level() -> float:
	return light_at(minute_of_day())


## Brightness of the Light at a minute of the day (0 dark … 1 bright).
static func light_at(minute_of_day_value: int) -> float:
	var m := float(minute_of_day_value)
	var dawn := smoothstep(5.0 * 60.0, 7.0 * 60.0, m)
	var dusk := 1.0 - smoothstep(21.0 * 60.0, 23.0 * 60.0, m)
	return minf(dawn, dusk)


func describe() -> String:
	return "Year %d · Day %d · %s %02d:%02d" % [year(), day(), WEEKDAYS[weekday()], hour(), minute()]
