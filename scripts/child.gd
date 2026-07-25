extends StaticBody2D

func _ready():
	add_to_group("children")

func _process(delta):
	position.y += delta * Globals.cur_forward_speed
	if position.y > 1000:
		queue_free()

func on_hit():
	$CollisionShape2D.disabled = true
	# TODO change sprite

func get_blood_bonus() -> float:
	return 40.0
