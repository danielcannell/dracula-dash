extends StaticBody2D

var scroll_speed := 300.0

func _ready():
	add_to_group("obstacles")

func set_scroll_speed(new_speed: float):
	scroll_speed = new_speed

func _process(delta):
	position.y += scroll_speed * delta
	if position.y > 1000:
		queue_free()
