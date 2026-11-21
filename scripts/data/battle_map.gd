class_name BattleMap
extends Resource

enum Tile { NONDEPLOYABLE, GROUND, ELEVATED }

@export var map_id: StringName
@export var size: Vector2i
@export var ground: Array[Vector2i]
@export var elevated: Array[Vector2i]
@export var spawns: Array[Vector2i]
@export var tunnel: Vector2i

func tile_at(cell: Vector2i) -> Tile:
	if not Rect2i(Vector2i.ZERO, size).has_point(cell) or cell in spawns or cell == tunnel:
		return Tile.NONDEPLOYABLE
	if cell in ground:
		return Tile.GROUND
	if cell in elevated:
		return Tile.ELEVATED
	return Tile.NONDEPLOYABLE

func validation_error(routes: Array[BattleRoute]) -> String:
	var bounds := Rect2i(Vector2i.ZERO, size)
	var used := {}
	var gates: Array[Vector2i] = spawns.duplicate()
	gates.append(tunnel)
	for cells: Array[Vector2i] in [ground, elevated, gates]:
		for cell in cells:
			if not bounds.has_point(cell) or used.has(cell):
				return "Map tiles must be in bounds and cannot overlap."
			used[cell] = true
	for route in routes:
		if route == null or route.cells.size() < 2 or route.cells.front() not in spawns or route.cells.back() != tunnel:
			return "A route must connect a spawn to the tunnel."
		for i in range(1, route.cells.size()):
			var delta := (route.cells[i] - route.cells[i - 1]).abs()
			if delta.x + delta.y != 1:
				return "Route waypoints must be adjacent."
			if i < route.cells.size() - 1 and tile_at(route.cells[i]) != Tile.GROUND:
				return "Interior route waypoints must be ground."
	return ""
