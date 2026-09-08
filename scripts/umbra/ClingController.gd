class_name ClingController
extends RefCounted

## The Cling verb: Umbra latching onto a light to drag it, or smothering one she
## cannot lift. Pure logic over a LightField plus the chamber's light metadata,
## so grabbing, carrying, snuffing and relighting are all testable headlessly.
##
## Two kinds of light, two relationships:
##   portable (candles)     — grab and carry; a moving light is a moving safe path
##   fixed (lamps, braziers) — cannot be lifted, only smothered by standing in
##                             their glare and holding on, which costs coherence
##
## That asymmetry is the whole puzzle vocabulary: carry darkness to a place, or
## pay in coherence to make a place dark.

signal grabbed(light_id: String)
signal released(light_id: String)
signal snuffed(light_id: String)
signal relit(light_id: String)

const CLING_RANGE := 1.9  ## cells; roughly "you can touch it"
const CARRY_INTENSITY := 0.45  ## a carried candle is half-smothered in her grip
const SMOTHER_SECONDS := 1.2  ## how long to hold on a fixed light to kill it

var field: LightField
var held_id: String = ""
var smother_id: String = ""
var smother_progress: float = 0.0

var _lights: Dictionary = {}  ## id -> {kind, portable, base_intensity, snuffed}


func _init(p_field: LightField, light_defs: Array = []) -> void:
	field = p_field
	for def in light_defs:
		register(def)


## `def` is a ChamberData light dictionary: {id, kind, cell, radius, intensity}.
func register(def: Dictionary) -> void:
	var kind := String(def.get("kind", "lamp"))
	_lights[String(def["id"])] = {
		"kind": kind,
		"portable": kind == "candle",
		"base_intensity": float(def.get("intensity", 1.0)),
		"snuffed": false,
	}


func is_portable(id: String) -> bool:
	return _lights.has(id) and _lights[id]["portable"]


func is_snuffed(id: String) -> bool:
	return _lights.has(id) and _lights[id]["snuffed"]


func is_holding() -> bool:
	return held_id != ""


## The nearest live light within reach — what a Cling press would act on.
func target_near(cell: Vector2i) -> String:
	var best := ""
	var best_distance := CLING_RANGE
	for emitter in field.emitters():
		if not _lights.has(emitter.id) or is_snuffed(emitter.id):
			continue
		var distance := Vector2(emitter.cell - cell).length()
		if distance <= best_distance:
			best_distance = distance
			best = emitter.id
	return best


## One press of Cling: release what you hold, else grab what you can lift, else
## begin smothering what you cannot.
func press(cell: Vector2i) -> String:
	if is_holding():
		release(cell)
		return "release"
	var target := target_near(cell)
	if target.is_empty():
		return ""
	if is_portable(target):
		_grab(target)
		return "grab"
	smother_id = target
	smother_progress = 0.0
	return "smother"


func release_press() -> void:
	if not smother_id.is_empty():
		smother_id = ""
		smother_progress = 0.0


func _grab(id: String) -> void:
	held_id = id
	field.set_emitter_intensity(id, CARRY_INTENSITY)
	grabbed.emit(id)


func release(cell: Vector2i) -> void:
	if not is_holding():
		return
	var id := held_id
	held_id = ""
	field.move_emitter(id, cell)
	field.set_emitter_intensity(id, _lights[id]["base_intensity"])
	released.emit(id)


## Called every frame: carries a held light and advances a smother-in-progress.
## `holding_input` is whether the Cling button is still down.
func tick(delta: float, cell: Vector2i, holding_input: bool) -> void:
	if is_holding():
		field.move_emitter(held_id, cell)
	if smother_id.is_empty():
		return
	if not holding_input or Vector2(field.get_emitter(smother_id).cell - cell).length() > CLING_RANGE:
		release_press()
		return
	smother_progress += delta
	if smother_progress >= SMOTHER_SECONDS:
		var id := smother_id
		release_press()
		snuff(id)


func smother_fraction() -> float:
	if smother_id.is_empty():
		return 0.0
	return clampf(smother_progress / SMOTHER_SECONDS, 0.0, 1.0)


func snuff(id: String) -> bool:
	if not _lights.has(id) or is_snuffed(id):
		return false
	if held_id == id:
		held_id = ""
	_lights[id]["snuffed"] = true
	field.set_emitter_enabled(id, false)
	snuffed.emit(id)
	return true


## Wardens relight what Umbra put out — the reason a snuffed room is a lead,
## not a solved state.
func relight(id: String) -> bool:
	if not _lights.has(id) or not is_snuffed(id):
		return false
	_lights[id]["snuffed"] = false
	field.set_emitter_intensity(id, _lights[id]["base_intensity"])
	field.set_emitter_enabled(id, true)
	relit.emit(id)
	return true


func snuffed_ids() -> Array[String]:
	var out: Array[String] = []
	for id in _lights:
		if _lights[id]["snuffed"]:
			out.append(String(id))
	return out
