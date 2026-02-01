extends Node3D
class_name SimpleRock

# Simple rock - just a sphere stretched

static var rock_material: StandardMaterial3D
static var material_ready := false

var rock_size := 0.5

func _ready() -> void:
	_init_material()
	_build()

static func _init_material() -> void:
	if material_ready:
		return
	
	rock_material = StandardMaterial3D.new()
	rock_material.albedo_color = Color(0.4, 0.38, 0.35)
	rock_material.roughness = 1.0
	
	material_ready = true

func _build() -> void:
	var rock = MeshInstance3D.new()
	rock.name = "Rock"
	
	var mesh = SphereMesh.new()
	mesh.radius = rock_size
	mesh.height = rock_size * 1.2
	rock.mesh = mesh
	rock.position.y = rock_size * 0.4
	rock.scale = Vector3(1.0, 0.6, 0.9)  # Flatten a bit
	rock.material_override = rock_material
	rock.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	add_child(rock)

static func create_random(rng: RandomNumberGenerator) -> SimpleRock:
	var rock = SimpleRock.new()
	rock.rock_size = rng.randf_range(0.3, 0.8)
	return rock
