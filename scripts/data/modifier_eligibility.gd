class_name ModifierEligibility
extends RefCounted

const Scope := BattleModifier.AppliesTo

class Encounter:
	var enemy: BattleEnemyDefinition
	var route: BattleRoute

var _stage: BattleStage
var _effects: BattleModifiers
var _state: DeploymentState
var _enhancements: Array[StringName]
var _encounters: Array[Encounter] = []
var _waves: Array[BattleWave] = []
var _spots: Dictionary[DeploymentSpec, Array] = {}
var _usable: Array[DeploymentSpec] = []
var _has_post := false

func _init(stage: BattleStage, entries: Array[DeploymentSpec], state: DeploymentState, effects: BattleModifiers, enhancements: Array[StringName]) -> void:
	_stage = stage
	_state = state
	_effects = effects
	_enhancements = enhancements
	for wave in stage.waves:
		var populated := false
		for group in wave.groups:
			if group.count <= 0:
				continue
			populated = true
			var route := stage.routes[group.route_index]
			_add_encounter(group.enemy, route)
			var boss := group.enemy as BossSpec
			if boss != null:
				for phase in boss.phases:
					if phase.reinforcement_count > 0:
						_add_encounter(phase.reinforcement, route)
		if populated:
			_waves.append(wave)
	for spec in entries:
		var cells := stage.map.ground if spec.is_melee() else stage.map.elevated
		var anchors: Array[Vector2i] = cells.filter(func(cell: Vector2i) -> bool: return state.footprint_error(spec, cell).is_empty())
		if anchors.is_empty():
			continue
		_spots[spec] = anchors
		_has_post = _has_post or spec.logistics_post
	for spec: DeploymentSpec in _spots:
		if (_has_post and state.rules.yield_percent > 0) or state.cost_for(spec) <= state.tokens:
			_usable.append(spec)

func error(modifier: BattleModifier) -> String:
	match modifier.applies_to:
		Scope.WAVES:
			return _unless(_stage.opening_delay_seconds > 0 or _timed_rest(0.0), "Requires time before a populated wave.")
		Scope.HEAT:
			return _unless(_has_heat(), "Requires a Heat-enabled map and an enemy that generates Heat.")
		Scope.CONCEALED:
			return _unless(_encounters.any(func(item: Encounter) -> bool: return item.enemy.concealed), "Requires a concealed enemy in a populated wave.")
		Scope.ORDINARY_ESCAPE:
			return _unless(_changes_escape(modifier), "Requires an ordinary escape with a changed Integrity cost.")
		Scope.RANGER_DAMAGE:
			return _unless(_usable.any(_ranger_damage), "Requires an equipped Ranger that can deal damage on the route.")
		Scope.RANGER_ATTACK:
			return _unless(_usable.any(func(spec: DeploymentSpec) -> bool: return spec.is_ranger() and spec.attack_damage > 0 and _reachable_enemy(spec)), "Requires a Ranger with a reachable auto-attack target.")
		Scope.RANGER_SKILL:
			return _unless(_usable.any(_recharging_ranger_skill), "Requires a usable Ranger skill with a recharge timer. Check Records and Silent Mobilization.")
		Scope.WEAKNESS:
			return _unless(_weakness_available(), "Requires a usable mark, stun, immobilize, slow or Disruption zone and a reachable target.")
		Scope.RANGER:
			return _unless(_usable.any(func(spec: DeploymentSpec) -> bool: return spec.is_ranger() and _take_damage(spec)), "Requires an equipped Ranger that can be hit on the route.")
		Scope.HEALING:
			return _unless(_healing_available(), "Requires Ranger healing and a Ranger that can take damage.")
		Scope.BLOCKING:
			return _unless(_blocking_available(false), "Requires a Ranger able to block a damaging ground threat on the route.")
		Scope.KNOCKDOWN:
			return _unless(_blocking_available(true), "Requires a blockable Knockdown enemy and a Ranger that can be knocked down.")
		Scope.TOKEN_OPENING:
			return _unless(_usable.any(func(spec: DeploymentSpec) -> bool: return not spec.logistics_post and spec.cost > 0) or _repeat_post(), "Requires an affordable paid deployment or a repeatable Post.")
		Scope.REDEPLOYMENT:
			return _unless(_has_post or _usable.any(func(spec: DeploymentSpec) -> bool: return spec.redeploy_seconds > 0 if spec.is_ranger() else spec.build_cooldown_seconds > 0), "Requires a deployable with a cooldown or a generating Post.")
		Scope.POST:
			return _unless(_has_post and _state.rules.yield_percent > 0, "Requires a generating Post with a legal footprint.")
		Scope.ENEMY:
			return _unless(not _encounters.is_empty(), "Requires an enemy in a populated wave.")
		Scope.SMOKE:
			return _unless(_encounters.any(func(item: Encounter) -> bool: return item.enemy.concealed and item.enemy.ability != null and item.enemy.ability.effect == EnemyAbility.Effect.SMOKE), "Requires an enemy with timed smoke concealment.")
		Scope.REST:
			return _unless(_timed_rest(_effects.scale(&"wave_rest_percent")), "Requires a timed rest before another populated wave.")
		Scope.SIEGE:
			return _unless(_usable.any(func(spec: DeploymentSpec) -> bool: return not spec.is_ranger() and _take_damage(spec)), "Requires a Siege enemy that can reach a legal Facility footprint.")
		Scope.CONSTRUCTION:
			return _unless(_usable.any(func(spec: DeploymentSpec) -> bool: return not spec.is_ranger() and not spec.logistics_post and spec.build_seconds > 0) or _repeat_post(), "Requires a possible timed Facility build.")
		Scope.AERIAL:
			return _unless(_encounters.any(func(item: Encounter) -> bool: return item.enemy.aerial), "Requires an aerial enemy in a populated wave.")
		Scope.RANGER_COST:
			return _unless(_usable.any(func(spec: DeploymentSpec) -> bool: return spec.is_ranger() and spec.cost > 0), "Requires a paid Ranger with a legal deployment.")
		Scope.SPAWN_INTERVAL:
			return _unless(_timed_spawns(), "Requires a timed gap between arrivals in a populated wave.")
	return ""

func _add_encounter(enemy: BattleEnemyDefinition, route: BattleRoute) -> void:
	var item := Encounter.new()
	item.enemy = enemy
	item.route = route
	_encounters.append(item)

func _has_heat() -> bool:
	if _stage.heat_capacity <= 0:
		return false
	for item in _encounters:
		if item.enemy.heat_per_second > 0:
			return true
		var boss := item.enemy as BossSpec
		if boss != null and boss.phases.any(func(phase: BossPhase) -> bool: return phase.extra_heat_per_second > 0):
			return true
	return false

func _changes_escape(modifier: BattleModifier) -> bool:
	var others := _effects.ids.duplicate()
	others.erase(modifier.id)
	var without := BattleModifiers.new(others)
	for item in _encounters:
		var enemy := item.enemy
		var fatal := enemy.escape_causes_defeat or enemy.enemy_id == _stage.capture_boss_id
		if not fatal and _effects.escape_penalty(enemy.escape_penalty) != without.escape_penalty(enemy.escape_penalty):
			return true
	return false

func _timed_rest(scale: float) -> bool:
	for i in range(_waves.size() - 1):
		if _different_ticks(_waves[i].rest_after_seconds, scale):
			return true
	return false

func _timed_spawns() -> bool:
	var scale := _effects.scale(&"spawn_interval_percent")
	for wave in _waves:
		var after := 0
		for i in range(wave.groups.size() - 1, -1, -1):
			var group := wave.groups[i]
			if group.count > 0 and (after > 0 or group.count > 1) and _different_ticks(group.interval_seconds, scale):
				return true
			after += group.count
	return false

func _different_ticks(seconds: float, scale: float) -> bool:
	return maxi(1, CombatClock.ticks_for(seconds)) != maxi(1, CombatClock.ticks_for(seconds * scale))

func _ready_ranger_skill(spec: DeploymentSpec) -> bool:
	var ranger := spec as RangerSpec
	if _effects.amount(&"disable_skills") > 0 or ranger == null or ranger.skill == DeploymentSpec.Skill.NONE or ranger.active_skill == null:
		return false
	return (not ranger.active_skill.requires_records or ranger.records_enhancement in _enhancements) and _reachable_enemy(ranger)

func _recharging_ranger_skill(spec: DeploymentSpec) -> bool:
	return _ready_ranger_skill(spec) and (spec as RangerSpec).active_skill.recharge_seconds > 0.0

func _ranger_damage(spec: DeploymentSpec) -> bool:
	if not spec.is_ranger():
		return false
	return (spec.attack_damage > 0 and _reachable_enemy(spec)) or (_ready_ranger_skill(spec) and (spec as RangerSpec).active_skill.damage > 0)

func _reachable_enemy(spec: DeploymentSpec, within: Array[Vector2i] = []) -> bool:
	for anchor: Vector2i in _spots[spec]:
		var covered := _state.coverage(spec, anchor, -1)
		if spec.is_melee():
			covered.append_array(_state.coverage(spec, anchor, 1))
		for item in _encounters:
			if item.enemy.aerial and (spec.is_melee() or not spec.targets_aerial):
				continue
			for cell in item.route.cells:
				if cell in covered and (within.is_empty() or cell in within):
					return true
	return false

func _can_block(spec: DeploymentSpec, item: Encounter) -> bool:
	if spec.block_capacity <= 0 or item.enemy.aerial:
		return false
	for anchor: Vector2i in _spots[spec]:
		for tile in spec.footprint(anchor):
			var route_index := item.route.cells.find(tile)
			if route_index > 0 and route_index < item.route.cells.size() - 1:
				return true
	return false

func _take_damage(spec: DeploymentSpec) -> bool:
	for item in _encounters:
		var profile := item.enemy.attack_profile
		if item.enemy.attack_damage <= 0:
			continue
		if profile == null:
			if _can_block(spec, item):
				return true
		elif DeploymentState.accepts_hit(spec, profile.kind):
			for anchor: Vector2i in _spots[spec]:
				for tile in spec.footprint(anchor):
					for cell in item.route.cells:
						var offset := (tile - cell).abs()
						if maxi(offset.x, offset.y) <= profile.radius:
							return true
	return false

func _weakness_available() -> bool:
	for spec in _usable:
		var facility := spec as FacilitySpec
		if (_ready_ranger_skill(spec) and (spec as RangerSpec).active_skill.effect != RangerSkill.Effect.TREATMENT) or (facility != null and facility.role == FacilitySpec.Role.SONIC_TURRET and _reachable_enemy(facility)):
			if _usable.any(func(attacker: DeploymentSpec) -> bool: return (attacker.attack_damage > 0 and _reachable_enemy(attacker)) or _ranger_damage(attacker)):
				return true
		if facility != null and facility.role == FacilitySpec.Role.DISRUPTION and facility.outgoing_reduction_percent > 0:
			var zone: Array[Vector2i] = []
			for anchor: Vector2i in _spots[facility]:
				zone.append_array(_state.coverage(facility, anchor, 1))
			if not zone.is_empty() and _usable.any(func(attacker: DeploymentSpec) -> bool: return attacker.attack_damage > 0 and _reachable_enemy(attacker, zone)):
				return true
	return false

func _healing_available() -> bool:
	var recipients := _usable.filter(func(spec: DeploymentSpec) -> bool: return spec.is_ranger() and _take_damage(spec))
	for source in _usable:
		var ranger := source as RangerSpec
		var facility := source as FacilitySpec
		var heals := ranger != null and ranger.heal_hp > 0
		heals = heals or (facility != null and facility.heal_per_kit > 0 and _effects.amount(&"disable_skills") == 0)
		if not heals:
			continue
		for target: DeploymentSpec in recipients:
			for anchor: Vector2i in _spots[source]:
				for location: Vector2i in _spots[target]:
					var offset := (anchor - location).abs()
					if maxi(offset.x, offset.y) <= source.attack_range:
						return true
	return false

func _blocking_available(needs_knockdown: bool) -> bool:
	for spec in _usable:
		if needs_knockdown and spec.id == &"ranger.barricade_ops":
			continue
		for item in _encounters:
			var ability := item.enemy.ability
			var matches := ability != null and ability.effect == EnemyAbility.Effect.KNOCKDOWN if needs_knockdown else item.enemy.attack_damage > 0
			if matches and _can_block(spec, item):
				return true
	return false

func _repeat_post() -> bool:
	if _state.rules.starter_only:
		return false
	for spec in _usable:
		if not spec.logistics_post or spec.build_seconds <= 0:
			continue
		for anchor: Vector2i in _spots[spec]:
			var occupied := spec.footprint(anchor)
			for other: Vector2i in _spots[spec]:
				if not spec.footprint(other).any(func(tile: Vector2i) -> bool: return tile in occupied):
					return true
		if _take_damage(spec):
			return true
	return false

func _unless(condition: bool, reason: String) -> String:
	return "" if condition else reason
