extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if DisplayServer.is_touchscreen_available():
		$VirtualJoystick.visible = true
	print("Joystick: ", Input.get_joy_name(0))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_X:
			$Dracula.dead.emit()
