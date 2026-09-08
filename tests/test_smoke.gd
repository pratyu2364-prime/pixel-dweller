extends GutTest

## The one test that answers "is there a game here at all".


func test_the_game_boots_into_a_chamber_with_umbra_in_it() -> void:
	var game: Game = load("res://scenes/Game.tscn").instantiate()
	add_child_autofree(game)
	assert_not_null(game.chamber)
	assert_not_null(game.chamber.umbra)
	assert_not_null(game.chamber.field)
	assert_true(game.chamber.field.is_shade(game.chamber.umbra.current_cell()))


func test_nothing_from_the_retired_build_is_still_loaded() -> void:
	for path in [
		"res://scripts/Dweller.gd",
		"res://scripts/Stats.gd",
		"res://scripts/CityMap.gd",
		"res://scenes/Main.tscn",
	]:
		assert_false(ResourceLoader.exists(path), "%s survived the revamp" % path)
