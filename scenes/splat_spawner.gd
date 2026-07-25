extends Node2D

@export var splat_scene: PackedScene

func make_splat(pos: Vector2) -> void:
	var splat = splat_scene.instantiate()
	add_child(splat)

	var splat_scale = randf_range(0.8, 2.5)
	splat.global_position = pos
	splat.scale = Vector2(1, 1) * splat_scale
	splat.rotation = randf_range(-0.3, 0.3)
