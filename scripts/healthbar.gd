@tool

extends Control

@export var health := 100.0:
	set(value):
		health = value
		$Foreground.size.x = (health / 100.0) * $Background.size.x

func _ready() -> void:
	pass

func set_health(value: float) -> void:
	self.health = value
