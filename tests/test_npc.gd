extends GutTest

const Npc := preload("res://scripts/Npc.gd")


func test_first_greet_gives_intro_and_boost() -> void:
	var npc := Npc.new()
	var result := npc.greet()
	assert_eq(result.mood_boost, Npc.MOOD_BOOST, "first meeting grants mood boost")
	assert_eq(result.text, npc.greeting, "first meeting uses full intro")
	assert_true(npc.already_met, "greet marks NPC as met")


func test_repeat_greet_short_line_no_boost() -> void:
	var npc := Npc.new()
	npc.greet()
	var result := npc.greet()
	assert_eq(result.mood_boost, 0.0, "no boost after first meeting")
	assert_eq(result.text, npc.repeat_text, "repeat line after first meeting")


func test_preloaded_met_flag_skips_intro() -> void:
	var npc := Npc.new()
	npc.already_met = true
	var result := npc.greet()
	assert_eq(result.text, npc.repeat_text, "met NPC from save greets with repeat line")
	assert_eq(result.mood_boost, 0.0)


func test_met_npcs_persist_via_save() -> void:
	var path := "user://test_npc_met.json"
	SaveManager.mark_npc_met("plaza_greeter", path)
	SaveManager.mark_npc_met("berry_vendor", path)
	SaveManager.mark_npc_met("plaza_greeter", path)
	var met := SaveManager.load_met_npcs(path)
	assert_eq(met.size(), 2, "no duplicate met entries")
	assert_has(met, "plaza_greeter")
	assert_has(met, "berry_vendor")
	SaveManager.save_dweller(Dweller.new(), path, "town")
	assert_eq(SaveManager.load_met_npcs(path).size(), 2, "save_dweller preserves met_npcs")
	DirAccess.remove_absolute(path)


func test_city_npcs_have_unique_ids_and_types() -> void:
	var ids := {}
	for entry: Dictionary in CityMap.NPCS:
		assert_false(ids.has(entry["id"]), "duplicate npc id: %s" % entry["id"])
		ids[entry["id"]] = true
		assert_true(entry["type"].length() > 0, "npc has a type")
		assert_true(entry["repeat"].length() > 0, "npc has a repeat line")


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
