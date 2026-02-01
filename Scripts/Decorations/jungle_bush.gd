@tool
extends Node3D
class_name JungleBush

# === BUSH VARIANTS ===
enum BushType { ROUND, TALL, SPREAD, FERN }

@export var bush_type: BushType = BushType.ROUND:
	set(v):
		bush_type = v
		if Engine.is_editor_hint(): _rebuild()

@export_group("Size")
@export var bush_size: float = 0.8:
	set(v):
		bush_size = v
		if Engine.is_editor_hint(): _rebuild()

@export_group("Appearance")
@export var bush_color: Color = Color(0.18, 0.45, 0.12):
	set(v):
		bush_color = v
		if Engine.is_editor_hint(): _rebuild()
@export var color_variation: float = 0.08:
	set(v):
		color_variation = v
		if Engine.is_editor_hint(): _rebuild()
@export var density: int = 5:
	set(v):
		density = clampi(v, 2, 10)
		if Engine.is_editor_hint(): _rebuild()

@export_group("Randomization")
@export var random_seed: int = 0

var _built := false

func _ready() -> void:
	if not _built:
		_rebuild()

func _rebuild() -> void:
	for child in get_children():
		child.queue_free()
	
	var rng = RandomNumberGenerator.new()
	rng.seed = random_seed if random_seed != 0 else hash(global_position)
	
	match bush_type:
		BushType.ROUND:
			_create_round_bush(rng)
		BushType.TALL:
			_create_tall_bush(rng)
		BushType.SPREAD:
			_create_spread_bush(rng)
		BushType.FERN:
			_create_fern(rng)
	
	_built = true

func _create_round_bush(rng: RandomNumberGenerator) -> void:
	# Clustered spheres forming a round bush
	for i in range(density):
		var sphere = MeshInstance3D.new()
		sphere.name = "BushPart_%d" % i
		
		var mesh = SphereMesh.new()
		var part_size = bush_size * rng.randf_range(0.4, 0.7)
		mesh.radius = part_size
		mesh.height = part_size * 2
		sphere.mesh = mesh
		
		# Cluster around center
		var angle = rng.randf() * TAU
		var dist = rng.randf_range(0, bush_size * 0.4)
		sphere.position = Vector3(
			cos(angle) * dist,
			part_size + rng.randf_range(0, bush_size * 0.3),
			sin(angle) * dist
		)
		
		sphere.material_override = _create_bush_material(rng)
		add_child(sphere)

func _create_tall_bush(rng: RandomNumberGenerator) -> void:
	# Vertical elongated shapes
	for i in range(density):
		var part = MeshInstance3D.new()
		part.name = "TallPart_%d" % i
		
		var mesh = CylinderMesh.new()
		var height = bush_size * rng.randf_range(1.0, 2.0)
		mesh.top_radius = bush_size * 0.2
		mesh.bottom_radius = bush_size * 0.3
		mesh.height = height
		part.mesh = mesh
		
		# Slight spread
		var angle = rng.randf() * TAU
		var dist = rng.randf_range(0, bush_size * 0.3)
		part.position = Vector3(
			cos(angle) * dist,
			height / 2,
			sin(angle) * dist
		)
		part.rotation.x = rng.randf_range(-0.2, 0.2)
		part.rotation.z = rng.randf_range(-0.2, 0.2)
		
		part.material_override = _create_bush_material(rng)
		add_child(part)

func _create_spread_bush(rng: RandomNumberGenerator) -> void:
	# Low, wide spreading bush
	for i in range(density + 2):
		var part = MeshInstance3D.new()
		part.name = "SpreadPart_%d" % i
		
		var mesh = SphereMesh.new()
		var part_size = bush_size * rng.randf_range(0.3, 0.5)
		mesh.radius = part_size
		mesh.height = part_size * 1.2
		part.mesh = mesh
		
		# Wide spread
		var angle = (float(i) / (density + 2)) * TAU + rng.randf_range(-0.3, 0.3)
		var dist = bush_size * rng.randf_range(0.5, 1.0)
		part.position = Vector3(
			cos(angle) * dist,
			part_size * 0.8,
			sin(angle) * dist
		)
		
		part.scale.y = 0.6  # Flatten
		part.material_override = _create_bush_material(rng)
		add_child(part)

func _create_fern(rng: RandomNumberGenerator) -> void:
	# Fern-like fronds radiating out
	var frond_count = density + 3
	
	for i in range(frond_count):
		var frond = MeshInstance3D.new()
		frond.name = "Frond_%d" % i
		
		# Elongated box for frond
		var mesh = BoxMesh.new()
		var length = bush_size * rng.randf_range(0.8, 1.2)
		mesh.size = Vector3(0.08, 0.02, length)
		frond.mesh = mesh
		
		# Radiate from center
		var angle = (float(i) / frond_count) * TAU
		frond.position = Vector3(0, bush_size * 0.2, 0)
		frond.rotation.y = angle
		frond.rotation.x = rng.randf_range(0.3, 0.7)  # Droop outward
		
		# Move pivot to base
		frond.position.z = length / 2
		frond.position = frond.position.rotated(Vector3.UP, angle)
		frond.position.y = bush_size * 0.1
		
		frond.material_override = _create_bush_material(rng, true)
		add_child(frond)

func _create_bush_material(rng: RandomNumberGenerator, darker: bool = false) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	var color = bush_color
	if darker:
		color = color.darkened(0.15)
	
	mat.albedo_color = Color(
		clampf(color.r + rng.randf_range(-color_variation, color_variation), 0, 1),
		clampf(color.g + rng.randf_range(-color_variation, color_variation), 0, 1),
		clampf(color.b + rng.randf_range(-color_variation, color_variation), 0, 1)
	)
	mat.roughness = 0.85
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat

# Factory method
static func create_random(rng: RandomNumberGenerator) -> JungleBush:
	var bush = JungleBush.new()
	bush.bush_type = rng.randi() % 4 as BushType
	bush.bush_size = rng.randf_range(0.5, 1.2)
	bush.density = rng.randi_range(3, 7)
	bush.random_seed = rng.randi()
	return bush
