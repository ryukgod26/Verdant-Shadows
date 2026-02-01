extends Node3D
class_name PathChunk

# === CHUNK CONFIGURATION ===
const CHUNK_LENGTH := 20.0
const PATH_WIDTH := 6.0
const DECORATION_WIDTH := 30.0  # Doubled from 15 for larger forest area
const LANE_WIDTH := 2.0  # Width of each lane

# Decoration density per chunk (per side) - increased for larger forest
const TREES_PER_SIDE := 12
const GRASS_PER_SIDE := 20
const ROCKS_PER_SIDE := 5
const BUSHES_PER_SIDE := 10

# Coin settings
const COIN_ROWS_PER_CHUNK := 4  # How many rows of coins per chunk
const COIN_HEIGHT := 1.0  # Height above ground

# Scripts (preloaded)
const PathSegmentScript = preload("res://Scripts/Path/path_segment.gd")
const JungleTreeScript = preload("res://Scripts/Decorations/jungle_tree.gd")
const GrassClumpScript = preload("res://Scripts/Decorations/grass_clump.gd")
const JungleRockScript = preload("res://Scripts/Decorations/jungle_rock.gd")
const JungleBushScript = preload("res://Scripts/Decorations/jungle_bush.gd")
const CoinScript = preload("res://Scripts/Collectibles/coin.gd")

# References
var chunk_index := 0
var path_segment: Node3D
var decorations_container: Node3D
var coins_container: Node3D

# Coin pattern - set by PathManager
static var spawn_coins := true

func _ready() -> void:
	_create_path_segment()
	_create_decorations_container()
	_generate_decorations()
	if spawn_coins:
		_create_coins()

func _create_path_segment() -> void:
	path_segment = Node3D.new()
	path_segment.set_script(PathSegmentScript)
	path_segment.name = "PathSegment"
	add_child(path_segment)

func _create_decorations_container() -> void:
	decorations_container = Node3D.new()
	decorations_container.name = "Decorations"
	add_child(decorations_container)

func _generate_decorations() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(chunk_index)  # Deterministic
	
	# Generate for both sides
	_generate_side_decorations(rng, -1)  # Left
	_generate_side_decorations(rng, 1)   # Right

func _generate_side_decorations(rng: RandomNumberGenerator, side: int) -> void:
	var base_x = side * (PATH_WIDTH / 2 + 2.0)
	
	# Trees
	for i in range(TREES_PER_SIDE):
		var tree = JungleTreeScript.create_random(rng)
		tree.position = _get_decoration_position(rng, base_x, side, 2.0, DECORATION_WIDTH)
		tree.rotation.y = rng.randf() * TAU
		decorations_container.add_child(tree)
	
	# Grass
	for i in range(GRASS_PER_SIDE):
		var grass = GrassClumpScript.create_random(rng)
		grass.position = _get_decoration_position(rng, base_x, side, 0.5, DECORATION_WIDTH)
		decorations_container.add_child(grass)
	
	# Rocks
	for i in range(ROCKS_PER_SIDE):
		var rock = JungleRockScript.create_random(rng)
		rock.position = _get_decoration_position(rng, base_x, side, 1.0, DECORATION_WIDTH * 0.7)
		rock.rotation.y = rng.randf() * TAU
		decorations_container.add_child(rock)
	
	# Bushes
	for i in range(BUSHES_PER_SIDE):
		var bush = JungleBushScript.create_random(rng)
		bush.position = _get_decoration_position(rng, base_x, side, 1.5, DECORATION_WIDTH * 0.8)
		bush.rotation.y = rng.randf() * TAU
		decorations_container.add_child(bush)

func _get_decoration_position(rng: RandomNumberGenerator, base_x: float, side: int, min_dist: float, max_dist: float) -> Vector3:
	var x = base_x + side * rng.randf_range(min_dist, max_dist)
	var z = rng.randf_range(0, -CHUNK_LENGTH)  # Negative Z is forward
	return Vector3(x, 0, z)

func _create_coins() -> void:
	coins_container = Node3D.new()
	coins_container.name = "Coins"
	add_child(coins_container)
	
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(chunk_index * 777)  # Different seed than decorations
	
	var row_spacing = CHUNK_LENGTH / (COIN_ROWS_PER_CHUNK + 1)
	
	for row in range(COIN_ROWS_PER_CHUNK):
		var z_pos = -row_spacing * (row + 1)
		
		# Randomly choose a coin pattern for this row
		var pattern = rng.randi() % 5
		
		match pattern:
			0:  # Single coin in center
				_spawn_coin(Vector3(0, COIN_HEIGHT, z_pos))
			1:  # Single coin on left
				_spawn_coin(Vector3(-LANE_WIDTH, COIN_HEIGHT, z_pos))
			2:  # Single coin on right
				_spawn_coin(Vector3(LANE_WIDTH, COIN_HEIGHT, z_pos))
			3:  # All three lanes
				_spawn_coin(Vector3(-LANE_WIDTH, COIN_HEIGHT, z_pos))
				_spawn_coin(Vector3(0, COIN_HEIGHT, z_pos))
				_spawn_coin(Vector3(LANE_WIDTH, COIN_HEIGHT, z_pos))
			4:  # Two coins (left + right)
				_spawn_coin(Vector3(-LANE_WIDTH, COIN_HEIGHT, z_pos))
				_spawn_coin(Vector3(LANE_WIDTH, COIN_HEIGHT, z_pos))

func _spawn_coin(pos: Vector3) -> void:
	var coin = CoinScript.create(pos)
	coins_container.add_child(coin)

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
