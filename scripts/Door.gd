class_name Door
extends Area2D

signal requested_transition(target_area: String, target_entry: String)

@export var target_area: String = ""
@export var target_entry: String = "EntryDefault"


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body is CharacterBody2D:
		requested_transition.emit(target_area, target_entry)
