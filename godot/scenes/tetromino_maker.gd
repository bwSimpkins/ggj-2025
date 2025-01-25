extends Node


func _ready() -> void:
	var cells = %Grid.get_used_cells_by_id(0, Vector2i.ZERO)
	var s = "["
	for cell in cells:
		s += "Vector2(%d, %d), " % [cell.x, cell.y]
	s += "],"
	print(s)
