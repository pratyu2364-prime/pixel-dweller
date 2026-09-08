class_name ChamberProver
extends RefCounted

## Proves a chamber is winnable *without ever standing in light*.
##
## Moving lights made hand-checking a floor impossible: a room that looks safe
## can seal itself four seconds after you enter it. So instead of trusting a
## designer's eye, this searches the room in space *and time* and answers one
## question — is there a route from the spawn to the exit that never crosses
## glare, given that beams sweep and lamps orbit?
##
## Ink is modelled too, because a lit crossing is legal when she has a puff to
## throw: a step into glare costs a charge, and charges only return in deep
## shade. That is exactly the game's own rule, so a route the prover finds is a
## route a player could actually walk.

const SLICE_SECONDS := 0.5
const DEFAULT_HORIZON := 160  ## 80 seconds of simulated time
const MAX_INK := 3
const MAX_SPEND := 8  ## more crossings than this and the room is not a puzzle

var reachable: bool = false
var slices_taken: int = -1
var ink_spent: int = 0
var visited_states: int = 0
## The route itself, cell by cell, one entry per half-second slice. This is what
## lets a bot walk the proof with the real body and real collision.
var route: Array[Vector2i] = []

var _data: ChamberData
var _snapshots: Array[LightField] = []

## Snapshot sets are a pure function of (chamber, horizon), and the tests build
## the same ones over and over, so they are shared rather than rebuilt.
static var _snapshot_cache: Dictionary = {}


## When set, the search must pass through this cell before the exit counts —
## used to prove a memory is not merely placed but actually collectable.
var via: Vector2i = Vector2i(-1, -1)


func _init(
	data: ChamberData,
	horizon: int = DEFAULT_HORIZON,
	p_via: Vector2i = Vector2i(-1, -1),
	max_budget: int = MAX_SPEND
) -> void:
	_data = data
	via = p_via
	# Snapshots wrap, so the horizon must cover a whole tide or the search would
	# be reasoning about a cycle the room does not actually have.
	if data.has_tide():
		var cycle := int(ceil(float(data.tide_definition["period"]) / SLICE_SECONDS))
		horizon = maxi(horizon, cycle)
	_build_snapshots(horizon)
	# Cheapest first: a route that pays for one crossing is a better answer
	# about a room than a faster route that pays for six.
	for budget in range(0, mini(max_budget, MAX_SPEND) + 1):
		_search(budget)
		if reachable:
			return


## One light field per time slice, advanced exactly the way the live chamber
## advances it. Snapshots are shared by every state at that instant, so the
## search costs no more than the simulation does.
func _build_snapshots(horizon: int) -> void:
	var key := "%s@%d" % [_data.signature(), horizon]
	if _snapshot_cache.has(key):
		_snapshots = _snapshot_cache[key]
		return
	for slice in horizon:
		var field := _data.build_field()
		var movers: Array[MovingLight] = []
		for definition in _data.movers:
			movers.append(MovingLight.from_definition(definition))
		for mover in movers:
			mover.advance(SLICE_SECONDS * float(slice))
			mover.apply(field)
		var tide := _data.build_tide()
		if tide != null:
			tide.apply(field, SLICE_SECONDS * float(slice))
		_snapshots.append(field)
	_snapshot_cache[key] = _snapshots


func snapshot(slice: int) -> LightField:
	return _snapshots[slice % _snapshots.size()]


func is_safe(cell: Vector2i, slice: int) -> bool:
	return snapshot(slice).is_shade(cell)


func is_deep(cell: Vector2i, slice: int) -> bool:
	return snapshot(slice).is_deep_shade(cell)


## Ink refills, so a state has to remember how many crossings it has paid for
## as well as what it is carrying — otherwise a route that spends three charges
## and recharges reads as free.
func _key(cell: Vector2i, slice: int, ink: int, spent: int, been: bool) -> int:
	var wrapped := slice % _snapshots.size()
	var place := (cell.y * _data.width + cell.x) * _snapshots.size() + wrapped
	var base := (place * (MAX_INK + 1) + ink) * (MAX_SPEND + 1) + spent
	return base * 2 + (1 if been else 0)


## Breadth-first over (cell, time, ink). Every edge is one time slice, so the
## first time the exit is reached is also the fastest safe route.
func _search(budget: int) -> void:
	if not _data.is_valid():
		return
	var start := _data.spawn
	var wants_detour := via != Vector2i(-1, -1)
	var start_been := not wants_detour or start == via
	var queue: Array = [[start, 0, MAX_INK, 0, start_been]]
	var seen := {_key(start, 0, MAX_INK, 0, start_been): true}
	var came_from := {}
	var head := 0
	while head < queue.size():
		var state: Array = queue[head]
		head += 1
		var cell: Vector2i = state[0]
		var slice: int = state[1]
		var ink: int = state[2]
		var spent: int = state[3]
		var been: bool = state[4]
		if cell == _data.exit and been:
			reachable = true
			slices_taken = slice
			ink_spent = spent
			visited_states = seen.size()
			route = _rebuild(came_from, head - 1, queue)
			return
		if slice >= _snapshots.size() * 2:
			continue
		var next_slice := slice + 1
		for offset in [Vector2i.ZERO, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = cell + offset
			if not _data.in_bounds(next) or _data.is_wall(next):
				continue
			var next_ink := ink
			var next_spent := spent
			if not is_safe(next, next_slice):
				# Crossing light is legal only with a puff to throw.
				if next_ink <= 0 or next_spent >= budget:
					continue
				next_ink -= 1
				next_spent += 1
			elif is_deep(next, next_slice) and next_ink < MAX_INK:
				next_ink += 1
			var next_been: bool = been or next == via
			var key := _key(next, next_slice, next_ink, next_spent, next_been)
			if seen.has(key):
				continue
			seen[key] = true
			came_from[queue.size()] = head - 1
			queue.append([next, next_slice, next_ink, next_spent, next_been])
	visited_states = seen.size()


## Walks the search backwards from the state that reached the exit.
func _rebuild(came_from: Dictionary, index: int, queue: Array) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var at := index
	while at >= 0:
		cells.append(queue[at][0])
		if not came_from.has(at):
			break
		at = came_from[at]
	cells.reverse()
	return cells


func seconds_taken() -> float:
	return float(slices_taken) * SLICE_SECONDS


func report() -> String:
	if not reachable:
		return "%s: NO SAFE ROUTE (searched %d states)" % [_data.id, visited_states]
	return (
		"%s: safe route in %.1fs, %d crossings paid for (%d states)"
		% [_data.id, seconds_taken(), ink_spent, visited_states]
	)
