extends GutTest

## Shop upgrades: Sana sells sword/armor tiers for coins; equip changes
## attack/defense; tiers persist.

const TEST_PATH := "user://test_shop_save.json"
const UIScript := preload("res://scripts/UI.gd")


func after_each() -> void:
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(TEST_PATH)


func test_next_tier_and_maxed() -> void:
	assert_eq(Stats.next_tier(Stats.SWORD_TIERS, 0)["name"], "Iron Sword")
	assert_eq(Stats.next_tier(Stats.SWORD_TIERS, Stats.SWORD_TIERS.size() - 1), {}, "maxed = no offer")


func test_cannot_buy_without_coins() -> void:
	var stats := Stats.new()
	assert_false(stats.buy_sword(), "broke = no sale")
	assert_eq(stats.sword_tier, 0, "tier unchanged")
	assert_eq(stats.attack, Stats.BASE_ATTACK, "attack unchanged")


func test_buy_sword_raises_attack_and_spends() -> void:
	var stats := Stats.new()
	stats.gain_coins(30)
	assert_true(stats.buy_sword(), "sale goes through")
	assert_eq(stats.sword_tier, 1, "iron sword owned")
	assert_eq(stats.coins, 0, "coins spent")
	assert_eq(stats.attack, Stats.BASE_ATTACK + 2, "iron bonus applied")


func test_buy_armor_raises_defense() -> void:
	var stats := Stats.new()
	stats.gain_coins(25)
	assert_true(stats.buy_armor(), "sale goes through")
	assert_eq(stats.defense, 1, "leather vest bonus")
	assert_eq(stats.damage_taken(3, stats.defense), 2, "hits softened")


func test_tier_swap_replaces_bonus_not_stacks() -> void:
	var stats := Stats.new()
	stats.gain_coins(130)
	stats.buy_sword()
	stats.buy_sword()
	assert_eq(stats.sword_tier, 2, "hero sword owned")
	assert_eq(stats.attack, Stats.BASE_ATTACK + 5, "hero bonus replaces iron bonus")
	assert_false(stats.buy_sword(), "maxed = no further sale")


func test_gear_persists_across_save_load() -> void:
	var stats := Stats.new()
	stats.gain_coins(55)
	stats.buy_sword()
	stats.buy_armor()
	SaveManager.save_stats(stats, TEST_PATH)

	var loaded := Stats.new()
	SaveManager.load_stats(loaded, TEST_PATH)
	assert_eq(loaded.sword_tier, 1, "sword tier persists")
	assert_eq(loaded.armor_tier, 1, "armor tier persists")
	assert_eq(loaded.attack, stats.attack, "attack persists")
	assert_eq(loaded.defense, stats.defense, "defense persists")


func test_offer_label_states() -> void:
	assert_eq(UIScript.offer_label("Sword", Stats.SWORD_TIERS, 0), "Iron Sword  30c")
	assert_eq(UIScript.offer_label("Sword", Stats.SWORD_TIERS, 2), "Sword: Best!")


func test_sana_is_a_shopkeeper() -> void:
	assert_eq(ShopMap.RESIDENT["type"], "shopkeeper", "shop buttons trigger off Sana")
