extends GutTest

const AreaManager := preload("res://scripts/AreaManager.gd")
const SaveManager := preload("res://scripts/SaveManager.gd")
const Dweller := preload("res://scripts/Dweller.gd")

const TEST_PATH: String = "user://test_area_manager.json"


func after_each() -> void:
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(TEST_PATH)


func test_load_area_sets_current_area() -> void:
	var mgr := AreaManager.new()
	var container := Node2D.new()
	add_child_autofree(container)

	mgr.load_area("house", "EntryDefault", container)

	assert_eq(mgr.current_area, "house", "current_area set to 'house'")


func test_load_area_places_player_at_entry() -> void:
	var mgr := AreaManager.new()
	var container := Node2D.new()
	add_child_autofree(container)

	mgr.load_area("house", "EntryDefault", container)

	var player := mgr.get_player()
	assert_not_null(player, "player created")
	assert_not_null(player.get_parent(), "player has a parent")

	var entry_position: Vector2 = Vector2.ZERO
	var area_node := mgr.get_current_area_node()
	if area_node != null:
		var entry := area_node.get_node_or_null("EntryDefault") as Marker2D
		if entry != null:
			entry_position = entry.position

	assert_eq(player.position, entry_position, "player at EntryDefault position")


func test_load_area_twice_replaces_old_area() -> void:
	var mgr := AreaManager.new()
	var container := Node2D.new()
	add_child_autofree(container)

	mgr.load_area("house", "EntryDefault", container)
	var first_player: CharacterBody2D = mgr.get_player()

	mgr.load_area("house", "EntryDefault", container)
	var second_player: CharacterBody2D = mgr.get_player()

	assert_ne(first_player, second_player, "new player instance on reload")
	assert_eq(container.get_child_count(), 1, "only one area in container")


func test_get_current_area_node_returns_area() -> void:
	var mgr := AreaManager.new()
	var container := Node2D.new()
	add_child_autofree(container)

	mgr.load_area("garden", "EntryFromHouse", container)

	var area_node := mgr.get_current_area_node()
	assert_not_null(area_node, "current area node exists")
	assert_true(area_node.has_method("apply_world_stage"), "garden area has apply_world_stage")


func test_save_load_round_trips_current_area() -> void:
	SaveManager.save_dweller(Dweller.new(), TEST_PATH, "house")

	var loaded_area: String = SaveManager.load_current_area(TEST_PATH)
	assert_eq(loaded_area, "house", "current_area round-trips as 'house'")


func test_load_current_area_defaults_to_house() -> void:
	var area: String = SaveManager.load_current_area("user://nonexistent.json")
	assert_eq(area, "house", "missing save defaults to 'house'")
