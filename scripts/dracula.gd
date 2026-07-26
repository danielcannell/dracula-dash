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
signal hit(object: PhysicsBody2D)
signal hit_bloody(object: PhysicsBody2D)
signal hit_powerup(object: PhysicsBody2D)
signal stunned(stun: bool)

const TURN_TIME_SCALE_S = 0.1
const SPEED = 1000
const BASE_BLOOD_DRAIN_RATE = 5
const DRAIN_RATE_DELTA = 0.25
const STUN_DURATION = 0.6
const BOUNCE_STRENGTH = 400.0
const BOUNCE_DECAY = 1000.0
const Y_RECENTRE_SPEED = 300.0
const HIT_DAMAGE = 10.0
const POPE_DAMAGE = 100.0
const SMALL_BOUNCE_STRENGTH = 200.0
const IMMUNE_TIMER = 3

enum State { NORMAL, STUNNED, DEAD }

var angle: float = 0
var cur_blood_drain_rate: float = BASE_BLOOD_DRAIN_RATE
var blood_level: float = 100
var state := State.NORMAL
var bounce_velocity := Vector2.ZERO
var base_pos: Vector2
var on_grass := false

func _ready() -> void:
	add_to_group("player")
	base_pos = position
	var items = [wheel_fl, wheel_fr, wheel_bl, wheel_br]
	for item in items:
		wheels.append(item)
		var scene = trail_scene.instantiate()
		wheel_trails.append(scene)
		trail_container.add_child(scene)

		hit_bloody.connect(
			func (obj):
				scene.make_bloody())

func on_entered_grass() -> void:
	on_grass = true

func on_exited_grass() -> void:
	on_grass = false

func _on_dead() -> void:
	state = State.DEAD
	$CollisionShape2D.disabled = true
	Globals.cur_forward_speed = 0
	dead.emit()

func add_blood(amount: float) -> void:
	if state != State.DEAD:
		blood_level += amount
		if blood_level > 100.0:
			blood_level = 100.0
		if blood_level <= 0:
			blood_level = 0
			_on_dead()
		blood.emit(blood_level)

func _process(delta: float) -> void:
	add_blood(-delta * cur_blood_drain_rate)
	cur_blood_drain_rate += delta * DRAIN_RATE_DELTA

func _physics_process(delta: float) -> void:
	match state:
		State.NORMAL:
			_normal_movement(delta)
			_process_wheel_trail()
		State.STUNNED:
			_stunned_movement(delta)
		State.DEAD:
			return

	for i in range(len(wheels)):
		var pos = wheels[i].global_position - trail_container.position
		_extend_trail(wheel_trails[i], pos)

	Globals.cur_position.x = position.x
	Globals.cur_position.y += -delta * Globals.cur_forward_speed

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
	if dodge_return_force < 0 and on_grass:
		boost_scale = 3

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
			hit.emit(collider)
			_on_hit(collision)
			if collider.has_method("nudge"):
				collider.nudge(-collision.get_normal())
			break
		elif collider.is_in_group("children") or collider.is_in_group("dead_players"):
			hit_bloody.emit(collider)
			break
		elif collider.is_in_group("cyclists"):
			hit_bloody.emit(collider)
			_small_bounce(collision)
			break
		elif collider.is_in_group("powerups"):
			hit_powerup.emit(collider)
			_immune_on_hit()
			break


func _immune_on_hit():
	$AnimatedSprite2D.play("immune_start")
	z_index = 99
	var old_mask = collision_mask
	var old_layer = collision_layer
	collision_mask = 16
	collision_layer = 0
	await get_tree().create_timer(IMMUNE_TIMER).timeout
	z_index = 0
	$AnimatedSprite2D.play("immune_stop")
	await $AnimatedSprite2D.animation_finished
	collision_mask = old_mask
	collision_layer = old_layer


func _stunned_movement(delta: float) -> void:
	velocity = bounce_velocity
	move_and_slide()
	bounce_velocity = bounce_velocity.move_toward(Vector2.ZERO, BOUNCE_DECAY * delta)
	global_position.y = move_toward(global_position.y, 100, Y_RECENTRE_SPEED * delta)

func hit_by_pope() -> void:
	$Audio/Obstacle_Hit.play()
	add_blood(-POPE_DAMAGE)

func _on_hit(collision: KinematicCollision2D) -> void:
	$Audio/Obstacle_Hit.play()
	state = State.STUNNED

	var normal = collision.get_normal()
	bounce_velocity = normal * BOUNCE_STRENGTH

	if abs(normal.x) < 0.3:
		var collider = collision.get_collider()
		var side = sign(global_position.x - collider.global_position.x)
		if side == 0:
			side = 1 if randf() < 0.5 else -1
		bounce_velocity.x += side * BOUNCE_STRENGTH * 0.6

	add_blood(-HIT_DAMAGE)

	Globals.cur_forward_speed = 0.0
	stunned.emit(true)
	await get_tree().create_timer(STUN_DURATION).timeout
	stunned.emit(false)
	state = State.NORMAL

func _small_bounce(collision: KinematicCollision2D) -> void:
	velocity += collision.get_normal() * SMALL_BOUNCE_STRENGTH
	var collider = collision.get_collider()
	if collider.has_method("nudge"):
		collider.nudge(-collision.get_normal(), BOUNCE_STRENGTH)

func _extend_trail(line: Line2D, pos: Vector2) -> void:
	if line.get_point_count() == 0 or pos.distance_to(line.points[-1]) > 4.0:
		line.trail_add_point(pos)
		if line.get_point_count() > MAX_TRAIL_POINTS:
			line.remove_point(0)
