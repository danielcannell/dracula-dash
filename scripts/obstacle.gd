extends StaticBody2D

@export var sprite_variants: Array[Texture2D] = []

@onready var sprite: Sprite2D = $Sprite2D

func _ready():
	add_to_group("obstacles")
	sprite.texture = sprite_variants[randi() % sprite_variants.size()]

func _physics_process(delta: float) -> void:
	position.y += delta * Globals.cur_forward_speed
	if position.y > 1000:
		queue_free()
