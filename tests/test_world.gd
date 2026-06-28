extends GutTest


func test_world_has_walls_player_and_spawn() -> void:
	var world := preload("res://scenes/World.tscn").instantiate()
	add_child_autofree(world)
	await get_tree().process_frame

	var static_bodies := []
	for child in world.get_children():
		if child is StaticBody2D:
			static_bodies.append(child)
	assert_gt(static_bodies.size(), 3, "World has >= 4 StaticBody2D walls")

	var players := []
	for child in world.get_children():
		if child is CharacterBody2D:
			players.append(child)
	assert_eq(players.size(), 1, "World has player (CharacterBody2D)")

	var spawn := world.get_node_or_null("Spawn")
	assert_not_null(spawn, "World has Marker2D named Spawn")
	assert_true(spawn is Marker2D, "Spawn is a Marker2D")
