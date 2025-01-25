extends Node2D
class_name Bubble

const DEFAULT_TICK = .5
const BUBBLE_POP_DURATION = 0


var row 
var column
var score = 10
	

func pop(_ordinal: int) -> void:
	queue_free()
	

func change_position_after_pop(pop_count: int, pos: Vector2) -> void:
	var tween = create_tween()
	tween.tween_interval(pop_count * BUBBLE_POP_DURATION)
	tween.tween_property(self, "position", pos, 0.75) \
		.set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_IN_OUT)
	animation_place(0.5) # todo fix

	
func distance_to_slam() -> float:
	assert(%SlamCast.is_colliding())
	return global_position.distance_to(%SlamCast.get_collision_point())
	
func animation_place(game_tick_length:float) -> void:
	%BubbleAnimationPlayer.speed_scale = 2 * (DEFAULT_TICK/game_tick_length)
	%BubbleAnimationPlayer.play("Place")
	await %BubbleAnimationPlayer.animation_finished
	%BubbleAnimationPlayer.speed_scale = .1
	%BubbleAnimationPlayer.queue("idle")

func animation_pop(game_tick_length:float) -> void:
	%BubbleAnimationPlayer.speed_scale = 2 * (DEFAULT_TICK/game_tick_length)
	%BubbleAnimationPlayer.play("pop")
	
func animation_idle() -> void:
	%BubbleAnimationPlayer.speed_scale = .1
	%BubbleAnimationPlayer.queue("idle")
	
func animation_coyote_input(game_tick_length:float) -> void:
	if $BubbleAnimationPlayer.current_animation != "coyote": 
		%BubbleAnimationPlayer.speed_scale = 4 * (DEFAULT_TICK/game_tick_length)
		%BubbleAnimationPlayer.play("coyote")
