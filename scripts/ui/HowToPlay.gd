class_name HowToPlayScreen
extends Control

## The briefing. PENUMBRA teaches its rule by killing you in the first room,
## which is fine for a player who chose that — but the game is a link someone
## opens once, so there has to be a page that says what the shadow can do
## before it says what the light does.
##
## The pages are static data rather than scene text so a test can assert that
## every verb the game binds is actually explained somewhere.

signal closed

## One card per idea, in the order a new player needs them: what kills you,
## what you can do about it, and what the meters on screen are saying.
const PAGES: Array[Dictionary] = [
	{
		"title": "the one rule",
		"lines": [
			"you are a shadow. light unmakes you.",
			"in shade you are safe. in glare your coherence drains —",
			"that meter is your health, your stamina and your clock at once.",
			"empty it and you scatter, and reform in the last shade you could have reached.",
			"nothing else in this game can hurt you.",
		],
	},
	{
		"title": "three verbs",
		"lines": [
			"move · WASD or the arrows · on a phone, the left half is a thumbstick",
			"cast · space · throw a puff of dark that bridges a lit floor for a moment",
			"cling · hold E · lift a candle, turn a mirror, or lean on a brazier until it gives",
			"casting costs ink, and ink comes back only in deep shade.",
			"hide, charge, sprint the light, hide. that is the whole loop.",
		],
	},
	{
		"title": "what to watch",
		"lines": [
			"the pale bar is coherence. the small pips beside it are ink.",
			"lamps orbit, beams sweep, and wardens notice a shadow that is not theirs.",
			"a room is never a trap: every floor is proved winnable without ever standing in light.",
			"the drifting motes mark deep shade — that is where ink returns.",
			"escape pauses. any floor can be started over from there.",
		],
	},
]

var _page: int = 0


## Every line of the briefing, flat — the honest thing to search when asking
## whether a mechanic is explained at all.
static func all_lines() -> PackedStringArray:
	var out := PackedStringArray()
	for page in PAGES:
		for line in page["lines"]:
			out.append(String(line))
	return out


func _ready() -> void:
	$Panel/Nav/Next.pressed.connect(func() -> void: turn(1))
	$Panel/Nav/Back.pressed.connect(func() -> void: turn(-1))
	$Panel/Done.pressed.connect(func() -> void:
		visible = false
		closed.emit()
	)
	show_page(0)


func page_index() -> int:
	return _page


## Turning past either end is a no-op rather than a wrap, so the last press on
## the last card does not silently dump you back at the beginning.
func turn(step: int) -> void:
	show_page(clampi(_page + step, 0, PAGES.size() - 1))


func show_page(index: int) -> void:
	_page = clampi(index, 0, PAGES.size() - 1)
	var page: Dictionary = PAGES[_page]
	$Panel/Heading.text = String(page["title"])
	$Panel/Dots.text = "%d / %d" % [_page + 1, PAGES.size()]
	var list: VBoxContainer = $Panel/List
	for child in list.get_children():
		child.queue_free()
	for line in page["lines"]:
		list.add_child(_line_label(String(line)))
	$Panel/Nav/Back.disabled = _page == 0
	$Panel/Nav/Next.disabled = _page == PAGES.size() - 1


func _line_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", Color(0.8, 0.82, 1.0, 0.88))
	return label


## Opens at the first card, because someone re-reading the briefing is almost
## always re-reading it from the start.
func present() -> void:
	show_page(0)
	visible = true
