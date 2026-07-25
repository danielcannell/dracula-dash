extends CharacterBody2D

signal dead
signal blood(health: float)

const TURN_TIME_SCALE_S = 0.1
const SPEED = 1000
const BLOOD_DRAIN_RATE = 10
const STUN_DURATION = 0.6
const BOUNCE_STRENGTH = 400.0
const BOUNCE_DECAY = 1000.0
const Y_RECENTRE_SPEED = 300.0
const HIT_DAMAGE = 20.0

enum State { NORMAL, STUNNED }

var angle: float = 0
var blood_level: float = 100
var state := State.NORMAL
var bounce_velocity := Vector2.ZERO
var base_pos: Vector2

@onready var spawner = get_node("/root/Main/ObstacleSpawner")

func _ready():
	add_to_group("player")
	base_pos = position

func _process(delta: float) -> void:
	# blood_level -= delta * BLOOD_DRAIN_RATE
	if blood_level <= 0:
		blood_level = 0
		emit_signal("dead")
	emit_signal("blood", blood_level)
	
	
func _physics_process(delta: float) -> void:
	match state:
		State.NORMAL:
			_normal_movement(delta)
		State.STUNNED:
			_stunned_movement(delta)

func _normal_movement(delta: float) -> void:
	# Get input in range [-1, 1]
	var turn = Input.get_axis("turn_left", "turn_right")
	var dodge = Input.get_axis("dodge_up", "dodge_down")
	
	const kf = 0.9
	var dodge_return_force = (position - base_pos).y * kf
	if abs(dodge_return_force) < 0.001:
		dodge_return_force = 0.0
	var dodge_force = dodge * 100
	
	# Exponential smoothing of direction angle
	var alpha = 1 - exp(-delta / TURN_TIME_SCALE_S)
	angle += alpha * (turn - angle)
	
	# Rotate the whole scene for the correct facing
	rotation = angle
	
	# Physics
	var vspeed = (dodge_force - dodge_return_force) * delta * 400
	velocity = SPEED * Vector2(sin(angle), 0) + Vector2(0, vspeed)
	move_and_slide()
	
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider.is_in_group("obstacles"):
			_on_hit(collision)
			break
			
func _stunned_movement(delta: float) -> void:
	velocity = bounce_velocity
	move_and_slide()
	bounce_velocity = bounce_velocity.move_toward(Vector2.ZERO, BOUNCE_DECAY * delta)
	global_position.y = move_toward(global_position.y, 100, Y_RECENTRE_SPEED * delta)

func _on_hit(collision: KinematicCollision2D) -> void:
	state = State.STUNNED
	bounce_velocity = collision.get_normal() * BOUNCE_STRENGTH

	blood_level -= HIT_DAMAGE

	_freeze_scroll(true)
	await get_tree().create_timer(STUN_DURATION).timeout
	_freeze_scroll(false)
	state = State.NORMAL

func _freeze_scroll(frozen: bool) -> void:
	spawner.set_paused(frozen)
	Globals.cur_forward_speed = 0.0 if frozen else 300.0
