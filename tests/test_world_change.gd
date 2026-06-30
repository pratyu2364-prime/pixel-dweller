extends GutTest

const Dweller := preload("res://scripts/Dweller.gd")
const SaveManager := preload("res://scripts/SaveManager.gd")

const TEST_PATH: String = "user://test_world_change.json"


func after_each() -> void:
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(TEST_PATH)


func test_kid_decoration_appears_at_kid_stage() -> void:
	var garden := preload("res://scenes/areas/Garden.tscn").instantiate()
	add_child_autofree(garden)
	await get_tree().process_frame

	garden.apply_world_stage(Dweller.Stage.KID)

	var tree := garden.get_node_or_null("TreeDecoration")
	assert_not_null(tree, "TreeDecoration exists at KID stage")
	assert_true(tree is Polygon2D, "TreeDecoration is a Polygon2D")


func test_adult_stage_shows_all_decorations() -> void:
	var garden := preload("res://scenes/areas/Garden.tscn").instantiate()
	add_child_autofree(garden)
	await get_tree().process_frame

	garden.apply_world_stage(Dweller.Stage.ADULT)

	var tree := garden.get_node_or_null("TreeDecoration")
	assert_not_null(tree, "TreeDecoration exists at ADULT stage")
	var flowers := garden.get_node_or_null("FlowersDecoration")
	assert_not_null(flowers, "FlowersDecoration exists at ADULT stage")


func test_apply_world_stage_idempotent() -> void:
	var garden := preload("res://scenes/areas/Garden.tscn").instantiate()
	add_child_autofree(garden)
	await get_tree().process_frame

	garden.apply_world_stage(Dweller.Stage.ADULT)
	garden.apply_world_stage(Dweller.Stage.ADULT)

	var count: int = 0
	for child in garden.get_children():
		if child is Polygon2D and child.name in ["TreeDecoration", "FlowersDecoration"]:
			count += 1

	assert_eq(count, 2, "No duplicate decorations on idempotent call")


func test_save_load_round_trip_preserves_stage() -> void:
	var d := Dweller.new()
	d.stage = Dweller.Stage.ADULT
	SaveManager.save_dweller(d, TEST_PATH)

	var d2 := Dweller.new()
	SaveManager.load_into_dweller(d2, TEST_PATH)

	assert_eq(d2.stage, Dweller.Stage.ADULT, "Stage preserved through save/load")


func test_house_has_no_apply_world_stage() -> void:
	var house := preload("res://scenes/areas/House.tscn").instantiate()
	add_child_autofree(house)
	await get_tree().process_frame

	assert_false(house.has_method("apply_world_stage"), "House has no apply_world_stage")


func test_house_grows_no_decor_at_adult() -> void:
	var house := preload("res://scenes/areas/House.tscn").instantiate()
	add_child_autofree(house)
	await get_tree().process_frame

	var tree := house.get_node_or_null("TreeDecoration")
	assert_null(tree, "House has no TreeDecoration at any stage")
	var flowers := house.get_node_or_null("FlowersDecoration")
	assert_null(flowers, "House has no FlowersDecoration at any stage")
