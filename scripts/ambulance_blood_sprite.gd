extends AnimatedSprite2D


const DECAY_TIMER = 4
var timer = Timer.new()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_speed_scale(0)
	set_frame(0)
	add_child(timer)
	timer.one_shot = true
	timer.timeout.connect(on_timeout)

func on_step(obj):
	frame = min(5, frame + 1)
	timer.start(DECAY_TIMER)

func on_timeout():
	frame = max(0, frame - 1)
	if frame != 0:
		timer.start(DECAY_TIMER)
