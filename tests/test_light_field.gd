extends GutTest

## PENUMBRA's single rule lives in LightField, so it gets the strictest tests.


func _field(w: int = 16, h: int = 16, ambient: float = 0.0) -> LightField:
	return LightField.new(w, h, ambient)


func test_empty_field_is_deep_shade() -> void:
	var f := _field()
	assert_eq(f.level_at(Vector2i(3, 3)), 0.0)
	assert_true(f.is_shade(Vector2i(3, 3)))
	assert_true(f.is_deep_shade(Vector2i(3, 3)))
	assert_false(f.is_glare(Vector2i(3, 3)))


func test_out_of_bounds_reads_as_dark_and_solid() -> void:
	var f := _field(4, 4)
	assert_eq(f.level_at(Vector2i(-1, 0)), 0.0)
	assert_true(f.is_opaque(Vector2i(9, 9)), "outside the chamber is wall")


func test_emitter_lights_its_own_cell_fully() -> void:
	var f := _field()
	f.emit("lamp", Vector2i(8, 8), 5.0, 1.0)
	assert_almost_eq(f.level_at(Vector2i(8, 8)), 1.0, 0.001)
	assert_true(f.is_glare(Vector2i(8, 8)))


func test_light_falls_off_with_distance() -> void:
	var f := _field()
	f.emit("lamp", Vector2i(8, 8), 6.0, 1.0)
	var near := f.level_at(Vector2i(9, 8))
	var mid := f.level_at(Vector2i(11, 8))
	var far := f.level_at(Vector2i(14, 8))
	assert_gt(near, mid)
	assert_gt(mid, far)
	assert_eq(far, 0.0, "beyond the radius there is no light at all")


func test_walls_cast_shadow() -> void:
	var f := _field()
	f.emit("lamp", Vector2i(4, 8), 10.0, 1.0)
	for y in range(6, 11):
		f.set_opaque(Vector2i(6, y), true)
	assert_gt(f.level_at(Vector2i(5, 8)), 0.0, "in front of the wall is lit")
	assert_eq(f.level_at(Vector2i(8, 8)), 0.0, "behind the wall is shadow")
	assert_true(f.is_shade(Vector2i(8, 8)))


func test_snuffed_emitter_leaves_shade() -> void:
	var f := _field()
	f.emit("lamp", Vector2i(8, 8), 6.0, 1.0)
	f.set_emitter_enabled("lamp", false)
	assert_eq(f.level_at(Vector2i(8, 8)), 0.0)
	f.set_emitter_enabled("lamp", true)
	assert_gt(f.level_at(Vector2i(8, 8)), 0.0)


func test_dimming_lowers_the_pool_without_snuffing() -> void:
	var f := _field()
	f.emit("lamp", Vector2i(8, 8), 6.0, 1.0)
	var bright := f.level_at(Vector2i(10, 8))
	f.set_emitter_intensity("lamp", 0.25)
	var dim := f.level_at(Vector2i(10, 8))
	assert_gt(bright, dim)
	assert_gt(dim, 0.0)


func test_moving_an_emitter_moves_its_pool() -> void:
	var f := _field()
	f.emit("lantern", Vector2i(2, 2), 5.0, 1.0)
	assert_eq(f.level_at(Vector2i(12, 12)), 0.0)
	f.move_emitter("lantern", Vector2i(12, 12))
	assert_almost_eq(f.level_at(Vector2i(12, 12)), 1.0, 0.001)
	assert_eq(f.level_at(Vector2i(2, 2)), 0.0)


func test_ink_puff_turns_glare_into_shade() -> void:
	var f := _field()
	f.emit("lamp", Vector2i(8, 8), 8.0, 1.0)
	var target := Vector2i(11, 8)
	assert_true(f.is_glare(target), "the crossing starts lit")
	f.cast_ink(target, 2.0, 1.0, 5.0)
	assert_true(f.is_shade(target), "ink makes a stepping stone")


func test_ink_fades_and_expires() -> void:
	var f := _field()
	f.emit("lamp", Vector2i(8, 8), 8.0, 1.0)
	var target := Vector2i(11, 8)
	f.cast_ink(target, 2.0, 1.0, 4.0)
	f.advance(1.0)
	assert_true(f.is_shade(target), "still holding early in its life")
	f.advance(3.5)
	assert_eq(f.ink_puffs().size(), 0, "expired puffs are dropped")
	assert_true(f.is_glare(target), "and the light comes back")


func test_ink_ignores_walls() -> void:
	var f := _field()
	f.set_opaque(Vector2i(5, 5), true)
	f.set_ambient(1.0)
	f.cast_ink(Vector2i(4, 5), 3.0, 1.0, 5.0)
	assert_true(f.is_shade(Vector2i(6, 5)), "darkness pools around corners")


func test_ambient_can_be_baked_per_cell() -> void:
	var f := _field(8, 8, 0.0)
	f.set_ambient_at(Vector2i(4, 4), 0.9)
	assert_true(f.is_glare(Vector2i(4, 4)), "a baked sunbeam")
	assert_true(f.is_shade(Vector2i(4, 5)))


func test_glare_scales_from_the_shade_threshold() -> void:
	var f := _field(8, 8)
	f.set_ambient_at(Vector2i(1, 1), LightField.SHADE_MAX)
	f.set_ambient_at(Vector2i(2, 1), 1.0)
	assert_eq(f.glare_at(Vector2i(1, 1)), 0.0, "the threshold itself is safe")
	assert_almost_eq(f.glare_at(Vector2i(2, 1)), 1.0, 0.001)
	assert_almost_eq(f.glare_at(Vector2i(0, 0)), 0.0, 0.001)


func test_nearest_shade_walks_around_walls() -> void:
	var f := _field(16, 16)
	f.set_ambient(1.0)
	for y in range(0, 16):
		f.set_opaque(Vector2i(8, y), true)
	f.set_ambient_at(Vector2i(3, 3), 0.0)
	var refuge := f.nearest_shade(Vector2i(5, 3))
	assert_eq(refuge, Vector2i(3, 3), "reform at the reachable shade")


func test_nearest_shade_returns_self_when_already_safe() -> void:
	var f := _field(8, 8)
	assert_eq(f.nearest_shade(Vector2i(2, 2)), Vector2i(2, 2))


func test_levels_snapshot_matches_queries() -> void:
	var f := _field(6, 6)
	f.emit("lamp", Vector2i(3, 3), 4.0, 1.0)
	var snapshot := f.levels()
	assert_eq(snapshot.size(), 36)
	assert_almost_eq(snapshot[3 * 6 + 3], f.level_at(Vector2i(3, 3)), 0.0001)
