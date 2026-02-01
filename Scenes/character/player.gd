extends CharacterBody3D

# === MOVEMENT SETTINGS ===
@export var run_speed := 10.0
@export var lane_switch_speed := 10.0
@export var jump_velocity := 4.5

# === LANE SYSTEM ===
@export var lane_width := 2.0
var current_lane := 0          # -1 = left, 0 = center, 1 = right
var target_x := 0.0

# === CAMERA SETTINGS ===
@export var camera_distance := 5.0
@export var camera_height := 2.5
@export var camera_smoothing := 5.0
@export var camera_look_ahead := 2.0

# === STATE ===
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var is_running := true
var distance_traveled := 0.0

# === NODE REFERENCES ===
@onready var camera_arm: Node3D = $CameraArm
@onready var camera: Camera3D = $CameraArm/Camera3D
@onready var model: Node3D = $Model
@onready var animation_player: AnimationPlayer = _find_animation_player(model)

func _ready() -> void:
	target_x = 0.0
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_start_run_animation()

# =========================
# ANIMATION
# =========================
func _start_run_animation() -> void:
	if not animation_player:
		push_warning("No AnimationPlayer found")
		return

	# Preferred animation (your confirmed correct one)
	if animation_player.has_animation("mixamo_com"):
		animation_player.play("mixamo_com")
		return

	# Fallback guesses (future-proofing)
	var fallbacks = ["Run", "run", "Running", "Take 001"]
	for name in fallbacks:
		if animation_player.has_animation(name):
			animation_player.play(name)
			return

	print("Available animations:", animation_player.get_animation_list())

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var result = _find_animation_player(child)
		if result:
			return result
	return null

# =========================
# INPUT
# =========================
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_left") and current_lane > -1:
		current_lane -= 1
		target_x = current_lane * lane_width

	if event.is_action_pressed("ui_right") and current_lane < 1:
		current_lane += 1
		target_x = current_lane * lane_width

	if event.is_action_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity

	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# =========================
# PHYSICS
# =========================
func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Auto-run
	if is_running:
		velocity.z = -run_speed
		distance_traveled += run_speed * delta

	# Lane movement
	var x_diff = target_x - global_position.x
	if abs(x_diff) > 0.01:
		velocity.x = sign(x_diff) * lane_switch_speed
		if abs(x_diff) < abs(velocity.x * delta):
			velocity.x = x_diff / delta
	else:
		velocity.x = 0
		global_position.x = target_x

	move_and_slide()
	_update_camera(delta)

# =========================
# CAMERA
# =========================
func _update_camera(delta: float) -> void:
	var cam_target = global_position + Vector3(0, camera_height, camera_distance)
	camera_arm.global_position = camera_arm.global_position.lerp(
		cam_target,
		camera_smoothing * delta
	)

	var look_target = global_position + Vector3(0, 1.0, -camera_look_ahead)
	camera.look_at(look_target)

# =========================
# EXTERNAL CONTROL
# =========================
func stop_running() -> void:
	is_running = false
	velocity = Vector3.ZERO

func start_running() -> void:
	is_running = true

func get_distance() -> float:
	return distance_traveled
