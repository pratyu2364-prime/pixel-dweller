class_name MapBuilder
extends RefCounted

## Builds a playable world from an ASCII layout string.
## Each character is one 16x16 cell. Rendering uses a single TileMapLayer with a
## runtime-generated solid-color TileSet (no binary art assets). Solid cells get
## full-cell collision polygons on the TileSet physics layer (collision_layer 1,
## same as existing walls).

const CELL := 16

## char -> {color, solid}. Digits are entry markers (walkable grass underneath).
## 'D' is a door cell (walkable road underneath); positions surface in parse()
## so the caller can wire Door scenes with target metadata.
const TILE_DEFS := {
	".": {"color": Color(0.55, 0.75, 0.45), "solid": false}, # grass
	",": {"color": Color(0.50, 0.72, 0.42), "solid": false}, # grass alt
	"#": {"color": Color(0.45, 0.36, 0.30), "solid": true},  # building/wall
	"r": {"color": Color(0.62, 0.58, 0.52), "solid": false}, # road
	"p": {"color": Color(0.80, 0.74, 0.62), "solid": false}, # plaza paving
	"w": {"color": Color(0.35, 0.55, 0.80), "solid": true},  # water
	"t": {"color": Color(0.25, 0.50, 0.30), "solid": true},  # tree
	"f": {"color": Color(0.85, 0.60, 0.75), "solid": false}, # flowers
	"b": {"color": Color(0.60, 0.45, 0.30), "solid": false}, # bridge
}

const ENTRY_UNDERLAY := "."
const DOOR_UNDERLAY := "r"


## Pure: layout text -> structured map data. Unit-testable, no scene tree needed.
## Returns {size: Vector2i, rows: PackedStringArray, entries: Dictionary[String, Vector2],
##          doors: Array[Vector2i]}.
static func parse(layout: String) -> Dictionary:
	var rows := PackedStringArray()
	var width := 0
	for raw_line in layout.split("\n"):
		var line := raw_line.strip_edges(false, true)
		if line.strip_edges().is_empty():
			continue
		rows.append(line)
		width = maxi(width, line.length())

	var entries: Dictionary = {}
	var doors: Array[Vector2i] = []
	for y in rows.size():
		# Pad short rows with grass so the grid is rectangular.
		if rows[y].length() < width:
			rows[y] = rows[y] + ".".repeat(width - rows[y].length())
		for x in width:
			var ch := rows[y][x]
			if ch >= "1" and ch <= "9":
				entries["Entry" + ch] = cell_center(Vector2i(x, y))
			elif ch == "D":
				doors.append(Vector2i(x, y))

	return {
		"size": Vector2i(width, rows.size()),
		"rows": rows,
		"entries": entries,
		"doors": doors,
	}


## Pure: is the cell at (x, y) solid (blocks movement)?
static func is_solid(parsed: Dictionary, cell: Vector2i) -> bool:
	var size: Vector2i = parsed["size"]
	if cell.x < 0 or cell.y < 0 or cell.x >= size.x or cell.y >= size.y:
		return true
	var def: Dictionary = TILE_DEFS.get(_render_char(parsed["rows"][cell.y][cell.x]), {})
	return bool(def.get("solid", false))


## Pure: world-space center of a cell.
static func cell_center(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * CELL + CELL / 2.0, cell.y * CELL + CELL / 2.0)


## Pure: world-space bounds of a parsed map (origin at 0,0).
static func bounds_of(parsed: Dictionary) -> Rect2:
	var size: Vector2i = parsed["size"]
	return Rect2(0, 0, size.x * CELL, size.y * CELL)


## Builds the TileMapLayer + entry Marker2Ds under `parent`. Returns the parsed data.
static func build(layout: String, parent: Node) -> Dictionary:
	var parsed := parse(layout)
	var tile_chars: Array = TILE_DEFS.keys()
	var layer := TileMapLayer.new()
	layer.name = "Map"
	layer.tile_set = _make_tile_set(tile_chars)

	var rows: PackedStringArray = parsed["rows"]
	for y in rows.size():
		for x in rows[y].length():
			var idx := tile_chars.find(_render_char(rows[y][x]))
			if idx >= 0:
				layer.set_cell(Vector2i(x, y), 0, Vector2i(idx, 0))
	parent.add_child(layer)

	for entry_name in parsed["entries"]:
		var marker := Marker2D.new()
		marker.name = entry_name
		marker.position = parsed["entries"][entry_name]
		parent.add_child(marker)
	if not parent.has_node("EntryDefault") and not parsed["entries"].is_empty():
		var fallback := Marker2D.new()
		fallback.name = "EntryDefault"
		fallback.position = parsed["entries"].values()[0]
		parent.add_child(fallback)

	return parsed


## Entry/door markers render as their walkable underlay tile.
static func _render_char(ch: String) -> String:
	if ch >= "1" and ch <= "9":
		return ENTRY_UNDERLAY
	if ch == "D":
		return DOOR_UNDERLAY
	return ch if TILE_DEFS.has(ch) else ENTRY_UNDERLAY


## One-row atlas texture: tile i is a 16x16 solid color with a subtle darker
## bottom edge so large fields don't read as flat.
static func _make_tile_set(tile_chars: Array) -> TileSet:
	var img := Image.create(CELL * tile_chars.size(), CELL, false, Image.FORMAT_RGBA8)
	for i in tile_chars.size():
		var color: Color = TILE_DEFS[tile_chars[i]]["color"]
		var edge := color.darkened(0.12)
		for y in CELL:
			for x in CELL:
				img.set_pixel(i * CELL + x, y, edge if y >= CELL - 2 else color)

	var atlas := TileSetAtlasSource.new()
	atlas.texture = ImageTexture.create_from_image(img)
	atlas.texture_region_size = Vector2i(CELL, CELL)

	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(CELL, CELL)
	tile_set.add_physics_layer()
	tile_set.set_physics_layer_collision_layer(0, 1)
	# Source must join the TileSet before tiles get collision polygons —
	# TileData only gains physics layers once its source belongs to the set.
	tile_set.add_source(atlas, 0)

	var half := CELL / 2.0
	var full_cell := PackedVector2Array([
		Vector2(-half, -half), Vector2(half, -half),
		Vector2(half, half), Vector2(-half, half),
	])
	for i in tile_chars.size():
		var coords := Vector2i(i, 0)
		atlas.create_tile(coords)
		if TILE_DEFS[tile_chars[i]]["solid"]:
			var data := atlas.get_tile_data(coords, 0)
			data.add_collision_polygon(0)
			data.set_collision_polygon_points(0, 0, full_cell)

	return tile_set
