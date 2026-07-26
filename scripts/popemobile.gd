extends CharacterBody2D

const SPEED = -300.0

enum State { NORMAL, DODGE }


func _physics_process(delta: float) -> void:
	# print(Globals.cur_forward_speed)
	velocity = Vector2(0, SPEED + Globals.cur_forward_speed)
	move_and_slide()
