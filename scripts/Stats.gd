class_name Stats
extends RefCounted

## Player combat stats. Pure logic — unit-testable without a scene tree.
## 1 heart = 2 hp (half-heart granularity, Zelda-style).

signal changed
signal died

const BASE_MAX_HP := 6
const BASE_ATTACK := 1

## Gear tiers sold by the shop. Buying the next tier swaps the flat bonus.
const SWORD_TIERS := [
	{"name": "Wooden Sword", "bonus": 0, "cost": 0},
	{"name": "Iron Sword", "bonus": 2, "cost": 30},
	{"name": "Hero Sword", "bonus": 5, "cost": 100},
]
const ARMOR_TIERS := [
	{"name": "Play Clothes", "bonus": 0, "cost": 0},
	{"name": "Leather Vest", "bonus": 1, "cost": 25},
	{"name": "Knight Armor", "bonus": 3, "cost": 80},
]

var max_hp: int = BASE_MAX_HP
var hp: int = BASE_MAX_HP
var attack: int = BASE_ATTACK
var defense: int = 0
var coins: int = 0
var xp: int = 0
var level: int = 1
var sword_tier: int = 0
var armor_tier: int = 0


## Pure: cumulative xp needed to reach the NEXT level from `level`.
static func xp_for_next(level_now: int) -> int:
	return 10 * level_now * level_now


## Pure: damage after armor. Always at least 1 so fights can't stall.
static func damage_taken(raw: int, defense_now: int) -> int:
	return maxi(1, raw - defense_now)


## Pure: per-heart display state for max_hp/2 hearts.
static func hearts(hp_now: int, max_hp_now: int) -> Array[String]:
	var out: Array[String] = []
	for i in range(0, max_hp_now, 2):
		var left := hp_now - i
		if left >= 2:
			out.append("full")
		elif left == 1:
			out.append("half")
		else:
			out.append("empty")
	return out


func take_damage(raw: int) -> int:
	var dmg := damage_taken(raw, defense)
	hp = maxi(0, hp - dmg)
	changed.emit()
	if hp == 0:
		died.emit()
	return dmg


func heal_full() -> void:
	hp = max_hp
	changed.emit()


## Pure: next tier for sale, or {} when maxed out.
static func next_tier(tiers: Array, tier_now: int) -> Dictionary:
	return {} if tier_now + 1 >= tiers.size() else tiers[tier_now + 1]


## Pure: can the purse afford the next tier?
static func can_afford(tiers: Array, tier_now: int, purse: int) -> bool:
	var offer := next_tier(tiers, tier_now)
	return not offer.is_empty() and purse >= int(offer["cost"])


func buy_sword() -> bool:
	if not can_afford(SWORD_TIERS, sword_tier, coins):
		return false
	var offer := next_tier(SWORD_TIERS, sword_tier)
	coins -= int(offer["cost"])
	attack += int(offer["bonus"]) - int(SWORD_TIERS[sword_tier]["bonus"])
	sword_tier += 1
	changed.emit()
	return true


func buy_armor() -> bool:
	if not can_afford(ARMOR_TIERS, armor_tier, coins):
		return false
	var offer := next_tier(ARMOR_TIERS, armor_tier)
	coins -= int(offer["cost"])
	defense += int(offer["bonus"]) - int(ARMOR_TIERS[armor_tier]["bonus"])
	armor_tier += 1
	changed.emit()
	return true


func gain_coins(amount: int) -> void:
	coins += amount
	changed.emit()


## Returns true if at least one level was gained. Leveling refills hearts.
func gain_xp(amount: int) -> bool:
	xp += amount
	var leveled := false
	while xp >= xp_for_next(level):
		xp -= xp_for_next(level)
		level += 1
		max_hp += 2
		attack += 1
		hp = max_hp
		leveled = true
	changed.emit()
	return leveled


func to_dict() -> Dictionary:
	return {
		"max_hp": max_hp, "hp": hp, "attack": attack, "defense": defense,
		"coins": coins, "xp": xp, "level": level,
		"sword_tier": sword_tier, "armor_tier": armor_tier,
	}


func from_dict(data: Dictionary) -> void:
	max_hp = int(data.get("max_hp", BASE_MAX_HP))
	hp = int(data.get("hp", max_hp))
	attack = int(data.get("attack", BASE_ATTACK))
	defense = int(data.get("defense", 0))
	coins = int(data.get("coins", 0))
	xp = int(data.get("xp", 0))
	level = int(data.get("level", 1))
	sword_tier = int(data.get("sword_tier", 0))
	armor_tier = int(data.get("armor_tier", 0))
	changed.emit()
