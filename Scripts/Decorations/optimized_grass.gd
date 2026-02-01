extends Node3D
class_name OptimizedGrass

static var grass_mesh: Mesh
static var grass_material: ShaderMaterial
static var mesh_loaded := false

func _ready() -> void:
	_load_mesh()
	_create_instance()

static func _load_mesh() -> void:
	if mesh_loaded:
		return
	
	# Load the grass mesh
	var grass_scene = load("res://assets/stylizedGrassMeshes/grass.glb")
	if grass_scene:
		var instance = grass_scene.instantiate()
		for child in instance.get_children():
			if child is MeshInstance3D:
				grass_mesh = child.mesh
				break
		instance.queue_free()
	
	if not grass_mesh:
		# Fallback
		var box = BoxMesh.new()
		box.size = Vector3(0.04, 0.5, 0.015)
		grass_mesh = box
	
	# Load the grass shader
	var shader = load("res://assets/stylizedGrassMeshes/grass.gdshader")
	grass_material = ShaderMaterial.new()
	grass_material.shader = shader
	grass_material.set_shader_parameter("color", Color(0.15, 0.45, 0.1))
	grass_material.set_shader_parameter("color2", Color(0.25, 0.6, 0.2))
	grass_material.set_shader_parameter("wind_strength", 0.1)
	grass_material.set_shader_parameter("wind_speed", 2.5)
	
	mesh_loaded = true

func _create_instance() -> void:
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = grass_mesh
	mesh_instance.material_override = grass_material
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mesh_instance)

static func create_random(rng: RandomNumberGenerator) -> OptimizedGrass:
	var grass = OptimizedGrass.new()
	var scale_val = rng.randf_range(0.6, 1.2)
	grass.scale = Vector3(scale_val, scale_val, scale_val)
	grass.rotation.y = rng.randf() * TAU
	return grass
