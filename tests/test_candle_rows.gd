extends GutTest

## Floor −2 exists to teach Cling, so its tests are about teaching, not layout.

var data: ChamberData


func before_all() -> void:
	data = ChamberData.from_file("res://chambers/candle_rows.txt")


func test_it_parses_and_is_sealed() -> void:
	assert_true(data.is_valid(), str(data.parse_errors))
	for x in data.width:
		assert_true(data.is_wall(Vector2i(x, 0)))
		assert_true(data.is_wall(Vector2i(x, data.height - 1)))
	for y in data.height:
		assert_true(data.is_wall(Vector2i(0, y)))
		assert_true(data.is_wall(Vector2i(data.width - 1, y)))


func test_it_is_completable_and_starts_safe() -> void:
	assert_true(data.exit_is_reachable())
	assert_true(data.build_field().is_deep_shade(data.spawn))


func test_it_is_mostly_candles_because_that_is_the_lesson() -> void:
	var candles := 0
	var fixed := 0
	for light in data.lights:
		if light["kind"] == "candle":
			candles += 1
		else:
			fixed += 1
	assert_gt(candles, fixed, "the floor that teaches lifting is full of liftable light")
	assert_gt(fixed, 0, "and a few you cannot lift, to teach the other half")


func test_the_room_teaches_before_it_tests() -> void:
	assert_gt(data.whispers.size(), 2)
	var first: Dictionary = data.whispers[0]
	assert_lt(Vector2(first["cell"] - data.spawn).length(), 6.0, "the first line lands at the door")


func test_whispers_parse_with_their_text_intact() -> void:
	var text := "id: x\nwhisper: at=(3,2) radius=4 the light does not like you\n\n#####\n#@..#\n#####"
	var parsed := ChamberData.from_text(text)
	assert_true(parsed.is_valid(), str(parsed.parse_errors))
	assert_eq(parsed.whispers[0]["cell"], Vector2i(3, 2))
	assert_almost_eq(float(parsed.whispers[0]["radius"]), 4.0, 0.001)
	assert_eq(parsed.whispers[0]["text"], "the light does not like you")


func test_a_silent_whisper_is_an_error() -> void:
	assert_false(ChamberData.from_text("id: x\nwhisper: at=(1,1)\n\n###\n#@#\n###").is_valid())


func test_a_whisper_lands_once_when_she_comes_close() -> void:
	var chamber := Chamber.new()
	chamber.chamber_path = "res://chambers/candle_rows.txt"
	add_child_autofree(chamber)
	var whisper: Dictionary = chamber.data.whispers[1]
	chamber.umbra.global_position = chamber.data.cell_to_world(whisper["cell"])
	chamber._process(0.016)
	assert_eq(chamber.hud.whisper, String(whisper["text"]))
	chamber.hud.say("")
	chamber._process(0.016)
	assert_eq(chamber.hud.whisper, "", "it does not repeat itself")


func test_a_whisper_fades_on_its_own() -> void:
	var hud: Hud = load("res://scenes/Hud.tscn").instantiate()
	add_child_autofree(hud)
	hud.say("the dark still fits you")
	hud._process(0.5)
	assert_gt(hud.get_node("Canvas/Whisper").modulate.a, 0.0, "it arrives")
	for step in 60:
		hud._process(0.2)
	assert_eq(hud.whisper, "", "and leaves without being dismissed")


func test_the_cistern_teaches_the_rule_at_the_door() -> void:
	var cistern := ChamberData.from_file("res://chambers/cistern.txt")
	assert_gt(cistern.whispers.size(), 3)
	assert_eq(cistern.next_id, "candle_rows")
