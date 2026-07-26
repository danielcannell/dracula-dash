extends Node2D

@export var dead_player: PackedScene;


# spawn a player at a position
func spawn_dead_player(name: String, pos: Vector2):
	var inst = dead_player.instantiate()
	inst.set_label_text(name)
	inst.position = pos
	add_child(inst)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_death_positions(deaths: Array) -> void:
	for death in deaths:
		spawn_dead_player(death["name"], death["pos"])
