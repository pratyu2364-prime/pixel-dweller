class_name Hud
extends CanvasLayer

## Everything the player needs and nothing else: how whole she is, how much
## darkness she has left to throw, and what the light under her is doing.
##
## The coherence bar is drawn, not a themed ProgressBar, so it can bleed colour
## as it empties — the meter itself is the warning.

const BAR_SIZE := Vector2(180, 10)
const BAR_MARGIN := Vector2(16, 16)
const PIP_SIZE := Vector2(14, 14)
const PIP_GAP := 6.0

var state: ShadowState = null
var glare: float = 0.0
var smother: float = 0.0
var hint: String = ""
var whisper: String = ""

const WHISPER_SECONDS := 4.5
var _whisper_timer: float = 0.0

@onready var _canvas: Control = $Canvas
@onready var _hint_label: Label = $Canvas/Hint
@onready var _whisper_label: Label = $Canvas/Whisper


func _ready() -> void:
	_canvas.draw.connect(func() -> void: draw_hud(_canvas))
	set_hint(hint)


func bind(p_state: ShadowState) -> void:
	state = p_state


func set_glare(value: float) -> void:
	glare = clampf(value, 0.0, 1.0)


func set_smother(value: float) -> void:
	smother = clampf(value, 0.0, 1.0)


func set_hint(text: String) -> void:
	hint = text
	if _hint_label != null:
		_hint_label.text = text
		_hint_label.visible = not text.is_empty()


## Whispers are Umbra's own thoughts: they arrive, they linger, they fade. The
## player is never asked to dismiss one.
func say(text: String) -> void:
	whisper = text
	_whisper_timer = WHISPER_SECONDS
	if _whisper_label != null:
		_whisper_label.text = text
		_whisper_label.modulate.a = 0.0


func _process(delta: float) -> void:
	if _canvas != null:
		_canvas.queue_redraw()
	_fade_whisper(delta)


func _fade_whisper(delta: float) -> void:
	if _whisper_label == null:
		return
	if _whisper_timer <= 0.0:
		_whisper_label.modulate.a = maxf(0.0, _whisper_label.modulate.a - delta * 1.5)
		if _whisper_label.modulate.a <= 0.0:
			whisper = ""
		return
	_whisper_timer -= delta
	var appearing: float = minf(1.0, (WHISPER_SECONDS - _whisper_timer) * 2.0)
	_whisper_label.modulate.a = minf(appearing, maxf(0.0, _whisper_timer))


## Called by the Canvas child's draw signal (wired in the scene).
func draw_hud(canvas: Control) -> void:
	if state == null:
		return
	_draw_coherence(canvas)
	_draw_ink(canvas)
	if smother > 0.0:
		_draw_smother(canvas)


func _draw_coherence(canvas: Control) -> void:
	var origin := BAR_MARGIN
	canvas.draw_rect(Rect2(origin, BAR_SIZE), Color(0.05, 0.05, 0.09, 0.85))
	var fraction := state.fraction()
	var filled := Vector2(BAR_SIZE.x * fraction, BAR_SIZE.y)
	canvas.draw_rect(Rect2(origin, filled), coherence_color(fraction))
	canvas.draw_rect(Rect2(origin, BAR_SIZE), Color(0.5, 0.5, 0.62, 0.5), false, 1.0)


## Whole and cold when safe; hot and pale as she burns away.
static func coherence_color(fraction: float) -> Color:
	var whole := Color(0.55, 0.62, 0.95)
	var fading := Color(0.98, 0.72, 0.42)
	var dying := Color(1.0, 0.35, 0.35)
	if fraction > 0.5:
		return fading.lerp(whole, (fraction - 0.5) / 0.5)
	return dying.lerp(fading, fraction / 0.5)


func _draw_ink(canvas: Control) -> void:
	var origin := BAR_MARGIN + Vector2(0, BAR_SIZE.y + 8)
	for i in int(state.max_ink()):
		var at := origin + Vector2((PIP_SIZE.x + PIP_GAP) * i, 0)
		var charged := state.ink >= float(i + 1)
		var partial := clampf(state.ink - float(i), 0.0, 1.0)
		canvas.draw_rect(Rect2(at, PIP_SIZE), Color(0.12, 0.12, 0.18, 0.9))
		if charged:
			canvas.draw_rect(Rect2(at, PIP_SIZE), Color(0.16, 0.10, 0.30))
			canvas.draw_circle(at + PIP_SIZE * 0.5, PIP_SIZE.x * 0.32, Color(0.75, 0.65, 1.0))
		elif partial > 0.0:
			var grown := PIP_SIZE * partial
			canvas.draw_rect(Rect2(at + (PIP_SIZE - grown) * 0.5, grown), Color(0.30, 0.26, 0.45))
		canvas.draw_rect(Rect2(at, PIP_SIZE), Color(0.45, 0.42, 0.60, 0.6), false, 1.0)


func _draw_smother(canvas: Control) -> void:
	var size := Vector2(90, 6)
	var origin := Vector2(canvas.size.x * 0.5 - size.x * 0.5, canvas.size.y - 60)
	canvas.draw_rect(Rect2(origin, size), Color(0.05, 0.05, 0.09, 0.8))
	canvas.draw_rect(Rect2(origin, Vector2(size.x * smother, size.y)), Color(0.9, 0.8, 0.5))
