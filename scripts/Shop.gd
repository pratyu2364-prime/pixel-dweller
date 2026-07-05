class_name ShopMap
extends AreaMap

## General store interior — entered from the market street stall.

const DOORS := {
	Vector2i(10, 12): {"target_area": "town", "target_entry": "EntryFromShop"},
}

const LAYOUT := """
####################
#pp##pp##pp##pp##pp#
#pppppppppppppppppp#
#pppppppppppppppppp#
#pp####pppp####pppp#
#pppppppppppppppppp#
#pppppppppppppppppp#
#pppppppppppppppppp#
#pppppppppppppppppp#
#ppppppppp1pppppppp#
#pppppppppppppppppp#
#pppppppppppppppppp#
##########D#########
"""


func _layout() -> String:
	return LAYOUT


func _door_table() -> Dictionary:
	return DOORS
