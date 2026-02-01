@tool
extends Area3D
class_name Coin

# === CONFIGURATION ===
@export var coin_value := 1
@export_group("Appearance")
@export var coin_radius := 0.4:
	set(v):
		coin_radius = v
		if Engine.is_editor_hint(): _rebuild()
@export var coin_thickness := 0.1:
	set(v):
		coin_thickness = v
		if Engine.is_editor_hint(): _rebuild()
@export var coin_color := Color(1.0, 0.85, 0.2):  # Gold
	set(v):
		coin_color = v
		if Engine.is_editor_hint(): _update_materials()
@export var emission_energy := 1.5:
	set(v):
		emission_energy = v
		if Engine.is_editor_hint(): _update_materials()
@export var coin_texture: Texture2D:
	set(v):
		coin_texture = v
		if Engine.is_editor_hint(): _update_materials()

@export_group("Animation")
@export var rotate_speed := 2.0
@export var bob_speed := 2.0
@export var bob_height := 0.15

@export_group("Light")
@export var light_enabled := true:
	set(v):
		light_enabled = v
		if Engine.is_editor_hint(): _rebuild()
@export var light_color := Color(1.0, 0.9, 0.5):
	set(v):
		light_color = v
		if _light: _light.light_color = v
@export var light_energy := 0.6:
	set(v):
		light_energy = v
		if _light: _light.light_energy = v
@export var light_range := 2.5:
	set(v):
		light_range = v
		if _light: _light.omni_range = v

# Internal
var _mesh: MeshInstance3D
var _light: OmniLight3D
var _material: StandardMaterial3D
var _initial_y := 0.0
var _time := 0.0
var _collected := false

signal collected(value: int)

func _ready() -> void:
	_initial_y = position.y
	_rebuild()
	
	# Connect signal for collection
	body_entered.connect(_on_body_entered)

func _rebuild() -> void:
	# Clear existing
	for child in get_children():
		child.queue_free()
	
	_create_mesh()
	_create_collision()
	if light_enabled:
		_create_light()

func _create_mesh() -> void:
	_mesh = MeshInstance3D.new()
	_mesh.name = "CoinMesh"
	
	# Use cylinder for coin shape
	var mesh = CylinderMesh.new()
	mesh.top_radius = coin_radius
	mesh.bottom_radius = coin_radius
	mesh.height = coin_thickness
	_mesh.mesh = mesh
	
	# Rotate to face player (coins are vertical)
	_mesh.rotation.x = PI / 2
	
	_create_material()
	_mesh.material_override = _material
	
	add_child(_mesh)

func _create_material() -> void:
	_material = StandardMaterial3D.new()
	_material.albedo_color = coin_color
	
	# Apply texture if provided
	if coin_texture:
		_material.albedo_texture = coin_texture
	
	# Emission for glow
	_material.emission_enabled = true
	_material.emission = coin_color
	_material.emission_energy_multiplier = emission_energy
	
	# Metallic look
	_material.metallic = 0.8
	_material.roughness = 0.3

func _update_materials() -> void:
	if _material:
		_material.albedo_color = coin_color
		_material.emission = coin_color
		_material.emission_energy_multiplier = emission_energy
		if coin_texture:
			_material.albedo_texture = coin_texture

func _create_collision() -> void:
	var collision = CollisionShape3D.new()
	collision.name = "CoinCollision"
	var shape = CylinderShape3D.new()
	shape.radius = coin_radius * 1.2  # Slightly larger for easier collection
	shape.height = coin_thickness * 2
	collision.shape = shape
	collision.rotation.x = PI / 2
	add_child(collision)

func _create_light() -> void:
	_light = OmniLight3D.new()
	_light.name = "CoinLight"
	_light.light_color = light_color
	_light.light_energy = light_energy
	_light.omni_range = light_range
	_light.omni_attenuation = 1.5
	_light.shadow_enabled = false
	add_child(_light)

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	if _collected:
		return
	
	_time += delta
	
	# Rotate
	if _mesh:
		_mesh.rotation.y += rotate_speed * delta
	
	# Bob up and down
	position.y = _initial_y + sin(_time * bob_speed) * bob_height

func _on_body_entered(body: Node3D) -> void:
	if _collected:
		return
	
	# Check if it's the player
	if body.is_in_group("player") or body.name == "Player":
		collect()

func collect() -> void:
	if _collected:
		return
	
	_collected = true
	collected.emit(coin_value)
	
	# Collection animation
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector3(1.5, 1.5, 1.5), 0.15)
	tween.tween_property(_material, "emission_energy_multiplier", 5.0, 0.15)
	
	tween.chain().tween_property(self, "scale", Vector3.ZERO, 0.1)
	tween.tween_callback(queue_free)

# === FACTORY ===
static func create(pos: Vector3, value: int = 1):
	var coin = Coin.new()
	coin.position = pos
	coin.coin_value = value
	return coin
