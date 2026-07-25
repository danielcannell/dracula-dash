extends CenterContainer

var joy_focus := false

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_exit_pressed() -> void:
	get_tree().quit()


func _switch_to_joy() -> void:
	if not joy_focus:
		joy_focus = true
		$Menu/Buttons/Start.grab_focus.call_deferred()


func _switch_from_joy() -> void:
	if joy_focus:
		joy_focus = false
		$Menu/Buttons/Start.release_focus()


func _input(event: InputEvent) -> void:
	if event is InputEventJoypadMotion:
		if abs(event.axis_value) > 0.2:
			_switch_to_joy()
	elif event is InputEventJoypadButton:
		_switch_to_joy()
	elif event is InputEventKey or event is InputEventMouseMotion or event is InputEventMouseButton:
		_switch_from_joy()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Menu/Buttons/Start.pressed.connect(_on_start_pressed)
	$Menu/Buttons/Exit.pressed.connect(_on_exit_pressed)
	
	$Audio/Intro_Music.play()
