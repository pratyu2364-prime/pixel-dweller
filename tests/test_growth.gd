extends GutTest

const Dweller := preload("res://scripts/Dweller.gd")


func test_crossing_kid_threshold_advances_stage_and_emits() -> void:
	var d := Dweller.new()
	d.care_score = 59.0
	watch_signals(d)
	d.apply_elapsed(2.0)
	assert_signal_emitted(d, "grew_up", "grew_up emitted at KID threshold")
	assert_eq(d.stage, Dweller.Stage.KID, "stage becomes KID")


func test_crossing_adult_threshold_advances_stage_and_emits() -> void:
	var d := Dweller.new()
	d.stage = Dweller.Stage.KID
	d.care_score = 179.0
	watch_signals(d)
	d.apply_elapsed(2.0)
	assert_signal_emitted(d, "grew_up", "grew_up emitted at ADULT threshold")
	assert_eq(d.stage, Dweller.Stage.ADULT, "stage becomes ADULT")


func test_neglect_slows_growth_vs_healthy() -> void:
	var healthy := Dweller.new()
	healthy.care_score = 10.0
	healthy.apply_elapsed(10.0)

	var neglected := Dweller.new()
	neglected.hunger = 0.0
	neglected.care_score = 10.0
	neglected.apply_elapsed(10.0)

	assert_lt(neglected.care_score, healthy.care_score, "neglect slows care_score growth")


func test_healthy_growth_increases_care_score() -> void:
	var d := Dweller.new()
	d.care_score = 10.0
	d.apply_elapsed(2.0)
	assert_gt(d.care_score, 10.0, "care_score grows with full needs")


func test_all_needs_zero_drops_care_score() -> void:
	var d := Dweller.new()
	d.hunger = 0.0
	d.energy = 0.0
	d.mood = 0.0
	d.care_score = 10.0
	d.apply_elapsed(2.0)
	assert_lt(d.care_score, 10.0, "care_score drops when all needs at 0")


func test_care_score_clamped_at_zero() -> void:
	var d := Dweller.new()
	d.hunger = 0.0
	d.energy = 0.0
	d.mood = 0.0
	d.care_score = 0.5
	d.apply_elapsed(10.0)
	assert_eq(d.care_score, 0.0, "care_score clamped at 0")
