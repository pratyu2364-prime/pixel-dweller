extends GutTest

## PENUMBRA is a game about being punished by light, which is exactly the kind
## of game that needs a way to turn the punishment down. These tests hold the
## line that gentle mode changes the cost of being wrong and nothing else.

const TEST_PATH := "user://test_options.json"


func after_each() -> void:
	PlayerOptions.clear(TEST_PATH)


func test_the_default_is_the_game_as_designed() -> void:
	var options := PlayerOptions.new()
	assert_false(options.gentle)
	assert_eq(options.drain_multiplier(), 1.0)
	assert_eq(options.bonus_ink(), 0.0)


func test_gentle_softens_the_light_and_deepens_her_pockets() -> void:
	var options := PlayerOptions.new()
	options.gentle = true
	assert_lt(options.drain_multiplier(), 1.0)
	assert_gt(options.bonus_ink(), 0.0)


func test_gentle_buys_time_rather_than_immunity() -> void:
	var normal := ShadowState.new()
	var gentle := ShadowState.new()
	gentle.drain_scale = PlayerOptions.GENTLE_DRAIN
	for i in 20:
		normal.tick(0.1, 1.0, false)
		gentle.tick(0.1, 1.0, false)
	assert_gt(gentle.coherence, normal.coherence, "she lasts longer")
	assert_lt(gentle.coherence, ShadowState.MAX_COHERENCE, "but the light still hurts")


func test_options_round_trip_through_a_file() -> void:
	var options := PlayerOptions.new()
	options.gentle = true
	options.high_contrast = true
	options.reduced_motion = true
	options.volume = 0.35
	options.save(TEST_PATH)
	var loaded := PlayerOptions.load_from(TEST_PATH)
	assert_true(loaded.gentle)
	assert_true(loaded.high_contrast)
	assert_true(loaded.reduced_motion)
	assert_almost_eq(loaded.volume, 0.35, 0.001)


func test_a_corrupt_options_file_is_the_defaults_not_a_crash() -> void:
	var file := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	file.store_string("nonsense")
	file.close()
	assert_false(PlayerOptions.load_from(TEST_PATH).gentle)


func test_silence_is_reachable() -> void:
	var options := PlayerOptions.new()
	options.volume = 0.0
	assert_lt(options.volume_db(), -60.0)


func test_a_chamber_honours_gentle_mode() -> void:
	var chamber := Chamber.new()
	chamber.chamber_path = "res://chambers/cistern.txt"
	add_child_autofree(chamber)
	chamber.options.gentle = true
	chamber.apply_boons()
	assert_almost_eq(chamber.umbra.state.drain_scale, PlayerOptions.GENTLE_DRAIN, 0.001)
	assert_gt(chamber.umbra.state.max_ink(), ShadowState.MAX_INK)


func test_reduced_motion_kills_the_shake() -> void:
	var chamber := Chamber.new()
	chamber.chamber_path = "res://chambers/cistern.txt"
	add_child_autofree(chamber)
	chamber.options.reduced_motion = true
	chamber.umbra.state.scatter()
	chamber._shake_camera(0.016)
	assert_eq(chamber._shake, 0.0, "no shake for anyone who asked for none")


func test_gentle_mode_does_not_move_the_safety_line() -> void:
	# The rooms, the routes and the endings must be identical either way.
	var chamber := Chamber.new()
	chamber.chamber_path = "res://chambers/cistern.txt"
	add_child_autofree(chamber)
	var before := chamber.field.levels()
	chamber.options.gentle = true
	chamber.options.high_contrast = true
	chamber.apply_boons()
	assert_eq(chamber.field.levels(), before, "the light itself is untouched")


func test_the_title_screen_offers_the_toggles() -> void:
	var title: TitleScreen = load("res://scenes/Title.tscn").instantiate()
	add_child_autofree(title)
	var row := title.get_node("Menu/Options")
	assert_eq(row.get_child_count(), 3, "gentle, contrast, motion")
	for child in row.get_children():
		assert_true(child is CheckButton)
