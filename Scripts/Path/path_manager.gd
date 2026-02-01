extends Node3D
class_name PathManager

# === CONFIGURATION ===
@export var player: Node3D  # Assign your Player node here in the Inspector
@export var chunks_ahead := 5        # How many chunks to keep spawned ahead
@export var chunks_behind := 2       # How many to keep behind before cleanup

# === CHUNK TRACKING ===
var active_chunks: Array[Node3D] = []
var next_chunk_index := 0
var next_spawn_z := 0.0

# Preload the chunk script - UPDATE THIS PATH to match your project structure
const PathChunkScript = preload("res://Scripts/Path/path_chunk.gd")

# Path mesh materials (created once, shared)
var path_material: StandardMaterial3D
var ground_material: StandardMaterial3D

func _ready() -> void:
	if not player:
		push_error("PathManager: No player assigned! Drag your Player node to the 'Player' field in Inspector.")
		return
	
	_setup_materials()
	
	# Spawn initial chunks
	for i in range(chunks_ahead + chunks_behind):
		_spawn_chunk()

func _setup_materials() -> void:
	# Main path - stone/temple floor look
	path_material = StandardMaterial3D.new()
	path_material.albedo_color = Color(0.55, 0.5, 0.45)  # Weathered stone
	path_material.roughness = 0.85
	
	# Ground beside path - dirt/jungle floor
	ground_material = StandardMaterial3D.new()
	ground_material.albedo_color = Color(0.3, 0.25, 0.15)  # Dark earth
	ground_material.roughness = 0.95

func _process(_delta: float) -> void:
	if not player:
		return
	
	var player_z = player.global_position.z
	
	# Spawn new chunks ahead
	while next_spawn_z > player_z - (chunks_ahead * PathChunk.CHUNK_LENGTH):
		_spawn_chunk()
	
	# Cleanup old chunks behind
	_cleanup_old_chunks(player_z)

func _spawn_chunk() -> void:
	var chunk = Node3D.new()
	chunk.set_script(PathChunkScript)
	chunk.chunk_index = next_chunk_index
	chunk.position.z = next_spawn_z
	
	# Add the actual path geometry
	_create_path_geometry(chunk)
	
	add_child(chunk)
	active_chunks.append(chunk)
	
	next_chunk_index += 1
	next_spawn_z -= PathChunk.CHUNK_LENGTH

func _create_path_geometry(chunk: Node3D) -> void:
	# Main runnable path
	var path_mesh = MeshInstance3D.new()
	var path_box = BoxMesh.new()
	path_box.size = Vector3(PathChunk.PATH_WIDTH, 0.5, PathChunk.CHUNK_LENGTH)
	path_mesh.mesh = path_box
	path_mesh.position = Vector3(0, -0.25, -PathChunk.CHUNK_LENGTH / 2)
	path_mesh.material_override = path_material
	chunk.add_child(path_mesh)
	
	# Path collision
	var path_body = StaticBody3D.new()
	var path_collision = CollisionShape3D.new()
	var path_shape = BoxShape3D.new()
	path_shape.size = Vector3(PathChunk.PATH_WIDTH, 0.5, PathChunk.CHUNK_LENGTH)
	path_collision.shape = path_shape
	path_collision.position = Vector3(0, -0.25, -PathChunk.CHUNK_LENGTH / 2)
	path_body.add_child(path_collision)
	chunk.add_child(path_body)
	
	# Ground on left side
	var left_ground = MeshInstance3D.new()
	var left_box = BoxMesh.new()
	left_box.size = Vector3(PathChunk.DECORATION_WIDTH * 2, 0.3, PathChunk.CHUNK_LENGTH)
	left_ground.mesh = left_box
	left_ground.position = Vector3(
		-(PathChunk.PATH_WIDTH / 2 + PathChunk.DECORATION_WIDTH),
		-0.35,
		-PathChunk.CHUNK_LENGTH / 2
	)
	left_ground.material_override = ground_material
	chunk.add_child(left_ground)
	
	# Ground on right side
	var right_ground = MeshInstance3D.new()
	right_ground.mesh = left_box  # Reuse mesh
	right_ground.position = Vector3(
		PathChunk.PATH_WIDTH / 2 + PathChunk.DECORATION_WIDTH,
		-0.35,
		-PathChunk.CHUNK_LENGTH / 2
	)
	right_ground.material_override = ground_material
	chunk.add_child(right_ground)
	
	# Optional: Add edge details (raised edges like temple run)
	_add_path_edges(chunk)

func _add_path_edges(chunk: Node3D) -> void:
	var edge_material = StandardMaterial3D.new()
	edge_material.albedo_color = Color(0.4, 0.38, 0.35)
	edge_material.roughness = 0.9
	
	# Left edge
	var left_edge = MeshInstance3D.new()
	var edge_mesh = BoxMesh.new()
	edge_mesh.size = Vector3(0.3, 0.3, PathChunk.CHUNK_LENGTH)
	left_edge.mesh = edge_mesh
	left_edge.position = Vector3(-PathChunk.PATH_WIDTH / 2 - 0.15, 0.15, -PathChunk.CHUNK_LENGTH / 2)
	left_edge.material_override = edge_material
	chunk.add_child(left_edge)
	
	# Right edge
	var right_edge = MeshInstance3D.new()
	right_edge.mesh = edge_mesh
	right_edge.position = Vector3(PathChunk.PATH_WIDTH / 2 + 0.15, 0.15, -PathChunk.CHUNK_LENGTH / 2)
	right_edge.material_override = edge_material
	chunk.add_child(right_edge)

func _cleanup_old_chunks(player_z: float) -> void:
	var chunks_to_remove: Array[Node3D] = []
	
	for chunk in active_chunks:
		# If chunk is too far behind player, mark for removal
		var chunk_end_z = chunk.position.z - PathChunk.CHUNK_LENGTH
		if chunk_end_z > player_z + (chunks_behind * PathChunk.CHUNK_LENGTH):
			chunks_to_remove.append(chunk)
	
	for chunk in chunks_to_remove:
		active_chunks.erase(chunk)
		chunk.queue_free()
