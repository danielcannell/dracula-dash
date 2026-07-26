extends CharacterBody2D

@export var tractor_texture: Texture2D
@export var speed := 40.0
@export var nudge_strength := 60.0
@export var nudge_recovery_speed := 250.0

signal on_hit(object: PhysicsBody2D)

var nudge_offset := Vector2.ZERO

func _ready():
	add_to_group("obstacles")

func _physics_process(delta: float) -> void:
	var closing_speed = Globals.cur_forward_speed - speed
	velocity = Vector2(0, closing_speed)
	move_and_slide()
	_apply_nudge(delta)

	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider.is_in_group("cyclists") or collider.is_in_group("children"):
			on_hit.emit(collider)

	if position.y > 1000:
		queue_free()

func _apply_nudge(delta: float) -> void:
	if nudge_offset != Vector2.ZERO:
		nudge_offset = nudge_offset.move_toward(Vector2.ZERO, nudge_recovery_speed * delta)
		position += nudge_offset * delta

func nudge(direction: Vector2) -> void:
	nudge_offset = direction.normalized() * nudge_strength
