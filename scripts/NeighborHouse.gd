class_name NeighborHouseMap
extends AreaMap

## A neighbor's cozy home in the residential district.

const DOORS := {
	Vector2i(9, 10): {"target_area": "town", "target_entry": "EntryFromNeighborHouse"},
}

const LAYOUT := """
##################
#bloqbbbbbbbbqolb#
#bmmbbbbbbbbbbbub#
#bbbbbbbbbbbbbbbb#
#bbbbbbcnncbbbbbb#
#bbbbbbbnnbbbbbbb#
#bbbbbbcbbcbbbbbb#
#bbbbbbbb1bbbbbbb#
#bbbbbbbbbbbbbbbb#
#bbbbbbbbbbbbbbbb#
#########D########
"""


const RESIDENT := {
	"id": "neighbor_yuki", "type": "villager", "cell": Vector2i(12, 4),
	"greeting": "Oh, a visitor! I'm Yuki, your neighbor. Make yourself at home!",
	"repeat": "Come by any time, neighbor!",
}


func _layout() -> String:
	return LAYOUT


func _door_table() -> Dictionary:
	return DOORS


func _after_build() -> void:
	_spawn_resident(RESIDENT, "res://assets/character/samurai_blue.png")
