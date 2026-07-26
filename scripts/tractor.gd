extends StaticBody2D

@export var tractor_texture: Texture2D
@export var speed := 40.0
@export var nudge_strength := 60.0
@export var nudge_recovery_speed := 250.0

signal on_hit(object: PhysicsBody2D)

var nudge_offset := Vector2.ZERO

func _ready():
	add_to_group("obstacles")
	add_to_group("tractors")
	$HitArea.body_entered.connect(_on_hit_area_body_entered)

func _physics_process(delta: float) -> void:
	var closing_speed = Globals.cur_forward_speed - speed
	position += Vector2(0, closing_speed) * delta
	_apply_nudge(delta)

	if position.y > 1000:
		queue_free()

func _apply_nudge(delta: float) -> void:
	if nudge_offset != Vector2.ZERO:
		nudge_offset = nudge_offset.move_toward(Vector2.ZERO, nudge_recovery_speed * delta)
		position += nudge_offset * delta

func nudge(direction: Vector2) -> void:
	nudge_offset = direction.normalized() * nudge_strength

func _on_hit_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("cyclists") or body.is_in_group("children"):
		on_hit.emit(body)
