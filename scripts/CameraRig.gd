class_name CameraRig
extends RefCounted

const DEFAULT_ZOOM := 2.0


## Pure: area bounds -> Camera2D limit values.
static func compute_limits(bounds: Rect2) -> Dictionary:
	return {
		"left": int(bounds.position.x),
		"top": int(bounds.position.y),
		"right": int(bounds.end.x),
		"bottom": int(bounds.end.y),
	}


## Creates the player camera. Zoom comes from the area's optional camera_zoom
## property (falls back to DEFAULT_ZOOM); limits clamp to the area's optional
## get_area_bounds() so the void outside the map is never visible.
static func attach(player: Node2D, area: Node2D) -> Camera2D:
	var camera := Camera2D.new()

	var zoom := DEFAULT_ZOOM
	if area != null:
		var override: Variant = area.get("camera_zoom")
		if override != null and float(override) > 0.0:
			zoom = float(override)
	camera.zoom = Vector2(zoom, zoom)
	camera.position_smoothing_enabled = true

	if area != null and area.has_method("get_area_bounds"):
		var limits := compute_limits(area.get_area_bounds())
		camera.limit_left = limits["left"]
		camera.limit_top = limits["top"]
		camera.limit_right = limits["right"]
		camera.limit_bottom = limits["bottom"]

	player.add_child(camera)
	return camera
