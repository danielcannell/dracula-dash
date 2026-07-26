extends AnimatedSprite2D

func _process(delta: float) -> void:
	if animation != "default":
		offset = Vector2(0, -16)
	else:
		offset = Vector2.ZERO

func _on_animation_finished():
	match animation:
		"immune_start":
			play("immune_loop")
		"immune_stop":
			play("default")
