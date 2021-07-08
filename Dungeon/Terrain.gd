extends TileMap
# Store all the information for paht finding o:

var astar : AStar2D
var used_cells

# Call setup after terrain is generated
func setup():
	astar = AStar2D.new()
	used_cells = get_used_cells_by_id(1)
	_add_points()
	_connect_points()

func _add_points():
	for cell in used_cells:
		astar.add_point(astar.get_available_point_id(),cell)
	
func _connect_points():
	for cell in used_cells:
		var neighbors = [Vector2(1,0),Vector2(-1,0),Vector2(0,1),Vector2(0,-1)]
		for neighbor in neighbors:
			var next_cell = cell + neighbor
			if used_cells.has(next_cell):
				astar.connect_points(astar.get_closest_point(cell),astar.get_closest_point(next_cell),false)

func _get_path(start, end):
	return astar.get_point_path(astar.get_closest_point(start), astar.get_closest_point(end))

func _set_state(at_position : Vector2, value : bool):
	var point = astar.get_closest_point(at_position, true)
	astar.set_point_disabled(point, !value)
