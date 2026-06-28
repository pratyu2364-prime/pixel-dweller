extends GutTest


func test_title_instantiates_and_has_begin_button() -> void:
	var title := preload("res://scenes/Title.tscn").instantiate()
	add_child_autofree(title)
	await get_tree().process_frame

	var begin := title.get_node_or_null("Center/VBox/Begin")
	assert_not_null(begin, "Title should have a Begin button")
	assert_true(begin is Button, "Begin should be a Button")


func test_settings_instantiates_and_has_sound_toggle() -> void:
	var settings := preload("res://scenes/Settings.tscn").instantiate()
	add_child_autofree(settings)
	await get_tree().process_frame

	var toggle := settings.get_node_or_null("Center/VBox/SoundToggle")
	assert_not_null(toggle, "Settings should have a SoundToggle")
	assert_true(toggle is Button, "SoundToggle should be a Button")


func test_settings_credits_label_exists() -> void:
	var settings := preload("res://scenes/Settings.tscn").instantiate()
	add_child_autofree(settings)
	await get_tree().process_frame

	var credits := settings.get_node_or_null("Center/VBox/CreditsLabel")
	assert_not_null(credits, "Settings should have CreditsLabel")
	assert_true(credits is Label, "CreditsLabel should be a Label")
	var label := credits as Label
	assert_true(label.text.find("Kenney") != -1, "Credits label should mention Kenney")
