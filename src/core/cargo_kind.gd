class_name CargoKind
extends RefCounted
## Cargo tiers (spec courier-progression / Licences and cargo tiers): what is carried, its tier, the
## pay multiplier and the gang interest (heat) it draws while carried.

const TABLE := {
	"food": {"tier": 1, "pay": 1.0, "heat": 0.0, "labels": []},
	"parcel": {"tier": 2, "pay": 1.6, "heat": 0.0, "labels": ["a sealed parcel", "a box of spare parts", "a letter bundle"]},
	"medicine": {"tier": 2, "pay": 1.8, "heat": 0.1, "labels": ["insulin packs", "a cooler of antibiotics", "blight tonic"]},
	"contraband": {"tier": 3, "pay": 2.6, "heat": 0.5, "labels": ["unmarked crates", "untaxed seed", "a bag that clinks"]},
	"data": {"tier": 3, "pay": 2.3, "heat": 0.3, "labels": ["a shielded drive", "council ledgers", "a sealed memory card"]},
	"person": {"tier": 4, "pay": 3.2, "heat": 0.2, "labels": ["a witness who must not be seen", "a runaway apprentice", "a council candidate"]},
}


static func tier(kind: String) -> int:
	return int(TABLE.get(kind, TABLE["food"])["tier"])


static func pay(kind: String) -> float:
	return float(TABLE.get(kind, TABLE["food"])["pay"])


static func heat(kind: String) -> float:
	return float(TABLE.get(kind, TABLE["food"])["heat"])


## Kinds of exactly a tier, in a fixed order.
static func kinds_of_tier(t: int) -> Array[String]:
	var result: Array[String] = []
	for kind: String in ["food", "parcel", "medicine", "contraband", "data", "person"]:
		if tier(kind) == t:
			result.append(kind)
	return result


## Encounter heat added by everything carried.
static func total_heat(jobs: Array[DeliveryJob]) -> float:
	var total := 0.0
	for job in jobs:
		total += heat(job.cargo_kind)
	return total


## Kinds a checkpoint scan finds (spec checkpoints).
static func is_contraband(kind: String) -> bool:
	return kind == "contraband" or kind == "data"
