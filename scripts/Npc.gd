class_name Npc
extends Area2D

signal greeted(text: String, mood_boost: float)
signal range_changed(in_range: bool, npc: Npc)

const MOOD_BOOST := 10.0
const GREET_COOLDOWN := 30.0

@export var greeting: String = "Hey there! Nice day for a walk!"

var _last_boost_time: float = -INF
var _player_in_range: bool = false


## Pure deterministic greet. Unit-testable: inject `now` (unix timestamp).
## Returns {"text": greeting, "mood_boost": <float>}.
## Mood boost granted only if cooldown elapsed (or first-ever greet).
func greet(now: float) -> Dictionary:
	var boost := 0.0
	if _last_boost_time < 0.0 or (now - _last_boost_time) >= GREET_COOLDOWN:
		boost = MOOD_BOOST
		_last_boost_time = now
	return {"text": greeting, "mood_boost": boost}


## Runtime wrapper: reads real clock, emits greeted signal.
func try_greet() -> void:
	var now := Time.get_unix_time_from_system()
	var result := greet(now)
	greeted.emit(result.text, result.mood_boost)


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
	if _player_in_range and Input.is_action_just_pressed("interact"):
		try_greet()


func _on_body_entered(body: Node) -> void:
	if body is CharacterBody2D:
		_player_in_range = true
		range_changed.emit(true, self)


func _on_body_exited(body: Node) -> void:
	if body is CharacterBody2D:
		_player_in_range = false
		range_changed.emit(false, self)
