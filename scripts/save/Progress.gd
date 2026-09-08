class_name Progress
extends RefCounted

## What survives being closed: which floors she has reached and finished, and
## how many times the light took her. Deliberately thin — PENUMBRA has no
## inventory, no currency and no levels, so there is almost nothing to persist.

const PATH := "user://penumbra.json"
const FIRST_CHAMBER := "cistern"

var reached: String = FIRST_CHAMBER  ## deepest floor entered; where Continue goes
var completed: Array[String] = []
var scatters: int = 0
var seconds_played: float = 0.0
## Which endings she has seen. Both can be true: the game invites a second climb
## rather than grading the first.
var endings: Dictionary = {}


func has_started() -> bool:
	return reached != FIRST_CHAMBER or not completed.is_empty() or scatters > 0


func has_finished() -> bool:
	return not endings.is_empty()


func is_complete(id: String) -> bool:
	return completed.has(id)


## Entering a floor only ever moves you forward in the record, so replaying an
## early chamber never costs you your place in the climb.
func enter(id: String, order: Array[String]) -> void:
	var current := order.find(reached)
	var next := order.find(id)
	if next > current:
		reached = id
	elif current < 0:
		reached = id


func complete(id: String) -> void:
	if not completed.has(id):
		completed.append(id)


func record_scatter() -> void:
	scatters += 1


func add_time(delta: float) -> void:
	seconds_played += maxf(delta, 0.0)


func to_dict() -> Dictionary:
	return {
		"reached": reached,
		"completed": completed,
		"scatters": scatters,
		"seconds_played": seconds_played,
		"endings": endings.keys(),
	}


static func from_dict(data: Dictionary) -> Progress:
	var progress := Progress.new()
	progress.reached = String(data.get("reached", FIRST_CHAMBER))
	progress.scatters = int(data.get("scatters", 0))
	progress.seconds_played = float(data.get("seconds_played", 0.0))
	for id in data.get("completed", []):
		progress.completed.append(String(id))
	for kind in data.get("endings", []):
		progress.endings[String(kind)] = true
	return progress


func save(path: String = PATH) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(to_dict()))


## A corrupt or missing save is a fresh start, never a crash: this runs in a
## browser, where storage can vanish between one visit and the next.
static func load_from(path: String = PATH) -> Progress:
	if not FileAccess.file_exists(path):
		return Progress.new()
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return Progress.new()
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return Progress.new()
	return Progress.from_dict(parsed)


static func clear(path: String = PATH) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
