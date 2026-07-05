extends GutTest


func test_house_has_walls_and_entry() -> void:
	var house := preload("res://scenes/areas/House.tscn").instantiate()
	add_child_autofree(house)
	await get_tree().process_frame

	assert_not_null(house.get_node_or_null("Map"), "House builds a TileMapLayer")
	var parsed := MapBuilder.parse(HouseMap.LAYOUT)
	var size: Vector2i = parsed["size"]
	for x in size.x:
		assert_true(MapBuilder.is_solid(parsed, Vector2i(x, 0)), "top boundary solid")
	for y in size.y:
		assert_true(MapBuilder.is_solid(parsed, Vector2i(0, y)), "left boundary solid")

	var entry := house.get_node_or_null("EntryDefault")
	assert_not_null(entry, "House has Marker2D named EntryDefault")
	assert_true(entry is Marker2D, "EntryDefault is a Marker2D")
