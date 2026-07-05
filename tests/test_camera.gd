extends GutTest


func test_compute_limits_from_bounds() -> void:
	var limits := CameraRig.compute_limits(Rect2(-600, -750, 1200, 1500))
	assert_eq(limits["left"], -600)
	assert_eq(limits["top"], -750)
	assert_eq(limits["right"], 600)
	assert_eq(limits["bottom"], 750)


func test_compute_limits_origin_based_bounds() -> void:
	var limits := CameraRig.compute_limits(Rect2(0, 0, 1600, 1920))
	assert_eq(limits["left"], 0)
	assert_eq(limits["top"], 0)
	assert_eq(limits["right"], 1600)
	assert_eq(limits["bottom"], 1920)


func test_attach_uses_default_zoom_and_smoothing() -> void:
	var player := Node2D.new()
	var area := Node2D.new()
	add_child_autofree(player)
	add_child_autofree(area)
	var camera := CameraRig.attach(player, area)
	assert_eq(camera.zoom, Vector2(2.0, 2.0))
	assert_true(camera.position_smoothing_enabled)
	assert_eq(camera.get_parent(), player)


func test_attach_clamps_to_area_bounds() -> void:
	var player := Node2D.new()
	var area: Node2D = (load("res://scenes/areas/Garden.tscn") as PackedScene).instantiate()
	add_child_autofree(player)
	add_child_autofree(area)
	var camera := CameraRig.attach(player, area)
	var bounds: Rect2 = area.get_area_bounds()
	assert_gt(bounds.size.x, 0.0, "garden bounds non-empty")
	assert_eq(camera.limit_left, int(bounds.position.x))
	assert_eq(camera.limit_top, int(bounds.position.y))
	assert_eq(camera.limit_right, int(bounds.end.x))
	assert_eq(camera.limit_bottom, int(bounds.end.y))


func test_attach_honors_area_zoom_override() -> void:
	var player := Node2D.new()
	var area: Node2D = (load("res://scenes/areas/House.tscn") as PackedScene).instantiate()
	add_child_autofree(player)
	add_child_autofree(area)
	var camera := CameraRig.attach(player, area)
	assert_eq(camera.zoom, Vector2(2.5, 2.5))
