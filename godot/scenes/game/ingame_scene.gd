extends Node2D


@onready var fade_overlay = %FadeOverlay
@onready var pause_overlay = %PauseOverlay

func _ready() -> void:
	preload("res://music/projectzodiac-smoothintro.mp3")
	preload("res://music/projectzodiac-smoothmainloop.mp3")
	%IntroMusic.play()
	%IntroMusic.connect("finished", _on_intro_finished)
	fade_overlay.visible = true
	
	%BackgroundAnimations.play("game_start")
	%BackgroundAnimations.queue("background_idle")

func _input(event) -> void:
	if event.is_action_pressed("pause") and not pause_overlay.visible:
		get_viewport().set_input_as_handled()
		get_tree().paused = true
		pause_overlay.grab_button_focus()
		pause_overlay.visible = true
		

func _on_intro_finished():
	%LoopMusic.play()
