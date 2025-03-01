extends Node2D
class_name PlayArea


const CONSECUTIVE_BUBBLE_POP = 10.0

signal PoppedBubbles


@export var min_tetrominos_per_powerup := 2
@export var max_tetrominos_per_powerup := 5


# Constanst
const TETROMINO = preload("res://scenes/game/tetromino/tetromino.tscn")
const POWERUP = preload("res://scenes/game/powerup/power_up.tscn")
const PIXELS_TO_UNITS = 32

 
# Global Variables
var bubble_grid: Dictionary = {}
var total_score := 0
var index := -1
var powerup_grid: Dictionary = {}
var tetronimo_max := 7.0
var tetrominos_until_power_up: int
var max_tetromino_radius := 0


func is_position_blocked(pos: Vector2) -> bool:
	var pos_i = _to_vector2i(pos)
	if 0 <= pos.x && pos.x < %Grid.width && pos.y >= %Grid.height:
		return false
	return !bubble_grid.has(pos_i.y) \
		|| !bubble_grid[pos_i.y].has(pos_i.x) \
		|| bubble_grid[pos_i.y][pos_i.x] != null
		
func get_position_powerup(pos: Vector2) -> PowerUp:
	var pos_i = _to_vector2i(pos)
	var off_grid_or_no_power_up = !powerup_grid.has(pos_i.y) \
		|| !powerup_grid[pos_i.y].has(pos_i.x) \
		|| powerup_grid[pos_i.y][pos_i.x] == null
	if off_grid_or_no_power_up: 
		return null
	var temp = powerup_grid[pos_i.y][pos_i.x]
	powerup_grid[pos_i.y][pos_i.x] = null
	remove_child(temp)
	return temp
		
		
func _to_vector2i(vec: Vector2) -> Vector2i:
	return Vector2i(int(round(vec.x)), int(round(vec.y)))


func _ready() -> void:
	for row in %Grid.height:
		bubble_grid[row] = {}
		powerup_grid[row] = {}
		for col in %Grid.width:
			bubble_grid[row][col] = null
			powerup_grid[row][col] = null
			
	for letter in Tetromino.TETROMINO_MAP.keys():
		for vec in Tetromino.TETROMINO_MAP[letter]:
			max_tetromino_radius = max(max_tetromino_radius, int(abs(vec.x)))
			
	tetrominos_until_power_up = randi_range(min_tetrominos_per_powerup / 2, max_tetrominos_per_powerup / 2)
	_spawn_tetromino()
	
	
func _spawn_tetromino() -> void:
	tetrominos_until_power_up -= 1
	if tetrominos_until_power_up <= 0:
		_spawn_powerup()
		
	var spawn_col = randi_range(max_tetromino_radius, %Grid.width - 1 - max_tetromino_radius)
	var spawn_pos = Vector2i(spawn_col, %Grid.height - 1)
	var tetromino = TETROMINO.instantiate()
	tetromino.position = spawn_pos * PIXELS_TO_UNITS
	var tetromino_selected := int(randf_range(0, min(tetronimo_max, Tetromino.TETROMINO_MAP.size() - 1)))
	tetromino.letter = Tetromino.TETROMINO_MAP.keys()[tetromino_selected] #picks random letter from tetromino maps
	tetronimo_max += 1.0
	tetromino.Placed.connect(_on_placed)
	add_child(tetromino)
	
	
func _spawn_powerup() -> void:
	tetrominos_until_power_up = randi_range(min_tetrominos_per_powerup, max_tetrominos_per_powerup)
	var powerup = POWERUP.instantiate()
	var spawn_spot = _get_random_empty_cell()
	powerup.position = spawn_spot * PIXELS_TO_UNITS
	powerup.type = ["mult", "flat"].pick_random()
	
	var power_row: int = spawn_spot.y
	var power_col: int = spawn_spot.x
	powerup_grid[power_row][power_col] = powerup
	add_child(powerup)
	
	
# returned as Vector2i(col, row)
func _get_random_empty_cell() -> Vector2i:
	var available := {}
	for row in range(%Grid.height):
		for col in range(%Grid.width):
			if bubble_grid[row][col] == null && powerup_grid[row][col] == null:
				if not available.has(row):
					available[row] = {}
				available[row][col] = true
	var random_row = available.keys().pick_random()
	var random_col = available[random_row].keys().pick_random()
	return Vector2i(random_col, random_row)
	
	
func _on_placed(bubbles: Array[Bubble], tetromino_position: Vector2) -> void:
	var game_over := false
	for bubble in bubbles:
		bubble.position += tetromino_position
		var row := int(bubble.position.y / PIXELS_TO_UNITS)
		var col := int(bubble.position.x / PIXELS_TO_UNITS)
		bubble.row = row
		bubble.column = col
		
		if not bubble_grid.has(row) || not bubble_grid[row].has(col) || bubble_grid[row][col] != null:
			game_over = true
			continue
			
		add_child(bubble)
		
		bubble_grid[row][col] = bubble
		
	if game_over:
		_handle_game_over()
		return
		
	await _handle_placed_bubbles()
	_spawn_tetromino()
	
	
func _handle_game_over(): 
	var gg = _GAME_OVER
	gg.shuffle()
	const offset := Vector2(3, 2)
	var i := 0
	for bubble_rows in bubble_grid.values():
		for bubble in bubble_rows.values():
			if bubble == null:
				continue
			var grid_pos = gg[i] if i < gg.size() else gg.pick_random()
			grid_pos += offset
			i += 1
			bubble.change_position_after_pop(grid_pos * PIXELS_TO_UNITS)
		
	

func _handle_placed_bubbles() -> void:
	var consecutive_bubbles_pop = min(%Grid.width, CONSECUTIVE_BUBBLE_POP)
	var popped_bubbles: Array[Vector2i] = []
	for row in range(%Grid.height):
		var cols = bubble_grid[row].keys()
		cols.sort()
		var cols_with_bubbles: Array[int] = []
		for col in cols:
			var icol: int = int(col)
			if bubble_grid[row][icol] != null:
				cols_with_bubbles.append(icol)
		for popped_col in _get_consecutive(cols_with_bubbles, consecutive_bubbles_pop):
			popped_bubbles.append(Vector2i(row, popped_col))
	await _handle_popped_bubbles(popped_bubbles)


func _get_consecutive(sorted_arr: Array[int], _min: int) -> Array[int]:
	const EMPTY: Array[int] = []
	
	if sorted_arr.size() == 0:
		return EMPTY
	
	var consecutive_numbers: Array[int] = [sorted_arr[0]]

	for i in range(1, sorted_arr.size()):
		if sorted_arr[i] == sorted_arr[i - 1] + 1:
			consecutive_numbers.append(sorted_arr[i])
		elif consecutive_numbers.size() >= _min:
			return consecutive_numbers
		else:
			consecutive_numbers = [sorted_arr[i]] 
	
	return consecutive_numbers if consecutive_numbers.size() >= _min else EMPTY

	
# note bubbles will be sorted from top left to bottom right
func _handle_popped_bubbles(bubbles_positions: Array[Vector2i]) -> void:
	if not bubbles_positions:
		return
		
	var bubbles: Array[Bubble] = []
	var bubble_shifts: Dictionary = {} 
	for bubbles_position in bubbles_positions:
		assert(bubble_grid[bubbles_position.x][bubbles_position.y] != null)
		bubbles.append(bubble_grid[bubbles_position.x][bubbles_position.y])
		bubble_grid[bubbles_position.x][bubbles_position.y] = null
		
		for down in range(1, %Grid.height - bubbles_position.x):
			var below_position = bubbles_position + Vector2i(down, 0)
			if not bubble_shifts.has(below_position):
				bubble_shifts[below_position] = 0
			bubble_shifts[below_position] += 1
			
	var ordinal: int = 0
	
	PoppedBubbles.emit(bubbles)
	
	for bubble in bubbles:
		bubble.pop(ordinal)
		ordinal += 1
		
	await bubbles.back().BubblePopped
	
	var finished_falling = false
	for row in range(0,  %Grid.height):
		for col in range(0,  %Grid.width):
			var b: Bubble = bubble_grid[row][col]
			var key = Vector2i(row, col)
			if b == null || !bubble_shifts.has(key):
				continue
			var shift = bubble_shifts[key]
			var new_pos = b.position
			new_pos.y -= shift * PIXELS_TO_UNITS
			finished_falling = b.change_position_after_pop(new_pos)
			bubble_grid[row - shift][col] = b
			bubble_grid[row][col] = null
			
	if finished_falling:
		await finished_falling
		
	await _handle_placed_bubbles()
		
		
		
var _GAME_OVER: Array[Vector2] = [
	Vector2(0, 1), Vector2(1, 0), Vector2(2, 0), Vector2(3, 0), Vector2(4, 1), Vector2(0, 2), 
	Vector2(0, 3), Vector2(0, 4), Vector2(0, 5), Vector2(1, 6), Vector2(2, 6), Vector2(3, 6), 
	Vector2(4, 5), Vector2(4, 4), Vector2(3, 4), Vector2(6, 6), Vector2(6, 5), Vector2(6, 4), 
	Vector2(6, 3), Vector2(6, 2), Vector2(6, 1), Vector2(7, 0), Vector2(8, 0), Vector2(9, 0), 
	Vector2(7, 3), Vector2(8, 3), Vector2(9, 3), Vector2(10, 1), Vector2(10, 2), Vector2(10, 3), 
	Vector2(10, 4), Vector2(10, 5), Vector2(10, 6), Vector2(12, 6), Vector2(12, 5), Vector2(12, 4),
	Vector2(12, 3), Vector2(12, 2), Vector2(12, 1), Vector2(12, 0), Vector2(13, 1), Vector2(14, 2),
	Vector2(14, 3), Vector2(15, 1), Vector2(16, 0), Vector2(16, 1), Vector2(16, 2), Vector2(16, 3), 
	Vector2(16, 4), Vector2(16, 5), Vector2(16, 6), Vector2(18, 0), Vector2(18, 1), Vector2(18, 2), 
	Vector2(18, 3), Vector2(18, 4), Vector2(18, 5), Vector2(18, 6), Vector2(19, 6), Vector2(20, 6), 
	Vector2(21, 6), Vector2(19, 3), Vector2(19, 0), Vector2(20, 0), Vector2(21, 0), Vector2(20, 3), 
	Vector2(22, 6), Vector2(22, 0), Vector2(21, 3), Vector2(0, 10), Vector2(0, 11), Vector2(0, 12), 
	Vector2(0, 13), Vector2(4, 10), Vector2(4, 11), Vector2(4, 12), Vector2(4, 13), Vector2(6, 9), 
	Vector2(6, 10), Vector2(6, 11), Vector2(7, 13), Vector2(9, 13), Vector2(10, 9), Vector2(10, 10), 
	Vector2(10, 11), Vector2(12, 9), Vector2(12, 10), Vector2(12, 11), Vector2(12, 12), 
	Vector2(12, 13), Vector2(12, 14), Vector2(18, 9), Vector2(18, 10), Vector2(18, 11), 
	Vector2(18, 12), Vector2(18, 13), Vector2(18, 14), Vector2(20, 12), Vector2(22, 10), 
	Vector2(0, 14), Vector2(1, 9), Vector2(1, 15), Vector2(2, 9), Vector2(2, 15), Vector2(3, 9), 
	Vector2(3, 15), Vector2(4, 14), Vector2(6, 12), Vector2(7, 14), Vector2(8, 15), Vector2(9, 14), 
	Vector2(10, 12), Vector2(12, 15), Vector2(13, 9), Vector2(13, 12), Vector2(13, 15), 
	Vector2(14, 9), Vector2(14, 12), Vector2(14, 15), Vector2(15, 9), Vector2(15, 12), 
	Vector2(15, 15), Vector2(16, 9), Vector2(16, 15), Vector2(18, 15), Vector2(19, 9), 
	Vector2(19, 12), Vector2(20, 9), Vector2(20, 13), Vector2(21, 9), Vector2(21, 12), 
	Vector2(21, 14), Vector2(22, 11), Vector2(22, 15),
]
