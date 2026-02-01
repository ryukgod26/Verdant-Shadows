extends CharacterBody3D

# === MOVEMENT SETTINGS ===
@export var run_speed := 12.0
@export var lane_switch_speed := 20.0
@export var jump_velocity := 5.0

# === LANE SYSTEM ===
@export var lane_width := 2.0
var current_lane := 0  # -1, 0, 1

# === CAMERA SETTINGS ===
@export var camera_distance := 6.0
@export var camera_height := 3.0

# === STATE ===
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var is_running := true
var is_dead := false
var distance_traveled := 0.0
var coins_collected := 0

# === NODE REFERENCES ===
@onready var camera_arm: Node3D = $CameraArm
@onready var camera: Camera3D = $CameraArm/Camera3D
@onready var model: Node3D = $Model
@onready var animation_player: AnimationPlayer = _find_animation_player(model)
@onready var hud: Control = $HUD

signal died
signal distance_changed(meters: float)
signal coin_collected(total: int)

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_start_run_animation()
	_setup_coin_collector()
	
	if hud:
		if hud.has_method("update_distance"):
			distance_changed.connect(hud.update_distance)
		if hud.has_method("update_coins"):
			coin_collected.connect(hud.update_coins)

func _setup_coin_collector() -> void:
	var collector = Area3D.new()
	collector.name = "CoinCollector"
	collector.monitoring = true
	collector.monitorable = false
	
	var col = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 1.2
	col.shape = shape
	
	collector.add_child(col)
	add_child(collector)
	
	collector.area_entered.connect(_on_coin_touched)

func _on_coin_touched(area: Area3D) -> void:
	if area.has_meta("is_coin"):
		coins_collected += 1
		coin_collected.emit(coins_collected)
		area.queue_free()

# =========================
# ANIMATION
# =========================
func _start_run_animation() -> void:
	if not animation_player:
		return
	if animation_player.has_animation("mixamo_com"):
		animation_player.play("mixamo_com")
		return
	for anim in ["Run", "run", "Running", "Take 001"]:
		if animation_player.has_animation(anim):
			animation_player.play(anim)
			return

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
	if is_dead:
		return
	
	if event.is_action_pressed("ui_left") and current_lane > -1:
		current_lane -= 1
	
	if event.is_action_pressed("ui_right") and current_lane < 1:
		current_lane += 1
	
	if event.is_action_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity
	
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# =========================
# PHYSICS
# =========================
func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	if is_running:
		distance_traveled += run_speed * delta
		distance_changed.emit(distance_traveled)
		
		# Forward movement (always -Z)
		velocity.z = -run_speed
		
		# Lane movement
		var target_x = current_lane * lane_width
		var lane_diff = target_x - global_position.x
		velocity.x = lane_diff * lane_switch_speed
	
	move_and_slide()
	
	if model:
		model.rotation.y = PI
	
	_update_camera(delta)

# =========================
# CAMERA
# =========================
func _update_camera(delta: float) -> void:
	var cam_target = global_position + Vector3(0, camera_height, camera_distance)
	camera_arm.global_position = camera_arm.global_position.lerp(cam_target, 10.0 * delta)
	
	var look_target = global_position + Vector3(0, 0.5, -5.0)
	camera.look_at(look_target)

# =========================
# EXTERNAL
# =========================
func get_distance() -> float:
	return distance_traveled

func get_coins() -> int:
	return coins_collected

func respawn() -> void:
	is_dead = false
	is_running = true
	current_lane = 0
	distance_traveled = 0.0
	coins_collected = 0
	global_position = Vector3(0, 1, 0)
	velocity = Vector3.ZERO
