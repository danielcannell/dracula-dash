extends CharacterBody2D

@onready var wheel_fl: Marker2D = $WheelFL
@onready var wheel_fr: Marker2D = $WheelFR
@onready var wheel_bl: Marker2D = $WheelBL
@onready var wheel_br: Marker2D = $WheelBR

# trail
var trail_scene: PackedScene = preload("res://scenes/trail.tscn")
@onready var trail_container: Node2D = get_tree().current_scene.get_node("TrailContainer")
var active_trail_bl: Line2D
var active_trail_br: Line2D
const MAX_TRAIL_POINTS := 80

# wheels and thier trails - filled in on ready
var wheels = []
var wheel_trails = []

signal dead
signal blood(health: float)
signal hit(object: StaticBody2D)
signal hit_bloody(object: StaticBody2D)
signal stunned(stun: bool)

const TURN_TIME_SCALE_S = 0.1
const SPEED = 1000
const BLOOD_DRAIN_RATE = 5
const STUN_DURATION = 0.6
const BOUNCE_STRENGTH = 400.0
const BOUNCE_DECAY = 1000.0
const Y_RECENTRE_SPEED = 300.0
const HIT_DAMAGE = 10.0

enum State { NORMAL, STUNNED }

var angle: float = 0
var blood_level: float = 100
var state := State.NORMAL
var bounce_velocity := Vector2.ZERO
var base_pos: Vector2

func _ready() -> void:
	add_to_group("player")
	base_pos = position
	var items = [wheel_fl, wheel_fr, wheel_bl, wheel_br]
	for item in items:
		wheels.append(item)
		var scene = trail_scene.instantiate()
		wheel_trails.append(scene)
		trail_container.add_child(scene)

func add_blood(amount: float) -> void:
	blood_level += amount
	if blood_level > 100.0:
		blood_level = 100.0
	if blood_level <= 0:
		blood_level = 0
		emit_signal("dead")
	emit_signal("blood", blood_level)

func _process(delta: float) -> void:
	add_blood(-delta * BLOOD_DRAIN_RATE)

func _physics_process(delta: float) -> void:
	match state:
		State.NORMAL:
			_normal_movement(delta)
			_process_wheel_trail()
		State.STUNNED:
			_stunned_movement(delta)

	for i in range(len(wheels)):
		var pos = wheels[i].global_position - trail_container.position
		_extend_trail(wheel_trails[i], pos)

func _process_wheel_trail():
	for i in range(len(wheels)):
		var pos = wheels[i].global_position - trail_container.position
		_extend_trail(wheel_trails[i], pos)

func _normal_movement(delta: float) -> void:
	# Get input in rang e [-1, 1]
	var turn = Input.get_axis("turn_left", "turn_right")
	var dodge = Input.get_axis("dodge_up", "dodge_down")

	var dodge_return_force = (position - base_pos).y
	if abs(dodge_return_force) < 0.001:
		dodge_return_force = 0.0
	var dodge_force = dodge * 100

	var boost_scale = 10 if dodge_return_force < 0 else 2

	Globals.cur_forward_speed = 300.0 - dodge_return_force * boost_scale

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
			hit.emit(collider)
			break
		elif collider.is_in_group("children"):
			hit_bloody.emit(collider)
			break

func _stunned_movement(delta: float) -> void:
	velocity = bounce_velocity
	move_and_slide()
	bounce_velocity = bounce_velocity.move_toward(Vector2.ZERO, BOUNCE_DECAY * delta)
	global_position.y = move_toward(global_position.y, 100, Y_RECENTRE_SPEED * delta)

func _on_hit(collision: KinematicCollision2D) -> void:
	$Audio/Hit.play()
	state = State.STUNNED
	bounce_velocity = collision.get_normal() * BOUNCE_STRENGTH

	blood_level -= HIT_DAMAGE

	Globals.cur_forward_speed = 0.0
	stunned.emit(true)
	await get_tree().create_timer(STUN_DURATION).timeout
	stunned.emit(false)
	state = State.NORMAL

func _extend_trail(line: Line2D, pos: Vector2) -> void:
	if line.get_point_count() == 0 or pos.distance_to(line.points[-1]) > 4.0:
		line.add_point(pos)
		if line.get_point_count() > MAX_TRAIL_POINTS:
			line.remove_point(0)
