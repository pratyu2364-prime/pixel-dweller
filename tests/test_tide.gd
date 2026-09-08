extends GutTest

## A tide floor is not a puzzle you solve once; it is a place that is
## periodically survivable. These tests pin the clock down.


func _tide() -> Tide:
	return Tide.new(0.0, 0.6, 40.0, 6.0)


func test_it_rises_holds_and_drains() -> void:
	var tide := _tide()
	assert_almost_eq(tide.level_at(0.0), 0.0, 0.01, "it starts out")
	assert_almost_eq(tide.level_at(14.0), 0.6, 0.01, "it comes all the way in")
	assert_almost_eq(tide.level_at(17.0), 0.6, 0.01, "and holds there")
	assert_lt(tide.level_at(24.0), 0.6, "then drains")
	assert_almost_eq(tide.level_at(34.0), 0.0, 0.01, "and rests")


func test_it_repeats_exactly() -> void:
	var tide := _tide()
	for t in [0.0, 7.0, 15.0, 28.0]:
		assert_almost_eq(tide.level_at(t), tide.level_at(t + tide.period), 0.001)


func test_high_water_is_a_room_with_no_open_floor_left() -> void:
	var tide := _tide()
	assert_false(tide.is_flooded(0.0))
	assert_true(tide.is_flooded(15.0))


func test_phase_lets_a_floor_start_mid_tide() -> void:
	var early := _tide()
	var late := _tide()
	late.phase = 0.35
	assert_ne(early.level_at(0.0), late.level_at(0.0))


func test_it_drives_the_field_it_is_given() -> void:
	var field := LightField.new(10, 10)
	var tide := _tide()
	tide.apply(field, 0.0)
	assert_true(field.is_shade(Vector2i(5, 5)))
	tide.apply(field, 15.0)
	assert_true(field.is_glare(Vector2i(5, 5)), "the whole floor goes")


func test_nooks_still_hold_at_high_water() -> void:
	var field := LightField.new(10, 10)
	field.set_nook(Vector2i(2, 2), true)
	_tide().apply(field, 15.0)
	assert_true(field.is_deep_shade(Vector2i(2, 2)), "an alcove is an alcove")


func test_a_tide_that_does_not_rise_is_an_error() -> void:
	var text := "id: x\ntide: low=0.5 high=0.1 period=20\n\n###\n#@#\n###"
	assert_false(ChamberData.from_text(text).is_valid())


func test_a_tide_without_a_period_is_an_error() -> void:
	assert_false(ChamberData.from_text("id: x\ntide: period=0\n\n###\n#@#\n###").is_valid())


func test_the_drowned_stair_is_a_tide_floor() -> void:
	var data := ChamberData.from_file("res://chambers/drowned_stair.txt")
	assert_true(data.is_valid(), str(data.parse_errors))
	assert_true(data.has_tide())
	assert_true(data.exit_is_reachable())
	assert_true(data.build_field().is_deep_shade(data.spawn))


func test_it_has_alcoves_to_wait_out_the_flood_in() -> void:
	var data := ChamberData.from_file("res://chambers/drowned_stair.txt")
	var field := data.build_field()
	data.build_tide().apply(field, 15.0)
	var refuges := 0
	for cell in data.reachable_floor():
		if field.is_shade(cell):
			refuges += 1
	assert_gt(refuges, 8, "there must be somewhere to be when it comes in")


func test_the_live_chamber_runs_its_tide() -> void:
	var chamber := Chamber.new()
	chamber.chamber_path = "res://chambers/drowned_stair.txt"
	add_child_autofree(chamber)
	assert_not_null(chamber.tide)
	var open_floor := Vector2i(20, 16)
	var readings := {}
	for step in 200:
		chamber._process(0.25)
		readings[chamber.field.is_glare(open_floor)] = true
	assert_eq(readings.size(), 2, "the same floor drowns and drains")


func test_the_stair_is_the_bottom_of_the_climb() -> void:
	assert_eq(Game.DEFAULT_ORDER[0], "drowned_stair")
	assert_eq(Progress.FIRST_CHAMBER, "drowned_stair")
	assert_eq(Game.next_after("drowned_stair", ""), "cistern")
