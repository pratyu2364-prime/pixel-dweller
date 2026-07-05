extends CharacterBody2D

## Ninja Adventure sprite sheet layout (sprite.png 64x112, 16x16 frames):
## columns = direction, rows = animation frame. Walk cycle = rows 0..3,
## row 4 = attack pose.
const COL_DOWN := 0
const COL_UP := 1
const COL_LEFT := 2
const COL_RIGHT := 3
const WALK_ROWS := [0, 1, 2, 3]
const ATTACK_ROW := 4
const ANIM_FPS := 8.0
const ATTACK_TIME := 0.25

@export var speed: float = 70.0
## Injected by Main from Stats on spawn; damage dealt per sword hit.
@export var attack_power: int = 1

var _facing_col: int = COL_DOWN
var _anim_t: float = 0.0
var _attack_t: float = 0.0

@onready var sprite: Sprite2D = $Sprite
@onready var sword_area: Area2D = $SwordArea
@onready var sword_sprite: Sprite2D = $SwordSprite


## Pure function: raw input vector -> normalized direction. Unit-testable.
static func input_to_direction(input_vec: Vector2) -> Vector2:
	if input_vec.length_squared() == 0.0:
		return Vector2.ZERO
	return input_vec.normalized()


## Pure: where the sword swing lands relative to the player. Unit-testable.
static func swing_offset(facing_col: int) -> Vector2:
	match facing_col:
		COL_RIGHT:
			return Vector2(18, 0)
		COL_LEFT:
			return Vector2(-18, 0)
		COL_UP:
			return Vector2(0, -18)
		_:
			return Vector2(0, 18)


func is_attacking() -> bool:
	return _attack_t > 0.0


func _ready() -> void:
	sword_area.body_entered.connect(_on_sword_hit)


func _physics_process(delta: float) -> void:
	if is_attacking():
		_attack_t -= delta
		velocity = Vector2.ZERO
		move_and_slide()
		sprite.frame_coords = Vector2i(_facing_col, ATTACK_ROW)
		if not is_attacking():
			_end_attack()
		return

	if Input.is_action_just_pressed("attack"):
		_start_attack()
		return

	var input_dir := Vector2.ZERO
	if Input.is_action_pressed("move_up"):
		input_dir.y -= 1.0
	if Input.is_action_pressed("move_down"):
		input_dir.y += 1.0
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1.0
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1.0

	var direction := input_to_direction(input_dir)
	velocity = direction * speed
	move_and_slide()
	_update_sprite(direction, delta)


func _start_attack() -> void:
	_attack_t = ATTACK_TIME
	var offset := swing_offset(_facing_col)
	sword_area.position = offset
	sword_sprite.position = offset
	sword_sprite.rotation = offset.angle() + PI / 2.0
	sword_sprite.visible = true
	sword_area.monitoring = true


func _end_attack() -> void:
	sword_sprite.visible = false
	sword_area.monitoring = false


func _on_sword_hit(body: Node) -> void:
	if body.has_method("take_hit"):
		body.take_hit(attack_power, global_position)


func _update_sprite(direction: Vector2, delta: float) -> void:
	if direction == Vector2.ZERO:
		_anim_t = 0.0
		sprite.frame_coords = Vector2i(_facing_col, WALK_ROWS[0])
		return

	if absf(direction.x) > absf(direction.y):
		_facing_col = COL_RIGHT if direction.x > 0.0 else COL_LEFT
	else:
		_facing_col = COL_DOWN if direction.y > 0.0 else COL_UP

	_anim_t += delta * ANIM_FPS
	var row: int = WALK_ROWS[int(_anim_t) % WALK_ROWS.size()]
	sprite.frame_coords = Vector2i(_facing_col, row)
