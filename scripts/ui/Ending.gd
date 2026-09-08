class_name EndingScreen
extends Control

## Two endings, no score, no grade. The game states what she did and stops.

const TEXT := {
	"free":
	{
		"title": "the lamp goes out",
		"body":
		"Nothing casts you now.\nThe Observatory is dark, and dark is only the shape of a room.\nYou are not a shadow of anything. You are what is left."
	},
	"rejoin":
	{
		"title": "the stair, and the light on it",
		"body":
		"You climb into the lamp's reach and let it find you.\nSomeone up there moves, and you move with them, the way you always did.\nThe Observatory keeps burning. You are a shadow again, and it fits."
	},
}

@onready var _title: Label = $Panel/Title
@onready var _body: Label = $Panel/Body
@onready var _again: Button = $Panel/Again


func _ready() -> void:
	_again.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/Title.tscn"))


func show_ending(kind: String) -> void:
	var entry: Dictionary = TEXT.get(kind, TEXT["rejoin"])
	_title.text = String(entry["title"])
	_body.text = String(entry["body"])


static func has_ending(kind: String) -> bool:
	return TEXT.has(kind)
