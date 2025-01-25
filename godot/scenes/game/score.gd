extends Node2D

var total_score = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_play_area_popped_bubbles(bubbles: Array[Bubble]) -> void:
	for bubble in bubbles:
		total_score += bubble.score
	print(total_score)
	pass # Replace with function body.
	
