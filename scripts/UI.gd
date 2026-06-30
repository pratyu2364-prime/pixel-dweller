extends CanvasLayer

const SAVE_PATH := "user://save.json"
const AUTOSAVE_INTERVAL := 5.0

var dweller: Dweller

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
	var last_saved: float = SaveManager.load_into_dweller(dweller, SAVE_PATH)
	if last_saved > 0.0:
		var elapsed: float = TimeManager.elapsed_since(last_saved)
		if elapsed > 0.0:
			dweller.apply_elapsed(elapsed)

	dweller.grew_up.connect(_on_dweller_grew_up)

	_apply_stage_to_area(dweller.stage)
	stage_label.text = _stage_name(dweller.stage)

	eat_button.pressed.connect(_on_eat_pressed)
	rest_button.pressed.connect(_on_rest_pressed)
	play_button.pressed.connect(_on_play_pressed)


func _process(delta: float) -> void:
	dweller.apply_elapsed(delta)
	hunger_bar.value = dweller.hunger
	energy_bar.value = dweller.energy
	mood_bar.value = dweller.mood

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
		_:
			return key.capitalize()


func set_area_label(area_name: String) -> void:
	area_label.text = pretty_area_name(area_name)


func show_dialog(text: String) -> void:
	dialog_label.text = text
	dialog_label.visible = true
	dialog_timer.start()


func set_talk_button_visible(visible: bool) -> void:
	talk_button.visible = visible


func _on_dialog_timer_timeout() -> void:
	dialog_label.visible = false
