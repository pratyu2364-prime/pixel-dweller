extends Node2D

@export var area_bounds: Rect2 = Rect2(-600, -750, 1200, 1500)
@export var camera_zoom: float = 0.0


func get_area_bounds() -> Rect2:
	return area_bounds
