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
signal ending_reached(kind: String)
signal restart_requested
signal memory_found(id: String, text: String)  ## "free" — the Lamp is out; "rejoin" — the stair

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
var touch: TouchPad
var keeper: Keeper
var chain: LampChain
var sound: Sound
var card: FloorCard
var pause_menu: PauseMenu
var _camera: Camera2D
var _shake: float = 0.0
var progress: Progress
var options: PlayerOptions = PlayerOptions.new()
var _whispers_said: Dictionary = {}
var _memories_taken: Dictionary = {}

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
	_spawn_sound()
	_spawn_chain()
	_spawn_keeper()
	_spawn_hud()
	_spawn_card()
	_spawn_pause()


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
	umbra.scattered_at.connect(func(_cell: Vector2i) -> void: _shake = 1.0)


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
	_camera = camera


## The Great Lamp cannot be touched while its feeders burn, so the finale is
## the game's own vocabulary at full size rather than a new mechanic.
func _spawn_sound() -> void:
	sound = Sound.new()
	sound.name = "Sound"
	add_child(sound)
	umbra.cast_requested.connect(func(_cell: Vector2i) -> void: sound.play(Sound.Voice.CAST))
	umbra.scattered_at.connect(func(_cell: Vector2i) -> void: sound.play(Sound.Voice.SCATTER, -3.0))
	umbra.reformed_at.connect(func(_cell: Vector2i) -> void: sound.play(Sound.Voice.REFORM, -8.0))
	cling.snuffed.connect(func(_id: String) -> void: sound.play(Sound.Voice.SNUFF, -5.0))
	cling.turned_mirror.connect(func(_cell: Vector2i) -> void: sound.play(Sound.Voice.TURN, -12.0))


func _spawn_chain() -> void:
	if data.chain.is_empty():
		return
	var great_id := data.light_id_at(data.chain["great"])
	var feeders: Array[String] = []
	for cell in data.chain["feeders"]:
		var id := data.light_id_at(cell)
		if not id.is_empty():
			feeders.append(id)
	if great_id.is_empty() or feeders.is_empty():
		push_error("Chamber %s has a chain that points at no lights" % data.id)
		return
	chain = LampChain.new(field, cling, great_id, feeders, 1.0)
	chain.extinguished.connect(func() -> void: _finish("free"))
	chain.extinguishable.connect(func() -> void: hud.say("now. before he reaches you"))


func _spawn_keeper() -> void:
	if data.keeper_cell == Vector2i(-1, -1):
		return
	keeper = Keeper.new()
	keeper.name = "Keeper"
	add_child(keeper)
	keeper.setup(field, data.keeper_cell)
	keeper.reached_her.connect(_on_keeper_reached)


func _on_keeper_reached() -> void:
	# He does not strike her. He simply arrives, and where he stands is lit.
	umbra.state.scatter()


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
	_wire_touch()


func _spawn_card() -> void:
	card = FloorCard.new()
	card.name = "FloorCard"
	add_child(card)
	card.present(data.title, data.subtitle)


func _spawn_pause() -> void:
	pause_menu = PauseMenu.new()
	pause_menu.name = "PauseMenu"
	add_child(pause_menu)
	pause_menu.restart_requested.connect(_on_restart)
	pause_menu.quit_requested.connect(_on_quit)


func _on_restart() -> void:
	pause_menu.close()
	restart_requested.emit()


func _on_quit() -> void:
	pause_menu.close()
	get_tree().change_scene_to_file("res://scenes/Title.tscn")


## The frame kicks when she comes apart — the only screen shake in the game, so
## it still means something when it happens.
func _shake_camera(delta: float) -> void:
	if _camera == null:
		return
	if options.reduced_motion:
		_shake = 0.0
	if _shake <= 0.0:
		_camera.offset = Vector2.ZERO
		return
	_shake = maxf(0.0, _shake - delta * 3.0)
	var amount := _shake * 6.0
	_camera.offset = Vector2(randf_range(-amount, amount), randf_range(-amount, amount))


func _wire_touch() -> void:
	touch = TouchPad.new()
	touch.name = "TouchPad"
	hud.get_node("Canvas").add_child(touch)
	touch.cast_pressed.connect(func() -> void: umbra.try_cast())
	touch.cling_changed.connect(_on_touch_cling)


func _on_touch_cling(down: bool) -> void:
	umbra.touch_cling = down
	if down:
		_on_cling_pressed(umbra.current_cell())
	else:
		cling.release_press()


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
	if touch != null:
		umbra.touch_direction = touch.direction
	if keeper != null and umbra != null:
		keeper.follow(umbra.current_cell())
	_shake_camera(delta)
	_check_memories()
	_check_whispers()
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
	elif cling.is_locked(target):
		hud.set_hint("it will not go out while the three still burn")
	elif cling.is_portable(target):
		hud.set_hint("cling to lift the candle")
	else:
		hud.set_hint("hold cling to smother it")


## Memories sit where she should not want to go. Taking one is permanent, and
## the only thing in the game that makes her stronger.
func _check_memories() -> void:
	if umbra == null or progress == null:
		return
	var cell := umbra.current_cell()
	for memory in data.memories:
		if memory["cell"] != cell:
			continue
		var id := Progress.memory_id(data.id, cell)
		if _memories_taken.has(id) or progress.has_memory(id):
			continue
		_memories_taken[id] = true
		progress.remember(id)
		apply_boons()
		if hud != null:
			hud.say(String(memory["text"]))
		if sound != null:
			sound.play(Sound.Voice.REFORM, -10.0)
		memory_found.emit(id, String(memory["text"]))
		return


## Everything she has ever remembered, plus whatever the player has asked the
## game to go easier on, applied to this body.
func apply_boons() -> void:
	if umbra == null:
		return
	var boons := {"coherence": 0.0, "ink": 0.0}
	if progress != null:
		boons = progress.boons()
	umbra.state.bonus_coherence = boons["coherence"]
	umbra.state.bonus_ink = boons["ink"] + options.bonus_ink()
	umbra.state.drain_scale = options.drain_multiplier()
	if renderer != null:
		renderer.set_high_contrast(options.high_contrast)
	if sound != null:
		sound.volume_scale = options.volume
	umbra.state.coherence = minf(umbra.state.coherence, umbra.state.max_coherence())


## Each whisper lands once, when she first comes close enough to think it.
func _check_whispers() -> void:
	if hud == null or umbra == null:
		return
	var cell := umbra.current_cell()
	for index in data.whispers.size():
		if _whispers_said.has(index):
			continue
		var whisper: Dictionary = data.whispers[index]
		if Vector2(whisper["cell"] - cell).length() <= float(whisper["radius"]):
			_whispers_said[index] = true
			hud.say(String(whisper["text"]))
			if sound != null:
				sound.play(Sound.Voice.WHISPER, -18.0)
			return


func _check_exit() -> void:
	if _exit_fired or umbra == null or data.exit == Vector2i(-1, -1):
		return
	if umbra.current_cell() == data.exit:
		_exit_fired = true
		if chain != null:
			_finish("rejoin")
		else:
			exit_reached.emit()


## The two ways this ends, and the game never says which is right.
func _finish(kind: String) -> void:
	_exit_fired = true
	if umbra != null:
		umbra.input_enabled = false
	ending_reached.emit(kind)
