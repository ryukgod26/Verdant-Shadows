extends Node3D
class_name PathChunkTurn

# === CHUNK CONFIGURATION ===
const PATH_WIDTH := 6.0
const TURN_RADIUS := 10.0  # Distance to exit point
const CHUNK_LENGTH := 10.0  # Straight section before/after turn

enum TurnDirection { LEFT = -1, RIGHT = 1 }

var chunk_index := 0
var turn_direction: TurnDirection = TurnDirection.LEFT
var turn_area: Area3D

# Materials
static var path_material: StandardMaterial3D
static var materials_initialized := false

func _ready() -> void:
	_init_materials()
	_create_turn_geometry()
	_create_turn_area()

static func _init_materials() -> void:
	if materials_initialized:
		return
	
	path_material = StandardMaterial3D.new()
	path_material.albedo_color = Color(0.4, 0.38, 0.35)
	path_material.roughness = 0.9
	
	materials_initialized = true

func _create_turn_geometry() -> void:
	var dir = int(turn_direction)
	
	# Entry straight section (along -Z)
	var entry = _create_path_segment(Vector3(0, 0, -CHUNK_LENGTH / 2), 0.0, CHUNK_LENGTH)
	add_child(entry)
	
	# Corner piece (square at the turn)
	var corner = _create_path_segment(Vector3(dir * PATH_WIDTH / 2, 0, -CHUNK_LENGTH), 0.0, PATH_WIDTH)
	add_child(corner)
	
	# Exit straight section (along X direction after turn)
	var exit_pos = Vector3(dir * (CHUNK_LENGTH / 2 + PATH_WIDTH / 2), 0, -CHUNK_LENGTH - PATH_WIDTH / 2)
	var exit = _create_path_segment(exit_pos, -dir * PI / 2, CHUNK_LENGTH)
	add_child(exit)

func _create_path_segment(pos: Vector3, rot_y: float, length: float) -> StaticBody3D:
	var body = StaticBody3D.new()
	body.position = pos
	body.rotation.y = rot_y
	
	# Visual mesh
	var mesh_inst = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = Vector3(PATH_WIDTH, 0.5, length)
	mesh_inst.mesh = mesh
	mesh_inst.position.y = -0.25
	mesh_inst.material_override = path_material
	body.add_child(mesh_inst)
	
	# Collision
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(PATH_WIDTH, 0.5, length)
	col.shape = shape
	col.position.y = -0.25
	body.add_child(col)
	
	# Side walls
	_add_wall(body, Vector3(-PATH_WIDTH / 2 - 0.25, 1.5, 0), length)
	_add_wall(body, Vector3(PATH_WIDTH / 2 + 0.25, 1.5, 0), length)
	
	return body

func _add_wall(parent: Node3D, pos: Vector3, length: float) -> void:
	var wall = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(0.5, 3.0, length)
	wall.shape = shape
	wall.position = pos
	parent.add_child(wall)

func _create_turn_area() -> void:
	turn_area = Area3D.new()
	turn_area.name = "TurnArea"
	turn_area.monitoring = true
	turn_area.monitorable = true

	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(PATH_WIDTH + 2.0, 4.0, 4.0)
	collision.shape = shape
	
	# Position at the corner
	turn_area.position = Vector3(0, 2.0, -CHUNK_LENGTH + 2.0)
	turn_area.add_child(collision)
	add_child(turn_area)

	turn_area.set_meta("is_turn", true)
	turn_area.set_meta("turn_direction", int(turn_direction))
	turn_area.set_meta("turn_chunk", self)

func get_exit_transform() -> Transform3D:
	var dir = int(turn_direction)
	var exit_pos = Vector3(dir * (CHUNK_LENGTH + PATH_WIDTH / 2), 0, -CHUNK_LENGTH - PATH_WIDTH / 2)
	var exit_rot = -dir * PI / 2
	
	var t = Transform3D()
	t.origin = global_position + exit_pos.rotated(Vector3.UP, rotation.y)
	t.basis = Basis(Vector3.UP, rotation.y + exit_rot)
	return t

func get_path_length() -> float:
	return CHUNK_LENGTH * 2 + PATH_WIDTH
