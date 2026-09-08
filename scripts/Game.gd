class_name Game
extends Node2D

## The climb. Holds one chamber at a time and swaps to the next when Umbra
## reaches the way out, carrying nothing between floors but her own condition —
## which is the whole reason the last stretch of a floor is tense.

signal chamber_entered(id: String)
signal climb_finished

const CHAMBER_DIR := "res://chambers/"
const FADE_SECONDS := 0.45

## The Sunken Observatory, cellar first. A chamber's own `next:` overrides this,
## so a floor can be rerouted without touching code.
const DEFAULT_ORDER: Array[String] = ["cistern", "candle_rows", "orrery", "warden_walk", "prism_hall"]

@export var start_chamber: String = "cistern"

var chamber: Chamber
var current_id: String = ""
var progress: Progress = Progress.new()

## Set by the title screen before the scene swaps, so Game does not have to
## know a title screen exists.
static var pending_chamber: String = ""

var _fade: ColorRect
var _swapping: bool = false


func _ready() -> void:
	_build_fade()
	progress = Progress.load_from()
	var first := pending_chamber if not pending_chamber.is_empty() else start_chamber
	pending_chamber = ""
	enter(first)


func _build_fade() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_fade = ColorRect.new()
	_fade.color = Color(0.01, 0.01, 0.02, 0.0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_fade)


static func path_for(id: String) -> String:
	return "%s%s.txt" % [CHAMBER_DIR, id]


## Where a floor leads: its own `next:`, else the next one in the climb.
static func next_after(id: String, declared_next: String) -> String:
	if not declared_next.strip_edges().is_empty():
		return declared_next.strip_edges()
	var index := DEFAULT_ORDER.find(id)
	if index < 0 or index + 1 >= DEFAULT_ORDER.size():
		return ""
	return DEFAULT_ORDER[index + 1]


func enter(id: String) -> void:
	if chamber != null:
		chamber.queue_free()
		remove_child(chamber)
		chamber = null
	current_id = id
	chamber = Chamber.new()
	chamber.name = "Chamber"
	chamber.chamber_path = path_for(id)
	add_child(chamber)
	chamber.exit_reached.connect(_on_exit_reached, CONNECT_ONE_SHOT)
	chamber.umbra_scattered.connect(_on_scattered)
	progress.enter(id, DEFAULT_ORDER)
	progress.save()
	chamber_entered.emit(id)


func _on_scattered(_cell: Vector2i) -> void:
	progress.record_scatter()
	progress.save()


func _process(delta: float) -> void:
	progress.add_time(delta)


func _on_exit_reached() -> void:
	if _swapping:
		return
	_swapping = true
	progress.complete(current_id)
	progress.save()
	var next := next_after(current_id, chamber.data.next_id)
	if next.is_empty():
		climb_finished.emit()
		_swapping = false
		return
	_fade_to(next)


func _fade_to(next: String) -> void:
	if chamber != null and chamber.umbra != null:
		chamber.umbra.input_enabled = false
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", 1.0, FADE_SECONDS)
	tween.tween_callback(func() -> void: enter(next))
	tween.tween_property(_fade, "color:a", 0.0, FADE_SECONDS)
	tween.tween_callback(func() -> void: _swapping = false)
