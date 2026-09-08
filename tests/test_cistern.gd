extends GutTest

## The Cistern is the first thing a player touches, so it gets guarded like a
## contract: it must parse, be walkable end to end, and teach the rule safely.

const GAME := preload("res://scenes/Game.tscn")

var data: ChamberData


func before_all() -> void:
	data = ChamberData.from_file("res://chambers/cistern.txt")


func test_it_parses() -> void:
	assert_true(data.is_valid(), str(data.parse_errors))


func test_it_is_sealed_by_a_wall_border() -> void:
	for x in data.width:
		assert_true(data.is_wall(Vector2i(x, 0)), "top row leaks at %d" % x)
		assert_true(data.is_wall(Vector2i(x, data.height - 1)), "bottom row leaks at %d" % x)
	for y in data.height:
		assert_true(data.is_wall(Vector2i(0, y)), "left wall leaks at %d" % y)
		assert_true(data.is_wall(Vector2i(data.width - 1, y)), "right wall leaks at %d" % y)


func test_the_exit_is_walkable_from_the_spawn() -> void:
	assert_true(data.exit_is_reachable())


func test_umbra_starts_safe() -> void:
	var field := data.build_field()
	assert_true(field.is_shade(data.spawn), "you are never born in the light")
	assert_true(field.is_deep_shade(data.spawn), "and you start able to charge ink")


func test_the_room_is_mostly_dark_but_not_empty() -> void:
	var field := data.build_field()
	var lit := 0
	var floor_cells := 0
	for y in data.height:
		for x in data.width:
			var cell := Vector2i(x, y)
			if data.is_wall(cell):
				continue
			floor_cells += 1
			if field.is_glare(cell):
				lit += 1
	var ratio := float(lit) / float(floor_cells)
	assert_gt(ratio, 0.05, "a chamber with no light has no game in it")
	assert_lt(ratio, 0.5, "the Cistern is a dark room with lights, not the reverse")


func test_there_is_a_safe_route_that_never_crosses_glare() -> void:
	# Not required of every chamber, but the tutorial floor must be beatable
	# without ever spending coherence.
	var field := data.build_field()
	var seen := {data.spawn: true}
	var queue: Array[Vector2i] = [data.spawn]
	var head := 0
	while head < queue.size():
		var cell: Vector2i = queue[head]
		head += 1
		for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = cell + offset
			if seen.has(next) or not data.in_bounds(next) or data.is_wall(next):
				continue
			if not field.is_shade(next):
				continue
			seen[next] = true
			queue.append(next)
	assert_true(seen.has(data.exit), "the Cistern can be solved by hiding alone")


func test_the_game_scene_builds_a_live_chamber() -> void:
	var game: Node2D = GAME.instantiate()
	add_child_autofree(game)
	var chamber: Chamber = game.get_node("Chamber")
	assert_not_null(chamber.field)
	assert_not_null(chamber.umbra)
	assert_eq(chamber.umbra.current_cell(), chamber.data.spawn)
	assert_not_null(chamber.get_node("Walls"), "walls became collision")


func test_casting_in_the_live_chamber_darkens_the_field() -> void:
	var game: Node2D = GAME.instantiate()
	add_child_autofree(game)
	var chamber: Chamber = game.get_node("Chamber")
	var lamp: Vector2i = chamber.data.lights[0]["cell"]
	var target := lamp
	for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var candidate: Vector2i = lamp + offset
		if not chamber.data.is_wall(candidate) and chamber.field.is_glare(candidate):
			target = candidate
			break
	assert_ne(target, lamp, "a lamp spills onto some open floor")
	assert_true(chamber.field.is_glare(target), "next to a lamp is lit")
	chamber.umbra.global_position = chamber.data.cell_to_world(target)
	assert_true(chamber.umbra.try_cast())
	assert_true(chamber.field.is_shade(target), "the puff lands where she stands")


func test_reaching_the_exit_ends_the_floor_once() -> void:
	var game: Node2D = GAME.instantiate()
	add_child_autofree(game)
	var chamber: Chamber = game.get_node("Chamber")
	watch_signals(chamber)
	chamber.umbra.global_position = chamber.data.cell_to_world(chamber.data.exit)
	chamber._process(0.016)
	chamber._process(0.016)
	assert_signal_emit_count(chamber, "exit_reached", 1)
