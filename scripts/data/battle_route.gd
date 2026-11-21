class_name BattleRoute
extends Resource

@export var cells: Array[Vector2i]

func position_at(distance: float) -> Vector2:
	var segment := mini(int(distance), cells.size() - 2)
	return Vector2(cells[segment]).lerp(Vector2(cells[segment + 1]), distance - segment)
