class_name CityMap
extends AreaMap

## The big city — Phase 3 world. Built at runtime by MapBuilder from LAYOUT
## (100x120 cells, 16px each -> 1600x1920 px). Districts: civic NW, park NE,
## market street, central plaza with fountain, riverside, residential south.

## Door cells ('D' in LAYOUT) -> transition wiring.
const DOORS := {
	Vector2i(3, 87): {"target_area": "garden", "target_entry": "EntryFromTownGarden"},
	Vector2i(41, 35): {"target_area": "shop", "target_entry": "EntryDefault"},
	Vector2i(42, 93): {"target_area": "neighbor_house", "target_entry": "EntryDefault"},
}

## MapBuilder digit entries -> semantic marker names other areas target.
const ENTRY_ALIASES := {
	"Entry1": "EntryFromGarden",
	"Entry3": "EntryFromShop",
	"Entry4": "EntryFromNeighborHouse",
}

## Ordered world-px regions; first hit wins. Bands first, then quadrants.
const DISTRICTS := [
	{"name": "Market Street", "rect": Rect2(0, 768, 1600, 160)},
	{"name": "Riverside", "rect": Rect2(0, 928, 1600, 352)},
	{"name": "Maple Residential", "rect": Rect2(0, 1280, 1600, 640)},
	{"name": "Old Quarter", "rect": Rect2(0, 0, 448, 768)},
	{"name": "Riverside Park", "rect": Rect2(1152, 0, 448, 288)},
	{"name": "Museum District", "rect": Rect2(1152, 288, 448, 480)},
	{"name": "Sunny Plaza", "rect": Rect2(448, 544, 704, 224)},
	{"name": "North Avenue", "rect": Rect2(448, 0, 704, 544)},
]

## Cozy greeters scattered across districts (game is for a kid — keep it sweet).
const NPCS := [
	{"cell": Vector2i(58, 42), "greeting": "Welcome to the big city! So much to explore!"},
	{"cell": Vector2i(24, 49), "greeting": "Fresh berries! Picked them this morning!"},
	{"cell": Vector2i(85, 10), "greeting": "The park smells like flowers today!"},
	{"cell": Vector2i(35, 68), "greeting": "I saw a fish jump right over the bridge!"},
	{"cell": Vector2i(50, 105), "greeting": "Race you to the plaza! ...Maybe after my nap."},
	{"cell": Vector2i(15, 19), "greeting": "The old clock tower rings at noon. Ding dong!"},
]

const LAYOUT := """
####################################################################################################
#t.tt.tt.tt.tt.tt,tt.tt.tt.tt.tt.tt.tt.tt.tt.tt.tt,tt.tt.tt.tt.tt.tt.tt.tt.tt.tt.tt,tt.tt.tt.tt.ttt#
#,..........,..........,....rrrr..,..........,..........,..........,rrrr......,..........,........t#
#t.....,..........,.........rrrr........,..........,..........,.....rrrr.,..........,..........,..t#
#t,..........,..........,...rrrr...,..........,..........,..........rrrr.......,..t......t,f.......#
#.......,..........,........rrrr.........,..........,..........,....rrrr..,...t.f....t...f..t...,.t#
#t.,..........,..........,..rrrr....,..........,..........,.........rrrr......f.,t.....ft..,...t..t#
#t.......,..........,.......rrrr..........,..........,..........,...rrrr...,ft......tf,....t..f..,.#
#...,...I.....H,....J.....,.rrrr.....,..........,..........,........rrrr........t,.f...t....f.t...t#
#t........,..........,......rrrr,..........,..........,..........,..rrrr....t....f.t...,..t.......t#
#t...,..........,..........,rrrr......,..........,..........,.......rrrr.......t..,...t.f....t.....#
#..........,..........,.....rrrr.,..........,..........,..........,.rrrr.....f....t...f.,t.....f..t#
#t....,..........,..........rrrr.......,..........,..........,......rrrr,.....t....,ft......tf,...t#
#t..........,..........,....rrrr..,..........,..........,..........,rrrr......,..tf.....t,.f...t...#
#......,..........,.........rrrr........,..........,..........,.....rrrr.,...t..f...t....f.t...,..t#
#t,..........,..........,...rrrr...,..........,..........,..........rrrr......f,t......t..,...t...t#
#t......,..........,........rrrr.........,..........,..........,....rrrr..,..........,..........,..#
#..,..........,..........,..rrrr....,..........,..........,.........rrrr........,..........,......t#
#trrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrt#
#trrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrr.#
#.rrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrt#
#t...,..........,..........,rrrr......,..........,..........,.......rrrr..........,..........,....t#
#t.........,..........,.....rrrr.,..........,..........,..........,.rrrr.....,..........,..........#
#.....,..........,..........rrrr.......,..........,..........,......rrrr,..........,..........,...t#
#t..........,..........,....rrrr..,..........,..........,..........,rrrr....J.,...I.....K,........t#
#t.....,..........,.........rrrr........,..........,..........,.....rrrr.,..........,..........,...#
#.,..........,..........,...rrrr...,..........,..........,..........rrrr.......,..........,.......t#
#t......,..........,........rrrr.........,..........,..........,....rrrr..,..........,..........,.t#
#t.,..........,..........,..rrrr....,..........,..........,.........rrrr........,..........,.......#
#........,..........,.......rrrr..........,..........,..........,...rrrr...,..........,..........,t#
#t..,..........,..........,.rrrr.....,..........,..........,........rrrr.........,..........,.....t#
#t........,..........,......rrrr,..........,..........,..........,..rrrr....,..........,..........,#
#....,..........,..........,rrrr......,.K........,..........,.......rrrr..........,..........,....t#
#t.........,..........,.....rrrr.,..........,..........,..........,.rrrr.....,..........,.........t#
#t....,..........,..........rrrr.......,..........,..........,......rrrr,..........,..........,....#
#,..........,..........,....rrrr..,......D...,..........,..........,rrrr......,..........,........t#
#t.....,..........,.........rrrr....pppppppppppppppppppppppppppp....rrrr.,..........,..........,..t#
#t,..........,..........,...rrrr...,pppppppppppppppppppppppppppp....rrrr.......,..........,........#
#.......,..........,........rrrr....ppppp3pppppppppppppppppppppp....rrrr..,..........,..........,.t#
#t.,..........,..........,..rrrr....pppppppppppppppppppppppppppp....rrrr........,..........,......t#
#t.......,..........,.......rrrr....ppppppppppppwwwwpppppppppppp,...rrrr...,..........,..........,.#
#...,..........,..........,.rrrr....ppppppppppppwwwwpppppppppppp....rrrr.........,..........,.....t#
#t........,..........,......rrrr,...ppppppppppppwwwwpppppppppppp.,..rrrr....,..........,..........t#
#t...,..........,..........,rrrr....ppppppppppppwwwwpppppppppppp....rrrr..........,..........,.....#
#..........,..........,.....rrrr.,..pppppppppppppppppppppppppppp..,.rrrr.....,..........,.........t#
#t....,..........,..........rrrr....ppppppppppppp2pppppppppppppp....rrrr,..........,..........,...t#
#t..........,..........,....rrrr..,.pppppppppppppppppppppppppppp...,rrrr......,..........,.........#
#......,..........,.........rrrr....pppppppppppppppppppppppppppp....rrrr.,..........,..........,..t#
#trrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrt#
#trrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrr.#
#.rrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrt#
#t.......,..........,.......rrrr..........,..........,..........,...rrrr...,..........,..........,t#
#t..,...K......,K.........,.rrrr.....,........K.,.......K..,........rrrr....K....,..K.......,......#
#.........,..........,......rrrr,..........,..........,..........,..rrrr....,..........,..........t#
#t...,..........,..........,rrrr......,..........,..........,.......rrrr..........,..........,....t#
#t.........,..........,.....rrrr.,..........,..........,..........,.rrrr.....,..........,..........#
#.....,..........,..........rrrr......I,....I.....,...J...J..,......rrrr,...I.....I,....I.....,...t#
#t..........,..........,....rrrr..,..........,..........,..........,rrrr......,..........,........t#
#t.....,I.....I...,.I.......rrrr........,..........,..........,.....rrrr.,..........,..........,...#
#.,..........,..........,...rrrr...,..........,..........,..........rrrr.......,..........,.......t#
#t......,..........,........rrrr......H..,..H.......,.K...K....,....rrrr..,.H.....H..,..H.......,.t#
#t.,..........,..........,..rrrr....,..........,..........,.........rrrr........,..........,.......#
#.......K,....K.....K.......rrrr..........,..........,..........,...rrrr...,..........,..........,t#
#t..,..........,..........,.rrrr.....,..........,..........,........rrrr.........,..........,.....t#
#t........,..........,......rrrr,..........,..........,..........,..rrrr....,..........,..........,#
#....,..........,..........,rrrr......,..........,..........,.......rrrr..........,..........,....t#
#t.........,..........,.....rrrr.,..........,..........,..........,.rrrr.....,..........,.........t#
#t....,..........,..........rrrr.......,..........,..........,......rrrr,..........,..........,....#
#,..f...f...f...f...f..,f...rrrrf.,.f...f...f,..f...f...f...f...f..,rrrrf...f.,.f...f...f,..f...f.t#
#t.....,..........,.........rrrr........,..........,..........,.....rrrr.,..........,..........,..t#
#wwwwwwwwwwwwwwwwwwwwwwwwwwwbbbbwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwbbbbwwwwwwwwwwwwwwwwwwwwwwwwwww#
#wwwwwwwwwwwwwwwwwwwwwwwwwwwbbbbwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwbbbbwwwwwwwwwwwwwwwwwwwwwwwwwww#
#wwwwwwwwwwwwwwwwwwwwwwwwwwwbbbbwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwbbbbwwwwwwwwwwwwwwwwwwwwwwwwwww#
#wwwwwwwwwwwwwwwwwwwwwwwwwwwbbbbwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwbbbbwwwwwwwwwwwwwwwwwwwwwwwwwww#
#wwwwwwwwwwwwwwwwwwwwwwwwwwwbbbbwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwbbbbwwwwwwwwwwwwwwwwwwwwwwwwwww#
#t........,..........,......rrrr,..........,..........,..........,..rrrr....,..........,..........t#
#t...,..........,..........,rrrr......,..........,..........,.......rrrr..........,..........,.....#
#....f....f,...f....f.,..f..rrrr.,.f....f...,f....f....f....f....f,.rrrr...f.,..f....f..,.f....f..t#
#t....,..........,..........rrrr.......,..........,..........,......rrrr,..........,..........,...t#
#t..........,..........,....rrrr..,..........,..........,..........,rrrr......,..........,.........#
#......,..........,.........rrrr........,..........,..........,.....rrrr.,..........,..........,..t#
#t,..........,..........,...rrrr...,..........,..........,..........rrrr.......,..........,.......t#
#t......,..........,........rrrr.........,..........,..........,....rrrr..,..........,..........,..#
#..,..........,..........,..rrrr....,..........,..........,.........rrrr........,..........,......t#
#t.......,..........,.......rrrr..........,..........,..........,...rrrr...,..........,..........,t#
#t..,..........,..........,.rrrr.....,..........,..........,........rrrr.........,..........,......#
#rrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrt#
#rrDr1rrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrt#
#rrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrr.#
#.....,..........,..........rrrr.......,..........,..........,......rrrr,..........,..........,...t#
#t......H...,.I.....J..,....rrrr..H.....I....,J.......H.,...I......,rrrr..J...,.H.....I..,........t#
#t.....,..........,.........rrrr........,..........,..........,.....rrrr.,..........,..........,...#
#.,..........,..........,...rrrr...,..........,..........,..........rrrr.......,..........,.......t#
#t......,..........,........rrrr.........,D.........,..........,....rrrr..,..........,..........,.t#
#t.,..........,..........,..rrrr....,..........,..........,.........rrrr........,..........,.......#
#........,..........,.......rrrr..........,..........,..........,...rrrr...,..........,..........,t#
#t..,..........,..........,.rrrr.....,....4.....,..........,........rrrr.........,..........,.....t#
#t........,..........,......rrrr,..........,..........,..........,..rrrr....,..........,..........,#
#....,..........,..........,rrrr......,..........,..........,.......rrrr..........,..........,....t#
#t.........,..........,.....rrrr.,..........,..........,..........,.rrrr.....,..........,.........t#
#t....,..........,..........rrrr.......,..........,..........,......rrrr,..........,..........,....#
#,..........,..........,....rrrr..,..........,..........,..........,rrrr......,..........,........t#
#t.....,..........,.........rrrr........,..........,..........,.....rrrr.,..........,..........,..t#
#t,..........,..........,...rrrr...,..........,..........,..........rrrr.......,..........,........#
#.rrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrt#
#trrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrt#
#trrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrr.#
#...,..........,..........,.rrrr.....,..........,..........,........rrrr.........,..........,.....t#
#t......J.,...H.....I,......rrrr,.J.....H..,..I.......J.....H....,..rrrr..I.,..........,wwwwwwwww.t#
#t...,..........,..........,rrrr......,..........,..........,.......rrrr..........,.....wwwwwwwww..#
#..........,..........,.....rrrr.,..........,..........,..........,.rrrr.....,..........wwwwwwwww.t#
#t....,..........,..........rrrr.......,..........,..........,......rrrr,..........,....wwwwwwwww.t#
#t..........,..........,....rrrr..,..........,..........,..........,rrrr......,.........wwwwwwwww..#
#......,..........,.........rrrr........,..........,..........,.....rrrr.,..........,...wwwwwwwww.t#
#t,..........,..........,...rrrr...,..........,..........,..........rrrr.......,........wwwwwwwww.t#
#t......,..........,........rrrr.........,..........,..........,....rrrr..,..........,..........,..#
#..,..........,..........,..rrrr....,..........,..........,.........rrrr........,..........,......t#
#t.......,..........,.......rrrr..........,..........,..........,...rrrr...,..........,..........,t#
#t.tt.tt.tt.tt.tt.tt.tt.tt,tt.tt.tt.tt.tt.tt.tt.tt.tt.tt.tt,tt.tt.tt.tt.tt.tt.tt.tt.tt.tt.tt,tt.ttt#
####################################################################################################
"""

## Pure: world position -> district name. Unit-testable.
static func district_for(pos: Vector2) -> String:
	for district: Dictionary in DISTRICTS:
		if (district["rect"] as Rect2).has_point(pos):
			return district["name"]
	return "City"


## Instance hook Main polls for the on-screen area label.
func district_at(pos: Vector2) -> String:
	return district_for(pos)


func _layout() -> String:
	return LAYOUT


func _door_table() -> Dictionary:
	return DOORS


func _entry_aliases() -> Dictionary:
	return ENTRY_ALIASES


func _after_build() -> void:
	_spawn_npcs()


## NPCs must be direct children — Main._connect_area_npcs scans get_children().
## Alternates samurai colors so the townsfolk don't look cloned.
func _spawn_npcs() -> void:
	var skins: Array = [
		load("res://assets/character/samurai_blue.png"),
		load("res://assets/character/samurai_green.png"),
	]
	for i in NPCS.size():
		var entry: Dictionary = NPCS[i]
		var npc: Npc = (preload("res://scenes/Npc.tscn") as PackedScene).instantiate()
		npc.position = MapBuilder.cell_center(entry["cell"])
		npc.greeting = entry["greeting"]
		npc.sprite_texture = skins[i % skins.size()]
		add_child(npc)
