extends GutTest

const TEST_PATH := "user://test_interiors_save.json"

const INTERIOR_KEYS := ["shop", "neighbor_house"]
const INTERIOR_SCENES := {
	"shop": "res://scenes/areas/Shop.tscn",
	"neighbor_house": "res://scenes/areas/NeighborHouse.tscn",
}


func after_each() -> void:
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(TEST_PATH)


func test_area_manager_loads_interiors() -> void:
	for key: String in INTERIOR_KEYS:
		var mgr := AreaManager.new()
		var container := Node2D.new()
		add_child_autofree(container)
		mgr.load_area(key, "EntryDefault", container)
		assert_eq(mgr.current_area, key, "current_area is '%s'" % key)
		assert_not_null(mgr.get_player(), "player placed in %s" % key)


func test_interiors_have_exit_door_to_city() -> void:
	var expected_entry := {
		"shop": "EntryFromShop",
		"neighbor_house": "EntryFromNeighborHouse",
	}
	for key: String in INTERIOR_KEYS:
		var interior: Node2D = (load(INTERIOR_SCENES[key]) as PackedScene).instantiate()
		add_child_autofree(interior)
		await get_tree().process_frame

		var found := false
		for child in interior.get_children():
			if child is Door:
				found = true
				assert_eq(child.target_area, "town", "%s exits to city" % key)
				assert_eq(child.target_entry, expected_entry[key], "%s exit entry" % key)
		assert_true(found, "%s has an exit Door" % key)


func test_city_has_interior_doors_and_return_markers() -> void:
	var city: Node2D = (load("res://scenes/areas/City.tscn") as PackedScene).instantiate()
	add_child_autofree(city)
	await get_tree().process_frame

	assert_not_null(city.get_node_or_null("EntryFromShop"), "city return marker for shop")
	assert_not_null(
		city.get_node_or_null("EntryFromNeighborHouse"), "city return marker for neighbor house"
	)

	var targets: Array[String] = []
	for child in city.get_children():
		if child is Door:
			targets.append(child.target_area)
	assert_has(targets, "shop", "city has a shop door")
	assert_has(targets, "neighbor_house", "city has a neighbor house door")


func test_interior_camera_zoom_is_closer() -> void:
	for key: String in INTERIOR_KEYS:
		var interior: Node2D = (load(INTERIOR_SCENES[key]) as PackedScene).instantiate()
		var player := Node2D.new()
		add_child_autofree(interior)
		add_child_autofree(player)
		await get_tree().process_frame

		var camera := CameraRig.attach(player, interior)
		assert_eq(camera.zoom, Vector2(2.5, 2.5), "%s uses closer zoom" % key)


func test_interior_area_persists_via_save() -> void:
	SaveManager.save_dweller(Dweller.new(), TEST_PATH, "shop")
	assert_eq(SaveManager.load_current_area(TEST_PATH), "shop", "shop round-trips")


func test_interior_entry_cells_walkable_and_clear_of_door() -> void:
	var layouts := {
		"shop": ShopMap.LAYOUT,
		"neighbor_house": NeighborHouseMap.LAYOUT,
	}
	var door_tables := {
		"shop": ShopMap.DOORS,
		"neighbor_house": NeighborHouseMap.DOORS,
	}
	for key: String in layouts:
		var parsed := MapBuilder.parse(layouts[key])
		var entries: Dictionary = parsed["entries"]
		assert_true(entries.has("Entry1"), "%s has Entry1" % key)
		for cell: Vector2i in parsed["doors"]:
			assert_true(door_tables[key].has(cell), "%s door wired: %s" % [key, cell])
			var entry_pos: Vector2 = entries["Entry1"]
			var gap: float = (entry_pos - MapBuilder.cell_center(cell)).length()
			assert_gt(gap, 40.0, "%s entry clear of door trigger zone" % key)


func test_interiors_have_residents() -> void:
	var expected := {"shop": "shopkeeper_sana", "neighbor_house": "neighbor_yuki"}
	for key: String in expected:
		var interior: Node2D = (load(INTERIOR_SCENES[key]) as PackedScene).instantiate()
		add_child_autofree(interior)
		await get_tree().process_frame

		var found := false
		for child in interior.get_children():
			if child is Npc:
				found = true
				assert_eq((child as Npc).npc_id, expected[key], "%s resident id" % key)
				assert_not_null((child as Npc).sprite_texture, "resident has skin")
		assert_true(found, "%s has a resident" % key)


func test_interiors_have_furniture_props() -> void:
	for key: String in INTERIOR_KEYS:
		var interior: Node2D = (load(INTERIOR_SCENES[key]) as PackedScene).instantiate()
		add_child_autofree(interior)
		await get_tree().process_frame

		var sprites := 0
		for child in interior.get_children():
			if child is Sprite2D:
				sprites += 1
		assert_gt(sprites, 4, "%s has furniture sprites" % key)


func test_resident_cells_not_on_entry() -> void:
	assert_ne(ShopMap.RESIDENT["cell"], Vector2i(10, 9), "shopkeeper not on entry")
	var parsed := MapBuilder.parse(ShopMap.LAYOUT)
	assert_false((parsed["entries"] as Dictionary).size() > 1, "shop has single entry digit")
