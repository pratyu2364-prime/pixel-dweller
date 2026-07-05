class_name HouseMap
extends AreaMap

## The dweller's home — a cozy tiled room instead of the old bare green box.
## 'b' renders as warm wood (bridge tile), 'p' as pale kitchen tile.

const DOORS := {
	Vector2i(20, 23): {"target_area": "garden", "target_entry": "EntryFromHouse"},
}

const ENTRY_ALIASES := {
	"Entry1": "EntryFromGarden",
}

const LAYOUT := """
########################################
#bloqoqobbbbbbbbbbbbbbbbbbbbppppppppplb#
#bbbbbbbbbbbbbbbbbbbbbbbbbbbpxunuxppppb#
#bbbbbbbbbbbbbbbbbbbbbbbbbbbppppppppppb#
#bbbbbbbbbbbbbbbbbbbbbbbbbbbppppppppppb#
#bbbbbbbbbbbbbbbbbbbbbbbbbbbppppppppppb#
#bbbbbbbbbbbbbbbbbbbbbbbbbbbppppppppppb#
#bbbbbbbbbbbbbbbbbbbbbbbbbbbppppppppppb#
#bbbmmbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb#
#bbbccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb#
#bbbbbbbbbbbbbbbbcnnncbbbbbbbbbbbbbbbbb#
#bbbbbbbbbbbbbbbbcnnncbbbbbbbbbbbbbbbbb#
#bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb#
#bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb#
#bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb#
#bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb#
#bubbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbub#
#bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb#
#bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb#
#bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb#
#bbbbbbbbbbbbbbbbbbb1bbbbbbbbbbbbbbbbbb#
#bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb#
#bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb#
####################D###################
"""


func _layout() -> String:
	return LAYOUT


func _door_table() -> Dictionary:
	return DOORS


func _entry_aliases() -> Dictionary:
	return ENTRY_ALIASES
