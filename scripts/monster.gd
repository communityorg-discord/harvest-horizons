extends CharacterBody3D
## Slime monster. Wanders idly when the player is far; chases when in range.
## Touches the player → damages on a 1-second cooldown. Takes damage from
## player.take_damage_to_nearest() (which the player calls when swinging
## the sword).

class_name Monster

@export var max_hp: int = 30
@export var contact_damage: int = 5
@export var move_speed: float = 2.5
@export var detect_range: float = 8.0
@export var attack_range: float = 1.0

const BODY_COLOR := Color(0.40, 0.74, 0.30)
const FLASH_COLOR := Color(1.0, 0.30, 0.30)

var hp: int = 30
var _player: CharacterBody3D
var _attack_cooldown: float = 0.0
var _flash_t: float = 0.0
var _wander_dir: Vector3 = Vector3.ZERO
var _wander_t: float = 0.0
var _bob_t: float = 0.0
var _mesh: MeshInstance3D
var _mat: StandardMaterial3D

func _ready() -> void:
	add_to_group("monster")
	hp = max_hp
	_build_visual()
	# Find the player even if added later
	await get_tree().process_frame
	_player = get_tree().get_first_node_in_group("player")

func _build_visual() -> void:
	_mesh = MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.45
	sm.height = 0.7
	sm.radial_segments = 14
	sm.rings = 7
	_mesh.mesh = sm
	_mesh.scale = Vector3(1.0, 0.7, 1.0)
	_mesh.position = Vector3(0, 0.32, 0)
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = BODY_COLOR
	_mat.roughness = 0.4
	_mat.emission_enabled = true
	_mat.emission = Color(0.20, 0.42, 0.18)
	_mat.emission_energy_multiplier = 0.4
	_mesh.material_override = _mat
	add_child(_mesh)
	# Eyes
	for sx in [-0.12, 0.12]:
		var eye := MeshInstance3D.new()
		var em := SphereMesh.new()
		em.radius = 0.05
		em.height = 0.10
		eye.mesh = em
		eye.position = Vector3(sx, 0.45, 0.30)
		var emat := StandardMaterial3D.new()
		emat.albedo_color = Color.BLACK
		eye.material_override = emat
		_mesh.add_child(eye)
	# Collision
	var col := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.height = 0.7
	shape.radius = 0.35
	col.shape = shape
	col.position = Vector3(0, 0.35, 0)
	add_child(col)

func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y -= 18.0 * delta
	else:
		velocity.y = 0.0

	if _player != null and is_instance_valid(_player):
		var to_player: Vector3 = _player.global_position - global_position
		to_player.y = 0
		var dist: float = to_player.length()
		if dist < detect_range:
			# Chase
			var dir: Vector3 = to_player.normalized()
			velocity.x = dir.x * move_speed
			velocity.z = dir.z * move_speed
			if dist < attack_range and _attack_cooldown <= 0.0:
				_strike_player()
		else:
			_wander(delta)
	else:
		_wander(delta)

	move_and_slide()
	_attack_cooldown = max(0.0, _attack_cooldown - delta)

	# Cute hop
	_bob_t += delta * 4.0
	if _mesh != null:
		_mesh.position.y = 0.32 + abs(sin(_bob_t)) * 0.12

	# Flash recovery
	if _flash_t > 0.0:
		_flash_t -= delta
		var t: float = clamp(_flash_t / 0.18, 0.0, 1.0)
		_mat.albedo_color = BODY_COLOR.lerp(FLASH_COLOR, t)

func _wander(delta: float) -> void:
	_wander_t -= delta
	if _wander_t <= 0.0:
		_wander_t = randf_range(1.5, 4.0)
		var a: float = randf() * TAU
		_wander_dir = Vector3(cos(a), 0, sin(a))
	velocity.x = _wander_dir.x * (move_speed * 0.4)
	velocity.z = _wander_dir.z * (move_speed * 0.4)

func _strike_player() -> void:
	GameState.damage(contact_damage)
	_attack_cooldown = 1.0

func take_damage(amount: int) -> void:
	hp -= amount
	_flash_t = 0.18
	# Floating damage number above the slime
	DamageNumber.spawn(get_tree().current_scene, global_position + Vector3(0, 1.0, 0),
		"-%d" % amount, Color(1.0, 0.85, 0.4))
	if hp <= 0:
		_die()

func _die() -> void:
	if has_node("/root/GameState"):
		GameState.set_meta("monster_kills", int(GameState.get_meta("monster_kills", 0)) + 1)
	# Drop slime gel near the body (1-2 with light scatter)
	var n := 1 + (randi() % 2)
	for i in range(n):
		var jitter := Vector3(randf_range(-0.4, 0.4), 0, randf_range(-0.4, 0.4))
		ItemPickup.spawn(get_tree().current_scene, global_position + jitter,
			"slime_gel", Color(0.42, 0.78, 0.32))
	queue_free()
