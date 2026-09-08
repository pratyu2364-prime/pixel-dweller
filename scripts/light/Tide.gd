class_name Tide
extends RefCounted

## Rooms where the light itself rises and falls — the Observatory's shutters
## opening on a slow clock. Ambient light climbs to a peak, holds, and drains
## away again, so a chamber is not a puzzle you solve once but a place that is
## periodically survivable.
##
## Deterministic, like every other moving light in PENUMBRA: a player can learn
## the tide, and a prover can search it.

var low: float = 0.0
var high: float = 0.6
var period: float = 40.0  ## a full rise and fall
var hold: float = 6.0  ## seconds at the top, when nowhere is safe
var phase: float = 0.0  ## 0..1 offset, so a floor can start mid-tide


func _init(p_low: float = 0.0, p_high: float = 0.6, p_period: float = 40.0, p_hold: float = 6.0):
	low = p_low
	high = p_high
	period = maxf(p_period, 0.01)
	hold = clampf(p_hold, 0.0, period * 0.5)


## Ambient light at a moment in the cycle: rise, hold, fall, rest.
func level_at(seconds: float) -> float:
	var t := fposmod(seconds / period + phase, 1.0) * period
	var swing := (period - hold * 2.0) * 0.5
	if t < swing:
		return lerpf(low, high, t / swing)
	if t < swing + hold:
		return high
	if t < swing * 2.0 + hold:
		return lerpf(high, low, (t - swing - hold) / swing)
	return low


## True while the room is at its peak — the beat where hiding stops working and
## the only answer is ink, a nook, or having already moved.
func is_flooded(seconds: float) -> bool:
	return level_at(seconds) > LightField.SHADE_MAX


func apply(field: LightField, seconds: float) -> void:
	field.set_ambient(level_at(seconds))


## `tide: low=0.02 high=0.55 period=36 hold=6 phase=0.25`
static func from_tokens(value: String) -> Dictionary:
	var out := {
		"low": 0.0, "high": 0.6, "period": 40.0, "hold": 6.0, "phase": 0.0,
		"errors": [] as Array[String],
	}
	for token in value.split(" ", false):
		var pair := String(token).split("=", true, 1)
		if pair.size() != 2:
			out["errors"].append("bad tide token: %s" % token)
			continue
		if out.has(pair[0]) and pair[0] != "errors":
			out[pair[0]] = pair[1].to_float()
		else:
			out["errors"].append("unknown tide key: %s" % pair[0])
	if out["period"] <= 0.0:
		out["errors"].append("a tide needs a period")
	if out["high"] <= out["low"]:
		out["errors"].append("a tide that does not rise is not a tide")
	return out


static func from_definition(definition: Dictionary) -> Tide:
	var tide := Tide.new(
		definition["low"], definition["high"], definition["period"], definition["hold"]
	)
	tide.phase = definition["phase"]
	return tide
