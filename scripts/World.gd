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
