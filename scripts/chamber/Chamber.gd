class_name Chamber
extends Node2D

## Turns a ChamberData into a live room: collision for walls, a LightField that
## every system reads, Umbra at the spawn, and the exit that ends the floor.
##
## Drawing here is deliberately crude — flat blocks and light pools — because
## the real look lands in R6. What matters now is that what you *see* is a
## direct readout of the simulated field, never a second, disagreeing truth.

signal exit_reached
signal umbra_scattered(cell: Vector2i)

const CELL := ChamberData.CELL_SIZE
const INK_RADIUS := 2.2
const INK_LIFE := 6.0
const UMBRA_SCENE := preload("res://scenes/Umbra.tscn")

@export var chamber_path: String = "res://chambers/cistern.txt"

var data: ChamberData
var field: LightField
var umbra: Umbra

var _exit_fired: bool = false


func _ready() -> void:
	load_chamber(chamber_path)


func load_chamber(path: String) -> void:
	data = ChamberData.from_file(path)
	if not data.is_valid():
		push_error("Chamber %s failed to parse: %s" % [path, ", ".join(data.parse_errors)])
		return
	field = data.build_field()
	_build_walls()
	_spawn_umbra()
	queue_redraw()


func _build_walls() -> void:
	var body := StaticBody2D.new()
	body.name = "Walls"
	body.collision_layer = 1
	# One rectangle per horizontal run of wall cells: far fewer shapes than one
	# per cell, and exactly the same collision.
	for y in data.height:
		var run_start := -1
		for x in range(data.width + 1):
			var solid := x < data.width and data.is_wall(Vector2i(x, y))
			if solid and run_start < 0:
				run_start = x
			elif not solid and run_start >= 0:
				body.add_child(_wall_shape(run_start, x, y))
				run_start = -1
	add_child(body)


func _wall_shape(from_x: int, to_x: int, y: int) -> CollisionShape2D:
	var shape := RectangleShape2D.new()
	var run := to_x - from_x
	shape.size = Vector2(run * CELL, CELL)
	var node := CollisionShape2D.new()
	node.shape = shape
	node.position = Vector2(from_x * CELL + run * CELL * 0.5, y * CELL + CELL * 0.5)
	return node


func _spawn_umbra() -> void:
	umbra = UMBRA_SCENE.instantiate()
	add_child(umbra)
	umbra.bind_field(field, CELL)
	umbra.global_position = data.cell_to_world(data.spawn)
	umbra.cast_requested.connect(_on_cast_requested)
	_attach_camera()
	umbra.scattered_at.connect(func(cell: Vector2i) -> void: umbra_scattered.emit(cell))


## Held close so a room reads as a claustrophobic pool of dark, and clamped to
## the chamber so the void outside the walls never shows.
func _attach_camera() -> void:
	var camera := Camera2D.new()
	camera.name = "ChamberCamera"
	camera.zoom = Vector2(3.0, 3.0)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	var bounds := data.bounds_rect()
	camera.limit_left = int(bounds.position.x)
	camera.limit_top = int(bounds.position.y)
	camera.limit_right = int(bounds.end.x)
	camera.limit_bottom = int(bounds.end.y)
	umbra.add_child(camera)
	camera.make_current()


func _on_cast_requested(cell: Vector2i) -> void:
	field.cast_ink(cell, INK_RADIUS, 1.0, INK_LIFE)
	queue_redraw()


func _process(delta: float) -> void:
	if field == null:
		return
	field.advance(delta)
	_check_exit()
	queue_redraw()


func _check_exit() -> void:
	if _exit_fired or umbra == null or data.exit == Vector2i(-1, -1):
		return
	if umbra.current_cell() == data.exit:
		_exit_fired = true
		exit_reached.emit()


# --- placeholder rendering ----------------------------------------------------


func _draw() -> void:
	if data == null or field == null:
		return
	var levels := field.levels()
	for y in data.height:
		for x in data.width:
			var cell := Vector2i(x, y)
			var rect := Rect2(Vector2(cell * CELL), Vector2(CELL, CELL))
			if data.is_wall(cell):
				draw_rect(rect, Color(0.10, 0.09, 0.14))
				continue
			var level: float = levels[y * data.width + x]
			draw_rect(rect, _floor_color(level))
	if data.exit != Vector2i(-1, -1):
		draw_rect(Rect2(Vector2(data.exit * CELL), Vector2(CELL, CELL)), Color(0.25, 0.9, 0.75, 0.5))


## Cold void → warm glare, with a visible step exactly at the shade threshold so
## the player can read safety at a glance instead of guessing at a gradient.
func _floor_color(level: float) -> Color:
	var void_color := Color(0.05, 0.05, 0.09)
	var shade_color := Color(0.11, 0.12, 0.20)
	var warm := Color(0.98, 0.85, 0.55)
	if level <= LightField.SHADE_MAX:
		return void_color.lerp(shade_color, level / LightField.SHADE_MAX)
	var t := (level - LightField.SHADE_MAX) / (1.0 - LightField.SHADE_MAX)
	return Color(0.30, 0.26, 0.28).lerp(warm, t)
