extends Node2D
class_name Tetromino


signal Placed


@export_enum("I", "O", "T", "J", "L", "S", "Z") var letter: String = "T"

var play_area: PlayArea


const PIXELS_PER_UNIT = 32

const TETROMINO_COLORS = {
	"I": Color(0, 0.941, 0.941),
	"O": Color(0.902, 0.827, 0),
	"T": Color(0.627, 0, 0.941),
	"J": Color(0, 0.51, 0.914),
	"L": Color(0.941, 0.627, 0),
	"Z": Color(0.941, 0, 0),
	"S": Color(0, 0.941, 0),
}

const TETROMINO_MAP = {
	"I": [Vector2.LEFT, Vector2.ZERO, Vector2.RIGHT, Vector2(2, 0)],
	"O": [Vector2.ZERO, Vector2.UP, Vector2(1, -1), Vector2.RIGHT],
	"T": [Vector2.LEFT, Vector2.ZERO, Vector2.RIGHT,Vector2.DOWN],
	"J": [Vector2.LEFT, Vector2.ZERO, Vector2.RIGHT, Vector2(-1, -1)],
	"L": [Vector2.LEFT, Vector2.ZERO, Vector2.RIGHT, Vector2(1, -1)],
	"Z": [Vector2.ZERO, Vector2.RIGHT, Vector2.UP, Vector2(-1, -1)],
	"S": [Vector2.ZERO, Vector2.LEFT, Vector2.UP, Vector2(1, -1)],
}

const BUBBLE := preload("res://scenes/game/tetromino/bubble.tscn")

var _current_rotation: int = 0

func _ready() -> void:
	play_area = get_parent()
	assert(letter in TETROMINO_MAP and letter in TETROMINO_COLORS)
	var color = TETROMINO_COLORS[letter]
	for pos in TETROMINO_MAP[letter]:
		var bubble = BUBBLE.instantiate()
		bubble.modulate = color
		bubble.position = pos * PIXELS_PER_UNIT
		%Bubbles.add_child(bubble)
		

func _process(delta: float) -> void:
	%FiniteStateMachine.process(delta)


func try_move(vec: Vector2) -> bool:
	if is_position_blocked(vec):
		return false
	position += vec * PIXELS_PER_UNIT
	return true
	

func slam_time(vec: Vector2, force: bool = false) -> void:
	while !is_position_blocked(vec) && not force:
		position += vec * PIXELS_PER_UNIT
		break
	

func process_rotate(degrees: int) -> void:
	_current_rotation = (_current_rotation + degrees) % 360

	if not wall_kick():
		# cannot rotate, undo rotation
		_current_rotation = (_current_rotation + 360 - degrees) % 360
		return
	
	var i = 0
	var bubble_positions_after_rotate = _get_bubble_positions()
	for bubble in get_bubbles():
		bubble.position = bubble_positions_after_rotate[i] * PIXELS_PER_UNIT
		i += 1
	

func _rotate(pos: Vector2, degrees: int) -> Vector2:
	var pivot := Vector2(0.5, -0.5) if letter == 'I' || letter == 'O' else Vector2.ZERO
	var relative_pos = pos - pivot
	var rotated_pos = relative_pos
	if degrees == 90:
		rotated_pos = Vector2(relative_pos.y, -relative_pos.x)
	elif degrees == 180:
		rotated_pos = Vector2(-relative_pos.x, -relative_pos.y)
	elif degrees == 270:
		rotated_pos = Vector2(-relative_pos.y, relative_pos.x)
	return rotated_pos + pivot
	
	
func wall_kick() -> bool:
	const kicks := [Vector2.UP, Vector2.RIGHT, Vector2.LEFT, Vector2.RIGHT]
	
	if !is_position_blocked(Vector2.ZERO):
		return true
	
	for kick in kicks:
		if try_move(kick):
			return true
	
	for first_kick in kicks:
		for second_kick in kicks:
			var double_kick = first_kick + second_kick
			if double_kick != Vector2.ZERO && try_move(double_kick):
				return true
	
	return false
	
	
func is_currently_blocked() -> bool:
	return is_position_blocked(Vector2.ZERO)
	

func is_left_blocked() -> bool:
	return is_position_blocked(Vector2.LEFT)


func is_right_blocked() -> bool:
	return is_position_blocked(Vector2.RIGHT)
	
	
func is_up_blocked() -> bool:
	return is_position_blocked(Vector2.UP)
	

func is_position_blocked(pos: Vector2) -> bool:
	for bubble_position in _get_bubble_positions():
		var pos_b = (position / PIXELS_PER_UNIT) + bubble_position + pos
		if play_area.is_position_blocked(pos_b):
			return true
	return false


func _get_bubble_positions() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	for bubble_position in TETROMINO_MAP[letter]:
		positions.append(_rotate(bubble_position, _current_rotation))
	return positions
	

func get_bubbles() -> Array[Bubble]:
	var bubbles: Array[Bubble] = []
	for child in %Bubbles.get_children():
		if child is Bubble:
			bubbles.append(child)
	return bubbles
	

func handle_placed() -> void:
	var bubbles = get_bubbles()
	for bubble in bubbles:
		bubble.get_parent().remove_child(bubble)
		bubble.animation_place(%GameClock.wait_time)
	Placed.emit(bubbles, position)
	queue_free()
	
