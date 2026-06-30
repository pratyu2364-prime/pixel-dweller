extends Node2D

@onready var area_container: Node2D = $AreaContainer

var area_manager: AreaManager = AreaManager.new()


func _ready() -> void:
	print("Pixel Dweller booted.")
	var saved_area: String = SaveManager.load_current_area()
	area_manager.load_area(saved_area, "EntryDefault", area_container)
