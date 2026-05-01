extends Node3D
## Isometric ¾ camera rig with right-click rotation.
## - Smoothly follows the target on the XZ plane.
## - Right-mouse drag rotates yaw + pitch around the player.
## - Mouse wheel zooms in / out within sane bounds.

@export var target_path: NodePath
@export var follow_speed: float = 8.0
@export var distance: float = 18.0
@export var pitch_deg: float = 35.0
@export var yaw_deg: float = 45.0
@export var min_distance: float = 8.0
@export var max_distance: float = 32.0
@export var min_pitch_deg: float = 15.0
@export var max_pitch_deg: float = 75.0
@export var rotate_sensitivity: float = 0.30
@export var zoom_step: float = 1.5

@onready var _camera: Camera3D = $Camera3D
var _target: Node3D
var _rotating: bool = false

func _ready() -> void:
	if target_path != NodePath(""):
		_target = get_node_or_null(target_path) as Node3D
	_recompute_offset()

func _recompute_offset() -> void:
	var pitch := deg_to_rad(pitch_deg)
	var yaw := deg_to_rad(yaw_deg)
	var offset := Vector3(
		sin(yaw) * cos(pitch),
		sin(pitch),
		cos(yaw) * cos(pitch)
	) * distance
	_camera.position = offset
	# Camera "size" controls orthographic zoom; scale with distance for parity
	if _camera.projection == Camera3D.PROJECTION_ORTHOGONAL:
		_camera.size = distance * 0.9
	_camera.look_at(global_position, Vector3.UP)

func _process(delta: float) -> void:
	if _target == null:
		return
	global_position = global_position.lerp(_target.global_position, clamp(follow_speed * delta, 0.0, 1.0))
	_camera.look_at(global_position, Vector3.UP)

func _unhandled_input(event: InputEvent) -> void:
	# Right-click to rotate
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_rotating = event.pressed
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if event.pressed else Input.MOUSE_MODE_VISIBLE)
			get_viewport().set_input_as_handled()
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			distance = clampf(distance - zoom_step, min_distance, max_distance)
			_recompute_offset()
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			distance = clampf(distance + zoom_step, min_distance, max_distance)
			_recompute_offset()
	elif event is InputEventMouseMotion and _rotating:
		yaw_deg = wrapf(yaw_deg + event.relative.x * rotate_sensitivity, 0.0, 360.0)
		pitch_deg = clampf(pitch_deg - event.relative.y * rotate_sensitivity, min_pitch_deg, max_pitch_deg)
		_recompute_offset()
