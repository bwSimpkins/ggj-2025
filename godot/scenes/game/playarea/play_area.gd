extends Node2D


const TETROMINO = preload("res://scenes/game/tetromino/tetromino.tscn")


func _ready() -> void:
	_spawn_tetromino()
	
	
func _spawn_tetromino() -> void:
	var tetromino = TETROMINO.instantiate()
	tetromino.letter = ["I", "O", "T", "J", "L", "S", "Z"].pick_random()
	tetromino.Placed.connect(_on_placed)
	add_child(tetromino)
	
	
func _on_placed(bubbles: Array[Bubble], tetromino_position: Vector2) -> void:
	for bubble in bubbles:
		bubble.position += tetromino_position
		add_child(bubble)
	_spawn_tetromino()
