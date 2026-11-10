class_name EncounterRules
extends RefCounted
## What a gang does when the courier crosses its bridge (spec encounters).

const SALT_ENCOUNTER := 171
const SALT_TALK := 172
const TOLL_CHANCE := 0.55
const SHAKEDOWN_CHANCE := 0.15
const HEAT_SHAKEDOWN := 0.25
const TALK_CHANCE := 0.5
const HEAT_TALK := 0.3
## Chase: gang pace (m/s), catch and escape distances, how long they keep at it (s).
const GANG_SPEED := 6.0
const CATCH_DISTANCE := 1.5
const ESCAPE_DISTANCE := 40.0
const CHASE_SECONDS := 30.0
## Heat added for running and for not paying in full.
const RUN_HEAT := 0.5
const SHORT_HEAT := 0.2


static func toll(cargo: int, heat: float) -> int:
	return roundi((8.0 + 4.0 * cargo) * (1.0 + heat))


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
