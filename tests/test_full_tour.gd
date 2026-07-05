extends GutTest

const TEST_PATH := "user://test_full_tour_save.json"

const ALL_AREAS := ["house", "garden", "town", "shop", "neighbor_house"]

## The Phase 3 walk: home -> garden -> city -> shop -> city -> neighbor -> back.
const TOUR := [
	{"area": "house", "entry": "EntryDefault"},
	{"area": "garden", "entry": "EntryFromHouse"},
	{"area": "town", "entry": "EntryFromGarden"},
	{"area": "shop", "entry": "EntryDefault"},
	{"area": "town", "entry": "EntryFromShop"},
	{"area": "neighbor_house", "entry": "EntryDefault"},
	{"area": "town", "entry": "EntryFromNeighborHouse"},
	{"area": "garden", "entry": "EntryFromTownGarden"},
	{"area": "house", "entry": "EntryFromGarden"},
]


func after_each() -> void:
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(TEST_PATH)


func test_full_tour_visits_every_stop() -> void:
	var mgr := AreaManager.new()
	var container := Node2D.new()
	add_child_autofree(container)

	for stop: Dictionary in TOUR:
		mgr.load_area(stop["area"], stop["entry"], container)
		assert_eq(mgr.current_area, stop["area"], "arrived at %s" % stop["area"])
		assert_not_null(mgr.get_player(), "player alive at %s" % stop["area"])
		var entry := mgr.get_current_area_node().get_node_or_null(stop["entry"])
		assert_not_null(entry, "%s has marker %s" % [stop["area"], stop["entry"]])
		assert_eq(
			mgr.get_player().position,
			(entry as Marker2D).position,
			"player placed at %s in %s" % [stop["entry"], stop["area"]]
		)


func test_boot_from_every_saved_area() -> void:
	for area: String in ALL_AREAS:
		SaveManager.save_dweller(Dweller.new(), TEST_PATH, area)
		assert_eq(SaveManager.load_current_area(TEST_PATH), area, "%s round-trips" % area)

		var mgr := AreaManager.new()
		var container := Node2D.new()
		add_child_autofree(container)
		mgr.load_area(area, "EntryDefault", container)
		assert_eq(mgr.current_area, area, "boot lands in %s" % area)
		assert_not_null(mgr.get_player(), "player placed booting into %s" % area)


## Wiring invariant: every Door in every area points at a registered area
## and at an entry marker that actually exists there.
func test_door_graph_is_consistent() -> void:
	var doors_seen := 0
	for area: String in ALL_AREAS:
		var mgr := AreaManager.new()
		var container := Node2D.new()
		add_child_autofree(container)
		mgr.load_area(area, "EntryDefault", container)

		for child in mgr.get_current_area_node().get_children():
			if not child is Door:
				continue
			doors_seen += 1
			var door := child as Door
			assert_has(ALL_AREAS, door.target_area, "%s door target registered" % area)

			var target_mgr := AreaManager.new()
			var target_container := Node2D.new()
			add_child_autofree(target_container)
			target_mgr.load_area(door.target_area, door.target_entry, target_container)
			var marker := target_mgr.get_current_area_node().get_node_or_null(door.target_entry)
			assert_not_null(
				marker,
				"%s -> %s: entry %s exists" % [area, door.target_area, door.target_entry]
			)
	assert_gte(doors_seen, 7, "all doors covered (house, garden x2, city x3, interiors x2)")


func test_boot_with_unknown_entry_falls_back() -> void:
	for area: String in ALL_AREAS:
		var mgr := AreaManager.new()
		var container := Node2D.new()
		add_child_autofree(container)
		mgr.load_area(area, "NoSuchEntry", container)
		assert_not_null(mgr.get_player(), "player survives bad entry in %s" % area)
