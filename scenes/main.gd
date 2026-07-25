extends Node

signal score_update(score: float)


var score: float = 0.0
var dead: bool = false


func _on_dead() -> void:
	dead = true


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("Joystick: ", Input.get_joy_name(0))
	Globals.cur_forward_speed = 300.0


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		$SplatSpawner.make_splat($Dracula.global_position)
	
	if not dead:
		score += delta
		emit_signal("score_update", score)

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_X:
			$Dracula.dead.emit()
