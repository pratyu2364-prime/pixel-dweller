extends GutTest

## There is not one audio file in this repository. These tests keep it that way
## and keep the generated voices audible and distinct.


func test_every_voice_renders_audible_audio() -> void:
	for voice in Sound.Voice.values():
		var stream := Sound.build(voice)
		assert_gt(stream.data.size(), 1000, "voice %d is empty" % voice)
		assert_between(Sound.peak(stream), 0.05, 1.0, "voice %d is silent or clipped" % voice)


func test_voices_do_not_all_sound_the_same() -> void:
	var scatter := Sound.build(Sound.Voice.SCATTER)
	var turn := Sound.build(Sound.Voice.TURN)
	assert_gt(scatter.data.size(), turn.data.size(), "coming apart lasts; glass does not")


func test_rendering_is_deterministic() -> void:
	assert_eq(Sound.build(Sound.Voice.CAST).data, Sound.build(Sound.Voice.CAST).data)


func test_the_streams_are_web_safe_mono_pcm() -> void:
	var stream := Sound.build(Sound.Voice.CAST)
	assert_eq(stream.format, AudioStreamWAV.FORMAT_16_BITS)
	assert_false(stream.stereo)
	assert_eq(stream.mix_rate, Sound.SAMPLE_RATE)


func test_a_chamber_brings_its_own_voice() -> void:
	var chamber := Chamber.new()
	chamber.chamber_path = "res://chambers/cistern.txt"
	add_child_autofree(chamber)
	assert_not_null(chamber.sound)
	chamber.umbra.try_cast()
	assert_true(chamber.sound.get_child(0) is AudioStreamPlayer)


func test_the_repository_ships_no_audio_files() -> void:
	var found: Array[String] = []
	var stack: Array[String] = ["res://assets", "res://scenes", "res://scripts"]
	while not stack.is_empty():
		var path: String = stack.pop_back()
		var dir := DirAccess.open(path)
		if dir == null:
			continue
		for entry in dir.get_directories():
			stack.append("%s/%s" % [path, entry])
		for file in dir.get_files():
			if file.get_extension().to_lower() in ["wav", "ogg", "mp3"]:
				found.append("%s/%s" % [path, file])
	assert_eq(found, [] as Array[String], "sound is generated, not shipped")
