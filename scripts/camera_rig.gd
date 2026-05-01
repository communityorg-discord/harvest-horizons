extends Node3D
## Tilted top-down camera rig. Smoothly follows a target node on the XZ plane.

@export var target_path: NodePath
@export var follow_speed: float = 8.0
@export var offset: Vector3 = Vector3(0.0, 0.0, 0.0)

var _target: Node3D

func _ready() -> void:
	if target_path != NodePath(""):
		_target = get_node_or_null(target_path) as Node3D

func _process(delta: float) -> void:
	if _target == null:
		return
	var goal: Vector3 = _target.global_position + offset
	global_position = global_position.lerp(goal, clamp(follow_speed * delta, 0.0, 1.0))
