extends GutTest

const GAME := preload("res://scenes/Game.tscn")


func _rig(waypoints: Array, snuffable: Array = []) -> Array:
	var field := LightField.new(30, 20)
	var defs: Array = []
	for entry in snuffable:
		var def := {
			"id": entry["id"], "kind": "brazier", "cell": entry["cell"],
			"radius": 6.0, "intensity": 1.0
		}
		field.emit(def["id"], def["cell"], 6.0, 1.0)
		defs.append(def)
	var cling := ClingController.new(field, defs)
	var warden := Warden.new()
	add_child_autofree(warden)
	warden.setup("hob", PatrolRoute.new(waypoints, PatrolRoute.Mode.PING_PONG, 2.0), field, cling)
	return [field, cling, warden]


# --- the beat -----------------------------------------------------------------


func test_a_route_walks_and_returns() -> void:
	var route := PatrolRoute.new([Vector2i(0, 0), Vector2i(10, 0)], PatrolRoute.Mode.PING_PONG, 2.0)
	assert_almost_eq(route.position().x, 0.0, 0.01)
	route.advance(2.5)
	assert_almost_eq(route.position().x, 5.0, 0.01)
	route.advance(5.0)
	assert_almost_eq(route.position().x, 5.0, 0.01, "and comes back the way it went")


func test_a_loop_never_doubles_back() -> void:
	var square: Array[Vector2i] = [
		Vector2i(0, 0), Vector2i(4, 0), Vector2i(4, 4), Vector2i(0, 4)
	]
	var route := PatrolRoute.new(square, PatrolRoute.Mode.LOOP, 1.0)
	assert_almost_eq(route.length(), 16.0, 0.01, "the loop closes")


func test_facing_leads_the_walk() -> void:
	var route := PatrolRoute.new([Vector2i(0, 0), Vector2i(10, 0)], PatrolRoute.Mode.PING_PONG, 2.0)
	assert_almost_eq(route.facing().x, 1.0, 0.01)
	route.advance(6.0)
	assert_almost_eq(route.facing().x, -1.0, 0.01, "the cone turns with them")


func test_waypoints_parse_from_a_chamber_line() -> void:
	var points := PatrolRoute.parse_waypoints("(5,3)>(20,3)>(20,10)")
	assert_eq(points, [Vector2i(5, 3), Vector2i(20, 3), Vector2i(20, 10)] as Array[Vector2i])


func test_a_one_point_route_is_invalid() -> void:
	assert_false(PatrolRoute.new([Vector2i(1, 1)]).is_valid())


# --- what they notice ---------------------------------------------------------


func test_the_cone_is_ahead_and_finite() -> void:
	var rig := _rig([Vector2i(5, 5), Vector2i(20, 5)])
	var warden: Warden = rig[2]
	assert_true(warden.sees(Vector2i(8, 5)), "straight ahead")
	assert_false(warden.sees(Vector2i(2, 5)), "behind them")
	assert_false(warden.sees(Vector2i(19, 5)), "beyond the lantern's reach")
	assert_false(warden.sees(Vector2i(8, 12)), "off to the side")


func test_they_carry_their_own_light() -> void:
	var rig := _rig([Vector2i(5, 5), Vector2i(20, 5)])
	var field: LightField = rig[0]
	var warden: Warden = rig[2]
	assert_true(field.is_glare(warden.current_cell()), "a Warden is a moving hazard")
	warden._physics_process(1.0)
	assert_eq(field.get_emitter(warden.lantern_id()).cell, warden.current_cell())


func test_ink_in_the_cone_draws_them_off_their_beat() -> void:
	var rig := _rig([Vector2i(5, 5), Vector2i(20, 5)])
	var field: LightField = rig[0]
	var warden: Warden = rig[2]
	watch_signals(warden)
	field.cast_ink(Vector2i(9, 5), 2.0, 1.0, 30.0)
	warden._physics_process(0.3)
	assert_eq(warden.state, Warden.State.INVESTIGATE)
	assert_signal_emitted(warden, "noticed")


func test_ink_behind_them_goes_unnoticed() -> void:
	var rig := _rig([Vector2i(5, 5), Vector2i(20, 5)])
	var field: LightField = rig[0]
	var warden: Warden = rig[2]
	field.cast_ink(Vector2i(2, 5), 2.0, 1.0, 30.0)
	warden._physics_process(0.3)
	assert_eq(warden.state, Warden.State.PATROL, "you can work behind their back")


func test_they_walk_over_and_relight_what_you_snuffed() -> void:
	var rig := _rig([Vector2i(5, 5), Vector2i(20, 5)], [{"id": "b0", "cell": Vector2i(9, 5)}])
	var field: LightField = rig[0]
	var cling: ClingController = rig[1]
	var warden: Warden = rig[2]
	watch_signals(warden)
	var lit_level := field.level_at(Vector2i(9, 5))
	cling.snuff("b0")
	assert_lt(field.level_at(Vector2i(9, 5)), lit_level, "snuffing it darkens the floor")
	assert_true(field.is_shade(Vector2i(9, 5)), "though their own lantern still spills a little")
	for i in 40:
		warden._physics_process(0.1)
	assert_false(cling.is_snuffed("b0"), "darkness you make is borrowed")
	assert_signal_emitted(warden, "relit_light")
	assert_true(field.is_glare(Vector2i(9, 5)))


func test_after_investigating_they_go_back_to_work() -> void:
	var rig := _rig([Vector2i(5, 5), Vector2i(20, 5)])
	var field: LightField = rig[0]
	var warden: Warden = rig[2]
	field.cast_ink(Vector2i(9, 5), 2.0, 1.0, 30.0)
	for i in 40:
		warden._physics_process(0.1)
	assert_eq(warden.state, Warden.State.PATROL)


# --- the chamber they live in -------------------------------------------------


func test_the_walk_parses_with_its_two_wardens() -> void:
	var data := ChamberData.from_file("res://chambers/warden_walk.txt")
	assert_true(data.is_valid(), str(data.parse_errors))
	assert_eq(data.wardens.size(), 2)
	assert_eq(data.wardens[0]["id"], "hob")
	assert_eq(data.wardens[0]["mode"], PatrolRoute.Mode.LOOP)
	assert_eq(data.wardens[1]["waypoints"].size(), 2)


func test_a_warden_route_must_stay_out_of_the_walls() -> void:
	var data := ChamberData.from_file("res://chambers/warden_walk.txt")
	for warden in data.wardens:
		for point in warden["waypoints"]:
			assert_false(data.is_wall(point), "%s routes through a wall at %s" % [warden["id"], point])


func test_the_walk_is_completable() -> void:
	var data := ChamberData.from_file("res://chambers/warden_walk.txt")
	assert_true(data.exit_is_reachable())
	assert_true(data.build_field().is_deep_shade(data.spawn))


func test_a_malformed_warden_line_is_an_error() -> void:
	var bad := ChamberData.from_text("id: x\nwarden: id=w1 route=(1,1)\n\n###\n#@#\n###")
	assert_false(bad.is_valid())


func test_the_chamber_brings_its_wardens_to_life() -> void:
	var chamber := Chamber.new()
	chamber.chamber_path = "res://chambers/warden_walk.txt"
	add_child_autofree(chamber)
	assert_eq(chamber.wardens.size(), 2)
	assert_not_null(chamber.field.get_emitter(chamber.wardens[0].lantern_id()))
