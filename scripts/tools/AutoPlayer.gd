class_name AutoPlayer
extends Node

## Walks a proven route with the real body: real acceleration, real collision,
## real light sampling, real coherence drain.
##
## The prover works on an idealised grid. This exists to catch the gap between
## that grid and the game — a corridor the search calls one cell wide that a
## body with a radius cannot actually turn in, a crossing the search times at
## half a second that acceleration makes take one. If the bot cannot finish a
## floor, the floor is not finishable, whatever the proof says.

signal finished(reached_exit: bool)

const ARRIVE := 5.0  ## pixels; a cell is 16
const CAST_GLARE := 0.25  ## throw a puff once the light under her starts to bite

var chamber: Chamber
var route: Array[Vector2i] = []
var index: int = 0
var elapsed: float = 0.0
var lowest_coherence: float = ShadowState.MAX_COHERENCE
var scatters: int = 0
var done: bool = false
var reached_exit: bool = false

## The proof is a route *and* a schedule — on a floor of moving light, arriving
## early is the same mistake as arriving late. The bot never runs ahead of the
## slice it was proved safe in.
var _last_position: Vector2 = Vector2.ZERO
var _stuck_for: float = 0.0


func drive(p_chamber: Chamber, p_route: Array[Vector2i]) -> void:
	chamber = p_chamber
	route = p_route
	index = 0
	# The bot steers through the same touch vector a phone uses, so it exercises
	# the real input path rather than a private back door.
	chamber.umbra.input_enabled = true
	chamber.umbra.scattered_at.connect(func(_cell: Vector2i) -> void: scatters += 1)


func target() -> Vector2i:
	if route.is_empty():
		return Vector2i.ZERO
	return route[mini(allowed_index(), route.size() - 1)]


## How far along the route the schedule permits her to be by now.
func allowed_index() -> int:
	var by_clock := int(elapsed / ChamberProver.SLICE_SECONDS) + 1
	return mini(index, by_clock)


## One step of the bot's own control loop, called from the test's physics ticks.
func step(delta: float) -> void:
	if done or chamber == null or chamber.umbra == null:
		return
	elapsed += delta
	var umbra := chamber.umbra
	lowest_coherence = minf(lowest_coherence, umbra.state.coherence)

	if umbra.state.is_scattered:
		# Let the body reform where it will, then re-aim at the nearest point on
		# the route rather than marching back to the start.
		umbra.touch_direction = Vector2.ZERO
		_reaim()
		return

	var goal := chamber.data.cell_to_world(target())
	var to := goal - umbra.global_position
	if to.length() <= ARRIVE and index == allowed_index():
		index += 1
		if index >= route.size():
			_finish(umbra.current_cell() == chamber.data.exit)
			return
		goal = chamber.data.cell_to_world(target())
		to = goal - umbra.global_position

	# Waiting is part of the route, so standing still on purpose is not stuck.
	if to.length() <= ARRIVE:
		umbra.touch_direction = Vector2.ZERO
	else:
		umbra.touch_direction = to.normalized()
	_watch_for_snags(delta, umbra)
	if umbra.glare() > CAST_GLARE and umbra.state.can_cast():
		umbra.try_cast()
	if umbra.current_cell() == chamber.data.exit:
		_finish(true)


## A body with a radius can catch on a corner the grid says is open. If she has
## not moved while trying to, ease toward the centre of the cell she is in
## before pushing on — the same thing a player does without thinking.
func _watch_for_snags(delta: float, umbra: Umbra) -> void:
	if umbra.touch_direction == Vector2.ZERO:
		_stuck_for = 0.0
		_last_position = umbra.global_position
		return
	if umbra.global_position.distance_to(_last_position) > 1.0:
		_stuck_for = 0.0
		_last_position = umbra.global_position
		return
	_stuck_for += delta
	if _stuck_for > 0.5:
		var centre := chamber.data.cell_to_world(umbra.current_cell())
		umbra.touch_direction = (
			(centre - umbra.global_position).normalized()
			if centre.distance_to(umbra.global_position) > 1.0
			else umbra.touch_direction.orthogonal()
		)
		_stuck_for = 0.0


func _reaim() -> void:
	var here := chamber.umbra.current_cell()
	var best := index
	var best_distance := INF
	for i in range(index, route.size()):
		var distance := Vector2(route[i] - here).length()
		if distance < best_distance:
			best_distance = distance
			best = i
	index = best


func _finish(success: bool) -> void:
	done = true
	reached_exit = success
	if chamber.umbra != null:
		chamber.umbra.touch_direction = Vector2.ZERO
	finished.emit(success)


func report() -> String:
	return (
		"%s: %s in %.1fs, %d scatters, coherence floor %.0f%%"
		% [
			chamber.data.id,
			"reached the exit" if reached_exit else "STUCK",
			elapsed,
			scatters,
			lowest_coherence,
		]
	)
