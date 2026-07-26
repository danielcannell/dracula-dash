extends Node2D

signal body_entered_grass(node: Node2D)
signal body_exited_grass(node: Node2D)

func _ready() -> void:
	$Grass.body_entered.connect(body_entered_grass.emit)
	$Grass.body_exited.connect(body_exited_grass.emit)
