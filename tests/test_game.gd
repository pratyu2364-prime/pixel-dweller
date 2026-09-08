extends GutTest

const GAME := preload("res://scenes/Game.tscn")


func test_the_climb_starts_in_the_cellar() -> void:
	var game: Game = GAME.instantiate()
	add_child_autofree(game)
	assert_eq(game.current_id, "cistern")
	assert_not_null(game.chamber.umbra)


func test_every_chamber_in_the_climb_exists_and_parses() -> void:
	for id in Game.DEFAULT_ORDER:
		var data := ChamberData.from_file(Game.path_for(id))
		assert_true(data.is_valid(), "%s: %s" % [id, str(data.parse_errors)])
		assert_true(data.exit_is_reachable(), "%s has no way out" % id)


func test_floors_follow_the_climb_order() -> void:
	assert_eq(Game.next_after("cistern", ""), "candle_rows")
	assert_eq(Game.next_after("lantern_room", ""), "", "the top of the stack ends the run")


func test_a_chamber_can_reroute_itself() -> void:
	assert_eq(Game.next_after("cistern", "prism_hall"), "prism_hall")


func test_entering_a_chamber_replaces_the_last_one() -> void:
	var game: Game = GAME.instantiate()
	add_child_autofree(game)
	watch_signals(game)
	game.enter("warden_walk")
	assert_eq(game.current_id, "warden_walk")
	assert_eq(game.chamber.data.id, "warden_walk")
	assert_signal_emitted(game, "chamber_entered")
	var chambers := 0
	for child in game.get_children():
		if child is Chamber:
			chambers += 1
	assert_eq(chambers, 1, "only one floor is ever live")


func test_the_last_floor_ends_in_a_choice_not_a_score() -> void:
	var game: Game = GAME.instantiate()
	add_child_autofree(game)
	game.enter("lantern_room")
	watch_signals(game)
	game.chamber.umbra.global_position = game.chamber.data.cell_to_world(game.chamber.data.exit)
	game.chamber._process(0.016)
	assert_signal_emitted_with_parameters(game, "ending_reached", ["rejoin"])
	assert_true(game.progress.has_finished())
