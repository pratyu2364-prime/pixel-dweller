extends GutTest


func _pad() -> TouchPad:
	var pad := TouchPad.new()
	pad.size = Vector2(640, 360)
	add_child_autofree(pad)
	return pad


func _touch(at: Vector2, pressed: bool, index: int = 0) -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.position = at
	event.pressed = pressed
	event.index = index
	return event


func _drag(at: Vector2, index: int = 0) -> InputEventScreenDrag:
	var event := InputEventScreenDrag.new()
	event.position = at
	event.index = index
	return event


func test_the_stick_appears_where_the_thumb_lands() -> void:
	var pad := _pad()
	pad._handle(_touch(Vector2(90, 200), true))
	pad._handle(_drag(Vector2(90 + TouchPad.MAX_RADIUS, 200)))
	assert_almost_eq(pad.direction.x, 1.0, 0.01)
	assert_almost_eq(pad.direction.y, 0.0, 0.01)


func test_the_stick_never_pushes_harder_than_full() -> void:
	var pad := _pad()
	pad._handle(_touch(Vector2(90, 200), true))
	pad._handle(_drag(Vector2(400, 200)))
	assert_almost_eq(pad.direction.length(), 1.0, 0.01)


func test_a_still_thumb_is_not_a_direction() -> void:
	var pad := _pad()
	pad._handle(_touch(Vector2(90, 200), true))
	pad._handle(_drag(Vector2(92, 201)))
	assert_eq(pad.direction, Vector2.ZERO, "the dead zone keeps her still")


func test_lifting_the_thumb_stops_her() -> void:
	var pad := _pad()
	pad._handle(_touch(Vector2(90, 200), true))
	pad._handle(_drag(Vector2(140, 200)))
	pad._handle(_touch(Vector2(140, 200), false))
	assert_eq(pad.direction, Vector2.ZERO)


func test_the_buttons_do_not_steal_the_stick() -> void:
	var pad := _pad()
	watch_signals(pad)
	pad._handle(_touch(pad.cast_button_center(), true))
	assert_signal_emitted(pad, "cast_pressed")
	assert_eq(pad.direction, Vector2.ZERO)


func test_cling_is_held_not_tapped() -> void:
	var pad := _pad()
	watch_signals(pad)
	pad._handle(_touch(pad.cling_button_center(), true, 1))
	assert_true(pad.cling_down)
	pad._handle(_touch(pad.cling_button_center(), false, 1))
	assert_false(pad.cling_down)
	assert_signal_emit_count(pad, "cling_changed", 2)


func test_touch_and_keyboard_drive_the_same_body() -> void:
	var chamber := Chamber.new()
	chamber.chamber_path = "res://chambers/cistern.txt"
	add_child_autofree(chamber)
	assert_not_null(chamber.touch, "a phone can play this")
	chamber.umbra.touch_direction = Vector2(1, 0)
	assert_almost_eq(chamber.umbra._read_input().x, 1.0, 0.01)
	chamber.umbra.touch_cling = true
	assert_true(chamber.umbra.is_clinging())
