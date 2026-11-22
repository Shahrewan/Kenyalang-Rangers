class_name HeadquartersCatalog
extends Resource

const CONTROL := &"room.control_room"
const HR := &"room.human_resources"
const FINANCE := &"room.finance_room"
const MECHANICAL := &"room.mechanical"
const ECOLOGY := &"room.ecology"
const OUTREACH := &"room.outreach"
const RECORDS := &"room.records"
const MAX_LEVEL := 5

@export var rooms: Array[HeadquartersRoom]

func room(id: StringName) -> HeadquartersRoom:
	for entry in rooms:
		if entry.id == id:
			return entry
	return null

func starting_levels() -> Dictionary:
	var levels := {}
	for entry in rooms:
		levels[String(entry.id)] = 1 if entry.starts_built() else 0
	return levels
