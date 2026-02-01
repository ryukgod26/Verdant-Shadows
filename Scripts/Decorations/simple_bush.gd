extends Node3D
class_name SimpleBush

# Simple round bush - no complex shapes

static var bush_material: StandardMaterial3D
static var material_ready := false

var bush_size := 0.7

func _ready() -> void:
	_init_material()
	_build()

static func _init_material() -> void:
	if material_ready:
		return
	
	bush_material = StandardMaterial3D.new()
	bush_material.albedo_color = Color(0.18, 0.4, 0.15)
	bush_material.roughness = 1.0
	bush_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	material_ready = true

func _build() -> void:
	var bush = MeshInstance3D.new()
	bush.name = "Bush"
	
	var mesh = SphereMesh.new()
	mesh.radius = bush_size
	mesh.height = bush_size * 1.4
	bush.mesh = mesh
	bush.position.y = bush_size * 0.6
	bush.material_override = bush_material
	bush.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	add_child(bush)

static func create_random(rng: RandomNumberGenerator) -> SimpleBush:
	var bush = SimpleBush.new()
	bush.bush_size = rng.randf_range(0.5, 1.0)
	return bush
