extends Control

# Dictionary to store references to the key labels
var key_labels = {}

func _ready():
# Populate the key_labels dictionary with Label nodes
	for label in %Keys.get_children():
		if label is Label:
			key_labels[label.name] = label


func _input(event):
	if event is InputEventKey:
		for key in key_labels.keys():
			var label: Label = key_labels[key]
			if Input.is_key_pressed(event.keycode) and OS.get_keycode_string(event.keycode) == key:
				await flash_key(label)


func flash_key(label: Label):
	label.add_theme_color_override("font_color", Color(0, 128, 128)) # Change to red
	await get_tree().create_timer(0.2).timeout      # Flash for 0.2 seconds
	label.add_theme_color_override("font_color", Color(1, 1, 1))           # Revert to default
