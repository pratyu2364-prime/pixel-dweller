extends GutTest

const GAME := preload("res://scenes/Game.tscn")


func _setup(defs: Array) -> Array:
	var field := LightField.new(24, 24)
	for def in defs:
		field.emit(def["id"], def["cell"], def.get("radius", 5.0), def.get("intensity", 1.0))
	return [field, ClingController.new(field, defs)]


func _candle(id: String, cell: Vector2i) -> Dictionary:
	return {"id": id, "kind": "candle", "cell": cell, "radius": 4.0, "intensity": 0.85}


func _brazier(id: String, cell: Vector2i) -> Dictionary:
	return {"id": id, "kind": "brazier", "cell": cell, "radius": 8.0, "intensity": 1.0}


func test_reaches_only_what_is_within_arm_length() -> void:
	var setup := _setup([_candle("c0", Vector2i(5, 5))])
	var cling: ClingController = setup[1]
	assert_eq(cling.target_near(Vector2i(6, 5)), "c0")
	assert_eq(cling.target_near(Vector2i(12, 5)), "", "across the room is out of reach")


func test_grabbing_a_candle_dims_it_and_carrying_moves_the_light() -> void:
	var setup := _setup([_candle("c0", Vector2i(5, 5))])
	var field: LightField = setup[0]
	var cling: ClingController = setup[1]
	assert_eq(cling.press(Vector2i(5, 5)), "grab")
	assert_true(cling.is_holding())
	assert_almost_eq(field.get_emitter("c0").intensity, ClingController.CARRY_INTENSITY, 0.001)
	cling.tick(0.1, Vector2i(9, 5), true)
	assert_eq(field.get_emitter("c0").cell, Vector2i(9, 5), "the light travels with her")


func test_setting_a_candle_down_restores_its_glow() -> void:
	var setup := _setup([_candle("c0", Vector2i(5, 5))])
	var field: LightField = setup[0]
	var cling: ClingController = setup[1]
	cling.press(Vector2i(5, 5))
	assert_eq(cling.press(Vector2i(8, 8)), "release")
	assert_false(cling.is_holding())
	assert_eq(field.get_emitter("c0").cell, Vector2i(8, 8))
	assert_almost_eq(field.get_emitter("c0").intensity, 0.85, 0.001)


func test_a_brazier_cannot_be_lifted_only_smothered() -> void:
	var setup := _setup([_brazier("b0", Vector2i(5, 5))])
	var field: LightField = setup[0]
	var cling: ClingController = setup[1]
	assert_eq(cling.press(Vector2i(6, 5)), "smother")
	assert_false(cling.is_holding())
	cling.tick(0.6, Vector2i(6, 5), true)
	assert_almost_eq(cling.smother_fraction(), 0.5, 0.05)
	assert_false(cling.is_snuffed("b0"), "half-smothered is still lit")
	cling.tick(0.7, Vector2i(6, 5), true)
	assert_true(cling.is_snuffed("b0"))
	assert_eq(field.level_at(Vector2i(5, 5)), 0.0, "the room goes dark")


func test_letting_go_abandons_the_smother() -> void:
	var setup := _setup([_brazier("b0", Vector2i(5, 5))])
	var cling: ClingController = setup[1]
	cling.press(Vector2i(6, 5))
	cling.tick(0.6, Vector2i(6, 5), true)
	cling.tick(0.1, Vector2i(6, 5), false)
	assert_eq(cling.smother_fraction(), 0.0, "progress is not banked")
	assert_false(cling.is_snuffed("b0"))


func test_walking_away_abandons_the_smother() -> void:
	var setup := _setup([_brazier("b0", Vector2i(5, 5))])
	var cling: ClingController = setup[1]
	cling.press(Vector2i(6, 5))
	cling.tick(0.6, Vector2i(6, 5), true)
	cling.tick(0.1, Vector2i(15, 5), true)
	assert_eq(cling.smother_fraction(), 0.0)


func test_snuffed_lights_are_out_of_reach_until_relit() -> void:
	var setup := _setup([_candle("c0", Vector2i(5, 5))])
	var cling: ClingController = setup[1]
	cling.snuff("c0")
	assert_eq(cling.target_near(Vector2i(5, 5)), "", "you cannot grab a dead candle")
	assert_eq(cling.snuffed_ids(), ["c0"] as Array[String])
	assert_true(cling.relight("c0"))
	assert_eq(cling.target_near(Vector2i(5, 5)), "c0")


func test_relighting_restores_the_original_brightness() -> void:
	var setup := _setup([_candle("c0", Vector2i(5, 5))])
	var field: LightField = setup[0]
	var cling: ClingController = setup[1]
	cling.press(Vector2i(5, 5))  # dims it to carry intensity
	cling.snuff("c0")
	cling.relight("c0")
	assert_almost_eq(field.get_emitter("c0").intensity, 0.85, 0.001)


func test_pressing_with_nothing_in_reach_does_nothing() -> void:
	var setup := _setup([_candle("c0", Vector2i(1, 1))])
	var cling: ClingController = setup[1]
	assert_eq(cling.press(Vector2i(18, 18)), "")


func test_the_live_chamber_wires_cling_to_its_lights() -> void:
	var game: Node2D = GAME.instantiate()
	add_child_autofree(game)
	var chamber: Chamber = game.get_node("Chamber")
	assert_not_null(chamber.cling)
	var candle_id := ""
	var candle_cell := Vector2i.ZERO
	for light in chamber.data.lights:
		if light["kind"] == "candle":
			candle_id = light["id"]
			candle_cell = light["cell"]
			break
	assert_ne(candle_id, "", "the Cistern has candles to lift")
	assert_eq(chamber.cling.press(candle_cell), "grab")
	chamber.cling.tick(0.1, candle_cell + Vector2i(0, 1), true)
	assert_eq(chamber.field.get_emitter(candle_id).cell, candle_cell + Vector2i(0, 1))
