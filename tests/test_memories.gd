extends GutTest

## Memories are the only progression in the game, and they are optional, so
## they have to be worth the risk and impossible to farm twice.

const TEST_PATH := "user://test_memories.json"


func after_each() -> void:
	Progress.clear(TEST_PATH)


func _room(id: String, progress: Progress) -> Chamber:
	var chamber := Chamber.new()
	chamber.chamber_path = Game.path_for(id)
	add_child_autofree(chamber)
	chamber.progress = progress
	chamber.apply_boons()
	return chamber


func test_every_floor_hides_one_and_says_something_with_it() -> void:
	for id in Game.DEFAULT_ORDER:
		var data := ChamberData.from_file(Game.path_for(id))
		assert_eq(data.memories.size(), 1, "%s should hide exactly one memory" % id)
		assert_gt(String(data.memories[0]["text"]).length(), 12, "%s: a memory must speak" % id)


func test_they_sit_in_the_light_with_shade_one_step_away() -> void:
	for id in Game.DEFAULT_ORDER:
		var data := ChamberData.from_file(Game.path_for(id))
		var field := data.build_field()
		var cell: Vector2i = data.memories[0]["cell"]
		assert_true(field.is_glare(cell), "%s: a memory you can stand on is not a choice" % id)
		assert_true(data.reachable_floor().has(cell), "%s: unreachable memory" % id)
		var escape := false
		for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			escape = escape or (not data.is_wall(cell + offset) and field.is_shade(cell + offset))
		assert_true(escape, "%s: a memory with no way back out is a trap" % id)


func test_a_memory_line_without_a_glyph_is_an_error() -> void:
	var text := "id: x\nmemory: at=(2,1) nothing is here\n\n#####\n#@..#\n#####"
	assert_false(ChamberData.from_text(text).is_valid())


func test_a_glyph_without_a_line_is_an_error() -> void:
	assert_false(ChamberData.from_text("id: x\n\n#####\n#@.*#\n#####").is_valid())


func test_taking_one_is_permanent_and_pays_out() -> void:
	var progress := Progress.new()
	var room := _room("cistern", progress)
	var cell: Vector2i = room.data.memories[0]["cell"]
	watch_signals(room)
	room.umbra.global_position = room.data.cell_to_world(cell)
	room._process(0.016)
	assert_signal_emitted(room, "memory_found")
	assert_eq(progress.memories.size(), 1)
	assert_gt(room.umbra.state.max_coherence(), ShadowState.MAX_COHERENCE, "she bears more light")
	room._process(0.016)
	assert_eq(progress.memories.size(), 1, "and it cannot be taken twice")


func test_a_found_memory_stays_found_across_a_restart() -> void:
	var progress := Progress.new()
	var first := _room("cistern", progress)
	first.umbra.global_position = first.data.cell_to_world(first.data.memories[0]["cell"])
	first._process(0.016)
	var again := _room("cistern", progress)
	watch_signals(again)
	again.umbra.global_position = again.data.cell_to_world(again.data.memories[0]["cell"])
	again._process(0.016)
	assert_signal_emit_count(again, "memory_found", 0)


func test_boons_grow_with_what_she_remembers() -> void:
	var progress := Progress.new()
	assert_eq(progress.boons()["coherence"], 0.0)
	progress.remember(Progress.memory_id("cistern", Vector2i(1, 1)))
	assert_almost_eq(progress.boons()["coherence"], Progress.COHERENCE_PER_MEMORY, 0.01)
	assert_eq(progress.boons()["ink"], 0.0, "one memory is not yet a charge")
	progress.remember(Progress.memory_id("orrery", Vector2i(2, 2)))
	assert_almost_eq(progress.boons()["ink"], 1.0, 0.01, "two are")


func test_memories_survive_being_saved_and_loaded() -> void:
	var progress := Progress.new()
	progress.remember(Progress.memory_id("cistern", Vector2i(36, 2)))
	progress.save(TEST_PATH)
	var loaded := Progress.load_from(TEST_PATH)
	assert_true(loaded.has_memory(Progress.memory_id("cistern", Vector2i(36, 2))))


func test_the_ceiling_moves_but_the_meter_still_reads_full() -> void:
	var state := ShadowState.new()
	state.grant(24.0, 1.0)
	assert_almost_eq(state.max_coherence(), ShadowState.MAX_COHERENCE + 24.0, 0.01)
	assert_almost_eq(state.fraction(), 1.0, 0.01)
	assert_eq(state.ink_charges(), 4)
