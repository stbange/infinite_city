class_name PlayStats
extends RefCounted
## What a session of play produced (spec economy-tables / Session stats): orders, deliveries,
## earnings, tolls, rescues and time per delivery, to compare playtests and tune the table.

var started_minute: int = -1
var orders_taken: int = 0
var deliveries: int = 0
var earnings: int = 0
var tolls_paid: int = 0
var rescues: int = 0
var delivery_minutes: Array[int] = []


func start(minute: int) -> void:
	if started_minute < 0:
		started_minute = minute


func order_taken() -> void:
	orders_taken += 1


func delivered(pay: int, picked_minute: int, minute: int) -> void:
	deliveries += 1
	earnings += pay
	delivery_minutes.append(maxi(0, minute - picked_minute))


func toll(amount: int) -> void:
	tolls_paid += amount


func rescued() -> void:
	rescues += 1


func per_game_hour(count: int, minute: int) -> float:
	var hours := maxf(1.0 / 60.0, float(minute - started_minute) / 60.0)
	return float(count) / hours


func average_delivery_minutes() -> float:
	if delivery_minutes.is_empty():
		return 0.0
	var total := 0
	for m in delivery_minutes:
		total += m
	return float(total) / delivery_minutes.size()


func lines(minute: int) -> PackedStringArray:
	return PackedStringArray([
		"Session: %d game min" % maxi(0, minute - started_minute),
		"Orders %d · delivered %d (%.1f per game hour)" % [orders_taken, deliveries, per_game_hour(deliveries, minute)],
		"Earned ¤%d (¤%.0f per game hour) · tolls ¤%d · rescues %d" % [earnings, per_game_hour(earnings, minute), tolls_paid, rescues],
		"Average delivery %.0f game min" % average_delivery_minutes(),
	])
