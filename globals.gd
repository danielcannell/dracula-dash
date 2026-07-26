extends Node

const BASE_FORWARD_SPEED := 300.0

var cur_position := Vector2.ZERO
var cur_forward_speed := 300.0
var gamepad_active := false

func check_gamepad_active(event: InputEvent):
	if event is InputEventJoypadMotion and abs(event.axis_value) > 0.2:
		gamepad_active = true
	elif event is InputEventJoypadButton:
		gamepad_active = true
	elif event is InputEventKey:
		gamepad_active = false
