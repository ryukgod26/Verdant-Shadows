extends Node3D
class_name PathManager

# === CONFIGURATION ===
@export var player: Node3D
@export var chunks_ahead := 8
@export var chunks_behind := 2

# === COINS ===
@export_group("Coins")
@export var spawn_coins := true

# === FOREST/DECORATIONS ===
@export_group("Forest")
@export var spawn_decorations := true

# === LIGHTING ===
@export_group("Path Lighting")
@export var default_light_mode := 0  # 0 = WARM, 1 = COOL

# === CHUNK TRACKING ===
var active_chunks: Array[Node3D] = []
var next_chunk_index := 0
var current_light_mode := 0
var next_spawn_z := 0.0

const PathChunkScript = preload("res://Scripts/Path/path_chunk.gd")
const CHUNK_LENGTH := 20.0

func _ready() -> void:
	if not player:
		push_error("PathManager: No player assigned!")
		return
	
	current_light_mode = default_light_mode
	PathChunk.spawn_coins = spawn_coins
	PathChunk.spawn_decorations = spawn_decorations
	
	for i in range(chunks_ahead + chunks_behind):
		_spawn_chunk()

func _process(_delta: float) -> void:
	if not player:
		return
	
	# Spawn more chunks as player moves forward
	while active_chunks.size() < chunks_ahead + chunks_behind + 2:
		_spawn_chunk()
	
	_cleanup_old_chunks()

func _spawn_chunk() -> void:
	var chunk = Node3D.new()
	chunk.set_script(PathChunkScript)
	chunk.chunk_index = next_chunk_index
	chunk.global_position = Vector3(0, 0, -next_spawn_z)
	
	add_child(chunk)
	active_chunks.append(chunk)
	chunk.call_deferred("set_light_mode", current_light_mode)
	
	next_spawn_z += CHUNK_LENGTH
	next_chunk_index += 1

func _cleanup_old_chunks() -> void:
	if active_chunks.size() <= chunks_behind:
		return
	
	var player_z = player.global_position.z
	var chunks_to_remove: Array[Node3D] = []
	
	for chunk in active_chunks:
		if chunk.global_position.z > player_z + CHUNK_LENGTH * 2:
			chunks_to_remove.append(chunk)
	
	for chunk in chunks_to_remove:
		active_chunks.erase(chunk)
		chunk.queue_free()

func set_light_mode(mode: int) -> void:
	current_light_mode = mode
	for chunk in active_chunks:
		if chunk.has_method("set_light_mode"):
			chunk.set_light_mode(mode)
