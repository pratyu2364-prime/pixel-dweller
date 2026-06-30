class_name AreaManager
extends RefCounted

var current_area: String = "house"

var _current_area_node: Node2D
var _player: CharacterBody2D

var _area_scenes: Dictionary = {
	"house": "res://scenes/areas/House.tscn",
	"garden": "res://scenes/areas/Garden.tscn",
}


func load_area(area_name: String, entry_name: String = "EntryDefault", container: Node = null) -> void:
	_unload_current()

	current_area = area_name

	var scene_path: String = _area_scenes.get(area_name, "")
	if scene_path.is_empty():
		return

	var scene: PackedScene = load(scene_path) as PackedScene
	if scene == null:
		return

	_current_area_node = scene.instantiate() as Node2D
	if _current_area_node == null:
		_current_area_node = null
		return

	if container != null:
		container.add_child(_current_area_node)

	_place_player(entry_name)


func get_current_area_node() -> Node2D:
	return _current_area_node


func get_player() -> CharacterBody2D:
	return _player


func _unload_current() -> void:
	if _player != null:
		var player_parent := _player.get_parent()
		if player_parent != null:
			player_parent.remove_child(_player)
		_player.queue_free()
		_player = null
	if _current_area_node != null:
		var area_parent := _current_area_node.get_parent()
		if area_parent != null:
			area_parent.remove_child(_current_area_node)
		_current_area_node.queue_free()
		_current_area_node = null


func _place_player(entry_name: String) -> void:
	var entry: Marker2D = _current_area_node.get_node_or_null(entry_name) as Marker2D

	var player_scene: PackedScene = preload("res://scenes/Player.tscn") as PackedScene
	_player = player_scene.instantiate() as CharacterBody2D
	if _player == null:
		return

	if entry != null:
		_player.position = entry.position

	_current_area_node.add_child(_player)

	var camera := Camera2D.new()
	camera.zoom = Vector2(3.5, 3.5)
	camera.position_smoothing_enabled = true
	_player.add_child(camera)
