extends GutTest

## Loot: defeated enemies pay out coins + xp; levels grant power; persisted.

const TEST_PATH := "user://test_loot_save.json"
const UIScript := preload("res://scripts/UI.gd")

var _changed_count := 0


func after_each() -> void:
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(TEST_PATH)
	_changed_count = 0


func _count_changed() -> void:
	_changed_count += 1


func test_gain_coins_adds_and_signals() -> void:
	var stats := Stats.new()
	stats.changed.connect(_count_changed)
	stats.gain_coins(7)
	assert_eq(stats.coins, 7, "coins added")
	assert_eq(_changed_count, 1, "changed emitted")


func test_defeated_enemy_pays_out() -> void:
	var stats := Stats.new()
	var enemy: Enemy = preload("res://scenes/Enemy.tscn").instantiate()
	add_child_autofree(enemy)
	enemy.defeated.connect(func(e: Enemy) -> void:
		stats.gain_coins(e.coin_value)
		stats.gain_xp(e.xp_value)
	)

	enemy.take_hit(enemy.max_hp, enemy.global_position + Vector2.LEFT)

	assert_eq(stats.coins, enemy.coin_value, "coins dropped")
	assert_eq(stats.xp, enemy.xp_value, "xp granted")


func test_level_up_grants_power_and_refills() -> void:
	var stats := Stats.new()
	stats.take_damage(3)
	var leveled := stats.gain_xp(Stats.xp_for_next(1))
	assert_true(leveled, "leveled up")
	assert_eq(stats.level, 2, "level 2")
	assert_eq(stats.max_hp, Stats.BASE_MAX_HP + 2, "extra heart")
	assert_eq(stats.attack, Stats.BASE_ATTACK + 1, "stronger sword")
	assert_eq(stats.hp, stats.max_hp, "hearts refilled")


func test_loot_text_readout() -> void:
	assert_eq(UIScript.loot_text(1, 0, 0), "Lv 1   XP 0/10   Coins 0")
	assert_eq(UIScript.loot_text(3, 42, 15), "Lv 3   XP 42/90   Coins 15")


func test_loot_persists_across_save_load() -> void:
	var stats := Stats.new()
	stats.gain_coins(12)
	stats.gain_xp(25)
	SaveManager.save_stats(stats, TEST_PATH)

	var loaded := Stats.new()
	SaveManager.load_stats(loaded, TEST_PATH)
	assert_eq(loaded.coins, 12, "coins persist")
	assert_eq(loaded.xp, stats.xp, "xp persists")
	assert_eq(loaded.level, stats.level, "level persists")
	assert_eq(loaded.max_hp, stats.max_hp, "max_hp persists")
