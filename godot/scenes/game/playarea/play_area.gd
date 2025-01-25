extends Node2D
class_name PlayArea


const CONSECUTIVE_BUBBLE_POP = 10.0


signal PoppedBubbles


const TETROMINO = preload("res://scenes/game/tetromino/tetromino.tscn")
const PIXELS_TO_UNITS = 32


# Dictionary[int, Dictionary[int, Bubble|null]]
var bubble_grid: Dictionary = {}

var spawn_pos: Vector2i



func is_position_blocked(pos: Vector2) -> bool:
	var pos_i = _to_vector2i(pos)
	return !bubble_grid.has(pos_i.y) \
		|| !bubble_grid[pos_i.y].has(pos_i.x) \
		|| bubble_grid[pos_i.y][pos_i.x] != null
		
		
func _to_vector2i(vec: Vector2) -> Vector2i:
	return Vector2i(int(round(vec.x)), int(round(vec.y)))


func _ready() -> void:
	for row in %Grid.height:
		bubble_grid[row] = {}
		for col in %Grid.width:
			bubble_grid[row][col] = null
			
	spawn_pos = Vector2i(int(%Grid.width / 2), %Grid.height - 1)
			
	_spawn_tetromino()
	
	
func _spawn_tetromino() -> void:
	var tetromino = TETROMINO.instantiate()
	tetromino.position = spawn_pos * PIXELS_TO_UNITS
	tetromino.letter = ["I", "O", "T", "J", "L", "S", "Z"].pick_random()
	tetromino.Placed.connect(_on_placed)
	add_child(tetromino)
	
	
func _on_placed(bubbles: Array[Bubble], tetromino_position: Vector2) -> void:
	var changed_rows: Array[int] = []
	for bubble in bubbles:
		bubble.position += tetromino_position
		add_child(bubble)
		var row := int(bubble.position.y / PIXELS_TO_UNITS)
		var col := int(bubble.position.x / PIXELS_TO_UNITS)
		assert(bubble_grid[row][col] == null)
		bubble_grid[row][col] = bubble
		changed_rows.append(row)
	changed_rows.sort()
	await _handle_placed_bubbles(changed_rows)
	_spawn_tetromino()
	

func _handle_placed_bubbles(changed_rows: Array[int]) -> void:
	var consecutive_bubbles_pop = min(%Grid.width, CONSECUTIVE_BUBBLE_POP)
	
	var popped_bubbles: Array[Bubble] = []
	const DEFAULT = Vector2i(-1, -1)
	var top_left_popped: Vector2i = Vector2i(-1, -1)
	var bottom_right_popped: Vector2i = Vector2i(-1, -1)
	for row in changed_rows:
		var cols = bubble_grid[row].keys()
		cols.sort()
		var cols_with_bubbles: Array[int] = []
		for col in cols:
			var icol: int = int(col)
			if bubble_grid[row][icol] != null:
				cols_with_bubbles.append(icol)
		for popped_col in _get_consecutive(cols_with_bubbles, consecutive_bubbles_pop):
			popped_bubbles.append(bubble_grid[row][popped_col])
			bottom_right_popped = Vector2i(row, popped_col)
			if top_left_popped == DEFAULT:
				top_left_popped = bottom_right_popped
	await _handle_popped_bubbles(popped_bubbles, top_left_popped, bottom_right_popped)


func _get_consecutive(sorted_arr: Array[int], _min: int) -> Array[int]:
	var consecutive_numbers: Array[int] = [sorted_arr[0]]

	for i in range(1, sorted_arr.size()):
		if sorted_arr[i] == sorted_arr[i - 1] + 1:
			consecutive_numbers.append(sorted_arr[i])
		elif consecutive_numbers.size() >= _min:
			return consecutive_numbers
		else:
			consecutive_numbers = [sorted_arr[i]]
			
	const EMPTY: Array[int] = []
	return consecutive_numbers if consecutive_numbers.size() >= _min else EMPTY

	
# note bubbles will be sorted from top left to bottom right
func _handle_popped_bubbles(bubbles: Array[Bubble], top_left: Vector2i, bot_right: Vector2i) -> void:
	if not bubbles:
		return
	
	var ordinal: int = 0
	for bubble in bubbles:
		bubble.pop(ordinal)
		ordinal += 1
	
	PoppedBubbles.emit(bubbles)
	
	await get_tree().create_timer(ordinal * .03).timeout #fix
	
	
	var shift = bot_right.x - top_left.x + 1
	var start_row = bot_right.x + 1
	
	var start_col = top_left.y
	var end_col = bot_right.y 
	var finished_falling: Signal=Signal()
	for row in range(start_row,  %Grid.height):
		if !bubble_grid.has(row):
			continue
		for col in range(start_col, end_col + 1):
			var potential_bubble: Bubble = bubble_grid[row][col]
			if potential_bubble != null:
				var new_pos = potential_bubble.position
				new_pos.y -= shift * PIXELS_TO_UNITS
				finished_falling = potential_bubble.change_position_after_pop(ordinal, new_pos)
			bubble_grid[row - shift][col] = potential_bubble
			bubble_grid[row][col] = null
	await finished_falling
