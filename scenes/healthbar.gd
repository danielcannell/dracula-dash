@tool

extends Control

@export var health := 100.0:
	set(value):
		health = value
		update()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func update() -> void:
	$Foreground.size.x = (self.health / 100.0) * $Background.size.x
#
## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#update()
