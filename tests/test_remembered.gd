extends GutTest

## The page of remembered lines is the payoff for going into the light, so it
## has to be honest about what is missing as well as what is found.


func test_a_new_save_shows_every_line_blank() -> void:
	var rows := RememberedScreen.rows(Progress.new())
	assert_eq(rows.size(), Game.DEFAULT_ORDER.size(), "one line per floor")
	for row in rows:
		assert_false(row["found"])
		assert_eq(row["text"], RememberedScreen.UNFOUND)


func test_a_found_memory_shows_its_words() -> void:
	var progress := Progress.new()
	var data := ChamberData.from_file(Game.path_for("cistern"))
	progress.remember(Progress.memory_id("cistern", data.memories[0]["cell"]))
	var found := 0
	for row in RememberedScreen.rows(progress):
		if row["found"]:
			found += 1
			assert_eq(row["text"], String(data.memories[0]["text"]))
	assert_eq(found, 1, "only the one she has")


func test_rows_follow_the_climb_so_blanks_say_where_to_look() -> void:
	var rows := RememberedScreen.rows(Progress.new())
	for i in Game.DEFAULT_ORDER.size():
		assert_eq(rows[i]["floor"], RememberedScreen.floor_name(Game.DEFAULT_ORDER[i]))


func test_the_count_is_plain_about_how_far_along_she_is() -> void:
	var progress := Progress.new()
	assert_string_contains(RememberedScreen.summary(progress), "nothing yet")
	for id in Game.DEFAULT_ORDER:
		var data := ChamberData.from_file(Game.path_for(id))
		progress.remember(Progress.memory_id(id, data.memories[0]["cell"]))
		break
	assert_string_contains(RememberedScreen.summary(progress), "1 of ")


func test_a_complete_save_says_so_without_congratulating_anyone() -> void:
	var progress := Progress.new()
	for id in Game.DEFAULT_ORDER:
		var data := ChamberData.from_file(Game.path_for(id))
		progress.remember(Progress.memory_id(id, data.memories[0]["cell"]))
	assert_eq(RememberedScreen.summary(progress), "all of it, then")


func test_the_page_renders_a_row_per_floor() -> void:
	var page: RememberedScreen = load("res://scenes/Remembered.tscn").instantiate()
	add_child_autofree(page)
	page.present(Progress.new())
	assert_eq(page.get_node("Panel/List").get_child_count(), Game.DEFAULT_ORDER.size())


func test_the_title_screen_can_open_it() -> void:
	var title: TitleScreen = load("res://scenes/Title.tscn").instantiate()
	add_child_autofree(title)
	var page := title.get_node("Remembered")
	assert_not_null(page)
	assert_false(page.visible, "it stays closed until asked for")
	title.get_node("Menu/RememberedButton").pressed.emit()
	assert_true(page.visible)


func test_closing_it_puts_it_away() -> void:
	var page: RememberedScreen = load("res://scenes/Remembered.tscn").instantiate()
	add_child_autofree(page)
	page.visible = true
	watch_signals(page)
	page.get_node("Panel/Back").pressed.emit()
	assert_false(page.visible)
	assert_signal_emitted(page, "closed")
