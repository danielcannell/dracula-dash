extends VirtualJoystick


func _ready() -> void:
	visible = DisplayServer.is_touchscreen_available()
