extends StaticBody2D

@export var garlic_texture: Texture2D
@export var onion_texture: Texture2D
@export var onion_particles: Texture2D
@export var garlic_particles: Texture2D
@export var swerve_amplitude := 30.0
@export var swerve_frequency := 2.0
@export var bounce_recovery_speed := 500.0

var is_bad := true
var base_x: float
var time_alive := 0.0
var bounce_offset := Vector2.ZERO
var swerve_phase := 0.0
var is_hit := false

func _ready():
	add_to_group("cyclists")
	_pick_variant()
	base_x = position.x

func _pick_variant():
	is_bad = randf() < 0.5
	$Sprite2D.texture = garlic_texture if is_bad else onion_texture

func set_swerve_phase(phase: float) -> void:
	swerve_phase = phase

# cyclist.gd
func _physics_process(delta):
	if is_hit:
		_apply_bounce_offset(delta)
		return
	time_alive += delta
	var effective_speed = 100.0
	position.y += delta * (effective_speed + Globals.cur_forward_speed)
	position.x = base_x + sin(time_alive * swerve_frequency + swerve_phase) * swerve_amplitude
	_apply_bounce_offset(delta)
	if position.y > 1000:
		queue_free()

func _apply_bounce_offset(delta: float) -> void:
	if bounce_offset != Vector2.ZERO:
		bounce_offset = bounce_offset.move_toward(Vector2.ZERO, bounce_recovery_speed * delta)
		position += bounce_offset * delta

func on_hit():
	is_hit = true
	$CollisionShape2D.set_deferred("disabled", true)
	$SoundHit.play()
	await get_tree().create_timer(0.2).timeout
	queue_free()

func get_explosion_texture() -> Texture2D:
	return garlic_particles if is_bad else onion_particles

func nudge(direction: Vector2, strength: float) -> void:
	bounce_offset = direction * strength

func get_blood_bonus() -> float:
	return -30.0 if is_bad else 30.0
