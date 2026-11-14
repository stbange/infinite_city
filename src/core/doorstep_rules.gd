class_name DoorstepRules
extends RefCounted
## Who answers the door when a delivery arrives (spec doorsteps): the customer when their routine
## says they are home and awake; slowly, for a smaller tip, when asleep; a household member awake at
## home when the customer is away; otherwise the bag is left at the door for a small tip.

const TIP_FACTORS := {"home": 1.0, "asleep": 0.5, "household": 0.8, "left": 0.3}
const SALT_LINE := 210


## {state, who (PersonId or null), tip (factor of the tip), line}.
static func answer(population: Population, routines: Routines, customer: PersonId, minute: int) -> Dictionary:
	var step := routines.at(customer, minute)
	var person := population.person(customer)
	var state := "left"
	var who: PersonId = null
	if step.activity == "at home":
		state = "home"
		who = customer
	elif step.activity == "sleeping":
		state = "asleep"
		who = customer
	else:
		var cell := customer.cell(population.layout)
		for member in population.residents(cell, customer.floor_index(), customer.unit_index()):
			if member.id.equals(customer):
				continue
			var their := routines.at(member.id, minute)
			if their.activity == "at home":
				state = "household"
				who = member.id
				break
	var speaker := population.person(who) if who != null else person
	return {"state": state, "who": who, "tip": float(TIP_FACTORS[state]), "line": line(population, state, speaker, minute)}


static func line(population: Population, state: String, speaker: PersonInfo, minute: int) -> String:
	var lines: Array = (DataTables.load_table("lines").data["doorstep"] as Dictionary)[state]
	var seed_value := DetHash.hash2(population.world_seed(), SALT_LINE, speaker.id.local if speaker != null else 0, minute)
	var text: String = lines[seed_value % lines.size()]
	return TextTemplate.fill(text, {"name": speaker.full_name() if speaker != null else "the customer"}, seed_value)
