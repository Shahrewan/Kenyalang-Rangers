class_name BattleModifier
extends Resource

enum AppliesTo {
	WAVES, HEAT, CONCEALED, ORDINARY_ESCAPE, RANGER_DAMAGE, RANGER_ATTACK,
	RANGER_SKILL, WEAKNESS, RANGER, HEALING, BLOCKING, KNOCKDOWN, TOKEN_OPENING,
	REDEPLOYMENT, POST, ENEMY, STOCKPILE, SMOKE, REST, SIEGE, CONSTRUCTION,
	AERIAL, RANGER_COST, SPAWN_INTERVAL,
}

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var chaos_points: int
@export var applies_to: AppliesTo
@export var effects: Dictionary[StringName, float]

func is_buff() -> bool:
	return chaos_points < 0
