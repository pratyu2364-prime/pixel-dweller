extends GutTest

## The prover works on an idealised grid. The bot walks the same route with the
## real body — acceleration, collision, light sampling, coherence drain — so the
## gap between "provably safe" and "actually playable" is a failing test rather
## than a discovery made by a player.

const STEP := 1.0 / 30.0
const MAX_TICKS := 2400  ## 80 seconds of simulated play


## A paused tree stops the physics server, and a bot that cannot move looks
## exactly like an unplayable floor. Any test that pauses must not leak it.
func before_each() -> void:
	get_tree().paused = false


func _play(id: String) -> AutoPlayer:
	# Bodies from the previous test only leave the physics space on a real
	# physics frame; without this the last floor's walls stand invisibly in this
	# one and the bot jams on nothing.
	await get_tree().physics_frame
	await get_tree().physics_frame
	var data := ChamberData.from_file(Game.path_for(id))
	var prover := ChamberProver.new(data, 40)
	assert_true(prover.reachable, "%s has no proven route to walk" % id)

	# Each floor gets its own physics world. Chambers from earlier tests are not
	# flushed out of the shared space until a real physics frame runs, and their
	# walls would otherwise sit invisibly across this one.
	var world := SubViewport.new()
	add_child_autofree(world)
	var chamber := Chamber.new()
	chamber.chamber_path = Game.path_for(id)
	world.add_child(chamber)
	var bot := AutoPlayer.new()
	add_child_autofree(bot)
	bot.drive(chamber, prover.route)

	var ticks := 0
	while not bot.done and ticks < MAX_TICKS:
		bot.step(STEP)
		chamber.umbra._physics_process(STEP)
		chamber._process(STEP)
		ticks += 1
	return bot


func test_the_first_floor_can_actually_be_walked() -> void:
	var bot: AutoPlayer = await _play("cistern")
	assert_true(bot.reached_exit, bot.report())


func test_a_floor_of_moving_light_can_actually_be_walked() -> void:
	var bot: AutoPlayer = await _play("orrery")
	assert_true(bot.reached_exit, bot.report())


func test_the_bot_steers_through_the_same_input_a_phone_uses() -> void:
	var data := ChamberData.from_file(Game.path_for("cistern"))
	var prover := ChamberProver.new(data, 40)
	var chamber := Chamber.new()
	chamber.chamber_path = Game.path_for("cistern")
	add_child_autofree(chamber)
	var bot := AutoPlayer.new()
	add_child_autofree(bot)
	bot.drive(chamber, prover.route)
	bot.step(STEP)
	assert_gt(chamber.umbra.touch_direction.length(), 0.0, "it drives the real input path")


func test_it_aims_at_the_next_cell_on_the_route() -> void:
	var data := ChamberData.from_file(Game.path_for("cistern"))
	assert_gt(ChamberProver.new(data, 40).route.size(), 0, "there is a route to aim along")
	var prover := ChamberProver.new(data, 40)
	var chamber := Chamber.new()
	chamber.chamber_path = Game.path_for("cistern")
	add_child_autofree(chamber)
	var bot := AutoPlayer.new()
	add_child_autofree(bot)
	bot.drive(chamber, prover.route)
	assert_eq(bot.target(), prover.route[0], "it starts by aiming at the first cell")


func test_a_proven_route_starts_at_the_spawn_and_ends_at_the_exit() -> void:
	for id in Game.DEFAULT_ORDER:
		var data := ChamberData.from_file(Game.path_for(id))
		var prover := ChamberProver.new(data, 40)
		assert_eq(prover.route[0], data.spawn, "%s: route starts somewhere else" % id)
		assert_eq(prover.route[prover.route.size() - 1], data.exit, "%s: route ends elsewhere" % id)


func test_a_proven_route_never_steps_through_a_wall() -> void:
	for id in Game.DEFAULT_ORDER:
		var data := ChamberData.from_file(Game.path_for(id))
		var prover := ChamberProver.new(data, 40)
		for i in prover.route.size():
			var cell: Vector2i = prover.route[i]
			assert_false(data.is_wall(cell), "%s: route enters a wall at %s" % [id, cell])
			if i > 0:
				var step: Vector2i = cell - prover.route[i - 1]
				assert_lte(absi(step.x) + absi(step.y), 1, "%s: route teleports" % id)
