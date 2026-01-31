extends CharacterBody3D

# Movement settings
@export var speed := 5.0
@export var jump_velocity := 5
@export var mouse_sensitivity := 0.003

# Get the gravity from the project settings
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var camera: Camera3D = $Camera3D

func _ready() -> void:
	# Capture mouse for FPS controls
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	# Mouse look
	if event is InputEventMouseMotion:
		# Rotate body left/right
		rotate_y(-event.relative.x * mouse_sensitivity)
		# Rotate camera up/down
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		# Clamp vertical look to prevent flipping
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)
	
	# Press Escape to free mouse
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Click to recapture mouse
	if event is InputEventMouseButton and event.pressed:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity

	# Get input direction
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# Transform input to world direction based on where we're facing
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()
