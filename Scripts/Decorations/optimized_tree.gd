extends Node3D
class_name OptimizedTree

static var tree_mesh: Mesh
static var tree_material: StandardMaterial3D
static var mesh_loaded := false

func _ready() -> void:
	_load_mesh()
	_create_instance()

static func _load_mesh() -> void:
	if mesh_loaded:
		return
	
	# Load the low poly tree mesh
	var scene = load("res://assets/low_poly_tree/Lowpoly_tree_sample.obj") as Mesh
	if scene:
		tree_mesh = scene
	else:
		# Fallback to generated mesh
		tree_mesh = _create_fallback_mesh()
	
	tree_material = StandardMaterial3D.new()
	tree_material.vertex_color_use_as_albedo = true
	tree_material.roughness = 0.9
	tree_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	mesh_loaded = true

static func _create_fallback_mesh() -> Mesh:
	# Simple cone + cylinder fallback
	var mesh = CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = 1.5
	mesh.height = 4.0
	return mesh

func _create_instance() -> void:
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = tree_mesh
	if tree_material:
		mesh_instance.material_override = tree_material
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mesh_instance)

static func create_random(rng: RandomNumberGenerator) -> OptimizedTree:
	var tree = OptimizedTree.new()
	var scale_val = rng.randf_range(0.8, 1.5)
	tree.scale = Vector3(scale_val, scale_val, scale_val)
	return tree
