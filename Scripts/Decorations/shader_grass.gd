extends Node3D
class_name ShaderGrass

# Shader-based grass with wind animation

static var grass_shader: Shader
static var shader_ready := false

var blade_count := 8
var spread := 0.4
var blade_height := 0.6

func _ready() -> void:
	_init_shader()
	_build()

static func _init_shader() -> void:
	if shader_ready:
		return
	
	grass_shader = Shader.new()
	grass_shader.code = """
shader_type spatial;
render_mode cull_disabled, shadows_disabled;

uniform vec3 grass_color : source_color = vec3(0.3, 0.55, 0.25);
uniform vec3 grass_tip_color : source_color = vec3(0.5, 0.7, 0.35);
uniform float wind_strength : hint_range(0.0, 1.0) = 0.25;
uniform float wind_speed : hint_range(0.0, 5.0) = 1.5;
uniform float phase_offset : hint_range(0.0, 10.0) = 0.0;

void vertex() {
	float height_factor = UV.y;
	float wind = sin(TIME * wind_speed + VERTEX.x * 3.0 + VERTEX.z * 2.0 + phase_offset) * wind_strength;
	VERTEX.x += wind * height_factor * height_factor;
	VERTEX.z += wind * height_factor * 0.3;
}

void fragment() {
	float gradient = UV.y;
	ALBEDO = mix(grass_color, grass_tip_color, gradient);
	ROUGHNESS = 0.9;
}
"""
	shader_ready = true

func _build() -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(global_position)
	
	for i in range(blade_count):
		var blade = MeshInstance3D.new()
		blade.name = "Blade_%d" % i
		
		var height = blade_height * rng.randf_range(0.7, 1.3)
		var mesh = QuadMesh.new()
		mesh.size = Vector2(0.04, height)
		blade.mesh = mesh
		
		# Position
		blade.position = Vector3(
			rng.randf_range(-spread, spread),
			height / 2,
			rng.randf_range(-spread, spread)
		)
		
		# Face camera-ish with some variation
		blade.rotation.y = rng.randf() * TAU
		blade.rotation.x = rng.randf_range(-0.15, 0.15)
		
		# Shader material
		var mat = ShaderMaterial.new()
		mat.shader = grass_shader
		mat.set_shader_parameter("grass_color", Vector3(0.3, 0.55, 0.25))
		mat.set_shader_parameter("grass_tip_color", Vector3(0.5, 0.7, 0.35))
		mat.set_shader_parameter("phase_offset", rng.randf() * 10.0)
		blade.material_override = mat
		blade.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		
		add_child(blade)

static func create_random(rng: RandomNumberGenerator) -> ShaderGrass:
	var grass = ShaderGrass.new()
	grass.blade_count = rng.randi_range(5, 10)
	grass.blade_height = rng.randf_range(0.4, 0.8)
	return grass
