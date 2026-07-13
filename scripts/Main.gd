extends Node2D

@onready var area_container: Node2D = $AreaContainer
@onready var fade_rect: ColorRect = $FadeLayer/FadeRect

var area_manager: AreaManager = AreaManager.new()
var _transitioning: bool = false
var _active_npc: Npc = null
var _district_accum: float = 0.0
var _met_npcs: Array = []
var stats: Stats = Stats.new()


func _ready() -> void:
	print("Pixel Dweller booted.")
	_met_npcs = SaveManager.load_met_npcs()
	SaveManager.load_stats(stats)
	$UI.bind_stats(stats)
	stats.changed.connect(_sync_player_stats)
	stats.died.connect(_on_player_defeated)
	var saved_area: String = SaveManager.load_current_area()
	area_manager.load_area(saved_area, "EntryDefault", area_container)
	_connect_area_doors()
	_connect_area_npcs()
	_connect_area_enemies()
	_sync_player_stats()

	if $UI.dweller != null:
		$UI._apply_stage_to_area($UI.dweller.stage)
		$UI.set_area_label(area_manager.current_area)

	$UI.talk_button.pressed.connect(_on_talk_pressed)


func _process(delta: float) -> void:
	_district_accum += delta
	if _district_accum < 0.3:
		return
	_district_accum = 0.0
	_update_district_label()


func _sync_player_stats() -> void:
	var player := area_manager.get_player()
	if player == null:
		return
	player.attack_power = stats.attack
	if not player.damaged.is_connected(_on_player_damaged):
		player.damaged.connect(_on_player_damaged)


func _on_player_damaged(amount: int) -> void:
	stats.take_damage(amount)


## Kid-friendly defeat: no game over — wake up at home with full hearts.
func _on_player_defeated() -> void:
	if _transitioning:
		return
	stats.heal_full()
	_transitioning = true
	_disconnect_area_doors()
	_disconnect_area_npcs()
	$UI.show_dialog("You got dizzy... but you woke up safe at home!")
	_do_fade_transition("house", "EntryDefault")


## In areas with districts (the city), the label tracks where the player walks.
func _update_district_label() -> void:
	if _transitioning:
		return
	var area_node := area_manager.get_current_area_node()
	var player := area_manager.get_player()
	if area_node == null or player == null:
		return
	if area_node.has_method("district_at"):
		$UI.set_area_label_text(area_node.district_at(player.position))


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
			npc.already_met = _met_npcs.has(npc.npc_id)
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


func _connect_area_enemies() -> void:
	var area_node := area_manager.get_current_area_node()
	if area_node == null:
		return
	for child in area_node.get_children():
		if child is Enemy:
			(child as Enemy).defeated.connect(_on_enemy_defeated)


func _on_enemy_defeated(enemy: Enemy) -> void:
	stats.gain_coins(enemy.coin_value)
	if stats.gain_xp(enemy.xp_value):
		$UI.show_dialog("Level up! You feel stronger. Lv %d!" % stats.level)
	$UI._save()


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
	_connect_area_enemies()
	_sync_player_stats()
	_active_npc = null

	if $UI.dweller != null:
		$UI._apply_stage_to_area($UI.dweller.stage)
		$UI.set_area_label(area_manager.current_area)

	_transitioning = false


func _on_npc_greeted(text: String, mood_boost: float) -> void:
	$UI.show_dialog(text)
	if _active_npc != null and not _active_npc.npc_id.is_empty():
		if not _met_npcs.has(_active_npc.npc_id):
			_met_npcs.append(_active_npc.npc_id)
			SaveManager.mark_npc_met(_active_npc.npc_id)
	if mood_boost > 0.0:
		$UI.dweller.refill_need("mood", mood_boost)
		$UI._save()


func _on_npc_range_changed(in_range: bool, npc: Npc) -> void:
	_active_npc = npc if in_range else null
	$UI.set_talk_button_visible(in_range)


func _on_talk_pressed() -> void:
	if _active_npc != null:
		_active_npc.try_greet()
