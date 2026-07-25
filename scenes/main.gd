extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	print(Input.get_joy_name(0))
	print(Input.get_axis("turn_left", "turn_right"))
	pass
