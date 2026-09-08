extends GutTest

const GAME := preload("res://scenes/Game.tscn")


func _chamber() -> Chamber:
	var game: Node2D = GAME.instantiate()
	add_child_autofree(game)
	return game.get_node("Chamber")


func test_the_chamber_has_a_renderer_behind_everything() -> void:
	var chamber := _chamber()
	assert_not_null(chamber.renderer)
	assert_lt(chamber.renderer.z_index, 0, "Umbra is a hole in the light, not under it")


func test_the_renderer_covers_exactly_the_room() -> void:
	var chamber := _chamber()
	var bounds := chamber.data.bounds_rect()
	assert_eq(chamber.renderer.scale, bounds.size)
	assert_eq(chamber.renderer.position, bounds.position)


func test_the_light_texture_matches_the_simulation() -> void:
	var chamber := _chamber()
	var image: Image = chamber.renderer._image
	assert_eq(image.get_width(), chamber.data.width)
	assert_eq(image.get_height(), chamber.data.height)
	var lamp: Vector2i = chamber.data.lights[0]["cell"]
	assert_almost_eq(image.get_pixelv(lamp).r, chamber.field.level_at(lamp), 0.01)
	var wall := Vector2i(0, 0)
	assert_eq(image.get_pixelv(wall).g, 1.0, "walls are flagged for the shader")


func test_snuffing_a_light_shows_up_in_the_texture() -> void:
	var chamber := _chamber()
	var brazier_id := ""
	var brazier_cell := Vector2i.ZERO
	for light in chamber.data.lights:
		if light["kind"] == "brazier":
			brazier_id = light["id"]
			brazier_cell = light["cell"]
			break
	assert_ne(brazier_id, "", "the Cistern has a brazier")
	assert_gt(chamber.renderer._image.get_pixelv(brazier_cell).r, 0.5)
	chamber.cling.snuff(brazier_id)
	chamber.renderer.refresh()
	assert_eq(chamber.renderer._image.get_pixelv(brazier_cell).r, 0.0, "the picture follows the sim")


func test_dread_rises_only_as_she_burns_away() -> void:
	var state := ShadowState.new()
	assert_eq(ChamberRenderer.dread_for(state), 0.0, "whole is calm")
	state.coherence = ShadowState.MAX_COHERENCE * 0.3
	assert_gt(ChamberRenderer.dread_for(state), 0.0)
	state.scatter()
	assert_eq(ChamberRenderer.dread_for(state), 1.0)
	assert_eq(ChamberRenderer.dread_for(null), 0.0)


func test_the_blot_never_settles() -> void:
	var a := UmbraBlot.silhouette(0.0, 1.0, 6.0, 1.0)
	var b := UmbraBlot.silhouette(0.4, 1.0, 6.0, 1.0)
	assert_eq(a.size(), UmbraBlot.POINTS)
	assert_ne(a[0], b[0], "the silhouette keeps churning")


func test_the_blot_stays_roughly_her_size() -> void:
	for step in 20:
		for point in UmbraBlot.silhouette(float(step) * 0.3, 2.0, 6.0, 1.0):
			assert_between(point.length(), 3.5, 9.0)


func test_the_blot_reads_her_condition() -> void:
	var chamber := _chamber()
	var lamp: Vector2i = chamber.data.lights[0]["cell"]
	chamber.umbra.global_position = chamber.data.cell_to_world(lamp)
	chamber.umbra._sync_blot()
	assert_gt(chamber.umbra.blot.glare, 0.5, "the body knows before the meter says so")
