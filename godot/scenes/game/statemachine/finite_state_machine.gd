extends Node
class_name FiniteStateMachine


@export var initial_state: TetrominoState
@export var game_clock: Timer

var current_state: TetrominoState = null
var states: Dictionary = {}


func _ready():
	for child in get_children():
		if child is TetrominoState:
			states[child.name.to_lower()] = child
			child.Transition.connect(on_child_transition)
			
	if initial_state:
		initial_state.enter()
		current_state = initial_state
		
	if not game_clock:
		game_clock = Timer.new()
	assert(not game_clock.one_shot)
	game_clock.timeout.connect(_on_game_tick_update)
	

func _process(delta: float):
	if current_state:
		current_state.process(delta, game_clock)


func _on_game_tick_update():
	if current_state:
		current_state.game_tick_update()
		
			
func on_child_transition(state: TetrominoState, next_state: String):
	if state != current_state:
		return
	
	next_state = next_state.to_lower()
	assert(next_state in states)
	
	if current_state:
		current_state.exit()
		
	current_state = states[next_state]
	current_state.enter()
	
