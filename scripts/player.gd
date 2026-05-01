extends CharacterBody3D
## Top-down WASD movement. Movement is in the XZ plane; Y is gravity.

@export var speed: float = 6.0
@export var gravity: float = 18.0

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

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	move_and_slide()
