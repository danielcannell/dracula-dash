extends Node2D

@export var obstacle_scene: PackedScene
@export var child_scene: PackedScene
@export var cyclist_scene: PackedScene
@export var powerup_scene: PackedScene
@export var popemobile_scene: PackedScene
@export var popemobile_warning: PackedScene
@export var tractor_scene: PackedScene

@export var spawn_interval_min := 300 * 0.5
@export var spawn_interval_max := 300 * 1.8
@export var peloton_chance := 0.5

signal on_pope_hit(object: PhysicsBody2D)

const NUM_LANES := 4
const BORDER_MARGIN := 140.0
const SPAWN_Y := -1000.0
const POPE_SPAWN_Y := 500.0
const WARNING_Y := 250.0

@onready
var spawn_table = [
	[0.3, obstacle_scene],
	[0.2, child_scene],
	[0.25, cyclist_scene],
	[0.1, powerup_scene],
	[0.15, tractor_scene]
]

var lane_positions: Array[float] = []
var next_spawn := 0.0
var left_bound: float
var right_bound: float

func _ready():
	_setup_lanes()
	_start_next_spawn_timer()
	$PopeTimer.timeout.connect(_on_pope_timeout)

func _on_pope_timeout():
	var lane = randi() % lane_positions.size()
	var lane_x = lane_positions[lane]
	var warning = popemobile_warning.instantiate()
	warning.position = Vector2(lane_x, WARNING_Y);
	warning.timeout.connect(func (): _spawn_pope(lane))
	warning.timeout.connect(warning.queue_free)
	warning.z_index = 50
	add_child(warning)
	$PopeTimer.start(randf_range(5.0, 15.0))

func _physics_process(delta: float) -> void:
	next_spawn -= delta * Globals.cur_forward_speed
	if next_spawn < 0:
		_on_spawn_timer_timeout()

func _start_next_spawn_timer():
	next_spawn = randf_range(spawn_interval_min, spawn_interval_max)

func _setup_lanes():
	var screen_size = get_viewport_rect().size
	var cam = get_viewport().get_camera_2d()
	var centre_x: float = cam.get_screen_center_position().x

	var left_edge = centre_x - screen_size.x / 2.0
	var usable_width = screen_size.x - (BORDER_MARGIN * 2.0)
	var lane_width = usable_width / float(NUM_LANES)

	for i in range(NUM_LANES):
		var lane_center = left_edge + BORDER_MARGIN + lane_width * i + lane_width / 2.0
		lane_positions.append(lane_center)
	left_bound = left_edge + BORDER_MARGIN - 50
	right_bound = left_edge + BORDER_MARGIN + usable_width + 50

func _pick_scene() -> PackedScene:
	var x = randf()
	for row in spawn_table:
		var frac = row[0]
		var scene = row[1]
		x -= frac
		if x < 0:
			return scene
	return spawn_table[-1][1]

func _on_spawn_timer_timeout():
	var scene = _pick_scene()

	if scene == cyclist_scene and randf() < peloton_chance:
		_spawn_peloton(scene)
	else:
		_spawn_single(scene)

	_start_next_spawn_timer()

func _spawn_single(scene: PackedScene):
	var obstacle = scene.instantiate()
	var lane_x = lane_positions[randi() % lane_positions.size()]
	obstacle.position = Vector2(lane_x, SPAWN_Y)
	if obstacle.has_signal("on_hit"):
		obstacle.on_hit.connect(on_pope_hit.emit)
	add_child(obstacle)

func _spawn_pope(lane):
	var pope = popemobile_scene.instantiate()
	var lane_x = lane_positions[lane]
	pope.position = Vector2(lane_x, POPE_SPAWN_Y)
	pope.on_hit.connect(on_pope_hit.emit)
	add_child(pope)

func _spawn_peloton(scene: PackedScene):
	var count = randi_range(2, 4)
	var lane_x = lane_positions[randi() % lane_positions.size()]
	var jitter_max = min(300.0, min(lane_x - left_bound, right_bound - lane_x))

	for i in range(count):
		var cyclist = scene.instantiate()

		var stagger_y = SPAWN_Y - (i * 120.0)
		var x_jitter = randf_range(-jitter_max, jitter_max)
		var x = clamp(lane_x + x_jitter, left_bound, right_bound)

		cyclist.position = Vector2(x, stagger_y)
		add_child(cyclist)
		if cyclist.has_method("set_swerve_phase"):
			cyclist.set_swerve_phase(randf_range(0, TAU))
