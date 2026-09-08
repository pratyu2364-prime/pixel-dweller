class_name Umbra
extends CharacterBody2D

## The player: a shadow come loose from its owner.
##
## The body is thin on purpose — it moves, samples the LightField under itself,
## and hands that reading to ShadowState. Every rule lives in ShadowState and
## LightField; this node only translates them into motion and signals.

signal scattered_at(cell: Vector2i)
signal reformed_at(cell: Vector2i)
signal cast_requested(cell: Vector2i)
signal cling_pressed(cell: Vector2i)
signal cling_released

const BASE_SPEED := 92.0
const ACCELERATION := 900.0
const FRICTION := 1100.0
const CELL_SIZE := 16

var state: ShadowState = ShadowState.new()
var field: LightField = null
var cell_size: int = CELL_SIZE
var input_enabled: bool = true

var _reform_timer: float = 0.0

const REFORM_DELAY := 0.8  ## the beat of being scattered, before you snap back


@onready var blot: UmbraBlot = $Blot


func _ready() -> void:
	state.scattered.connect(_on_scattered)


## Chambers call this after building their LightField.
func bind_field(p_field: LightField, p_cell_size: int = CELL_SIZE) -> void:
	field = p_field
	cell_size = maxi(p_cell_size, 1)


func current_cell() -> Vector2i:
	return Vector2i(floori(global_position.x / cell_size), floori(global_position.y / cell_size))


func cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell * cell_size) + Vector2.ONE * (cell_size * 0.5)


func glare() -> float:
	if field == null:
		return 0.0
	return field.glare_at(current_cell())


func in_deep_shade() -> bool:
	return field != null and field.is_deep_shade(current_cell())


func _physics_process(delta: float) -> void:
	if state.is_scattered:
		_tick_scattered(delta)
		return

	state.tick(delta, glare(), in_deep_shade())
	_apply_motion(delta, _read_input())
	_sync_blot()


func _read_input() -> Vector2:
	if not input_enabled:
		return Vector2.ZERO
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")


func is_clinging() -> bool:
	return input_enabled and Input.is_action_pressed("cling")


func _apply_motion(delta: float, direction: Vector2) -> void:
	var target := direction * BASE_SPEED * state.speed_multiplier(glare())
	if direction == Vector2.ZERO:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
	else:
		velocity = velocity.move_toward(target, ACCELERATION * delta)
	move_and_slide()


func _sync_blot() -> void:
	if blot != null:
		blot.set_condition(glare(), state.fraction(), state.is_scattered)


func _tick_scattered(delta: float) -> void:
	velocity = Vector2.ZERO
	_sync_blot()
	_reform_timer -= delta
	if _reform_timer <= 0.0:
		reform()


func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled or state.is_scattered:
		return
	if event.is_action_pressed("cast"):
		try_cast()
	elif event.is_action_pressed("cling"):
		cling_pressed.emit(current_cell())
	elif event.is_action_released("cling"):
		cling_released.emit()


## Casting is announced, not resolved here: the chamber owns the LightField and
## decides where the puff actually lands.
func try_cast() -> bool:
	if not state.can_cast():
		return false
	if not state.spend_ink():
		return false
	cast_requested.emit(current_cell())
	return true


func _on_scattered() -> void:
	velocity = Vector2.ZERO
	_reform_timer = REFORM_DELAY
	scattered_at.emit(current_cell())


func reform() -> void:
	var target := current_cell()
	if field != null:
		target = field.nearest_shade(target)
		global_position = cell_to_world(target)
	state.reform()
	reformed_at.emit(target)
