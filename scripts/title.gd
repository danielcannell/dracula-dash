extends CenterContainer

var joy_was_active := false

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _input(event: InputEvent) -> void:
	Globals.check_gamepad_active(event)
	if Globals.gamepad_active and not joy_was_active:
		$Menu/Buttons/Start.grab_focus.call_deferred()
	elif not Globals.gamepad_active and joy_was_active:
		$Menu/Buttons/Start.release_focus()
		$Menu/Buttons/Exit.release_focus()
	joy_was_active = Globals.gamepad_active


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Menu/Buttons/Start.pressed.connect(_on_start_pressed)
	$Audio/Intro_Music.play()
