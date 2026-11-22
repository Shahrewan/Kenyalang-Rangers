class_name WaveIntel
extends VBoxContainer

func show_stage(stage: BattleStage, live: BattleSimulation = null) -> void:
	for group in get_children():
		remove_child(group)
		group.queue_free()
	if live != null and not live.active.is_empty():
		var field := StoryUI.panel(self)
		field.add_child(StoryUI.label("On the field", 21, StoryUI.AMBER))
		for enemy: BattleEnemy in live.active.values():
			var text := "%s  ·  %d/%d HP  ·  Danger %d" % [
				enemy_name(enemy.definition), enemy.hp, enemy.definition.max_hp, enemy.definition.danger,
			]
			var shield := enemy.active_shield(live.clock.tick)
			if shield > 0:
				text += "  ·  %d temporary HP" % shield
			var mark := enemy.damage_mark_bonus(live.clock.tick)
			if mark > 0:
				text += "  ·  +%d%% damage taken" % mark
			field.add_child(StoryUI.label(text, 18))
	for index in stage.waves.size():
		var wave := stage.waves[index]
		var count := 0
		for group in wave.groups:
			count += group.count
		if count == 0:
			continue
		var box := StoryUI.panel(self)
		box.add_child(StoryUI.label("Wave %d · %d enemies" % [index + 1, count], 20, StoryUI.AMBER))
		for group in wave.groups:
			if group.count > 0:
				var route := "Entry " + char(65 + group.route_index) if stage.routes.size() > 1 else "Route 1"
				box.add_child(StoryUI.label("%d × %s  ·  %s" % [group.count, enemy_name(group.enemy), route], 18))
				box.add_child(StoryUI.label(enemy_details(group.enemy), 17, StoryUI.BEIGE))
				if not group.enemy.counterplay.is_empty():
					box.add_child(StoryUI.label(group.enemy.counterplay, 17))
				var boss := group.enemy as BossSpec
				if boss != null:
					var reinforcements := 0
					for phase in boss.phases:
						reinforcements += phase.reinforcement_count
					if reinforcements > 0:
						box.add_child(StoryUI.label("Boss phases can call %d additional enemies." % reinforcements, 17, StoryUI.BEIGE))

static func enemy_name(enemy: BattleEnemyDefinition) -> String:
	return String(enemy.enemy_id) if enemy.display_name.is_empty() else "%s · %s" % [enemy.enemy_id, enemy.display_name]

static func enemy_details(enemy: BattleEnemyDefinition) -> String:
	var tags := enemy.tags()
	if not enemy.aerial:
		tags.insert(0, "Ground")
	if enemy.heat_per_second > 0.0:
		tags.append("Builds Heat")
	var escape := "Defeat on escape" if enemy.escape_causes_defeat else "−%d Integrity on escape" % enemy.escape_penalty
	return "%d HP  ·  Danger %d  ·  %s  ·  %s" % [
		enemy.max_hp, enemy.danger, " · ".join(tags), escape,
	]
