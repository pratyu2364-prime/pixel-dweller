extends CanvasLayer

@onready var sound_button: Button = $Center/VBox/SoundToggle
@onready var back_button: Button = $Center/VBox/Back


func _ready() -> void:
	sound_button.pressed.connect(_on_sound_toggle_pressed)
	back_button.pressed.connect(_on_back_pressed)
	_update_sound_button()


func _on_sound_toggle_pressed() -> void:
	var muted: bool = AudioServer.is_bus_mute(0)
	AudioServer.set_bus_mute(0, not muted)
	_update_sound_button()


func _update_sound_button() -> void:
	if AudioServer.is_bus_mute(0):
		sound_button.text = "Sound: Off"
	else:
		sound_button.text = "Sound: On"


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Title.tscn")
