extends Node3D
class_name PathManager

# === CONFIGURATION ===
@export var player: Node3D
@export var chunks_ahead := 5
@export var chunks_behind := 2

# === TURNS ===
@export_group("Turns")
@export var enable_turns := true
@export var min_straight_before_turn := 3  # Minimum straight chunks before a turn can occur
@export var turn_chance := 0.25  # 25% chance of turn after minimum straights

# === COINS ===
@export_group("Coins")
@export var spawn_coins := true

# === LIGHTING ===
@export_group("Path Lighting")
@export var default_light_mode := 0  # 0 = WARM, 1 = COOL
@export var light_transition_duration := 1.0

# === CHUNK TRACKING ===
var active_chunks: Array[Node3D] = []
var next_chunk_index := 0
var current_light_mode := 0

# Path direction tracking (for turns)
var current_direction := Vector3.FORWARD  # -Z is forward
var current_rotation := 0.0  # Rotation in radians
var next_spawn_position := Vector3.ZERO
var straight_count := 0  # How many straight chunks since last turn

# Preload
const PathChunkScript = preload("res://Scripts/Path/path_chunk.gd")
const PathChunkTurnScript = preload("res://Scripts/Path/path_chunk_turn.gd")

const CHUNK_LENGTH := 20.0
const TURN_RADIUS := 10.0

func _ready() -> void:
	if not player:
		push_error("PathManager: No player assigned!")
		return
	
	current_light_mode = default_light_mode
	PathChunk.spawn_coins = spawn_coins
	
	# Spawn initial chunks (all straight to start)
	for i in range(chunks_ahead + chunks_behind):
		_spawn_straight_chunk()

func _process(_delta: float) -> void:
	if not player:
		return
	
	# Calculate how far ahead we need chunks based on player position
	# This is more complex with turns, so we use chunk count
	while active_chunks.size() < chunks_ahead + chunks_behind + 2:
		_spawn_next_chunk()
	
	# Cleanup old chunks behind
	_cleanup_old_chunks()

func _spawn_next_chunk() -> void:
	if enable_turns and straight_count >= min_straight_before_turn:
		var rng = RandomNumberGenerator.new()
		rng.seed = hash(next_chunk_index * 12345)
		
		if rng.randf() < turn_chance:
			# Spawn a turn
			var turn_dir = 1 if rng.randf() > 0.5 else -1  # Random left or right
			_spawn_turn_chunk(turn_dir)
			straight_count = 0
			return
	
	_spawn_straight_chunk()
	straight_count += 1

func _spawn_straight_chunk() -> void:
	var chunk = Node3D.new()
	chunk.set_script(PathChunkScript)
	chunk.chunk_index = next_chunk_index
	
	# Position and rotate based on current path direction
	chunk.global_position = next_spawn_position
	chunk.rotation.y = current_rotation
	
	add_child(chunk)
	active_chunks.append(chunk)
	
	# Apply lighting
	chunk.call_deferred("set_light_mode", current_light_mode)
	
	# Update next spawn position
	var forward = Vector3(0, 0, -CHUNK_LENGTH).rotated(Vector3.UP, current_rotation)
	next_spawn_position += forward
	
	next_chunk_index += 1

func _spawn_turn_chunk(direction: int) -> void:
	var chunk = Node3D.new()
	chunk.set_script(PathChunkTurnScript)
	chunk.chunk_index = next_chunk_index
	chunk.turn_direction = direction
	
	# Position and rotate
	chunk.global_position = next_spawn_position
	chunk.rotation.y = current_rotation
	
	add_child(chunk)
	active_chunks.append(chunk)
	
	# Apply lighting
	chunk.call_deferred("set_light_mode", current_light_mode)
	
	# Update direction and position for next chunk
	# Turn changes our heading by 90 degrees
	current_rotation += -direction * PI / 2
	
	# Calculate exit position of the turn
	var turn_exit_local = Vector3(direction * TURN_RADIUS, 0, -TURN_RADIUS)
	var turn_exit_global = next_spawn_position + turn_exit_local.rotated(Vector3.UP, current_rotation + direction * PI / 2)
	next_spawn_position = turn_exit_global
	
	next_chunk_index += 1

func _cleanup_old_chunks() -> void:
	if active_chunks.size() <= chunks_behind:
		return
	
	var player_pos = player.global_position
	var chunks_to_remove: Array[Node3D] = []
	
	# Remove chunks that are far behind the player
	for chunk in active_chunks:
		var dist_to_player = player_pos.distance_to(chunk.global_position)
		var chunk_behind = (chunk.global_position - player_pos).dot(-current_direction) > CHUNK_LENGTH * 2
		
		# Simple distance check - if chunk is far and behind, remove it
		if dist_to_player > CHUNK_LENGTH * (chunks_behind + 2) and chunk_behind:
			chunks_to_remove.append(chunk)
	
	# Keep at least some chunks
	while chunks_to_remove.size() > 0 and active_chunks.size() - chunks_to_remove.size() >= chunks_behind:
		var chunk = chunks_to_remove.pop_front()
		active_chunks.erase(chunk)
		chunk.queue_free()

# === LIGHTING API ===

func set_all_lights_mode(mode: int) -> void:
	current_light_mode = mode
	for chunk in active_chunks:
		if chunk.has_method("set_light_mode"):
			chunk.set_light_mode(mode)

func transition_all_lights(mode: int, duration: float = -1.0) -> void:
	if duration < 0:
		duration = light_transition_duration
	
	current_light_mode = mode
	for chunk in active_chunks:
		if chunk.has_method("transition_light_mode"):
			chunk.transition_light_mode(mode, duration)

func set_warm_lighting() -> void:
	transition_all_lights(0)

func set_cool_lighting() -> void:
	transition_all_lights(1)

func toggle_light_mode() -> void:
	var new_mode = 1 if current_light_mode == 0 else 0
	transition_all_lights(new_mode)

# === COIN API ===

func set_coins_enabled(enabled: bool) -> void:
	spawn_coins = enabled
	PathChunk.spawn_coins = enabled
