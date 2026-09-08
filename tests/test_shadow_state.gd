extends GutTest


func test_starts_whole() -> void:
	var s := ShadowState.new()
	assert_eq(s.coherence, ShadowState.MAX_COHERENCE)
	assert_eq(s.ink_charges(), 3)
	assert_false(s.is_scattered)


func test_glare_drains_coherence() -> void:
	var s := ShadowState.new()
	s.tick(1.0, 1.0, false)
	assert_almost_eq(s.coherence, ShadowState.MAX_COHERENCE - ShadowState.DRAIN_PER_SECOND, 0.01)


func test_partial_glare_drains_proportionally() -> void:
	var s := ShadowState.new()
	s.tick(1.0, 0.5, false)
	var expected := ShadowState.MAX_COHERENCE - ShadowState.DRAIN_PER_SECOND * 0.5
	assert_almost_eq(s.coherence, expected, 0.01)


func test_full_glare_kills_in_about_three_seconds() -> void:
	var s := ShadowState.new()
	for i in 29:
		s.tick(0.1, 1.0, false)
	assert_false(s.is_scattered, "still alive just under 3s")
	s.tick(0.2, 1.0, false)
	assert_true(s.is_scattered, "scattered just past 3s")


func test_shade_regenerates_after_a_grace_delay() -> void:
	var s := ShadowState.new()
	s.tick(1.0, 1.0, false)
	var hurt := s.coherence
	s.tick(0.2, 0.0, false)
	assert_almost_eq(s.coherence, hurt, 0.01, "no regen during the grace window")
	s.tick(1.0, 0.0, false)
	assert_gt(s.coherence, hurt)


func test_deep_shade_regenerates_faster() -> void:
	var shallow := ShadowState.new()
	var deep := ShadowState.new()
	for s in [shallow, deep]:
		s.tick(1.0, 1.0, false)
		s.tick(ShadowState.REGEN_DELAY, 0.0, false)
	shallow.tick(1.0, 0.0, false)
	deep.tick(1.0, 0.0, true)
	assert_gt(deep.coherence, shallow.coherence)


func test_ink_only_refills_in_deep_shade() -> void:
	var s := ShadowState.new()
	s.spend_ink()
	s.spend_ink()
	assert_eq(s.ink_charges(), 1)
	s.tick(2.0, 0.0, false)
	assert_eq(s.ink_charges(), 1, "plain shade does not refill ink")
	s.tick(2.0, 0.0, true)
	assert_gt(s.ink, 1.0)


func test_ink_caps_at_max() -> void:
	var s := ShadowState.new()
	s.tick(60.0, 0.0, true)
	assert_eq(s.ink, ShadowState.MAX_INK)


func test_cannot_cast_without_ink() -> void:
	var s := ShadowState.new()
	for i in 3:
		assert_true(s.spend_ink())
	assert_false(s.can_cast())
	assert_false(s.spend_ink())


func test_scatter_emits_once() -> void:
	var s := ShadowState.new()
	watch_signals(s)
	s.scatter()
	s.scatter()
	assert_signal_emit_count(s, "scattered", 1)


func test_reform_gives_half_coherence_and_a_charge() -> void:
	var s := ShadowState.new()
	for i in 3:
		s.spend_ink()
	s.scatter()
	s.reform()
	assert_false(s.is_scattered)
	assert_almost_eq(s.coherence, ShadowState.MAX_COHERENCE * 0.5, 0.01)
	assert_true(s.can_cast(), "you always reform able to act")


func test_scattered_state_ignores_ticks() -> void:
	var s := ShadowState.new()
	s.scatter()
	s.tick(5.0, 0.0, true)
	assert_eq(s.coherence, 0.0)


func test_glare_slows_movement() -> void:
	var s := ShadowState.new()
	assert_eq(s.speed_multiplier(0.0), 1.0)
	assert_almost_eq(s.speed_multiplier(1.0), 0.5, 0.001)
	assert_gt(s.speed_multiplier(0.5), s.speed_multiplier(1.0))


func test_round_trips_through_a_dictionary() -> void:
	var s := ShadowState.new()
	s.tick(1.0, 1.0, false)
	s.spend_ink()
	var restored := ShadowState.new()
	restored.from_dict(s.to_dict())
	assert_almost_eq(restored.coherence, s.coherence, 0.001)
	assert_almost_eq(restored.ink, s.ink, 0.001)
