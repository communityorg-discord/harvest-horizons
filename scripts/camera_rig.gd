extends Node2D
## 2D camera follow rig. Smoothly trails the target with optional zoom.

@export var target_path: NodePath
@export var follow_speed: float = 8.0

@onready var _camera: Camera2D = $Camera2D
var _target: Node2D

func _ready() -> void:
	if target_path != NodePath(""):
		_target = get_node_or_null(target_path) as Node2D

func _process(delta: float) -> void:
	if _target == null:
		return
	global_position = global_position.lerp(
		_target.global_position,
		clamp(follow_speed * delta, 0.0, 1.0)
	)
