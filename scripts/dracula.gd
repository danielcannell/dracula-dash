extends CharacterBody2D


const TURN_TIME_SCALE_S = 0.1
const SPEED = 1000


var angle: float = 0


func _physics_process(delta: float) -> void:
	# Get input in range [-1, 1]
	var turn = Input.get_axis("turn_left", "turn_right")
	
	# Exponential smoothing of direction angle
	var alpha = 1 - exp(-delta / TURN_TIME_SCALE_S)
	angle += alpha * (turn - angle)
	
	# Rotate the whole scene for the correct facing
	rotation = angle
	
	# Physics
	velocity = SPEED * Vector2(sin(angle), 0)
	move_and_slide()
