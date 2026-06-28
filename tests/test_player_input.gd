extends GutTest

const Player := preload("res://scripts/Player.gd")
const PlayerScene := preload("res://scenes/Player.tscn")


func test_scene_instantiates_without_error() -> void:
	var p := PlayerScene.instantiate()
	add_child_autofree(p)
	await get_tree().process_frame
	assert_not_null(p.get_node_or_null("AnimatedSprite2D"), "has AnimatedSprite2D")
	assert_not_null(p.get_node_or_null("TouchDPad"), "has touch d-pad")
	assert_not_null((p.get_node("AnimatedSprite2D") as AnimatedSprite2D).sprite_frames, "sprite_frames set in _ready")


func test_up() -> void:
	assert_eq(Player.input_to_direction(Vector2(0.0, -1.0)), Vector2(0.0, -1.0))


func test_down() -> void:
	assert_eq(Player.input_to_direction(Vector2(0.0, 1.0)), Vector2(0.0, 1.0))


func test_left() -> void:
	assert_eq(Player.input_to_direction(Vector2(-1.0, 0.0)), Vector2(-1.0, 0.0))


func test_right() -> void:
	assert_eq(Player.input_to_direction(Vector2(1.0, 0.0)), Vector2(1.0, 0.0))


func test_diagonal_up_right() -> void:
	var expected := Vector2(1.0, -1.0).normalized()
	assert_eq(Player.input_to_direction(Vector2(1.0, -1.0)), expected)


func test_diagonal_down_left() -> void:
	var expected := Vector2(-1.0, 1.0).normalized()
	assert_eq(Player.input_to_direction(Vector2(-1.0, 1.0)), expected)


func test_idle() -> void:
	assert_eq(Player.input_to_direction(Vector2.ZERO), Vector2.ZERO)
