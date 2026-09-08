class_name UmbraBlot
extends Node2D

## Umbra's body, drawn as an absence rather than a sprite: a wobbling hole with
## no outline, which only grows a rim when the light starts eating her.
##
## She is deliberately shapeless. A shadow with a face is a character in a
## costume; a shadow with a silhouette that never settles is a shadow.

const POINTS := 14
const BASE_RADIUS := 6.5
const WOBBLE := 0.9

var glare: float = 0.0
var coherence_fraction: float = 1.0
var scattered: bool = false

var _time: float = 0.0
var _seed: float = 0.0


func _ready() -> void:
	_seed = randf() * 10.0


func _process(delta: float) -> void:
	# She churns faster the more the light hurts — the body reads the danger
	# before the meter does.
	_time += delta * (1.0 + glare * 2.5)
	queue_redraw()


func set_condition(p_glare: float, p_fraction: float, p_scattered: bool) -> void:
	glare = clampf(p_glare, 0.0, 1.0)
	coherence_fraction = clampf(p_fraction, 0.0, 1.0)
	scattered = p_scattered


## The silhouette for the current instant. Pure, so the wobble is testable.
static func silhouette(
	time: float, seed_value: float, radius: float, wobble: float, points: int = POINTS
) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in points:
		var angle := TAU * float(i) / float(points)
		var noise := sin(angle * 3.0 + time * 2.1 + seed_value)
		noise += 0.5 * sin(angle * 5.0 - time * 1.3 + seed_value * 2.0)
		out.append(Vector2.from_angle(angle) * (radius + noise * wobble))
	return out


func _draw() -> void:
	if scattered:
		_draw_scattering()
		return
	# She thins as she burns, but never vanishes before she scatters.
	var radius := BASE_RADIUS * lerpf(0.72, 1.0, coherence_fraction)
	var shape := silhouette(_time, _seed, radius, WOBBLE * (1.0 + glare))

	# Three stacked blots: a soft halo of darkness, the body, and a dense core.
	draw_colored_polygon(
		silhouette(_time * 0.7, _seed + 3.0, radius * 1.55, WOBBLE),
		Color(0.02, 0.02, 0.05, 0.35)
	)
	draw_colored_polygon(shape, Color(0.03, 0.02, 0.06, 0.96))
	draw_colored_polygon(
		silhouette(_time * 1.4, _seed + 7.0, radius * 0.45, WOBBLE * 0.6),
		Color(0.0, 0.0, 0.0, 1.0)
	)

	# Only the light gives her an edge: a burning rim, brighter the deeper in.
	if glare > 0.01:
		var rim := Color(1.0, 0.78, 0.45, 0.35 + 0.5 * glare)
		draw_polyline(_closed(shape), rim, 1.0 + glare, true)


func _draw_scattering() -> void:
	# Coming apart: the same blot, torn into drifting flecks.
	for i in 9:
		var angle := TAU * float(i) / 9.0 + _time
		var drift := Vector2.from_angle(angle) * (4.0 + 7.0 * fmod(_time, 1.0))
		draw_circle(drift, 1.6, Color(0.04, 0.03, 0.08, 0.7))


static func _closed(shape: PackedVector2Array) -> PackedVector2Array:
	var out := shape.duplicate()
	if out.size() > 0:
		out.append(out[0])
	return out
