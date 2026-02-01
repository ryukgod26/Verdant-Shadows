extends Node3D
class_name PathManager

# === CONFIGURATION ===
@export var player: Node3D
@export var chunks_ahead := 5
@export var chunks_behind := 2

# === LIGHTING ===
@export_group("Path Lighting")
@export var default_light_mode := 0  # 0 = WARM, 1 = COOL
@export var light_transition_duration := 1.0

# === CHUNK TRACKING ===
var active_chunks: Array[Node3D] = []
var next_chunk_index := 0
var next_spawn_z := 0.0
var current_light_mode := 0

# Preload
const PathChunkScript = preload("res://Scripts/Path/path_chunk.gd")

func _ready() -> void:
	if not player:
		push_error("PathManager: No player assigned!")
		return
	
	current_light_mode = default_light_mode
	
	# Spawn initial chunks
	for i in range(chunks_ahead + chunks_behind):
		_spawn_chunk()

func _process(_delta: float) -> void:
	if not player:
		return
	
	var player_z = player.global_position.z
	
	# Spawn new chunks ahead
	while next_spawn_z > player_z - (chunks_ahead * 20.0):  # CHUNK_LENGTH
		_spawn_chunk()
	
	# Cleanup old chunks behind
	_cleanup_old_chunks(player_z)

func _spawn_chunk() -> void:
	var chunk = Node3D.new()
	chunk.set_script(PathChunkScript)
	chunk.chunk_index = next_chunk_index
	chunk.position.z = next_spawn_z
	
	add_child(chunk)
	active_chunks.append(chunk)
	
	# Apply current light mode after a frame (let it initialize)
	chunk.call_deferred("set_light_mode", current_light_mode)
	
	next_chunk_index += 1
	next_spawn_z -= 20.0  # CHUNK_LENGTH

func _cleanup_old_chunks(player_z: float) -> void:
	var chunks_to_remove: Array[Node3D] = []
	
	for chunk in active_chunks:
		var chunk_end_z = chunk.position.z - 20.0  # CHUNK_LENGTH
		if chunk_end_z > player_z + (chunks_behind * 20.0):
			chunks_to_remove.append(chunk)
	
	for chunk in chunks_to_remove:
		active_chunks.erase(chunk)
		chunk.queue_free()

# === LIGHTING API ===

## Set light mode for all chunks (instant)
func set_all_lights_mode(mode: int) -> void:
	current_light_mode = mode
	for chunk in active_chunks:
		if chunk.has_method("set_light_mode"):
			chunk.set_light_mode(mode)

## Transition all chunks to new light mode (smooth)
func transition_all_lights(mode: int, duration: float = -1.0) -> void:
	if duration < 0:
		duration = light_transition_duration
	
	current_light_mode = mode
	for chunk in active_chunks:
		if chunk.has_method("transition_light_mode"):
			chunk.transition_light_mode(mode, duration)

## Convenience: Switch to warm lighting (dawn/evening - 5.67)
func set_warm_lighting() -> void:
	transition_all_lights(0)  # WARM

## Convenience: Switch to cool lighting (midnight - 20.67)
func set_cool_lighting() -> void:
	transition_all_lights(1)  # COOL

## Toggle between modes
func toggle_light_mode() -> void:
	var new_mode = 1 if current_light_mode == 0 else 0
	transition_all_lights(new_mode)
