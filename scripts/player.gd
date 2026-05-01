extends CharacterBody3D
## Top-down WASD movement + procedurally built stylized character.
## Pressing `use_tool` (E or Space) applies the currently selected hotbar tool
## to the soil tile in front of the player.

@export var speed: float = 6.0
@export var gravity: float = 18.0
@export var farm_grid_path: NodePath
@export var rotate_speed: float = 12.0

@onready var _farm_grid: Node = get_node_or_null(farm_grid_path)
@onready var _visual: Node3D = $Visual

var _facing: Vector3 = Vector3.BACK  # face the camera at start
var _bob_t: float = 0.0

# ────────────────────────────────────────────────────────────────────────────
# Character build (procedural)

const SKIN       := Color(0.97, 0.83, 0.70)
const HAIR       := Color(0.42, 0.27, 0.16)
const HAT_STRAW  := Color(0.93, 0.78, 0.42)
const HAT_BAND   := Color(0.62, 0.32, 0.22)
const SHIRT      := Color(0.18, 0.42, 0.65)
const PANTS      := Color(0.32, 0.22, 0.14)
const SHOES      := Color(0.18, 0.12, 0.07)

func _ready() -> void:
	_build_character()

func _build_character() -> void:
	# Legs
	_add_box(_visual, Vector3(-0.13, 0.30, 0), Vector3(0.18, 0.55, 0.18), PANTS)
	_add_box(_visual, Vector3( 0.13, 0.30, 0), Vector3(0.18, 0.55, 0.18), PANTS)
	# Shoes
	_add_box(_visual, Vector3(-0.13, 0.045, 0.04), Vector3(0.20, 0.10, 0.26), SHOES)
	_add_box(_visual, Vector3( 0.13, 0.045, 0.04), Vector3(0.20, 0.10, 0.26), SHOES)
	# Body
	_add_box(_visual, Vector3(0, 0.85, 0), Vector3(0.55, 0.55, 0.36), SHIRT)
	# Arms (slightly forward + outward)
	_add_box(_visual, Vector3(-0.36, 0.85, 0), Vector3(0.16, 0.55, 0.20), SHIRT)
	_add_box(_visual, Vector3( 0.36, 0.85, 0), Vector3(0.16, 0.55, 0.20), SHIRT)
	# Hands
	_add_sphere(_visual, Vector3(-0.36, 0.55, 0), 0.10, SKIN)
	_add_sphere(_visual, Vector3( 0.36, 0.55, 0), 0.10, SKIN)
	# Head
	_add_sphere(_visual, Vector3(0, 1.30, 0), 0.27, SKIN)
	# Hair (back tuft)
	_add_sphere(_visual, Vector3(0, 1.36, -0.06), 0.28, HAIR)
	# Hat brim + crown
	_add_cylinder(_visual, Vector3(0, 1.50, 0), 0.45, 0.04, HAT_STRAW)
	_add_cylinder(_visual, Vector3(0, 1.58, 0), 0.24, 0.16, HAT_STRAW)
	_add_cylinder(_visual, Vector3(0, 1.52, 0), 0.245, 0.04, HAT_BAND)
	# Eyes (look forward — toward -Z which is the camera-back direction in our scene)
	_add_sphere(_visual, Vector3(-0.09, 1.32, 0.24), 0.035, Color.BLACK)
	_add_sphere(_visual, Vector3( 0.09, 1.32, 0.24), 0.035, Color.BLACK)

func _add_box(parent: Node, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	m.mesh = bm
	m.position = pos
	m.material_override = _mat(color)
	parent.add_child(m)
	return m

func _add_sphere(parent: Node, pos: Vector3, radius: float, color: Color) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0
	sm.radial_segments = 16
	sm.rings = 8
	m.mesh = sm
	m.position = pos
	m.material_override = _mat(color)
	parent.add_child(m)
	return m

func _add_cylinder(parent: Node, pos: Vector3, radius: float, height: float, color: Color) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = radius
	cm.bottom_radius = radius
	cm.height = height
	cm.radial_segments = 18
	m.mesh = cm
	m.position = pos
	m.material_override = _mat(color)
	parent.add_child(m)
	return m

func _mat(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.85
	mat.metallic = 0.0
	return mat

# ────────────────────────────────────────────────────────────────────────────
# Movement

func _physics_process(delta: float) -> void:
	var input := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	var dir := Vector3(input.x, 0.0, input.y)
	if dir.length() > 1.0:
		dir = dir.normalized()

	velocity.x = dir.x * speed
	velocity.z = dir.z * speed

	if dir.length_squared() > 0.01:
		_facing = dir.normalized()
		# Subtle walk bob
		_bob_t += delta * 12.0
		_visual.position.y = abs(sin(_bob_t)) * 0.05
	else:
		_visual.position.y = lerp(_visual.position.y, 0.0, 8.0 * delta)

	# Rotate visual to face movement direction (smoothed).
	var target_yaw: float = atan2(_facing.x, _facing.z)
	_visual.rotation.y = lerp_angle(_visual.rotation.y, target_yaw, rotate_speed * delta)

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("use_tool"):
		_use_tool()

func _use_tool() -> void:
	if _farm_grid == null:
		return
	var probe: Vector3 = global_position + _facing * 1.0
	_farm_grid.use_tool(GameState.current_tool, probe)
