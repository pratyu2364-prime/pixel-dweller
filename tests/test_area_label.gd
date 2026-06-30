extends GutTest

const UI := preload("res://scripts/UI.gd")
const AreaManager := preload("res://scripts/AreaManager.gd")
const SaveManager := preload("res://scripts/SaveManager.gd")
const Dweller := preload("res://scripts/Dweller.gd")

const TEST_PATH: String = "user://test_area_label.json"


func after_each() -> void:
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(TEST_PATH)


func test_pretty_area_name_house() -> void:
	assert_eq(UI.pretty_area_name("house"), "House", "house maps to House")


func test_pretty_area_name_garden() -> void:
	assert_eq(UI.pretty_area_name("garden"), "Garden", "garden maps to Garden")


func test_pretty_area_name_town() -> void:
	assert_eq(UI.pretty_area_name("town"), "Town", "town maps to Town")


func test_pretty_area_name_unknown_fallback() -> void:
	assert_eq(UI.pretty_area_name("unknown"), "Unknown", "unknown key capitalizes")


func test_place_player_fallback_on_missing_entry() -> void:
	var mgr := AreaManager.new()
	var container := Node2D.new()
	add_child_autofree(container)

	mgr.load_area("garden", "NonExistentEntry", container)

	var player := mgr.get_player()
	assert_not_null(player, "player created despite missing entry")
	assert_not_null(player.get_parent(), "player has a parent")
	assert_true(container.get_child_count() == 1, "area container has one child")


func test_save_load_round_trips_current_area_garden() -> void:
	SaveManager.save_dweller(Dweller.new(), TEST_PATH, "garden")

	var loaded_area: String = SaveManager.load_current_area(TEST_PATH)
	assert_eq(loaded_area, "garden", "current_area round-trips as 'garden'")


func test_save_load_round_trips_current_area_town() -> void:
	SaveManager.save_dweller(Dweller.new(), TEST_PATH, "town")

	var loaded_area: String = SaveManager.load_current_area(TEST_PATH)
	assert_eq(loaded_area, "town", "current_area round-trips as 'town'")
