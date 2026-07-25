extends StaticBody2D

func _ready():
	add_to_group("children")
	# randomize a bit
	$Child_Hit.pitch_scale = randf_range(0.5, 2.0)

func _physics_process(delta: float) -> void:
	position.y += delta * Globals.cur_forward_speed
	if position.y > 1000:
		queue_free()

func on_hit():
	$CollisionShape2D.disabled = true
	$Child_Hit.play()
	# TODO change sprite

func get_blood_bonus() -> float:
	return 40.0
