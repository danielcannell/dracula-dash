extends Node2D

@export var obstacle_scene: PackedScene
@export var scroll_speed := 300.0
@export var spawn_interval_min := 0.5
@export var spawn_interval_max := 1.8

const NUM_LANES := 4
const BORDER_MARGIN := 175.0
const SPAWN_Y := -1000.0

var lane_positions: Array[float] = []

func _ready():
	_setup_lanes()

	$SpawnTimer.one_shot = true
	$SpawnTimer.timeout.connect(_on_spawn_timer_timeout)
	_start_next_spawn_timer()

func _start_next_spawn_timer():
	$SpawnTimer.wait_time = randf_range(spawn_interval_min, spawn_interval_max)
	$SpawnTimer.start()
	
func set_paused(paused: bool):
	$SpawnTimer.paused = paused

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

func _on_spawn_timer_timeout():
	var obstacle = obstacle_scene.instantiate()
	add_child(obstacle)

	var lane_x = lane_positions[randi() % lane_positions.size()]
	obstacle.global_position = Vector2(lane_x, SPAWN_Y)
	obstacle.scroll_speed = scroll_speed
	
	_start_next_spawn_timer()
