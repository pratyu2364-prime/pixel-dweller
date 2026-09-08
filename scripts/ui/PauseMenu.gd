class_name PauseMenu
extends CanvasLayer

## Escape, or the corner button on a phone. Three things only: go back to the
## room, start this floor over, or leave. Starting a floor over exists because
## a shadow can strand herself in a lit corner, and a puzzle game that can be
## soft-locked without a way out is a broken one.

signal resumed
signal restart_requested
signal quit_requested

var _root: Control
var _panel: VBoxContainer


func _init() -> void:
	layer = 18
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.visible = false
	add_child(_root)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.02, 0.04, 0.82)
	_root.add_child(dim)

	_panel = VBoxContainer.new()
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_bottom = 0.5
	_panel.offset_left = -120.0
	_panel.offset_right = 120.0
	_panel.offset_top = -80.0
	_panel.offset_bottom = 80.0
	_panel.add_theme_constant_override("separation", 12)
	_root.add_child(_panel)

	_add_button("back to the dark", func() -> void: close())
	_add_button("start this floor over", func() -> void: restart_requested.emit())
	_add_button("leave", func() -> void: quit_requested.emit())


func _add_button(text: String, action: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.pressed.connect(action)
	_panel.add_child(button)


func is_open() -> bool:
	return _root.visible


func open() -> void:
	_root.visible = true
	get_tree().paused = true


func close() -> void:
	_root.visible = false
	get_tree().paused = false
	resumed.emit()


func toggle() -> void:
	if is_open():
		close()
	else:
		open()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		toggle()
		get_viewport().set_input_as_handled()
