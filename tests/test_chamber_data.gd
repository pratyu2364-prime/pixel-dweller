extends GutTest

const TINY := """id: tiny
title: A Room
ambient: 0.1

#####
#@.o#
#~.>#
#####"""


func test_parses_front_matter() -> void:
	var d := ChamberData.from_text(TINY)
	assert_true(d.is_valid(), str(d.parse_errors))
	assert_eq(d.id, "tiny")
	assert_eq(d.title, "A Room")
	assert_almost_eq(d.ambient, 0.1, 0.001)


func test_parses_geometry() -> void:
	var d := ChamberData.from_text(TINY)
	assert_eq(d.width, 5)
	assert_eq(d.height, 4)
	assert_eq(d.spawn, Vector2i(1, 1))
	assert_eq(d.exit, Vector2i(3, 2))
	assert_true(d.is_wall(Vector2i(0, 0)))
	assert_false(d.is_wall(Vector2i(2, 1)))


func test_parses_lights_with_stable_ids() -> void:
	var d := ChamberData.from_text(TINY)
	assert_eq(d.lights.size(), 1)
	assert_eq(d.lights[0]["id"], "lamp_0")
	assert_eq(d.lights[0]["cell"], Vector2i(3, 1))


func test_unknown_glyph_is_an_error_not_a_surprise() -> void:
	var d := ChamberData.from_text("id: x\n\n###\n#@%\n###")
	assert_false(d.is_valid())
	assert_string_contains(d.parse_errors[0], "unknown glyph")


func test_missing_spawn_is_an_error() -> void:
	var d := ChamberData.from_text("id: x\n\n####\n#..#\n####")
	assert_false(d.is_valid())


func test_missing_file_is_an_error() -> void:
	var d := ChamberData.from_file("res://chambers/nope.txt")
	assert_false(d.is_valid())


func test_ragged_rows_are_padded_not_dropped() -> void:
	var d := ChamberData.from_text("id: x\n\n#####\n#@\n#####")
	assert_eq(d.width, 5)
	assert_eq(d.glyph_at(Vector2i(4, 1)), " ")


func test_builds_a_field_that_matches_the_map() -> void:
	var d := ChamberData.from_text(TINY)
	var f := d.build_field()
	assert_true(f.is_opaque(Vector2i(0, 0)), "walls occlude")
	assert_true(f.is_glare(Vector2i(3, 1)), "the lamp burns its own cell")
	assert_true(f.is_deep_shade(Vector2i(1, 2)), "a nook is always deep shade")


func test_sunbeams_bake_into_ambient() -> void:
	var d := ChamberData.from_text("id: x\n\n####\n#@s#\n####")
	var f := d.build_field()
	assert_true(f.is_glare(Vector2i(2, 1)))


func test_exit_reachability_is_provable() -> void:
	var d := ChamberData.from_text(TINY)
	assert_true(d.exit_is_reachable())
	var sealed := ChamberData.from_text("id: x\n\n#####\n#@#>#\n#####")
	assert_false(sealed.exit_is_reachable(), "a walled-off exit fails the check")
