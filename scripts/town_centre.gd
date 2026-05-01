extends Node3D
## Town Centre — placeholder scene reached via the east farm gate.
## Cobble plaza with a fountain, a few stub shop buildings, and a return
## gate going back to the farm. Will be fleshed out properly in a later
## phase (NPCs, real Blacksmith / Inn / Cafe / General Store interiors).

const NATURE := "res://assets/models/nature/"
const SURVIVAL := "res://assets/models/survival/"

const COBBLE     := Color(0.62, 0.58, 0.52)
const COBBLE_DARK:= Color(0.45, 0.42, 0.38)
const STONE      := Color(0.55, 0.52, 0.48)
const FOUNTAIN_WATER := Color(0.25, 0.55, 0.78)
const ROOF_RED   := Color(0.65, 0.30, 0.22)
const ROOF_BLUE  := Color(0.30, 0.42, 0.55)
const ROOF_GREEN := Color(0.32, 0.55, 0.32)
const WOOD       := Color(0.52, 0.36, 0.22)
const WHITE_WALL := Color(0.92, 0.88, 0.78)
const SIGN_BG    := Color(0.78, 0.62, 0.42)

@onready var _player: CharacterBody3D = $Player

func _ready() -> void:
	_build_ground()
	_build_plaza()
	_build_fountain()
	_build_shop(Vector3(-12, 0, -7), ROOF_BLUE,  "BLACKSMITH")
	_build_shop(Vector3( 12, 0, -7), ROOF_RED,   "GENERAL STORE")
	_build_shop(Vector3(-12, 0,  7), ROOF_GREEN, "CAFE")
	_build_shop(Vector3( 12, 0,  7), ROOF_RED,   "INN")
	_build_perimeter_walls()
	_scatter_lampposts()
	_scatter_decor()
	_build_return_gate()
	_build_mayor()
	_handle_intro()

func _build_mayor() -> void:
	var npc := NPC.new()
	npc.npc_name = "Mayor Victor"
	npc.shirt_color = Color(0.32, 0.22, 0.45)  # formal purple
	npc.hat_color   = Color(0.18, 0.10, 0.06)  # top-hat-ish
	npc.hair_color  = Color(0.85, 0.85, 0.85)  # silver
	npc.position = Vector3(0, 0, 5)            # south of fountain, faces player
	npc.lines = [
		{"speaker": "Mayor Victor", "text": "Wait — what?  A visitor?  We haven't had a soul come through Greenfield in years.", "color": Color(0.55, 0.32, 0.62)},
		{"speaker": "Mayor Victor", "text": "Who are you, and what brings you to our valley?", "color": Color(0.55, 0.32, 0.62)},
		{"speaker": "You", "text": "I got a letter — from the Wizard.  He asked me to restore the old farm and help rebuild the town.", "color": Color(0.20, 0.45, 0.65)},
		{"speaker": "Mayor Victor", "text": "The WIZARD?!  He's still alive?  We haven't seen him since the great… flood.", "color": Color(0.55, 0.32, 0.62)},
		{"speaker": "Mayor Victor", "text": "Well.  This changes everything.  Head west out of the plaza — that path leads to the old farm.  The Inn Master Lily said she'd meet you when you arrived.", "color": Color(0.55, 0.32, 0.62)},
		{"speaker": "Mayor Victor", "text": "Take this minimap.  You'll need it.  Welcome to Greenfield Valley, farmer.", "color": Color(0.55, 0.32, 0.62)},
	]
	add_child(npc)
	npc.dialogue_finished.connect(_on_mayor_done)

func _handle_intro() -> void:
	if not GameState.has_meta("intro_pending"):
		return
	if GameState.get_meta("intro_pending") != "town_mayor":
		return
	GameState.remove_meta("intro_pending")
	# Position the player just south of the Mayor so the dialogue flows.
	if _player != null:
		_player.global_position = Vector3(0, 1, 8)
	# Find the Mayor NPC and play its dialogue immediately.
	var mayor := _find_npc("Mayor Victor")
	if mayor != null:
		_play_immediately(mayor)

func _find_npc(npc_name: String) -> Node:
	for child in get_children():
		if child is NPC and (child as NPC).npc_name == npc_name:
			return child
	return null

func _play_immediately(npc: Node) -> void:
	var box := find_child("DialogueBox", true, false)
	if box == null or npc.lines.is_empty():
		return
	box.show_lines(npc.lines)
	if not box.finished.is_connected(npc._on_dialogue_finished):
		box.finished.connect(npc._on_dialogue_finished, CONNECT_ONE_SHOT)

func _on_mayor_done() -> void:
	GameState.complete_quest("intro_mayor")
	GameState.complete_quest("wizard_letter")  # the seeded opening quest

func _mat(color: Color, rough: float = 0.9) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	return m

func _box(pos: Vector3, size: Vector3, color: Color, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.position = pos
	mi.rotation = rot
	mi.material_override = _mat(color)
	add_child(mi)
	return mi

func _add_collider(pos: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	add_child(body)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	return body

# ────────────────────────────────────────────────────────────────────────────
# Ground + plaza tiles

func _build_ground() -> void:
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(160, 160)
	ground.mesh = pm
	ground.material_override = _mat(Color(0.30, 0.48, 0.22), 0.95)
	add_child(ground)
	# Static collider so the player doesn't fall through
	_add_collider(Vector3(0, -0.1, 0), Vector3(160, 0.2, 160))

func _build_plaza() -> void:
	# Cobble plaza centre, 12x12, made from many small tiles for visual rhythm
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var step: float = 1.0
	var x: float = -6
	while x <= 6:
		var z: float = -6
		while z <= 6:
			var c := COBBLE if rng.randf() < 0.7 else COBBLE_DARK
			var t := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(0.95, 0.05, 0.95)
			t.mesh = bm
			t.position = Vector3(x, 0.025, z)
			t.material_override = _mat(c, 0.95)
			add_child(t)
			z += step
		x += step

func _build_fountain() -> void:
	# Round stone basin
	var basin := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 1.4
	cm.bottom_radius = 1.4
	cm.height = 0.6
	basin.mesh = cm
	basin.position = Vector3(0, 0.3, 0)
	basin.material_override = _mat(STONE)
	add_child(basin)
	# Inner water
	var water := MeshInstance3D.new()
	var wm := CylinderMesh.new()
	wm.top_radius = 1.15
	wm.bottom_radius = 1.15
	wm.height = 0.05
	water.mesh = wm
	water.position = Vector3(0, 0.62, 0)
	var wmat := _mat(FOUNTAIN_WATER, 0.2)
	wmat.metallic = 0.3
	water.material_override = wmat
	add_child(water)
	# Centre column
	var col := MeshInstance3D.new()
	var ccm := CylinderMesh.new()
	ccm.top_radius = 0.18
	ccm.bottom_radius = 0.30
	ccm.height = 1.2
	col.mesh = ccm
	col.position = Vector3(0, 1.2, 0)
	col.material_override = _mat(STONE)
	add_child(col)
	# Top bowl
	var top := MeshInstance3D.new()
	var tm := CylinderMesh.new()
	tm.top_radius = 0.65
	tm.bottom_radius = 0.45
	tm.height = 0.20
	top.mesh = tm
	top.position = Vector3(0, 1.85, 0)
	top.material_override = _mat(STONE)
	add_child(top)
	# Collision (treat fountain as solid cylinder)
	var body := StaticBody3D.new()
	body.position = Vector3(0, 0.5, 0)
	add_child(body)
	var ccol := CollisionShape3D.new()
	var cshape := CylinderShape3D.new()
	cshape.radius = 1.4
	cshape.height = 1.2
	ccol.shape = cshape
	body.add_child(ccol)

# ────────────────────────────────────────────────────────────────────────────
# Stub shop buildings

func _build_shop(origin: Vector3, roof_color: Color, label: String) -> void:
	# Foundation
	_box(origin + Vector3(0, 0.3, 0), Vector3(5.0, 0.6, 4.0), STONE)
	# Walls
	_box(origin + Vector3(0, 1.6, 0), Vector3(4.6, 2.0, 3.6), WHITE_WALL)
	# Door
	_box(origin + Vector3(0, 1.0, 1.85), Vector3(0.8, 1.4, 0.06), Color(0.32, 0.20, 0.12))
	# Windows
	_box(origin + Vector3(-1.3, 1.7, 1.85), Vector3(0.7, 0.7, 0.06), Color(0.78, 0.88, 0.92))
	_box(origin + Vector3( 1.3, 1.7, 1.85), Vector3(0.7, 0.7, 0.06), Color(0.78, 0.88, 0.92))
	# Sloped roof
	for sz in [-1.0, 1.0]:
		var slope := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(5.4, 0.20, 2.6)
		slope.mesh = bm
		slope.position = origin + Vector3(0, 3.4, sz * 1.0)
		slope.rotation = Vector3(deg_to_rad(40.0 * sz), 0, 0)
		slope.material_override = _mat(roof_color, 0.7)
		add_child(slope)
	# Sign above door
	var sign := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(2.4, 0.5, 0.08)
	sign.mesh = bm
	sign.position = origin + Vector3(0, 2.4, 1.95)
	sign.material_override = _mat(SIGN_BG)
	add_child(sign)
	# Sign label using a Label3D so we can read it
	var label3d := Label3D.new()
	label3d.text = label
	label3d.font_size = 56
	label3d.outline_size = 8
	label3d.position = origin + Vector3(0, 2.4, 2.02)
	label3d.modulate = Color(0.22, 0.16, 0.10)
	add_child(label3d)
	# Collision footprint
	_add_collider(origin + Vector3(0, 1.5, 0), Vector3(5.0, 3.0, 4.0))

# ────────────────────────────────────────────────────────────────────────────
# Lampposts + decor

func _scatter_lampposts() -> void:
	for p in [Vector3(-4, 0, -4), Vector3(4, 0, -4), Vector3(-4, 0, 4), Vector3(4, 0, 4)]:
		# Post
		var post := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.06
		cm.bottom_radius = 0.06
		cm.height = 2.4
		post.mesh = cm
		post.position = p + Vector3(0, 1.2, 0)
		post.material_override = _mat(Color(0.18, 0.14, 0.10))
		add_child(post)
		# Lamp glow
		var lamp := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.18
		sm.height = 0.36
		lamp.mesh = sm
		lamp.position = p + Vector3(0, 2.5, 0)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.95, 0.7)
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.85, 0.5)
		mat.emission_energy_multiplier = 2.0
		lamp.material_override = mat
		add_child(lamp)
		# Light source
		var light := OmniLight3D.new()
		light.position = p + Vector3(0, 2.6, 0)
		light.light_color = Color(1.0, 0.85, 0.6)
		light.light_energy = 1.4
		light.omni_range = 8.0
		add_child(light)

func _scatter_decor() -> void:
	# Trees + flowers along the perimeter
	var rng := RandomNumberGenerator.new()
	rng.seed = 222
	for i in range(20):
		var angle := (i / 20.0) * TAU + rng.randf_range(-0.05, 0.05)
		var r := rng.randf_range(18.0, 25.0)
		var x := cos(angle) * r
		var z := sin(angle) * r * 0.75
		var packed: PackedScene = load(NATURE + "tree_oak.glb")
		if packed:
			var inst: Node3D = packed.instantiate()
			inst.position = Vector3(x, 0, z)
			inst.scale = Vector3(2.2, 2.2, 2.2)
			inst.rotation.y = rng.randf() * TAU
			add_child(inst)

# ────────────────────────────────────────────────────────────────────────────
# Boundary walls

func _build_perimeter_walls() -> void:
	# Dense forest perimeter (visual) + invisible walls (collision).
	var rng := RandomNumberGenerator.new()
	rng.seed = 777
	var x_min: float = -16.0
	var x_max: float =  16.0
	var z_min: float = -16.0
	var z_max: float =  16.0
	var pad: float = 1.5
	var step: float = 1.6
	var x: float = x_min - pad
	while x <= x_max + pad:
		_perimeter_tree(rng, Vector3(x, 0, z_min - pad))
		_perimeter_tree(rng, Vector3(x, 0, z_max + pad))
		x += step
	var z: float = z_min - pad
	while z <= z_max + pad:
		# West side: leave a gap for the return gate around z=-3..3
		if abs(z) > 3.5:
			_perimeter_tree(rng, Vector3(x_min - pad, 0, z))
		_perimeter_tree(rng, Vector3(x_max + pad, 0, z))
		z += step
	# Invisible solid walls
	var wall_h: float = 4.0
	var wall_t: float = 1.0
	_add_collider(Vector3(0, wall_h * 0.5, z_min - 0.5), Vector3(x_max - x_min + 4.0, wall_h, wall_t))
	_add_collider(Vector3(0, wall_h * 0.5, z_max + 0.5), Vector3(x_max - x_min + 4.0, wall_h, wall_t))
	_add_collider(Vector3(x_max + 0.5, wall_h * 0.5, 0), Vector3(wall_t, wall_h, z_max - z_min + 4.0))
	# West split for return-gate gap
	var gap_top := -3.5
	var gap_bot := 3.5
	var west_top_len: float = gap_top - z_min + 2.0
	var west_bot_len: float = z_max - gap_bot + 2.0
	_add_collider(Vector3(x_min - 0.5, wall_h * 0.5, (z_min + gap_top) * 0.5 - 1.0), Vector3(wall_t, wall_h, west_top_len))
	_add_collider(Vector3(x_min - 0.5, wall_h * 0.5, (gap_bot + z_max) * 0.5 + 1.0), Vector3(wall_t, wall_h, west_bot_len))

func _perimeter_tree(rng: RandomNumberGenerator, base: Vector3) -> void:
	var paths: Array[String] = ["tree_pineTallA.glb", "tree_pineDefaultA.glb", "tree_pineDefaultB.glb", "tree_oak.glb"]
	var path: String = NATURE + paths[rng.randi() % paths.size()]
	var packed: PackedScene = load(path)
	if packed == null:
		return
	var jitter := Vector3(rng.randf_range(-0.4, 0.4), 0, rng.randf_range(-0.4, 0.4))
	var inst: Node3D = packed.instantiate()
	inst.position = base + jitter
	var s := rng.randf_range(2.2, 3.0)
	inst.scale = Vector3(s, s, s)
	inst.rotation.y = rng.randf() * TAU
	add_child(inst)

# ────────────────────────────────────────────────────────────────────────────
# Return gate — west side, leads back to the farm

func _build_return_gate() -> void:
	var gate := Area3D.new()
	gate.set_script(load("res://scripts/door.gd"))
	gate.set("target_scene", "res://scenes/main.tscn")
	gate.position = Vector3(-16.8, 0.6, 0.0)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.0, 1.8, 4.0)
	col.shape = shape
	gate.add_child(col)
	add_child(gate)
	# Gate posts + lintel
	_box(gate.position + Vector3(0, 1.0, -2.4), Vector3(0.2, 2.4, 0.2), Color(0.30, 0.20, 0.12))
	_box(gate.position + Vector3(0, 1.0,  2.4), Vector3(0.2, 2.4, 0.2), Color(0.30, 0.20, 0.12))
	_box(gate.position + Vector3(0, 2.3,  0.0), Vector3(0.2, 0.30, 5.0), Color(0.30, 0.20, 0.12))
	# Glow marker
	var marker := MeshInstance3D.new()
	var mm := SphereMesh.new()
	mm.radius = 0.22
	mm.height = 0.44
	marker.mesh = mm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 1.0, 0.5)
	mat.emission_enabled = true
	mat.emission = Color(0.3, 1.0, 0.4)
	mat.emission_energy_multiplier = 1.4
	marker.material_override = mat
	marker.position = Vector3(0, 1.0, 0)
	gate.add_child(marker)
	# Sign
	var label3d := Label3D.new()
	label3d.text = "← TO FARM"
	label3d.font_size = 48
	label3d.outline_size = 6
	label3d.position = gate.position + Vector3(0, 2.85, 0)
	label3d.modulate = Color(0.9, 0.9, 0.85)
	add_child(label3d)
