extends AnimatedSprite2D

# ideally:
# (MAX_SCALE_FLYING - 1) / SCALE_RATE = start/stop frames / animation fps
const MAX_SCALE_FLYING = 1.4
const SCALE_RATE = 0.5

const MAX_OFFSET_FLYING = -8
const OFFSET_SCALE_RATE = 10

var cur_offset = 0

func _process(delta: float) -> void:
	match animation:
		"default":
			offset = Vector2.ZERO
			cur_offset = 0
			set_scale(Vector2(1, 1))
		"immune_stop":
			if cur_offset < 0:
				cur_offset = min(0, cur_offset + delta*OFFSET_SCALE_RATE)
			offset = Vector2(0, -16 + cur_offset)
			var cur_scale = get_scale().x
			if cur_scale > 1:
				var new_scale = max(cur_scale - delta * SCALE_RATE, 1)
				set_scale(Vector2(new_scale, new_scale))
			$BloodSprite.offset = Vector2(0, cur_offset)
			$CoffinContainer.position = Vector2(0, cur_offset + 4)
		_:
			if cur_offset > MAX_OFFSET_FLYING:
				cur_offset = max(MAX_OFFSET_FLYING, cur_offset - delta*OFFSET_SCALE_RATE)
			offset = Vector2(0, -16 + cur_offset)
			$BloodSprite.offset = Vector2(0, cur_offset)
			$CoffinContainer.position = Vector2(0, cur_offset + 4)

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
