extends Node2D

@onready var spawn: Marker2D = $Spawn


func _ready() -> void:
	var player := preload("res://scenes/Player.tscn").instantiate() as CharacterBody2D
	player.position = spawn.position
	player.collision_layer = 1
	player.collision_mask = 1
	add_child(player)

	var camera := Camera2D.new()
	camera.position_smoothing_enabled = true
	player.add_child(camera)


func apply_world_stage(stage_index: int) -> void:
	if stage_index >= Dweller.Stage.KID:
		_add_tree()
	if stage_index >= Dweller.Stage.ADULT:
		_add_flowers()


func _add_tree() -> void:
	if get_node_or_null("TreeDecoration") != null:
		return
	var tree: Polygon2D = Polygon2D.new()
	tree.name = "TreeDecoration"
	tree.polygon = PackedVector2Array([
		Vector2(-30, 0), Vector2(30, 0), Vector2(0, -60),
	])
	tree.color = Color(0.0, 0.6, 0.0)
	tree.position = Vector2(200, -100)
	add_child(tree)


func _add_flowers() -> void:
	if get_node_or_null("FlowersDecoration") != null:
		return
	var flowers: Polygon2D = Polygon2D.new()
	flowers.name = "FlowersDecoration"
	flowers.polygon = PackedVector2Array([
		Vector2(-15, -8), Vector2(15, -8), Vector2(8, 8), Vector2(-8, 8),
	])
	flowers.color = Color(1.0, 0.5, 0.8)
	flowers.position = Vector2(-200, 150)
	add_child(flowers)
