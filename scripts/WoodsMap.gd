class_name WoodsMap
extends AreaMap

## Whispering Woods — the danger area north of the East Orchard. The only
## place enemies live; town stays safe. Slimes spawn on 'e' cells.

const SLIME_SCENE := "res://scenes/Enemy.tscn"

## Door cells ('D' in LAYOUT) -> transition wiring.
const DOORS := {
	Vector2i(19, 33): {"target_area": "town", "target_entry": "EntryFromWoods"},
}

const ENTRY_ALIASES := {
	"Entry1": "EntryFromTown",
}

const LAYOUT := """
################################################
#tttttttttttttttttttttttttttttttttttttttttttttt#
#tt..t,..t..tt.,..t...tt..,t...t..t,..t..t.,.tt#
#t..,......e.......,..........e........,.....t.#
#t....t..t...t..t....t..t...t...,t..t...t..t..t#
#tt.,.....,.....................,.........,.tt.#
#t...t..,....t...ffff....,....t.....t..,....t.t#
#t.t.......t....f,..,f.......t....,......t...tt#
#tt...,.e.......f....f...e.....,........e....t.#
#t..t......t..,..ffff......t......t...t....,.tt#
#t....,t........................,.........t..t.#
#t.t......t...,....t..t..,t..........t,......tt#
#tt...t.....e...............,...e.....t...t..t.#
#t.,....t.......,t...t..........t.....,....t.tt#
#t...t.....t..........,....t.......t.....,..tt.#
#tt....,......t...rrr........,..t.......t....t.#
#t..t.....,t......rrr...t..........,t......,.tt#
#t....t.......e...rrr........e..........t....t.#
#t.,......t.......rrr..,........t...,......t.tt#
#tt...t........t..rrr.......t........t..,....t.#
#t......,t........rrr...........,t.........t.tt#
#t..t........t....rrr....t..............t....t.#
#t....,..t........rrr........,..t...t......,.tt#
#tt.......e..t....rrr..t...e...........t.....t.#
#t..t,.........t..rrr.........,....t......t.tt.#
#t......t.........rrr....,t.........,t.......t.#
#tt..,......t.....rrr..........t.........,t..t.#
#t.....t..........rrr...t...........t........tt#
#t..t.....,t......rrr..........,..t.....t..,.t.#
#tt.....t.........rrr....t,..................tt#
#t...,.......t....r1r...........t...,t...t...t.#
#tt....t..........rrr...t...........t.....,.tt.#
#tttttttttttttttttrrrttttttttttttttttttttttttt.#
###################D############################
"""


func _layout() -> String:
	return LAYOUT


func _door_table() -> Dictionary:
	return DOORS


func _entry_aliases() -> Dictionary:
	return ENTRY_ALIASES


## Slimes must be direct children so sword hits and cleanup find them.
func _after_build() -> void:
	for cell: Vector2i in _parsed["spawns"]:
		var slime: Enemy = (load(SLIME_SCENE) as PackedScene).instantiate()
		slime.position = MapBuilder.cell_center(cell)
		add_child(slime)
