class_name HeadquartersRoom
extends Resource

enum Role { CONTROL, HR, FINANCE, MECHANICAL, ECOLOGY, OUTREACH, RECORDS, RESEARCH }
enum Gate { NONE, RESTORATION, OUTREACH }

@export var id: StringName
@export var label: String
@export var role: Role
@export var costs: PackedInt32Array
@export var capacities: PackedInt32Array
@export var income_rates: PackedInt32Array
@export var storage_limits: PackedInt32Array
@export var best_response: PackedInt32Array
@export var tier_unlocks: PackedStringArray
@export var gate: Gate
@export var gate_level := 5
@export var gate_minimum: int

func starts_built() -> bool:
	return costs[0] == 0

func cost(level: int) -> int:
	return _at(costs, level)

func capacity(level: int) -> int:
	return _at(capacities, level)

func income(level: int) -> int:
	return _at(income_rates, level)

func storage(level: int) -> int:
	return _at(storage_limits, level)

func unlocks(level: int) -> PackedStringArray:
	var earned := PackedStringArray()
	for i in mini(level, tier_unlocks.size()):
		if not tier_unlocks[i].is_empty():
			earned.append(tier_unlocks[i])
	return earned

func outreach_change(level: int, grade: StringName) -> int:
	var best := _at(best_response, level)
	match grade:
		&"best":
			return best
		&"acceptable":
			return best / 2
		&"harmful":
			return -best / 4
	return 0

func _at(values: PackedInt32Array, level: int) -> int:
	return values[level - 1] if level >= 1 and level <= values.size() else 0
