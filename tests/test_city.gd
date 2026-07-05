extends GutTest

const CITY_SCENE := preload("res://scenes/areas/City.tscn")


func test_layout_is_at_least_100_by_120() -> void:
	var parsed := MapBuilder.parse(CityMap.LAYOUT)
	var size: Vector2i = parsed["size"]
	assert_gte(size.x, 100, "city at least 100 cells wide")
	assert_gte(size.y, 120, "city at least 120 cells tall")


func test_layout_entries_and_doors_defined() -> void:
	var parsed := MapBuilder.parse(CityMap.LAYOUT)
	var entries: Dictionary = parsed["entries"]
	assert_true(entries.has("Entry1"), "garden-side entry exists")
	assert_true(entries.has("Entry2"), "plaza spawn entry exists")
	for cell: Vector2i in parsed["doors"]:
		assert_true(CityMap.DOORS.has(cell), "every door cell is wired: %s" % cell)
	assert_gte((parsed["doors"] as Array).size(), 1, "at least one door cell")


func test_city_builds_map_and_markers() -> void:
	var city: Node2D = CITY_SCENE.instantiate()
	add_child_autofree(city)
	await get_tree().process_frame

	assert_not_null(city.get_node_or_null("Map"), "TileMapLayer built")
	assert_not_null(city.get_node_or_null("EntryDefault"), "EntryDefault fallback exists")
	assert_not_null(city.get_node_or_null("EntryFromGarden"), "EntryFromGarden alias exists")


func test_city_door_targets_garden() -> void:
	var city: Node2D = CITY_SCENE.instantiate()
	add_child_autofree(city)
	await get_tree().process_frame

	var found := false
	for child in city.get_children():
		if child is Door:
			found = true
			assert_eq(child.target_area, "garden", "city door targets garden")
			assert_eq(child.target_entry, "EntryFromTownGarden", "city door entry marker")
	assert_true(found, "city has a Door child")


func test_city_has_npc() -> void:
	var city: Node2D = CITY_SCENE.instantiate()
	add_child_autofree(city)
	await get_tree().process_frame

	var found := false
	for child in city.get_children():
		if child is Npc:
			found = true
	assert_true(found, "city has an Npc child")


func test_city_bounds_cover_full_map() -> void:
	var city: Node2D = CITY_SCENE.instantiate()
	add_child_autofree(city)
	await get_tree().process_frame

	var bounds: Rect2 = city.get_area_bounds()
	assert_eq(bounds.position, Vector2.ZERO)
	assert_gte(bounds.size.x, 1600.0, "bounds at least 1600 px wide")
	assert_gte(bounds.size.y, 1920.0, "bounds at least 1920 px tall")


func test_area_manager_town_key_loads_city() -> void:
	var mgr := AreaManager.new()
	var container := Node2D.new()
	add_child_autofree(container)

	mgr.load_area("town", "EntryDefault", container)
	assert_eq(mgr.current_area, "town", "legacy 'town' key still works")
	var area := mgr.get_current_area_node()
	assert_eq(area.name.substr(0, 4), "City", "'town' key loads the City scene")
	assert_not_null(mgr.get_player(), "player placed in city")


func test_walkable_spawn_cells() -> void:
	var parsed := MapBuilder.parse(CityMap.LAYOUT)
	var entries: Dictionary = parsed["entries"]
	for entry_name: String in entries:
		var pos: Vector2 = entries[entry_name]
		var cell := Vector2i(int(pos.x) / MapBuilder.CELL, int(pos.y) / MapBuilder.CELL)
		assert_false(MapBuilder.is_solid(parsed, cell), "%s spawn cell walkable" % entry_name)
