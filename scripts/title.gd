extends Node


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_exit_pressed() -> void:
	get_tree().quit()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Start.grab_focus.call_deferred()
	$Start.pressed.connect(_on_start_pressed)
	$Exit.pressed.connect(_on_exit_pressed)
