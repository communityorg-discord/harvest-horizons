extends Area3D
## Bed: walk into the area, press [E] / [Space], the player sleeps and the
## game saves. Per docs/DESIGN.md the bed is the only save point.

@export_node_path("Node3D") var bedside_marker: NodePath

var _player: CharacterBody3D = null
var _prompt: Label3D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_build_prompt()

func _build_prompt() -> void:
	_prompt = Label3D.new()
	_prompt.text = "Press [E] to sleep"
	_prompt.font_size = 64
	_prompt.outline_size = 12
	_prompt.modulate = Color(1.0, 0.95, 0.7)
	_prompt.position = Vector3(0, 1.6, 0)
	_prompt.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_prompt.no_depth_test = true
	_prompt.visible = false
	add_child(_prompt)

func _on_body_entered(body: Node) -> void:
	if body is CharacterBody3D:
		_player = body
		_prompt.visible = true

func _on_body_exited(body: Node) -> void:
	if body == _player:
		_player = null
		_prompt.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if _player == null:
		return
	if event.is_action_pressed("use_tool"):
		get_viewport().set_input_as_handled()
		_sleep()

func _sleep() -> void:
	GameState.sleep()
	# Move the player to the bedside marker so they wake up next to the bed.
	if bedside_marker != NodePath(""):
		var marker := get_node_or_null(bedside_marker) as Node3D
		if marker != null and _player != null:
			_player.global_position = marker.global_position
