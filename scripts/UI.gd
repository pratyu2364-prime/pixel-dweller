extends CanvasLayer

const SAVE_PATH := "user://save.json"
const AUTOSAVE_INTERVAL := 5.0

const HEART_TEXTURES := {
	"full": preload("res://assets/ui/heart.png"),
	"half": preload("res://assets/ui/heart_2.png"),
	"empty": preload("res://assets/ui/heart_3.png"),
}

var dweller: Dweller
var stats: Stats

@onready var hearts_row: HBoxContainer = $Margin/VBox/HeartsRow
@onready var hunger_bar: ProgressBar = $Margin/VBox/HungerBar
@onready var energy_bar: ProgressBar = $Margin/VBox/EnergyBar
@onready var mood_bar: ProgressBar = $Margin/VBox/MoodBar
@onready var eat_button: Button = $Margin/VBox/Buttons/Eat
@onready var rest_button: Button = $Margin/VBox/Buttons/Rest
@onready var play_button: Button = $Margin/VBox/Buttons/Play
@onready var stage_label: Label = $Margin/VBox/StageLabel
@onready var area_label: Label = $Margin/VBox/AreaLabel
@onready var dialog_label: Label = $Margin/VBox/DialogLabel
@onready var talk_button: Button = $Margin/VBox/Buttons/Talk
@onready var dialog_timer: Timer = $DialogTimer

var _autosave_timer: float = 0.0


func _ready() -> void:
	dialog_timer.timeout.connect(_on_dialog_timer_timeout)
	dweller = Dweller.new()
	# Care sim is paused (explorer pivot): no offline decay applied on boot.
	SaveManager.load_into_dweller(dweller, SAVE_PATH)

	dweller.grew_up.connect(_on_dweller_grew_up)

	_apply_stage_to_area(dweller.stage)
	stage_label.text = _stage_name(dweller.stage)

	eat_button.pressed.connect(_on_eat_pressed)
	rest_button.pressed.connect(_on_rest_pressed)
	play_button.pressed.connect(_on_play_pressed)


func _process(delta: float) -> void:
	_autosave_timer += delta
	if _autosave_timer >= AUTOSAVE_INTERVAL:
		_autosave_timer = 0.0
		_save()


func _on_eat_pressed() -> void:
	dweller.refill_need("hunger", 30)
	_save()


func _on_rest_pressed() -> void:
	dweller.refill_need("energy", 30)
	_save()


func _on_play_pressed() -> void:
	dweller.refill_need("mood", 30)
	_save()


func _save() -> void:
	var main := get_node("..") as Node
	var area_manager: AreaManager = main.area_manager as AreaManager
	SaveManager.save_dweller(dweller, SAVE_PATH, area_manager.current_area)
	if stats != null:
		SaveManager.save_stats(stats, SAVE_PATH)


## Hearts HUD ------------------------------------------------------------

func bind_stats(new_stats: Stats) -> void:
	stats = new_stats
	stats.changed.connect(_refresh_hearts)
	_refresh_hearts()


func _refresh_hearts() -> void:
	if hearts_row == null or stats == null:
		return
	for child in hearts_row.get_children():
		child.queue_free()
	for state: String in Stats.hearts(stats.hp, stats.max_hp):
		var rect := TextureRect.new()
		rect.texture = HEART_TEXTURES[state]
		rect.custom_minimum_size = Vector2(32, 32)
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		hearts_row.add_child(rect)


func _on_dweller_grew_up(new_stage: int) -> void:
	_apply_stage_to_area(new_stage)
	stage_label.text = _stage_name(new_stage)


func _apply_stage_to_area(stage: int) -> void:
	var main := get_node("..") as Node
	var area_manager: AreaManager = main.area_manager as AreaManager
	var area_node: Node2D = area_manager.get_current_area_node()
	if area_node != null and area_node.has_method("apply_world_stage"):
		area_node.apply_world_stage(stage)


func _stage_name(stage: int) -> String:
	match stage:
		Dweller.Stage.BABY:
			return "Baby"
		Dweller.Stage.KID:
			return "Kid"
		Dweller.Stage.ADULT:
			return "Adult"
		_:
			return ""


static func pretty_area_name(key: String) -> String:
	match key:
		"house":
			return "House"
		"garden":
			return "Garden"
		"town":
			return "Town"
		"woods":
			return "Whispering Woods"
		_:
			return key.capitalize()


func set_area_label(area_name: String) -> void:
	area_label.text = pretty_area_name(area_name)


## Raw text, no key prettifying — used for city district names.
func set_area_label_text(text: String) -> void:
	area_label.text = text


func show_dialog(text: String) -> void:
	dialog_label.text = text
	dialog_label.visible = true
	dialog_timer.start()


func set_talk_button_visible(visible: bool) -> void:
	talk_button.visible = visible


func _on_dialog_timer_timeout() -> void:
	dialog_label.visible = false
