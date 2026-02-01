extends Node3D
class_name PathChunkTurn

# === CHUNK CONFIGURATION ===
const PATH_WIDTH := 6.0
const TURN_RADIUS := 10.0  # How wide the turn is
const SEGMENTS := 8        # Smoothness of the curve
const DECORATION_WIDTH := 30.0

# Decoration density (reduced for turn chunks since they're smaller)
const TREES_PER_SIDE := 4
const GRASS_PER_SIDE := 6
const ROCKS_PER_SIDE := 2
const BUSHES_PER_SIDE := 3

# Scripts
const JungleTreeScript = preload("res://Scripts/Decorations/jungle_tree.gd")
const GrassClumpScript = preload("res://Scripts/Decorations/grass_clump.gd")
const JungleRockScript = preload("res://Scripts/Decorations/jungle_rock.gd")
const JungleBushScript = preload("res://Scripts/Decorations/jungle_bush.gd")

enum TurnDirection { LEFT = -1, RIGHT = 1 }

var chunk_index := 0
var turn_direction: TurnDirection = TurnDirection.LEFT
var decorations_container: Node3D

# Materials
static var path_material: StandardMaterial3D
static var edge_material: StandardMaterial3D
static var ground_material: StandardMaterial3D
static var strip_material_warm: StandardMaterial3D
static var strip_material_cool: StandardMaterial3D
static var materials_initialized := false

# Light strip references for color changing
var strip_meshes: Array[MeshInstance3D] = []
var current_mode := 0  # 0 = warm, 1 = cool

# Light colors
const WARM_COLOR := Color(1.0, 0.7, 0.4)
const COOL_COLOR := Color(0.4, 0.6, 1.0)
const EMISSION_ENERGY := 2.0

func _ready() -> void:
	_init_materials()
	_create_turn_geometry()
	_create_decorations()
	set_light_mode(current_mode)

static func _init_materials() -> void:
	if materials_initialized:
		return
	
	path_material = StandardMaterial3D.new()
	path_material.albedo_color = Color(0.4, 0.38, 0.35)
	path_material.roughness = 0.9
	
	edge_material = StandardMaterial3D.new()
	edge_material.albedo_color = Color(0.3, 0.28, 0.25)
	edge_material.roughness = 0.85
	
	ground_material = StandardMaterial3D.new()
	ground_material.albedo_color = Color(0.15, 0.12, 0.08)
	ground_material.roughness = 0.95
	
	materials_initialized = true

func _create_turn_geometry() -> void:
	var dir = int(turn_direction)
	
	# Create curved path segments
	for i in range(SEGMENTS):
		var angle_start = (float(i) / SEGMENTS) * (PI / 2)
		var angle_end = (float(i + 1) / SEGMENTS) * (PI / 2)
		var angle_mid = (angle_start + angle_end) / 2
		
		# Calculate positions along the curve
		# Turn pivots around a point offset from the path
		var pivot = Vector3(dir * TURN_RADIUS, 0, 0)
		
		var pos_start = pivot + Vector3(-dir * TURN_RADIUS * cos(angle_start), 0, -TURN_RADIUS * sin(angle_start))
		var pos_end = pivot + Vector3(-dir * TURN_RADIUS * cos(angle_end), 0, -TURN_RADIUS * sin(angle_end))
		var pos_mid = (pos_start + pos_end) / 2
		
		var segment_length = pos_start.distance_to(pos_end)
		
		# Path segment
		var path_mesh = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(PATH_WIDTH, 0.5, segment_length + 0.1)  # Slight overlap
		path_mesh.mesh = box
		path_mesh.position = pos_mid + Vector3(0, -0.25, 0)
		path_mesh.rotation.y = -angle_mid * dir
		path_mesh.material_override = path_material
		add_child(path_mesh)
		
		# Collision
		var body = StaticBody3D.new()
		var collision = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = box.size
		collision.shape = shape
		body.position = path_mesh.position
		body.rotation = path_mesh.rotation
		add_child(body)
		body.add_child(collision)
		
		# Inner edge
		var inner_edge = MeshInstance3D.new()
		var edge_box = BoxMesh.new()
		edge_box.size = Vector3(0.4, 0.4, segment_length + 0.1)
		inner_edge.mesh = edge_box
		var inner_offset = (TURN_RADIUS - PATH_WIDTH / 2 - 0.2)
		inner_edge.position = pivot + Vector3(-dir * inner_offset * cos(angle_mid), 0.2, -inner_offset * sin(angle_mid))
		inner_edge.rotation.y = -angle_mid * dir
		inner_edge.material_override = edge_material
		add_child(inner_edge)
		
		# Outer edge
		var outer_edge = MeshInstance3D.new()
		outer_edge.mesh = edge_box
		var outer_offset = (TURN_RADIUS + PATH_WIDTH / 2 + 0.2)
		outer_edge.position = pivot + Vector3(-dir * outer_offset * cos(angle_mid), 0.2, -outer_offset * sin(angle_mid))
		outer_edge.rotation.y = -angle_mid * dir
		outer_edge.material_override = edge_material
		add_child(outer_edge)
		
		# LED strips along edges
		_create_turn_strip(pivot, inner_offset - 0.15, angle_mid, segment_length, dir)
		_create_turn_strip(pivot, outer_offset + 0.15, angle_mid, segment_length, dir)
	
	# Ground (simplified for turns)
	_create_turn_ground()

func _create_turn_strip(pivot: Vector3, radius: float, angle: float, length: float, dir: int) -> void:
	var strip = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = Vector3(0.15, 0.08, length + 0.1)
	strip.mesh = mesh
	strip.position = pivot + Vector3(-dir * radius * cos(angle), 0.06, -radius * sin(angle))
	strip.rotation.y = -angle * dir
	
	# Create unique material for this strip
	var mat = StandardMaterial3D.new()
	mat.emission_enabled = true
	mat.emission = WARM_COLOR
	mat.emission_energy_multiplier = EMISSION_ENERGY
	mat.albedo_color = WARM_COLOR.darkened(0.5)
	mat.roughness = 0.3
	strip.material_override = mat
	
	add_child(strip)
	strip_meshes.append(strip)

func _create_turn_ground() -> void:
	# Simplified ground plane for the turn area
	var ground = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = Vector3(TURN_RADIUS * 2 + DECORATION_WIDTH, 0.2, TURN_RADIUS * 2 + DECORATION_WIDTH)
	ground.mesh = mesh
	ground.position = Vector3(int(turn_direction) * TURN_RADIUS / 2, -0.35, -TURN_RADIUS / 2)
	ground.material_override = ground_material
	add_child(ground)

func _create_decorations() -> void:
	decorations_container = Node3D.new()
	decorations_container.name = "Decorations"
	add_child(decorations_container)
	
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(chunk_index)
	
	var dir = int(turn_direction)
	var pivot = Vector3(dir * TURN_RADIUS, 0, 0)
	
	# Spawn decorations around the outer edge of the turn
	_spawn_turn_decorations(rng, pivot, TURN_RADIUS + PATH_WIDTH / 2 + 3.0, DECORATION_WIDTH * 0.7)
	
	# Spawn some on the inner edge too (if there's room)
	if TURN_RADIUS > PATH_WIDTH:
		_spawn_turn_decorations(rng, pivot, 2.0, TURN_RADIUS - PATH_WIDTH / 2 - 2.0)

func _spawn_turn_decorations(rng: RandomNumberGenerator, pivot: Vector3, min_radius: float, max_radius: float) -> void:
	var dir = int(turn_direction)
	
	# Trees
	for i in range(TREES_PER_SIDE):
		var tree = JungleTreeScript.create_random(rng)
		var angle = rng.randf_range(0, PI / 2)
		var radius = rng.randf_range(min_radius, max_radius)
		tree.position = pivot + Vector3(-dir * radius * cos(angle), 0, -radius * sin(angle))
		tree.rotation.y = rng.randf() * TAU
		decorations_container.add_child(tree)
	
	# Grass
	for i in range(GRASS_PER_SIDE):
		var grass = GrassClumpScript.create_random(rng)
		var angle = rng.randf_range(0, PI / 2)
		var radius = rng.randf_range(min_radius, max_radius)
		grass.position = pivot + Vector3(-dir * radius * cos(angle), 0, -radius * sin(angle))
		decorations_container.add_child(grass)
	
	# Rocks
	for i in range(ROCKS_PER_SIDE):
		var rock = JungleRockScript.create_random(rng)
		var angle = rng.randf_range(0, PI / 2)
		var radius = rng.randf_range(min_radius, max_radius * 0.7)
		rock.position = pivot + Vector3(-dir * radius * cos(angle), 0, -radius * sin(angle))
		rock.rotation.y = rng.randf() * TAU
		decorations_container.add_child(rock)
	
	# Bushes
	for i in range(BUSHES_PER_SIDE):
		var bush = JungleBushScript.create_random(rng)
		var angle = rng.randf_range(0, PI / 2)
		var radius = rng.randf_range(min_radius, max_radius * 0.8)
		bush.position = pivot + Vector3(-dir * radius * cos(angle), 0, -radius * sin(angle))
		bush.rotation.y = rng.randf() * TAU
		decorations_container.add_child(bush)

# === LIGHTING CONTROL ===
func set_light_mode(mode: int) -> void:
	current_mode = mode
	var color = WARM_COLOR if mode == 0 else COOL_COLOR
	
	for strip in strip_meshes:
		var mat = strip.material_override as StandardMaterial3D
		if mat:
			mat.emission = color
			mat.albedo_color = color.darkened(0.5)

func transition_light_mode(mode: int, duration: float = 1.0) -> void:
	if mode == current_mode:
		return
	
	var target_color = WARM_COLOR if mode == 0 else COOL_COLOR
	var target_albedo = target_color.darkened(0.5)
	var tween = create_tween()
	tween.set_parallel(true)
	
	for strip in strip_meshes:
		var mat = strip.material_override as StandardMaterial3D
		if mat:
			tween.tween_property(mat, "emission", target_color, duration)
			tween.tween_property(mat, "albedo_color", target_albedo, duration)
	
	current_mode = mode

# === UTILITY ===

## Get the exit position and rotation after this turn
func get_exit_transform() -> Transform3D:
	var dir = int(turn_direction)
	var exit_pos = Vector3(dir * TURN_RADIUS, 0, -TURN_RADIUS)
	var exit_rot = -dir * PI / 2  # 90 degrees
	
	var transform = Transform3D()
	transform.origin = global_position + exit_pos
	transform.basis = Basis(Vector3.UP, exit_rot)
	return transform

## Length along the path (for spawn distance calculations)
func get_path_length() -> float:
	return TURN_RADIUS * PI / 2  # Quarter circle arc length
