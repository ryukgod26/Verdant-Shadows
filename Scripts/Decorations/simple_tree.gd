extends Node3D
class_name SimpleTree

# Simple tree with round canopy - no pine/cone shapes

static var trunk_material: StandardMaterial3D
static var canopy_material: StandardMaterial3D
static var materials_ready := false

var trunk_height := 3.5
var trunk_radius := 0.25
var canopy_radius := 1.5

func _ready() -> void:
	_init_materials()
	_build()

static func _init_materials() -> void:
	if materials_ready:
		return
	
	trunk_material = StandardMaterial3D.new()
	trunk_material.albedo_color = Color(0.4, 0.28, 0.15)
	trunk_material.roughness = 1.0
	
	canopy_material = StandardMaterial3D.new()
	canopy_material.albedo_color = Color(0.2, 0.5, 0.2)
	canopy_material.roughness = 1.0
	canopy_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	materials_ready = true

func _build() -> void:
	# Trunk - simple cylinder
	var trunk = MeshInstance3D.new()
	trunk.name = "Trunk"
	var trunk_mesh = CylinderMesh.new()
	trunk_mesh.top_radius = trunk_radius * 0.8
	trunk_mesh.bottom_radius = trunk_radius
	trunk_mesh.height = trunk_height
	trunk.mesh = trunk_mesh
	trunk.position.y = trunk_height / 2
	trunk.material_override = trunk_material
	trunk.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(trunk)
	
	# Canopy - single sphere
	var canopy = MeshInstance3D.new()
	canopy.name = "Canopy"
	var canopy_mesh = SphereMesh.new()
	canopy_mesh.radius = canopy_radius
	canopy_mesh.height = canopy_radius * 1.6
	canopy.mesh = canopy_mesh
	canopy.position.y = trunk_height + canopy_radius * 0.5
	canopy.material_override = canopy_material
	canopy.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(canopy)

static func create_random(rng: RandomNumberGenerator) -> SimpleTree:
	var tree = SimpleTree.new()
	tree.trunk_height = rng.randf_range(2.5, 5.0)
	tree.trunk_radius = rng.randf_range(0.2, 0.35)
	tree.canopy_radius = rng.randf_range(1.2, 2.2)
	return tree
