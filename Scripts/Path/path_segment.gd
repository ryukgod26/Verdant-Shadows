extends Node3D
class_name PathSegment

# === CONFIGURATION ===
const SEGMENT_LENGTH := 20.0
const PATH_WIDTH := 6.0
const EDGE_HEIGHT := 0.3

# === LIGHTING MODES ===
enum LightMode { WARM, COOL, BOOST }
var current_mode := LightMode.WARM

# Light strip colors
const WARM_COLOR := Color(1.0, 0.7, 0.4)      # Dawn/evening - orange glow
const COOL_COLOR := Color(0.4, 0.6, 1.0)      # Midnight - blue glow
const BOOST_COLOR := Color(0.2, 0.7, 1.0)     # Speed boost - bright cyan
const EMISSION_ENERGY := 2.0                   # Glow intensity
const BOOST_EMISSION := 5.0                    # Intense boost glow

# Strip dimensions
const STRIP_WIDTH := 0.15
const STRIP_HEIGHT := 0.08

# References
var left_strip: MeshInstance3D
var right_strip: MeshInstance3D
var left_strip_material: StandardMaterial3D
var right_strip_material: StandardMaterial3D



# Materials (shared for geometry)
static var path_material: StandardMaterial3D
static var edge_material: StandardMaterial3D
static var ground_material: ShaderMaterial
static var materials_initialized := false

func _ready() -> void:
	_init_materials()
	_create_path_geometry()
	_create_light_strips()
	set_light_mode(current_mode)

static func _init_materials() -> void:
	if materials_initialized:
		return
	
	# Main path - solid stone color
	path_material = StandardMaterial3D.new()
	path_material.albedo_color = Color(0.35, 0.32, 0.28)
	path_material.roughness = 0.9
	path_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED if false else BaseMaterial3D.SHADING_MODE_PER_PIXEL
	
	# Edge - darker stone
	edge_material = StandardMaterial3D.new()
	edge_material.albedo_color = Color(0.25, 0.22, 0.18)
	edge_material.roughness = 0.85
	
	# Ground - forest floor shader with dirt, moss, leaves
	var floor_shader = load("res://Shaders/forest_floor.gdshader")
	ground_material = ShaderMaterial.new()
	ground_material.shader = floor_shader
	ground_material.set_shader_parameter("dirt_color", Color(0.18, 0.12, 0.08))
	ground_material.set_shader_parameter("dark_dirt", Color(0.1, 0.07, 0.04))
	ground_material.set_shader_parameter("moss_color", Color(0.12, 0.22, 0.08))
	ground_material.set_shader_parameter("leaf_color", Color(0.25, 0.15, 0.08))
	ground_material.set_shader_parameter("noise_scale", 12.0)
	ground_material.set_shader_parameter("moss_amount", 0.3)
	ground_material.set_shader_parameter("leaf_amount", 0.2)
	
	materials_initialized = true

func _create_path_geometry() -> void:
	# Main runnable path
	var path_mesh = MeshInstance3D.new()
	path_mesh.name = "PathMesh"
	var path_box = BoxMesh.new()
	path_box.size = Vector3(PATH_WIDTH, 0.5, SEGMENT_LENGTH)
	path_mesh.mesh = path_box
	path_mesh.position = Vector3(0, -0.25, -SEGMENT_LENGTH / 2)
	path_mesh.material_override = path_material
	add_child(path_mesh)
	
	# Path collision
	var path_body = StaticBody3D.new()
	path_body.name = "PathCollision"
	var path_collision = CollisionShape3D.new()
	var path_shape = BoxShape3D.new()
	path_shape.size = Vector3(PATH_WIDTH, 0.5, SEGMENT_LENGTH)
	path_collision.shape = path_shape
	path_collision.position = Vector3(0, -0.25, -SEGMENT_LENGTH / 2)
	path_body.add_child(path_collision)
	add_child(path_body)
	
	# Left edge
	var left_edge = MeshInstance3D.new()
	left_edge.name = "LeftEdge"
	var edge_mesh = BoxMesh.new()
	edge_mesh.size = Vector3(0.4, EDGE_HEIGHT + 0.1, SEGMENT_LENGTH)
	left_edge.mesh = edge_mesh
	left_edge.position = Vector3(-PATH_WIDTH / 2 - 0.2, EDGE_HEIGHT / 2, -SEGMENT_LENGTH / 2)
	left_edge.material_override = edge_material
	add_child(left_edge)
	
	# Right edge
	var right_edge = MeshInstance3D.new()
	right_edge.name = "RightEdge"
	right_edge.mesh = edge_mesh
	right_edge.position = Vector3(PATH_WIDTH / 2 + 0.2, EDGE_HEIGHT / 2, -SEGMENT_LENGTH / 2)
	right_edge.material_override = edge_material
	add_child(right_edge)
	
	# Ground planes
	_create_ground_plane(-1)
	_create_ground_plane(1)

func _create_ground_plane(side: int) -> void:
	var ground = MeshInstance3D.new()
	ground.name = "Ground_" + ("Left" if side == -1 else "Right")
	var ground_mesh = BoxMesh.new()
	ground_mesh.size = Vector3(50.0, 0.1, SEGMENT_LENGTH)
	ground.mesh = ground_mesh
	ground.position = Vector3(
		side * (PATH_WIDTH / 2 + 25.0),
		-0.55,  # Lower to avoid z-fighting
		-SEGMENT_LENGTH / 2
	)
	ground.material_override = ground_material
	add_child(ground)

func _create_light_strips() -> void:
	# Left LED strip
	left_strip = _create_strip_mesh()
	left_strip.name = "LeftLightStrip"
	left_strip.position = Vector3(
		-PATH_WIDTH / 2 - 0.05,  # Just inside the edge
		STRIP_HEIGHT / 2 + 0.02,  # Slightly above ground
		-SEGMENT_LENGTH / 2
	)
	left_strip_material = _create_emissive_material()
	left_strip.material_override = left_strip_material
	add_child(left_strip)
	
	# Right LED strip
	right_strip = _create_strip_mesh()
	right_strip.name = "RightLightStrip"
	right_strip.position = Vector3(
		PATH_WIDTH / 2 + 0.05,
		STRIP_HEIGHT / 2 + 0.02,
		-SEGMENT_LENGTH / 2
	)
	right_strip_material = _create_emissive_material()
	right_strip.material_override = right_strip_material
	add_child(right_strip)

func _create_strip_mesh() -> MeshInstance3D:
	var strip = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = Vector3(STRIP_WIDTH, STRIP_HEIGHT, SEGMENT_LENGTH)
	strip.mesh = mesh
	return strip

func _create_emissive_material() -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.emission_enabled = true
	mat.emission = WARM_COLOR
	mat.emission_energy_multiplier = EMISSION_ENERGY
	mat.albedo_color = WARM_COLOR.darkened(0.5)
	mat.roughness = 0.3
	mat.metallic = 0.2
	return mat

func set_light_mode(mode: LightMode) -> void:
	current_mode = mode
	var color: Color
	var energy: float = EMISSION_ENERGY
	
	match mode:
		LightMode.WARM:
			color = WARM_COLOR
		LightMode.COOL:
			color = COOL_COLOR
		LightMode.BOOST:
			color = BOOST_COLOR
			energy = BOOST_EMISSION
	
	# Update strip emissions
	if left_strip_material:
		left_strip_material.emission = color
		left_strip_material.albedo_color = color.darkened(0.5)
		left_strip_material.emission_energy_multiplier = energy
	if right_strip_material:
		right_strip_material.emission = color
		right_strip_material.albedo_color = color.darkened(0.5)
		right_strip_material.emission_energy_multiplier = energy

func set_emission_energy(energy: float) -> void:
	if left_strip_material:
		left_strip_material.emission_energy_multiplier = energy
	if right_strip_material:
		right_strip_material.emission_energy_multiplier = energy

# Smooth transition between modes
func transition_to_mode(mode: LightMode, duration: float = 1.0) -> void:
	if mode == current_mode:
		return
	
	var target_color: Color
	var target_energy: float = EMISSION_ENERGY
	
	match mode:
		LightMode.WARM:
			target_color = WARM_COLOR
		LightMode.COOL:
			target_color = COOL_COLOR
		LightMode.BOOST:
			target_color = BOOST_COLOR
			target_energy = BOOST_EMISSION
	
	var target_albedo = target_color.darkened(0.5)
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Transition strip materials
	if left_strip_material:
		tween.tween_property(left_strip_material, "emission", target_color, duration)
		tween.tween_property(left_strip_material, "albedo_color", target_albedo, duration)
		tween.tween_property(left_strip_material, "emission_energy_multiplier", target_energy, duration)
	if right_strip_material:
		tween.tween_property(right_strip_material, "emission", target_color, duration)
		tween.tween_property(right_strip_material, "albedo_color", target_albedo, duration)
		tween.tween_property(right_strip_material, "emission_energy_multiplier", target_energy, duration)
	
	current_mode = mode
