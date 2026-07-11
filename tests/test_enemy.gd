extends GutTest


func test_next_state_transitions() -> void:
	assert_eq(Enemy.next_state(200.0, 96.0, 0.0), Enemy.State.WANDER, "far -> wander")
	assert_eq(Enemy.next_state(50.0, 96.0, 0.0), Enemy.State.CHASE, "close -> chase")
	assert_eq(Enemy.next_state(50.0, 96.0, 0.1), Enemy.State.HURT, "hurt overrides")


func test_velocity_for_states() -> void:
	var chase := Enemy.velocity_for(
		Enemy.State.CHASE, Vector2(100, 0), Vector2.DOWN, 20.0, 45.0, Vector2.ZERO
	)
	assert_eq(chase, Vector2(45, 0), "chase runs at player")
	var hurt := Enemy.velocity_for(
		Enemy.State.HURT, Vector2(100, 0), Vector2.DOWN, 20.0, 45.0, Vector2(-120, 0)
	)
	assert_eq(hurt, Vector2(-120, 0), "hurt uses knockback")
	var wander := Enemy.velocity_for(
		Enemy.State.WANDER, Vector2.ZERO, Vector2.RIGHT, 20.0, 45.0, Vector2.ZERO
	)
	assert_eq(wander, Vector2(20, 0), "wander drifts")


func test_take_hit_reduces_hp_and_defeat_signal() -> void:
	var enemy: Enemy = (load("res://scenes/Enemy.tscn") as PackedScene).instantiate()
	add_child_autofree(enemy)
	await get_tree().process_frame
	watch_signals(enemy)

	enemy.take_hit(1, enemy.global_position + Vector2(10, 0))
	assert_eq(enemy.hp, 2)
	assert_signal_not_emitted(enemy, "defeated")

	enemy.take_hit(5, enemy.global_position + Vector2(10, 0))
	assert_signal_emitted(enemy, "defeated")


func test_enemy_scene_layers() -> void:
	var enemy: Enemy = (load("res://scenes/Enemy.tscn") as PackedScene).instantiate()
	add_child_autofree(enemy)
	await get_tree().process_frame
	assert_eq(enemy.collision_layer, 2, "enemy on layer 2 (sword target)")
	assert_eq((enemy.get_node("Hurtbox") as Area2D).collision_mask, 1, "hurtbox senses player")


func test_player_hurt_respects_invuln() -> void:
	var player: CharacterBody2D = (load("res://scenes/Player.tscn") as PackedScene).instantiate()
	add_child_autofree(player)
	await get_tree().process_frame
	watch_signals(player)

	player.hurt(1)
	player.hurt(1)
	player.hurt(1)
	assert_signal_emit_count(player, "damaged", 1, "invuln window blocks repeat hits")


func test_sword_kills_enemy() -> void:
	var player: CharacterBody2D = (load("res://scenes/Player.tscn") as PackedScene).instantiate()
	player.attack_power = 3
	add_child_autofree(player)
	var enemy: Enemy = (load("res://scenes/Enemy.tscn") as PackedScene).instantiate()
	enemy.position = Vector2(0, 18)
	add_child_autofree(enemy)
	await get_tree().physics_frame
	watch_signals(enemy)

	player._start_attack()
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame

	assert_signal_emitted(enemy, "defeated", "one 3-damage swing defeats a 3hp slime")
