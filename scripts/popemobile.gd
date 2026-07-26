extends CharacterBody2D

const SPEED = -2000.0

signal on_hit(object: PhysicsBody2D)

func _physics_process(delta: float) -> void:
	# Ignores player forward speed
	velocity = Vector2(0, SPEED).rotated(rotation)
	var hit = move_and_collide(velocity * delta)
	if hit:
		var obj = hit.get_collider()
		on_hit.emit(obj)

	if position.y < -1000:
		queue_free()
