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
var cling: ClingController
var hud: Hud
var renderer: ChamberRenderer
var wardens: Array[Warden] = []
var movers: Array[MovingLight] = []

var _exit_fired: bool = false


func _ready() -> void:
	load_chamber(chamber_path)


func load_chamber(path: String) -> void:
	data = ChamberData.from_file(path)
	if not data.is_valid():
		push_error("Chamber %s failed to parse: %s" % [path, ", ".join(data.parse_errors)])
		return
	field = data.build_field()
	cling = ClingController.new(field, data.lights)
	for definition in data.movers:
		movers.append(MovingLight.from_definition(definition))
	_build_walls()
	_spawn_renderer()
	_spawn_umbra()
	_spawn_wardens()
	_spawn_hud()


## Behind everything, so Umbra reads as a hole punched in the light.
func _spawn_renderer() -> void:
	renderer = ChamberRenderer.new()
	renderer.name = "Renderer"
	renderer.z_index = -10
	add_child(renderer)
	renderer.setup(data, field)


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
	umbra.cling_pressed.connect(_on_cling_pressed)
	umbra.cling_released.connect(cling.release_press)
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


## Wardens are spawned after Umbra so their lanterns light a room she is
## already standing in — no frame where the floor is dark by accident.
func _spawn_wardens() -> void:
	for definition in data.wardens:
		var route := PatrolRoute.new(
			definition["waypoints"], definition["mode"], definition["speed"]
		)
		if not route.is_valid():
			push_error("Warden %s has an unwalkable beat" % definition["id"])
			continue
		var warden := Warden.new()
		warden.name = String(definition["id"])
		warden.lantern_radius = definition["lantern"]
		add_child(warden)
		warden.setup(String(definition["id"]), route, field, cling)
		wardens.append(warden)


const HUD_SCENE := preload("res://scenes/Hud.tscn")


func _spawn_hud() -> void:
	hud = HUD_SCENE.instantiate()
	add_child(hud)
	hud.bind(umbra.state)


func _on_cling_pressed(cell: Vector2i) -> void:
	cling.press(cell)


func _on_cast_requested(cell: Vector2i) -> void:
	field.cast_ink(cell, INK_RADIUS, 1.0, INK_LIFE)


func _process(delta: float) -> void:
	if field == null:
		return
	field.advance(delta)
	for mover in movers:
		mover.advance(delta)
		mover.apply(field)
	if umbra != null:
		cling.tick(delta, umbra.current_cell(), umbra.is_clinging())
		_update_hud()
	if renderer != null:
		renderer.advance(delta, ChamberRenderer.dread_for(umbra.state if umbra else null))
	_check_exit()


## The only text the game ever shows during play: what this light will do if you
## reach for it.
func _update_hud() -> void:
	if hud == null:
		return
	hud.set_glare(umbra.glare())
	hud.set_smother(cling.smother_fraction())
	if cling.is_holding():
		hud.set_hint("carrying a candle — cling to set it down")
		return
	var target := cling.target_near(umbra.current_cell())
	if target.is_empty():
		hud.set_hint("")
	elif cling.is_portable(target):
		hud.set_hint("cling to lift the candle")
	else:
		hud.set_hint("hold cling to smother it")


func _check_exit() -> void:
	if _exit_fired or umbra == null or data.exit == Vector2i(-1, -1):
		return
	if umbra.current_cell() == data.exit:
		_exit_fired = true
		exit_reached.emit()
