extends Parallax2D

func _physics_process(delta):
	scroll_offset.y += delta * Globals.cur_forward_speed
