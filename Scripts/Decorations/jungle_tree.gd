@tool
extends Node3D
class_name JungleTree

# === EXPORT PARAMETERS ===
@export_group("Trunk")
@export var trunk_height: float = 4.5:
	set(v):
		trunk_height = v
		if Engine.is_editor_hint(): _rebuild()
@export var trunk_radius: float = 0.3:
	set(v):
		trunk_radius = v
		if Engine.is_editor_hint(): _rebuild()
@export var trunk_color: Color = Color(0.35, 0.2, 0.1):
	set(v):
		trunk_color = v
		if Engine.is_editor_hint(): _rebuild()

@export_group("Foliage")
@export var foliage_layers: int = 3:
	set(v):
		foliage_layers = clampi(v, 1, 5)
		if Engine.is_editor_hint(): _rebuild()
@export var foliage_radius: float = 1.5:
	set(v):
		foliage_radius = v
		if Engine.is_editor_hint(): _rebuild()
@export var foliage_color: Color = Color(0.15, 0.5, 0.15):
	set(v):
		foliage_color = v
		if Engine.is_editor_hint(): _rebuild()
@export var foliage_color_variation: float = 0.1:
	set(v):
		foliage_color_variation = v
		if Engine.is_editor_hint(): _rebuild()

@export_group("Randomization")
@export var use_random_seed: bool = true
@export var random_seed: int = 0

var _built := false

func _ready() -> void:
	if not _built:
		_rebuild()

func _rebuild() -> void:
	# Clear existing children
	for child in get_children():
		child.queue_free()
	
	var rng = RandomNumberGenerator.new()
	if use_random_seed:
		rng.seed = random_seed if random_seed != 0 else hash(global_position)
	
	_create_trunk(rng)
	_create_foliage(rng)
	_built = true

func _create_trunk(rng: RandomNumberGenerator) -> void:
	var trunk = MeshInstance3D.new()
	trunk.name = "Trunk"
	
	var mesh = CylinderMesh.new()
	mesh.top_radius = trunk_radius * 0.7
	mesh.bottom_radius = trunk_radius
	mesh.height = trunk_height
	trunk.mesh = mesh
	trunk.position.y = trunk_height / 2
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = trunk_color
	mat.roughness = 0.9
	trunk.material_override = mat
	
	add_child(trunk)

func _create_foliage(rng: RandomNumberGenerator) -> void:
	for i in range(foliage_layers):
		var foliage = MeshInstance3D.new()
		foliage.name = "Foliage_%d" % i
		
		var mesh = CylinderMesh.new()
		var layer_scale = 1.0 - (i * 0.2)
		var layer_height = rng.randf_range(1.5, 2.5)
		mesh.top_radius = 0.1
		mesh.bottom_radius = foliage_radius * layer_scale
		mesh.height = layer_height
		foliage.mesh = mesh
		
		foliage.position.y = trunk_height + (i * layer_height * 0.6)
		
		# Color with variation
		var mat = StandardMaterial3D.new()
		var color_offset = Vector3(
			rng.randf_range(-foliage_color_variation, foliage_color_variation),
			rng.randf_range(-foliage_color_variation, foliage_color_variation),
			rng.randf_range(-foliage_color_variation, foliage_color_variation)
		)
		mat.albedo_color = Color(
			clampf(foliage_color.r + color_offset.x, 0, 1),
			clampf(foliage_color.g + color_offset.y, 0, 1),
			clampf(foliage_color.b + color_offset.z, 0, 1)
		)
		mat.roughness = 0.8
		foliage.material_override = mat
		
		add_child(foliage)

# Factory method for quick creation with randomization
static func create_random(rng: RandomNumberGenerator) -> JungleTree:
	var tree = JungleTree.new()
	tree.trunk_height = rng.randf_range(3.0, 6.0)
	tree.trunk_radius = rng.randf_range(0.2, 0.4)
	tree.foliage_layers = rng.randi_range(2, 4)
	tree.foliage_radius = rng.randf_range(1.0, 2.0)
	tree.random_seed = rng.randi()
	return tree
