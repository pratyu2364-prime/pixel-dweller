extends GutTest

## Moving light is only fair if it is predictable, so the Orrery's timing is
## pinned down here rather than left to feel.


func test_an_orbit_returns_to_where_it_started() -> void:
	var mover := MovingLight.new("p", MovingLight.Kind.ORBIT)
	mover.center = Vector2(10, 10)
	mover.radius = 4.0
	mover.period = 8.0
	var start := mover.position()
	mover.advance(4.0)
	assert_gt(start.distance_to(mover.position()), 6.0, "halfway round is across the circle")
	mover.advance(4.0)
	assert_almost_eq(start.distance_to(mover.position()), 0.0, 0.001, "and back again")


func test_an_orbit_keeps_its_radius() -> void:
	var mover := MovingLight.new("p", MovingLight.Kind.ORBIT)
	mover.center = Vector2(10, 10)
	mover.radius = 4.0
	mover.period = 6.0
	for step in 30:
		mover.advance(0.2)
		assert_almost_eq(mover.center.distance_to(mover.position()), 4.0, 0.001)


func test_phase_staggers_two_lamps_on_the_same_ring() -> void:
	var a := MovingLight.new("a", MovingLight.Kind.ORBIT)
	var b := MovingLight.new("b", MovingLight.Kind.ORBIT)
	for mover in [a, b]:
		mover.center = Vector2(10, 10)
		mover.radius = 5.0
		mover.period = 10.0
	b.phase = 0.5
	assert_gt(a.position().distance_to(b.position()), 9.0, "opposite sides of the ring")


func test_direction_reverses_when_counter_clockwise() -> void:
	var cw := MovingLight.new("cw", MovingLight.Kind.ORBIT)
	var ccw := MovingLight.new("ccw", MovingLight.Kind.ORBIT)
	for mover in [cw, ccw]:
		mover.center = Vector2(10, 10)
		mover.radius = 5.0
		mover.period = 8.0
	ccw.clockwise = false
	cw.advance(1.0)
	ccw.advance(1.0)
	assert_almost_eq(cw.position().x, ccw.position().x, 0.001)
	assert_ne(cw.position().y, ccw.position().y)


func test_a_beam_lights_ahead_and_leaves_the_rest_dark() -> void:
	var field := LightField.new(30, 30)
	var beam := MovingLight.new("eye", MovingLight.Kind.SWEEP)
	beam.center = Vector2(15, 15)
	beam.period = 12.0
	beam.half_angle = 0.3
	beam.install(field, 12.0)
	assert_true(field.is_glare(Vector2i(18, 15)), "the beam falls where it points")
	assert_true(field.is_shade(Vector2i(15, 18)), "and nowhere else")


func test_a_sweeping_beam_eventually_finds_every_side() -> void:
	var field := LightField.new(30, 30)
	var beam := MovingLight.new("eye", MovingLight.Kind.SWEEP)
	beam.center = Vector2(15, 15)
	beam.period = 12.0
	beam.half_angle = 0.3
	beam.install(field, 12.0)
	var was_lit := false
	for step in 120:
		beam.advance(0.1)
		beam.apply(field)
		if field.is_glare(Vector2i(15, 18)):
			was_lit = true
	assert_true(was_lit, "standing still is not a plan")


func test_a_beam_still_respects_walls() -> void:
	var field := LightField.new(30, 30)
	for y in range(10, 21):
		field.set_opaque(Vector2i(18, y), true)
	var beam := MovingLight.new("eye", MovingLight.Kind.SWEEP)
	beam.center = Vector2(15, 15)
	beam.half_angle = 0.5
	beam.install(field, 12.0)
	assert_true(field.is_shade(Vector2i(20, 15)), "a pillar still throws a shadow")


func test_movers_parse_from_chamber_front_matter() -> void:
	var text := "id: x\norbit: id=p1 center=(9,9) radius=3 period=5 light=4\n\n#####\n#@..#\n#####"
	var data := ChamberData.from_text(text)
	assert_true(data.is_valid(), str(data.parse_errors))
	assert_eq(data.movers.size(), 1)
	assert_eq(data.movers[0]["id"], "p1")
	assert_eq(data.movers[0]["center"], Vector2(9, 9))


func test_a_zero_period_mover_is_an_error() -> void:
	var data := ChamberData.from_text("id: x\norbit: id=p1 period=0\n\n###\n#@#\n###")
	assert_false(data.is_valid())


func test_the_orrery_parses_and_is_completable() -> void:
	var data := ChamberData.from_file("res://chambers/orrery.txt")
	assert_true(data.is_valid(), str(data.parse_errors))
	assert_eq(data.movers.size(), 3)
	assert_true(data.exit_is_reachable())
	assert_true(data.build_field().is_deep_shade(data.spawn))


func test_the_orrery_is_sealed() -> void:
	var data := ChamberData.from_file("res://chambers/orrery.txt")
	for x in data.width:
		assert_true(data.is_wall(Vector2i(x, 0)))
		assert_true(data.is_wall(Vector2i(x, data.height - 1)))
	for y in data.height:
		assert_true(data.is_wall(Vector2i(0, y)))
		assert_true(data.is_wall(Vector2i(data.width - 1, y)))


func test_the_orrery_never_stops_changing() -> void:
	var chamber := Chamber.new()
	chamber.chamber_path = "res://chambers/orrery.txt"
	add_child_autofree(chamber)
	var probe := Vector2i(19, 7)
	var readings := {}
	for step in 60:
		chamber._process(0.2)
		readings[chamber.field.is_glare(probe)] = true
	assert_eq(readings.size(), 2, "the same tile is safe, then not, then safe again")
