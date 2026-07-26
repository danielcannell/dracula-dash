extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("children")
	add_to_group("dead_players")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	position.y += delta * Globals.cur_forward_speed
	if position.y > 1000:
		queue_free()

func on_hit():
	$CollisionPolygon2D.disabled = true
	explode()

func get_blood_bonus():
	return 50


func explode():
	$AnimatedSprite2D.show()
	$AnimatedSprite2D.play("explode")
	$Coffin.hide()
	
	
	# Wait until the animation plays its last frame and finishes
	await $AnimatedSprite2D.animation_finished
	
	# Remove/unload the node from memory and the scene tree
	queue_free()


# set the player name
func set_label_text(name):
	$Label.text = name
