extends Node2D

var total_score = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_score_label() #Initialize label at start of main game screen


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_play_area_popped_bubbles(bubbles: Array[Bubble]) -> void:
	for bubble in bubbles:
		total_score += bubble.score
	print(total_score)
	update_score_label() #Update score label after score is calculated


func update_score_label():
	var score_label =  $HUD/Label
	score_label.text = str("Score:\n") + str(total_score)
