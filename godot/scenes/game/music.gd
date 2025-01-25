extends AudioStreamPlayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var intro_music = preload("res://music/ProjectZodiac-loopintro.wav")
	var loop_music = preload("res://music/ProjectZodiac-mainloop.wav")
	stream() = intro_music
	await finished
	stream.loop = true
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
	
	
	
	
