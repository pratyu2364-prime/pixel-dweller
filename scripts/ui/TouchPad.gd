class_name TouchPad
extends Control

## Phone controls. The left half of the screen is a floating thumbstick that
## appears wherever the thumb lands; the right half holds cast and cling.
##
## Nothing is drawn until it is touched, so on a desktop this is invisible and
## on a phone it never covers the room you are trying to read.

signal cast_pressed
signal cling_changed(down: bool)

const DEAD_ZONE := 6.0
const MAX_RADIUS := 46.0
const BUTTON_RADIUS := 34.0

var direction: Vector2 = Vector2.ZERO
var cling_down: bool = false

var _stick_finger: int = -1
var _stick_origin: Vector2 = Vector2.ZERO
var _stick_at: Vector2 = Vector2.ZERO
var _cling_finger: int = -1


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func cast_button_center() -> Vector2:
	return Vector2(size.x - 72.0, size.y - 78.0)


func cling_button_center() -> Vector2:
	return Vector2(size.x - 150.0, size.y - 60.0)


func _gui_input(event: InputEvent) -> void:
	_handle(event)


func _unhandled_input(event: InputEvent) -> void:
	_handle(event)


func _handle(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_on_touch(event)
	elif event is InputEventScreenDrag:
		_on_drag(event)


func _on_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if _hits(event.position, cast_button_center()):
			cast_pressed.emit()
			return
		if _hits(event.position, cling_button_center()):
			_cling_finger = event.index
			_set_cling(true)
			return
		if _stick_finger < 0 and event.position.x < size.x * 0.5:
			_stick_finger = event.index
			_stick_origin = event.position
			_stick_at = event.position
		return
	if event.index == _stick_finger:
		_stick_finger = -1
		direction = Vector2.ZERO
	elif event.index == _cling_finger:
		_cling_finger = -1
		_set_cling(false)
	queue_redraw()


func _on_drag(event: InputEventScreenDrag) -> void:
	if event.index != _stick_finger:
		return
	_stick_at = event.position
	var offset := _stick_at - _stick_origin
	direction = Vector2.ZERO if offset.length() < DEAD_ZONE else offset / MAX_RADIUS
	if direction.length() > 1.0:
		direction = direction.normalized()
	queue_redraw()


func _set_cling(down: bool) -> void:
	if cling_down == down:
		return
	cling_down = down
	cling_changed.emit(down)
	queue_redraw()


func _hits(at: Vector2, center: Vector2) -> bool:
	return at.distance_to(center) <= BUTTON_RADIUS


func _process(_delta: float) -> void:
	if _stick_finger >= 0:
		queue_redraw()


func _draw() -> void:
	if DisplayServer.is_touchscreen_available():
		_draw_button(cast_button_center(), Color(0.62, 0.55, 0.95), "cast")
		_draw_button(cling_button_center(), Color(0.95, 0.80, 0.55), "cling")
	if _stick_finger < 0:
		return
	draw_circle(_stick_origin, MAX_RADIUS, Color(0.6, 0.62, 0.85, 0.10))
	draw_circle(_stick_origin, MAX_RADIUS, Color(0.6, 0.62, 0.85, 0.18))
	draw_circle(_stick_origin + direction * MAX_RADIUS, 16.0, Color(0.75, 0.78, 0.95, 0.35))


func _draw_button(center: Vector2, tint: Color, _label: String) -> void:
	var pressed := center == cling_button_center() and cling_down
	draw_circle(center, BUTTON_RADIUS, Color(tint.r, tint.g, tint.b, 0.30 if pressed else 0.14))
	draw_arc(center, BUTTON_RADIUS, 0.0, TAU, 28, Color(tint.r, tint.g, tint.b, 0.55), 2.0)
