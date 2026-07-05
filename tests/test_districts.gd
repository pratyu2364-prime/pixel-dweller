extends GutTest


func test_district_at_known_spots() -> void:
	assert_eq(CityMap.district_for(Vector2(800, 650)), "Sunny Plaza", "plaza center")
	assert_eq(CityMap.district_for(Vector2(400, 790)), "Market Street", "market road")
	assert_eq(CityMap.district_for(Vector2(1360, 160)), "Riverside Park", "park")
	assert_eq(CityMap.district_for(Vector2(1360, 400)), "Museum District", "museum")
	assert_eq(CityMap.district_for(Vector2(560, 1150)), "Riverside", "river band")
	assert_eq(CityMap.district_for(Vector2(800, 1700)), "Maple Residential", "south homes")
	assert_eq(CityMap.district_for(Vector2(200, 300)), "Old Quarter", "civic NW")
	assert_eq(CityMap.district_for(Vector2(800, 300)), "North Avenue", "north central")


func test_district_band_boundaries() -> void:
	assert_eq(CityMap.district_for(Vector2(800, 768)), "Market Street", "band start inclusive")
	assert_eq(CityMap.district_for(Vector2(800, 767)), "Sunny Plaza", "one px above is plaza")
	assert_eq(CityMap.district_for(Vector2(800, 928)), "Riverside", "riverside start")
	assert_eq(CityMap.district_for(Vector2(800, 1280)), "Maple Residential", "residential start")


func test_district_fallback_outside_map() -> void:
	assert_eq(CityMap.district_for(Vector2(-50, -50)), "City", "outside falls back to City")


func test_every_district_has_unique_name() -> void:
	var names: Array[String] = []
	for district: Dictionary in CityMap.DISTRICTS:
		assert_false(names.has(district["name"]), "duplicate district: %s" % district["name"])
		names.append(district["name"])
	assert_gte(names.size(), 5, "at least 5 districts")


func test_city_spawns_at_least_5_distinct_npcs() -> void:
	var city: Node2D = (load("res://scenes/areas/City.tscn") as PackedScene).instantiate()
	add_child_autofree(city)
	await get_tree().process_frame

	var greetings: Array[String] = []
	for child in city.get_children():
		if child is Npc:
			greetings.append((child as Npc).greeting)
	assert_gte(greetings.size(), 5, "at least 5 NPCs in the city")

	var unique := {}
	for greeting: String in greetings:
		unique[greeting] = true
	assert_eq(unique.size(), greetings.size(), "all greetings distinct")


func test_npc_spawn_cells_walkable() -> void:
	var parsed := MapBuilder.parse(CityMap.LAYOUT)
	for entry: Dictionary in CityMap.NPCS:
		assert_false(
			MapBuilder.is_solid(parsed, entry["cell"]),
			"NPC cell walkable: %s" % entry["cell"]
		)


func test_npcs_cover_multiple_districts() -> void:
	var covered := {}
	for entry: Dictionary in CityMap.NPCS:
		covered[CityMap.district_for(MapBuilder.cell_center(entry["cell"]))] = true
	assert_gte(covered.size(), 4, "NPCs spread across at least 4 districts")
