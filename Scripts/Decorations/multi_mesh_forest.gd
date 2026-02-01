extends Node3D
class_name MultiMeshForest

# Cached meshes and materials
static var tree_mesh: Mesh
static var grass_mesh: Mesh
static var grass_material: ShaderMaterial
static var rock_mesh: Mesh
static var rock_material: StandardMaterial3D
static var bush_mesh: Mesh
static var bush_material: StandardMaterial3D
static var resources_loaded := false

var tree_multimesh: MultiMeshInstance3D
var grass_multimesh: MultiMeshInstance3D
var rock_multimesh: MultiMeshInstance3D
var bush_multimesh: MultiMeshInstance3D

func _init() -> void:
	_load_resources()

static func _load_resources() -> void:
	if resources_loaded:
		return
	
	# Load tree mesh
	var tree_scene = load("res://assets/low_poly_tree/Lowpoly_tree_sample.obj")
	if tree_scene is Mesh:
		tree_mesh = tree_scene
	else:
		tree_mesh = _create_simple_tree_mesh()
	
	# Load grass mesh
	var grass_scene = load("res://assets/stylizedGrassMeshes/grass.glb")
	if grass_scene:
		var instance = grass_scene.instantiate()
		for child in instance.get_children():
			if child is MeshInstance3D:
				grass_mesh = child.mesh
				break
		instance.queue_free()
	
	if not grass_mesh:
		grass_mesh = _create_simple_grass_mesh()
	
	# Load grass shader
	var shader = load("res://assets/stylizedGrassMeshes/grass.gdshader")
	grass_material = ShaderMaterial.new()
	grass_material.shader = shader
	grass_material.set_shader_parameter("color", Color(0.15, 0.45, 0.1))
	grass_material.set_shader_parameter("color2", Color(0.3, 0.65, 0.25))
	grass_material.set_shader_parameter("wind_strength", 0.12)
	grass_material.set_shader_parameter("wind_speed", 2.0)
	
	# Rock mesh and material
	var sphere = SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 0.8
	rock_mesh = sphere
	
	rock_material = StandardMaterial3D.new()
	rock_material.albedo_color = Color(0.4, 0.38, 0.35)
	rock_material.roughness = 0.95
	
	# Bush mesh and material
	var bush_sphere = SphereMesh.new()
	bush_sphere.radius = 0.6
	bush_sphere.height = 1.0
	bush_mesh = bush_sphere
	
	bush_material = StandardMaterial3D.new()
	bush_material.albedo_color = Color(0.18, 0.42, 0.15)
	bush_material.roughness = 0.85
	
	resources_loaded = true

static func _create_simple_tree_mesh() -> Mesh:
	var mesh = CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = 1.2
	mesh.height = 3.5
	return mesh

static func _create_simple_grass_mesh() -> Mesh:
	var mesh = BoxMesh.new()
	mesh.size = Vector3(0.05, 0.6, 0.02)
	return mesh

func setup_forest(chunk_index: int, chunk_length: float, path_width: float, decoration_width: float, trees_count: int, grass_count: int, rocks_count: int, bushes_count: int) -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(chunk_index)
	
	# Trees (both sides)
	_setup_trees(rng, chunk_length, path_width, decoration_width, trees_count * 2)
	
	# Grass (both sides)
	_setup_grass(rng, chunk_length, path_width, decoration_width, grass_count * 2)
	
	# Rocks (both sides)
	_setup_rocks(rng, chunk_length, path_width, decoration_width, rocks_count * 2)
	
	# Bushes (both sides)
	_setup_bushes(rng, chunk_length, path_width, decoration_width, bushes_count * 2)

func _setup_trees(rng: RandomNumberGenerator, chunk_length: float, path_width: float, decoration_width: float, count: int) -> void:
	tree_multimesh = MultiMeshInstance3D.new()
	tree_multimesh.name = "Trees"
	tree_multimesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = tree_mesh
	mm.instance_count = count
	
	for i in range(count):
		var side = -1 if i < count / 2 else 1
		var base_x = side * (path_width / 2 + 2.0)
		var x = base_x + side * rng.randf_range(2.0, decoration_width)
		var z = rng.randf_range(0, -chunk_length)
		
		var scale_val = rng.randf_range(0.7, 1.3)
		var rot_y = rng.randf() * TAU
		
		var transform = Transform3D()
		transform = transform.scaled(Vector3(scale_val, scale_val, scale_val))
		transform = transform.rotated(Vector3.UP, rot_y)
		transform.origin = Vector3(x, 0, z)
		
		mm.set_instance_transform(i, transform)
	
	tree_multimesh.multimesh = mm
	add_child(tree_multimesh)

func _setup_grass(rng: RandomNumberGenerator, chunk_length: float, path_width: float, decoration_width: float, count: int) -> void:
	grass_multimesh = MultiMeshInstance3D.new()
	grass_multimesh.name = "Grass"
	grass_multimesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	grass_multimesh.material_override = grass_material
	
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = grass_mesh
	mm.instance_count = count
	
	for i in range(count):
		var side = -1 if i < count / 2 else 1
		var base_x = side * (path_width / 2 + 1.0)
		var x = base_x + side * rng.randf_range(0.5, decoration_width)
		var z = rng.randf_range(0, -chunk_length)
		
		var scale_val = rng.randf_range(0.5, 1.0)
		var rot_y = rng.randf() * TAU
		
		var transform = Transform3D()
		transform = transform.scaled(Vector3(scale_val, scale_val, scale_val))
		transform = transform.rotated(Vector3.UP, rot_y)
		transform.origin = Vector3(x, 0, z)
		
		mm.set_instance_transform(i, transform)
	
	grass_multimesh.multimesh = mm
	add_child(grass_multimesh)

func _setup_rocks(rng: RandomNumberGenerator, chunk_length: float, path_width: float, decoration_width: float, count: int) -> void:
	rock_multimesh = MultiMeshInstance3D.new()
	rock_multimesh.name = "Rocks"
	rock_multimesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	rock_multimesh.material_override = rock_material
	
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = rock_mesh
	mm.instance_count = count
	
	for i in range(count):
		var side = -1 if i < count / 2 else 1
		var base_x = side * (path_width / 2 + 2.0)
		var x = base_x + side * rng.randf_range(1.0, decoration_width * 0.7)
		var z = rng.randf_range(0, -chunk_length)
		
		var scale_x = rng.randf_range(0.6, 1.4)
		var scale_y = rng.randf_range(0.4, 0.9)
		var scale_z = rng.randf_range(0.6, 1.4)
		var rot_y = rng.randf() * TAU
		
		var transform = Transform3D()
		transform = transform.scaled(Vector3(scale_x, scale_y, scale_z))
		transform = transform.rotated(Vector3.UP, rot_y)
		transform.origin = Vector3(x, scale_y * 0.3, z)
		
		mm.set_instance_transform(i, transform)
	
	rock_multimesh.multimesh = mm
	add_child(rock_multimesh)

func _setup_bushes(rng: RandomNumberGenerator, chunk_length: float, path_width: float, decoration_width: float, count: int) -> void:
	bush_multimesh = MultiMeshInstance3D.new()
	bush_multimesh.name = "Bushes"
	bush_multimesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	bush_multimesh.material_override = bush_material
	
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = bush_mesh
	mm.instance_count = count
	
	for i in range(count):
		var side = -1 if i < count / 2 else 1
		var base_x = side * (path_width / 2 + 1.5)
		var x = base_x + side * rng.randf_range(1.5, decoration_width * 0.8)
		var z = rng.randf_range(0, -chunk_length)
		
		var scale_val = rng.randf_range(0.5, 1.0)
		var rot_y = rng.randf() * TAU
		
		var transform = Transform3D()
		transform = transform.scaled(Vector3(scale_val * 1.2, scale_val, scale_val * 1.2))
		transform = transform.rotated(Vector3.UP, rot_y)
		transform.origin = Vector3(x, scale_val * 0.4, z)
		
		mm.set_instance_transform(i, transform)
	
	bush_multimesh.multimesh = mm
	add_child(bush_multimesh)
