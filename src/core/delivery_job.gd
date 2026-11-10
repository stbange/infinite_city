class_name DeliveryJob
extends RefCounted
## A food order from a patron to a customer's door (spec courier-jobs).

var id: String
var pickup: PersonId
var patron_name: String
var dropoff_cell: Vector3i
var dropoff_floor: int
var dropoff_unit: int
var customer: PersonId
var customer_name: String
var cargo: String = "noodles"
## Straight distance between the patron's and the customer's block centres (m), floor difference.
var distance: float = 0.0
var floors: int = 0
var base_pay: int = 0
## Game minute it was picked up, -1 while waiting at the counter.
var picked_minute: int = -1
## Beat of the story this delivery belongs to, or "" for an ordinary order.
var story_beat: String = ""
## Cargo tier kind (CargoKind.TABLE).
var cargo_kind: String = "food"


func to_dict() -> Dictionary:
	return {"id": id, "pickup": pickup.key(), "patron": patron_name,
		"dropoff": [dropoff_cell.x, dropoff_cell.y, dropoff_cell.z, dropoff_floor, dropoff_unit],
		"customer": customer.key(), "customer_name": customer_name, "cargo": cargo,
		"distance": distance, "floors": floors, "base_pay": base_pay, "picked": picked_minute, "story": story_beat, "kind": cargo_kind}


static func from_dict(data: Dictionary) -> DeliveryJob:
	var job := DeliveryJob.new()
	job.id = data["id"]
	job.pickup = PersonId.from_key(data["pickup"])
	job.patron_name = data["patron"]
	var d: Array = data["dropoff"]
	job.dropoff_cell = Vector3i(int(d[0]), int(d[1]), int(d[2]))
	job.dropoff_floor = int(d[3])
	job.dropoff_unit = int(d[4])
	job.customer = PersonId.from_key(data["customer"])
	job.customer_name = data["customer_name"]
	job.cargo = data["cargo"]
	job.distance = float(data["distance"])
	job.floors = int(data["floors"])
	job.base_pay = int(data["base_pay"])
	job.picked_minute = int(data["picked"])
	job.story_beat = str(data.get("story", ""))
	job.cargo_kind = str(data.get("kind", "food"))
	return job
