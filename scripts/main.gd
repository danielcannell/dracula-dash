extends Node

signal score_update(score: int)


var score: float = 0.0
var dead: bool = false


func _on_dead() -> void:
	dead = true


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("Joystick: ", Input.get_joy_name(0))
	Globals.cur_forward_speed = 300.0
	$Dracula.hit.connect(_on_hit)
	$Dracula.hit_bloody.connect(_on_hit_bloody)
	$Dracula.hit_powerup.connect(func (obj): obj.on_hit())
	$ObstacleSpawner.on_pope_hit.connect(_on_pope_hit)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not dead:
		score += delta
		score_update.emit(round(score))

func _on_pope_hit(object: StaticBody2D) -> void:
	if object.is_in_group("children") or object.is_in_group("cyclists"):
		$SplatSpawner.make_splat(object.global_position)
		object.on_hit()

		var explosion_texture: Texture2D = null
		if object.has_method("get_explosion_texture"):
			explosion_texture = object.get_explosion_texture()

		_on_spawn_explode(object.global_position - Vector2(0, 20), explosion_texture)

func _on_hit(_object: StaticBody2D) -> void:
	if Globals.gamepad_active:
		Input.start_joy_vibration(0, 0.0, 1.0, 0.5)

func _on_hit_bloody(object: StaticBody2D) -> void:
	if Globals.gamepad_active:
		Input.start_joy_vibration(0, 1.0, 0.0, 0.5)
	$SplatSpawner.make_splat(object.global_position)
	object.on_hit()
	$Dracula.add_blood(object.get_blood_bonus())

	var explosion_texture: Texture2D = null
	if object.has_method("get_explosion_texture"):
		explosion_texture = object.get_explosion_texture()

	_on_spawn_explode(object.global_position - Vector2(0, 20), explosion_texture)

func _on_spawn_explode(pos: Vector2, texture: Texture2D = null):
	var explosion = $BloodExplode.duplicate(true)
	add_child(explosion)
	explosion.translate(pos)
	if texture:
		explosion.texture = texture
	explosion.restart()

func _input(event: InputEvent) -> void:
	Globals.check_gamepad_active(event)
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_X:
			$Dracula._on_dead()
		if event.pressed and event.keycode == KEY_B:
			_on_spawn_explode(get_viewport().get_mouse_position())

func _on_death_show_leaderboard() -> void:
	$Death.visible = false
	$Leaderboard.visible = true
