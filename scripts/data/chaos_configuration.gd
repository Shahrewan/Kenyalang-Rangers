class_name ChaosConfiguration
extends RefCounted

const WAVE_SLOTS := 5
const ENEMIES_PER_WAVE := 50
const ROUTES := {
	&"T01": "Forgotten Patrol",
	&"T02": "Gunung Mulu · Ridge Route",
	&"T03": "Batang Ai",
	&"T04": "Tanjung Datu",
	&"T05": "Imbak Canyon",
	&"T06": "Sepilok-Kabili",
}

var route_id: StringName = &"T02"
var _roster: Dictionary[StringName, BattleEnemyDefinition] = {}
var _slots: Array[Dictionary] = []

func _init() -> void:
	for enemy in CampaignContent.ENEMIES.entries + CampaignContent.BOSSES.entries:
		_roster[enemy.enemy_id] = enemy
	for slot in WAVE_SLOTS:
		_slots.append({})

func select_route(id: StringName) -> bool:
	if not ROUTES.has(id):
		return false
	route_id = id
	return true

func route_label() -> String:
	return ROUTES[route_id]

func enemies() -> Array[BattleEnemyDefinition]:
	var result: Array[BattleEnemyDefinition] = []
	result.assign(_roster.values())
	return result

func quantity(slot: int, enemy_id: StringName) -> int:
	return _slots[slot].get(enemy_id, 0) if _valid_slot(slot) else 0

func wave_size(slot: int) -> int:
	var total := 0
	if _valid_slot(slot):
		for count: int in _slots[slot].values():
			total += count
	return total

func wave_points(slot: int) -> int:
	var total := 0
	if _valid_slot(slot):
		for id: StringName in _slots[slot]:
			total += _slots[slot][id] * _roster[id].chaos_points
	return total

func capacity_for(slot: int, enemy_id: StringName) -> int:
	return ENEMIES_PER_WAVE - wave_size(slot) + quantity(slot, enemy_id) if _valid_slot(slot) and _roster.has(enemy_id) else 0

func set_quantity(slot: int, enemy_id: StringName, requested: int) -> int:
	if not _valid_slot(slot) or not _roster.has(enemy_id):
		return 0
	var count := clampi(requested, 0, capacity_for(slot, enemy_id))
	if count == 0:
		_slots[slot].erase(enemy_id)
	else:
		_slots[slot][enemy_id] = count
	return count

func build_stage() -> BattleStage:
	var template: BattleStage = CampaignContent.MAPS[route_id]
	var stage := BattleStage.new()
	stage.stage_id = route_id
	stage.map = template.map
	stage.routes = template.routes
	stage.opening_delay_seconds = 18.0
	if route_id == &"T05":
		stage.heat_capacity = 100
		stage.heat_integrity_loss = 10
	for slot in WAVE_SLOTS:
		if _slots[slot].is_empty():
			continue
		var wave := BattleWave.new()
		wave.rest_after_seconds = 18.0
		for id: StringName in _roster:
			if not _slots[slot].has(id):
				continue
			var group := BattleSpawnGroup.new()
			group.enemy = _roster[id]
			group.count = quantity(slot, id)
			group.route_index = (stage.waves.size() + wave.groups.size()) % stage.routes.size()
			group.interval_seconds = 2.5
			wave.groups.append(group)
		stage.waves.append(wave)
	return stage

func save_data() -> Dictionary:
	var waves: Array[Dictionary] = []
	for slot in _slots:
		var counts := {}
		for id: StringName in slot:
			counts[String(id)] = slot[id]
		waves.append(counts)
	return {"route": String(route_id), "waves": waves}

static func from_data(data: Dictionary) -> ChaosConfiguration:
	var route: Variant = data.get("route")
	var waves: Variant = data.get("waves")
	if not route is String or not waves is Array or waves.size() != WAVE_SLOTS:
		return null
	var configuration := ChaosConfiguration.new()
	if not configuration.select_route(StringName(route)):
		return null
	for index in WAVE_SLOTS:
		var counts: Variant = waves[index]
		if not counts is Dictionary:
			return null
		for key: Variant in counts:
			if not key is String:
				return null
			var id := StringName(key)
			var amount: Variant = counts[key]
			if not ProfileFile.whole_between(amount, 1, configuration.capacity_for(index, id)):
				return null
			configuration.set_quantity(index, id, int(amount))
	return configuration

func _valid_slot(slot: int) -> bool:
	return slot >= 0 and slot < WAVE_SLOTS
