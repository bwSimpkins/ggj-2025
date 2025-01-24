extends TetrominoState
class_name Rising


func game_tick_update():
	var coyote_time = tetromino.is_position_blocked(Vector2(0, -2))
	if not tetromino.is_up_blocked():
		tetromino.position.y -= tetromino.PIXELS_PER_UNIT
	if coyote_time:
		Transition.emit(self, "Coyote")
	
