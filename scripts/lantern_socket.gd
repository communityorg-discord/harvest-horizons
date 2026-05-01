extends Area3D
## Empty lantern bracket. Walk close while holding a lantern, press [E] →
## consumes 1 lantern from inventory, fills the socket. Filled sockets glow
## (real OmniLight3D) and report progress to the Light the Farm quest.

signal placed

@export var quest_id: String = "light_the_farm"

var _filled: bool = false
var _player_in_range: bool = false
var _empty_visual: Node3D
var _filled_visual: Node3D
var _prompt: Label3D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_build_collision()
	_build_visual()
	_refresh()

func _build_collision() -> void:
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 1.4
	col.shape = shape
	add_child(col)

func _build_visual() -> void:
	# A sturdy little wooden post that stays regardless of state
	var post := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.16, 1.4, 0.16)
	post.mesh = bm
	post.position = Vector3(0, 0.7, 0)
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = Color(0.30, 0.20, 0.12)
	post.material_override = pmat
	add_child(post)
	# Solid collider for the post itself so the player bumps into it
	var body := StaticBody3D.new()
	body.position = Vector3(0, 0.7, 0)
	add_child(body)
	var bcol := CollisionShape3D.new()
	var bshape := BoxShape3D.new()
	bshape.size = Vector3(0.20, 1.4, 0.20)
	bcol.shape = bshape
	body.add_child(bcol)
	# Empty bracket — small dark frame
	_empty_visual = Node3D.new()
	add_child(_empty_visual)
	var bracket := MeshInstance3D.new()
	var brm := BoxMesh.new()
	brm.size = Vector3(0.32, 0.32, 0.32)
	bracket.mesh = brm
	bracket.position = Vector3(0, 1.55, 0)
	var brmat := StandardMaterial3D.new()
	brmat.albedo_color = Color(0.18, 0.12, 0.08)
	brmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	brmat.albedo_color.a = 0.35
	bracket.material_override = brmat
	_empty_visual.add_child(bracket)
	# Filled — glowing lantern + real light
	_filled_visual = Node3D.new()
	add_child(_filled_visual)
	var lbody := MeshInstance3D.new()
	var lbm := BoxMesh.new()
	lbm.size = Vector3(0.28, 0.30, 0.28)
	lbody.mesh = lbm
	lbody.position = Vector3(0, 1.55, 0)
	var lmat := StandardMaterial3D.new()
	lmat.albedo_color = Color(0.30, 0.20, 0.12)
	lbody.material_override = lmat
	_filled_visual.add_child(lbody)
	var glow := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.13
	sm.height = 0.26
	glow.mesh = sm
	glow.position = Vector3(0, 1.55, 0)
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color(1.0, 0.92, 0.55)
	gmat.emission_enabled = true
	gmat.emission = Color(1.0, 0.78, 0.38)
	gmat.emission_energy_multiplier = 3.5
	glow.material_override = gmat
	_filled_visual.add_child(glow)
	var light := OmniLight3D.new()
	light.position = Vector3(0, 1.55, 0)
	light.light_color = Color(1.0, 0.85, 0.55)
	light.light_energy = 1.8
	light.omni_range = 8.0
	_filled_visual.add_child(light)
	# Empty-state prompt
	_prompt = Label3D.new()
	_prompt.text = "Press [E] to place"
	_prompt.font_size = 32
	_prompt.outline_size = 6
	_prompt.modulate = Color(1.0, 0.95, 0.7)
	_prompt.position = Vector3(0, 2.1, 0)
	_prompt.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_prompt.no_depth_test = true
	_prompt.visible = false
	add_child(_prompt)

func _refresh() -> void:
	_empty_visual.visible = not _filled
	_filled_visual.visible = _filled

func _on_body_entered(body: Node) -> void:
	if body is CharacterBody3D:
		_player_in_range = true
		_prompt.visible = not _filled and GameState.item_count("lantern") > 0

func _on_body_exited(body: Node) -> void:
	if body is CharacterBody3D:
		_player_in_range = false
		_prompt.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if _filled or not _player_in_range:
		return
	if event.is_action_pressed("use_tool"):
		if GameState.remove_item("lantern", 1):
			_filled = true
			_refresh()
			_prompt.visible = false
			placed.emit()
			get_viewport().set_input_as_handled()
