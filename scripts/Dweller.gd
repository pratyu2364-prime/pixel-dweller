class_name Dweller
extends RefCounted

enum Stage { BABY, KID, ADULT }

signal grew_up(new_stage: Stage)

const DECAY_MOOD: float = 0.6
const DECAY_HUNGER: float = 0.35
const DECAY_ENERGY: float = 0.15
const MAX_NEED: float = 100.0
const MIN_NEED: float = 0.0

const KID_THRESHOLD: float = 60.0
const ADULT_THRESHOLD: float = 180.0
const NEGLECT_PENALTY: float = 0.5

var hunger: float = MAX_NEED
var energy: float = MAX_NEED
var mood: float = MAX_NEED

var stage: Stage = Stage.BABY
var care_score: float = 0.0


func apply_elapsed(seconds: float) -> void:
	mood = clamp(mood - DECAY_MOOD * seconds, MIN_NEED, MAX_NEED)
	hunger = clamp(hunger - DECAY_HUNGER * seconds, MIN_NEED, MAX_NEED)
	energy = clamp(energy - DECAY_ENERGY * seconds, MIN_NEED, MAX_NEED)

	var avg_need: float = (hunger + energy + mood) / 3.0
	care_score += (avg_need / MAX_NEED) * seconds

	if hunger <= MIN_NEED or energy <= MIN_NEED or mood <= MIN_NEED:
		care_score = max(care_score - NEGLECT_PENALTY * seconds, 0.0)

	_check_stage()


func _check_stage() -> void:
	var new_stage: Stage = stage
	if care_score >= ADULT_THRESHOLD:
		new_stage = Stage.ADULT
	elif care_score >= KID_THRESHOLD:
		new_stage = Stage.KID
	if new_stage != stage:
		stage = new_stage
		grew_up.emit(stage)


func refill_need(need: String, amount: float) -> void:
	match need:
		"hunger":
			hunger = clamp(hunger + amount, MIN_NEED, MAX_NEED)
		"energy":
			energy = clamp(energy + amount, MIN_NEED, MAX_NEED)
		"mood":
			mood = clamp(mood + amount, MIN_NEED, MAX_NEED)
