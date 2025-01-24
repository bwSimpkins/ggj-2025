extends TetrominoState
class_name Placed


func enter():
	tetromino.handle_placed()
	
	
func process(_delta: float, _game_clock: Timer):
	pass
