class_name Lamplighter
extends Node2D

## A Warden relights what you put out. The Lamplighter is worse: they walk their
## round setting *new* candles, and a room they have finished with is a room
## that has changed shape.
##
## Wardens make your darkness temporary. The Lamplighter makes the map itself
## get worse the longer you take, which turns hesitation into a cost without
## ever threatening her directly.

signal lit(id: String, cell: Vector2i)

const INTERVAL := 6.0  ## seconds between candles
const CANDLE_RADIUS := 4.0
const CANDLE_INTENSITY := 0.85
const LANTERN_RADIUS := 5.0

var id: String = "lamplighter"
var route: PatrolRoute
var field: LightField
var cling: ClingController
var cell_size: int = ChamberData.CELL_SIZE
var placed: Array[String] = []

var _timer: float = INTERVAL
var _cell_position: Vector2 = Vector2.ZERO
var _count: int = 0


func setup(
	p_id: String, p_route: PatrolRoute, p_field: LightField, p_cling: ClingController
) -> void:
	id = p_id
	route = p_route
	field = p_field
	cling = p_cling
	_cell_position = route.position()
	field.emit(lantern_id(), current_cell(), LANTERN_RADIUS, 1.0)
	_sync()


func lantern_id() -> String:
	return "%s_lantern" % id


func current_cell() -> Vector2i:
	return Vector2i(roundi(_cell_position.x), roundi(_cell_position.y))


func _physics_process(delta: float) -> void:
	if field == null:
		return
	route.advance(delta)
	_cell_position = route.position()
	field.move_emitter(lantern_id(), current_cell())
	_sync()

	_timer -= delta
	if _timer <= 0.0:
		_timer = INTERVAL
		place_candle()


## The candles are ordinary candles: liftable, snuffable, and left behind. What
## the player does about them is the whole point.
func place_candle() -> String:
	var cell := current_cell()
	if field.has_mirror(cell) or _occupied(cell):
		return ""
	var candle_id := "%s_candle_%d" % [id, _count]
	_count += 1
	field.emit(candle_id, cell, CANDLE_RADIUS, CANDLE_INTENSITY)
	if cling != null:
		cling.register(
			{
				"id": candle_id,
				"kind": "candle",
				"cell": cell,
				"radius": CANDLE_RADIUS,
				"intensity": CANDLE_INTENSITY,
			}
		)
	placed.append(candle_id)
	lit.emit(candle_id, cell)
	return candle_id


func _occupied(cell: Vector2i) -> bool:
	for emitter in field.emitters():
		if emitter.id != lantern_id() and emitter.cell == cell:
			return true
	return false


func _sync() -> void:
	position = _cell_position * float(cell_size) + Vector2.ONE * (cell_size * 0.5)
	queue_redraw()


func _draw() -> void:
	draw_colored_polygon(
		PackedVector2Array([Vector2(-4, 7), Vector2(-3, -7), Vector2(3, -7), Vector2(4, 7)]),
		Color(0.19, 0.15, 0.10)
	)
	draw_circle(Vector2(0, -10), 3.0, Color(0.24, 0.20, 0.16))
	# The long pole, and the flame on the end of it.
	draw_line(Vector2(3, -2), Vector2(11, -12), Color(0.35, 0.28, 0.20), 1.5)
	draw_circle(Vector2(11, -12), 3.5, Color(1.0, 0.85, 0.5, 0.35))
	draw_circle(Vector2(11, -12), 1.6, Color(1.0, 0.95, 0.8))
