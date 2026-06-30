extends GutTest

const AreaManager := preload("res://scripts/AreaManager.gd")
const SaveManager := preload("res://scripts/SaveManager.gd")
const Dweller := preload("res://scripts/Dweller.gd")

const TEST_PATH: String = "user://test_doors.json"

var _sig_area: String = ""
var _sig_entry: String = ""
var _sig_emitted: bool = false


func after_each() -> void:
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(TEST_PATH)
	_sig_area = ""
	_sig_entry = ""
	_sig_emitted = false


func _on_requested(ta: String, te: String) -> void:
	_sig_area = ta
	_sig_entry = te
	_sig_emitted = true


func test_door_instantiation() -> void:
	var door := preload("res://scenes/Door.tscn").instantiate()
	add_child_autofree(door)

	assert_not_null(door, "Door scene instantiates")
	assert_true(door is Door, "Door is Door type")


func test_door_exports_target_area() -> void:
	var door := preload("res://scenes/Door.tscn").instantiate()
	add_child_autofree(door)

	door.target_area = "garden"
	assert_eq(door.target_area, "garden", "target_area set correctly")


func test_door_exports_target_entry() -> void:
	var door := preload("res://scenes/Door.tscn").instantiate()
	add_child_autofree(door)

	door.target_entry = "EntryFromHouse"
	assert_eq(door.target_entry, "EntryFromHouse", "target_entry set correctly")


func test_handler_emits_for_character_body() -> void:
	var door := Door.new()
	add_child_autofree(door)

	door.target_area = "garden"
	door.target_entry = "EntryFromHouse"
	door.requested_transition.connect(_on_requested)

	var body := CharacterBody2D.new()
	add_child_autofree(body)

	door._on_body_entered(body)

	assert_true(_sig_emitted, "handler emitted signal for CharacterBody2D")
	assert_eq(_sig_area, "garden", "emitted target_area")
	assert_eq(_sig_entry, "EntryFromHouse", "emitted target_entry")


func test_handler_emits_for_player_scene() -> void:
	var door := preload("res://scenes/Door.tscn").instantiate()
	add_child_autofree(door)

	door.target_area = "garden"
	door.target_entry = "EntryFromHouse"
	door.requested_transition.connect(_on_requested)

	var player := preload("res://scenes/Player.tscn").instantiate()
	add_child_autofree(player)

	door._on_body_entered(player)

	assert_true(_sig_emitted, "handler emitted for Player scene")
	assert_eq(_sig_area, "garden", "emitted target_area")
	assert_eq(_sig_entry, "EntryFromHouse", "emitted target_entry")


func test_handler_ignores_non_character_body() -> void:
	var door := Door.new()
	add_child_autofree(door)

	door.requested_transition.connect(_on_requested)

	var fake_body := Node2D.new()
	add_child_autofree(fake_body)

	door._on_body_entered(fake_body)

	assert_false(_sig_emitted, "handler did not emit for Node2D")


func test_signal_can_be_connected_and_emitted() -> void:
	var door := Door.new()
	add_child_autofree(door)

	door.requested_transition.connect(_on_requested)
	door.requested_transition.emit("manual", "test")

	assert_true(_sig_emitted, "direct signal emit works")
	assert_eq(_sig_area, "manual")
	assert_eq(_sig_entry, "test")


func test_area_manager_transition_to_garden_changes_current_area() -> void:
	var mgr := AreaManager.new()
	var container := Node2D.new()
	add_child_autofree(container)

	mgr.load_area("house", "EntryDefault", container)
	assert_eq(mgr.current_area, "house")

	mgr.load_area("garden", "EntryFromHouse", container)
	assert_eq(mgr.current_area, "garden")


func test_transition_places_player_at_garden_entry() -> void:
	var mgr := AreaManager.new()
	var container := Node2D.new()
	add_child_autofree(container)

	mgr.load_area("house", "EntryDefault", container)
	mgr.load_area("garden", "EntryFromHouse", container)

	var area_node := mgr.get_current_area_node()
	assert_not_null(area_node, "garden area loaded")

	var entry := area_node.get_node_or_null("EntryFromHouse") as Marker2D
	assert_not_null(entry, "garden has EntryFromHouse marker")

	var player := mgr.get_player()
	assert_not_null(player, "player exists after transition")
	assert_eq(player.position, entry.position, "player at EntryFromHouse")


func test_house_has_entry_from_garden_marker() -> void:
	var house := preload("res://scenes/areas/House.tscn").instantiate()
	add_child_autofree(house)
	await get_tree().process_frame

	var entry := house.get_node_or_null("EntryFromGarden")
	assert_not_null(entry, "House has EntryFromGarden Marker2D")
	assert_true(entry is Marker2D, "EntryFromGarden is Marker2D")


func test_garden_has_entry_from_house_marker() -> void:
	var garden := preload("res://scenes/areas/Garden.tscn").instantiate()
	add_child_autofree(garden)
	await get_tree().process_frame

	var entry := garden.get_node_or_null("EntryFromHouse")
	assert_not_null(entry, "Garden has EntryFromHouse Marker2D")
	assert_true(entry is Marker2D, "EntryFromHouse is Marker2D")


func test_garden_has_door() -> void:
	var garden := preload("res://scenes/areas/Garden.tscn").instantiate()
	add_child_autofree(garden)
	await get_tree().process_frame

	var door_found := false
	for child in garden.get_children():
		if child is Door:
			door_found = true
			assert_eq(child.target_area, "house", "Garden door targets house")
			assert_eq(child.target_entry, "EntryFromGarden", "Garden door targets EntryFromGarden")
	assert_true(door_found, "Garden has a Door child")


func test_house_has_door() -> void:
	var house := preload("res://scenes/areas/House.tscn").instantiate()
	add_child_autofree(house)
	await get_tree().process_frame

	var door_found := false
	for child in house.get_children():
		if child is Door:
			door_found = true
			assert_eq(child.target_area, "garden", "House door targets garden")
			assert_eq(child.target_entry, "EntryFromHouse", "House door targets EntryFromHouse")
	assert_true(door_found, "House has a Door child")


func test_transition_saves_current_area() -> void:
	var mgr := AreaManager.new()
	var container := Node2D.new()
	add_child_autofree(container)

	mgr.load_area("house", "EntryDefault", container)
	mgr.load_area("garden", "EntryFromHouse", container)

	SaveManager.save_dweller(Dweller.new(), TEST_PATH, mgr.current_area)
	var loaded: String = SaveManager.load_current_area(TEST_PATH)
	assert_eq(loaded, "garden", "saved current_area is 'garden'")
