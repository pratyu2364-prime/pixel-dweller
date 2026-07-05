extends GutTest

const TEST_PATH := "user://test_stats_save.json"


func after_each() -> void:
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(TEST_PATH)


func test_xp_curve_grows() -> void:
	assert_eq(Stats.xp_for_next(1), 10)
	assert_eq(Stats.xp_for_next(2), 40)
	assert_eq(Stats.xp_for_next(3), 90)


func test_damage_floor_is_one() -> void:
	assert_eq(Stats.damage_taken(5, 2), 3)
	assert_eq(Stats.damage_taken(2, 10), 1, "armor never blocks fully")


func test_hearts_display() -> void:
	assert_eq(Stats.hearts(6, 6), ["full", "full", "full"] as Array[String])
	assert_eq(Stats.hearts(3, 6), ["full", "half", "empty"] as Array[String])
	assert_eq(Stats.hearts(0, 6), ["empty", "empty", "empty"] as Array[String])


func test_take_damage_and_death_signal() -> void:
	var s := Stats.new()
	watch_signals(s)
	s.take_damage(3)
	assert_eq(s.hp, 3)
	assert_signal_not_emitted(s, "died")
	s.take_damage(99)
	assert_eq(s.hp, 0)
	assert_signal_emitted(s, "died")


func test_gain_xp_levels_up_and_refills() -> void:
	var s := Stats.new()
	s.take_damage(2)
	var leveled := s.gain_xp(10)
	assert_true(leveled, "10 xp reaches level 2")
	assert_eq(s.level, 2)
	assert_eq(s.max_hp, 8)
	assert_eq(s.hp, 8, "level up refills hearts")
	assert_eq(s.attack, 2)
	assert_eq(s.xp, 0, "xp consumed by threshold")


func test_gain_xp_multi_level() -> void:
	var s := Stats.new()
	s.gain_xp(50)
	assert_eq(s.level, 3, "10+40 consumed")
	assert_eq(s.xp, 0)


func test_stats_save_round_trip_preserves_other_keys() -> void:
	SaveManager.mark_npc_met("someone", TEST_PATH)
	var s := Stats.new()
	s.coins = 42
	s.take_damage(1)
	s.gain_xp(10)
	SaveManager.save_stats(s, TEST_PATH)

	var loaded := Stats.new()
	SaveManager.load_stats(loaded, TEST_PATH)
	assert_eq(loaded.coins, 42)
	assert_eq(loaded.level, 2)
	assert_eq(loaded.hp, loaded.max_hp)
	assert_has(SaveManager.load_met_npcs(TEST_PATH), "someone", "met_npcs preserved")
