extends Node3D
class_name PathChunk

# === CHUNK CONFIGURATION ===
const CHUNK_LENGTH := 20.0
const PATH_WIDTH := 6.0
const DECORATION_WIDTH := 25.0  # Forest area
const LANE_WIDTH := 2.0  # Width of each lane

# Decoration density per chunk (per side)
const TREES_PER_SIDE := 8
const GRASS_PATCHES_PER_SIDE := 4  # Each patch has 500-1200 grass blades
const ROCKS_PER_SIDE := 6
const BUSHES_PER_SIDE := 12

# Coin settings
const COIN_HEIGHT := 1.0
const COIN_SPAWN_CHANCE := 0.3  # 30% chance for coin stream
const STREAM_LENGTH := 6  # Coins in a stream
const STREAM_SPACING := 2.5  # Distance between coins in stream

# Booster settings
const BOOSTER_HEIGHT := 1.2
const BOOSTER_SPAWN_CHANCE := 0.08  # 8% chance per chunk

# Spawn config
static var spawn_decorations := true
static var spawn_coins := true
static var spawn_boosters := true

# Scripts (preloaded)
const PathSegmentScript = preload("res://Scripts/Path/path_segment.gd")
const MultiMeshForestScript = preload("res://Scripts/Decorations/multi_mesh_forest.gd")
const CoinScript = preload("res://Scripts/Collectibles/coin.gd")
const BoosterScript = preload("res://Scripts/Collectibles/booster.gd")

# References
var chunk_index := 0
var path_segment: Node3D
var forest: Node3D
var coins_container: Node3D
var boosters_container: Node3D

func _ready() -> void:
	_create_path_segment()
	_create_walls()
	if spawn_decorations:
		_create_forest()
	if spawn_coins:
		_create_coins()
	if spawn_boosters:
		_create_boosters()

func _create_path_segment() -> void:
	path_segment = Node3D.new()
	path_segment.set_script(PathSegmentScript)
	path_segment.name = "PathSegment"
	add_child(path_segment)

func _create_walls() -> void:
	# Invisible walls on both sides of straight path
	for side in [-1, 1]:
		var wall = StaticBody3D.new()
		wall.name = "Wall_" + ("Left" if side == -1 else "Right")

		var collision = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = Vector3(0.5, 3.0, CHUNK_LENGTH + 1.0)
		collision.shape = shape

		wall.position = Vector3(side * (PATH_WIDTH / 2 + 0.25), 1.5, -CHUNK_LENGTH / 2)
		wall.add_child(collision)
		add_child(wall)

func _create_forest() -> void:
	forest = Node3D.new()
	forest.set_script(MultiMeshForestScript)
	forest.name = "Forest"
	add_child(forest)
	forest.setup_forest(chunk_index, CHUNK_LENGTH, PATH_WIDTH, DECORATION_WIDTH, TREES_PER_SIDE, GRASS_PATCHES_PER_SIDE, ROCKS_PER_SIDE, BUSHES_PER_SIDE)

func _create_coins() -> void:
	coins_container = Node3D.new()
	coins_container.name = "Coins"
	add_child(coins_container)
	
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(chunk_index * 777)
	
	# Chance to spawn a coin stream
	if rng.randf() > COIN_SPAWN_CHANCE:
		return
	
	# Pick a lane: -1 (left), 0 (center), 1 (right)
	var lane = rng.randi_range(-1, 1)
	var x_pos = lane * LANE_WIDTH
	
	# Starting Z position
	var start_z = -2.0
	
	# Create stream of coins
	for i in range(STREAM_LENGTH):
		var z_pos = start_z - (i * STREAM_SPACING)
		if z_pos < -CHUNK_LENGTH + 1.0:
			break
		_spawn_coin(Vector3(x_pos, COIN_HEIGHT, z_pos))

func _spawn_coin(pos: Vector3) -> void:
	var coin = CoinScript.create(pos)
	coins_container.add_child(coin)

func _create_boosters() -> void:
	boosters_container = Node3D.new()
	boosters_container.name = "Boosters"
	add_child(boosters_container)
	
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(chunk_index * 999)
	
	if rng.randf() > BOOSTER_SPAWN_CHANCE:
		return
	
	# Spawn booster in random lane
	var lane = rng.randi_range(-1, 1)
	var x_pos = lane * LANE_WIDTH
	var z_pos = rng.randf_range(-5.0, -CHUNK_LENGTH + 5.0)
	
	var booster = BoosterScript.create(Vector3(x_pos, BOOSTER_HEIGHT, z_pos))
	boosters_container.add_child(booster)

# === DECORATIONS CONTROL ===
func _hide_decorations() -> void:
	if forest:
		forest.visible = false

func set_decorations_visible(visible: bool) -> void:
	if forest:
		forest.visible = visible

# === LIGHTING CONTROL ===
func set_light_mode(mode: int) -> void:
	if path_segment and path_segment.has_method("set_light_mode"):
		path_segment.set_light_mode(mode)

func transition_light_mode(mode: int, duration: float = 1.0) -> void:
	if path_segment and path_segment.has_method("transition_to_mode"):
		path_segment.transition_to_mode(mode, duration)

# === UTILITY ===
func get_end_position() -> Vector3:
	return global_position + Vector3(0, 0, -CHUNK_LENGTH)
