class_name MapBuilder
extends RefCounted

## Builds a playable world from an ASCII layout string.
## Each character is one 16x16 cell. Ground renders on a single TileMapLayer
## using regions of the CC0 Ninja Adventure tilesets (assets/tiles). Prop
## characters (trees, flowers, houses) become y-sorted Sprite2Ds with
## StaticBody2D footprints, so the player walks behind them Pokemon-style.

const CELL := 16

## Ground characters -> solidity (collision) semantics.
const TILE_DEFS := {
	".": {"solid": false}, # grass
	",": {"solid": false}, # grass variant
	"#": {"solid": true},  # building/wall
	"r": {"solid": false}, # road/path
	"p": {"solid": false}, # plaza/paving
	"w": {"solid": true},  # water
	"f": {"solid": false}, # flowers (sprite prop, walkable)
	"b": {"solid": false}, # bridge / interior pavers
}

## Render key -> [atlas source index into ART_SOURCES, tile coords].
## w_* keys are water bank variants picked by water_variant() from the
## grass-ringed pond autotile block.
const ART_TILES := {
	".": [0, Vector2i(1, 4)],
	",": [0, Vector2i(3, 4)],
	"r": [1, Vector2i(1, 8)],
	"p": [1, Vector2i(1, 1)],
	"w": [3, Vector2i(1, 7)],
	"b": [2, Vector2i(1, 13)],
	"#": [2, Vector2i(9, 1)],
	"w_tl": [3, Vector2i(0, 6)],
	"w_t": [3, Vector2i(1, 6)],
	"w_tr": [3, Vector2i(2, 6)],
	"w_l": [3, Vector2i(0, 7)],
	"w_r": [3, Vector2i(2, 7)],
	"w_bl": [3, Vector2i(0, 8)],
	"w_b": [3, Vector2i(1, 8)],
	"w_br": [3, Vector2i(2, 8)],
}

const ART_SOURCES := [
	"res://assets/tiles/TilesetField.png",
	"res://assets/tiles/tileset_floor.png",
	"res://assets/tiles/tileset_interior_floor.png",
	"res://assets/tiles/TilesetWater.png",
]

## Prop chars -> sprite region + footprint. Footprint cells block movement
## when solid; the sprite is y-sorted at the footprint's bottom edge.
const PROP_DEFS := {
	"t": {"tex": 0, "region": Rect2(0, 0, 32, 40), "size": Vector2i(1, 1), "solid": true},
	"f": {"tex": 0, "region": Rect2(16, 176, 16, 16), "size": Vector2i(1, 1), "solid": false},
	"H": {"tex": 1, "region": Rect2(0, 0, 64, 48), "size": Vector2i(4, 3), "solid": true},
	"I": {"tex": 1, "region": Rect2(64, 0, 64, 48), "size": Vector2i(4, 3), "solid": true},
	"J": {"tex": 1, "region": Rect2(128, 0, 64, 48), "size": Vector2i(4, 3), "solid": true},
	"K": {"tex": 1, "region": Rect2(192, 0, 64, 48), "size": Vector2i(4, 3), "solid": true},
	"m": {"tex": 2, "region": Rect2(112, 0, 16, 16), "size": Vector2i(1, 1), "solid": true},
	"n": {"tex": 1, "region": Rect2(64, 48, 16, 16), "size": Vector2i(1, 1), "solid": true},
	"o": {"tex": 1, "region": Rect2(0, 48, 16, 16), "size": Vector2i(1, 1), "solid": true},
	"q": {"tex": 1, "region": Rect2(32, 48, 16, 16), "size": Vector2i(1, 1), "solid": true},
	"u": {"tex": 1, "region": Rect2(80, 48, 16, 16), "size": Vector2i(1, 1), "solid": true},
	"l": {"tex": 1, "region": Rect2(96, 48, 16, 16), "size": Vector2i(1, 1), "solid": true},
	"x": {"tex": 1, "region": Rect2(112, 48, 16, 16), "size": Vector2i(1, 1), "solid": true},
	"c": {"tex": 2, "region": Rect2(128, 0, 16, 16), "size": Vector2i(1, 1), "solid": false},
}

const PROP_TEXTURES := [
	"res://assets/tiles/TilesetNature.png",
	"res://assets/tiles/TilesetHouse.png",
	"res://assets/tiles/InteriorElements.png",
]

const PAVED_CHARS := "bp"


## Pure: layout text -> structured map data. Unit-testable, no scene tree needed.
## Returns {size, rows, entries, doors, spawns, props: [{char, cell}],
## solid_extra: {cell: true}}. 'e' cells mark enemy spawn points.
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
	var spawns: Array[Vector2i] = []
	var props: Array[Dictionary] = []
	var solid_extra: Dictionary = {}
	for y in rows.size():
		if rows[y].length() < width:
			rows[y] = rows[y] + ".".repeat(width - rows[y].length())
		for x in width:
			var ch := rows[y][x]
			if ch >= "1" and ch <= "9":
				entries["Entry" + ch] = cell_center(Vector2i(x, y))
			elif ch == "D":
				doors.append(Vector2i(x, y))
			elif ch == "e":
				spawns.append(Vector2i(x, y))
			elif PROP_DEFS.has(ch):
				props.append({"char": ch, "cell": Vector2i(x, y)})
				if PROP_DEFS[ch]["solid"]:
					var size: Vector2i = PROP_DEFS[ch]["size"]
					for fy in range(y, y + size.y):
						for fx in range(x, x + size.x):
							solid_extra[Vector2i(fx, fy)] = true

	return {
		"size": Vector2i(width, rows.size()),
		"rows": rows,
		"entries": entries,
		"doors": doors,
		"spawns": spawns,
		"props": props,
		"solid_extra": solid_extra,
	}


## Pure: does the cell at (x, y) block movement?
static func is_solid(parsed: Dictionary, cell: Vector2i) -> bool:
	var size: Vector2i = parsed["size"]
	if cell.x < 0 or cell.y < 0 or cell.x >= size.x or cell.y >= size.y:
		return true
	if parsed["solid_extra"].has(cell):
		return true
	var ch: String = parsed["rows"][cell.y][cell.x]
	var def: Dictionary = TILE_DEFS.get(_render_char(parsed["rows"], cell.x, cell.y), {})
	if PROP_DEFS.has(ch):
		return false # covered by solid_extra above when solid
	return bool(def.get("solid", false))


## Pure: world-space center of a cell.
static func cell_center(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * CELL + CELL / 2.0, cell.y * CELL + CELL / 2.0)


## Pure: world-space bounds of a parsed map (origin at 0,0).
static func bounds_of(parsed: Dictionary) -> Rect2:
	var size: Vector2i = parsed["size"]
	return Rect2(0, 0, size.x * CELL, size.y * CELL)


## Builds the ground TileMapLayer, prop sprites and entry Marker2Ds under
## `parent`, enabling y-sort so the player renders behind props. Returns
## the parsed data.
static func build(layout: String, parent: Node) -> Dictionary:
	var parsed := parse(layout)
	if parent is Node2D:
		(parent as Node2D).y_sort_enabled = true

	var render_keys: Array = ART_TILES.keys()
	var layer := TileMapLayer.new()
	layer.name = "Map"
	layer.tile_set = _make_tile_set(render_keys)

	var rows: PackedStringArray = parsed["rows"]
	for y in rows.size():
		for x in rows[y].length():
			var key := _render_char(rows, x, y)
			if key == "w":
				key = water_variant(rows, x, y)
			var idx := render_keys.find(key)
			if idx >= 0:
				layer.set_cell(Vector2i(x, y), 0, Vector2i(idx, 0))
	parent.add_child(layer)

	_spawn_props(parsed, parent)

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


## Pure: which water tile a water cell renders as, from its bank sides.
## Bridges ('b') count as water so banks don't wrap around them.
static func water_variant(rows: PackedStringArray, x: int, y: int) -> String:
	var vert := ""
	if not _is_waterish(rows, x, y - 1):
		vert = "t"
	elif not _is_waterish(rows, x, y + 1):
		vert = "b"
	var horiz := ""
	if not _is_waterish(rows, x - 1, y):
		horiz = "l"
	elif not _is_waterish(rows, x + 1, y):
		horiz = "r"
	if vert.is_empty() and horiz.is_empty():
		return "w"
	return "w_" + vert + horiz


static func _is_waterish(rows: PackedStringArray, x: int, y: int) -> bool:
	if y < 0 or y >= rows.size() or x < 0 or x >= rows[y].length():
		return true
	return rows[y][x] == "w" or rows[y][x] == "b"


## Pure: what ground char a cell renders as. Entries and props show a
## walkable neighbor's ground; doors show pavement so they read as mats.
static func _render_char(rows: PackedStringArray, x: int, y: int) -> String:
	var ch := rows[y][x]
	if TILE_DEFS.has(ch):
		return ch
	if ch == "D":
		var near := _walkable_neighbor(rows, x, y)
		return near if PAVED_CHARS.contains(near) else "r"
	return _walkable_neighbor(rows, x, y)


static func _walkable_neighbor(rows: PackedStringArray, x: int, y: int) -> String:
	for offset: Vector2i in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]:
		var nx: int = x + offset.x
		var ny: int = y + offset.y
		if ny < 0 or ny >= rows.size() or nx < 0 or nx >= rows[ny].length():
			continue
		var nch := rows[ny][nx]
		if TILE_DEFS.has(nch) and not TILE_DEFS[nch]["solid"]:
			return nch
	return "."


static func _spawn_props(parsed: Dictionary, parent: Node) -> void:
	var textures: Array = []
	for path: String in PROP_TEXTURES:
		textures.append(load(path) if ResourceLoader.exists(path) else null)

	for prop: Dictionary in parsed["props"]:
		var def: Dictionary = PROP_DEFS[prop["char"]]
		var tex: Texture2D = textures[def["tex"]]
		if tex == null:
			continue
		var cell: Vector2i = prop["cell"]
		var size: Vector2i = def["size"]
		var region: Rect2 = def["region"]
		var foot_w := size.x * CELL
		var foot_h := size.y * CELL
		var bottom := Vector2(cell.x * CELL + foot_w / 2.0, (cell.y + size.y) * CELL)

		var sprite := Sprite2D.new()
		sprite.texture = tex
		sprite.region_enabled = true
		sprite.region_rect = region
		sprite.position = bottom
		sprite.offset = Vector2(0, -region.size.y / 2.0)
		parent.add_child(sprite)

		if def["solid"]:
			var body := StaticBody2D.new()
			body.collision_layer = 1
			var shape := CollisionShape2D.new()
			var rect := RectangleShape2D.new()
			rect.size = Vector2(foot_w, foot_h)
			shape.shape = rect
			body.add_child(shape)
			body.position = Vector2(0, -foot_h / 2.0)
			sprite.add_child(body)


## One-row atlas per ground char from ART_TILES regions; solid chars get a
## full-cell collision polygon. Art textures ship in the repo, but a color
## fallback keeps headless tests meaningful if a region is missing.
static func _make_tile_set(render_keys: Array) -> TileSet:
	var img := Image.create(CELL * render_keys.size(), CELL, false, Image.FORMAT_RGBA8)
	for i in render_keys.size():
		var art: Array = ART_TILES.get(render_keys[i], [])
		var painted := false
		if not art.is_empty() and ResourceLoader.exists(ART_SOURCES[art[0]]):
			var src: Texture2D = load(ART_SOURCES[art[0]])
			var src_img := src.get_image()
			if src_img != null:
				var coords: Vector2i = art[1]
				img.blit_rect(
					src_img,
					Rect2i(coords.x * CELL, coords.y * CELL, CELL, CELL),
					Vector2i(i * CELL, 0)
				)
				painted = true
		if not painted:
			img.fill_rect(Rect2i(i * CELL, 0, CELL, CELL), Color(0.5, 0.5, 0.5))

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
	for i in render_keys.size():
		var coords := Vector2i(i, 0)
		atlas.create_tile(coords)
		var key: String = render_keys[i]
		var solid: bool = key.begins_with("w") or bool(TILE_DEFS.get(key, {}).get("solid", false))
		if solid:
			var data := atlas.get_tile_data(coords, 0)
			data.add_collision_polygon(0)
			data.set_collision_polygon_points(0, 0, full_cell)

	return tile_set
