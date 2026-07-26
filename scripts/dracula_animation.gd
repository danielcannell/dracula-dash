extends AnimatedSprite2D

# ideally:
# (MAX_SCALE_FLYING - 1) / SCALE_RATE = start/stop frames / animation fps
const MAX_SCALE_FLYING = 1.4
const SCALE_RATE = 0.5

func _process(delta: float) -> void:
	match animation:
		"default":
			offset = Vector2.ZERO
			set_scale(Vector2(1, 1))
		"immune_stop":
			offset = Vector2(0, -16)
			var cur_scale = get_scale().x
			if cur_scale > 1:
				var new_scale = min(cur_scale - delta * SCALE_RATE, MAX_SCALE_FLYING)
				set_scale(Vector2(new_scale, new_scale))
		_:
			offset = Vector2(0, -16)
			var cur_scale = get_scale().x
			if cur_scale < MAX_SCALE_FLYING:
				var new_scale = min(cur_scale + delta * SCALE_RATE, MAX_SCALE_FLYING)
				set_scale(Vector2(new_scale, new_scale))


func _on_animation_finished():
	match animation:
		"immune_start":
			play("immune_loop")
		"immune_stop":
			play("default")
