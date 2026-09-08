class_name ShadowState
extends RefCounted

## Umbra's whole condition: coherence and ink. Pure logic, no scene tree.
##
## Coherence is health, stamina and timer at once — it drains in glare and
## refills in shade. Ink is spent to cast puffs of darkness and only refills in
## deep shade, which is what makes the loop *hide → charge → sprint → hide*.

signal scattered  ## coherence hit zero; the body must reform at nearest shade
signal reformed
signal coherence_changed(value: float)
signal ink_changed(value: float)

const MAX_COHERENCE := 100.0
const DRAIN_PER_SECOND := 34.0  ## at full glare: ~3s of direct light kills
const REGEN_PER_SECOND := 18.0  ## in shade
const DEEP_REGEN_PER_SECOND := 30.0  ## in deep shade
const REGEN_DELAY := 0.45  ## grace before regen starts, so glare stings

const MAX_INK := 3.0
const INK_PER_CAST := 1.0
const INK_REGEN_PER_SECOND := 0.55  ## deep shade only

## Movement is halved at full glare — running the light should feel like wading.
const GLARE_SPEED_PENALTY := 0.5

## Memories she has found raise these two ceilings and nothing else. There are
## no levels in PENUMBRA — the only thing that grows is how long she can bear
## the light and how much dark she can carry.
var bonus_coherence: float = 0.0
var bonus_ink: float = 0.0

var coherence: float = MAX_COHERENCE
var ink: float = MAX_INK
var is_scattered: bool = false

var _regen_cooldown: float = 0.0


func max_coherence() -> float:
	return MAX_COHERENCE + bonus_coherence


func max_ink() -> float:
	return MAX_INK + bonus_ink


func grant(p_coherence: float, p_ink: float) -> void:
	bonus_coherence += p_coherence
	bonus_ink += p_ink
	coherence = max_coherence()
	ink = max_ink()
	coherence_changed.emit(coherence)
	ink_changed.emit(ink)


func fraction() -> float:
	return coherence / max_coherence()


func ink_charges() -> int:
	return int(floor(ink))


func can_cast() -> bool:
	return not is_scattered and ink >= INK_PER_CAST


func spend_ink() -> bool:
	if not can_cast():
		return false
	ink -= INK_PER_CAST
	ink_changed.emit(ink)
	return true


## One simulation step. `glare` is 0 in shade → 1 in full light (LightField
## hands it over); `deep_shade` gates ink regeneration.
func tick(delta: float, glare: float, deep_shade: bool) -> void:
	if is_scattered or delta <= 0.0:
		return
	var before_coherence := coherence
	var before_ink := ink

	if glare > 0.0:
		coherence = maxf(0.0, coherence - DRAIN_PER_SECOND * glare * delta)
		_regen_cooldown = REGEN_DELAY
	else:
		_regen_cooldown = maxf(0.0, _regen_cooldown - delta)
		if _regen_cooldown <= 0.0:
			var rate := DEEP_REGEN_PER_SECOND if deep_shade else REGEN_PER_SECOND
			coherence = minf(max_coherence(), coherence + rate * delta)

	if deep_shade:
		ink = minf(max_ink(), ink + INK_REGEN_PER_SECOND * delta)

	if not is_equal_approx(coherence, before_coherence):
		coherence_changed.emit(coherence)
	if not is_equal_approx(ink, before_ink):
		ink_changed.emit(ink)
	if coherence <= 0.0:
		scatter()


func scatter() -> void:
	if is_scattered:
		return
	is_scattered = true
	coherence = 0.0
	_regen_cooldown = 0.0
	scattered.emit()


## Reforming is generous: half coherence back, so a bad crossing costs progress
## and tension, never a run.
func reform() -> void:
	if not is_scattered:
		return
	is_scattered = false
	coherence = max_coherence() * 0.5
	ink = maxf(ink, INK_PER_CAST)
	coherence_changed.emit(coherence)
	ink_changed.emit(ink)
	reformed.emit()


func speed_multiplier(glare: float) -> float:
	return 1.0 - GLARE_SPEED_PENALTY * clampf(glare, 0.0, 1.0)


func to_dict() -> Dictionary:
	return {"coherence": coherence, "ink": ink}


func from_dict(data: Dictionary) -> void:
	coherence = clampf(float(data.get("coherence", max_coherence())), 0.0, max_coherence())
	ink = clampf(float(data.get("ink", max_ink())), 0.0, max_ink())
	is_scattered = coherence <= 0.0
