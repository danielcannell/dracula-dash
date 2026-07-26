extends Node2D



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Timer.timeout.connect(_timeout)

func _timeout():
	$Sprite2D.visible = !$Sprite2D.visible

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
