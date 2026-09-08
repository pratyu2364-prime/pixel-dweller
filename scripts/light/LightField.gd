class_name LightField
extends RefCounted

## The deterministic tile-grid light simulation — PENUMBRA's whole ruleset.
##
## Every cell holds a light level in 0..1. Ambient light comes from the chamber
## itself; emitters (lamps, candles, Warden lanterns, sunbeams) add light with
## line-of-sight falloff; ink puffs cast by Umbra subtract it. Walls occlude.
##
## Pure logic, no scene tree: rendering reads this, never the other way round.

const SHADE_MAX := 0.35  ## at or below this a cell is shade — Umbra is safe
const DEEP_SHADE_MAX := 0.10  ## at or below this coherence and ink regenerate

var width: int
var height: int
var ambient: float

var _light: PackedFloat32Array
var _ambient_cells: PackedFloat32Array
var _opaque: PackedByteArray
var _emitters: Array[LightEmitter] = []
var _inks: Array[InkPuff] = []
var _dirty: bool = true


## A light source. Radius is in cells; intensity is the level at its own cell.
class LightEmitter:
	extends RefCounted

	var id: String
	var cell: Vector2i
	var radius: float
	var intensity: float
	var enabled: bool

	func _init(
		p_id: String,
		p_cell: Vector2i,
		p_radius: float = 6.0,
		p_intensity: float = 1.0,
		p_enabled: bool = true
	) -> void:
		id = p_id
		cell = p_cell
		radius = maxf(p_radius, 0.001)
		intensity = p_intensity
		enabled = p_enabled


## A cast puff of darkness. Subtracts light, ignores walls, fades with age.
class InkPuff:
	extends RefCounted

	var cell: Vector2i
	var radius: float
	var strength: float
	var life: float
	var age: float = 0.0

	func _init(
		p_cell: Vector2i, p_radius: float = 2.0, p_strength: float = 1.0, p_life: float = 5.0
	) -> void:
		cell = p_cell
		radius = maxf(p_radius, 0.001)
		strength = p_strength
		life = maxf(p_life, 0.001)

	func is_alive() -> bool:
		return age < life

	## Full strength for most of its life, then a quick fade out at the end.
	func current_strength() -> float:
		if not is_alive():
			return 0.0
		var remaining := 1.0 - age / life
		return strength * minf(1.0, remaining / 0.3)


func _init(p_width: int, p_height: int, p_ambient: float = 0.0) -> void:
	width = maxi(p_width, 1)
	height = maxi(p_height, 1)
	ambient = p_ambient
	var count := width * height
	_light = PackedFloat32Array()
	_light.resize(count)
	_ambient_cells = PackedFloat32Array()
	_ambient_cells.resize(count)
	_ambient_cells.fill(ambient)
	_opaque = PackedByteArray()
	_opaque.resize(count)


# --- geometry -----------------------------------------------------------------


func in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < width and cell.y < height


func _index(cell: Vector2i) -> int:
	return cell.y * width + cell.x


# --- authoring ----------------------------------------------------------------


func set_opaque(cell: Vector2i, value: bool) -> void:
	if not in_bounds(cell):
		return
	_opaque[_index(cell)] = 1 if value else 0
	_dirty = true


func is_opaque(cell: Vector2i) -> bool:
	if not in_bounds(cell):
		return true
	return _opaque[_index(cell)] == 1


## Per-cell ambient override, e.g. a shaft of daylight baked into the chamber.
func set_ambient_at(cell: Vector2i, value: float) -> void:
	if not in_bounds(cell):
		return
	_ambient_cells[_index(cell)] = clampf(value, 0.0, 1.0)
	_dirty = true


func set_ambient(value: float) -> void:
	ambient = clampf(value, 0.0, 1.0)
	_ambient_cells.fill(ambient)
	_dirty = true


func add_emitter(emitter: LightEmitter) -> LightEmitter:
	_emitters.append(emitter)
	_dirty = true
	return emitter


func emit(
	id: String, cell: Vector2i, radius: float = 6.0, intensity: float = 1.0
) -> LightEmitter:
	return add_emitter(LightEmitter.new(id, cell, radius, intensity))


func get_emitter(id: String) -> LightEmitter:
	for e in _emitters:
		if e.id == id:
			return e
	return null


func emitters() -> Array[LightEmitter]:
	return _emitters


func remove_emitter(id: String) -> void:
	for i in range(_emitters.size() - 1, -1, -1):
		if _emitters[i].id == id:
			_emitters.remove_at(i)
			_dirty = true


func move_emitter(id: String, cell: Vector2i) -> void:
	var e := get_emitter(id)
	if e == null or e.cell == cell:
		return
	e.cell = cell
	_dirty = true


func set_emitter_enabled(id: String, enabled: bool) -> void:
	var e := get_emitter(id)
	if e == null or e.enabled == enabled:
		return
	e.enabled = enabled
	_dirty = true


## Dim (or brighten) a source without snuffing it. Used by Cling.
func set_emitter_intensity(id: String, intensity: float) -> void:
	var e := get_emitter(id)
	if e == null:
		return
	var clamped := clampf(intensity, 0.0, 1.0)
	if is_equal_approx(e.intensity, clamped):
		return
	e.intensity = clamped
	_dirty = true


func cast_ink(
	cell: Vector2i, radius: float = 2.0, strength: float = 1.0, life: float = 5.0
) -> InkPuff:
	var puff := InkPuff.new(cell, radius, strength, life)
	_inks.append(puff)
	_dirty = true
	return puff


func ink_puffs() -> Array[InkPuff]:
	return _inks


func clear_ink() -> void:
	if _inks.is_empty():
		return
	_inks.clear()
	_dirty = true


# --- simulation ---------------------------------------------------------------


## Ages ink puffs. Emitter animation lives in the nodes that own them.
func advance(delta: float) -> void:
	if _inks.is_empty():
		return
	var died := false
	for i in range(_inks.size() - 1, -1, -1):
		_inks[i].age += delta
		if not _inks[i].is_alive():
			_inks.remove_at(i)
			died = true
	# Live puffs fade continuously, so any live puff also dirties the field.
	if died or not _inks.is_empty():
		_dirty = true


func mark_dirty() -> void:
	_dirty = true


func recompute() -> void:
	_light = _ambient_cells.duplicate()
	for e in _emitters:
		if e.enabled and e.intensity > 0.0:
			_add_emitter_light(e)
	for puff in _inks:
		_subtract_ink(puff)
	for i in _light.size():
		_light[i] = clampf(_light[i], 0.0, 1.0)
	_dirty = false


func _add_emitter_light(e: LightEmitter) -> void:
	var r := int(ceil(e.radius))
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			var cell := e.cell + Vector2i(dx, dy)
			if not in_bounds(cell):
				continue
			var dist := Vector2(dx, dy).length()
			if dist > e.radius:
				continue
			var falloff := 1.0 - dist / e.radius
			# Squared falloff reads as a soft pool of light rather than a disc.
			var value := e.intensity * falloff * falloff
			if value <= 0.0:
				continue
			if not _has_line_of_sight(e.cell, cell):
				continue
			var idx := _index(cell)
			_light[idx] = maxf(_light[idx], value)


func _subtract_ink(puff: InkPuff) -> void:
	var strength := puff.current_strength()
	if strength <= 0.0:
		return
	var r := int(ceil(puff.radius))
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			var cell := puff.cell + Vector2i(dx, dy)
			if not in_bounds(cell):
				continue
			var dist := Vector2(dx, dy).length()
			if dist > puff.radius:
				continue
			# Flat core with a soft rim, so a puff is a reliable stepping stone.
			var edge := clampf((puff.radius - dist) / maxf(puff.radius * 0.5, 0.001), 0.0, 1.0)
			var idx := _index(cell)
			_light[idx] -= strength * edge


## Walls block light. Endpoints are exempt so a lamp inside a wall still glows
## on its own cell and a lit wall face still reads as lit.
func _has_line_of_sight(from: Vector2i, to: Vector2i) -> bool:
	if from == to:
		return true
	var delta := (to - from).abs()
	var step := Vector2i(signi(to.x - from.x), signi(to.y - from.y))
	var err := delta.x - delta.y
	var cell := from
	var guard := delta.x + delta.y + 2
	while guard > 0:
		guard -= 1
		var double_err := err * 2
		if double_err > -delta.y:
			err -= delta.y
			cell.x += step.x
		if double_err < delta.x:
			err += delta.x
			cell.y += step.y
		if cell == to:
			return true
		if is_opaque(cell):
			return false
	return true


# --- queries ------------------------------------------------------------------


func level_at(cell: Vector2i) -> float:
	if not in_bounds(cell):
		return 0.0
	if _dirty:
		recompute()
	return _light[_index(cell)]


func is_shade(cell: Vector2i) -> bool:
	return level_at(cell) <= SHADE_MAX


func is_deep_shade(cell: Vector2i) -> bool:
	return level_at(cell) <= DEEP_SHADE_MAX


func is_glare(cell: Vector2i) -> bool:
	return not is_shade(cell)


## How hard the light is biting, 0 in shade → 1 in full glare. Drives the
## coherence drain rate so stepping one tile into a beam is survivable.
func glare_at(cell: Vector2i) -> float:
	var level := level_at(cell)
	if level <= SHADE_MAX:
		return 0.0
	return (level - SHADE_MAX) / (1.0 - SHADE_MAX)


## Snapshot of the whole field, for the renderer and for tests.
func levels() -> PackedFloat32Array:
	if _dirty:
		recompute()
	return _light.duplicate()


## Nearest shade cell to `from`, searched breadth-first through walkable cells.
## Umbra reforms here after scattering.
func nearest_shade(from: Vector2i, max_radius: int = 24) -> Vector2i:
	if in_bounds(from) and not is_opaque(from) and is_shade(from):
		return from
	var seen := {from: true}
	var queue: Array[Vector2i] = [from]
	var head := 0
	while head < queue.size():
		var cell: Vector2i = queue[head]
		head += 1
		if (cell - from).length() > float(max_radius):
			continue
		for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = cell + offset
			if seen.has(next) or not in_bounds(next) or is_opaque(next):
				continue
			seen[next] = true
			if is_shade(next):
				return next
			queue.append(next)
	return from
