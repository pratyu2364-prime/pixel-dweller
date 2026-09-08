extends GutTest

## Placing a memory in the light is easy. Placing one that can actually be
## taken — and then walked away from — is the part a designer gets wrong, so it
## is proved rather than assumed.
##
## The prover is told to route through the memory before the exit counts, using
## the same rules as any other run: never stand in glare without a puff to
## throw, and puffs only come back in deep shade.

const HORIZON := 60
## A memory should never be worth more than a couple of crossings, and capping
## the search keeps the proof affordable enough to run on every build.
const MAX_CROSSINGS := 3


func _prove_memory(id: String) -> ChamberProver:
	var data := ChamberData.from_file(Game.path_for(id))
	var memory: Vector2i = data.memories[0]["cell"]
	return ChamberProver.new(data, HORIZON, memory, MAX_CROSSINGS)


func test_every_memory_can_be_taken_on_a_run_that_still_finishes() -> void:
	for id in Game.DEFAULT_ORDER:
		var prover := _prove_memory(id)
		assert_true(prover.reachable, "%s: its memory cannot be collected" % id)


func test_a_detour_for_a_memory_actually_visits_it() -> void:
	for id in Game.DEFAULT_ORDER:
		var data := ChamberData.from_file(Game.path_for(id))
		var memory: Vector2i = data.memories[0]["cell"]
		var prover := ChamberProver.new(data, HORIZON, memory, MAX_CROSSINGS)
		assert_true(prover.route.has(memory), "%s: the proof skipped the memory" % id)
		assert_eq(prover.route[prover.route.size() - 1], data.exit)


func test_the_detour_costs_something() -> void:
	# If reaching a memory were free, it would not be a choice. Every floor's
	# memory run must cost either time or ink against the direct route.
	for id in Game.DEFAULT_ORDER:
		var data := ChamberData.from_file(Game.path_for(id))
		var direct := ChamberProver.new(data, HORIZON)
		var detour := ChamberProver.new(data, HORIZON, data.memories[0]["cell"], MAX_CROSSINGS)
		var costs_more := (
			detour.slices_taken > direct.slices_taken or detour.ink_spent > direct.ink_spent
		)
		assert_true(costs_more, "%s: its memory is on the way, so it asks nothing" % id)


func test_no_memory_demands_more_than_she_can_carry_and_recharge() -> void:
	for id in Game.DEFAULT_ORDER:
		var prover := _prove_memory(id)
		assert_lte(prover.ink_spent, MAX_CROSSINGS, "%s asks too much for it" % id)


func test_a_memory_walled_off_from_the_route_fails_the_proof() -> void:
	var text := (
		"id: x\nmemory: at=(1,3) unreachable\n\n"
		+ "#######\n"
		+ "#@...>#\n"
		+ "#######\n"
		+ "#*#####\n"
		+ "#######"
	)
	var data := ChamberData.from_text(text)
	assert_true(data.is_valid(), str(data.parse_errors))
	assert_false(ChamberProver.new(data, 12, data.memories[0]["cell"], MAX_CROSSINGS).reachable)


func test_without_a_detour_the_proof_is_the_direct_route() -> void:
	var data := ChamberData.from_file(Game.path_for("cistern"))
	var direct := ChamberProver.new(data, HORIZON)
	var same := ChamberProver.new(data, HORIZON, Vector2i(-1, -1))
	assert_eq(direct.slices_taken, same.slices_taken)
