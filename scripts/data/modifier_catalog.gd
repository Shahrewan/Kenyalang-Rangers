class_name ModifierCatalog
extends Resource

@export var entries: Array[BattleModifier]

func definition(id: StringName) -> BattleModifier:
	for modifier in entries:
		if modifier.id == id:
			return modifier
	return null
