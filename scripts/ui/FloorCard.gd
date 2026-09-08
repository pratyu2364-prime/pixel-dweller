class_name FloorCard
extends CanvasLayer

## The card that names a floor as you arrive: "−2 · Candle Rows", and under it
## the line the chamber file carries. It fades in over the dark, holds, and
## leaves — the game never waits for a keypress to get on with itself.

const HOLD_SECONDS := 2.2
const FADE_SECONDS := 0.8

var elapsed: float = 0.0
var showing: bool = false

var _title: Label
var _subtitle: Label
var _root: Control


func _init() -> void:
	layer = 15
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.modulate.a = 0.0
	add_child(_root)

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.anchor_left = 0.5
	box.anchor_right = 0.5
	box.anchor_top = 0.5
	box.anchor_bottom = 0.5
	box.offset_left = -260.0
	box.offset_right = 260.0
	box.offset_top = -60.0
	box.offset_bottom = 40.0
	box.add_theme_constant_override("separation", 10)
	_root.add_child(box)

	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 34)
	_title.add_theme_color_override("font_color", Color(0.87, 0.88, 1.0, 0.94))
	box.add_child(_title)

	_subtitle = Label.new()
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_subtitle.add_theme_color_override("font_color", Color(0.6, 0.63, 0.85, 0.8))
	box.add_child(_subtitle)


func present(title: String, subtitle: String) -> void:
	_title.text = title
	_subtitle.text = subtitle
	elapsed = 0.0
	showing = true


## Fade in, hold, fade out — expressed as a pure curve so the timing is
## testable without waiting for it in real time.
static func alpha_at(seconds: float) -> float:
	if seconds < FADE_SECONDS:
		return clampf(seconds / FADE_SECONDS, 0.0, 1.0)
	if seconds < FADE_SECONDS + HOLD_SECONDS:
		return 1.0
	var out := seconds - FADE_SECONDS - HOLD_SECONDS
	return clampf(1.0 - out / FADE_SECONDS, 0.0, 1.0)


static func total_seconds() -> float:
	return FADE_SECONDS * 2.0 + HOLD_SECONDS


func _process(delta: float) -> void:
	if not showing:
		return
	elapsed += delta
	_root.modulate.a = alpha_at(elapsed)
	if elapsed >= total_seconds():
		showing = false
		_root.modulate.a = 0.0
