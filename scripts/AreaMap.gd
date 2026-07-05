class_name AreaMap
extends Node2D

## Base for MapBuilder-driven areas. Subclasses override _layout() and
## _door_table(); _after_build() hooks extra population (NPCs, aliases).

## 0 -> CameraRig default (2.0); interiors set a closer value in their scene.
@export var camera_zoom: float = 0.0

var _parsed: Dictionary = {}


func _ready() -> void:
	_parsed = MapBuilder.build(_layout(), self)
	_spawn_doors()
	_after_build()


func get_area_bounds() -> Rect2:
	if _parsed.is_empty():
		_parsed = MapBuilder.parse(_layout())
	return MapBuilder.bounds_of(_parsed)


func _layout() -> String:
	return ""


func _door_table() -> Dictionary:
	return {}


func _after_build() -> void:
	pass


## Doors must be direct children — Main._connect_area_doors scans get_children().
func _spawn_doors() -> void:
	for cell: Vector2i in _parsed["doors"]:
		var info: Dictionary = _door_table().get(cell, {})
		if info.is_empty():
			continue
		var door: Door = (preload("res://scenes/Door.tscn") as PackedScene).instantiate()
		door.position = MapBuilder.cell_center(cell)
		door.target_area = info["target_area"]
		door.target_entry = info["target_entry"]
		add_child(door)
