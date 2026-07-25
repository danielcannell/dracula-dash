extends CharacterBody2D


var angle: float = 0


func _physics_process(delta: float) -> void:
	var turn = Input.get_axis("turn_left", "turn_right")
	angle += 0.1 * (turn - angle)
	rotation = angle
	
	velocity = 1000 * Vector2(sin(angle), 0)

	move_and_slide()
