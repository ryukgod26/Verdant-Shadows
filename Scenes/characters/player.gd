extends CharacterBody3D

# === MOVEMENT SETTINGS ===
@export var run_speed := 10.0
@export var lane_switch_speed := 10.0
@export var jump_velocity := 4.5

# === LANE SYSTEM ===
@export var lane_width := 2.0  # Distance between lanes
var current_lane := 0  # -1 = left, 0 = center, 1 = right
var target_x := 0.0

# === CAMERA SETTINGS ===
@export var camera_distance := 5.0  # How far behind
@export var camera_height := 2.5    # How high above player
@export var camera_smoothing := 5.0

# === INTERNAL ===
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var is_running := true

@onready var camera: Camera3D = $CameraArm/Camera3D
@onready var camera_arm: Node3D = $CameraArm
@onready var model: Node3D = $Model
@onready var animation_player: AnimationPlayer = $Model/AnimationPlayer

func _ready() -> void:
	# Start in center lane
	target_x = 0.0
	
	# Lock & hide cursor for cleaner gameplay
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Start run animation if available
	if animation_player and animation_player.has_animation("mixamo_com"):
		print("ANIM AVAILABLE")
		animation_player.play("mixamo_com")

func _unhandled_input(event: InputEvent) -> void:
	# Lane switching
	if event.is_action_pressed("ui_left") and current_lane > -1:
		current_lane -= 1
		target_x = current_lane * lane_width
	
	if event.is_action_pressed("ui_right") and current_lane < 1:
		current_lane += 1
		target_x = current_lane * lane_width
	
	# Jump
	if event.is_action_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity
	
	# Escape to free cursor (for testing)
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _physics_process(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Auto-run forward (negative Z is forward in Godot)
	if is_running:
		velocity.z = -run_speed
	
	# Smooth lane switching (X axis)
	var current_x = global_position.x
	var x_diff = target_x - current_x
	
	if abs(x_diff) > 0.01:
		velocity.x = sign(x_diff) * lane_switch_speed
		# Clamp so we don't overshoot
		if abs(x_diff) < abs(velocity.x * delta):
			velocity.x = x_diff / delta
	else:
		velocity.x = 0
		# Snap to exact lane position
		global_position.x = target_x
	
	move_and_slide()
	
	# Update camera to follow
	_update_camera(delta)

func _update_camera(delta: float) -> void:
	# Camera arm follows player position
	var target_pos = global_position + Vector3(0, camera_height, camera_distance)
	camera_arm.global_position = camera_arm.global_position.lerp(target_pos, camera_smoothing * delta)
	
	# Camera always looks at player
	camera.look_at(global_position + Vector3(0, 1, 0))
