extends Line2D

const bloody_gradient = preload("res://resources/trail_bloody_gradient.tres")

enum {PURE, GRADIENT, BLACK}
var state = BLACK
var bloody_timer_pure = Timer.new()
var bloody_timer_gradient = Timer.new()
var last_point: Vector2

func _ready() -> void:
	bloody_timer_pure.one_shot = true
	bloody_timer_gradient.one_shot = true
	bloody_timer_pure.timeout.connect(_on_pure_timeout)
	bloody_timer_gradient.timeout.connect(_on_gradient_timeout)
	add_child(bloody_timer_pure)
	add_child(bloody_timer_gradient)


func make_bloody():
	bloody_timer_gradient.stop()
	bloody_timer_pure.start(2)
	# clear points before switching modes so line doesnt jump from prev
	if state != PURE:
		$RedTrail.clear_points()
		$RedTrail.add_point(last_point)
	state = PURE
	bloody_timer_pure.start(2)

func _on_pure_timeout():
	if state != GRADIENT:
		$BloodyTrail.clear_points()
		$BloodyTrail.add_point(last_point)
	bloody_timer_gradient.start(2)
	state = GRADIENT
	
func _on_gradient_timeout():
	if state != BLACK:
		clear_points()
		add_point(last_point)
	state = BLACK

func trail_add_point(pos: Vector2):
	match state:
		PURE:
			$RedTrail.add_point(pos)
		GRADIENT:
			$BloodyTrail.add_point(pos)
		BLACK:
			add_point(pos)
	last_point = pos
