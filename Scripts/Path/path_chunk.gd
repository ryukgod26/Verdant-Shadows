extends Node3D
class_name PathChunk

# Chunk configuration
const CHUNK_LENGTH := 20.0  # How long each path segment is (Z direction)
const PATH_WIDTH := 6.0     # Width of runnable path (3 lanes)
const DECORATION_WIDTH := 15.0  # How far out decorations spawn

# References set by PathManager
var chunk_index := 0

func _ready() -> void:
	_generate_decorations()

func _generate_decorations() -> void:
	# Spawn trees and foliage on both sides of the path
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(chunk_index)  # Deterministic based on position
	
	# Left side decorations
	_spawn_side_decorations(rng, -1)
	# Right side decorations  
	_spawn_side_decorations(rng, 1)

func _spawn_side_decorations(rng: RandomNumberGenerator, side: int) -> void:
	var base_x = side * (PATH_WIDTH / 2 + 2.0)  # Start just outside path
	
	# Trees (5-8 per side per chunk)
	var tree_count = rng.randi_range(5, 8)
	for i in tree_count:
		var tree = _create_tree(rng)
		var x = base_x + side * rng.randf_range(1.0, DECORATION_WIDTH)
		var z = rng.randf_range(0, CHUNK_LENGTH)
		tree.position = Vector3(x, 0, -z)
		tree.rotation.y = rng.randf_range(0, TAU)
		add_child(tree)
	
	# Grass clumps (10-15 per side)
	var grass_count = rng.randi_range(10, 15)
	for i in grass_count:
		var grass = _create_grass(rng)
		var x = base_x + side * rng.randf_range(0.5, DECORATION_WIDTH)
		var z = rng.randf_range(0, CHUNK_LENGTH)
		grass.position = Vector3(x, 0, -z)
		add_child(grass)
	
	# Rocks (2-4 per side)
	var rock_count = rng.randi_range(2, 4)
	for i in rock_count:
		var rock = _create_rock(rng)
		var x = base_x + side * rng.randf_range(1.0, DECORATION_WIDTH * 0.7)
		var z = rng.randf_range(0, CHUNK_LENGTH)
		rock.position = Vector3(x, 0, -z)
		rock.rotation.y = rng.randf_range(0, TAU)
		add_child(rock)

func _create_tree(rng: RandomNumberGenerator) -> Node3D:
	var tree = Node3D.new()
	
	# Trunk
	var trunk_mesh = MeshInstance3D.new()
	var trunk_cylinder = CylinderMesh.new()
	var trunk_height = rng.randf_range(3.0, 6.0)
	var trunk_radius = rng.randf_range(0.2, 0.4)
	trunk_cylinder.top_radius = trunk_radius * 0.7
	trunk_cylinder.bottom_radius = trunk_radius
	trunk_cylinder.height = trunk_height
	trunk_mesh.mesh = trunk_cylinder
	trunk_mesh.position.y = trunk_height / 2
	
	# Trunk material (brown)
	var trunk_mat = StandardMaterial3D.new()
	trunk_mat.albedo_color = Color(0.35, 0.2, 0.1)
	trunk_mat.roughness = 0.9
	trunk_mesh.material_override = trunk_mat
	tree.add_child(trunk_mesh)
	
	# Foliage (layered cones for jungle look)
	var foliage_layers = rng.randi_range(2, 4)
	for i in foliage_layers:
		var foliage_mesh = MeshInstance3D.new()
		var foliage_cone = CylinderMesh.new()
		var layer_height = rng.randf_range(1.5, 2.5)
		var layer_radius = rng.randf_range(1.0, 2.0) * (1.0 - i * 0.2)
		foliage_cone.top_radius = 0.1
		foliage_cone.bottom_radius = layer_radius
		foliage_cone.height = layer_height
		foliage_mesh.mesh = foliage_cone
		foliage_mesh.position.y = trunk_height + i * layer_height * 0.6
		
		# Foliage material (green variations)
		var foliage_mat = StandardMaterial3D.new()
		foliage_mat.albedo_color = Color(
			rng.randf_range(0.1, 0.25),
			rng.randf_range(0.4, 0.6),
			rng.randf_range(0.1, 0.2)
		)
		foliage_mat.roughness = 0.8
		foliage_mesh.material_override = foliage_mat
		tree.add_child(foliage_mesh)
	
	return tree

func _create_grass(rng: RandomNumberGenerator) -> Node3D:
	var grass = Node3D.new()
	
	# Cluster of grass blades
	var blade_count = rng.randi_range(3, 7)
	for i in blade_count:
		var blade = MeshInstance3D.new()
		var blade_mesh = BoxMesh.new()
		blade_mesh.size = Vector3(0.05, rng.randf_range(0.3, 0.8), 0.02)
		blade.mesh = blade_mesh
		blade.position = Vector3(
			rng.randf_range(-0.2, 0.2),
			blade_mesh.size.y / 2,
			rng.randf_range(-0.2, 0.2)
		)
		blade.rotation.x = rng.randf_range(-0.2, 0.2)
		blade.rotation.z = rng.randf_range(-0.3, 0.3)
		
		var grass_mat = StandardMaterial3D.new()
		grass_mat.albedo_color = Color(
			rng.randf_range(0.2, 0.35),
			rng.randf_range(0.5, 0.7),
			rng.randf_range(0.1, 0.2)
		)
		grass_mat.roughness = 0.9
		blade.material_override = grass_mat
		grass.add_child(blade)
	
	return grass

func _create_rock(rng: RandomNumberGenerator) -> Node3D:
	var rock = MeshInstance3D.new()
	
	# Use a sphere squashed to look rocky
	var rock_mesh = SphereMesh.new()
	var rock_size = rng.randf_range(0.3, 1.0)
	rock_mesh.radius = rock_size
	rock_mesh.height = rock_size * rng.randf_range(0.6, 1.2)
	rock.mesh = rock_mesh
	rock.position.y = rock_mesh.height * 0.3
	
	# Squash and rotate for variety
	rock.scale = Vector3(
		rng.randf_range(0.7, 1.3),
		rng.randf_range(0.5, 1.0),
		rng.randf_range(0.7, 1.3)
	)
	
	var rock_mat = StandardMaterial3D.new()
	rock_mat.albedo_color = Color(
		rng.randf_range(0.3, 0.45),
		rng.randf_range(0.3, 0.4),
		rng.randf_range(0.25, 0.35)
	)
	rock_mat.roughness = 0.95
	rock.material_override = rock_mat
	
	return rock

# Get the end position of this chunk (for spawning next chunk)
func get_end_position() -> Vector3:
	return global_position + Vector3(0, 0, -CHUNK_LENGTH)
