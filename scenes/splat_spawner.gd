extends Node2D

@export var splat_scene: PackedScene
@export var scroll_speed := 300.0

func splat(pos: Vector2) -> void:
	var splat = splat_scene.instantiate()
	add_child(splat)

	var scale = randf_range(0.8, 2.5)
	splat.transform = Transform2D(randf_range(-0.3, 0.3), Vector2.ZERO).scaled(Vector2(scale, scale))
	splat.global_position = pos
	splat.scroll_speed = scroll_speed
