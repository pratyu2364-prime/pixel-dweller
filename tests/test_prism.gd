extends GutTest

## Mirrors are the first thing in the Observatory that answers to the player,
## so their behaviour is pinned down hard.


func _hall(width: int = 20, height: int = 12) -> LightField:
	return LightField.new(width, height)


func test_a_ray_runs_until_it_hits_a_wall() -> void:
	var field := _hall()
	for y in 12:
		field.set_opaque(Vector2i(10, y), true)
	var ray := field.add_ray(LightField.LightRay.new("r", Vector2i(1, 5), Vector2i.RIGHT, 1.0, 30))
	var path := field.trace_ray(ray)
	assert_eq(path.size(), 8, "cells 2..9, then the wall")
	assert_true(field.is_glare(Vector2i(5, 5)))
	assert_true(field.is_shade(Vector2i(12, 5)), "nothing gets past the wall")


func test_a_ray_lights_only_its_own_line() -> void:
	var field := _hall()
	field.add_ray(LightField.LightRay.new("r", Vector2i(1, 5), Vector2i.RIGHT, 1.0, 30))
	assert_true(field.is_glare(Vector2i(6, 5)))
	assert_true(field.is_shade(Vector2i(6, 6)), "one cell aside is safe")


func test_mirrors_bend_a_ray_ninety_degrees() -> void:
	assert_eq(LightField.reflect(Vector2i.RIGHT, "/"), Vector2i.UP)
	assert_eq(LightField.reflect(Vector2i.RIGHT, "\\"), Vector2i.DOWN)
	assert_eq(LightField.reflect(Vector2i.DOWN, "/"), Vector2i.LEFT)
	assert_eq(LightField.reflect(Vector2i.UP, "\\"), Vector2i.LEFT)


func test_a_mirror_turns_the_beam_in_the_room() -> void:
	var field := _hall()
	field.set_mirror(Vector2i(8, 5), "\\")
	field.add_ray(LightField.LightRay.new("r", Vector2i(1, 5), Vector2i.RIGHT, 1.0, 30))
	assert_true(field.is_glare(Vector2i(8, 8)), "bent downward")
	assert_true(field.is_shade(Vector2i(12, 5)), "and no longer running straight on")


func test_turning_a_mirror_moves_the_danger() -> void:
	var field := _hall()
	field.set_mirror(Vector2i(8, 5), "\\")
	field.add_ray(LightField.LightRay.new("r", Vector2i(1, 5), Vector2i.RIGHT, 1.0, 30))
	assert_true(field.is_glare(Vector2i(8, 8)))
	assert_true(field.turn_mirror(Vector2i(8, 5)))
	assert_true(field.is_shade(Vector2i(8, 8)), "the beam left")
	assert_true(field.is_glare(Vector2i(8, 2)), "and went the other way")


func test_turning_nothing_is_not_an_error() -> void:
	assert_false(_hall().turn_mirror(Vector2i(3, 3)))


func test_a_ring_of_mirrors_does_not_hang_the_game() -> void:
	var field := _hall()
	field.set_mirror(Vector2i(4, 4), "\\")
	field.set_mirror(Vector2i(8, 4), "/")
	field.set_mirror(Vector2i(8, 8), "\\")
	field.set_mirror(Vector2i(4, 8), "/")
	var ray := field.add_ray(LightField.LightRay.new("r", Vector2i(1, 4), Vector2i.RIGHT, 1.0, 200))
	assert_lt(field.trace_ray(ray).size(), 200, "a loop terminates")


func test_a_reflected_beam_weakens_along_its_path() -> void:
	var field := LightField.new(40, 12)
	field.add_ray(LightField.LightRay.new("r", Vector2i(0, 5), Vector2i.RIGHT, 1.0, 36))
	assert_gt(field.level_at(Vector2i(2, 5)), field.level_at(Vector2i(30, 5)))


func test_a_lamp_ignores_mirrors_so_glass_is_a_lever_not_a_light() -> void:
	var field := _hall()
	field.set_mirror(Vector2i(8, 5), "/")
	field.emit("lamp", Vector2i(5, 5), 12.0, 1.0)
	assert_true(field.is_glare(Vector2i(9, 5)), "the lamp's glow passes the glass by")


func test_cling_turns_the_mirror_you_stand_beside() -> void:
	var field := _hall()
	field.set_mirror(Vector2i(8, 5), "/")
	var cling := ClingController.new(field, [])
	watch_signals(cling)
	assert_eq(cling.press(Vector2i(7, 5)), "turn")
	assert_eq(field.mirror_at(Vector2i(8, 5)), "\\")
	assert_signal_emitted(cling, "turned_mirror")
	assert_eq(cling.press(Vector2i(2, 2)), "", "out of reach, out of mind")


func test_the_prism_hall_parses_and_can_be_finished() -> void:
	var data := ChamberData.from_file("res://chambers/prism_hall.txt")
	assert_true(data.is_valid(), str(data.parse_errors))
	assert_eq(data.mirrors.size(), 5)
	assert_eq(data.rays.size(), 2)
	assert_true(data.exit_is_reachable())
	assert_true(data.build_field().is_deep_shade(data.spawn))


func test_the_prism_hall_is_actually_crossed_by_light() -> void:
	var data := ChamberData.from_file("res://chambers/prism_hall.txt")
	var field := data.build_field()
	var lit := 0
	for ray in field.rays():
		lit += field.trace_ray(ray).size()
	assert_gt(lit, 15, "two beams that go somewhere")


func test_the_hall_stands_between_the_walk_and_the_top() -> void:
	assert_eq(Game.next_after("warden_walk", ""), "prism_hall")
	assert_eq(Game.next_after("prism_hall", ""), "")
