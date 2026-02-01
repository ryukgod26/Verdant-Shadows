@tool
extends Area3D
class_name Booster

# === CONFIGURATION ===
@export_group("Appearance")
@export var orb_radius := 0.5:
	set(v):
		orb_radius = v
		if Engine.is_editor_hint(): _rebuild()

@export_group("Animation")
@export var rotate_speed := 2.0
@export var bob_speed := 1.5
@export var bob_height := 0.15
@export var pulse_speed := 3.0

# Internal
var _mesh: MeshInstance3D
var _glow_mesh: MeshInstance3D
var _material: StandardMaterial3D
var _glow_material: StandardMaterial3D
var _initial_y := 0.0
var _time := 0.0
var _collected := false

signal collected

func _ready() -> void:
	_initial_y = position.y
	_rebuild()
	
	set_meta("is_booster", true)
	
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _rebuild() -> void:
	for child in get_children():
		child.queue_free()
	
	_create_mesh()
	_create_arrow_trails()
	_create_glow()
	_create_collision()

func _create_mesh() -> void:
	_mesh = MeshInstance3D.new()
	_mesh.name = "BoosterMesh"
	
	# Arrow/chevron pointing forward using prism
	var mesh = PrismMesh.new()
	mesh.size = Vector3(orb_radius * 1.0, orb_radius * 0.8, orb_radius * 1.4)
	_mesh.mesh = mesh
	_mesh.rotation.x = -PI / 2  # Point forward
	
	_material = StandardMaterial3D.new()
	_material.albedo_color = Color(0.1, 0.4, 1.0)
	_material.metallic = 0.9
	_material.roughness = 0.05
	_material.emission_enabled = true
	_material.emission = Color(0.2, 0.5, 1.0)
	_material.emission_energy_multiplier = 4.0
	_material.rim_enabled = true
	_material.rim = 1.0
	_material.rim_tint = 0.3
	
	_mesh.material_override = _material
	add_child(_mesh)

func _create_arrow_trails() -> void:
	# Trailing speed lines behind the arrow
	var trail_mat = StandardMaterial3D.new()
	trail_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	trail_mat.albedo_color = Color(0.3, 0.7, 1.0, 0.6)
	trail_mat.emission_enabled = true
	trail_mat.emission = Color(0.3, 0.7, 1.0)
	trail_mat.emission_energy_multiplier = 2.0
	
	for i in range(3):
		var trail = MeshInstance3D.new()
		trail.name = "Trail_" + str(i)
		var box = BoxMesh.new()
		var length = orb_radius * (0.8 - i * 0.2)
		box.size = Vector3(0.08, 0.08, length)
		trail.mesh = box
		trail.position = Vector3((i - 1) * 0.25, 0, orb_radius * 0.8 + i * 0.3)
		trail.material_override = trail_mat
		add_child(trail)

func _create_glow() -> void:
	# Outer glow - elongated for speed feel
	_glow_mesh = MeshInstance3D.new()
	_glow_mesh.name = "GlowMesh"
	
	var mesh = BoxMesh.new()
	mesh.size = Vector3(orb_radius * 2.0, orb_radius * 1.5, orb_radius * 2.5)
	_glow_mesh.mesh = mesh
	
	_glow_material = StandardMaterial3D.new()
	_glow_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_glow_material.albedo_color = Color(0.2, 0.5, 1.0, 0.12)
	_glow_material.emission_enabled = true
	_glow_material.emission = Color(0.2, 0.6, 1.0)
	_glow_material.emission_energy_multiplier = 2.0
	_glow_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	_glow_mesh.material_override = _glow_material
	add_child(_glow_mesh)

func _create_collision() -> void:
	var collision = CollisionShape3D.new()
	collision.name = "BoosterCollision"
	var shape = SphereShape3D.new()
	shape.radius = orb_radius * 1.5
	collision.shape = shape
	add_child(collision)

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	if _collected:
		return
	
	_time += delta
	
	# Rotate
	if _mesh:
		_mesh.rotation.y += rotate_speed * delta
	if _glow_mesh:
		_glow_mesh.rotation.y -= rotate_speed * 0.5 * delta
	
	# Bob
	position.y = _initial_y + sin(_time * bob_speed) * bob_height
	
	# Pulse glow
	if _material:
		var pulse = 2.5 + sin(_time * pulse_speed) * 1.0
		_material.emission_energy_multiplier = pulse

func _on_body_entered(body: Node3D) -> void:
	if _collected:
		return
	if body.is_in_group("player") or body.name.contains("Player"):
		collect()

func _on_area_entered(area: Area3D) -> void:
	if _collected:
		return
	if area.name == "CoinCollector":
		collect()

func collect() -> void:
	if _collected:
		return
	
	_collected = true
	collected.emit()
	
	# Collection animation - expand and fade
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector3(2.0, 2.0, 2.0), 0.2)
	tween.tween_property(_material, "emission_energy_multiplier", 10.0, 0.2)
	tween.tween_property(_glow_material, "albedo_color:a", 0.0, 0.2)
	
	tween.chain().tween_property(self, "scale", Vector3.ZERO, 0.1)
	tween.tween_callback(queue_free)

static func create(pos: Vector3) -> Booster:
	var booster = Booster.new()
	booster.position = pos
	return booster
