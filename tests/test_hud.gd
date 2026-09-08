extends GutTest

const HUD := preload("res://scenes/Hud.tscn")
const GAME := preload("res://scenes/Game.tscn")


func test_binds_and_reads_state() -> void:
	var hud: Hud = HUD.instantiate()
	add_child_autofree(hud)
	var state := ShadowState.new()
	hud.bind(state)
	assert_eq(hud.state, state)


func test_coherence_colour_warns_before_it_kills() -> void:
	var whole := Hud.coherence_color(1.0)
	var half := Hud.coherence_color(0.5)
	var dying := Hud.coherence_color(0.0)
	assert_gt(whole.b, whole.r, "whole reads cold")
	assert_gt(dying.r, dying.b, "dying reads hot")
	assert_gt(half.r, whole.r, "the warning starts before the end")


func test_hint_is_hidden_when_empty() -> void:
	var hud: Hud = HUD.instantiate()
	add_child_autofree(hud)
	hud.set_hint("cling to lift the candle")
	assert_true(hud.get_node("Canvas/Hint").visible)
	hud.set_hint("")
	assert_false(hud.get_node("Canvas/Hint").visible)


func test_the_chamber_hint_names_what_you_can_do() -> void:
	var game: Node2D = GAME.instantiate()
	add_child_autofree(game)
	var chamber: Chamber = game.get_node("Chamber")
	var candle_cell := Vector2i.ZERO
	for light in chamber.data.lights:
		if light["kind"] == "candle":
			candle_cell = light["cell"]
			break
	chamber.umbra.global_position = chamber.data.cell_to_world(candle_cell + Vector2i(1, 0))
	chamber._update_hud()
	assert_string_contains(chamber.hud.hint, "lift")
	chamber.cling.press(chamber.umbra.current_cell())
	chamber._update_hud()
	assert_string_contains(chamber.hud.hint, "carrying")


func test_the_hud_tracks_glare_under_her() -> void:
	var game: Node2D = GAME.instantiate()
	add_child_autofree(game)
	var chamber: Chamber = game.get_node("Chamber")
	var lamp: Vector2i = chamber.data.lights[0]["cell"]
	chamber.umbra.global_position = chamber.data.cell_to_world(lamp)
	chamber._update_hud()
	assert_gt(chamber.hud.glare, 0.5)
