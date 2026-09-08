class_name LampChain
extends RefCounted

## The Great Lamp and the feeders that keep it burning.
##
## The Lamp cannot be smothered while it is fed: it only dims, one share at a
## time, as its feeders go out. So the finale is not a boss fight, it is the
## game's own vocabulary at full size — snuff the small lights, then lean on
## the big one until it gives.

signal dimmed(fraction: float)
signal extinguishable
signal extinguished

var great_id: String = ""
var feeder_ids: Array[String] = []
var base_intensity: float = 1.0

var _field: LightField
var _cling: ClingController
var _announced: bool = false


func _init(
	p_field: LightField,
	p_cling: ClingController,
	p_great: String,
	p_feeders: Array,
	p_base: float = 1.0
) -> void:
	_field = p_field
	_cling = p_cling
	great_id = p_great
	for id in p_feeders:
		feeder_ids.append(String(id))
	base_intensity = p_base
	_cling.lock(great_id)
	_cling.snuffed.connect(_on_light_snuffed)
	_cling.relit.connect(_on_light_relit)
	apply()


func live_feeders() -> int:
	var alive := 0
	for id in feeder_ids:
		if not _cling.is_snuffed(id):
			alive += 1
	return alive


## What is left of the Lamp: full while every feeder burns, out when none do.
func fraction() -> float:
	if feeder_ids.is_empty():
		return 1.0
	return float(live_feeders()) / float(feeder_ids.size())


func is_extinguishable() -> bool:
	return live_feeders() == 0


func is_extinguished() -> bool:
	return _cling.is_snuffed(great_id)


func apply() -> void:
	if is_extinguished():
		return
	_field.set_emitter_intensity(great_id, base_intensity * fraction())


func _on_light_snuffed(id: String) -> void:
	if id == great_id:
		extinguished.emit()
		return
	if not feeder_ids.has(id):
		return
	apply()
	dimmed.emit(fraction())
	if is_extinguishable() and not _announced:
		_announced = true
		_cling.unlock(great_id)
		extinguishable.emit()


func _on_light_relit(id: String) -> void:
	if feeder_ids.has(id):
		_announced = false
		_cling.lock(great_id)
		apply()
		dimmed.emit(fraction())
