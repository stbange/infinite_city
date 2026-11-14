class_name Wallet
extends RefCounted
## The courier's money and weekly rent (spec courier-jobs / Rent).

static var RENT: int:
	get:
		return Economy.whole("rent", "amount")
## Rent falls due on Mondays at 06:00.
static var RENT_MINUTE: int:
	get:
		return Economy.whole("rent", "minute")
const WEEK := 7 * GameClock.MINUTES_PER_DAY

var credits: int = Economy.whole("rent", "start_credits")
var _last_rent_week: int = 0


static func rent_week(clock: GameClock) -> int:
	return floori(float(clock.total_minutes - RENT_MINUTE) / WEEK)


func start(clock: GameClock) -> void:
	_last_rent_week = rent_week(clock)


func update(clock: GameClock) -> void:
	var week := rent_week(clock)
	while _last_rent_week < week:
		_last_rent_week += 1
		credits -= RENT


func to_dict() -> Dictionary:
	return {"credits": credits, "rent_week": _last_rent_week}


func from_dict(data: Dictionary) -> void:
	credits = int(data.get("credits", credits))
	_last_rent_week = int(data.get("rent_week", _last_rent_week))
