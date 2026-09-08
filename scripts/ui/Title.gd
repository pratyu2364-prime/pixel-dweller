class_name TitleScreen
extends Control

## The first thing anyone sees. One word, one line, and a way in — the title is
## drawn as a hole in a lit field, which is the whole game in one image.

signal start_requested(chamber: String)

const FLOOR_NAMES := {
	"cistern": "−3 · The Cistern",
	"candle_rows": "−2 · Candle Rows",
	"orrery": "−1 · The Orrery",
	"warden_walk": "0 · Warden's Walk",
	"prism_hall": "+1 · The Prism Hall",
}

var progress: Progress

@onready var _continue_button: Button = $Menu/Continue
@onready var _begin_button: Button = $Menu/Begin
@onready var _where: Label = $Menu/Where


func _ready() -> void:
	progress = Progress.load_from()
	_begin_button.pressed.connect(func() -> void: _start(Progress.FIRST_CHAMBER))
	_continue_button.pressed.connect(func() -> void: _start(progress.reached))
	refresh()


func refresh() -> void:
	var started := progress.has_started()
	_continue_button.visible = started
	_continue_button.text = "descend"
	_begin_button.text = "begin again" if started else "begin"
	_where.text = subtitle_for(progress)
	_where.visible = started


## What the menu says about a save: where she is, and what it has cost.
static func subtitle_for(state: Progress) -> String:
	if not state.has_started():
		return ""
	var floor_name: String = FLOOR_NAMES.get(state.reached, state.reached)
	if state.scatters == 0:
		return "%s · never yet scattered" % floor_name
	if state.scatters == 1:
		return "%s · scattered once" % floor_name
	return "%s · scattered %d times" % [floor_name, state.scatters]


func _start(chamber: String) -> void:
	Game.pending_chamber = chamber
	start_requested.emit(chamber)
	get_tree().change_scene_to_file("res://scenes/Game.tscn")
