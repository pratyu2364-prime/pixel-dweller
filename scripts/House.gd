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
#bb##bb##bbbbbbbbbbbbbbbbbbb##pp##pp####
#bbbbbbbbbbbbbbbbbbbbbbbbbbbppppppppp###
#bbbbbbbbbbbbbbbbbbbbbbbbbbbppppppppp###
#bb####bbbbbbbbbbbbbbbbbbbbbpp####ppp###
#bb####bbbbbbbbbbbbbbbbbbbbbpp####ppp###
#bbbbbbbbbbbbbbbbbbbbbbbbbbbppppppppp###
#bbbbbbbbbbbbbbbbbbbbbbbbbbbppppppppp###
#bbbbbbbbbpppppppbbbbbbbbbbbbbbbbbbbb###
#bbbbbbbbbpppppppbbbbbbbbbbbbbbbbbbbb###
#bbbbbbbbbpppppppbbbbbbbbbbbbbbbbbbbb###
#bbbbbbbbbpppppppbbbbbbbbbb####bbbbbb###
#bbbbbbbbbbbbbbbbbbbbbbbbbb####bbbbbb###
#bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb###
#bb####bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb###
#bb####bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb###
#bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb###
#bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb###
#bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb###
#bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb###
#bbbbbbbbbbbbbbbbbbb1bbbbbbbbbbbbbbbb###
#bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb###
#bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb###
####################D###################
"""


func _layout() -> String:
	return LAYOUT


func _door_table() -> Dictionary:
	return DOORS


func _entry_aliases() -> Dictionary:
	return ENTRY_ALIASES
