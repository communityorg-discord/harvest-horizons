extends CharacterBody3D
## Top-down WASD movement. Movement is in the XZ plane; Y is gravity.
## Pressing `use_tool` (E or Space) applies the currently selected hotbar tool
## to the soil tile in front of the player.

@export var speed: float = 6.0
@export var gravity: float = 18.0
@export var farm_grid_path: NodePath

@onready var _farm_grid: Node = get_node_or_null(farm_grid_path)

var _facing: Vector3 = Vector3.FORWARD

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
	# Apply to the tile one step ahead of the player along facing direction.
	var probe: Vector3 = global_position + _facing * 1.0
	_farm_grid.use_tool(GameState.current_tool, probe)
