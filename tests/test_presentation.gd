extends GutTest


func after_each() -> void:
	get_tree().paused = false


func _room(path: String = "res://chambers/cistern.txt") -> Chamber:
	var chamber := Chamber.new()
	chamber.chamber_path = path
	add_child_autofree(chamber)
	return chamber


func test_a_floor_names_itself_on_arrival() -> void:
	var room := _room()
	assert_not_null(room.card)
	assert_true(room.card.showing)
	assert_string_contains(room.data.title, "Cistern")


func test_the_card_leaves_without_being_dismissed() -> void:
	assert_almost_eq(FloorCard.alpha_at(0.0), 0.0, 0.01, "it fades in")
	assert_almost_eq(FloorCard.alpha_at(FloorCard.FADE_SECONDS), 1.0, 0.01)
	assert_almost_eq(FloorCard.alpha_at(FloorCard.total_seconds()), 0.0, 0.01, "and out")
	assert_almost_eq(FloorCard.alpha_at(FloorCard.total_seconds() + 5.0), 0.0, 0.01)


func test_every_floor_has_something_to_call_itself() -> void:
	for id in Game.DEFAULT_ORDER:
		var data := ChamberData.from_file(Game.path_for(id))
		assert_false(data.title.is_empty(), "%s has no title" % id)
		assert_false(data.subtitle.is_empty(), "%s has no subtitle" % id)


func test_a_floor_can_always_be_started_over() -> void:
	var room := _room()
	watch_signals(room)
	assert_not_null(room.pause_menu)
	room.pause_menu.restart_requested.emit()
	assert_signal_emitted(room, "restart_requested")


func test_the_pause_menu_stops_and_restarts_the_world() -> void:
	var room := _room()
	room.pause_menu.open()
	assert_true(room.pause_menu.is_open())
	assert_true(get_tree().paused)
	room.pause_menu.close()
	assert_false(room.pause_menu.is_open())
	assert_false(get_tree().paused)


func test_restarting_a_floor_rebuilds_it_fresh() -> void:
	var game: Game = load("res://scenes/Game.tscn").instantiate()
	add_child_autofree(game)
	var lamp: Vector2i = game.chamber.data.lights[0]["cell"]
	game.chamber.cling.snuff(game.chamber.data.light_id_at(lamp))
	assert_true(game.chamber.cling.is_snuffed(game.chamber.data.light_id_at(lamp)))
	game.chamber.restart_requested.emit()
	assert_false(
		game.chamber.cling.is_snuffed(game.chamber.data.light_id_at(lamp)),
		"the room comes back as it was"
	)


func test_the_frame_kicks_only_when_she_comes_apart() -> void:
	var room := _room()
	assert_eq(room._shake, 0.0)
	room.umbra.state.scatter()
	assert_gt(room._shake, 0.0, "the one shake in the game")
	for step in 30:
		room._shake_camera(0.1)
	assert_eq(room._shake, 0.0, "and it settles")


func test_the_project_is_called_what_the_game_is_called() -> void:
	assert_eq(ProjectSettings.get_setting("application/config/name"), "PENUMBRA")
