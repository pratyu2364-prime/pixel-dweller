extends GutTest

## The briefing is the only place the game explains itself in words, so it has
## to stay in step with the verbs the game actually binds.


func before_each() -> void:
	get_tree().paused = false


func after_each() -> void:
	get_tree().paused = false


func test_every_verb_is_explained() -> void:
	var text := " ".join(HowToPlayScreen.all_lines()).to_lower()
	for verb in ["move", "cast", "cling", "space", "wasd", "ink", "coherence"]:
		assert_string_contains(text, verb)


func test_it_opens_on_the_first_card() -> void:
	var page: HowToPlayScreen = load("res://scenes/HowToPlay.tscn").instantiate()
	add_child_autofree(page)
	page.show_page(2)
	page.present()
	assert_eq(page.page_index(), 0)
	assert_true(page.visible)


func test_paging_stops_at_both_ends() -> void:
	var page: HowToPlayScreen = load("res://scenes/HowToPlay.tscn").instantiate()
	add_child_autofree(page)
	page.turn(-1)
	assert_eq(page.page_index(), 0, "no wrap backwards off the first card")
	for i in HowToPlayScreen.PAGES.size() + 3:
		page.turn(1)
	assert_eq(page.page_index(), HowToPlayScreen.PAGES.size() - 1)


func test_each_card_renders_its_lines() -> void:
	var page: HowToPlayScreen = load("res://scenes/HowToPlay.tscn").instantiate()
	add_child_autofree(page)
	for i in HowToPlayScreen.PAGES.size():
		page.show_page(i)
		assert_eq(page.get_node("Panel/Heading").text, String(HowToPlayScreen.PAGES[i]["title"]))
		assert_string_contains(page.get_node("Panel/Dots").text, "%d /" % (i + 1))


func test_done_puts_it_away() -> void:
	var page: HowToPlayScreen = load("res://scenes/HowToPlay.tscn").instantiate()
	add_child_autofree(page)
	page.present()
	watch_signals(page)
	page.get_node("Panel/Done").pressed.emit()
	assert_false(page.visible)
	assert_signal_emitted(page, "closed")


func test_the_title_screen_can_open_it() -> void:
	var title: TitleScreen = load("res://scenes/Title.tscn").instantiate()
	add_child_autofree(title)
	var page := title.get_node("HowToPlay")
	assert_false(page.visible, "closed until asked for")
	title.get_node("Menu/HowToPlayButton").pressed.emit()
	assert_true(page.visible)


func test_the_pause_menu_can_open_it_mid_floor() -> void:
	var menu := PauseMenu.new()
	add_child_autofree(menu)
	menu.open()
	for button in menu.get_child(0).get_child(1).get_children():
		if button.text == "how to play":
			button.pressed.emit()
	var page := menu.get_child(0).get_node_or_null("HowToPlay")
	assert_not_null(page, "the briefing is reachable without leaving the floor")
	assert_true(page.visible)
	menu.close()
