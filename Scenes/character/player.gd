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

# Animation blending
var animation_tree: AnimationTree
var anim_state_machine: AnimationNodeStateMachinePlayback
const BLEND_TIME := 0.2

signal died
signal distance_changed(meters: float)
signal coin_collected(total: int)
signal boost_started
signal boost_ended

# Motion blur
var motion_blur_rect: ColorRect
var motion_blur_material: ShaderMaterial

func _ready() -> void:
	add_to_group("player")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_setup_animation_tree()
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
func _setup_animation_tree() -> void:
	if not animation_player:
		return
	
	# Load and add jump animation to the AnimationPlayer
	var jump_anim = load("res://assets/jump_animation/jump_animation.anim")
	if jump_anim:
		var lib = animation_player.get_animation_library("")
		if lib and not lib.has_animation("jump"):
			lib.add_animation("jump", jump_anim)
	
	# Find run animation name
	var run_anim_name := ""
	for anim in ["mixamo_com", "Run", "run", "Running", "Take 001"]:
		if animation_player.has_animation(anim):
			run_anim_name = anim
			break
	
	if run_anim_name.is_empty():
		return
	
	# Create AnimationTree with state machine for blending
	animation_tree = AnimationTree.new()
	animation_tree.name = "AnimationTree"
	
	# Build state machine
	var state_machine = AnimationNodeStateMachine.new()
	
	# Add run animation node
	var run_node = AnimationNodeAnimation.new()
	run_node.animation = run_anim_name
	state_machine.add_node("run", run_node, Vector2(0, 0))
	
	# Add jump animation node
	var jump_node = AnimationNodeAnimation.new()
	jump_node.animation = "jump"
	state_machine.add_node("jump", jump_node, Vector2(200, 0))
	
	# Create transitions with blending
	var run_to_jump = AnimationNodeStateMachineTransition.new()
	run_to_jump.xfade_time = BLEND_TIME
	run_to_jump.switch_mode = AnimationNodeStateMachineTransition.SWITCH_MODE_IMMEDIATE
	state_machine.add_transition("run", "jump", run_to_jump)
	
	var jump_to_run = AnimationNodeStateMachineTransition.new()
	jump_to_run.xfade_time = BLEND_TIME
	jump_to_run.switch_mode = AnimationNodeStateMachineTransition.SWITCH_MODE_AT_END
	state_machine.add_transition("jump", "run", jump_to_run)
	
	# Set start node
	state_machine.set_graph_offset(Vector2(-100, -50))
	
	animation_tree.tree_root = state_machine
	animation_tree.anim_player = animation_player.get_path()
	animation_tree.active = true
	
	model.add_child(animation_tree)
	
	# Get playback control
	anim_state_machine = animation_tree.get("parameters/playback")
	if anim_state_machine:
		anim_state_machine.travel("run")

func _play_jump_animation() -> void:
	if anim_state_machine:
		anim_state_machine.travel("jump")

func _play_run_animation() -> void:
	if anim_state_machine:
		anim_state_machine.travel("run")

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
		_play_jump_animation()
	
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# =========================
# PHYSICS
# =========================
var was_on_floor := true

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	var on_floor = is_on_floor()
	
	if not on_floor:
		velocity.y -= gravity * delta
	
	# Detect landing - transition back to run
	if on_floor and not was_on_floor:
		_play_run_animation()
	was_on_floor = on_floor
	
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
	camera_arm.global_position = camera_arm.global_position.lerp(cam_target, 4.0 * delta)
	
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
	was_on_floor = true
	_play_run_animation()
