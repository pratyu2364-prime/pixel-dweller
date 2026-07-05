class_name GardenMap
extends AreaMap

## The garden between House and City — tiled park with pond and flower beds.
## Growth decorations (apply_world_stage) land here as the dweller grows up.

const DOORS := {
	Vector2i(1, 20): {"target_area": "house", "target_entry": "EntryFromGarden"},
	Vector2i(48, 20): {"target_area": "town", "target_entry": "EntryFromGarden"},
}

const ENTRY_ALIASES := {
	"Entry1": "EntryFromHouse",
	"Entry2": "EntryFromTownGarden",
}

const LAYOUT := """
##################################################
#t.tt.tt.tt.tt.tt,tt.tt.tt.tt.tt.tt.tt.tt.tt.tt.t#
#,..........,..........,..........,..........,..t#
#t.....,..........,..........,..........,........#
#t,..........,..........,..........,..........,.t#
#.......,..........,..........,.....wwwwwwwww...t#
#t.,..........,.t........,..........wwwwwwwww..,.#
#t.......,..........,..........,....wwwwwwwww...t#
#...,...fffffff,..........,.t.......wwwwwwwww...t#
#t......fffffff......,..........,...wwwwwwwww....#
#t...,..fffffff.,..........,........wwwwwwwww...t#
#..........,..........,..........,..wwwwwwwww...t#
#t....,..........,..........,..........,.........#
#t..........,..........,..........,..........,..t#
#......,..........,..........,..........,.......t#
#t,..........,..........,..........,..........,..#
#t......,..........,..........,..........,......t#
#..,..........,..........,..........,..........,t#
#t.......,..........,..........,..........,......#
#rrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrr#
#Drr1rrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrr2rrD#
#rrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrr#
#t.........,..........,..........,..........,...t#
#.....,..........,..........,..........,........t#
#t..........,..........,..........,..........,...#
#t.....,..........,..........,..........,.......t#
#.,.......t..,..........,.........fffffff.....,.t#
#t......,..........,..........,...fffffff,.......#
#t.,..........,.....fffffff.......fffffff......,t#
#........,..........fffffff....,..........,.....t#
#t..,..........,....fffffff..........,..........,#
#t........,..........,..........,..........,....t#
#....,.t........,..........,..........,....t....t#
#t.........,..........,.......t..,..........,....#
#t....,..........,..........,..........,........t#
#,..........,..........,..........,..........,..t#
#t.....,..........,..........,..........,........#
#t,..........,..........,..........,..........,.t#
#ttt.tt.tt.tt.tt.tt,tt.tt.tt.tt.tt.tt.tt.tt.tt.tt#
##################################################
"""


func _layout() -> String:
	return LAYOUT


func _door_table() -> Dictionary:
	return DOORS


func _entry_aliases() -> Dictionary:
	return ENTRY_ALIASES


func apply_world_stage(stage_index: int) -> void:
	if stage_index >= Dweller.Stage.KID:
		_add_tree()
	if stage_index >= Dweller.Stage.ADULT:
		_add_flowers()


func _add_tree() -> void:
	if get_node_or_null("TreeDecoration") != null:
		return
	var tree: Polygon2D = Polygon2D.new()
	tree.name = "TreeDecoration"
	tree.polygon = PackedVector2Array([
		Vector2(-30, 0), Vector2(30, 0), Vector2(0, -60),
	])
	tree.color = Color(0.0, 0.6, 0.0)
	tree.position = Vector2(560, 240)
	add_child(tree)


func _add_flowers() -> void:
	if get_node_or_null("FlowersDecoration") != null:
		return
	var flowers: Polygon2D = Polygon2D.new()
	flowers.name = "FlowersDecoration"
	flowers.polygon = PackedVector2Array([
		Vector2(-15, -8), Vector2(15, -8), Vector2(8, 8), Vector2(-8, 8),
	])
	flowers.color = Color(1.0, 0.5, 0.8)
	flowers.position = Vector2(250, 420)
	add_child(flowers)
