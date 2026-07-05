class_name ShopMap
extends AreaMap

## General store interior — entered from the market street stall.

const DOORS := {
	Vector2i(10, 12): {"target_area": "town", "target_entry": "EntryFromShop"},
}

const LAYOUT := """
####################
#poqoxppppppppxoqop#
#puppppppppppppppup#
#pppppppppppppppppp#
#pppppnnnnnnnnppppp#
#pppppppppppppppppp#
#pppppppppppppppppp#
#pppppppppppppppppp#
#pppppppppppppppppp#
#ppppppppp1pppppppp#
#pppppppppppppppppp#
#pppppppppppppppppp#
##########D#########
"""


const RESIDENT := {
	"id": "shopkeeper_sana", "type": "shopkeeper", "cell": Vector2i(9, 3),
	"greeting": "Welcome to my store! I'm Sana. Everything a dweller could need!",
	"repeat": "Take your time, look around!",
}


func _layout() -> String:
	return LAYOUT


func _door_table() -> Dictionary:
	return DOORS


func _after_build() -> void:
	_spawn_resident(RESIDENT, "res://assets/character/samurai_green.png")
