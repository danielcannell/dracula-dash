@tool

extends Control

@export var health := 100.0:
	set(value):
		health = value
		update()

func _ready() -> void:
	pass

func update() -> void:
	$Foreground.size.x = (self.health / 100.0) * $Background.size.x


func set_health(health: float) -> void:
	self.health = health
