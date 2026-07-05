extends GutTest

const PlayerScript := preload("res://scripts/Player.gd")

const DUMMY_SOURCE := """
extends StaticBody2D
var hits: int = 0
var last_from: Vector2 = Vector2.ZERO
func take_hit(damage: int, from_pos: Vector2) -> void:
	hits += damage
	last_from = from_pos
"""


func test_swing_offset_all_directions() -> void:
	assert_eq(PlayerScript.swing_offset(PlayerScript.COL_RIGHT), Vector2(18, 0))
	assert_eq(PlayerScript.swing_offset(PlayerScript.COL_LEFT), Vector2(-18, 0))
	assert_eq(PlayerScript.swing_offset(PlayerScript.COL_UP), Vector2(0, -18))
	assert_eq(PlayerScript.swing_offset(PlayerScript.COL_DOWN), Vector2(0, 18))


func test_attack_action_registered() -> void:
	assert_true(InputMap.has_action("attack"), "attack action in input map")


func test_player_scene_has_sword_nodes() -> void:
	var player: CharacterBody2D = (load("res://scenes/Player.tscn") as PackedScene).instantiate()
	add_child_autofree(player)
	await get_tree().process_frame

	var area := player.get_node("SwordArea") as Area2D
	assert_not_null(area, "SwordArea exists")
	assert_false(area.monitoring, "sword idle by default")
	assert_eq(area.collision_mask, 2, "sword hits enemy layer")
	assert_false((player.get_node("SwordSprite") as Sprite2D).visible, "sword hidden idle")


func test_sword_swing_hits_enemy_layer_body() -> void:
	var player: CharacterBody2D = (load("res://scenes/Player.tscn") as PackedScene).instantiate()
	player.attack_power = 3
	add_child_autofree(player)

	var dummy_script := GDScript.new()
	dummy_script.source_code = DUMMY_SOURCE
	dummy_script.reload()
	var dummy := StaticBody2D.new()
	dummy.set_script(dummy_script)
	dummy.collision_layer = 2
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(14, 14)
	shape.shape = rect
	dummy.add_child(shape)
	dummy.position = Vector2(0, 18) # in front of default down-facing player
	add_child_autofree(dummy)

	await get_tree().physics_frame
	player._start_attack()
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame

	assert_eq(dummy.hits, 3, "sword dealt attack_power damage")
	assert_true(player.is_attacking(), "swing still active within ATTACK_TIME")
