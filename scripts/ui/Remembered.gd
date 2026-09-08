class_name RememberedScreen
extends Control

## What she has remembered, in the order she found it — and blanks for what she
## has not. The blanks are the point: a player who has five of eight lines can
## see there are three more and roughly where they were.

signal closed

const UNFOUND := "— — —"


## One row per floor in climb order: the floor's name, and either the memory's
## line or a blank. Static and pure, so the whole page can be asserted.
static func rows(progress: Progress) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id in Game.DEFAULT_ORDER:
		var data := ChamberData.from_file(Game.path_for(id))
		if data.memories.is_empty():
			continue
		var cell: Vector2i = data.memories[0]["cell"]
		var found := progress.has_memory(Progress.memory_id(id, cell))
		out.append(
			{
				"floor": RememberedScreen.floor_name(id),
				"found": found,
				"text": String(data.memories[0]["text"]) if found else UNFOUND,
			}
		)
	return out


static func floor_name(id: String) -> String:
	return String(TitleScreen.FLOOR_NAMES.get(id, id))


static func summary(progress: Progress) -> String:
	var total := 0
	var found := 0
	for row in RememberedScreen.rows(progress):
		total += 1
		if row["found"]:
			found += 1
	if found == 0:
		return "nothing yet. it is all still down there"
	if found == total:
		return "all of it, then"
	return "%d of %d" % [found, total]


func present(progress: Progress) -> void:
	var list: VBoxContainer = $Panel/List
	for child in list.get_children():
		child.queue_free()
	for row in RememberedScreen.rows(progress):
		list.add_child(_row_label(row))
	$Panel/Count.text = RememberedScreen.summary(progress)


func _row_label(row: Dictionary) -> Label:
	var label := Label.new()
	label.text = "%s   %s" % [row["floor"], row["text"]]
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var found: bool = row["found"]
	label.add_theme_color_override(
		"font_color",
		Color(0.82, 0.84, 1.0, 0.9) if found else Color(0.45, 0.47, 0.6, 0.55)
	)
	return label


func _ready() -> void:
	$Panel/Back.pressed.connect(func() -> void:
		visible = false
		closed.emit()
	)
