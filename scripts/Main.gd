extends Node2D

@onready var area_container: Node2D = $AreaContainer
@onready var fade_rect: ColorRect = $FadeLayer/FadeRect

var area_manager: AreaManager = AreaManager.new()
var _transitioning: bool = false
var _active_npc: Npc = null


func _ready() -> void:
	print("Pixel Dweller booted.")
	var saved_area: String = SaveManager.load_current_area()
	area_manager.load_area(saved_area, "EntryDefault", area_container)
	_connect_area_doors()
	_connect_area_npcs()

	if $UI.dweller != null:
		$UI._apply_stage_to_area($UI.dweller.stage)
		$UI.set_area_label(area_manager.current_area)

	$UI.talk_button.pressed.connect(_on_talk_pressed)


func _connect_area_doors() -> void:
	var area_node := area_manager.get_current_area_node()
	if area_node == null:
		return
	for child in area_node.get_children():
		if child is Door:
			(child as Door).requested_transition.connect(_on_door_triggered)


func _disconnect_area_doors() -> void:
	var area_node := area_manager.get_current_area_node()
	if area_node == null:
		return
	for child in area_node.get_children():
		if child is Door:
			if (child as Door).requested_transition.is_connected(_on_door_triggered):
				(child as Door).requested_transition.disconnect(_on_door_triggered)


func _connect_area_npcs() -> void:
	var area_node := area_manager.get_current_area_node()
	if area_node == null:
		return
	for child in area_node.get_children():
		if child is Npc:
			var npc := child as Npc
			npc.greeted.connect(_on_npc_greeted)
			npc.range_changed.connect(_on_npc_range_changed)


func _disconnect_area_npcs() -> void:
	var area_node := area_manager.get_current_area_node()
	if area_node == null:
		return
	for child in area_node.get_children():
		if child is Npc:
			var npc := child as Npc
			if npc.greeted.is_connected(_on_npc_greeted):
				npc.greeted.disconnect(_on_npc_greeted)
			if npc.range_changed.is_connected(_on_npc_range_changed):
				npc.range_changed.disconnect(_on_npc_range_changed)


func _on_door_triggered(target_area: String, target_entry: String) -> void:
	if _transitioning:
		return
	_transitioning = true
	_disconnect_area_doors()
	_disconnect_area_npcs()
	_do_fade_transition(target_area, target_entry)


func _do_fade_transition(target_area: String, target_entry: String) -> void:
	fade_rect.modulate.a = 0.0
	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP

	var tween := create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, 0.15)
	tween.tween_callback(_finish_transition.bind(target_area, target_entry))
	tween.tween_property(fade_rect, "modulate:a", 0.0, 0.15)
	tween.tween_callback(func():
		fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	)


func _finish_transition(target_area: String, target_entry: String) -> void:
	SaveManager.save_dweller($UI.dweller, "user://save.json", target_area)
	area_manager.load_area(target_area, target_entry, area_container)
	_connect_area_doors()
	_connect_area_npcs()
	_active_npc = null

	if $UI.dweller != null:
		$UI._apply_stage_to_area($UI.dweller.stage)
		$UI.set_area_label(area_manager.current_area)

	_transitioning = false


func _on_npc_greeted(text: String, mood_boost: float) -> void:
	$UI.show_dialog(text)
	if mood_boost > 0.0:
		$UI.dweller.refill_need("mood", mood_boost)
		$UI._save()


func _on_npc_range_changed(in_range: bool, npc: Npc) -> void:
	_active_npc = npc if in_range else null
	$UI.set_talk_button_visible(in_range)


func _on_talk_pressed() -> void:
	if _active_npc != null:
		_active_npc.try_greet()
