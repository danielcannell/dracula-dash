extends Parallax2D

@export var scroll_speed := 300.0
var base_scroll := 0.0
var scrolling := true

func _physics_process(delta):
	if scrolling:
		base_scroll += scroll_speed * delta
