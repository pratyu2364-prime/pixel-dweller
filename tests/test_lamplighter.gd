extends GutTest

## Wardens make your darkness temporary. The Lamplighter makes the map itself
## get worse the longer you take.


func _rig() -> Array:
	var field := LightField.new(30, 20)
	var cling := ClingController.new(field, [])
	var lamplighter := Lamplighter.new()
	add_child_autofree(lamplighter)
	var route := PatrolRoute.new(
		[Vector2i(4, 4), Vector2i(24, 4)], PatrolRoute.Mode.PING_PONG, 2.0
	)
	lamplighter.setup("quill", route, field, cling)
	return [field, cling, lamplighter]


func test_they_carry_a_lantern_like_everyone_else_here() -> void:
	var rig := _rig()
	var field: LightField = rig[0]
	var lamplighter: Lamplighter = rig[2]
	assert_true(field.is_glare(lamplighter.current_cell()))


func test_they_leave_new_light_behind_them() -> void:
	var rig := _rig()
	var field: LightField = rig[0]
	var lamplighter: Lamplighter = rig[2]
	watch_signals(lamplighter)
	var before := field.emitters().size()
	for step in 70:
		lamplighter._physics_process(0.1)
	assert_gt(field.emitters().size(), before, "the room has more light in it now")
	assert_signal_emitted(lamplighter, "lit")
	assert_gt(lamplighter.placed.size(), 0)


func test_the_candles_they_leave_are_ordinary_candles() -> void:
	var rig := _rig()
	var cling: ClingController = rig[1]
	var lamplighter: Lamplighter = rig[2]
	var candle := lamplighter.place_candle()
	assert_ne(candle, "", "it placed one")
	assert_true(cling.is_portable(candle), "you can pick it up")
	assert_true(cling.snuff(candle), "and you can put it out")


func test_they_do_not_stack_candles_on_top_of_each_other() -> void:
	var rig := _rig()
	var lamplighter: Lamplighter = rig[2]
	assert_ne(lamplighter.place_candle(), "")
	assert_eq(lamplighter.place_candle(), "", "one candle per place")


func test_they_do_not_set_fire_to_the_glass() -> void:
	var rig := _rig()
	var field: LightField = rig[0]
	var lamplighter: Lamplighter = rig[2]
	field.set_mirror(lamplighter.current_cell(), "/")
	assert_eq(lamplighter.place_candle(), "")


func test_they_light_the_room_faster_than_they_walk_it() -> void:
	# The pressure has to be legible: a full circuit should cost you several
	# candles, not one.
	var rig := _rig()
	var lamplighter: Lamplighter = rig[2]
	for step in 200:
		lamplighter._physics_process(0.1)
	assert_gte(lamplighter.placed.size(), 3)


func test_a_lamplighter_is_declared_like_a_warden() -> void:
	var text := (
		"id: x\nlamplighter: id=quill route=(1,1)>(3,1) mode=loop speed=2\n\n"
		+ "#####\n#@..#\n#####"
	)
	var data := ChamberData.from_text(text)
	assert_true(data.is_valid(), str(data.parse_errors))
	assert_eq(data.wardens.size(), 1)
	assert_true(data.wardens[0]["lamplighter"])


func test_an_ordinary_warden_is_not_one() -> void:
	var text := "id: x\nwarden: id=hob route=(1,1)>(3,1)\n\n#####\n#@..#\n#####"
	assert_false(ChamberData.from_text(text).wardens[0]["lamplighter"])


func test_the_long_gallery_has_one_of_each() -> void:
	var data := ChamberData.from_file("res://chambers/long_gallery.txt")
	assert_true(data.is_valid(), str(data.parse_errors))
	assert_eq(data.wardens.size(), 2)
	assert_true(data.exit_is_reachable())
	assert_true(data.build_field().is_deep_shade(data.spawn))
	for warden in data.wardens:
		for point in warden["waypoints"]:
			assert_false(data.is_wall(point), "%s walks through a wall" % warden["id"])


func test_the_chamber_brings_the_lamplighter_to_life() -> void:
	var chamber := Chamber.new()
	chamber.chamber_path = "res://chambers/long_gallery.txt"
	add_child_autofree(chamber)
	assert_eq(chamber.lamplighters.size(), 1)
	assert_eq(chamber.wardens.size(), 1)
	var before := chamber.field.emitters().size()
	chamber.lamplighters[0].place_candle()
	assert_eq(chamber.field.emitters().size(), before + 1)


func test_the_gallery_sits_between_the_walk_and_the_hall() -> void:
	assert_eq(Game.next_after("warden_walk", ""), "long_gallery")
	assert_eq(Game.next_after("long_gallery", ""), "prism_hall")
