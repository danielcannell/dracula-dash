extends Node2D

signal timeout

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$FlashTimer.timeout.connect(_timeout)
	$DoneTimer.timeout.connect(timeout.emit)

func _timeout():
	$Sprite2D.visible = !$Sprite2D.visible
