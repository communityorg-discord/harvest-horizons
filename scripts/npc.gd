extends StaticBody3D
## Procedural NPC: simple stylized character + name label + interaction zone.
## Walk close, press [E], dialogue plays via the scene's DialogueBox.
##
## Configure via setters before adding to tree:
##   var npc = NPC.new()
##   npc.npc_name = "Mayor"
##   npc.shirt_color = Color.PURPLE
##   npc.lines = [{"speaker": "Mayor", "text": "..."}]
##   npc.position = Vector3(...)
##   parent.add_child(npc)

class_name NPC

@export var npc_name: String = "Villager"
@export var shirt_color: Color = Color(0.42, 0.32, 0.62)
@export var hat_color: Color = Color(0.62, 0.32, 0.22)
@export var hair_color: Color = Color(0.30, 0.20, 0.12)
@export var skin_color: Color = Color(0.97, 0.83, 0.70)

# Dialogue lines to fire when the player presses interact while in range.
# Each line: {"speaker": "...", "text": "...", "color": Color}
@export var lines: Array = []

# Set true if you want the dialogue to fire automatically when the player
# walks into range (used for first-time greetings).
@export var auto_play: bool = false

# Optional: callback to fire after the dialogue finishes.
# (Use signal `dialogue_finished` if you want signal-based instead.)
signal dialogue_finished

var _player_in_range: bool = false
var _played_already: bool = false
var _interact_area: Area3D
var _prompt: Label3D
var _name_label: Label3D

func _ready() -> void:
	_build_visual()
	_build_collision()
	_build_interact_area()

func _build_visual() -> void:
	# Legs
	_box(Vector3(-0.13, 0.30, 0), Vector3(0.18, 0.55, 0.18), Color(0.28, 0.20, 0.13))
	_box(Vector3( 0.13, 0.30, 0), Vector3(0.18, 0.55, 0.18), Color(0.28, 0.20, 0.13))
	# Body
	_box(Vector3(0, 0.85, 0), Vector3(0.55, 0.55, 0.36), shirt_color)
	# Arms
	_box(Vector3(-0.36, 0.85, 0), Vector3(0.16, 0.55, 0.20), shirt_color)
	_box(Vector3( 0.36, 0.85, 0), Vector3(0.16, 0.55, 0.20), shirt_color)
	# Hands
	_sphere(Vector3(-0.36, 0.55, 0), 0.10, skin_color)
	_sphere(Vector3( 0.36, 0.55, 0), 0.10, skin_color)
	# Head
	_sphere(Vector3(0, 1.30, 0), 0.27, skin_color)
	# Hair
	_sphere(Vector3(0, 1.36, -0.06), 0.28, hair_color)
	# Hat brim + crown
	_cyl(Vector3(0, 1.50, 0), 0.45, 0.04, hat_color)
	_cyl(Vector3(0, 1.58, 0), 0.24, 0.16, hat_color)
	# Eyes
	_sphere(Vector3(-0.09, 1.32, 0.24), 0.035, Color.BLACK)
	_sphere(Vector3( 0.09, 1.32, 0.24), 0.035, Color.BLACK)
	# Floating name label
	_name_label = Label3D.new()
	_name_label.text = npc_name
	_name_label.font_size = 48
	_name_label.outline_size = 8
	_name_label.modulate = Color(1.0, 0.95, 0.7)
	_name_label.position = Vector3(0, 2.1, 0)
	_name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_name_label.no_depth_test = true
	add_child(_name_label)

func _build_collision() -> void:
	# Solid body so the player bumps into the NPC instead of walking through.
	var col := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.height = 1.6
	shape.radius = 0.35
	col.shape = shape
	col.position = Vector3(0, 0.8, 0)
	add_child(col)

func _build_interact_area() -> void:
	_interact_area = Area3D.new()
	_interact_area.position = Vector3(0, 0.8, 0)
	add_child(_interact_area)
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 1.4
	col.shape = shape
	_interact_area.add_child(col)
	_interact_area.body_entered.connect(_on_body_entered)
	_interact_area.body_exited.connect(_on_body_exited)

	# "Press [E]" prompt
	_prompt = Label3D.new()
	_prompt.text = "Press [E] to talk"
	_prompt.font_size = 36
	_prompt.outline_size = 6
	_prompt.modulate = Color(1.0, 0.95, 0.7)
	_prompt.position = Vector3(0, 1.7, 0)
	_prompt.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_prompt.no_depth_test = true
	_prompt.visible = false
	add_child(_prompt)

func _on_body_entered(body: Node) -> void:
	if body is CharacterBody3D:
		_player_in_range = true
		if auto_play and not _played_already:
			_played_already = true
			_play_dialogue()
		else:
			_prompt.visible = true

func _on_body_exited(body: Node) -> void:
	if body is CharacterBody3D:
		_player_in_range = false
		_prompt.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if not _player_in_range:
		return
	if event.is_action_pressed("use_tool"):
		get_viewport().set_input_as_handled()
		_play_dialogue()

func _play_dialogue() -> void:
	if lines.is_empty():
		return
	_prompt.visible = false
	# Find the DialogueBox in the current scene.
	var scene := get_tree().current_scene
	var box := scene.find_child("DialogueBox", true, false)
	if box == null:
		push_warning("NPC '%s': no DialogueBox in scene." % npc_name)
		return
	box.show_lines(lines)
	if not box.finished.is_connected(_on_dialogue_finished):
		box.finished.connect(_on_dialogue_finished, CONNECT_ONE_SHOT)

func _on_dialogue_finished() -> void:
	dialogue_finished.emit()

# Mesh helpers (mirror player.gd for consistency)
func _box(pos: Vector3, size: Vector3, color: Color) -> void:
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	m.mesh = bm
	m.position = pos
	m.material_override = _mat(color)
	add_child(m)

func _sphere(pos: Vector3, radius: float, color: Color) -> void:
	var m := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0
	sm.radial_segments = 14
	sm.rings = 7
	m.mesh = sm
	m.position = pos
	m.material_override = _mat(color)
	add_child(m)

func _cyl(pos: Vector3, radius: float, height: float, color: Color) -> void:
	var m := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = radius
	cm.bottom_radius = radius
	cm.height = height
	cm.radial_segments = 16
	m.mesh = cm
	m.position = pos
	m.material_override = _mat(color)
	add_child(m)

func _mat(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.85
	return mat
