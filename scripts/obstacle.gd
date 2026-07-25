extends StaticBody2D

func _ready():
	add_to_group("obstacles")

func _physics_process(delta: float) -> void:
	position.y += delta * Globals.cur_forward_speed
	if position.y > 1000:
		queue_free()
