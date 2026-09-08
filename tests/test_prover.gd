extends GutTest

## Moving light made hand-checking a floor impossible, so fairness is proved
## rather than eyeballed: for every chamber in the climb there exists a route
## from spawn to exit that never stands in glare.

const HORIZON := 40


func _prove(id: String) -> ChamberProver:
	return ChamberProver.new(ChamberData.from_file(Game.path_for(id)), HORIZON)


func test_every_floor_in_the_climb_has_a_safe_route() -> void:
	for id in Game.DEFAULT_ORDER:
		var prover := _prove(id)
		assert_true(prover.reachable, prover.report())


func test_no_floor_demands_an_unreasonable_number_of_crossings() -> void:
	for id in Game.DEFAULT_ORDER:
		var prover := _prove(id)
		assert_lt(prover.ink_spent, ChamberProver.MAX_SPEND, "%s asks too much" % id)


func test_no_floor_is_a_marathon() -> void:
	for id in Game.DEFAULT_ORDER:
		var prover := _prove(id)
		assert_lt(prover.seconds_taken(), 90.0, "%s is too long a hold" % id)


func test_the_prover_refuses_a_room_with_no_way_through() -> void:
	var sealed := ChamberData.from_text("id: x\n\n#####\n#@#>#\n#####")
	assert_false(ChamberProver.new(sealed, 8).reachable)


func test_the_prover_will_not_walk_through_standing_light() -> void:
	# A corridor plugged by a lamp: passable only by spending ink.
	var text := "id: x\n\n##########\n#@..ss..>#\n##########"
	var prover := ChamberProver.new(ChamberData.from_text(text), 12)
	assert_true(prover.reachable)
	assert_eq(prover.ink_spent, 2, "two lit cells, two puffs, and not one more")


func test_without_ink_a_wall_of_light_is_a_wall() -> void:
	var text := "id: x\n\n###########\n#@sssssss>#\n###########"
	var prover := ChamberProver.new(ChamberData.from_text(text), 12)
	assert_false(prover.reachable, "three charges do not cross seven lit cells")


func test_a_sweeping_beam_opens_and_closes_a_corridor() -> void:
	var text := (
		"id: x\nsweep: id=eye cell=(5,3) period=8 arc=0.35 light=9\n\n"
		+ "###########\n"
		+ "#@.......>#\n"
		+ "#.........#\n"
		+ "#.........#\n"
		+ "###########"
	)
	var prover := ChamberProver.new(ChamberData.from_text(text), 40)
	assert_true(prover.reachable, "waiting for the beam to pass is a solution")


func test_the_prover_is_cheap_enough_to_run_on_every_build() -> void:
	var started := Time.get_ticks_msec()
	var prover := _prove("orrery")
	assert_true(prover.reachable)
	assert_lt(Time.get_ticks_msec() - started, 5000, "fairness has to stay affordable")
