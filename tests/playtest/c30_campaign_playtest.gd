extends SceneTree
## Deterministic player actions against the real battle simulation. Profiles
## represent entry to each mission and use only prior Campaign grants.

const POST := &"facility.logistics_post"
const SCOUT := &"ranger.scout_sniper"
const PATROL := &"ranger.patrolman"
const MEDIC := &"ranger.combat_medic"
const GUARD := &"ranger.guard_veteran"
const SONIC := &"facility.sonic_turret"
const TRACKER := &"ranger.woods_tracker"
const K9 := &"ranger.k9_ranger"
const SEER := &"ranger.kenyalang_seer"
const SABOTEUR := &"ranger.saboteurist"
const STRIKE := &"ranger.strike_team"
const FIREBREAK := &"facility.firebreak_beacon"
const LINEUP := [SCOUT, PATROL, GUARD, &"ranger.crowd_controller", MEDIC,
	&"ranger.barricade_ops", &"ranger.outpost_mechanic", POST, SONIC,
	&"facility.canopy_defense_launcher", &"facility.electric_pulse_turret",
	&"facility.medic_cabin", &"facility.reinforced_cover_station"]

var _content := CampaignContent.new()
var _path := "user://c30-playtest-%d.json" % OS.get_process_id()
var _spawned: Array[int] = []
var _orders: Array[Dictionary] = []
var _tactical := false
var _guard_drills := false
var _expanded := false
var _balanced := false
var _advanced := false
var _retreats := 0
var _frontline := false
var _intervention := false
var _trial_firebreak := false
var _earned_trial_firebreak := false
var _late_policy := ""
var _trial_heat := 0.0
var _trial_opening := -1.0
var _trial_intervals: PackedFloat32Array
var _trial_buffs: Array[StringName]
var _proven_profiles := false
var _hold_rangers_seconds := 0.0
var _ranger_level := 1

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	if not _content.error.is_empty():
		printerr(_content.error)
		quit(1)
		return
	var args := OS.get_cmdline_user_args()
	_tactical = "--tactical" in args
	_guard_drills = "--guard-drills" in args
	_expanded = "--expanded-rangers" in args
	_balanced = "--mixed-lineup" in args
	_advanced = "--advanced-loadout" in args
	_frontline = "--frontline" in args
	_intervention = "--intervention" in args
	_trial_firebreak = "--trial-firebreak-award" in args
	_proven_profiles = "--three-tiers" in args
	for arg in args:
		if arg.begins_with("--heat="):
			_trial_heat = arg.get_slice("=", 1).to_float()
		elif arg.begins_with("--opening="):
			_trial_opening = arg.get_slice("=", 1).to_float()
		elif arg.begins_with("--intervals="):
			for interval: String in arg.get_slice("=", 1).split(","):
				_trial_intervals.append(interval.to_float())
		elif arg.begins_with("--hold-rangers="):
			_hold_rangers_seconds = arg.get_slice("=", 1).to_float()
		elif arg.begins_with("--ranger-level="):
			_ranger_level = clampi(arg.get_slice("=", 1).to_int(), 1, DeployableLevels.MAX_LEVEL)
		elif arg.begins_with("--policy="):
			_late_policy = arg.get_slice("=", 1)
		elif arg.begins_with("--buffs="):
			_trial_buffs.assign(Array(arg.get_slice("=", 1).split(",", false)).map(func(id: String) -> StringName: return StringName(id)))
	if _trial_firebreak:
		_earned_trial_firebreak = _earn_trial_firebreak()
		if not _earned_trial_firebreak:
			printerr("The experimental award requires a successful C2-07 playtest.")
			quit(1)
			return
	var stage_ids := Array(args).filter(func(id: String) -> bool: return id.begins_with("C"))
	for operation: StoryOperation in _content.operations:
		if not stage_ids.is_empty() and String(operation.stage.stage_id) not in stage_ids:
			continue
		var tiers := ["low", "progressed", "advanced"] if _proven_profiles else (["advanced" if _advanced else "progressed"] if _tactical else ["low", "progressed"])
		for tier: String in tiers:
			_advanced = tier == "advanced"
			var sample := _play(operation, tier != "low")
			print(JSON.stringify(sample))
	for suffix in ["", ".bak", ".tmp", ".bak.tmp"]:
		if FileAccess.file_exists(_path + suffix):
			DirAccess.remove_absolute(_path + suffix)
	quit()

func _plan(operation: StoryOperation, progressed: bool) -> OperationPlan:
	var profile := CampaignSave.fresh()
	profile.leader_name = "Pacing check"
	if _ranger_level > 1:
		profile.funds = 3 * DeployableLevels.cost(1, _ranger_level)
	profile.rooms["room.control_room"] = operation.min_control_level
	profile.rooms["room.human_resources"] = 4 if progressed else 2
	profile.rooms["room.mechanical"] = 3 if progressed else 1
	for prior: StoryOperation in _content.operations:
		if prior == operation:
			break
		profile.records[String(prior.stage.stage_id)] = {"cleared": true, "perfect": false}
		for id: StringName in prior.clear_unlock_ids:
			profile.owned.append(String(id))
	if progressed:
		profile.deployable_levels[String(POST)] = 30
		if _advanced:
			profile.rooms["room.human_resources"] = 5
			profile.rooms["room.mechanical"] = 4
			# Focus investment on one Facility whose current level actually changes output.
			profile.deployable_levels[String(POST)] = 50
		profile.rooms["room.records"] = 4
		profile.encyclopaedia.perfect_chapters = ["records_chapter.scout_sniper", "records_chapter.combat_medic"]
		profile.rooms["room.r_d_crisis"] = 3
		profile.rooms["room.r_d_combat"] = 4
		profile.rooms["room.r_d_eco"] = 3 if _tactical else 2
		if _guard_drills:
			profile.rooms["room.r_d_guard"] = 4
		if _intervention or &"B14" in _trial_buffs:
			profile.rooms["room.r_d_crisis"] = 4
		if not _late_policy.is_empty():
			profile.rooms["room.r_d_guard"] = 4
			profile.rooms["room.r_d_combat"] = 5
	if _earned_trial_firebreak and operation.stage.stage_id == &"C2-08":
		profile.owned.append(String(FIREBREAK))
	ProfileFile.replace(_path, profile, false)
	var progress := CampaignProgress.new(_path)
	var plan := OperationPlan.new(operation, [])
	plan.configure_campaign(progress, [])
	var lineup := LINEUP
	if _expanded:
		lineup = [GUARD, SCOUT, SEER, K9, MEDIC, STRIKE, SABOTEUR, TRACKER, PATROL,
			&"ranger.crowd_controller", POST, FIREBREAK, &"facility.canopy_defense_launcher",
			&"facility.electric_pulse_turret", SONIC]
		if _balanced:
			lineup = [GUARD, SCOUT, &"ranger.crowd_controller", SEER, K9, STRIKE, SABOTEUR, TRACKER,
				MEDIC, PATROL, POST, FIREBREAK, &"facility.canopy_defense_launcher",
				&"facility.electric_pulse_turret", SONIC]
	if not _late_policy.is_empty():
		lineup = [GUARD, SCOUT, &"ranger.crowd_controller", K9, SEER, STRIKE, MEDIC, TRACKER,
			&"ranger.barricade_ops", SABOTEUR, PATROL, POST, FIREBREAK, SONIC,
			&"facility.electric_pulse_turret", &"facility.reinforced_cover_station", &"facility.medic_cabin"]
		if _late_policy in ["convoy", "convoy-late"]:
			lineup = [GUARD, SCOUT, &"ranger.crowd_controller", K9, STRIKE, &"ranger.barricade_ops",
				MEDIC, SEER, TRACKER, PATROL, POST, SONIC, &"facility.electric_pulse_turret",
				&"facility.reinforced_cover_station", &"facility.medic_cabin"]
	for id in lineup:
		for spec: DeploymentSpec in plan.choices:
			if spec.id == id:
				plan.select_unit(spec, true)
	if _ranger_level > 1:
		var tracks := 0
		var selection := plan.selected_ids.duplicate()
		for id: StringName in selection:
			if not DeployableLevels.definition(id).is_ranger():
				continue
			var error := progress.purchase_levels(id, _ranger_level)
			if not error.is_empty():
				push_error("Could not purchase playtest Ranger levels: " + error)
				break
			tracks += 1
			if tracks == 3:
				break
		plan.configure_campaign(progress, selection)
	if progressed and not _trial_buffs.is_empty():
		for id in _trial_buffs:
			plan.set_modifier(BattleModifiers.CATALOG.definition(id), true)
	elif progressed:
		plan.set_modifier(BattleModifiers.CATALOG.definition(&"B13"), true)
		if _tactical:
			var support := &"B02" if operation.has_heat else (&"B11" if _guard_drills else &"B05")
			if _intervention:
				support = &"B14"
			plan.set_modifier(BattleModifiers.CATALOG.definition(support), true)
	return plan

func _play(operation: StoryOperation, progressed: bool) -> Dictionary:
	var plan := _plan(operation, progressed)
	var resolved := plan.resolved()
	var stage := _trial_stage(resolved.stage)
	var sim := BattleSimulation.new(stage)
	var progress := CampaignProgress.new(_path)
	var entered := progress.begin_attempt(operation)
	var funds_before := progress.funds()
	sim.deployment = DeploymentState.new(resolved.stage.map, sim.clock, resolved.tokens,
		resolved.opening, plan._enhancements, sim.effects)
	_orders.clear()
	_spawned.clear()
	_retreats = 0
	sim.enemy_spawned.connect(_arrived.bind(sim.clock))
	var heat_overflows: Array[int] = []
	var clock := sim.clock
	sim.heat_overflow.connect(func() -> void: heat_overflows.append(clock.tick))
	var wave_peaks: Array[int] = []
	var preparation_tokens := 0
	var paid_cells: Array[Dictionary] = []
	var peak := 0
	var first_wave_escapes := 0
	var opening_peak := 0
	var first_ranger := -1
	var skills := 0
	var boss_phase_ticks: Array[int] = []
	sim.boss_phase_changed.connect(func(_id: int, _phase: BossPhase) -> void: boss_phase_ticks.append(clock.tick))
	for ignored in 90000:
		if sim.clock.stopped:
			break
		if sim.clock.tick % 30 == 0:
			if _deploy(sim, resolved.entries) and first_ranger < 0 and _orders.back().ranger:
				first_ranger = sim.clock.tick
			skills += _skills(sim)
			if _expanded:
				_cycle_specialists(sim)
		if _spawned.is_empty():
			preparation_tokens = sim.deployment.tokens
		sim.clock.advance_frame()
		while wave_peaks.size() < sim.wave_number:
			wave_peaks.append(0)
		wave_peaks[sim.wave_number - 1] = maxi(wave_peaks[sim.wave_number - 1], sim.active.size())
		peak = maxi(peak, sim.active.size())
		if sim.wave_number == 1:
			opening_peak = maxi(opening_peak, sim.active.size())
			first_wave_escapes = sim.escaped
	var counts := {}
	for order in _orders:
		counts[order.id] = counts.get(order.id, 0) + 1
		if order.at < stage.opening_delay_seconds * CombatClock.TICKS_PER_SECOND or order.id == FIREBREAK:
			paid_cells.append(order)
	var result := progress.complete(operation, sim.is_perfect()) if entered and sim.outcome == BattleSimulation.Outcome.WON else {}
	var outcome := {"stage": operation.stage.stage_id, "profile": ("advanced" if _advanced else "progressed") if progressed else "low",
		"legal_plan": resolved.can_start() and entered, "buffs": plan.modifier_selection(), "first_arrival": _spawned[0] if not _spawned.is_empty() else -1,
		"first_ranger": first_ranger, "peak": peak, "wave_1_peak": opening_peak, "wave_1_escapes": first_wave_escapes,
		"outcome": sim.outcome, "perfect": sim.is_perfect(), "integrity": sim.integrity,
		"wave": sim.wave_number, "defeated": sim.defeated, "escaped": sim.escaped, "tick": sim.clock.tick,
		"skills": skills, "deployed": counts, "tokens": sim.deployment.tokens,
		"retreats": _retreats, "loadout": plan.selected_ids, "heat_overflows": heat_overflows.size(),
		"fatal_escape": sim.fatal_escape_id, "boss_escape": sim.escaped_boss_id,
		"heat_scale": stage.heat_gain_scale, "heat_overflow_ticks": heat_overflows, "wave_peaks": wave_peaks,
		"holding_tokens_at_first_spawn": preparation_tokens, "opening_deployments": paid_cells,
		"funds_credited": progress.funds() - funds_before, "pending_awards": result.get("pending_awards", []),
		"firebreak_owned": progress.owns(FIREBREAK), "settled": not result.is_empty(),
		"boss_phase_ticks": boss_phase_ticks}
	if _ranger_level > 1:
		var paid_levels := {}
		for id: StringName in plan.selected_ids:
			var level := progress.deployable_level(id)
			if String(id).begins_with("ranger.") and level > 1:
				paid_levels[id] = level
		outcome["purchased_ranger_levels"] = paid_levels
	return outcome

func _earn_trial_firebreak() -> bool:
	# Reuse the shipped C2-07 clear policy. Only the experimental award differs.
	var args := [_late_policy, _trial_heat, _trial_opening, _trial_intervals, _trial_buffs,
		_tactical, _expanded, _balanced, _advanced, _frontline, _intervention, _guard_drills]
	_late_policy = ""
	_trial_heat = 0.0
	_trial_opening = -1.0
	_trial_intervals = PackedFloat32Array()
	_trial_buffs = []
	_tactical = true
	_expanded = false
	_balanced = false
	_advanced = false
	_frontline = false
	_intervention = false
	_guard_drills = false
	var prior := _content.operation(&"C2-07")
	prior.clear_unlock_ids.append(FIREBREAK)
	var result := _play(prior, true)
	prior.clear_unlock_ids.pop_back()
	_late_policy = args[0]
	_trial_heat = args[1]
	_trial_opening = args[2]
	_trial_intervals = args[3]
	_trial_buffs = args[4]
	_tactical = args[5]
	_expanded = args[6]
	_balanced = args[7]
	_advanced = args[8]
	_frontline = args[9]
	_intervention = args[10]
	_guard_drills = args[11]
	print(JSON.stringify(result))
	return result.get("settled", false) and result.get("firebreak_owned", false)

func _trial_stage(base: BattleStage) -> BattleStage:
	if _trial_heat == 0.0 and _trial_opening < 0.0 and _trial_intervals.is_empty():
		return base
	var stage := base.duplicate() as BattleStage
	if _trial_heat > 0.0:
		stage.heat_gain_scale = _trial_heat * BattleModifiers.new(base.modifier_ids).scale(&"heat_gain_percent")
	if _trial_opening >= 0.0:
		stage.opening_delay_seconds = _trial_opening
	if _trial_intervals.size() == stage.waves.size():
		stage.waves = []
		for i in base.waves.size():
			var wave := base.waves[i].duplicate() as BattleWave
			wave.groups = []
			for original in base.waves[i].groups:
				var group := original.duplicate() as BattleSpawnGroup
				group.interval_seconds = _trial_intervals[i] * BattleModifiers.new(base.modifier_ids).scale(&"spawn_interval_percent")
				wave.groups.append(group)
			stage.waves.append(wave)
	return stage

func _arrived(_id: int, _type: StringName, clock: CombatClock) -> void:
	_spawned.append(clock.tick)

func _deploy(sim: BattleSimulation, entries: Array[DeploymentSpec]) -> bool:
	var state := sim.deployment
	var fielded := {}
	var armed := 0
	for unit: DeploymentState.Placement in state.placed.values():
		fielded[unit.spec.id] = fielded.get(unit.spec.id, 0) + 1
		if unit.spec.attack_damage > 0:
			armed += 1
	var reserve_beacon: bool = _earned_trial_firebreak and sim._stage.stage_id == &"C2-08" and armed >= 4 \
		and fielded.get(FIREBREAK, 0) == 0 and entries.any(func(spec: DeploymentSpec) -> bool: return spec.id == FIREBREAK)
	var best := -INF
	var choice: DeploymentSpec
	var destination := Vector2i.ZERO
	var facing := -1
	for spec: DeploymentSpec in entries:
		if spec.is_ranger() and sim.clock.tick < CombatClock.ticks_for(_hold_rangers_seconds):
			continue
		if state.cooldown_ticks(spec.id) > 0 or (reserve_beacon and spec.id != FIREBREAK):
			continue
		var count: int = fielded.get(spec.id, 0)
		var weight := _tactical_priority(spec, count, armed, sim) if _tactical else _priority(spec, count, armed, sim)
		if not _late_policy.is_empty():
			weight = _late_priority(spec, count, armed, sim, weight)
		if weight < 0 or ((_expanded or not _late_policy.is_empty()) and state.tokens < state.cost_for(spec)):
			continue
		var cells := state.map.ground if spec.uses_ground() else state.map.elevated
		for cell: Vector2i in cells:
			if not state.footprint_error(spec, cell).is_empty():
				continue
			for side in ([-1, 1] if spec.is_melee() else [-1]):
				var coverage := state.coverage(spec, cell, side)
				var score := weight + _site_score(spec, coverage, cell, sim)
				if score >= 0.0 and score > best:
					best = score
					choice = spec
					destination = cell
					facing = side
	if choice == null or not state.deploy(choice, destination, facing).is_empty():
		return false
	_orders.append({"id": choice.id, "ranger": choice.is_ranger(), "cell": [destination.x, destination.y], "facing": facing, "at": sim.clock.tick})
	return true

func _priority(spec: DeploymentSpec, count: int, fighters: int, sim: BattleSimulation) -> float:
	match spec.id:
		POST:
			if sim.deployment.posts_deployed == 0:
				return 300
			if sim._stage.stage_id == &"C1-01" or count >= 3:
				return -1
			if sim.deployment.posts_deployed == 1 and (fighters >= 1 or sim.deployment.tokens >= 30):
				return 134
			return 120 if fighters >= 3 and sim.wave_number < 4 else -1
		TRACKER:
			return 87 - count * 100 if not sim.active.is_empty() else -1
		K9: return 89 - count * 24
		SEER: return 104 - count * 22
		SABOTEUR:
			return 102 - count * 100 if sim.active.values().any(func(e: BattleEnemy) -> bool: return e.definition.technological) else -1
		STRIKE:
			return 117 - count * 100 if sim.active.size() >= 3 else -1
		SCOUT: return 94 - count * 15
		PATROL: return 90 - count * 14 if fighters > 0 else 62
		GUARD: return 110 - count * 17 if fighters > 0 else 72
		MEDIC: return 83 - count * 28 if fighters >= 4 and count < 2 else -1
		FIREBREAK: return 155 - count * 200 if fighters >= 2 else -1
		&"facility.canopy_defense_launcher": return 96 - count * 21 if fighters >= 3 else -1
		&"facility.electric_pulse_turret": return 88 - count * 26 if fighters >= 4 else -1
		SONIC: return 82 - count * 19 if fighters >= 3 else -1
		&"ranger.barricade_ops": return 91 - count * 25 if fighters >= 2 else -1
		&"ranger.crowd_controller": return 99 - count * 18 if fighters > 0 else 77
		&"ranger.outpost_mechanic": return 68 - count * 30 if fighters >= 4 and count < 2 else -1
	return -1

func _tactical_priority(spec: DeploymentSpec, count: int, fighters: int, sim: BattleSimulation) -> float:
	# Save platform space for ranged Rangers and protect their melee line.
	match spec.id:
		POST:
			if sim.deployment.posts_deployed == 0:
				return 300
			if count >= 2:
				return -1
			if sim.deployment.posts_deployed == 1 and (fighters >= 2 or (sim._stage.heat_capacity <= 0.0 and sim.deployment.tokens >= 30)):
				return (96 if _frontline else 124)
			return -1
		SCOUT: return 100 - count * 9
		PATROL: return 87 - count * 18 if fighters > 1 else 62
		MEDIC: return 99 - count * 14 if fighters >= 4 and count < 2 else -1
		&"facility.canopy_defense_launcher":
			return 98 - count * 100 if fighters >= 3 and sim.wave_number < 4 and sim._stage.stage_id != &"C2-10" else -1
		&"facility.electric_pulse_turret":
			return 84 - count * 100 if fighters >= 5 and sim._stage.stage_id != &"C2-10" else -1
		SONIC: return 81 - count * 100 if fighters >= 3 else -1
	return _priority(spec, count, fighters, sim)

func _late_priority(spec: DeploymentSpec, count: int, fighters: int, sim: BattleSimulation, default_weight: float) -> float:
	match spec.id:
		POST:
			if count == 0:
				return 300
			if count < 3 and (fighters >= count or sim.clock.tick < CombatClock.ticks_for(sim._stage.opening_delay_seconds)):
				return 135 - count * 8
			return -1
		FIREBREAK: return 190 if count == 0 and fighters >= 2 else -1
		SONIC: return 107 - count * 100 if fighters >= 3 else -1
		&"facility.electric_pulse_turret": return 108 - count * 100 if fighters >= 4 else -1
		&"facility.medic_cabin": return 99 - count * 100 if fighters >= 5 else -1
		&"ranger.barricade_ops": return 103 - count * 50 if fighters >= 1 else 70
		GUARD: return 114 - count * 11
		K9: return 102 - count * 23
		SCOUT: return 111 - count * 7
		MEDIC: return 107 - count * 25 if fighters >= 3 else -1
		&"ranger.crowd_controller": return 106 - count * 10
		STRIKE: return 115 - count * 170 if sim.active.size() >= 5 else -1
		TRACKER: return 88 - count * 100 if not sim.active.is_empty() else -1
	return default_weight

func _site_score(spec: DeploymentSpec, coverage: Array[Vector2i], cell: Vector2i, sim: BattleSimulation) -> float:
	if spec.logistics_post:
		var path_proximity := 0.0
		for route: BattleRoute in sim._stage.routes:
			for path in route.cells:
				var delta := (cell - path).abs()
				if maxi(delta.x, delta.y) <= 2:
					path_proximity += 1.0
		return -path_proximity * 0.45 - cell.x * 0.03
	var score := 0.0
	var correctly_facing := not spec.is_melee()
	for route: BattleRoute in sim._stage.routes:
		for index in range(1, route.cells.size()):
			if route.cells[index] in coverage:
				var fraction := float(index) / route.cells.size()
				score += 0.9 + (1.0 - fraction) * 3.6 if (_tactical and sim._stage.heat_capacity > 0.0) or _frontline or _late_policy == "convoy" else 0.9 + fraction * 1.2
		if spec.is_melee() or ((_frontline or _late_policy == "convoy") and spec.block_capacity > 0):
			var entry := route.cells.size()
			for occupied: Vector2i in spec.footprint(cell):
				var index := route.cells.find(occupied)
				if index > 0:
					entry = mini(entry, index)
			if entry < route.cells.size() and route.cells[entry - 1] in coverage:
				score += float(route.cells.size() - entry) * 1.7 if (_tactical and sim._stage.heat_capacity > 0.0) or _frontline or _late_policy == "convoy" else float(entry) * 0.6
				correctly_facing = true
	if not correctly_facing:
		return -1000.0
	if spec.id == MEDIC:
		for unit: DeploymentState.Placement in sim.deployment.placed.values():
			if unit.spec.is_ranger() and unit.anchor in coverage:
				score += 4.0 if unit.spec.is_melee() else 1.0
	return score

func _skills(sim: BattleSimulation) -> int:
	var count := 0
	var state := sim.deployment
	for unit: DeploymentState.Placement in state.placed.values():
		if unit.ranger == null or unit.skill_charges <= 0:
			continue
		match unit.spec.id:
			GUARD, &"ranger.crowd_controller", K9, SEER:
				if sim.tap_unit(unit.id):
					count += 1
			SCOUT:
				var threat := -1.0
				var aim := DeploymentState.NO_CELL
				for enemy: BattleEnemy in sim.active.values():
					var cell := enemy.grid_cell()
					if enemy.hp < 25 or not enemy.is_targetable(sim.clock.tick) or not state.can_attack(unit, cell, enemy.definition.aerial):
						continue
					var priority := enemy.distance + float(enemy.definition.heat_per_second) * 3.0
					if priority > threat:
						threat = priority
						aim = cell
				if aim != DeploymentState.NO_CELL and sim.tap_unit(unit.id) and state.select_target(aim) and sim.confirm_skill_target():
					count += 1
			MEDIC:
				for target: DeploymentState.Placement in state.placed.values():
					if target.spec.is_ranger() and target.hp * 2 <= target.spec.max_hp and state.can_attack(unit, target.anchor, false):
						if sim.tap_unit(unit.id) and state.select_target(target.anchor) and sim.confirm_skill_target():
							count += 1
						break
	return count


func _cycle_specialists(sim: BattleSimulation) -> void:
	var state := sim.deployment
	for unit: DeploymentState.Placement in state.placed.values():
		var withdraw := false
		match unit.spec.id:
			TRACKER: withdraw = unit.net_landed and unit.blocking_count == 0 and unit.next_attack_tick <= sim.clock.tick
			SABOTEUR:
				withdraw = unit.hp * 3 < unit.spec.max_hp and sim.active.values().any(
					func(enemy: BattleEnemy) -> bool: return unit.distance_to(enemy.grid_cell()) <= 1)
			STRIKE:
				withdraw = unit.arrival_tick == 0 and unit.blocking_count == 0 and (unit.arrival_rank < 2 or unit.hp * 3 < unit.spec.max_hp)
		if withdraw and state.retreat(unit.id):
			_retreats += 1
