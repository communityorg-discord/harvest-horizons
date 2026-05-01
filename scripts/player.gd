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
	add_to_group("player")
	_build_character()
	GameState.hp_changed.connect(_on_hp_changed)

var _last_hp: int = -1
func _on_hp_changed(value: int, _max_val: int) -> void:
	if _last_hp >= 0 and value < _last_hp:
		var lost: int = _last_hp - value
		DamageNumber.spawn(get_tree().current_scene,
			global_position + Vector3(0, 1.8, 0),
			"-%d" % lost, Color(1.0, 0.35, 0.35))
		# Brief red flash on the body meshes
		_flash_player_red()
	_last_hp = value

func _flash_player_red() -> void:
	if _visual == null:
		return
	for child in _visual.get_children():
		if child is MeshInstance3D:
			var mi: MeshInstance3D = child
			var mat: StandardMaterial3D = mi.material_override as StandardMaterial3D
			if mat == null:
				continue
			var orig: Color = mat.albedo_color
			mat.albedo_color = Color(1.0, 0.35, 0.35)
			var tw := create_tween()
			tw.tween_property(mat, "albedo_color", orig, 0.20)

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
	# Sword (hotbar slot 4) → swing at the nearest monster in range.
	if GameState.current_tool == 4:
		_swing_sword()
		return
	# Otherwise use the tool on the farm grid (till / water / plant / harvest).
	if _farm_grid == null:
		return
	var probe: Vector3 = global_position + _facing * 1.0
	_farm_grid.use_tool(GameState.current_tool, probe)

const SWORD_RANGE := 2.0
const SWORD_DAMAGE := 20

func _swing_sword() -> void:
	# Visual swing arc fires regardless of having a sword (so the player gets
	# feedback). Damage only applies if you actually have a sword.
	_spawn_swing_arc()
	if GameState.item_count("rusted_sword") <= 0:
		return
	var nearest: Node = null
	var nearest_d: float = 999.0
	for m in get_tree().get_nodes_in_group("monster"):
		if not (m is Node3D):
			continue
		var d: float = (m as Node3D).global_position.distance_to(global_position)
		if d < nearest_d and d < SWORD_RANGE:
			nearest = m
			nearest_d = d
	if nearest == null:
		return
	if nearest.has_method("take_damage"):
		nearest.take_damage(SWORD_DAMAGE)
	# Tick down sword durability — at 50 kills the rusted sword snaps.
	var kills: int = int(GameState.get_meta("rusted_sword_kills", 0)) + 1
	GameState.set_meta("rusted_sword_kills", kills)
	if kills >= 50:
		GameState.remove_item("rusted_sword", 1)
		GameState.set_meta("rusted_sword_kills", 0)

# Quick white-arc flash in front of the player that fades over ~0.18s.
func _spawn_swing_arc() -> void:
	var arc := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.6, 0.04, 0.4)
	arc.mesh = bm
	# Position 1m in front of player, hip-high, oriented along facing
	var ahead: Vector3 = global_position + Vector3(0, 1.0, 0) + _facing * 1.0
	arc.global_position = ahead
	arc.look_at(arc.global_position + _facing.cross(Vector3.UP).normalized(), Vector3.UP)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1, 1, 1, 0.95)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.95, 0.6)
	mat.emission_energy_multiplier = 2.5
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	arc.material_override = mat
	get_tree().current_scene.add_child(arc)
	# Tween the alpha + scale, then free
	var tw := arc.create_tween()
	tw.set_parallel(true)
	tw.tween_property(arc, "scale", Vector3(1.4, 1.0, 1.0), 0.18)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.18)
	tw.chain().tween_callback(arc.queue_free)
