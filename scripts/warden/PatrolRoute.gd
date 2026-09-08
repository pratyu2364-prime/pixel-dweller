class_name PatrolRoute
extends RefCounted

## A Warden's beat: a list of cells walked at a steady pace, either looped or
## paced back and forth. Pure geometry — no nodes, no delta accumulation
## hidden in a scene — so a patrol's timing can be reasoned about in a test.

enum Mode { LOOP, PING_PONG }

var waypoints: Array[Vector2i] = []
var mode: int = Mode.PING_PONG
var speed: float = 2.4  ## cells per second

var _distance: float = 0.0
var _segment_lengths: PackedFloat32Array = PackedFloat32Array()
var _total: float = 0.0


func _init(
	p_waypoints: Array = [], p_mode: int = Mode.PING_PONG, p_speed: float = 2.4
) -> void:
	for point in p_waypoints:
		waypoints.append(point)
	mode = p_mode
	speed = maxf(p_speed, 0.01)
	_measure()


func _measure() -> void:
	_segment_lengths = PackedFloat32Array()
	_total = 0.0
	var path := _walked_path()
	for i in range(path.size() - 1):
		var length := Vector2(path[i + 1] - path[i]).length()
		_segment_lengths.append(length)
		_total += length


## PING_PONG is modelled as a loop over the doubled path, so one code path
## handles both modes and a Warden never teleports at the turnaround.
func _walked_path() -> Array[Vector2i]:
	if mode == Mode.LOOP:
		var looped := waypoints.duplicate()
		if looped.size() > 1:
			looped.append(waypoints[0])
		return looped
	var out := waypoints.duplicate()
	for i in range(waypoints.size() - 2, 0, -1):
		out.append(waypoints[i])
	if waypoints.size() > 1:
		out.append(waypoints[0])
	return out


func length() -> float:
	return _total


func is_valid() -> bool:
	return waypoints.size() >= 2 and _total > 0.0


func advance(delta: float) -> void:
	if not is_valid():
		return
	_distance = fposmod(_distance + speed * delta, _total)


func reset() -> void:
	_distance = 0.0


func distance_travelled() -> float:
	return _distance


## Where the Warden stands right now, in cell space (fractional between cells).
func position() -> Vector2:
	if waypoints.is_empty():
		return Vector2.ZERO
	if not is_valid():
		return Vector2(waypoints[0])
	var path := _walked_path()
	var remaining := _distance
	for i in _segment_lengths.size():
		var segment: float = _segment_lengths[i]
		if remaining <= segment:
			var t := remaining / segment
			return Vector2(path[i]).lerp(Vector2(path[i + 1]), t)
		remaining -= segment
	return Vector2(path[path.size() - 1])


## Which way they are looking — the direction of travel, so the cone always
## leads the walk.
func facing() -> Vector2:
	if not is_valid():
		return Vector2.RIGHT
	var here := position()
	var probe := _distance
	_distance = fposmod(_distance + 0.35, _total)
	var ahead := position()
	_distance = probe
	var direction := ahead - here
	return Vector2.RIGHT if direction.length() < 0.001 else direction.normalized()


static func parse_waypoints(text: String) -> Array[Vector2i]:
	## "(5,3)>(20,3)>(20,10)" — readable in a chamber file, and diffable.
	var out: Array[Vector2i] = []
	for chunk in text.split(">", false):
		var cleaned := String(chunk).strip_edges().trim_prefix("(").trim_suffix(")")
		var parts := cleaned.split(",")
		if parts.size() != 2:
			continue
		out.append(Vector2i(int(parts[0].strip_edges()), int(parts[1].strip_edges())))
	return out
