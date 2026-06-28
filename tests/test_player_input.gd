extends GutTest

const Player := preload("res://scripts/Player.gd")
const PlayerScene := preload("res://scenes/Player.tscn")


func test_scene_instantiates_without_error() -> void:
	var p := PlayerScene.instantiate()
	add_child_autofree(p)
	await get_tree().process_frame
	var spr := p.get_node_or_null("Sprite") as Sprite2D
	assert_not_null(spr, "has Sprite2D")
	assert_not_null(spr.texture, "sprite has a real texture")
	assert_eq(spr.hframes, 4, "4 direction columns")
	assert_eq(spr.vframes, 7, "7 frame rows")
	assert_not_null(p.get_node_or_null("TouchDPad"), "has touch d-pad")


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
