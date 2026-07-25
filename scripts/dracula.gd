extends CharacterBody2D


var angle: float = 0


func _physics_process(delta: float) -> void:
	var turn = 0
	if Input.is_action_pressed("turn_left"):
		turn -= 1
	if Input.is_action_pressed("turn_right"):
		turn += 1
	
	angle += 0.1 * (turn - angle)
	rotation = angle
	
	velocity = 1000 * Vector2(sin(angle), 0)

	move_and_slide()
