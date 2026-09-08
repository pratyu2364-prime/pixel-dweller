class_name TitleScreen
extends Control

## The first thing anyone sees. One word, one line, and a way in — the title is
## drawn as a hole in a lit field, which is the whole game in one image.

signal start_requested(chamber: String)

const FLOOR_NAMES := {
	"drowned_stair": "−4 · The Drowned Stair",
	"cistern": "−3 · The Cistern",
	"candle_rows": "−2 · Candle Rows",
	"orrery": "−1 · The Orrery",
	"warden_walk": "0 · Warden's Walk",
	"long_gallery": "+1 · The Long Gallery",
	"prism_hall": "+2 · The Prism Hall",
	"lantern_room": "+3 · The Lantern Room",
}

var progress: Progress
var options: PlayerOptions

@onready var _continue_button: Button = $Menu/Continue
@onready var _begin_button: Button = $Menu/Begin
@onready var _where: Label = $Menu/Where


func _ready() -> void:
	progress = Progress.load_from()
	options = PlayerOptions.load_from()
	_build_options_row()
	_begin_button.pressed.connect(func() -> void: _start(Progress.FIRST_CHAMBER))
	_continue_button.pressed.connect(func() -> void: _start(progress.reached))
	refresh()


## Three toggles, in the language of the game rather than of a settings menu.
func _build_options_row() -> void:
	var row := VBoxContainer.new()
	row.name = "Options"
	row.add_theme_constant_override("separation", 6)
	$Menu.add_child(row)
	_add_toggle(row, "gentle · the light bites softer", options.gentle, func(on: bool) -> void:
		options.gentle = on
	)
	_add_toggle(row, "high contrast", options.high_contrast, func(on: bool) -> void:
		options.high_contrast = on
	)
	_add_toggle(row, "still flames · no shake", options.reduced_motion, func(on: bool) -> void:
		options.reduced_motion = on
	)


func _add_toggle(parent: Node, label: String, value: bool, apply: Callable) -> void:
	var button := CheckButton.new()
	button.text = label
	button.button_pressed = value
	button.toggled.connect(func(on: bool) -> void:
		apply.call(on)
		options.save()
	)
	parent.add_child(button)


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
	var remembered := ""
	if state.memories.size() > 0:
		remembered = " · %d remembered" % state.memories.size()
	if state.has_finished():
		if state.endings.size() > 1:
			return "you have gone out, and you have gone back"
		var ending := "you snuffed the lamp" if state.endings.has("free") else "you went back to them"
		return ending + remembered
	var floor_name: String = FLOOR_NAMES.get(state.reached, state.reached)
	if state.scatters == 0:
		return "%s · never yet scattered%s" % [floor_name, remembered]
	if state.scatters == 1:
		return "%s · scattered once%s" % [floor_name, remembered]
	return "%s · scattered %d times%s" % [floor_name, state.scatters, remembered]


func _start(chamber: String) -> void:
	Game.pending_chamber = chamber
	start_requested.emit(chamber)
	get_tree().change_scene_to_file("res://scenes/Game.tscn")
