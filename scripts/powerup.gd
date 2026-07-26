extends StaticBody2D

func _ready():
	visible=true
	add_to_group("powerups")

func on_hit():
	$CollisionShape2D.disabled = true
	visible=false

func _physics_process(delta: float) -> void:
	position.y += delta * Globals.cur_forward_speed
	if position.y > 1000:
		queue_free()


func get_powerup_type():
	return "immune"
