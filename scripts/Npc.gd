class_name Npc
extends Area2D

signal greeted(text: String, mood_boost: float)
signal range_changed(in_range: bool, npc: Npc)

const MOOD_BOOST := 10.0
const GREET_COOLDOWN := 30.0
const IDLE_FPS := 2.0

## Same sheet layout as Player.gd: columns are facing (down/up/left/right).
const COL_DOWN := 0
const COL_UP := 1
const COL_LEFT := 2
const COL_RIGHT := 3

@export var greeting: String = "Hey there! Nice day for a walk!"
@export var sprite_texture: Texture2D

var _last_boost_time: float = -INF
var _player_in_range: bool = false
var _facing_col: int = COL_DOWN
var _idle_t: float = 0.0

@onready var sprite: Sprite2D = get_node_or_null("Sprite")


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


## Pure: which sheet column faces from `npc_pos` toward `target`. Unit-testable.
static func facing_toward(npc_pos: Vector2, target: Vector2) -> int:
	var diff := target - npc_pos
	if absf(diff.x) > absf(diff.y):
		return COL_RIGHT if diff.x > 0.0 else COL_LEFT
	return COL_DOWN if diff.y > 0.0 else COL_UP


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if sprite != null and sprite_texture != null:
		sprite.texture = sprite_texture


func _process(delta: float) -> void:
	if _player_in_range and Input.is_action_just_pressed("interact"):
		try_greet()
	if sprite != null:
		_idle_t += delta * IDLE_FPS
		sprite.frame_coords = Vector2i(_facing_col, int(_idle_t) % 2)


func _on_body_entered(body: Node) -> void:
	if body is CharacterBody2D:
		_player_in_range = true
		_facing_col = facing_toward(global_position, (body as Node2D).global_position)
		range_changed.emit(true, self)


func _on_body_exited(body: Node) -> void:
	if body is CharacterBody2D:
		_player_in_range = false
		range_changed.emit(false, self)
