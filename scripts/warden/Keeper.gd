class_name Keeper
extends Node2D

## The Lantern Keeper. Not a boss in the usual sense — there is nothing to hit
## and nothing that hits you. He simply walks toward her, slowly, forever,
## carrying the last portable flame in the Observatory.
##
## He is a deadline with a lantern. You cannot beat him; you can only finish
## before he arrives, and every second spent smothering is a second he closes.

signal reached_her

const SPEED := 1.35  ## cells per second — always slower than she is
const LANTERN_RADIUS := 7.0
const TOUCH_DISTANCE := 0.8

var id: String = "keeper"
var field: LightField
var cell_size: int = ChamberData.CELL_SIZE

var _cell_position: Vector2 = Vector2.ZERO
var _target: Vector2 = Vector2.ZERO
var _time: float = 0.0


func setup(p_field: LightField, start_cell: Vector2i) -> void:
	field = p_field
	_cell_position = Vector2(start_cell)
	_target = _cell_position
	field.emit("%s_lantern" % id, start_cell, LANTERN_RADIUS, 1.0)
	_sync()


func lantern_id() -> String:
	return "%s_lantern" % id


func current_cell() -> Vector2i:
	return Vector2i(roundi(_cell_position.x), roundi(_cell_position.y))


func follow(cell: Vector2i) -> void:
	_target = Vector2(cell)


func _physics_process(delta: float) -> void:
	if field == null:
		return
	_time += delta
	var to := _target - _cell_position
	if to.length() > TOUCH_DISTANCE:
		# He never runs and never stops. Walls do not stop him either: he keeps
		# the keys to this place.
		_cell_position += to.normalized() * SPEED * delta
	elif to.length() <= TOUCH_DISTANCE:
		reached_her.emit()
	field.move_emitter(lantern_id(), current_cell())
	_sync()


func _sync() -> void:
	position = _cell_position * float(cell_size) + Vector2.ONE * (cell_size * 0.5)
	queue_redraw()


func _draw() -> void:
	var sway := sin(_time * 1.6) * 1.5
	draw_colored_polygon(
		PackedVector2Array([Vector2(-6, 8), Vector2(-4, -9), Vector2(4, -9), Vector2(6, 8)]),
		Color(0.11, 0.10, 0.13)
	)
	draw_circle(Vector2(0, -11), 3.5, Color(0.18, 0.17, 0.20))
	var lantern := Vector2(8 + sway, 0)
	draw_circle(lantern, 6.0, Color(1.0, 0.88, 0.6, 0.22))
	draw_circle(lantern, 2.6, Color(1.0, 0.95, 0.78))
