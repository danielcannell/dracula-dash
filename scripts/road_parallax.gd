extends Parallax2D

func _physics_process(delta: float) -> void:
	scroll_offset.y += delta * Globals.cur_forward_speed
