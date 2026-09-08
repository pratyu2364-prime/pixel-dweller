class_name ChamberData
extends RefCounted

## Parses an ASCII chamber into everything the game needs to build a room.
##
## Rooms are authored as plain text under `chambers/` so a floor of the Sunken
## Observatory is a thing you can read and edit in a diff. Parsing is pure and
## strict: a malformed room fails loudly in tests, not silently at runtime.
##
##   #  wall            .  floor           space  floor
##   @  Umbra's spawn   >  exit to the next chamber
##   o  lamp   (radius 7, full)     c  candle (radius 4, soft)
##   O  brazier(radius 10, full)    s  sunbeam — baked ambient light on the floor
##   ~  a floor cell that is always deep shade (a nook, a drape's shadow)

const CELL_SIZE := 16

const LAMP_RADIUS := 7.0
const CANDLE_RADIUS := 4.0
const BRAZIER_RADIUS := 10.0
const CANDLE_INTENSITY := 0.85
const SUNBEAM_LEVEL := 0.9

var id: String = ""
var title: String = ""
var subtitle: String = ""
var ambient: float = 0.0
var width: int = 0
var height: int = 0
var spawn: Vector2i = Vector2i.ZERO
var exit: Vector2i = Vector2i(-1, -1)
var walls: Array[Vector2i] = []
var sunbeams: Array[Vector2i] = []
var nooks: Array[Vector2i] = []
var lights: Array[Dictionary] = []  ## {id, cell, radius, intensity, kind}
var wardens: Array[Dictionary] = []  ## {id, waypoints, mode, speed, lantern}
var movers: Array[Dictionary] = []  ## orbiting lamps and sweeping beams
var mirrors: Array[Dictionary] = []  ## {cell, orientation}
var rays: Array[Dictionary] = []  ## {id, cell, direction, intensity, range}
var memories: Array[Dictionary] = []  ## {cell, text}
var _memory_lines: Dictionary = {}  ## cell -> text, bound to glyphs after the map
var whispers: Array[Dictionary] = []  ## {cell, radius, text}
var keeper_cell: Vector2i = Vector2i(-1, -1)
var chain: Dictionary = {}  ## {great: Vector2i, feeders: Array[Vector2i]}
var next_id: String = ""  ## the chamber this one leads to; empty ends the run
var parse_errors: Array[String] = []

var _rows: PackedStringArray = PackedStringArray()


static func from_file(path: String) -> ChamberData:
	var data := ChamberData.new()
	if not FileAccess.file_exists(path):
		data.parse_errors.append("missing chamber file: %s" % path)
		return data
	return ChamberData.from_text(FileAccess.open(path, FileAccess.READ).get_as_text())


## Text is `key: value` front matter, a blank line, then the ASCII map.
static func from_text(text: String) -> ChamberData:
	var data := ChamberData.new()
	var lines := text.split("\n")
	var in_map := false
	var map_lines: Array[String] = []
	for raw in lines:
		var line := String(raw).trim_suffix("\r")
		if not in_map:
			if line.strip_edges().is_empty():
				in_map = true
				continue
			data._read_front_matter(line)
			continue
		map_lines.append(line)
	while not map_lines.is_empty() and map_lines[map_lines.size() - 1].strip_edges().is_empty():
		map_lines.remove_at(map_lines.size() - 1)
	data._read_map(map_lines)
	return data


func _read_front_matter(line: String) -> void:
	if line.begins_with("//"):
		return
	var parts := line.split(":", true, 1)
	if parts.size() != 2:
		parse_errors.append("bad front matter line: %s" % line)
		return
	var key := parts[0].strip_edges()
	var value := parts[1].strip_edges()
	match key:
		"id":
			id = value
		"title":
			title = value
		"subtitle":
			subtitle = value
		"ambient":
			ambient = clampf(value.to_float(), 0.0, 1.0)
		"next":
			next_id = value
		"warden":
			_read_warden(value)
		"keeper":
			_read_keeper(value)
		"chain":
			_read_chain(value)
		"ray":
			_read_ray(value)
		"memory":
			_read_memory(value)
		"whisper":
			_read_whisper(value)
		"orbit":
			_read_mover(MovingLight.Kind.ORBIT, value)
		"sweep":
			_read_mover(MovingLight.Kind.SWEEP, value)
		_:
			parse_errors.append("unknown key: %s" % key)


## `warden: id=w1 route=(5,3)>(20,3) mode=pingpong speed=2.4 lantern=6`
## Routes live in front matter rather than in glyphs because a beat is a path,
## and a path drawn in ASCII stops being readable the moment two of them cross.
func _read_warden(value: String) -> void:
	var warden := {
		"id": "warden_%d" % wardens.size(),
		"waypoints": [] as Array[Vector2i],
		"mode": PatrolRoute.Mode.PING_PONG,
		"speed": 2.4,
		"lantern": 6.0,
	}
	for token in value.split(" ", false):
		var pair := String(token).split("=", true, 1)
		if pair.size() != 2:
			parse_errors.append("bad warden token: %s" % token)
			continue
		match pair[0]:
			"id":
				warden["id"] = pair[1]
			"route":
				warden["waypoints"] = PatrolRoute.parse_waypoints(pair[1])
			"mode":
				warden["mode"] = (
					PatrolRoute.Mode.LOOP if pair[1] == "loop" else PatrolRoute.Mode.PING_PONG
				)
			"speed":
				warden["speed"] = pair[1].to_float()
			"lantern":
				warden["lantern"] = pair[1].to_float()
			_:
				parse_errors.append("unknown warden key: %s" % pair[0])
	var waypoints: Array = warden["waypoints"]
	if waypoints.size() < 2:
		parse_errors.append("warden %s needs at least two route points" % warden["id"])
	wardens.append(warden)


## `whisper: at=(3,5) radius=3 the light does not like you`
## Teaching happens in the room, in her own voice, once — never in a tooltip
## and never in a menu the player has to be told to open.
## `ray: id=dawn cell=(1,9) dir=(1,0) range=34`
func _read_keeper(value: String) -> void:
	for token in value.split(" ", false):
		var pair := String(token).split("=", true, 1)
		if pair.size() == 2 and pair[0] == "at":
			var point := MovingLight._parse_point(pair[1])
			keeper_cell = Vector2i(roundi(point.x), roundi(point.y))
		else:
			parse_errors.append("bad keeper token: %s" % token)
	if keeper_cell == Vector2i(-1, -1):
		parse_errors.append("keeper has nowhere to start")


## `chain: great=(18,9) feeders=(12,6),(21,6),(18,14)`
## Written as cells rather than ids because a chamber file should not have to
## know how light ids are numbered.
func _read_chain(value: String) -> void:
	var feeders: Array[Vector2i] = []
	var great := Vector2i(-1, -1)
	for token in value.split(" ", false):
		var pair := String(token).split("=", true, 1)
		if pair.size() != 2:
			parse_errors.append("bad chain token: %s" % token)
			continue
		if pair[0] == "great":
			var point := MovingLight._parse_point(pair[1])
			great = Vector2i(roundi(point.x), roundi(point.y))
		elif pair[0] == "feeders":
			for part in pair[1].split("),", false):
				var feeder := MovingLight._parse_point(part if part.ends_with(")") else part + ")")
				feeders.append(Vector2i(roundi(feeder.x), roundi(feeder.y)))
		else:
			parse_errors.append("unknown chain key: %s" % pair[0])
	if great == Vector2i(-1, -1) or feeders.is_empty():
		parse_errors.append("a chain needs a great lamp and at least one feeder")
	chain = {"great": great, "feeders": feeders}


## The generated id of whatever light sits on a cell, or "" if none does.
func light_id_at(cell: Vector2i) -> String:
	for light in lights:
		if light["cell"] == cell:
			return String(light["id"])
	return ""


func _read_ray(value: String) -> void:
	var ray := {
		"id": "ray_%d" % rays.size(),
		"cell": Vector2i.ZERO,
		"direction": Vector2i.RIGHT,
		"intensity": 1.0,
		"range": 30,
	}
	for token in value.split(" ", false):
		var pair := String(token).split("=", true, 1)
		if pair.size() != 2:
			parse_errors.append("bad ray token: %s" % token)
			continue
		var point := MovingLight._parse_point(pair[1])
		match pair[0]:
			"id":
				ray["id"] = pair[1]
			"cell":
				ray["cell"] = Vector2i(roundi(point.x), roundi(point.y))
			"dir":
				ray["direction"] = Vector2i(roundi(point.x), roundi(point.y))
			"intensity":
				ray["intensity"] = pair[1].to_float()
			"range":
				ray["range"] = int(pair[1].to_int())
			_:
				parse_errors.append("unknown ray key: %s" % pair[0])
	if ray["direction"] == Vector2i.ZERO:
		parse_errors.append("ray %s points nowhere" % ray["id"])
	rays.append(ray)


## `memory: at=(21,6) she left a window open, once, and you touched the sill`
## The glyph places it; this line gives it something to say. A memory with no
## line is a pickup, and PENUMBRA does not want pickups.
func _read_memory(value: String) -> void:
	var cell := Vector2i(-1, -1)
	var words: Array[String] = []
	for token in value.split(" ", false):
		var pair := String(token).split("=", true, 1)
		if pair.size() == 2 and pair[0] == "at":
			var point := MovingLight._parse_point(pair[1])
			cell = Vector2i(roundi(point.x), roundi(point.y))
		else:
			words.append(String(token))
	if cell == Vector2i(-1, -1) or words.is_empty():
		parse_errors.append("a memory needs a place and something to say")
		return
	# Front matter is read before the map, so the line waits for its glyph.
	_memory_lines[cell] = " ".join(words)


func _read_whisper(value: String) -> void:
	var whisper := {"cell": Vector2i.ZERO, "radius": 3.0, "text": ""}
	var words: Array[String] = []
	for token in value.split(" ", false):
		var text := String(token)
		var pair := text.split("=", true, 1)
		if pair.size() == 2 and pair[0] == "at":
			var point := MovingLight._parse_point(pair[1])
			whisper["cell"] = Vector2i(roundi(point.x), roundi(point.y))
		elif pair.size() == 2 and pair[0] == "radius":
			whisper["radius"] = pair[1].to_float()
		else:
			words.append(text)
	whisper["text"] = " ".join(words)
	if whisper["text"].is_empty():
		parse_errors.append("whisper at %s has nothing to say" % whisper["cell"])
	whispers.append(whisper)


func _read_mover(kind: int, value: String) -> void:
	var mover := MovingLight.from_tokens(kind, value, movers.size())
	for error in mover["errors"]:
		parse_errors.append("mover %s: %s" % [mover["id"], error])
	movers.append(mover)


func _read_map(map_lines: Array[String]) -> void:
	if map_lines.is_empty():
		parse_errors.append("chamber has no map")
		return
	height = map_lines.size()
	for line in map_lines:
		width = maxi(width, line.length())
	var light_index := 0
	var found_spawn := false
	for y in height:
		var line: String = map_lines[y]
		_rows.append(line.rpad(width, " "))
		for x in width:
			var cell := Vector2i(x, y)
			var glyph := " " if x >= line.length() else line[x]
			match glyph:
				"#":
					walls.append(cell)
				".", " ":
					pass
				"~":
					nooks.append(cell)
				"/", "\\":
					mirrors.append({"cell": cell, "orientation": glyph})
				"s":
					sunbeams.append(cell)
				"*":
					memories.append({"cell": cell, "text": ""})
				"@":
					spawn = cell
					found_spawn = true
				">":
					exit = cell
				"o":
					lights.append(_light("lamp", light_index, cell, LAMP_RADIUS, 1.0))
					light_index += 1
				"O":
					lights.append(_light("brazier", light_index, cell, BRAZIER_RADIUS, 1.0))
					light_index += 1
				"c":
					lights.append(
						_light("candle", light_index, cell, CANDLE_RADIUS, CANDLE_INTENSITY)
					)
					light_index += 1
				_:
					parse_errors.append("unknown glyph '%s' at %d,%d" % [glyph, x, y])
	for memory in memories:
		memory["text"] = String(_memory_lines.get(memory["cell"], ""))
		if String(memory["text"]).is_empty():
			parse_errors.append("the memory at %s has nothing to say" % memory["cell"])
	for cell in _memory_lines:
		var placed := false
		for memory in memories:
			placed = placed or memory["cell"] == cell
		if not placed:
			parse_errors.append("memory line at %s has no * on the map" % cell)
	if not found_spawn:
		parse_errors.append("chamber has no @ spawn")


func _light(kind: String, index: int, cell: Vector2i, radius: float, intensity: float) -> Dictionary:
	return {
		"id": "%s_%d" % [kind, index],
		"kind": kind,
		"cell": cell,
		"radius": radius,
		"intensity": intensity,
	}


func is_valid() -> bool:
	return parse_errors.is_empty()


func in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < width and cell.y < height


func glyph_at(cell: Vector2i) -> String:
	if not in_bounds(cell) or cell.y >= _rows.size():
		return "#"
	return _rows[cell.y][cell.x]


func is_wall(cell: Vector2i) -> bool:
	return glyph_at(cell) == "#"


## The LightField this chamber describes: walls occlude, sunbeams and nooks bake
## into the ambient layer, and every glyph light becomes a named emitter.
func build_field() -> LightField:
	var field := LightField.new(maxi(width, 1), maxi(height, 1), ambient)
	for cell in walls:
		field.set_opaque(cell, true)
	for cell in sunbeams:
		field.set_ambient_at(cell, SUNBEAM_LEVEL)
	for cell in nooks:
		field.set_nook(cell, true)
	for light in lights:
		field.emit(light["id"], light["cell"], light["radius"], light["intensity"])
	for mirror in mirrors:
		field.set_mirror(mirror["cell"], mirror["orientation"])
	for ray in rays:
		field.add_ray(
			LightField.LightRay.new(
				ray["id"], ray["cell"], ray["direction"], ray["intensity"], ray["range"]
			)
		)
	for definition in movers:
		MovingLight.from_definition(definition).install(field, definition["light"])
	return field


## Floor cells reachable from the spawn on foot — used to prove a chamber is
## solvable before it ever ships.
func reachable_floor() -> Dictionary:
	var seen := {spawn: true}
	var queue: Array[Vector2i] = [spawn]
	var head := 0
	while head < queue.size():
		var cell: Vector2i = queue[head]
		head += 1
		for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = cell + offset
			if seen.has(next) or not in_bounds(next) or is_wall(next):
				continue
			seen[next] = true
			queue.append(next)
	return seen


func exit_is_reachable() -> bool:
	return exit != Vector2i(-1, -1) and reachable_floor().has(exit)


func cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell * CELL_SIZE) + Vector2.ONE * (CELL_SIZE * 0.5)


func bounds_rect() -> Rect2:
	return Rect2(Vector2.ZERO, Vector2(width, height) * CELL_SIZE)
