extends CharacterBody3D

# === MOVEMENT SETTINGS ===
@export var run_speed := 12.0
@export var lane_switch_speed := 20.0
@export var jump_velocity := 5.0

# === BOOST SETTINGS ===
@export var boost_multiplier := 7.0
@export var boost_duration := 5.0

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
var is_boosting := false
var boost_timer := 0.0
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
signal boost_started
signal boost_ended

# Motion blur
var motion_blur_rect: ColorRect
var motion_blur_material: ShaderMaterial

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_start_run_animation()
	_setup_coin_collector()
	_setup_motion_blur()
	
	if hud:
		if hud.has_method("update_distance"):
			distance_changed.connect(hud.update_distance)
		if hud.has_method("update_coins"):
			coin_collected.connect(hud.update_coins)
	
	boost_started.connect(_on_boost_started)
	boost_ended.connect(_on_boost_ended)

func _setup_motion_blur() -> void:
	# HUD layer above motion blur
	var hud_layer = CanvasLayer.new()
	hud_layer.name = "HUDLayer"
	hud_layer.layer = 20
	add_child(hud_layer)
	
	if hud:
		hud.get_parent().remove_child(hud)
		hud_layer.add_child(hud)
	
	# Motion blur layer
	var blur_layer = CanvasLayer.new()
	blur_layer.name = "MotionBlurLayer"
	blur_layer.layer = 10
	add_child(blur_layer)
	
	motion_blur_rect = ColorRect.new()
	motion_blur_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	motion_blur_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var shader = load("res://Shaders/motion_blur.gdshader")
	motion_blur_material = ShaderMaterial.new()
	motion_blur_material.shader = shader
	motion_blur_material.set_shader_parameter("blur_amount", 0.0)
	
	motion_blur_rect.material = motion_blur_material
	blur_layer.add_child(motion_blur_rect)

func _on_boost_started() -> void:
	if motion_blur_material:
		var tween = create_tween()
		tween.tween_method(_set_blur_amount, 0.0, 1.0, 0.3)
	
	if hud and hud.has_method("show_boost_bar"):
		hud.show_boost_bar(boost_duration)
	
	# Speed up animation
	if animation_player:
		animation_player.speed_scale = 1.4

func _on_boost_ended() -> void:
	if motion_blur_material:
		var tween = create_tween()
		tween.tween_method(_set_blur_amount, 1.0, 0.0, 0.5)
	
	if hud and hud.has_method("hide_boost_bar"):
		hud.hide_boost_bar()
	
	# Normal animation speed
	if animation_player:
		animation_player.speed_scale = 1.0

func _set_blur_amount(val: float) -> void:
	if motion_blur_material:
		motion_blur_material.set_shader_parameter("blur_amount", val)

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
	elif area.has_meta("is_booster"):
		_activate_boost()
		area.queue_free()

func _activate_boost() -> void:
	if is_boosting:
		# Extend boost time
		boost_timer = boost_duration
		return
	
	is_boosting = true
	boost_timer = boost_duration
	boost_started.emit()

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
	
	# Boost timer
	if is_boosting:
		boost_timer -= delta
		
		if hud and hud.has_method("update_boost_bar"):
			hud.update_boost_bar(boost_timer)
		
		if boost_timer <= 0:
			is_boosting = false
			boost_ended.emit()
	
	if is_running:
		var current_speed = run_speed * (boost_multiplier if is_boosting else 1.0)
		distance_traveled += current_speed * delta
		distance_changed.emit(distance_traveled)
		
		# Forward movement (always -Z)
		velocity.z = -current_speed
		
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
