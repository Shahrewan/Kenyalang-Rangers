class_name EnemyAttackProfile
extends Resource

enum Kind { MELEE, RANGED, PROJECTILE, SIEGE }

@export var kind: Kind
@export var radius := 1
@export var windup_seconds := 0.0
