class_name EncounterRules
extends RefCounted
## What a gang does when the courier crosses its bridge (spec encounters).

const SALT_ENCOUNTER := 171
const SALT_TALK := 172
const SALT_CHECKPOINT := 173
static var TOLL_CHANCE: float:
	get:
		return Economy.num("encounters", "toll_chance")
static var SHAKEDOWN_CHANCE: float:
	get:
		return Economy.num("encounters", "shakedown_chance")
static var HEAT_SHAKEDOWN: float:
	get:
		return Economy.num("encounters", "heat_shakedown")
static var TALK_CHANCE: float:
	get:
		return Economy.num("encounters", "talk_chance")
static var HEAT_TALK: float:
	get:
		return Economy.num("encounters", "heat_talk")
## Chase: gang pace (m/s), catch and escape distances, how long they keep at it (s).
static var GANG_SPEED: float:
	get:
		return Economy.num("encounters", "gang_speed")
static var CATCH_DISTANCE: float:
	get:
		return Economy.num("encounters", "catch_distance")
static var ESCAPE_DISTANCE: float:
	get:
		return Economy.num("encounters", "escape_distance")
static var CHASE_SECONDS: float:
	get:
		return Economy.num("encounters", "chase_seconds")
## Heat added for running and for not paying in full.
static var RUN_HEAT: float:
	get:
		return Economy.num("encounters", "run_heat")
static var SHORT_HEAT: float:
	get:
		return Economy.num("encounters", "short_heat")


static func toll(cargo: int, heat: float) -> int:
	return roundi((Economy.num("encounters", "toll_base") + Economy.num("encounters", "toll_per_order") * cargo) * (1.0 + heat))


## "pass", "toll" or "shakedown" for a bridge in a game hour (hours since year 0).
static func roll(seed_value: int, bridge: BridgeInfo, hour: int, cargo: int, heat: float) -> String:
	if cargo <= 0:
		return "pass"
	var c := bridge.cell_a
	var u := DetHash.u01(DetHash.hash4(seed_value, SALT_ENCOUNTER, c.x, c.y, c.z, bridge.axis * 1000003 + hour))
	var shakedown := SHAKEDOWN_CHANCE + HEAT_SHAKEDOWN * minf(heat, 1.0)
	if u < shakedown:
		return "shakedown"
	if u < shakedown + TOLL_CHANCE:
		return "toll"
	return "pass"


static func talk_succeeds(seed_value: int, bridge: BridgeInfo, hour: int, heat: float) -> bool:
	var c := bridge.cell_a
	var u := DetHash.u01(DetHash.hash4(seed_value, SALT_TALK, c.x, c.y, c.z, bridge.axis * 1000003 + hour))
	return u < TALK_CHANCE - HEAT_TALK * minf(heat, 1.0)


## Whether the Authority runs a checkpoint on a bridge: some bridges of the top layers below the
## roof (spec checkpoints).
static func is_checkpoint(seed_value: int, bridge: BridgeInfo, roof_layer: int) -> bool:
	var depth := roof_layer - bridge.cell_a.y
	if depth < 0 or depth >= Economy.whole("checkpoints", "layers"):
		return false
	var c := bridge.cell_a
	return DetHash.u01(DetHash.hash4(seed_value, SALT_CHECKPOINT, c.x, c.y, c.z, bridge.axis)) < Economy.num("checkpoints", "share")


## What a checkpoint wants from a courier: {kind: "pass" | "permit" | "contraband", price}.
static func checkpoint(carried: Array[DeliveryJob], light_rights: bool) -> Dictionary:
	if carried.is_empty():
		return {"kind": "pass", "price": 0}
	for job in carried:
		if CargoKind.is_contraband(job.cargo_kind):
			return {"kind": "contraband", "price": roundi(toll(carried.size(), 0.0) * Economy.num("checkpoints", "bribe_factor"))}
	if light_rights:
		return {"kind": "pass", "price": 0}
	return {"kind": "permit", "price": Economy.whole("checkpoints", "permit")}
