extends GutTest

const Npc := preload("res://scripts/Npc.gd")


func test_first_greet_boosts_mood() -> void:
	var npc := Npc.new()
	var result := npc.greet(100.0)
	assert_eq(result.mood_boost, Npc.MOOD_BOOST, "first greet grants mood boost")
	assert_true(result.text.length() > 0, "greeting text non-empty")


func test_greet_within_cooldown_no_boost() -> void:
	var npc := Npc.new()
	npc.greet(100.0)
	var result := npc.greet(105.0)
	assert_eq(result.mood_boost, 0.0, "within cooldown no mood boost")
	assert_true(result.text.length() > 0, "text still returned within cooldown")


func test_greet_after_cooldown_boosts_again() -> void:
	var npc := Npc.new()
	npc.greet(100.0)
	npc.greet(105.0)
	var result := npc.greet(131.0)
	assert_eq(result.mood_boost, Npc.MOOD_BOOST, "after cooldown boost again")


func test_facing_toward_player() -> void:
	assert_eq(Npc.facing_toward(Vector2.ZERO, Vector2(50, 10)), Npc.COL_RIGHT)
	assert_eq(Npc.facing_toward(Vector2.ZERO, Vector2(-50, 10)), Npc.COL_LEFT)
	assert_eq(Npc.facing_toward(Vector2.ZERO, Vector2(10, 50)), Npc.COL_DOWN)
	assert_eq(Npc.facing_toward(Vector2.ZERO, Vector2(10, -50)), Npc.COL_UP)


func test_npc_scene_has_sprite() -> void:
	var npc: Npc = (load("res://scenes/Npc.tscn") as PackedScene).instantiate()
	add_child_autofree(npc)
	await get_tree().process_frame
	var sprite := npc.get_node_or_null("Sprite") as Sprite2D
	assert_not_null(sprite, "Npc has a Sprite2D")
	assert_not_null(sprite.texture, "Npc sprite textured")
	assert_eq(sprite.hframes, 4)
	assert_eq(sprite.vframes, 7)


func test_city_npcs_have_varied_skins() -> void:
	var city: Node2D = (load("res://scenes/areas/City.tscn") as PackedScene).instantiate()
	add_child_autofree(city)
	await get_tree().process_frame
	var textures := {}
	for child in city.get_children():
		if child is Npc:
			textures[(child as Npc).sprite_texture.resource_path] = true
	assert_gte(textures.size(), 2, "at least 2 NPC skins in city")
