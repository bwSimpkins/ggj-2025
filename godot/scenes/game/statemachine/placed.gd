extends TetrominoState
class_name Placed


var _last_chance_time: float = 0.05

func enter():
	_last_chance_time = 0.05
	

func process(delta: float) -> void:
	_last_chance_time -= delta
	if _last_chance_time > 0:
		return
		
	if tetromino.is_up_blocked():
		tetromino.handle_placed()
	else:
		Transition.emit(self, "Rising")
		

func game_tick_update() -> void:
	pass
