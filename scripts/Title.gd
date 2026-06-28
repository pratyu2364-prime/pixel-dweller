extends CanvasLayer

@onready var begin_button: Button = $Center/VBox/Begin
@onready var settings_button: Button = $Center/VBox/Settings


func _ready() -> void:
	begin_button.pressed.connect(_on_begin_pressed)
	settings_button.pressed.connect(_on_settings_pressed)


func _on_begin_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")


func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Settings.tscn")
