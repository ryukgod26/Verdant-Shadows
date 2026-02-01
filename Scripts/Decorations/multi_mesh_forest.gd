extends Node3D
class_name MultiMeshForest

# Cached meshes and materials
static var tree_mesh: Mesh
static var grass_mesh: Mesh
static var grass_material: ShaderMaterial
static var rock_mesh: Mesh
static var rock_material: ShaderMaterial
static var bush_mesh: ArrayMesh
static var bush_material: ShaderMaterial
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
	grass_material.set_shader_parameter("color", Color(0.2, 0.55, 0.15))   # Brighter base
	grass_material.set_shader_parameter("color2", Color(0.4, 0.75, 0.3))  # Brighter tips
	grass_material.set_shader_parameter("wind_strength", 0.08)
	grass_material.set_shader_parameter("wind_speed", 2.0)
	
	# Rock mesh - irregular boulder shape
	rock_mesh = _create_rock_mesh()
	
	# Rock shader with color variation and subtle moss
	var rock_shader = load("res://Shaders/rock.gdshader")
	rock_material = ShaderMaterial.new()
	rock_material.shader = rock_shader
	rock_material.set_shader_parameter("base_color", Color(0.35, 0.33, 0.3))
	rock_material.set_shader_parameter("dark_color", Color(0.2, 0.18, 0.16))
	rock_material.set_shader_parameter("highlight_color", Color(0.5, 0.48, 0.44))
	rock_material.set_shader_parameter("noise_scale", 8.0)
	rock_material.set_shader_parameter("color_variation", 0.4)
	
	# Bush mesh - clustered spheres for organic look
	bush_mesh = _create_bush_mesh()
	
	# Bush shader with wind sway and color variation
	var bush_shader = load("res://Shaders/bush.gdshader")
	bush_material = ShaderMaterial.new()
	bush_material.shader = bush_shader
	bush_material.set_shader_parameter("base_color", Color(0.12, 0.35, 0.08))
	bush_material.set_shader_parameter("tip_color", Color(0.2, 0.5, 0.15))
	bush_material.set_shader_parameter("wind_strength", 0.1)
	bush_material.set_shader_parameter("wind_speed", 1.5)
	bush_material.set_shader_parameter("color_variation", 0.3)
	
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

static func _create_rock_mesh() -> ArrayMesh:
	# Create irregular rock by combining deformed sphere data
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Main rock body - flattened and stretched
	var main_sphere = SphereMesh.new()
	main_sphere.radius = 0.4
	main_sphere.height = 0.5
	main_sphere.radial_segments = 8
	main_sphere.rings = 4
	
	var arrays = main_sphere.get_mesh_arrays()
	var verts = arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
	var normals = arrays[Mesh.ARRAY_NORMAL] as PackedVector3Array
	var indices = arrays[Mesh.ARRAY_INDEX] as PackedInt32Array
	
	# Deform vertices for irregular look
	var rng = RandomNumberGenerator.new()
	rng.seed = 12345
	for i in range(verts.size()):
		var v = verts[i]
		var noise = rng.randf_range(-0.08, 0.08)
		v.x *= 1.0 + rng.randf_range(-0.2, 0.3)
		v.z *= 1.0 + rng.randf_range(-0.2, 0.3)
		v.y = v.y * 0.7 + noise
		verts[i] = v
	
	for i in range(verts.size()):
		st.set_normal(normals[i])
		st.add_vertex(verts[i])
	
	for idx in indices:
		st.add_index(idx)
	
	st.generate_normals()
	return st.commit()

static func _create_bush_mesh() -> ArrayMesh:
	# Create organic bush - multiple overlapping spheres
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var sphere = SphereMesh.new()
	sphere.radius = 0.3
	sphere.height = 0.5
	sphere.radial_segments = 6
	sphere.rings = 3
	
	var base_arrays = sphere.get_mesh_arrays()
	var base_verts = base_arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
	var base_normals = base_arrays[Mesh.ARRAY_NORMAL] as PackedVector3Array
	var base_indices = base_arrays[Mesh.ARRAY_INDEX] as PackedInt32Array
	
	# Create 5 overlapping spheres for bush shape
	var offsets = [
		Vector3(0.0, 0.15, 0.0),
		Vector3(0.15, 0.0, 0.1),
		Vector3(-0.15, 0.05, 0.1),
		Vector3(0.1, 0.0, -0.15),
		Vector3(-0.1, 0.1, -0.1)
	]
	var scales = [1.0, 0.8, 0.85, 0.75, 0.7]
	
	var vertex_offset = 0
	for s in range(offsets.size()):
		for i in range(base_verts.size()):
			var v = base_verts[i] * scales[s] + offsets[s]
			st.set_normal(base_normals[i])
			st.add_vertex(v)
		
		for idx in base_indices:
			st.add_index(idx + vertex_offset)
		
		vertex_offset += base_verts.size()
	
	st.generate_normals()
	return st.commit()

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
	
	var base_scale = 0.25
	
	# Better spacing - divide chunk into zones
	var zone_length = chunk_length / (count / 2.0)
	
	for i in range(count):
		var side = -1 if i < count / 2 else 1
		var local_i = i if i < count / 2 else i - count / 2
		
		# Space trees along the chunk with slight randomness
		var z = -local_i * zone_length - rng.randf_range(0.5, zone_length - 0.5)
		z = clampf(z, -chunk_length + 1.0, -1.0)
		
		# Trees further from path, layered depth
		var min_dist = 4.0
		var max_dist = decoration_width - 2.0
		var base_x = side * (path_width / 2 + min_dist)
		var x = base_x + side * rng.randf_range(0.0, max_dist - min_dist)
		
		var scale_val = base_scale * rng.randf_range(0.8, 1.2)
		var rot_y = rng.randf() * TAU
		
		var transform = Transform3D()
		transform = transform.scaled(Vector3(scale_val, scale_val, scale_val))
		transform = transform.rotated(Vector3.UP, rot_y)
		transform.origin = Vector3(x, 0, z)
		
		mm.set_instance_transform(i, transform)
	
	tree_multimesh.multimesh = mm
	add_child(tree_multimesh)

func _setup_grass(rng: RandomNumberGenerator, chunk_length: float, path_width: float, decoration_width: float, patch_count: int) -> void:
	# patch_count is number of grass patches, each patch has 500-1200 blades
	grass_multimesh = MultiMeshInstance3D.new()
	grass_multimesh.name = "Grass"
	grass_multimesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	grass_multimesh.material_override = grass_material
	
	# Calculate total grass blades from patches
	var patch_positions: Array[Vector3] = []
	var patch_sizes: Array[int] = []
	var total_blades := 0
	
	for p in range(patch_count):
		var side = -1 if p < patch_count / 2 else 1
		var base_x = side * (path_width / 2 + 1.0)
		var patch_x = base_x + side * rng.randf_range(0.5, decoration_width - 2.0)
		var patch_z = rng.randf_range(-1.0, -chunk_length + 1.0)
		patch_positions.append(Vector3(patch_x, 0, patch_z))
		
		var blades_in_patch = rng.randi_range(500, 1200)
		patch_sizes.append(blades_in_patch)
		total_blades += blades_in_patch
	
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = grass_mesh
	mm.instance_count = total_blades
	
	var blade_idx := 0
	for p in range(patch_count):
		var patch_center = patch_positions[p]
		var patch_radius = rng.randf_range(1.5, 3.0)  # Patch spread radius
		
		for _b in range(patch_sizes[p]):
			# Distribute in circular patch with gaussian-like density (more in center)
			var angle = rng.randf() * TAU
			var dist = rng.randf() * rng.randf() * patch_radius  # Squared for center density
			var x = patch_center.x + cos(angle) * dist
			var z = patch_center.z + sin(angle) * dist
			
			var scale_val = rng.randf_range(0.6, 1.2)
			var rot_y = rng.randf() * TAU
			
			var transform = Transform3D()
			transform = transform.scaled(Vector3(scale_val, scale_val, scale_val))
			transform = transform.rotated(Vector3.UP, rot_y)
			transform.origin = Vector3(x, 0, z)
			
			mm.set_instance_transform(blade_idx, transform)
			blade_idx += 1
	
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
	
	var zone_length = chunk_length / (count / 2.0 + 1.0)
	
	for i in range(count):
		var side = -1 if i < count / 2 else 1
		var local_i = i if i < count / 2 else i - count / 2
		
		# Spread rocks evenly with randomness
		var z = -local_i * zone_length - rng.randf_range(1.0, zone_length)
		z = clampf(z, -chunk_length + 1.0, -1.0)
		
		# Rocks closer to path edge, some scattered further
		var base_x = side * (path_width / 2 + 1.5)
		var x = base_x + side * rng.randf_range(0.5, decoration_width * 0.5)
		
		var base_size = rng.randf_range(1.5, 3.5)
		var scale_x = base_size * rng.randf_range(0.8, 1.4)
		var scale_y = base_size * rng.randf_range(0.5, 0.9)
		var scale_z = base_size * rng.randf_range(0.8, 1.4)
		var rot_y = rng.randf() * TAU
		var rot_x = rng.randf_range(-0.15, 0.15)
		var rot_z = rng.randf_range(-0.15, 0.15)
		
		var transform = Transform3D()
		transform = transform.scaled(Vector3(scale_x, scale_y, scale_z))
		transform = transform.rotated(Vector3.UP, rot_y)
		transform = transform.rotated(Vector3.RIGHT, rot_x)
		transform = transform.rotated(Vector3.FORWARD, rot_z)
		transform.origin = Vector3(x, scale_y * 0.15, z)
		
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
	
	var zone_length = chunk_length / (count / 2.0 + 1.0)
	
	for i in range(count):
		var side = -1 if i < count / 2 else 1
		var local_i = i if i < count / 2 else i - count / 2
		
		# Spread bushes with staggered positioning
		var z = -local_i * zone_length - rng.randf_range(0.5, zone_length)
		z = clampf(z, -chunk_length + 1.0, -1.0)
		
		# Bushes near path edge for natural border feel
		var base_x = side * (path_width / 2 + 1.0)
		var x = base_x + side * rng.randf_range(0.3, decoration_width * 0.6)
		
		var base_size = rng.randf_range(1.5, 3.0)
		var scale_x = base_size * rng.randf_range(0.9, 1.3)
		var scale_y = base_size * rng.randf_range(0.7, 1.0)
		var scale_z = base_size * rng.randf_range(0.9, 1.3)
		var rot_y = rng.randf() * TAU
		
		var transform = Transform3D()
		transform = transform.scaled(Vector3(scale_x, scale_y, scale_z))
		transform = transform.rotated(Vector3.UP, rot_y)
		transform.origin = Vector3(x, scale_y * 0.1, z)
		
		mm.set_instance_transform(i, transform)
	
	bush_multimesh.multimesh = mm
	add_child(bush_multimesh)
