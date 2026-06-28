extends GutTest

const Dweller := preload("res://scripts/Dweller.gd")


func test_normal_decay_reduces_needs() -> void:
	var d := Dweller.new()
	d.apply_elapsed(1.0)
	assert_almost_eq(d.hunger, 99.65, 0.001, "hunger decays medium")
	assert_almost_eq(d.energy, 99.85, 0.001, "energy decays slow")
	assert_almost_eq(d.mood, 99.4, 0.001, "mood decays fast")


func test_clamp_at_zero_for_huge_elapsed() -> void:
	var d := Dweller.new()
	d.apply_elapsed(999999.0)
	assert_eq(d.hunger, 0.0, "hunger bottom")
	assert_eq(d.energy, 0.0, "energy bottom")
	assert_eq(d.mood, 0.0, "mood bottom")


func test_large_elapsed_no_clamp() -> void:
	var d := Dweller.new()
	d.apply_elapsed(100.0)
	assert_eq(d.hunger, 65.0, "hunger after 100s")
	assert_eq(d.energy, 85.0, "energy after 100s")
	assert_eq(d.mood, 40.0, "mood after 100s")


func test_zero_elapsed_no_change() -> void:
	var d := Dweller.new()
	d.apply_elapsed(0.0)
	assert_eq(d.hunger, 100.0, "hunger unchanged")
	assert_eq(d.energy, 100.0, "energy unchanged")
	assert_eq(d.mood, 100.0, "mood unchanged")


func test_refill_clamps_at_max() -> void:
	var d := Dweller.new()
	d.apply_elapsed(10.0)
	d.refill_need("hunger", 999.0)
	d.refill_need("energy", 999.0)
	d.refill_need("mood", 999.0)
	assert_eq(d.hunger, 100.0, "hunger max")
	assert_eq(d.energy, 100.0, "energy max")
	assert_eq(d.mood, 100.0, "mood max")


func test_refill_partial() -> void:
	var d := Dweller.new()
	d.apply_elapsed(50.0)
	d.refill_need("hunger", 5.0)
	d.refill_need("energy", 5.0)
	d.refill_need("mood", 5.0)
	assert_almost_eq(d.hunger, 87.5, 0.001, "hunger refilled")
	assert_almost_eq(d.energy, 97.5, 0.001, "energy refilled")
	assert_almost_eq(d.mood, 75.0, 0.001, "mood refilled")
