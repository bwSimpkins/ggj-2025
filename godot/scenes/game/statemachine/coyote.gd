extends TetrominoState
class_name Coyote

@export var maximum_entries: int = 3
@export var max_coyote_ticks: int = 3
@export var min_coyote_ticks: int = 1

var coyote_etries := 0
var total_ticks := 1
var ticks_since_last_rotation := 1


func enter():
	coyote_etries += 1
	if coyote_etries > maximum_entries:
		Transition.emit(self, 'Placed')
	
	for bubble in tetromino.get_bubbles():
		bubble.animation_coyote_input(%GameClock.wait_time)

func exit():
	total_ticks = 1
	ticks_since_last_rotation = 1
	
	
func process(delta: float) -> void:
	super.process(delta)
	
	if action_this_frame:
		ticks_since_last_rotation = 0
		
		for bubble in tetromino.get_bubbles():
			bubble.animation_coyote_input(%GameClock.wait_time)

func game_tick_update():
	total_ticks += 1
	ticks_since_last_rotation += 1
	
	
	if not tetromino.is_up_blocked():
		Transition.emit(self, 'Rising')
		return
	
	if ticks_since_last_rotation > min_coyote_ticks || total_ticks > max_coyote_ticks:
		Transition.emit(self, 'Placed')
		return
