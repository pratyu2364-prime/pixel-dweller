extends CharacterBody2D

@export var speed: float = 70.0

## Ninja Adventure sprite sheet layout (sprite.png 64x112, 16x16 frames):
## columns = direction, rows = animation frame. Walk cycle = rows 0..3.
const COL_DOWN := 0
const COL_UP := 1
const COL_LEFT := 2
const COL_RIGHT := 3
const WALK_ROWS := [0, 1, 2, 3]
const ANIM_FPS := 8.0

var _facing_col: int = COL_DOWN
var _anim_t: float = 0.0

@onready var sprite: Sprite2D = $Sprite


## Pure function: raw input vector -> normalized direction. Unit-testable.
static func input_to_direction(input_vec: Vector2) -> Vector2:
	if input_vec.length_squared() == 0.0:
		return Vector2.ZERO
	return input_vec.normalized()


func _physics_process(delta: float) -> void:
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
