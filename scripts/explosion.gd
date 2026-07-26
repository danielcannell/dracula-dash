extends Node2D


func _ready() -> void:
	# Play your non-looping animation (e.g., "explosion")
	$AnimatedSprite2D.play("explosion")
	$AudioStreamPlayer2D.play()

	# Wait until the animation plays its last frame and finishes
	await $AnimatedSprite2D.animation_finished

	# Remove/unload the node from memory and the scene tree
	queue_free()
