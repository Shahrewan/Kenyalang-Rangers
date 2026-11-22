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
			field.add_child(StoryUI.label("%s  ·  %d/%d HP  ·  Danger %d" % [
				enemy_name(enemy.definition), enemy.hp, enemy.definition.max_hp, enemy.definition.danger,
			], 18))
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
				box.add_child(StoryUI.label("%d × %s  ·  Route %d" % [group.count, enemy_name(group.enemy), group.route_index + 1], 18))
				box.add_child(StoryUI.label(enemy_details(group.enemy), 17, StoryUI.BEIGE))
				if not group.enemy.counterplay.is_empty():
					box.add_child(StoryUI.label(group.enemy.counterplay, 17))

static func enemy_name(enemy: BattleEnemyDefinition) -> String:
	return String(enemy.enemy_id) if enemy.display_name.is_empty() else "%s · %s" % [enemy.enemy_id, enemy.display_name]

static func enemy_details(enemy: BattleEnemyDefinition) -> String:
	var movement := "Aerial" if enemy.aerial else "Ground"
	if enemy.technological:
		movement += " · Technological"
	if enemy.concealed:
		movement += " · Concealed"
	if enemy.heat_per_second > 0.0:
		movement += " · Builds Heat"
	if enemy.attack_profile != null and enemy.attack_profile.kind == EnemyAttackProfile.Kind.SIEGE:
		movement += " · Siege"
	return "%d HP  ·  Danger %d  ·  %s  ·  −%d Integrity on escape" % [
		enemy.max_hp, enemy.danger, movement, enemy.escape_penalty,
	]
