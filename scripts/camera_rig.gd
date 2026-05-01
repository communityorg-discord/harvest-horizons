extends Node3D
## Isometric ¾ camera rig. Smoothly follows a target on the XZ plane.
## Pitch ~30° from horizontal, yaw 45° (true isometric vibe — the angle
## the concept-art screenshots use).

@export var target_path: NodePath
@export var follow_speed: float = 8.0
@export var distance: float = 18.0
@export var pitch_deg: float = 35.0  # degrees down from horizontal
@export var yaw_deg: float = 45.0    # degrees clockwise from -Z

@onready var _camera: Camera3D = $Camera3D
var _target: Node3D
var _offset: Vector3

func _ready() -> void:
	if target_path != NodePath(""):
		_target = get_node_or_null(target_path) as Node3D
	# Compute the camera's offset from the rig origin so it sits up & back
	# along the chosen yaw/pitch.
	var pitch := deg_to_rad(pitch_deg)
	var yaw := deg_to_rad(yaw_deg)
	_offset = Vector3(
		sin(yaw) * cos(pitch),
		sin(pitch),
		cos(yaw) * cos(pitch)
	) * distance
	_camera.position = _offset
	_camera.look_at(global_position, Vector3.UP)

func _process(delta: float) -> void:
	if _target == null:
		return
	var goal: Vector3 = _target.global_position
	global_position = global_position.lerp(goal, clamp(follow_speed * delta, 0.0, 1.0))
	# Keep camera looking at rig origin (= target) regardless of any drift.
	_camera.look_at(global_position, Vector3.UP)
