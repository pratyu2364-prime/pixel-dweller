extends GutTest

const Npc := preload("res://scripts/Npc.gd")


func test_first_greet_boosts_mood() -> void:
	var npc := Npc.new()
	var result := npc.greet(100.0)
	assert_eq(result.mood_boost, Npc.MOOD_BOOST, "first greet grants mood boost")
	assert_true(result.text.length() > 0, "greeting text non-empty")


func test_greet_within_cooldown_no_boost() -> void:
	var npc := Npc.new()
	npc.greet(100.0)
	var result := npc.greet(105.0)
	assert_eq(result.mood_boost, 0.0, "within cooldown no mood boost")
	assert_true(result.text.length() > 0, "text still returned within cooldown")


func test_greet_after_cooldown_boosts_again() -> void:
	var npc := Npc.new()
	npc.greet(100.0)
	npc.greet(105.0)
	var result := npc.greet(131.0)
	assert_eq(result.mood_boost, Npc.MOOD_BOOST, "after cooldown boost again")
