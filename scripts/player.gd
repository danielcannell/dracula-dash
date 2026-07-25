extends CharacterBody2D


var acceleration = Vector2.ZERO


func _physics_process(delta: float) -> void:
	velocity += acceleration * delta
	move_and_slide()
