extends GutTest


func test_house_has_walls_and_entry() -> void:
	var house := preload("res://scenes/areas/House.tscn").instantiate()
	add_child_autofree(house)
	await get_tree().process_frame

	var static_bodies := []
	for child in house.get_children():
		if child is StaticBody2D:
			static_bodies.append(child)
	assert_gt(static_bodies.size(), 3, "House has >= 4 StaticBody2D walls")

	var entry := house.get_node_or_null("EntryDefault")
	assert_not_null(entry, "House has Marker2D named EntryDefault")
	assert_true(entry is Marker2D, "EntryDefault is a Marker2D")
