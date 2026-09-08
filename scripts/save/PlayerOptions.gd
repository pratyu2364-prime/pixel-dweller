class_name PlayerOptions
extends RefCounted

## Player-facing settings, saved next to progress.
##
## PENUMBRA is a game about being punished by light, which is exactly the kind
## of game that needs a way to turn the punishment down. Gentle mode is not a
## lesser version — the rooms, the routes and the endings are identical; only
## the cost of being wrong changes.

const PATH := "user://options.json"

const GENTLE_DRAIN := 0.55  ## light bites a little over half as hard
const GENTLE_INK := 2.0  ## and she carries two more puffs

var gentle: bool = false
var high_contrast: bool = false  ## widen the gap between shade and glare
var reduced_motion: bool = false  ## no screen shake, no flicker
var volume: float = 0.8


func drain_multiplier() -> float:
	return GENTLE_DRAIN if gentle else 1.0


func bonus_ink() -> float:
	return GENTLE_INK if gentle else 0.0


func volume_db() -> float:
	if volume <= 0.001:
		return -80.0
	return linear_to_db(clampf(volume, 0.0, 1.0))


func to_dict() -> Dictionary:
	return {
		"gentle": gentle,
		"high_contrast": high_contrast,
		"reduced_motion": reduced_motion,
		"volume": volume,
	}


static func from_dict(data: Dictionary) -> PlayerOptions:
	var options := PlayerOptions.new()
	options.gentle = bool(data.get("gentle", false))
	options.high_contrast = bool(data.get("high_contrast", false))
	options.reduced_motion = bool(data.get("reduced_motion", false))
	options.volume = clampf(float(data.get("volume", 0.8)), 0.0, 1.0)
	return options


func save(path: String = PATH) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(to_dict()))


static func load_from(path: String = PATH) -> PlayerOptions:
	if not FileAccess.file_exists(path):
		return PlayerOptions.new()
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return PlayerOptions.new()
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return PlayerOptions.new()
	return PlayerOptions.from_dict(parsed)


static func clear(path: String = PATH) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
