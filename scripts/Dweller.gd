class_name Dweller
extends RefCounted

const DECAY_MOOD: float = 0.6
const DECAY_HUNGER: float = 0.35
const DECAY_ENERGY: float = 0.15
const MAX_NEED: float = 100.0
const MIN_NEED: float = 0.0

var hunger: float = MAX_NEED
var energy: float = MAX_NEED
var mood: float = MAX_NEED


func apply_elapsed(seconds: float) -> void:
	mood = clamp(mood - DECAY_MOOD * seconds, MIN_NEED, MAX_NEED)
	hunger = clamp(hunger - DECAY_HUNGER * seconds, MIN_NEED, MAX_NEED)
	energy = clamp(energy - DECAY_ENERGY * seconds, MIN_NEED, MAX_NEED)


func refill_need(need: String, amount: float) -> void:
	match need:
		"hunger":
			hunger = clamp(hunger + amount, MIN_NEED, MAX_NEED)
		"energy":
			energy = clamp(energy + amount, MIN_NEED, MAX_NEED)
		"mood":
			mood = clamp(mood + amount, MIN_NEED, MAX_NEED)
