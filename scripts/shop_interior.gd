extends Node3D
## Shared shop interior. Reads GameState meta "shop_type" to theme the room
## (blacksmith / general / cafe / inn). Floor, walls, exit door, lamp, plus
## per-shop furniture. Exit door warps back to town_centre.tscn.

const SURVIVAL := "res://assets/models/survival/"

@onready var _player: CharacterBody3D = $Player

var shop_type: String = "general"

func _ready() -> void:
	if GameState.has_meta("shop_type"):
		shop_type = String(GameState.get_meta("shop_type"))
		GameState.remove_meta("shop_type")
	_build_room()
	match shop_type:
		"blacksmith": _furnish_blacksmith()
		"general":    _furnish_general()
		"cafe":       _furnish_cafe()
		"inn":        _furnish_inn()
		_:            _furnish_general()
	_build_shopkeeper()
	_build_exit_door()
	# Spawn the player a couple steps inside, facing the room
	if _player != null:
		_player.global_position = Vector3(0, 1, 3.0)

# ────────────────────────────────────────────────────────────────────────────
# Shopkeeper NPC — placed behind the counter in each shop, talk on [E]

func _build_shopkeeper() -> void:
	var npc := NPC.new()
	match shop_type:
		"blacksmith":
			npc.npc_name = "Thomas"
			npc.shirt_color = Color(0.32, 0.22, 0.18)  # dark workshirt
			npc.hat_color   = Color(0.22, 0.18, 0.14)  # leather cap
			npc.hair_color  = Color(0.22, 0.16, 0.10)
			npc.position = Vector3(2.5, 0, -2.0)  # behind counter
			npc.lines = [
				{"speaker": "Thomas", "text": "Aye?  Come for a weapon, or just lookin'?", "color": Color(0.62, 0.45, 0.32)},
				{"speaker": "Thomas", "text": "I'd sell you a proper bronze blade, but I'm runnin' low on iron.  Need to mine more — and the mines are flooded.", "color": Color(0.62, 0.45, 0.32)},
				{"speaker": "Thomas", "text": "If you can pump the water out, I'll give you a discount for life.  That's a promise.", "color": Color(0.62, 0.45, 0.32)},
				{"speaker": "Thomas", "text": "Until then, take care of that rusted sword Tobias gave you — it's all you've got.", "color": Color(0.62, 0.45, 0.32)},
			]
		"general":
			npc.npc_name = "Gus"
			npc.shirt_color = Color(0.42, 0.55, 0.32)  # apron green
			npc.hat_color   = Color(0.85, 0.78, 0.62)  # straw boater
			npc.hair_color  = Color(0.85, 0.85, 0.85)  # silver
			npc.position = Vector3(0, 0, -2.5)
			npc.lines = [
				{"speaker": "Gus", "text": "Welcome, welcome!  Greenfield General Store — if I ain't got it, you don't need it.", "color": Color(0.55, 0.45, 0.22)},
				{"speaker": "Gus", "text": "Seeds, fence panels, lanterns, building scraps — I keep 'em all stocked.", "color": Color(0.55, 0.45, 0.22)},
				{"speaker": "Gus", "text": "Word of advice, friend — buy fence panels BEFORE the storms come.  Mayor'll be 'round to warn you, but the price doubles when folks panic.", "color": Color(0.55, 0.45, 0.22)},
				{"speaker": "Gus", "text": "Come back any time.  I don't sleep much these days.", "color": Color(0.55, 0.45, 0.22)},
			]
		"cafe":
			npc.npc_name = "Mira"
			npc.shirt_color = Color(0.95, 0.65, 0.55)  # apron pink
			npc.hat_color   = Color(0.95, 0.95, 0.92)  # chef hat
			npc.hair_color  = Color(0.42, 0.27, 0.16)
			npc.position = Vector3(0, 0, -2.8)
			npc.lines = [
				{"speaker": "Mira", "text": "Oh!  A new face — finally!  Sit, sit, what'll you have?", "color": Color(0.85, 0.45, 0.42)},
				{"speaker": "Mira", "text": "I do strawberry tart, parsnip soup, and a roast that'll make you cry.  Bring me good ingredients and I'll cook you anything.", "color": Color(0.85, 0.45, 0.42)},
				{"speaker": "Mira", "text": "The radio plays a new recipe every morning — listen at home and I'll teach you to make it.", "color": Color(0.85, 0.45, 0.42)},
				{"speaker": "Mira", "text": "Come back when you're hungry, farmer.  Stay warm out there!", "color": Color(0.85, 0.45, 0.42)},
			]
		"inn":
			npc.npc_name = "Elara"
			npc.shirt_color = Color(0.55, 0.32, 0.62)  # purple
			npc.hat_color   = Color(0.95, 0.95, 0.92)
			npc.hair_color  = Color(0.42, 0.27, 0.16)
			npc.position = Vector3(-2.0, 0, -1.5)
			npc.lines = [
				{"speaker": "Elara", "text": "Welcome to the Greenfield Inn.  Lily told me you'd be by — she's out at the farm tonight.", "color": Color(0.65, 0.42, 0.72)},
				{"speaker": "Elara", "text": "We've got rooms for travellers, hot meals, and a fire that never goes out.  Safe shelter, day or night.", "color": Color(0.65, 0.42, 0.72)},
				{"speaker": "Elara", "text": "If a monster ever knocks you out, the Doctor'll patch you up — but he keeps the medicine here for emergencies.", "color": Color(0.65, 0.42, 0.72)},
				{"speaker": "Elara", "text": "Ring the bell on the desk if you need me.  Sleep well, farmer.", "color": Color(0.65, 0.42, 0.72)},
			]
		_:
			return
	add_child(npc)

# ────────────────────────────────────────────────────────────────────────────
# Shared room shell

func _wall_color() -> Color:
	match shop_type:
		"blacksmith": return Color(0.42, 0.40, 0.36)  # cool stone
		"cafe":       return Color(0.95, 0.88, 0.72)  # warm cream
		"inn":        return Color(0.88, 0.78, 0.62)  # warm parchment
		_:            return Color(0.92, 0.88, 0.78)  # general off-white

func _floor_color() -> Color:
	match shop_type:
		"blacksmith": return Color(0.32, 0.30, 0.28)
		"cafe":       return Color(0.55, 0.36, 0.22)
		"inn":        return Color(0.50, 0.34, 0.20)
		_:            return Color(0.55, 0.40, 0.26)

func _build_room() -> void:
	# Floor
	var floor_node := MeshInstance3D.new()
	var fm := PlaneMesh.new()
	fm.size = Vector2(11, 9)
	floor_node.mesh = fm
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = _floor_color()
	fmat.roughness = 0.85
	floor_node.material_override = fmat
	add_child(floor_node)
	# Floor collider
	var fbody := StaticBody3D.new()
	fbody.position = Vector3(0, -0.1, 0)
	add_child(fbody)
	var fcol := CollisionShape3D.new()
	var fshape := BoxShape3D.new()
	fshape.size = Vector3(11, 0.2, 9)
	fcol.shape = fshape
	fbody.add_child(fcol)
	# Walls
	_wall(Vector3(0, 1.5, -4.5), Vector3(11, 3, 0.2), _wall_color())
	_wall(Vector3(0, 1.5,  4.5), Vector3(11, 3, 0.2), _wall_color())
	_wall(Vector3(-5.5, 1.5, 0), Vector3(0.2, 3, 9), _wall_color().darkened(0.05))
	_wall(Vector3( 5.5, 1.5, 0), Vector3(0.2, 3, 9), _wall_color().darkened(0.05))
	# Ceiling beams
	for x in [-3.5, 0.0, 3.5]:
		var beam := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.2, 0.2, 8.6)
		beam.mesh = bm
		beam.position = Vector3(x, 2.85, 0)
		var bmat := StandardMaterial3D.new()
		bmat.albedo_color = Color(0.32, 0.20, 0.12)
		beam.material_override = bmat
		add_child(beam)
	# Lamp
	var lamp := OmniLight3D.new()
	lamp.position = Vector3(0, 2.5, 0)
	lamp.light_color = _lamp_color()
	lamp.light_energy = 2.5
	lamp.omni_range = 14.0
	add_child(lamp)
	# Title sign on the back wall
	var label := Label3D.new()
	label.text = _shop_title()
	label.font_size = 96
	label.outline_size = 12
	label.modulate = Color(0.22, 0.16, 0.10)
	label.position = Vector3(0, 2.4, -4.39)
	add_child(label)

func _lamp_color() -> Color:
	match shop_type:
		"blacksmith": return Color(1.0, 0.55, 0.30)  # forge glow
		"cafe":       return Color(1.0, 0.85, 0.55)
		"inn":        return Color(1.0, 0.78, 0.42)
		_:            return Color(1.0, 0.92, 0.75)

func _shop_title() -> String:
	match shop_type:
		"blacksmith": return "BLACKSMITH"
		"cafe":       return "CAFE"
		"inn":        return "INN"
		"general":    return "GENERAL STORE"
		_:            return "SHOP"

func _wall(pos: Vector3, size: Vector3, color: Color) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	mi.material_override = mat
	add_child(mi)
	var body := StaticBody3D.new()
	body.position = pos
	add_child(body)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)

# ────────────────────────────────────────────────────────────────────────────
# Furnishing — one per shop

func _box(pos: Vector3, size: Vector3, color: Color, rot: Vector3 = Vector3.ZERO) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.position = pos
	mi.rotation = rot
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.85
	mi.material_override = mat
	add_child(mi)

func _emissive_box(pos: Vector3, size: Vector3, base: Color, glow: Color, energy: float) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = base
	mat.emission_enabled = true
	mat.emission = glow
	mat.emission_energy_multiplier = energy
	mi.material_override = mat
	add_child(mi)

func _add_collider(pos: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	add_child(body)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)

func _kenney(path: String, pos: Vector3, scale: float = 1.0, rot_y: float = 0.0) -> void:
	var packed: PackedScene = load(SURVIVAL + path)
	if packed == null:
		return
	var inst: Node3D = packed.instantiate()
	inst.position = pos
	inst.scale = Vector3(scale, scale, scale)
	inst.rotation.y = rot_y
	add_child(inst)

# ─── Blacksmith: forge, anvil, weapons rack, anvil counter ───────────────

func _furnish_blacksmith() -> void:
	# Forge — big stone box with a glowing red interior
	_box(Vector3(-3.5, 0.55, -3.5), Vector3(2.0, 1.1, 1.6), Color(0.32, 0.30, 0.28))
	_emissive_box(Vector3(-3.5, 1.1, -3.5), Vector3(1.0, 0.5, 0.7), Color(0.30, 0.10, 0.05),
		Color(1.0, 0.32, 0.10), 2.6)
	# Forge chimney
	_box(Vector3(-3.5, 2.4, -3.8), Vector3(0.8, 1.5, 0.8), Color(0.42, 0.40, 0.38))
	_add_collider(Vector3(-3.5, 0.8, -3.5), Vector3(2.0, 1.6, 1.6))
	# Anvil base + top
	_box(Vector3(-1.0, 0.30, -2.5), Vector3(0.6, 0.6, 0.5), Color(0.22, 0.20, 0.18))
	_box(Vector3(-1.0, 0.78, -2.5), Vector3(0.9, 0.30, 0.40), Color(0.18, 0.18, 0.20))
	_box(Vector3(-1.4, 0.78, -2.5), Vector3(0.30, 0.20, 0.30), Color(0.18, 0.18, 0.20))
	_add_collider(Vector3(-1.0, 0.5, -2.5), Vector3(1.0, 1.0, 0.6))
	# Counter at the back (sales)
	_box(Vector3(2.5, 0.55, -3.0), Vector3(3.0, 1.1, 0.8), Color(0.42, 0.30, 0.18))
	_add_collider(Vector3(2.5, 0.55, -3.0), Vector3(3.0, 1.1, 0.8))
	# Weapons rack on the west wall
	_box(Vector3(-5.30, 1.4, 1.0), Vector3(0.10, 1.6, 2.4), Color(0.28, 0.20, 0.14))
	for i in range(4):
		var z := 1.0 + (i - 1.5) * 0.5
		# Sword on the rack — vertical slim box + handle
		_box(Vector3(-5.18, 1.4, z), Vector3(0.06, 1.4, 0.06), Color(0.78, 0.78, 0.80))
		_box(Vector3(-5.18, 0.65, z), Vector3(0.10, 0.20, 0.10), Color(0.45, 0.30, 0.18))
		_box(Vector3(-5.18, 0.80, z), Vector3(0.20, 0.05, 0.20), Color(0.78, 0.62, 0.28))
	# Barrel + chest props
	_kenney("barrel.glb", Vector3(3.5, 0, 3.0), 1.5, 0.0)
	_kenney("chest.glb",  Vector3(-3.0, 0, 3.0), 1.5, 0.0)

# ─── General Store: counter, shelves, stacked goods ───────────────────────

func _furnish_general() -> void:
	# Long sales counter at the back
	_box(Vector3(0, 0.55, -3.5), Vector3(8.0, 1.1, 1.0), Color(0.55, 0.36, 0.22))
	_box(Vector3(0, 0.30, -3.0), Vector3(8.0, 0.05, 0.20), Color(0.32, 0.20, 0.12))  # counter trim
	_add_collider(Vector3(0, 0.55, -3.5), Vector3(8.0, 1.1, 1.0))
	# Shelves on the side walls
	for sx in [-1.0, 1.0]:
		for y in [0.8, 1.5, 2.2]:
			_box(Vector3(sx * 4.2, y, 0), Vector3(0.4, 0.06, 4.0), Color(0.55, 0.36, 0.22))
			# Stacked goods on the shelf
			for i in range(5):
				var z := -1.6 + i * 0.8
				var box_h := randf_range(0.18, 0.32)
				_box(Vector3(sx * 4.0, y + box_h * 0.5 + 0.04, z),
					Vector3(0.30, box_h, 0.25),
					Color(randf_range(0.4, 0.8), randf_range(0.3, 0.6), randf_range(0.2, 0.5)))
	# Welcome mat
	var mat_node := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(1.4, 0.8)
	mat_node.mesh = pm
	mat_node.position = Vector3(0, 0.02, 3.5)
	mat_node.material_override = (func() -> StandardMaterial3D:
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.55, 0.30, 0.25)
		return m).call()
	add_child(mat_node)
	# Barrel + chest props
	_kenney("barrel.glb", Vector3(-4.5, 0, 3.5), 1.4, 0.0)
	_kenney("chest.glb",  Vector3(4.5, 0, 3.5), 1.4, 0.0)

# ─── Cafe: tables + chairs, kitchen counter ───────────────────────────────

func _furnish_cafe() -> void:
	# Kitchen counter at the back
	_box(Vector3(0, 0.55, -3.8), Vector3(7.0, 1.1, 1.0), Color(0.78, 0.62, 0.42))
	_add_collider(Vector3(0, 0.55, -3.8), Vector3(7.0, 1.1, 1.0))
	# Pastry display (emissive yellow)
	_emissive_box(Vector3(-2.0, 1.2, -3.8), Vector3(1.4, 0.4, 0.6),
		Color(1.0, 0.92, 0.72), Color(1.0, 0.85, 0.55), 1.0)
	# Coffee machine glow
	_emissive_box(Vector3(2.0, 1.3, -3.8), Vector3(0.6, 0.6, 0.4),
		Color(0.2, 0.2, 0.2), Color(0.85, 0.32, 0.10), 0.6)
	# Tables — 3 small round-ish (use boxes scaled)
	for slot in [Vector3(-2.5, 0, 1.5), Vector3(0, 0, 1.5), Vector3(2.5, 0, 1.5)]:
		# Table top
		_box(slot + Vector3(0, 0.65, 0), Vector3(1.0, 0.10, 1.0), Color(0.55, 0.36, 0.22))
		# Pedestal
		_box(slot + Vector3(0, 0.30, 0), Vector3(0.20, 0.50, 0.20), Color(0.32, 0.20, 0.12))
		_box(slot + Vector3(0, 0.05, 0), Vector3(0.45, 0.10, 0.45), Color(0.22, 0.14, 0.08))
		# Two chairs per table
		for sz in [-0.8, 0.8]:
			_box(slot + Vector3(0, 0.30, sz), Vector3(0.45, 0.05, 0.45), Color(0.42, 0.28, 0.16))
			_box(slot + Vector3(0, 0.55, sz + (0.20 if sz < 0 else -0.20)), Vector3(0.45, 0.5, 0.05), Color(0.42, 0.28, 0.16))
		_add_collider(slot + Vector3(0, 0.5, 0), Vector3(1.0, 1.0, 1.0))

# ─── Inn: front desk, beds, fireplace ─────────────────────────────────────

func _furnish_inn() -> void:
	# Front desk
	_box(Vector3(-2.0, 0.55, -1.0), Vector3(2.4, 1.1, 0.9), Color(0.55, 0.36, 0.22))
	_box(Vector3(-2.0, 1.20, -1.45), Vector3(2.4, 0.20, 0.10), Color(0.32, 0.20, 0.12))
	_add_collider(Vector3(-2.0, 0.55, -1.0), Vector3(2.4, 1.1, 0.9))
	# Bell on the desk (gold sphere)
	var bell := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.10
	sm.height = 0.20
	bell.mesh = sm
	bell.position = Vector3(-2.0, 1.20, -0.7)
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = Color(0.95, 0.78, 0.36)
	bmat.metallic = 0.6
	bmat.roughness = 0.3
	bell.material_override = bmat
	add_child(bell)
	# Two beds at the back
	for sx in [-3.0, 0.5]:
		# Frame
		_box(Vector3(sx, 0.30, -3.5), Vector3(2.0, 0.4, 1.4), Color(0.55, 0.36, 0.22))
		# Mattress
		_box(Vector3(sx, 0.65, -3.5), Vector3(2.0, 0.3, 1.4), Color(0.95, 0.92, 0.85))
		# Pillow
		_box(Vector3(sx - 0.7, 0.85, -3.5), Vector3(0.5, 0.15, 0.6), Color(0.85, 0.55, 0.50))
		# Blanket
		_box(Vector3(sx + 0.3, 0.81, -3.5), Vector3(1.2, 0.06, 1.4), Color(0.55, 0.32, 0.30))
		_add_collider(Vector3(sx, 0.5, -3.5), Vector3(2.0, 1.0, 1.4))
	# Fireplace on the east wall
	_box(Vector3(4.5, 1.1, 0.0), Vector3(1.2, 2.2, 1.4), Color(0.42, 0.40, 0.38))
	_emissive_box(Vector3(4.2, 0.55, 0.0), Vector3(0.6, 0.7, 0.8),
		Color(0.30, 0.10, 0.05), Color(1.0, 0.42, 0.10), 2.4)
	_add_collider(Vector3(4.5, 1.1, 0.0), Vector3(1.2, 2.2, 1.4))
	# Fire glow OmniLight
	var fire_light := OmniLight3D.new()
	fire_light.position = Vector3(4.0, 0.6, 0.0)
	fire_light.light_color = Color(1.0, 0.45, 0.18)
	fire_light.light_energy = 2.0
	fire_light.omni_range = 7.0
	add_child(fire_light)
	# Rug in the centre
	var rug := MeshInstance3D.new()
	var rpm := PlaneMesh.new()
	rpm.size = Vector2(3.0, 2.0)
	rug.mesh = rpm
	rug.position = Vector3(0.5, 0.02, 1.5)
	var rmat := StandardMaterial3D.new()
	rmat.albedo_color = Color(0.55, 0.30, 0.30)
	rug.material_override = rmat
	add_child(rug)

# ────────────────────────────────────────────────────────────────────────────
# Exit door — back to town centre

func _build_exit_door() -> void:
	var door := Area3D.new()
	door.set_script(load("res://scripts/door.gd"))
	door.set("target_scene", "res://scenes/town_centre.tscn")
	door.position = Vector3(0, 0.6, 4.4)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.6, 1.8, 1.0)
	col.shape = shape
	door.add_child(col)
	add_child(door)
	# Visible door slab
	var slab := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.2, 2.2, 0.06)
	slab.mesh = bm
	slab.position = Vector3(0, 0.5, 0)
	var dmat := StandardMaterial3D.new()
	dmat.albedo_color = Color(0.32, 0.20, 0.12)
	slab.material_override = dmat
	door.add_child(slab)
	# Glow marker on the floor
	var marker := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.18
	sm.height = 0.36
	marker.mesh = sm
	marker.position = Vector3(0, -0.4, 0)
	var mmat := StandardMaterial3D.new()
	mmat.albedo_color = Color(1.0, 0.85, 0.4)
	mmat.emission_enabled = true
	mmat.emission = Color(1.0, 0.7, 0.2)
	mmat.emission_energy_multiplier = 1.4
	marker.material_override = mmat
	door.add_child(marker)
	# Sign
	var label := Label3D.new()
	label.text = "← EXIT"
	label.font_size = 48
	label.outline_size = 6
	label.modulate = Color(1.0, 0.95, 0.7)
	label.position = Vector3(0, 1.7, 0)
	door.add_child(label)
