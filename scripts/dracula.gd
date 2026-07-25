extends CharacterBody2D


var acceleration = Vector2.ZERO


func _physics_process(delta: float) -> void:
	if Input.is_action_pressed("turn_left"):
		print("x")
	if Input.is_action_pressed("turn_right"):
		print("y")

	velocity += acceleration * delta
	move_and_slide()
