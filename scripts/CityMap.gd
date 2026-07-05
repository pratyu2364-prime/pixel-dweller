class_name CityMap
extends Node2D

## The big city — Phase 3 world. Built at runtime by MapBuilder from LAYOUT
## (100x120 cells, 16px each -> 1600x1920 px). Districts: civic NW, park NE,
## market street, central plaza with fountain, riverside, residential south.

## Door cells ('D' in LAYOUT) -> transition wiring.
const DOORS := {
	Vector2i(3, 87): {"target_area": "garden", "target_entry": "EntryFromTownGarden"},
}

## MapBuilder digit entries -> semantic marker names other areas target.
const ENTRY_ALIASES := {
	"Entry1": "EntryFromGarden",
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
#t.......,..........,.......rrrr..........,..........,..........,...rrrr...,..........,..........,t#
#t..,...######.,######....,.rrrr.....,######..######....######......rrrr....######..######..,......#
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
#.,...#######,....#######...rr#######.....#######.....#######.....#######.....#######.....,.......t#
#t....#######.....#######...rr#######....,#######...,.#######..,..#######.,...#######,..........,.t#
#t.,..#######.,...#######,..rr#######.....#######.....#######.....#######.....#######......,.......#
#........,..........,.......rrrr..........,..........,..........,...rrrr...,..........,..........,t#
#t..,.#######..,..#######.,.rr#######,....#######.....#######.....#######.....#######.......,.....t#
#t....#######.....#######...rr#######.....#######.....#######....,#######...,.#######..,..........,#
#....,#######...,.#######..,rr#######.,...#######,....#######.....#######.....#######........,....t#
#t.........,..........,.....rrrr.,..........,..........,..........,.rrrr.....,..........,.........t#
#t....,..........,..........rrrr.......,..........,..........,......rrrr,..........,..........,....#
#,..........,..........,....rrrr..,..........,..........,..........,rrrr......,..........,........t#
#t.....,..........,.........rrrr........,..........,..........,.....rrrr.,..........,..........,..t#
#t,..........,..........,...rrrr...,..........,..........,..........rrrr.......,..........,........#
#.rrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrt#
#trrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrt#
#trrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrr.#
#...,..........,..........,.rrrr.....,..........,..........,........rrrr.........,..........,.....t#
#t....#######.....#######...rr#######.....#######.....#######....,#######...,.##wwwwwwwww.........t#
#t...,#######...,.#######..,rr#######.,...#######,....#######.....#######.....##wwwwwwwww....,.....#
#.....#######.....#######...rr#######.....#######.....#######.....#######....,##wwwwwwwww.........t#
#t....,..........,..........rrrr.......,..........,..........,......rrrr,.......wwwwwwwww.....,...t#
#t....#######.....#######...rr#######.....#######.....#######.....#######.....##wwwwwwwww,.........#
#.....#######.....#######...rr#######...,.#######..,..#######.,...#######,....##wwwwwwwww......,..t#
#t,...#######,....#######...rr#######.....#######.....#######.....#######.....##wwwwwwwww.,.......t#
#t......,..........,........rrrr.........,..........,..........,....rrrr..,..........,..........,..#
#..,..........,..........,..rrrr....,..........,..........,.........rrrr........,..........,......t#
#t.......,..........,.......rrrr..........,..........,..........,...rrrr...,..........,..........,t#
#t.tt.tt.tt.tt.tt.tt.tt.tt,tt.tt.tt.tt.tt.tt.tt.tt.tt.tt.tt,tt.tt.tt.tt.tt.tt.tt.tt.tt.tt.tt,tt.ttt#
####################################################################################################
"""

## Camera stays at CameraRig default (2.0); exported so interiors could differ.
@export var camera_zoom: float = 0.0

var _parsed: Dictionary = {}


func _ready() -> void:
	_parsed = MapBuilder.build(LAYOUT, self)
	_spawn_doors()
	_alias_entries()
	_spawn_npcs()


func get_area_bounds() -> Rect2:
	if _parsed.is_empty():
		_parsed = MapBuilder.parse(LAYOUT)
	return MapBuilder.bounds_of(_parsed)


## Doors must be direct children — Main._connect_area_doors scans get_children().
func _spawn_doors() -> void:
	for cell: Vector2i in _parsed["doors"]:
		var info: Dictionary = DOORS.get(cell, {})
		if info.is_empty():
			continue
		var door: Door = (preload("res://scenes/Door.tscn") as PackedScene).instantiate()
		door.position = MapBuilder.cell_center(cell)
		door.target_area = info["target_area"]
		door.target_entry = info["target_entry"]
		add_child(door)


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
