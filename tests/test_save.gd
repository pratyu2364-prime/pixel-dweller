extends GutTest

const SaveManager := preload("res://scripts/SaveManager.gd")
const TimeManager := preload("res://scripts/TimeManager.gd")
const Dweller := preload("res://scripts/Dweller.gd")

const TEST_PATH: String = "user://test_save.json"


func after_each() -> void:
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(TEST_PATH)


func test_round_trip_preserves_values() -> void:
	var d := Dweller.new()
	d.hunger = 42.5
	d.energy = 73.1
	d.mood = 88.8
	SaveManager.save_dweller(d, TEST_PATH)
	var loaded := SaveManager.load(TEST_PATH)
	assert_eq(loaded.get("hunger", -1), 42.5, "hunger preserved")
	assert_eq(loaded.get("energy", -1), 73.1, "energy preserved")
	assert_eq(loaded.get("mood", -1), 88.8, "mood preserved")
	assert_true(loaded.has("last_saved_at"), "timestamp present")


func test_round_trip_into_dweller() -> void:
	var d := Dweller.new()
	d.hunger = 10.0
	d.energy = 20.0
	d.mood = 30.0
	SaveManager.save_dweller(d, TEST_PATH)
	var d2 := Dweller.new()
	var ts := SaveManager.load_into_dweller(d2, TEST_PATH)
	assert_eq(d2.hunger, 10.0, "hunger restored")
	assert_eq(d2.energy, 20.0, "energy restored")
	assert_eq(d2.mood, 30.0, "mood restored")
	assert_gt(ts, 0.0, "timestamp > 0")


func test_load_missing_returns_empty() -> void:
	var data := SaveManager.load("user://nonexistent.json")
	assert_eq(data, {}, "missing file returns empty dict")


func test_elapsed_since_approximate() -> void:
	var past := Time.get_unix_time_from_system() - 10.0
	var elapsed := TimeManager.elapsed_since(past)
	assert_almost_eq(elapsed, 10.0, 2.0, "~10 seconds elapsed")


func test_elapsed_since_clamps_negative() -> void:
	var future := Time.get_unix_time_from_system() + 9999.0
	var elapsed := TimeManager.elapsed_since(future)
	assert_eq(elapsed, 0.0, "future timestamp clamped to 0")
