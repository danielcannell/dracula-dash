extends Node2D

@export var car: CharacterBody2D

# Spring tuning - rotation
@export var lean_stiffness := 120.0     # higher = snaps back faster/stiffer
@export var lean_damping := 8.0         # higher = less oscillation/wobble
@export var lean_strength := 0.15  # how much accel/turning affects lean angle
@export var max_lean_angle := 0.35 # radians, clamp so it doesn't flip out

# Spring tuning - forward-back
@export var bounce_stiffness := 100.0
@export var bounce_damping := 8.0
@export var bounce_strength := 0.02
@export var max_bounce_offset := 1.0  # pixels

var current_angle := 0.0
var angle_velocity := 0.0

var current_bounce := 0.0
var bounce_velocity := 0.0

var last_car_velocity := Vector2.ZERO
var last_car_rotation := 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	if delta <= 0.0:
		return

	# car accel since last frame
	var accel := (car.velocity - last_car_velocity) / delta
	last_car_velocity = car.velocity

	var angular_vel := wrapf(car.rotation - last_car_rotation, -PI, PI) / delta
	last_car_rotation = car.rotation

	# sideways accel (relative to car facing) causes side-to-side lean
	var local_accel := accel.rotated(-car.rotation)
	var target_angle := -local_accel.x * lean_strength * 0.01 - angular_vel * lean_strength
	target_angle = clamp(target_angle, -max_lean_angle, max_lean_angle)

	# string sim for coffin rotation
	var force := (target_angle - current_angle) * lean_stiffness
	force -= angle_velocity * lean_damping
	angle_velocity += force * delta
	current_angle += angle_velocity * delta

	rotation = current_angle

	# string sim for coffin y axis
	var target_bounce := local_accel.y * bounce_strength
	target_bounce = clamp(target_bounce, -max_bounce_offset, max_bounce_offset)
	var bounce_force := (target_bounce - current_bounce) * bounce_stiffness
	bounce_force -= bounce_velocity * bounce_damping
	bounce_velocity += bounce_force * delta
	current_bounce += bounce_velocity * delta

	position.y = current_bounce
