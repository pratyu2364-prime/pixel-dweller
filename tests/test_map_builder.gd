extends GutTest

const DEMO_LAYOUT := """
##########
#...r....#
#.1.r.tt.#
#...r....#
#wwwbwww.#
#...r..2.#
#...D....#
##########
"""


func test_parse_size_and_rows() -> void:
	var parsed := MapBuilder.parse(DEMO_LAYOUT)
	assert_eq(parsed["size"], Vector2i(10, 8))
	assert_eq((parsed["rows"] as PackedStringArray).size(), 8)


func test_parse_pads_short_rows_with_grass() -> void:
	var parsed := MapBuilder.parse("##\n#")
	assert_eq(parsed["size"], Vector2i(2, 2))
	assert_false(MapBuilder.is_solid(parsed, Vector2i(1, 1)))


func test_parse_finds_entries_at_cell_centers() -> void:
	var parsed := MapBuilder.parse(DEMO_LAYOUT)
	var entries: Dictionary = parsed["entries"]
	assert_eq(entries.size(), 2)
	assert_eq(entries["Entry1"], Vector2(2 * 16 + 8, 2 * 16 + 8))
	assert_eq(entries["Entry2"], Vector2(7 * 16 + 8, 5 * 16 + 8))


func test_parse_finds_door_cells() -> void:
	var parsed := MapBuilder.parse(DEMO_LAYOUT)
	var doors: Array[Vector2i] = parsed["doors"]
	assert_eq(doors, [Vector2i(4, 6)] as Array[Vector2i])


func test_solid_and_walkable_cells() -> void:
	var parsed := MapBuilder.parse(DEMO_LAYOUT)
	assert_true(MapBuilder.is_solid(parsed, Vector2i(0, 0)), "wall solid")
	assert_true(MapBuilder.is_solid(parsed, Vector2i(1, 4)), "water solid")
	assert_true(MapBuilder.is_solid(parsed, Vector2i(6, 2)), "tree solid")
	assert_false(MapBuilder.is_solid(parsed, Vector2i(4, 1)), "road walkable")
	assert_false(MapBuilder.is_solid(parsed, Vector2i(4, 4)), "bridge over water walkable")
	assert_false(MapBuilder.is_solid(parsed, Vector2i(2, 2)), "entry cell walkable")
	assert_false(MapBuilder.is_solid(parsed, Vector2i(4, 6)), "door cell walkable")
	assert_true(MapBuilder.is_solid(parsed, Vector2i(-1, 0)), "out of bounds solid")


func test_bounds_of() -> void:
	var parsed := MapBuilder.parse(DEMO_LAYOUT)
	assert_eq(MapBuilder.bounds_of(parsed), Rect2(0, 0, 160, 128))


func test_build_creates_map_layer_and_markers() -> void:
	var root := Node2D.new()
	add_child_autofree(root)
	var parsed := MapBuilder.build(DEMO_LAYOUT, root)

	var layer := root.get_node("Map") as TileMapLayer
	assert_not_null(layer)
	assert_eq(layer.get_used_cells().size(), 10 * 8)

	var entry1 := root.get_node("Entry1") as Marker2D
	assert_not_null(entry1)
	assert_eq(entry1.position, (parsed["entries"] as Dictionary)["Entry1"])
	assert_not_null(root.get_node_or_null("EntryDefault"))


func test_build_solid_tiles_have_collision() -> void:
	var root := Node2D.new()
	add_child_autofree(root)
	MapBuilder.build(DEMO_LAYOUT, root)

	var layer := root.get_node("Map") as TileMapLayer
	var tile_set := layer.tile_set
	assert_eq(tile_set.get_physics_layers_count(), 1)
	assert_eq(tile_set.get_physics_layer_collision_layer(0), 1)

	var atlas := tile_set.get_source(0) as TileSetAtlasSource
	var wall_atlas := layer.get_cell_atlas_coords(Vector2i(0, 0))
	var road_atlas := layer.get_cell_atlas_coords(Vector2i(4, 1))
	assert_eq(atlas.get_tile_data(wall_atlas, 0).get_collision_polygons_count(0), 1)
	assert_eq(atlas.get_tile_data(road_atlas, 0).get_collision_polygons_count(0), 0)


func test_prop_footprint_blocks_movement() -> void:
	var parsed := MapBuilder.parse("....\n.H..\n....\n....\n....")
	assert_true(MapBuilder.is_solid(parsed, Vector2i(1, 1)), "house anchor solid")
	assert_true(MapBuilder.is_solid(parsed, Vector2i(3, 3)), "house footprint corner solid (4x3 clipped)")
	assert_false(MapBuilder.is_solid(parsed, Vector2i(0, 0)), "outside footprint walkable")
	assert_eq((parsed["props"] as Array).size(), 1)


func test_flower_prop_is_walkable() -> void:
	var parsed := MapBuilder.parse("...\n.f.\n...")
	assert_false(MapBuilder.is_solid(parsed, Vector2i(1, 1)), "flowers walkable")


func test_build_spawns_prop_sprites_and_collision() -> void:
	var root := Node2D.new()
	add_child_autofree(root)
	MapBuilder.build("......\n.H..t.\n......\n......", root)

	var sprites := 0
	var bodies := 0
	for child in root.get_children():
		if child is Sprite2D:
			sprites += 1
			for sub in child.get_children():
				if sub is StaticBody2D:
					bodies += 1
	assert_eq(sprites, 2, "house + tree sprites spawned")
	assert_eq(bodies, 2, "both props solid")
	assert_true(root.y_sort_enabled, "area y-sorts props vs player")


func test_door_renders_as_paved_mat() -> void:
	var rows := PackedStringArray(["....", ".D..", "...."])
	assert_eq(MapBuilder._render_char(rows, 1, 1), "r", "door on grass renders road mat")
	var rows2 := PackedStringArray(["pppp", "pDpp", "pppp"])
	assert_eq(MapBuilder._render_char(rows2, 1, 1), "p", "door on plaza renders plaza")
