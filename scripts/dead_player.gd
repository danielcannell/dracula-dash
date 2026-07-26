extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("children")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	position.y += delta * Globals.cur_forward_speed
	if position.y > 1000:
		queue_free()

func on_hit():
	$CollisionPolygon2D.disabled = true

func get_blood_bonus():
	return 0


# set the player name
func set_label_text(name):
	$Label.text = name
