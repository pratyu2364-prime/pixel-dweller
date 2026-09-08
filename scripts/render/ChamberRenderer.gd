class_name ChamberRenderer
extends Sprite2D

## Draws the chamber by handing the simulated LightField to a shader, one texel
## per cell. Nothing here decides anything: if the picture and the rules ever
## disagree, this file is wrong.

const SHADER := preload("res://shaders/chamber.gdshader")

var data: ChamberData
var field: LightField

var _pixels: PackedByteArray = PackedByteArray()
var _image: Image
var _texture: ImageTexture
var _material: ShaderMaterial
var _time: float = 0.0
var _shake: float = 0.0
var _shake_origin: Vector2 = Vector2.ZERO


func setup(p_data: ChamberData, p_field: LightField) -> void:
	data = p_data
	field = p_field
	_image = Image.create(data.width, data.height, false, Image.FORMAT_RGB8)
	_texture = ImageTexture.create_from_image(_image)

	_material = ShaderMaterial.new()
	_material.shader = SHADER
	_material.set_shader_parameter("light_tex", _texture)
	_material.set_shader_parameter("grid_size", Vector2(data.width, data.height))
	_material.set_shader_parameter("shade_max", LightField.SHADE_MAX)
	_material.set_shader_parameter("contrast_boost", 0.0)
	_material.set_shader_parameter("flicker_amount", 1.0)
	material = _material

	# A blank 1x1 sprite stretched over the room: the shader paints everything.
	var blank := Image.create(1, 1, false, Image.FORMAT_RGB8)
	blank.fill(Color.WHITE)
	texture = ImageTexture.create_from_image(blank)
	centered = false
	var bounds := data.bounds_rect()
	scale = bounds.size
	position = bounds.position

	refresh()


## High contrast widens the gap between shade and glare instead of recolouring
## anything: the safety line stays exactly where the rules put it, it just gets
## harder to misread.
func set_high_contrast(enabled: bool) -> void:
	if _material != null:
		_material.set_shader_parameter("contrast_boost", 1.0 if enabled else 0.0)


func set_reduced_motion(enabled: bool) -> void:
	if _material != null:
		_material.set_shader_parameter("flicker_amount", 0.0 if enabled else 1.0)


## Repacks the field into the texture. Called every frame — the grid is tiny
## (a room is ~40x22 texels), so this is cheaper than any per-cell node.
func refresh() -> void:
	if field == null or _image == null:
		return
	var levels := field.levels()
	if _pixels.size() != data.width * data.height * 3:
		_prime_static_channels()
	# Only the light channel changes between frames; walls and the exit are
	# baked once. Writing raw bytes avoids a Color per cell, every frame.
	for i in levels.size():
		_pixels[i * 3] = int(clampf(levels[i], 0.0, 1.0) * 255.0)
	_image.set_data(data.width, data.height, false, Image.FORMAT_RGB8, _pixels)
	_texture.update(_image)


func _prime_static_channels() -> void:
	_pixels = PackedByteArray()
	_pixels.resize(data.width * data.height * 3)
	for y in data.height:
		for x in data.width:
			var cell := Vector2i(x, y)
			var i := (y * data.width + x) * 3
			_pixels[i + 1] = 255 if data.is_wall(cell) else 0
			_pixels[i + 2] = 255 if cell == data.exit else 0


## Mirrors are drawn as glass, above the light pass: the one solid thing in a
## chamber that answers to the player.
func _draw() -> void:
	if data == null:
		return
	var cell_size := float(ChamberData.CELL_SIZE)
	for mirror in data.mirrors:
		var at: Vector2i = mirror["cell"]
		var orientation: String = field.mirror_at(at)
		var origin := (Vector2(at) - Vector2(data.bounds_rect().position) / cell_size)
		var base := origin * cell_size + Vector2.ONE * cell_size * 0.5
		var span := Vector2(cell_size * 0.42, cell_size * 0.42)
		var from := base + (Vector2(-span.x, span.y) if orientation == "/" else -span)
		var to := base + (Vector2(span.x, -span.y) if orientation == "/" else span)
		draw_line(from, to, Color(0.75, 0.90, 1.0, 0.85), 2.0)
		draw_line(from, to, Color(1.0, 1.0, 1.0, 0.25), 4.0)


func advance(delta: float, dread: float) -> void:
	_time += delta
	if _material == null:
		return
	_material.set_shader_parameter("time_seconds", _time)
	_material.set_shader_parameter("dread", clampf(dread, 0.0, 1.0))
	refresh()
	queue_redraw()


## What the shader is being told about her condition: 0 while she is whole,
## rising as coherence runs out. Kept static so it can be tested on its own.
static func dread_for(state: ShadowState) -> float:
	if state == null:
		return 0.0
	if state.is_scattered:
		return 1.0
	return clampf(1.0 - state.fraction() / 0.6, 0.0, 1.0)
