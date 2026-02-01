@tool
extends Node3D
class_name GrassClump

# === EXPORT PARAMETERS ===
@export_group("Blades")
@export var blade_count: int = 5:
	set(v):
		blade_count = clampi(v, 1, 15)
		if Engine.is_editor_hint(): _rebuild()
@export var blade_height_min: float = 0.3:
	set(v):
		blade_height_min = v
		if Engine.is_editor_hint(): _rebuild()
@export var blade_height_max: float = 0.8:
	set(v):
		blade_height_max = v
		if Engine.is_editor_hint(): _rebuild()
@export var spread_radius: float = 0.25:
	set(v):
		spread_radius = v
		if Engine.is_editor_hint(): _rebuild()

@export_group("Appearance")
@export var grass_color: Color = Color(0.45, 0.75, 0.35):  # Lighter green
	set(v):
		grass_color = v
		if Engine.is_editor_hint(): _rebuild()
@export var color_variation: float = 0.1:
	set(v):
		color_variation = v
		if Engine.is_editor_hint(): _rebuild()
@export var use_wind_shader: bool = false:
	set(v):
		use_wind_shader = v
		if Engine.is_editor_hint(): _rebuild()

@export_group("Randomization")
@export var random_seed: int = 0

var _built := false
static var wind_shader_material: ShaderMaterial

func _ready() -> void:
	if not _built:
		_rebuild()

func _rebuild() -> void:
	for child in get_children():
		child.queue_free()
	
	var rng = RandomNumberGenerator.new()
	rng.seed = random_seed if random_seed != 0 else hash(global_position)
	
	_create_blades(rng)
	_built = true

func _create_blades(rng: RandomNumberGenerator) -> void:
	for i in range(blade_count):
		var blade = MeshInstance3D.new()
		blade.name = "Blade_%d" % i
		
		var height = rng.randf_range(blade_height_min, blade_height_max)
		var mesh = BoxMesh.new()
		mesh.size = Vector3(0.02, height, 0.008)  # Thinner blades
		blade.mesh = mesh
		
		# Position within spread radius
		blade.position = Vector3(
			rng.randf_range(-spread_radius, spread_radius),
			height / 2,
			rng.randf_range(-spread_radius, spread_radius)
		)
		
		# Slight tilt for natural look
		blade.rotation.x = rng.randf_range(-0.2, 0.2)
		blade.rotation.z = rng.randf_range(-0.3, 0.3)
		
		# Material
		if use_wind_shader:
			blade.material_override = _get_wind_shader_material(rng)
		else:
			var mat = StandardMaterial3D.new()
			mat.albedo_color = _get_varied_color(rng)
			mat.roughness = 0.9
			mat.cull_mode = BaseMaterial3D.CULL_DISABLED  # Double-sided
			blade.material_override = mat
		
		add_child(blade)

func _get_varied_color(rng: RandomNumberGenerator) -> Color:
	return Color(
		clampf(grass_color.r + rng.randf_range(-color_variation, color_variation), 0, 1),
		clampf(grass_color.g + rng.randf_range(-color_variation, color_variation), 0, 1),
		clampf(grass_color.b + rng.randf_range(-color_variation, color_variation), 0, 1)
	)

func _get_wind_shader_material(rng: RandomNumberGenerator) -> ShaderMaterial:
	# Create unique instance for this blade with varied phase
	var mat = ShaderMaterial.new()
	mat.shader = _get_or_create_wind_shader()
	mat.set_shader_parameter("grass_color", _get_varied_color(rng))
	mat.set_shader_parameter("wind_phase_offset", rng.randf() * TAU)
	return mat

static func _get_or_create_wind_shader() -> Shader:
	# This returns a simple wind sway shader
	var shader = Shader.new()
	shader.code = """
shader_type spatial;
render_mode cull_disabled;

uniform vec3 grass_color : source_color = vec3(0.45, 0.75, 0.35);
uniform float wind_strength : hint_range(0.0, 1.0) = 0.3;
uniform float wind_speed : hint_range(0.0, 5.0) = 2.0;
uniform float wind_phase_offset : hint_range(0.0, 6.28) = 0.0;

void vertex() {
	// Sway more at the top of the blade
	float sway_factor = UV.y;
	float wind = sin(TIME * wind_speed + wind_phase_offset + VERTEX.x * 2.0) * wind_strength;
	VERTEX.x += wind * sway_factor;
	VERTEX.z += wind * sway_factor * 0.5;
}

void fragment() {
	ALBEDO = grass_color;
	ROUGHNESS = 0.9;
}
"""
	return shader

# Factory method
static func create_random(rng: RandomNumberGenerator) -> GrassClump:
	var grass = GrassClump.new()
	grass.blade_count = rng.randi_range(3, 7)
	grass.blade_height_max = rng.randf_range(0.5, 1.0)
	grass.random_seed = rng.randi()
	return grass
