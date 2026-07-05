class_name CityMap
extends AreaMap

## The big city — Phase 3 world. Built at runtime by MapBuilder from LAYOUT
## (100x120 cells, 16px each -> 1600x1920 px). Districts: civic NW, park NE,
## market street, central plaza with fountain, riverside, residential south.

## Door cells ('D' in LAYOUT) -> transition wiring.
const DOORS := {
	Vector2i(3, 87): {"target_area": "garden", "target_entry": "EntryFromTownGarden"},
	Vector2i(18, 52): {"target_area": "shop", "target_entry": "EntryDefault"},
	Vector2i(45, 98): {"target_area": "neighbor_house", "target_entry": "EntryDefault"},
}

## MapBuilder digit entries -> semantic marker names other areas target.
const ENTRY_ALIASES := {
	"Entry1": "EntryFromGarden",
	"Entry3": "EntryFromShop",
	"Entry4": "EntryFromNeighborHouse",
}

const LAYOUT := """
####################################################################################################
#t.tt.tt.tt.tt.tt,tt.tt.tt.tt.tt.tt.tt.tt.tt.tt.tt,tt.tt.tt.tt.tt.tt.tt.tt.tt.tt.tt,tt.tt.tt.tt.ttt#
#,..........,..........,....rrrr..,..........,..........,..........,rrrr......,..........,........t#
#t.....,..........,.........rrrr........,..........,..........,.....rrrr.,..........,..........,..t#
#t,..........,..........,...rrrr...,..........,..........,..........rrrr.......,..t......t,f.......#
#.......,..........,........rrrr.........,..........,..........,....rrrr..,...t.f....t...f..t...,.t#
#t.,....#################,..rrrr....,..........,..........,.........rrrr......f.,t.....ft..,...t..t#
#t......#################...rrrr..........,..........,..........,...rrrr...,ft......tf,....t..f..,.#
#...,...#################.,.rrrr.....,..........,..........,........rrrr........t,.f...t....f.t...t#
#t......#################...rrrr,..........,..........,..........,..rrrr....t....f.t...,..t.......t#
#t...,..#################..,rrrr......,..........,..........,.......rrrr.......t..,...t.f....t.....#
#.......#################...rrrr.,..........,..........,..........,.rrrr.....f....t...f.,t.....f..t#
#t....,.#################...rrrr.......,..........,..........,......rrrr,.....t....,ft......tf,...t#
#t......#################...rrrr..,..........,..........,..........,rrrr......,..tf.....t,.f...t...#
#......,#################...rrrr........,..........,..........,.....rrrr.,...t..f...t....f.t...,..t#
#t,..........,..........,...rrrr...,..........,..........,..........rrrr......f,t......t..,...t...t#
#t......,..........,........rrrr.........,..........,..........,....rrrr..,..........,..........,..#
#..,..........,..........,..rrrr....,..........,..........,.........rrrr........,..........,......t#
#trrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrt#
#trrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrr.#
#.rrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrt#
#t...,..........,..........,rrrr......,..........,..........,.......rrrr..........,..........,....t#
#t.........,..........,.....rrrr.,..........,..........,..........,.rrrr....#################......#
#.....,..........,..........rrrr.......,..........,..........,......rrrr,...#################.,...t#
#t......###############,....rrrr..,..........,..........,..........,rrrr....#################.....t#
#t.....,###############.....rrrr........,..........,..........,.....rrrr.,..#################..,...#
#.,.....###############.,...rrrr...,..........,..........,..........rrrr....#################.....t#
#t......###############.....rrrr.........,..........,..........,....rrrr..,.#################...,.t#
#t.,....###############..,..rrrr....,..........,..........,.........rrrr....#################......#
#.......###############.....rrrr..........,..........,..........,...rrrr...,#################....,t#
#t..,...###############...,.rrrr.....,..........,..........,........rrrr....#################.....t#
#t......###############.....rrrr,..........,..........,..........,..rrrr....#################.....,#
#....,..###############....,rrrr......,..........,..........,.......rrrr....#################,....t#
#t.........,..........,.....rrrr.,..........,..........,..........,.rrrr.....,..........,.........t#
#t....,..........,..........rrrr.......,..........,..........,......rrrr,..........,..........,....#
#,..........,..........,....rrrr..,..........,..........,..........,rrrr......,..........,........t#
#t.....,..........,.........rrrr....pppppppppppppppppppppppppppp....rrrr.,..........,..........,..t#
#t,..........,..........,...rrrr...,pppppppppppppppppppppppppppp....rrrr.......,..........,........#
#.......,..........,........rrrr....pppppppppppppppppppppppppppp....rrrr..,..........,..........,.t#
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
#t.......,......3...,.......rrrr..........,..........,..........,...rrrr...,..........,..........,t#
#t..,...######.,##D###....,.rrrr.....,######..######....######......rrrr....######..######..,......#
#.......######..######......rrrr,.....######..######..,.######...,..rrrr....######..######........t#
#t...,..######..######.....,rrrr......######..######....######......rrrr....######,.######...,....t#
#t......######..######,.....rrrr.,....######,.######...,######....,.rrrr....######..######.........#
#.....,..........,..........rrrr......#############...##########....rrrr,...#################.,...t#
#t..........,..........,....rrrr..,...#############...##########...,rrrr....#################.....t#
#t.....,#################...rrrr......#############,..##########....rrrr.,..#################..,...#
#.,.....#################...rrrr...,..#############...##########....rrrr....#################.....t#
#t......#################...rrrr......#############.,.##########....rrrr..,.#################...,.t#
#t.,....#################,..rrrr....,.#############...##########....rrrr....#################......#
#.......#################...rrrr......#############..,##########,...rrrr...,#################....,t#
#t..,...#################.,.rrrr.....,#############...##########....rrrr....#################.....t#
#t......#################...rrrr,.....#############...##########.,..rrrr....#################.....,#
#....,..#################..,rrrr......,..........,..........,.......rrrr....#################,....t#
#t......#################...rrrr.,..........,..........,..........,.rrrr....#################.....t#
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
#t..........,..........,....rrrr..,..........,..........,..........,rrrr......,..........,........t#
#t.....,..........,.........rrrr........,..........,..........,.....rrrr.,..........,..........,...#
#.,...#######,....#######...rrrr#####.....#######.....#######.....##rrrr......#######.....,.......t#
#t....#######.....#######...rrrr#####....,#######...,.#######..,..##rrrr..,...#######,..........,.t#
#t.,..#######.,...#######,..rrrr#####.....#######.....#######.....##rrrr......#######......,.......#
#........,..........,.......rrrr..........,..........,..........,...rrrr...,..........,..........,t#
#t..,.#######..,..#######.,.rrrr#####,....#######.....#######.....##rrrr......#######.......,.....t#
#t....#######.....#######...rrrr#####.....#######.....#######....,##rrrr....,.#######..,..........,#
#....,#######...,.#######..,rrrr#####.,...###D###,....#######.....##rrrr......#######........,....t#
#t.........,..........,.....rrrr.,..........,..........,..........,.rrrr.....,..........,.........t#
#t....,..........,..........rrrr.......,..........,..........,......rrrr,..........,..........,....#
#,..........,..........,....rrrr..,..........4..........,..........,rrrr......,..........,........t#
#t.....,..........,.........rrrr........,..........,..........,.....rrrr.,..........,..........,..t#
#t,..........,..........,...rrrr...,..........,..........,..........rrrr.......,..........,........#
#.rrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrt#
#trrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrt#
#trrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrr.#
#...,..........,..........,.rrrr.....,..........,..........,........rrrr.........,..........,.....t#
#t....#######.....#######...rrrr#####.....#######.....#######....,##rrrr....,.##wwwwwwwww.........t#
#t...,#######...,.#######..,rrrr#####.,...#######,....#######.....##rrrr......##wwwwwwwww....,.....#
#.....#######.....#######...rrrr#####.....#######.....#######.....##rrrr.....,##wwwwwwwww.........t#
#t....,..........,..........rrrr.......,..........,..........,......rrrr,.......wwwwwwwww.....,...t#
#t....#######.....#######...rrrr#####.....#######.....#######.....##rrrr......##wwwwwwwww,.........#
#.....#######.....#######...rrrr#####...,.#######..,..#######.,...##rrrr.,....##wwwwwwwww......,..t#
#t,...#######,....#######...rrrr#####.....#######.....#######.....##rrrr......##wwwwwwwww.,.......t#
#t......,..........,........rrrr.........,..........,..........,....rrrr..,..........,..........,..#
#..,..........,..........,..rrrr....,..........,..........,.........rrrr........,..........,......t#
#t.......,..........,.......rrrr..........,..........,..........,...rrrr...,..........,..........,t#
#t.tt.tt.tt.tt.tt.tt.tt.tt,tt.tt.tt.tt.tt.tt.tt.tt.tt.tt.tt,tt.tt.tt.tt.tt.tt.tt.tt.tt.tt.tt,tt.ttt#
####################################################################################################
"""

func _layout() -> String:
	return LAYOUT


func _door_table() -> Dictionary:
	return DOORS


func _after_build() -> void:
	_alias_entries()
	_spawn_npcs()


func _alias_entries() -> void:
	for digit_name: String in ENTRY_ALIASES:
		var source := get_node_or_null(digit_name) as Marker2D
		if source == null:
			continue
		var alias := Marker2D.new()
		alias.name = ENTRY_ALIASES[digit_name]
		alias.position = source.position
		add_child(alias)


## NPCs must be direct children — Main._connect_area_npcs scans get_children().
## One plaza greeter for now; the city gets populated in P3-5.
func _spawn_npcs() -> void:
	var npc: Npc = (preload("res://scenes/Npc.tscn") as PackedScene).instantiate()
	npc.position = MapBuilder.cell_center(Vector2i(58, 42))
	npc.greeting = "Welcome to the big city! So much to explore!"
	add_child(npc)
