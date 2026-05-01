extends Area3D
## Generic walk-into-it pickup. Configure item_id + tint before adding to tree.
##   var p := ItemPickup.spawn(scene, pos, "slime_gel", Color.GREEN)

class_name ItemPickup

@export var item_id: String = "slime_gel"
@export var item_color: Color = Color(0.42, 0.78, 0.32)
@export var quantity: int = 1

var _bob_t: float = randf_range(0.0, TAU)
var _picked: bool = false
var _mesh: MeshInstance3D

static func spawn(parent: Node, pos: Vector3, id: String, tint: Color, qty: int = 1) -> ItemPickup:
	var p := ItemPickup.new()
	p.item_id = id
	p.item_color = tint
	p.quantity = qty
	p.position = pos
	parent.add_child(p)
	return p

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_build_visual()
	_build_collision()

func _build_visual() -> void:
	_mesh = MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.18
	sm.height = 0.36
	sm.radial_segments = 12
	sm.rings = 6
	_mesh.mesh = sm
	_mesh.position = Vector3(0, 0.25, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = item_color
	mat.emission_enabled = true
	mat.emission = item_color
	mat.emission_energy_multiplier = 0.8
	_mesh.material_override = mat
	add_child(_mesh)
	# Soft glow light
	var light := OmniLight3D.new()
	light.position = Vector3(0, 0.25, 0)
	light.light_color = item_color
	light.light_energy = 0.6
	light.omni_range = 2.5
	add_child(light)

func _build_collision() -> void:
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.6
	col.shape = shape
	add_child(col)

func _process(delta: float) -> void:
	_bob_t += delta * 4.0
	if _mesh != null:
		_mesh.position.y = 0.25 + sin(_bob_t) * 0.08
		_mesh.rotation.y += delta * 2.0

func _on_body_entered(body: Node) -> void:
	if _picked:
		return
	if body is CharacterBody3D:
		_picked = true
		GameState.add_item(item_id, quantity)
		queue_free()
