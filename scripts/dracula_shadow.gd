extends Sprite2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$"../Dracula/AnimatedSprite2D".scale_changed.connect(_on_scale_changed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	global_position = $"../Dracula".global_position
	position += Vector2(16, 16)
	rotation = $"../Dracula".global_rotation
	position -= Vector2(16, 16)
	scale = $"../Dracula/AnimatedSprite2D".scale * 4

func _on_scale_changed(scale: float):
	self_modulate.a = (scale - 1) * 1.5
