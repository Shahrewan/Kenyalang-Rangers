class_name BattleEnemyDefinition
extends Resource

@export var enemy_id: StringName
@export var display_name: String
@export var danger := 1
@export_multiline var counterplay: String
@export var tiles_per_second: float
@export var escape_penalty: int
@export var escape_causes_defeat := false
@export var chaos_points: int

@export var aerial := false
@export var technological := false
@export var concealed := false
@export var heavy := false
@export var environmental := false
@export var heat_per_second: float

@export var max_hp := 100
@export var attack_damage := 6
@export var attack_seconds := 1.8
@export var attack_profile: EnemyAttackProfile
@export var ability: EnemyAbility

func is_siege_capable() -> bool:
	return attack_profile != null and attack_profile.kind == EnemyAttackProfile.Kind.SIEGE

func tags() -> PackedStringArray:
	var names := PackedStringArray()
	if aerial:
		names.append("Aerial")
	if technological:
		names.append("Technological")
	if concealed:
		names.append("Invisible")
	if heavy:
		names.append("Heavy")
	if environmental:
		names.append("Environmental")
	if is_siege_capable():
		names.append("Siege")
	return names
