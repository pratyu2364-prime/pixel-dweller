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

var _autosave_timer: float = 0.0


func _ready() -> void:
	dweller = Dweller.new()
	var last_saved: float = SaveManager.load_into_dweller(dweller, SAVE_PATH)
	if last_saved > 0.0:
		var elapsed: float = TimeManager.elapsed_since(last_saved)
		if elapsed > 0.0:
			dweller.apply_elapsed(elapsed)

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
	SaveManager.save_dweller(dweller, SAVE_PATH)
