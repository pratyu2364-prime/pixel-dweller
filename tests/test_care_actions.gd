extends GutTest

const Dweller := preload("res://scripts/Dweller.gd")


func test_eat_raises_hunger() -> void:
	var d := Dweller.new()
	d.apply_elapsed(60.0)
	var before := d.hunger
	d.refill_need("hunger", 30)
	assert_gt(d.hunger, before, "Eat raises hunger")


func test_rest_raises_energy() -> void:
	var d := Dweller.new()
	d.apply_elapsed(60.0)
	var before := d.energy
	d.refill_need("energy", 30)
	assert_gt(d.energy, before, "Rest raises energy")


func test_play_raises_mood() -> void:
	var d := Dweller.new()
	d.apply_elapsed(60.0)
	var before := d.mood
	d.refill_need("mood", 30)
	assert_gt(d.mood, before, "Play raises mood")
