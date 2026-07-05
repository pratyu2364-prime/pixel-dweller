class_name NeighborHouseMap
extends AreaMap

## A neighbor's cozy home in the residential district.

const DOORS := {
	Vector2i(9, 10): {"target_area": "town", "target_entry": "EntryFromNeighborHouse"},
}

const LAYOUT := """
##################
#....##....##....#
#................#
#..ff........ff..#
#................#
#......####......#
#......####......#
#........1.......#
#................#
#................#
#########D########
"""


func _layout() -> String:
	return LAYOUT


func _door_table() -> Dictionary:
	return DOORS
