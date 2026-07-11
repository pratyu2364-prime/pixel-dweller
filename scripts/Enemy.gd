class_name Enemy
extends CharacterBody2D

## Cute monster: wanders, chases the player when close, bonks on contact,
## takes sword hits, poofs on defeat. Sheet layout matches characters:
## 4x4 grid, columns = facing (down/up/left/right), rows = walk frames.

signal defeated(enemy: Enemy)

enum State { WANDER, CHASE, HURT }

const ANIM_FPS := 6.0
const HURT_TIME := 0.2
const KNOCKBACK_SPEED := 120.0
const WANDER_PERIOD := 1.6

@export var max_hp: int = 3
@export var damage: int = 1
@export var wander_speed: float = 20.0
@export var chase_speed: float = 45.0
@export var chase_radius: float = 96.0
@export var xp_value: int = 5
@export var coin_value: int = 2

var hp: int
var _state: State = State.WANDER
var _wander_dir: Vector2 = Vector2.DOWN
var _wander_t: float = 0.0
var _hurt_t: float = 0.0
var _knockback: Vector2 = Vector2.ZERO
var _anim_t: float = 0.0
var _touching_player: Node2D = null

@onready var sprite: Sprite2D = $Sprite
@onready var hurtbox: Area2D = $Hurtbox


## Pure: which state given distance to player. Unit-testable.
static func next_state(dist: float, radius: float, hurt_time_left: float) -> State:
	if hurt_time_left > 0.0:
		return State.HURT
	return State.CHASE if dist <= radius else State.WANDER


## Pure: velocity for a state. Unit-testable.
static func velocity_for(
	state: State, to_player: Vector2, wander_dir: Vector2,
	wander_spd: float, chase_spd: float, knockback: Vector2
) -> Vector2:
	match state:
		State.HURT:
			return knockback
		State.CHASE:
			return to_player.normalized() * chase_spd if to_player.length() > 4.0 else Vector2.ZERO
		_:
			return wander_dir * wander_spd


func _ready() -> void:
	hp = max_hp
	hurtbox.body_entered.connect(_on_touch)
	hurtbox.body_exited.connect(_on_untouch)


func take_hit(amount: int, from_pos: Vector2) -> void:
	hp -= amount
	_hurt_t = HURT_TIME
	_knockback = (global_position - from_pos).normalized() * KNOCKBACK_SPEED
	sprite.modulate = Color(1, 0.5, 0.5)
	if hp <= 0:
		_die()


func _die() -> void:
	defeated.emit(self)
	# Poof: quick shrink, then gone. Kid-friendly, no gore.
	var tween := create_tween()
	hurtbox.set_deferred("monitoring", false)
	collision_layer = 0
	tween.tween_property(self, "scale", Vector2(0.05, 0.05), 0.15)
	tween.tween_callback(queue_free)


func _physics_process(delta: float) -> void:
	if _hurt_t > 0.0:
		_hurt_t -= delta
		if _hurt_t <= 0.0:
			sprite.modulate = Color.WHITE
	else:
		_wander_t -= delta
		if _wander_t <= 0.0:
			_wander_t = WANDER_PERIOD
			_wander_dir = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT, Vector2.ZERO].pick_random()

	var player := get_tree().get_first_node_in_group("player") as Node2D
	var to_player := Vector2.ZERO
	var dist := INF
	if player != null:
		to_player = player.global_position - global_position
		dist = to_player.length()

	_state = next_state(dist, chase_radius, _hurt_t)
	velocity = velocity_for(_state, to_player, _wander_dir, wander_speed, chase_speed, _knockback)
	move_and_slide()

	if _touching_player != null and _touching_player.has_method("hurt"):
		_touching_player.hurt(damage)

	_animate(delta)


func _on_touch(body: Node) -> void:
	if body.is_in_group("player"):
		_touching_player = body as Node2D


func _on_untouch(body: Node) -> void:
	if body == _touching_player:
		_touching_player = null


func _animate(delta: float) -> void:
	var col := 0
	if absf(velocity.x) > absf(velocity.y):
		col = 3 if velocity.x > 0.0 else 2
	elif velocity.y < 0.0:
		col = 1
	if velocity.length_squared() > 1.0:
		_anim_t += delta * ANIM_FPS
	sprite.frame_coords = Vector2i(col, int(_anim_t) % 4)
