extends StaticBody2D

@onready var anim_idx := randi_range(1, 3)

var dead := false
var next_move_time := 0.0
const MOVE_SPEED = 600
var move_target := Vector2.ZERO

func _ready():
	add_to_group("children")
	# randomize a bit
	$AnimatedSprite2D.animation = "child_" + str(anim_idx)
	$Child_Hit.pitch_scale = randf_range(0.5, 2.0)
	_random_next_move()

func _random_next_move():
	next_move_time = randf_range(0.5, 1.0)
	move_target = position + Vector2(randf_range(-400, 100), randf_range(-400, 100))

func _physics_process(delta: float) -> void:
	if not dead:
		next_move_time -= delta
		if next_move_time < 0:
			_random_next_move()

		# move towards the target pos
		position = position.move_toward(move_target, delta * MOVE_SPEED)
		move_target.y += delta * Globals.cur_forward_speed

	position.y += delta * Globals.cur_forward_speed
	if position.y > 1000:
		queue_free()

func on_hit():
	$AnimatedSprite2D.animation = "dead_" + str(anim_idx)
	$CollisionShape2D.disabled = true
	$Child_Hit.play()
	dead = true
	# TODO change sprite

func get_blood_bonus() -> float:
	return 40.0
