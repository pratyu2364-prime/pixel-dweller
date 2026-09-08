class_name MovingLight
extends RefCounted

## Lights that will not hold still: the orrery's orbiting lamps and the beams
## that sweep the hall. Both are the same idea — a light whose position or aim
## is a function of time — which makes them fully deterministic and therefore
## solvable. A player can learn a rhythm; they cannot learn a random number.

enum Kind { ORBIT, SWEEP }

var id: String
var kind: int = Kind.ORBIT
var center: Vector2  ## in cells
var radius: float = 5.0  ## orbit radius, in cells
var period: float = 8.0  ## seconds for one full revolution
var phase: float = 0.0  ## 0..1 offset around the circle, for staggering
var clockwise: bool = true
var half_angle: float = 0.45  ## SWEEP only: the cone's half width in radians

var _time: float = 0.0


func _init(p_id: String, p_kind: int = Kind.ORBIT) -> void:
	id = p_id
	kind = p_kind


func advance(delta: float) -> void:
	period = maxf(period, 0.01)
	_time = fposmod(_time + delta, period)


func reset() -> void:
	_time = 0.0


func elapsed() -> float:
	return _time


## Angle around the circle right now, in radians.
func angle() -> float:
	var turns := _time / period + phase
	return TAU * (turns if clockwise else -turns)


## Where an orbiting light sits this instant, in cell space.
func position() -> Vector2:
	if kind != Kind.ORBIT:
		return center
	return center + Vector2.from_angle(angle()) * radius


func cell() -> Vector2i:
	var at := position()
	return Vector2i(roundi(at.x), roundi(at.y))


## Which way a sweeping beam points this instant.
func direction() -> Vector2:
	return Vector2.from_angle(angle())


## Registers this light in a field and returns the emitter, so the two can
## never disagree about which id belongs to which mover.
func install(field: LightField, light_radius: float, intensity: float = 1.0) -> void:
	field.emit(id, cell(), light_radius, intensity)
	if kind == Kind.SWEEP:
		field.aim_emitter(id, direction(), half_angle)


func apply(field: LightField) -> void:
	if kind == Kind.ORBIT:
		field.move_emitter(id, cell())
	else:
		field.aim_emitter(id, direction())


## `orbit: id=p1 center=(20,10) radius=6 period=9 phase=0.5 light=5 ccw`
## `sweep: id=eye cell=(20,10) period=14 arc=0.4 light=13`
static func from_tokens(kind: int, value: String, index: int) -> Dictionary:
	var out := {
		"id": "%s_%d" % ["orbit" if kind == Kind.ORBIT else "sweep", index],
		"kind": kind,
		"center": Vector2(0, 0),
		"radius": 5.0,
		"period": 8.0,
		"phase": 0.0,
		"clockwise": true,
		"half_angle": 0.45,
		"light": 5.0,
		"errors": [] as Array[String],
	}
	for token in value.split(" ", false):
		var text := String(token)
		if text == "ccw":
			out["clockwise"] = false
			continue
		var pair := text.split("=", true, 1)
		if pair.size() != 2:
			out["errors"].append("bad token: %s" % text)
			continue
		match pair[0]:
			"id":
				out["id"] = pair[1]
			"center", "cell":
				out["center"] = _parse_point(pair[1])
			"radius":
				out["radius"] = pair[1].to_float()
			"period":
				out["period"] = pair[1].to_float()
			"phase":
				out["phase"] = pair[1].to_float()
			"arc":
				out["half_angle"] = pair[1].to_float()
			"light":
				out["light"] = pair[1].to_float()
			_:
				out["errors"].append("unknown key: %s" % pair[0])
	if out["period"] <= 0.0:
		out["errors"].append("period must be positive")
	return out


static func from_definition(definition: Dictionary) -> MovingLight:
	var mover := MovingLight.new(String(definition["id"]), int(definition["kind"]))
	mover.center = definition["center"]
	mover.radius = definition["radius"]
	mover.period = definition["period"]
	mover.phase = definition["phase"]
	mover.clockwise = definition["clockwise"]
	mover.half_angle = definition["half_angle"]
	return mover


static func _parse_point(text: String) -> Vector2:
	var cleaned := text.strip_edges().trim_prefix("(").trim_suffix(")")
	var parts := cleaned.split(",")
	if parts.size() != 2:
		return Vector2.ZERO
	return Vector2(parts[0].to_float(), parts[1].to_float())
