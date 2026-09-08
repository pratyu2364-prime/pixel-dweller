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
var _nooks: PackedByteArray
var _mirrors: Dictionary = {}  ## cell -> "/" or "\\"
var _rays: Array[LightRay] = []
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
	## A beam: emitter light is confined to a cone. `cone_half_angle` of TAU
	## (the default) means an ordinary lamp shining every way at once.
	var direction: Vector2 = Vector2.RIGHT
	var cone_half_angle: float = TAU

	func is_beam() -> bool:
		return cone_half_angle < PI

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


## A ray of light: a beam traced cell by cell that reflects off mirrors and
## stops at walls. Unlike a lamp, a ray is a *line* — which is what makes a
## mirror worth turning.
class LightRay:
	extends RefCounted

	var id: String
	var cell: Vector2i
	var direction: Vector2i
	var intensity: float
	var range_cells: int
	var enabled: bool = true

	func _init(
		p_id: String,
		p_cell: Vector2i,
		p_direction: Vector2i = Vector2i.RIGHT,
		p_intensity: float = 1.0,
		p_range: int = 30
	) -> void:
		id = p_id
		cell = p_cell
		direction = p_direction
		intensity = p_intensity
		range_cells = p_range


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
	_nooks = PackedByteArray()
	_nooks.resize(count)


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


## A nook stays dark no matter what shines at it — a drape's shadow, a crack
## under the stair. Guaranteed refuge, so a chamber always has a safe beat in it.
func set_nook(cell: Vector2i, value: bool) -> void:
	if not in_bounds(cell):
		return
	_nooks[_index(cell)] = 1 if value else 0
	_dirty = true


func is_nook(cell: Vector2i) -> bool:
	return in_bounds(cell) and _nooks[_index(cell)] == 1


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


# --- mirrors and rays ---------------------------------------------------------


## Mirrors are "/" or "\\". They reflect rays and nothing else: a lamp's glow
## passes them by, so a mirror in a dark room is a lever, not a light.
func set_mirror(cell: Vector2i, orientation: String) -> void:
	if not in_bounds(cell):
		return
	if orientation.is_empty():
		_mirrors.erase(cell)
	else:
		_mirrors[cell] = orientation
	_dirty = true


func mirror_at(cell: Vector2i) -> String:
	return String(_mirrors.get(cell, ""))


func has_mirror(cell: Vector2i) -> bool:
	return _mirrors.has(cell)


## Turning a mirror is the Prism Hall's whole verb: one press, ninety degrees.
func turn_mirror(cell: Vector2i) -> bool:
	if not _mirrors.has(cell):
		return false
	_mirrors[cell] = "\\" if _mirrors[cell] == "/" else "/"
	_dirty = true
	return true


static func reflect(direction: Vector2i, orientation: String) -> Vector2i:
	## "/" maps right->up and down->left; "\\" maps right->down and up->left.
	if orientation == "/":
		return Vector2i(-direction.y, -direction.x)
	return Vector2i(direction.y, direction.x)


func add_ray(ray: LightRay) -> LightRay:
	_rays.append(ray)
	_dirty = true
	return ray


func rays() -> Array[LightRay]:
	return _rays


func get_ray(id: String) -> LightRay:
	for ray in _rays:
		if ray.id == id:
			return ray
	return null


func set_ray_enabled(id: String, enabled: bool) -> void:
	var ray := get_ray(id)
	if ray == null or ray.enabled == enabled:
		return
	ray.enabled = enabled
	_dirty = true


## The cells a ray actually lights, in order — the same walk the renderer and
## any test can inspect, so "where does the beam go" has one answer.
func trace_ray(ray: LightRay) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	var cell := ray.cell
	var direction := ray.direction
	var seen := {}
	for step in ray.range_cells:
		cell += direction
		if not in_bounds(cell) or is_opaque(cell):
			break
		path.append(cell)
		var orientation := mirror_at(cell)
		if not orientation.is_empty():
			direction = LightField.reflect(direction, orientation)
			# A ring of mirrors would otherwise trap a ray forever.
			var key := [cell, direction]
			if seen.has(key):
				break
			seen[key] = true
	return path


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
	for ray in _rays:
		if ray.enabled and ray.intensity > 0.0:
			_add_ray_light(ray)
	for i in _nooks.size():
		if _nooks[i] == 1:
			_light[i] = 0.0
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
			if e.is_beam() and not _within_cone(e, dx, dy):
				continue
			if not _has_line_of_sight(e.cell, cell):
				continue
			var idx := _index(cell)
			_light[idx] = maxf(_light[idx], value)


## Cells inside a beam's cone. The emitter's own cell always counts, so a beam
## source still glows where it stands.
## A ray dims along its length rather than around a point, so a long reflected
## path is visibly weaker at its end than at its source.
func _add_ray_light(ray: LightRay) -> void:
	var path := trace_ray(ray)
	for i in path.size():
		var falloff := 1.0 - float(i) / float(maxi(ray.range_cells, 1))
		var value := ray.intensity * maxf(falloff, 0.25)
		var idx := _index(path[i])
		_light[idx] = maxf(_light[idx], value)


func _within_cone(e: LightEmitter, dx: int, dy: int) -> bool:
	var offset := Vector2(dx, dy)
	if offset.length() < 0.001:
		return true
	return absf(e.direction.angle_to(offset.normalized())) <= e.cone_half_angle


## Aim a beam. Widening past PI turns it back into an ordinary lamp.
func aim_emitter(id: String, direction: Vector2, half_angle: float = -1.0) -> void:
	var e := get_emitter(id)
	if e == null:
		return
	if direction.length() > 0.001:
		e.direction = direction.normalized()
	if half_angle >= 0.0:
		e.cone_half_angle = half_angle
	_dirty = true


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
