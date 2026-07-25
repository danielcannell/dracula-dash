extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if DisplayServer.is_touchscreen_available():
		$VirtualJoystick.visible = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	print(Input.get_joy_name(0))
	print(Input.get_axis("turn_left", "turn_right"))
	pass
