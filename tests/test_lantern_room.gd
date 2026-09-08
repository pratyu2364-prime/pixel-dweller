extends GutTest

## The finale. It has to be finishable, it has to be a choice, and neither
## choice may be called the right one.

var data: ChamberData


func before_all() -> void:
	data = ChamberData.from_file("res://chambers/lantern_room.txt")


func _room() -> Chamber:
	var chamber := Chamber.new()
	chamber.chamber_path = "res://chambers/lantern_room.txt"
	add_child_autofree(chamber)
	return chamber


func test_it_parses_with_a_keeper_and_a_chain() -> void:
	assert_true(data.is_valid(), str(data.parse_errors))
	assert_eq(data.keeper_cell, Vector2i(18, 3))
	assert_eq(data.chain["feeders"].size(), 3)
	assert_ne(data.light_id_at(data.chain["great"]), "", "the great lamp is a real light")


func test_a_chain_without_feeders_is_an_error() -> void:
	assert_false(ChamberData.from_text("id: x\nchain: great=(1,1)\n\n###\n#@#\n###").is_valid())


func test_a_keeper_with_nowhere_to_stand_is_an_error() -> void:
	assert_false(ChamberData.from_text("id: x\nkeeper: who=me\n\n###\n#@#\n###").is_valid())


func test_the_great_lamp_dims_one_share_per_feeder() -> void:
	var room := _room()
	assert_almost_eq(room.chain.fraction(), 1.0, 0.001)
	room.cling.snuff(room.chain.feeder_ids[0])
	assert_almost_eq(room.chain.fraction(), 2.0 / 3.0, 0.01)
	assert_almost_eq(
		room.field.get_emitter(room.chain.great_id).intensity, 2.0 / 3.0, 0.01,
		"the room itself gets darker"
	)


func test_the_great_lamp_refuses_to_be_touched_while_it_is_fed() -> void:
	var room := _room()
	assert_true(room.cling.is_locked(room.chain.great_id))
	assert_false(room.cling.snuff(room.chain.great_id), "you cannot skip the work")
	assert_eq(room.cling.press(data.chain["great"]), "locked")


func test_putting_out_all_three_unlocks_the_lamp() -> void:
	var room := _room()
	watch_signals(room.chain)
	for id in room.chain.feeder_ids:
		room.cling.snuff(id)
	assert_true(room.chain.is_extinguishable())
	assert_false(room.cling.is_locked(room.chain.great_id))
	assert_signal_emitted(room.chain, "extinguishable")


func test_a_warden_relighting_a_feeder_locks_it_again() -> void:
	var room := _room()
	for id in room.chain.feeder_ids:
		room.cling.snuff(id)
	room.cling.relight(room.chain.feeder_ids[0])
	assert_true(room.cling.is_locked(room.chain.great_id), "the work comes undone")
	assert_almost_eq(room.chain.fraction(), 1.0 / 3.0, 0.01)


func test_snuffing_the_lamp_is_one_ending() -> void:
	var room := _room()
	watch_signals(room)
	for id in room.chain.feeder_ids:
		room.cling.snuff(id)
	room.cling.snuff(room.chain.great_id)
	assert_signal_emitted_with_parameters(room, "ending_reached", ["free"])


func test_taking_the_stair_is_the_other() -> void:
	var room := _room()
	watch_signals(room)
	room.umbra.global_position = room.data.cell_to_world(room.data.exit)
	room._process(0.016)
	assert_signal_emitted_with_parameters(room, "ending_reached", ["rejoin"])


func test_both_endings_have_words_and_neither_has_a_score() -> void:
	assert_true(EndingScreen.has_ending("free"))
	assert_true(EndingScreen.has_ending("rejoin"))
	for kind in ["free", "rejoin"]:
		var entry: Dictionary = EndingScreen.TEXT[kind]
		assert_gt(String(entry["body"]).length(), 40)
		assert_false(String(entry["body"]).to_lower().contains("score"))


func test_the_keeper_walks_toward_her_and_never_runs() -> void:
	var field := LightField.new(30, 20)
	var keeper := Keeper.new()
	add_child_autofree(keeper)
	keeper.setup(field, Vector2i(2, 2))
	keeper.follow(Vector2i(20, 2))
	keeper._physics_process(1.0)
	assert_almost_eq(float(keeper.current_cell().x), 2.0 + Keeper.SPEED, 0.6)
	assert_lt(Keeper.SPEED * 16.0, Umbra.BASE_SPEED, "she can always outwalk him")


func test_the_keeper_is_a_moving_pool_of_light() -> void:
	var field := LightField.new(30, 20)
	var keeper := Keeper.new()
	add_child_autofree(keeper)
	keeper.setup(field, Vector2i(5, 5))
	assert_true(field.is_glare(Vector2i(5, 5)))
	keeper.follow(Vector2i(20, 5))
	for step in 20:
		keeper._physics_process(0.2)
	assert_eq(field.get_emitter(keeper.lantern_id()).cell, keeper.current_cell())


func test_the_keeper_arriving_scatters_her_rather_than_killing_her() -> void:
	var room := _room()
	room.umbra.global_position = room.data.cell_to_world(room.keeper.current_cell())
	room.keeper.follow(room.umbra.current_cell())
	room.keeper._physics_process(0.1)
	assert_true(room.umbra.state.is_scattered, "he arrives; he does not strike")


func test_the_room_can_be_reached_and_left_on_foot() -> void:
	assert_true(data.exit_is_reachable())
	assert_true(data.build_field().is_deep_shade(data.spawn))
	assert_eq(Game.next_after("prism_hall", ""), "lantern_room")
