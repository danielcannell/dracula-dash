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
	$Dracula.hit_bloody.connect(_on_hit_bloody)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not dead:
		score += delta
		emit_signal("score_update", score)

func _on_hit_bloody(object: StaticBody2D) -> void:
	$SplatSpawner.make_splat(object.global_position)
	object.on_hit()
	$Dracula.add_blood(object.get_blood_bonus())
	_on_spawn_explode(object.global_position - Vector2(0, 20))

func _on_spawn_explode(pos: Vector2):
	var explosion = $BloodExplode.duplicate()
	add_child(explosion)
	explosion.translate(pos)
	explosion.restart()

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_X:
			$Dracula.dead.emit()
		if event.pressed and event.keycode == KEY_B:
			_on_spawn_explode(get_viewport().get_mouse_position())
