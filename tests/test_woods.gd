extends GutTest

## Whispering Woods — the danger area. Enemies live only here; town is safe;
## defeat sends the player home with full hearts.


func test_layout_has_enemy_spawns() -> void:
	var parsed := MapBuilder.parse(WoodsMap.LAYOUT)
	assert_gte((parsed["spawns"] as Array).size(), 5, "woods holds a pack of slimes")


func test_spawn_cells_are_walkable() -> void:
	var parsed := MapBuilder.parse(WoodsMap.LAYOUT)
	for cell: Vector2i in parsed["spawns"]:
		assert_false(MapBuilder.is_solid(parsed, cell), "spawn %s walkable" % cell)


func test_door_cell_matches_door_table() -> void:
	var parsed := MapBuilder.parse(WoodsMap.LAYOUT)
	for cell: Vector2i in parsed["doors"]:
		assert_true(WoodsMap.DOORS.has(cell), "door %s wired" % cell)
	assert_eq((parsed["doors"] as Array).size(), WoodsMap.DOORS.size(), "all doors placed")


func test_entry_reaches_door_on_foot() -> void:
	var parsed := MapBuilder.parse(WoodsMap.LAYOUT)
	var entry := Vector2i(19, 30)
	assert_true(parsed["entries"].has("Entry1"), "Entry1 exists")
	assert_eq(parsed["entries"]["Entry1"], MapBuilder.cell_center(entry), "Entry1 at path")

	# BFS from entry: door cell must be reachable walking.
	var target := Vector2i(19, 33)
	var seen := {entry: true}
	var queue: Array[Vector2i] = [entry]
	var found := false
	while not queue.is_empty():
		var cur: Vector2i = queue.pop_front()
		if cur == target:
			found = true
			break
		for offset: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var next: Vector2i = cur + offset
			if seen.has(next) or MapBuilder.is_solid(parsed, next):
				continue
			seen[next] = true
			queue.append(next)
	assert_true(found, "door reachable from entry")


func test_woods_area_spawns_enemies() -> void:
	var mgr := AreaManager.new()
	var container := Node2D.new()
	add_child_autofree(container)
	mgr.load_area("woods", "EntryFromTown", container)

	var enemies := 0
	for child in mgr.get_current_area_node().get_children():
		if child is Enemy:
			enemies += 1
	assert_gte(enemies, 5, "slimes populate the woods")


func test_town_stays_safe() -> void:
	assert_false(CityMap.LAYOUT.contains("e"), "no enemy spawn cells in town")

	var mgr := AreaManager.new()
	var container := Node2D.new()
	add_child_autofree(container)
	mgr.load_area("town", "EntryDefault", container)
	for child in mgr.get_current_area_node().get_children():
		assert_false(child is Enemy, "no enemies in town")


func test_defeat_heals_to_full() -> void:
	var stats := Stats.new()
	stats.take_damage(99)
	assert_eq(stats.hp, 0, "defeated")
	stats.heal_full()
	assert_eq(stats.hp, stats.max_hp, "respawn restores full hearts")
