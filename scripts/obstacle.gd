extends Sprite2D

var scroll_speed := 300.0

func _process(delta):
	position.y += scroll_speed * delta

	if position.y > 1000:
		queue_free()
