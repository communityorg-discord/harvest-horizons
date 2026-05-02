extends Area3D
## Glowing lantern lying on the ground. Walk into it → adds 1 lantern to
## inventory, plays a tiny float animation, then despawns.

var _picked: bool = false
var _bob_t: float = 0.0
var _glow: MeshInstance3D
var _label: Label3D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_build_visual()
	_build_collision()

func _build_collision() -> void:
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.7
	col.shape = shape
	add_child(col)

func _build_visual() -> void:
	# Body of the lantern (small box)
	var body := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.30, 0.36, 0.30)
	body.mesh = bm
	body.position = Vector3(0, 0.18, 0)
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = Color(0.30, 0.20, 0.12)
	body.material_override = bmat
	add_child(body)
	# Glow sphere
	_glow = MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.16
	sm.height = 0.32
	_glow.mesh = sm
	_glow.position = Vector3(0, 0.20, 0)
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color(1.0, 0.92, 0.55)
	gmat.emission_enabled = true
	gmat.emission = Color(1.0, 0.78, 0.38)
	gmat.emission_energy_multiplier = 3.0
	_glow.material_override = gmat
	add_child(_glow)
	# Floating label
	_label = Label3D.new()
	_label.text = "★ Lantern"
	_label.font_size = 32
	_label.outline_size = 6
	_label.modulate = Color(1.0, 0.95, 0.7)
	_label.position = Vector3(0, 0.85, 0)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.no_depth_test = true
	add_child(_label)
	# Real point light so it actually glows in the world
	var light := OmniLight3D.new()
	light.position = Vector3(0, 0.4, 0)
	light.light_color = Color(1.0, 0.85, 0.55)
	light.light_energy = 1.6
	light.omni_range = 4.5
	add_child(light)

func _process(delta: float) -> void:
	_bob_t += delta * 3.0
	if _glow != null:
		_glow.position.y = 0.2 + sin(_bob_t) * 0.05

func _on_body_entered(body: Node) -> void:
	if _picked:
		return
	if body is CharacterBody3D:
		_picked = true
		GameState.add_item("lantern", 1)
		queue_free()
