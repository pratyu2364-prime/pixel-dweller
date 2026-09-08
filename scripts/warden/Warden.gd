class_name Warden
extends Node2D

## A keeper of the Observatory's lights. Wardens never attack and never see
## Umbra — a shadow among shadows is invisible to them. What they notice is
## *absence*: a puff of ink where the floor should be lit, or a light that has
## gone out. Then they walk over and fix it.
##
## So the threat is not damage. The threat is that the darkness you made is
## temporary, and something is coming to take it back.

signal noticed(cell: Vector2i)
signal calmed
signal relit_light(id: String)

enum State { PATROL, INVESTIGATE, RELIGHT }

const CONE_RANGE := 6.0
const CONE_HALF_ANGLE := 0.62  ## radians, ~35° either side
const INVESTIGATE_SPEED := 3.2
const ARRIVE_DISTANCE := 0.6
const CALM_SECONDS := 2.0
const SCAN_INTERVAL := 0.25

var id: String = "warden"
var route: PatrolRoute
var field: LightField
var cling: ClingController
var lantern_radius: float = 6.0
var cell_size: int = ChamberData.CELL_SIZE

var state: int = State.PATROL
var target_cell: Vector2i = Vector2i.ZERO
var target_light_id: String = ""

var _cell_position: Vector2 = Vector2.ZERO
var _facing: Vector2 = Vector2.RIGHT
var _scan_timer: float = 0.0
var _calm_timer: float = 0.0
var _lantern_id: String = ""


func setup(
	p_id: String, p_route: PatrolRoute, p_field: LightField, p_cling: ClingController
) -> void:
	id = p_id
	route = p_route
	field = p_field
	cling = p_cling
	_cell_position = route.position()
	_facing = route.facing()
	_lantern_id = "%s_lantern" % id
	field.emit(_lantern_id, current_cell(), lantern_radius, 1.0)
	_sync_position()


func lantern_id() -> String:
	return _lantern_id


func current_cell() -> Vector2i:
	return Vector2i(roundi(_cell_position.x), roundi(_cell_position.y))


func facing() -> Vector2:
	return _facing


func _physics_process(delta: float) -> void:
	if field == null:
		return
	match state:
		State.PATROL:
			_walk_patrol(delta)
		State.INVESTIGATE:
			_walk_to(target_cell, delta)
		State.RELIGHT:
			_walk_to(target_cell, delta)
	field.move_emitter(_lantern_id, current_cell())
	_sync_position()
	_scan(delta)


func _walk_patrol(delta: float) -> void:
	route.advance(delta)
	_cell_position = route.position()
	_facing = route.facing()


func _walk_to(cell: Vector2i, delta: float) -> void:
	var to := Vector2(cell) - _cell_position
	if to.length() <= ARRIVE_DISTANCE:
		_arrive()
		return
	_facing = to.normalized()
	_cell_position += _facing * INVESTIGATE_SPEED * delta


func _arrive() -> void:
	if state == State.RELIGHT and not target_light_id.is_empty():
		if cling != null and cling.relight(target_light_id):
			relit_light.emit(target_light_id)
		target_light_id = ""
	_calm_timer = CALM_SECONDS
	state = State.PATROL
	# Resume the beat from the nearest point on it, so investigating never
	# rewinds a patrol to its start.
	_snap_route_to_here()
	calmed.emit()


func _snap_route_to_here() -> void:
	if route == null or not route.is_valid():
		return
	var best := 0.0
	var best_distance := INF
	var probe := 0.0
	var saved := route.distance_travelled()
	while probe < route.length():
		route.reset()
		route.advance(probe / route.speed)
		var distance := route.position().distance_to(_cell_position)
		if distance < best_distance:
			best_distance = distance
			best = probe
		probe += 0.5
	route.reset()
	route.advance(best / route.speed)
	if not is_finite(best_distance):
		route.advance(saved / route.speed)
	_cell_position = route.position()


func _scan(delta: float) -> void:
	if _calm_timer > 0.0:
		_calm_timer -= delta
		return
	_scan_timer -= delta
	if _scan_timer > 0.0:
		return
	_scan_timer = SCAN_INTERVAL

	var snuffed := _snuffed_in_cone()
	if not snuffed.is_empty():
		target_light_id = snuffed
		target_cell = field.get_emitter(snuffed).cell
		state = State.RELIGHT
		noticed.emit(target_cell)
		return
	var anomaly := _ink_in_cone()
	if anomaly != Vector2i(-1, -1) and state == State.PATROL:
		target_cell = anomaly
		state = State.INVESTIGATE
		noticed.emit(anomaly)


## Cone test in cell space. Range and angle only — walls are handled by the
## light itself, since a Warden cannot notice what they cannot illuminate.
func sees(cell: Vector2i) -> bool:
	var to := Vector2(cell) - _cell_position
	var distance := to.length()
	if distance < 0.001:
		return true
	if distance > CONE_RANGE:
		return false
	return absf(_facing.angle_to(to.normalized())) <= CONE_HALF_ANGLE


func _ink_in_cone() -> Vector2i:
	for puff in field.ink_puffs():
		if sees(puff.cell):
			return puff.cell
	return Vector2i(-1, -1)


func _snuffed_in_cone() -> String:
	if cling == null:
		return ""
	for light_id in cling.snuffed_ids():
		var emitter := field.get_emitter(light_id)
		if emitter != null and sees(emitter.cell):
			return light_id
	return ""


func _sync_position() -> void:
	position = _cell_position * float(cell_size) + Vector2.ONE * (cell_size * 0.5)


# --- look ---------------------------------------------------------------------


func _process(_delta: float) -> void:
	queue_redraw()


## A Warden is the only lit thing in the room, so they are drawn as a warm
## silhouette rather than a shadow: the one shape you can always see coming.
func _draw() -> void:
	var alert := state != State.PATROL
	var robe := Color(0.16, 0.13, 0.11) if not alert else Color(0.24, 0.15, 0.12)
	draw_colored_polygon(
		PackedVector2Array([Vector2(-5, 6), Vector2(-3, -6), Vector2(3, -6), Vector2(5, 6)]), robe
	)
	draw_circle(Vector2(0, -8), 3.0, Color(0.22, 0.19, 0.17))
	var lantern := Vector2(_facing.x * 7.0, 1.0)
	draw_circle(lantern, 4.5, Color(1.0, 0.86, 0.55, 0.30))
	draw_circle(lantern, 2.2, Color(1.0, 0.93, 0.72))
	if alert:
		draw_circle(Vector2(0, -14), 1.6, Color(1.0, 0.55, 0.35))
