extends CharacterBody2D

@export var speed: float = 100.0

## Pure function: maps raw input vector (from keyboard or touch) to
## normalized movement direction. Unit-testable without a running scene.
static func input_to_direction(input_vec: Vector2) -> Vector2:
	if input_vec.length_squared() == 0.0:
		return Vector2.ZERO
	return input_vec.normalized()


func _ready() -> void:
	var sf := SpriteFrames.new()
	sf.add_animation("idle")
	sf.add_animation("walk")
	$AnimatedSprite2D.sprite_frames = sf
	$AnimatedSprite2D.play("idle")


func _physics_process(_delta: float) -> void:
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
	_update_animation(direction)
	move_and_slide()


func _update_animation(direction: Vector2) -> void:
	var anim := $AnimatedSprite2D as AnimatedSprite2D
	if direction == Vector2.ZERO:
		anim.play("idle")
	else:
		anim.play("walk")
		if direction.x != 0.0:
			anim.flip_h = direction.x < 0.0
