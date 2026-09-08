class_name Sound
extends Node

## Every sound in PENUMBRA is generated at runtime. There is not one audio file
## in the repository, which keeps the web build tiny and means the palette can
## be tuned in a diff rather than in a DAW.
##
## The vocabulary is deliberately small and all of it is breath and glass:
## a soft thud when she throws ink, a hiss when she comes apart, a puff when a
## flame dies, and a low tone under a whisper.

const SAMPLE_RATE := 22050

enum Voice { CAST, SCATTER, REFORM, SNUFF, WHISPER, TURN }

var _players: Array[AudioStreamPlayer] = []
var _streams: Dictionary = {}
var _next_player: int = 0
var volume_scale: float = 1.0


func _ready() -> void:
	for i in 6:
		var player := AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		_players.append(player)
	for voice in Voice.values():
		_streams[voice] = build(voice)


func play(voice: int, volume_db: float = -6.0) -> void:
	if not _streams.has(voice) or _players.is_empty():
		return
	var player := _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	player.stream = _streams[voice]
	if volume_scale <= 0.001:
		return
	player.volume_db = volume_db + linear_to_db(clampf(volume_scale, 0.001, 1.0))
	player.play()


## Each voice is a short envelope over a shaped oscillator plus noise. Kept
## static and pure so the waveform itself can be asserted in a test.
static func build(voice: int) -> AudioStreamWAV:
	match voice:
		Voice.CAST:
			return _render(0.22, 150.0, 60.0, 0.35, 3.0)
		Voice.SCATTER:
			return _render(0.75, 320.0, 70.0, 0.85, 1.4)
		Voice.REFORM:
			return _render(0.45, 90.0, 220.0, 0.20, 2.2)
		Voice.SNUFF:
			return _render(0.30, 700.0, 120.0, 0.90, 4.5)
		Voice.WHISPER:
			return _render(0.90, 210.0, 190.0, 0.12, 1.1)
		Voice.TURN:
			return _render(0.18, 900.0, 1250.0, 0.10, 5.0)
	return _render(0.2, 220.0, 220.0, 0.2, 3.0)


## `noise_mix` 0..1 blends breath over the tone; `decay` shapes the fall-off.
static func _render(
	seconds: float,
	start_hz: float,
	end_hz: float,
	noise_mix: float,
	decay: float
) -> AudioStreamWAV:
	var count := int(SAMPLE_RATE * seconds)
	var data := PackedByteArray()
	data.resize(count * 2)
	var phase := 0.0
	var noise := RandomNumberGenerator.new()
	noise.seed = int(start_hz * 1000.0 + end_hz)
	for i in count:
		var t := float(i) / float(count)
		var hz: float = lerpf(start_hz, end_hz, t)
		phase += TAU * hz / float(SAMPLE_RATE)
		var tone := sin(phase)
		var breath := noise.randf_range(-1.0, 1.0)
		var envelope := exp(-decay * t) * minf(1.0, t * 40.0)
		var sample: float = lerpf(tone, breath, noise_mix) * envelope * 0.7
		var value := int(clampf(sample, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, value)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	return stream


## Peak amplitude of a rendered voice, for tests and for balancing by ear.
static func peak(stream: AudioStreamWAV) -> float:
	var highest := 0.0
	var samples := stream.data.size() / 2
	for i in samples:
		highest = maxf(highest, absf(float(stream.data.decode_s16(i * 2)) / 32767.0))
	return highest
