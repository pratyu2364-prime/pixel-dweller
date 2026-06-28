extends Node2D
## Root scene. Phase 0 placeholder — boots cleanly so CI smoke test passes.
## Feature scenes (World, Player, UI) get wired in during Phase 1.


func _ready() -> void:
	print("Pixel Dweller booted.")
