@tool
extends Node3D
class_name JungleRock

# === EXPORT PARAMETERS ===
@export_group("Size")
@export var rock_size: float = 0.6:
	set(v):
		rock_size = v
		if Engine.is_editor_hint(): _rebuild()
@export var height_ratio: float = 0.8:
	set(v):
		height_ratio = clampf(v, 0.3, 1.5)
		if Engine.is_editor_hint(): _rebuild()

@export_group("Shape")
@export var squash_x: float = 1.0:
	set(v):
		squash_x = v
		if Engine.is_editor_hint(): _rebuild()
@export var squash_z: float = 1.0:
	set(v):
		squash_z = v
		if Engine.is_editor_hint(): _rebuild()

@export_group("Appearance")
@export var rock_color: Color = Color(0.38, 0.35, 0.32):
	set(v):
		rock_color = v
		if Engine.is_editor_hint(): _rebuild()
@export var color_variation: float = 0.05:
	set(v):
		color_variation = v
		if Engine.is_editor_hint(): _rebuild()
@export var add_moss: bool = false:
	set(v):
		add_moss = v
		if Engine.is_editor_hint(): _rebuild()
@export var moss_color: Color = Color(0.2, 0.4, 0.15):
	set(v):
		moss_color = v
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
	
	_create_rock(rng)
	
	if add_moss:
		_create_moss(rng)
	
	_built = true

func _create_rock(rng: RandomNumberGenerator) -> void:
	var rock = MeshInstance3D.new()
	rock.name = "RockMesh"
	
	var mesh = SphereMesh.new()
	mesh.radius = rock_size
	mesh.height = rock_size * 2.0 * height_ratio
	rock.mesh = mesh
	
	# Apply squash for irregular shape
	rock.scale = Vector3(
		squash_x * rng.randf_range(0.8, 1.2),
		rng.randf_range(0.6, 1.0),
		squash_z * rng.randf_range(0.8, 1.2)
	)
	
	# Sink slightly into ground
	rock.position.y = mesh.height * 0.3 * rock.scale.y
	
	# Material
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(
		clampf(rock_color.r + rng.randf_range(-color_variation, color_variation), 0, 1),
		clampf(rock_color.g + rng.randf_range(-color_variation, color_variation), 0, 1),
		clampf(rock_color.b + rng.randf_range(-color_variation, color_variation), 0, 1)
	)
	mat.roughness = 0.95
	rock.material_override = mat
	
	add_child(rock)

func _create_moss(rng: RandomNumberGenerator) -> void:
	# Add a few moss patches on top of rock
	var moss_count = rng.randi_range(2, 4)
	
	for i in range(moss_count):
		var moss = MeshInstance3D.new()
		moss.name = "Moss_%d" % i
		
		var mesh = SphereMesh.new()
		var moss_size = rock_size * rng.randf_range(0.2, 0.4)
		mesh.radius = moss_size
		mesh.height = moss_size * 0.5
		moss.mesh = mesh
		
		# Position on top/sides of rock
		var angle = rng.randf() * TAU
		var height_offset = rng.randf_range(0.3, 0.8)
		moss.position = Vector3(
			cos(angle) * rock_size * 0.5,
			rock_size * height_ratio * height_offset,
			sin(angle) * rock_size * 0.5
		)
		
		var mat = StandardMaterial3D.new()
		mat.albedo_color = moss_color
		mat.roughness = 0.95
		moss.material_override = mat
		
		add_child(moss)

# Factory method
static func create_random(rng: RandomNumberGenerator) -> JungleRock:
	var rock = JungleRock.new()
	rock.rock_size = rng.randf_range(0.3, 1.0)
	rock.height_ratio = rng.randf_range(0.5, 1.0)
	rock.squash_x = rng.randf_range(0.7, 1.3)
	rock.squash_z = rng.randf_range(0.7, 1.3)
	rock.add_moss = rng.randf() > 0.6  # 40% chance of moss
	rock.random_seed = rng.randi()
	return rock
