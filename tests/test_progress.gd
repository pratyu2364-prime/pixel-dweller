extends GutTest

const TEST_PATH := "user://test_penumbra.json"


func after_each() -> void:
	Progress.clear(TEST_PATH)


func test_a_fresh_save_starts_at_the_bottom() -> void:
	var p := Progress.new()
	assert_eq(p.reached, Progress.FIRST_CHAMBER)
	assert_eq(Progress.FIRST_CHAMBER, Game.DEFAULT_ORDER[0], "the save starts where the climb does")
	assert_false(p.has_started())


func test_entering_a_floor_only_moves_forward() -> void:
	var p := Progress.new()
	p.enter("orrery", Game.DEFAULT_ORDER)
	assert_eq(p.reached, "orrery")
	p.enter("cistern", Game.DEFAULT_ORDER)
	assert_eq(p.reached, "orrery", "replaying an early floor keeps your place")


func test_an_unknown_floor_is_still_recorded() -> void:
	var p := Progress.new()
	p.reached = "nowhere"
	p.enter("orrery", Game.DEFAULT_ORDER)
	assert_eq(p.reached, "orrery")


func test_completion_is_recorded_once() -> void:
	var p := Progress.new()
	p.complete("cistern")
	p.complete("cistern")
	assert_eq(p.completed.size(), 1)
	assert_true(p.is_complete("cistern"))


func test_it_round_trips_through_a_file() -> void:
	var p := Progress.new()
	p.enter("warden_walk", Game.DEFAULT_ORDER)
	p.complete("cistern")
	p.record_scatter()
	p.add_time(12.5)
	p.save(TEST_PATH)
	var loaded := Progress.load_from(TEST_PATH)
	assert_eq(loaded.reached, "warden_walk")
	assert_eq(loaded.completed, ["cistern"] as Array[String])
	assert_eq(loaded.scatters, 1)
	assert_almost_eq(loaded.seconds_played, 12.5, 0.001)


func test_a_missing_save_is_a_fresh_start_not_a_crash() -> void:
	assert_false(Progress.load_from("user://definitely_not_here.json").has_started())


func test_a_corrupt_save_is_a_fresh_start_not_a_crash() -> void:
	var file := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	file.store_string("{ this is not json")
	file.close()
	assert_false(Progress.load_from(TEST_PATH).has_started())


func test_the_menu_says_where_she_is_and_what_it_cost() -> void:
	var p := Progress.new()
	assert_eq(TitleScreen.subtitle_for(p), "", "a new save says nothing")
	p.enter("orrery", Game.DEFAULT_ORDER)
	assert_string_contains(TitleScreen.subtitle_for(p), "The Orrery")
	assert_string_contains(TitleScreen.subtitle_for(p), "never yet scattered")
	p.record_scatter()
	assert_string_contains(TitleScreen.subtitle_for(p), "scattered once")
	p.record_scatter()
	assert_string_contains(TitleScreen.subtitle_for(p), "scattered 2 times")


func test_every_floor_in_the_climb_has_a_name_for_the_menu() -> void:
	for id in Game.DEFAULT_ORDER:
		assert_true(TitleScreen.FLOOR_NAMES.has(id), "%s has no name on the menu" % id)


func test_the_title_offers_descend_only_once_there_is_somewhere_to_descend_to() -> void:
	var title: TitleScreen = load("res://scenes/Title.tscn").instantiate()
	add_child_autofree(title)
	title.progress = Progress.new()
	title.refresh()
	assert_false(title.get_node("Menu/Continue").visible)
	title.progress.enter("orrery", Game.DEFAULT_ORDER)
	title.refresh()
	assert_true(title.get_node("Menu/Continue").visible)
	assert_eq(title.get_node("Menu/Begin").text, "begin again")
