extends Node2D

@export var obstacle_scene: PackedScene
@export var child_scene: PackedScene

@export var spawn_interval_min := 300 * 0.5
@export var spawn_interval_max := 300 * 1.8

const NUM_LANES := 4
const BORDER_MARGIN := 175.0
const SPAWN_Y := -1000.0

@onready
var spawn_table = [
	[0.5, obstacle_scene],
	[0.5, child_scene],
]

var lane_positions: Array[float] = []

var next_spawn := 0.0

func _ready():
	_setup_lanes()
	_start_next_spawn_timer()

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

func _spawn():
	var x = randf();
	for row in spawn_table:
		var frac = row[0]
		var scene = row[1]

		x -= frac
		if x < 0:
			return scene.instantiate()

func _on_spawn_timer_timeout():
	var obstacle = _spawn()

	var lane_x = lane_positions[randi() % lane_positions.size()]
	obstacle.global_position = Vector2(lane_x, SPAWN_Y)

	add_child(obstacle)

	_start_next_spawn_timer()
