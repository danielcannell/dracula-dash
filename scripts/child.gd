extends StaticBody2D

@onready var anim_idx := randi_range(1, 3)

func _ready():
	add_to_group("children")
	# randomize a bit
	$AnimatedSprite2D.animation = "child_" + str(anim_idx)
	$Child_Hit.pitch_scale = randf_range(0.5, 2.0)

func _physics_process(delta: float) -> void:
	position.y += delta * Globals.cur_forward_speed
	if position.y > 1000:
		queue_free()

func on_hit():
	$AnimatedSprite2D.animation = "dead_" + str(anim_idx)
	$CollisionShape2D.disabled = true
	$Child_Hit.play()
	# TODO change sprite

func get_blood_bonus() -> float:
	return 40.0
