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
	Vector2i(116, 0): {"target_area": "woods", "target_entry": "EntryFromTown"},
}

## MapBuilder digit entries -> semantic marker names other areas target.
const ENTRY_ALIASES := {
	"Entry1": "EntryFromGarden",
	"Entry3": "EntryFromShop",
	"Entry4": "EntryFromNeighborHouse",
	"Entry5": "EntryFromWoods",
}

## Ordered world-px regions; first hit wins. East district, bands, quadrants.
const DISTRICTS := [
	{"name": "East Orchard", "rect": Rect2(1552, 0, 688, 1920)},
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
	{"id": "plaza_greeter", "type": "villager", "cell": Vector2i(58, 42),
		"greeting": "Welcome to the big city! I'm Milo — ask me anything!",
		"repeat": "Enjoying the plaza? The fountain is my favorite spot."},
	{"id": "berry_vendor", "type": "vendor", "cell": Vector2i(24, 49),
		"greeting": "Fresh berries! Picked them this morning! I'm Rosa, by the way.",
		"repeat": "Back for more berries? Best in town!"},
	{"id": "park_stroller", "type": "elder", "cell": Vector2i(85, 10),
		"greeting": "Ah, a new face! I'm Grandpa Ren. The park smells like flowers today.",
		"repeat": "Flowers never get old, dear."},
	{"id": "riverside_fisher", "type": "villager", "cell": Vector2i(35, 68),
		"greeting": "Shh! I'm Finn. I saw a fish jump right over the bridge!",
		"repeat": "Still waiting on that big one..."},
	{"id": "racer_kid", "type": "kid", "cell": Vector2i(50, 105),
		"greeting": "I'm Pip, fastest kid in town! Race you to the plaza! ...After my nap.",
		"repeat": "Zzz... five more minutes..."},
	{"id": "clock_keeper", "type": "elder", "cell": Vector2i(15, 19),
		"greeting": "Welcome! I'm Tock. The old clock tower rings at noon. Ding dong!",
		"repeat": "Ding dong! Right on schedule."},
	{"id": "farmer_ines", "type": "vendor", "cell": Vector2i(108, 22),
		"greeting": "Howdy! I'm Ines. This whole orchard? Planted it myself, tree by tree!",
		"repeat": "The apples will be ready soon, I can feel it!"},
	{"id": "lake_dreamer", "type": "kid", "cell": Vector2i(120, 52),
		"greeting": "Hi! I'm Momo. One day I'll swim all the way across the lake!",
		"repeat": "Just... warming up first. The water looks cold."},
]

const LAYOUT := """
####################################################################################################################D#######################
#t.tt.tt.tt.tt.tt,tt.tt.tt.tt.tt.tt.tt.tt.tt.tt.tt,tt.tt.tt.tt.tt.tt.tt.tt.tt.tt.tt,tt.tt.tt.tt.t...t.tt.tt.tt.tt5tt,tt.tt.tt.tt.tt.tt.tt.t#
#,..........,..........,....rrrr..,..........,..........,..........,rrrr......,..........,..........,..........,..........,..........,....t#
#t.....,..........,.........rrrr........,..........,..........,.....rrrr.,..........,..........,..........,..........,..........,..........#
#t,..........,..........,...rrrr...,..........,..........,..........rrrr.......,..t......t,f.........,..t...t...t...t...t..,t...t...t.,...t#
#.......,..........,........rrrr.........,..........,..........,....rrrr..,...t.f....t...f..t...,..........,..........,..........,........t#
#t.,..........,..........,..rrrr....,..........,..........,.........rrrr......f.,t.....ft..,...t......,...f...f..,f...f...f.,.f...f....,...#
#t.......,..........,.......rrrr..........,..........,..........,...rrrr...,ft......tf,....t..f..,..........,..........,..........,.......t#
#...,...I.....H,....J.....,.rrrr.....,..........,..........,........rrrr........t,.f...t....f.t........,t...t...t.,.t...t...t,..t...t...,.t#
#t........,..........,......rrrr,..........,..........,..........,..rrrr....t....f.t...,..t.......,..........,..........,..........,.......#
#t...,..........,..........,rrrr......,..........,..........,.......rrrr.......t..,...t.f....t..........,.f...f...f,..f...f...f...f......,t#
#..........,..........,.....rrrr.,..........,..........,..........,.rrrr.....f....t...f.,t.....f...,..........,..........,..........,.....t#
#t....,..........,..........rrrr.......,..........,..........,......rrrr,.....t....,ft......tf,.........t,..t...t...t...t...t..,t...t.....,#
#t..........,..........,....rrrr..,..........,..........,..........,rrrr......,..tf.....t,.f...t....,..........,..........,..........,....t#
#......,..........,.........rrrr........,..........,..........,.....rrrr.,...t..f...t....f.t...,..........f...f...f..,f...f...f.,.f.......t#
#t,..........,..........,...rrrr...,..........,..........,..........rrrr......f,t......t..,...t......,..........,..........,..........,....#
#t......,..........,........rrrr.........,..........,..........,....rrrr..,..........,..........,..........,..........,..........,........t#
#..,..........,..........,..rrrr....,..........,..........,.........rrrr........,..........,..........,..........,..........,..........,..t#
#trrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrr..#
#trrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrr.t#
#.rrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrr.t#
#t...,..........,..........,rrrr......,..........,..........,.......rrrr..........,..........,..........,..........,..........,..........,.#
#t.........,..........,.....rrrr.,..........,..........,..........,.rrrr.....,..........,..........,..........,..........,..........,.....t#
#.....,..........,..........rrrr.......,..........,..........,......rrrr,..........,..........,..........,..........,..........,..........t#
#t..........,..........,....rrrr..,..........,..........,..........,rrrr....J.,...I.....K,..........,..........,..........,..........,.....#
#t.....,..........,.........rrrr........,..........,..........,.....rrrr.,..........,..........,..........,..........,..........,.........t#
#.,..........,..........,...rrrr...,..........,..........,..........rrrr.......,..........,..........,..........,..........,..........,...t#
#t......,..........,........rrrr.........,..........,..........,....rrrr..,..........,..........,..........,..........,..........,.........#
#t.,..........,..........,..rrrr....,..........,..........,.........rrrr........,..........,..........,..........,..........,..........,..t#
#........,..........,.......rrrr..........,..........,..........,...rrrr...,..........,..........,..........,..........,..........,.......t#
#t..,..........,..........,.rrrr.....,..........,..........,........rrrr.........,..........,..........,..........,..........,..........,..#
#t........,..........,......rrrr,..........,..........,..........,..rrrr....,..........,..........,..........,..........,..........,......t#
#....,..........,..........,rrrr......,.K........,..........,.......rrrr..........,..........,..........,..........,..........,..........,t#
#t.........,..........,.....rrrr.,..........,..........,..........,.rrrr.....,..........,..........,..........,..........,..........,......#
#t....,..........,..........rrrr.......,..........,..........,......rrrr,..........,..........,..........,..........,..........,..........t#
#,..........,..........,....rrrr..,......D...,..........,..........,rrrr......,..........,..........,..........,..........,..........,....t#
#t.....,..........,.........rrrr....pppppppppppppppppppppppppppp....rrrr.,..........,..........,..........,..........,..........,..........#
#t,..........,..........,...rrrr...,pppppppppppppppppppppppppppp....rrrr.......,..........,..........,..........,..........,..........,...t#
#.......,..........,........rrrr....ppppp3pppppppppppppppppppppp....rrrr..,..........,..........,..........,..........,..........,........t#
#t.,..........,..........,..rrrr....pppppppppppppppppppppppppppp....rrrr........,..........,..........,..........,..........,..........,...#
#t.......,..........,.......rrrr....ppppppppppppwwwwpppppppppppp,...rrrr...,..........,..........,..........,..........,..........,.......t#
#...,..........,..........,.rrrr....ppppppppppppwwwwpppppppppppp....rrrr.........,..........,..........,..........,..........,..........,.t#
#t........,..........,......rrrr,...ppppppppppppwwwwpppppppppppp.,..rrrr....,..........,..........,..........,..........,..........,.......#
#t...,..........,..........,rrrr....ppppppppppppwwwwpppppppppppp....rrrr..........,..........,..........,..........,..........,..........,t#
#..........,..........,.....rrrr.,..pppppppppppppppppppppppppppp..,.rrrr.....,..........,..........,..........,..........,..........,.....t#
#t....,..........,..........rrrr....ppppppppppppp2pppppppppppppp....rrrr,..........,..........,..........,..........,..........,..........,#
#t..........,..........,....rrrr..,.pppppppppppppppppppppppppppp...,rrrr......,..........,..........,..........,..........,..........,....t#
#......,..........,.........rrrr....pppppppppppppppppppppppppppp....rrrr.,..........,..........,..........,..........,..........,.........t#
#trrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrr..#
#trrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrr.t#
#.rrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrr.t#
#t.......,..........,.......rrrr..........,..........,..........,...rrrr...,..........,..........,..........,..........,..........,........#
#t..,...K......,K.........,.rrrr.....,........K.,.......K..,........rrrr....K....,..K.......,..........,..........,..........,..........,.t#
#.........,..........,......rrrr,..........,..........,..........,..rrrr....,..........,..........,..........,..........,..........,......t#
#t...,..........,..........,rrrr......,..........,..........,.......rrrr..........,..........,..........,..........,..........,..........,.#
#t.........,..........,.....rrrr.,..........,..........,..........,.rrrr.....,..........,..........,..........,..........,..........,.....t#
#.....,..........,..........rrrr......I,....I.....,...J...J..,......rrrr,...I.....I,....I.....,..........,......wwwwwwwwwwwwwwww..........t#
#t..........,..........,....rrrr..,..........,..........,..........,rrrr......,..........,..........,..........,wwwwwwwwwwwwwwww.....,.....#
#t.....,I.....I...,.I.......rrrr........,..........,..........,.....rrrr.,..........,..........,..........,.....wwwwwwwwwwwwwwww,.........t#
#.,..........,..........,...rrrr...,..........,..........,..........rrrr.......,..........,..........,..........wwwwwwwwwwwwwwww......,...t#
#t......,..........,........rrrr......H..,..H.......,.K...K....,....rrrr..,.H.....H..,..H.......,..........,....wwwwwwwwwwwwwwww.,.........#
#t.,..........,..........,..rrrr....,..........,..........,.........rrrr........,..........,..........,.........wwwwwwwwwwwwwwww.......,..t#
#.......K,....K.....K.......rrrr..........,..........,..........,...rrrr...,..........,..........,..........,...wwwwwwwwwwwwwwww..,.......t#
#t..,..........,..........,.rrrr.....,..........,..........,........rrrr.........,..........,..........,........wwwwwwwwwwwwwwww........,..#
#t........,..........,......rrrr,..........,..........,..........,..rrrr....,..........,..........,..........,..wwwwwwwwwwwwwwww...,......t#
#....,..........,..........,rrrr......,..........,..........,.......rrrr..........,..........,..........,.......wwwwwwwwwwwwwwww.........,t#
#t.........,..........,.....rrrr.,..........,..........,..........,.rrrr.....,..........,..........,..........,.wwwwwwwwwwwwwwww....,......#
#t....,..........,..........rrrr.......,..........,..........,......rrrr,..........,..........,..........,..........,..........,..........t#
#,..f...f...f...f...f..,f...rrrrf.,.f...f...f,..f...f...f...f...f..,rrrrf...f.,.f...f...f,..f...f...,..........,..........,..........,....t#
#t.....,..........,.........rrrr........,..........,..........,.....rrrr.,..........,..........,..........,..........,..........,..........#
#wwwwwwwwwwwwwwwwwwwwwwwwwwwbbbbwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwbbbbwwwwwwwwwwwwwwwwwwwwwwwwwww.f,..........,f.........,..f.......,...t#
#wwwwwwwwwwwwwwwwwwwwwwwwwwwbbbbwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwbbbbwwwwwwwwwwwwwwwwwwwwwwwwwww........f..........,.f........,...f....t#
#wwwwwwwwwwwwwwwwwwwwwwwwwwwbbbbwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwbbbbwwwwwwwwwwwwwwwwwwwwwwwwwww..f,..........,f.........,..f.......,...#
#wwwwwwwwwwwwwwwwwwwwwwwwwwwbbbbwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwbbbbwwwwwwwwwwwwwwwwwwwwwwwwwww.........f..........,.f........,...f...t#
#wwwwwwwwwwwwwwwwwwwwwwwwwwwbbbbwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwbbbbwwwwwwwwwwwwwwwwwwwwwwwwwww...f,..........,f.........,..f.......,.t#
#t........,..........,......rrrr,..........,..........,..........,..rrrr....,..........,..........,..........f..........,.f........,...f...#
#t...,..........,..........,rrrr......,..........,..........,.......rrrr..........,..........,.........f,..........,f.........,..f.......,t#
#....f....f,...f....f.,..f..rrrr.,.f....f...,f....f....f....f....f,.rrrr...f.,..f....f..,.f....f...,..........f..........,.f........,.....t#
#t....,..........,..........rrrr.......,..........,..........,......rrrr,..........,..........,.........f,..........,f.........,..f.......,#
#t..........,..........,....rrrr..,..........,..........,..........,rrrr......,..........,..........,..........f..........,.f........,....t#
#......,..........,.........rrrr........,..........,..........,.....rrrr.,..........,..........,.........f,..........,f.........,..f......t#
#t,..........,..........,...rrrr...,..........,..........,..........rrrr.......,..........,..........,..........f..........,.f........,....#
#t......,..........,........rrrr.........,..........,..........,....rrrr..,..........,..........,.........f,..........,f.........,..f.....t#
#..,..........,..........,..rrrr....,..........,..........,.........rrrr........,..........,........f.,..........f..........,.f........,..t#
#t.......,..........,.......rrrr..........,..........,..........,...rrrr...,..........,..........,..........,..........,..........,........#
#t..,..........,..........,.rrrr.....,..........,..........,........rrrr.........,..........,..........,..........,..........,..........,.t#
#rrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrr.......,..........,......t#
#rrDr1rrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrr..,..........,..........,.#
#rrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrr........,..........,.....t#
#.....,..........,..........rrrr.......,..........,..........,......rrrr,..........,..........,..........,..........,..........,..........t#
#t......H...,.I.....J..,....rrrr..H.....I....,J.......H.,...I......,rrrr..J...,.H.....I..,..........,..........,..........,..........,.....#
#t.....,..........,.........rrrr........,..........,..........,.....rrrr.,..........,..........,..........,..........,..........,.........t#
#.,..........,..........,...rrrr...,..........,..........,..........rrrr.......,..........,..........,..........,..........,..........,...t#
#t......,..........,........rrrr.........,D.........,..........,....rrrr..,..........,..........,..........,..........,..........,.........#
#t.,..........,..........,..rrrr....,..........,..........,.........rrrr........,..........,..........,..........,..........,..........,..t#
#........,..........,.......rrrr..........,..........,..........,...rrrr...,..........,..........,..........,..........,..........,.......t#
#t..,..........,..........,.rrrr.....,....4.....,..........,........rrrr.........,..........,..........,H.......I.,.....J....,..K.......,..#
#t........,..........,......rrrr,..........,..........,..........,..rrrr....,..........,..........,..........,..........,..........,......t#
#....,..........,..........,rrrr......,..........,..........,.......rrrr..........,..........,..........,..........,..........,..........,t#
#t.........,..........,.....rrrr.,..........,..........,..........,.rrrr.....,..........,..........,..........,..........,..........,......#
#t....,..........,..........rrrr.......,..........,..........,......rrrr,..........,..........,..........,..........,..........,..........t#
#,..........,..........,....rrrr..,..........,..........,..........,rrrr......,..........,..........,..........,..........,..........,....t#
#t.....,..........,.........rrrr........,..........,..........,.....rrrr.,..........,..........,..........,..........,..........,..........#
#t,..........,..........,...rrrr...,..........,..........,..........rrrr.......,..........,..........,..........,..........,..........,...t#
#.rrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrr.t#
#trrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrr..#
#trrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrr.t#
#...,..........,..........,.rrrr.....,..........,..........,........rrrr.........,..........,..........,..........,..........,..........,.t#
#t......J.,...H.....I,......rrrr,.J.....H..,..I.......J.....H....,..rrrr..I.,..........,wwwwwwwww.,..........,..........,..........,.......#
#t...,..........,..........,rrrr......,..........,..........,.......rrrr..........,.....wwwwwwwww.......,..........,..........,..........,t#
#..........,..........,.....rrrr.,..........,..........,..........,.rrrr.....,..........wwwwwwwww..,....J.....,.K.......H,..........,.....t#
#t....,..........,..........rrrr.......,..........,..........,......rrrr,..........,....wwwwwwwww........,..........,..........,..........,#
#t..........,..........,....rrrr..,..........,..........,..........,rrrr......,.........wwwwwwwww...,..........,..........,..........,....t#
#......,..........,.........rrrr........,..........,..........,.....rrrr.,..........,...wwwwwwwww.........,..........,..........,.........t#
#t,..........,..........,...rrrr...,..........,..........,..........rrrr.......,........wwwwwwwww....,..........,..........,..........,....#
#t......,..........,........rrrr.........,..........,..........,....rrrr..,..........,..........,..........,..........,..........,........t#
#..,..........,..........,..rrrr....,..........,..........,.........rrrr........,..........,..........,..........,..........,..........,..t#
#t.......,..........,.......rrrr..........,..........,..........,...rrrr...,..........,..........,..........,..........,..........,........#
#t.tt.tt.tt.tt.tt.tt.tt.tt,tt.tt.tt.tt.tt.tt.tt.tt.tt.tt.tt,tt.tt.tt.tt.tt.tt.tt.tt.tt.tt.tt,tt.t...t.tt.tt.tt.tt.tt.tt.tt.tt,tt.tt.tt.tt.t#
############################################################################################################################################
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
		npc.npc_id = entry["id"]
		npc.npc_type = entry["type"]
		npc.greeting = entry["greeting"]
		npc.repeat_text = entry["repeat"]
		npc.sprite_texture = skins[i % skins.size()]
		add_child(npc)
