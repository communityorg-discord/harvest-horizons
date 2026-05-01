extends Node3D
## Procedural farm decoration using Kenney CC0 models for natural elements.
## Adds StaticBody3D collision around buildings, trees, fences, rocks etc.
## so the player can't walk through them. A cliff perimeter encloses the farm
## (you can't fall off the map). A door Area3D enters the cottage interior;
## an east gate Area3D leads to the town centre.

# ────────────────────────────────────────────────────────────────────────────
# Cottage palette (still procedural — see _build_cottage)

const STONE        := Color(0.55, 0.52, 0.48)
const STONE_DARK   := Color(0.38, 0.36, 0.34)
const WOOD_WALL    := Color(0.52, 0.36, 0.22)
const WOOD_BEAM    := Color(0.30, 0.20, 0.12)
const ROOF_BLUE    := Color(0.30, 0.42, 0.55)
const ROOF_BLUE_D  := Color(0.22, 0.32, 0.42)
const DOOR         := Color(0.32, 0.20, 0.12)
const WINDOW_GLASS := Color(0.78, 0.88, 0.92)
const CHIMNEY_BRICK:= Color(0.55, 0.30, 0.22)
const PATH_DIRT    := Color(0.62, 0.48, 0.30)
const GRASS_DARK   := Color(0.30, 0.48, 0.22)
const GRASS_LIGHT  := Color(0.45, 0.62, 0.30)

# ────────────────────────────────────────────────────────────────────────────
# Kenney model paths

const NATURE := "res://assets/models/nature/"
const SURVIVAL := "res://assets/models/survival/"

const TREE_PATHS := [
	"tree_pineDefaultA.glb", "tree_pineDefaultB.glb",
	"tree_pineSmallA.glb",   "tree_pineSmallB.glb",
	"tree_pineTallA.glb",    "tree_oak.glb",
	"tree_fat.glb",          "tree_default.glb",
]
const ROCK_PATHS := ["rock_smallE.glb", "rock_tallH.glb"]
const FLOWER_PATHS := ["flower_purpleA.glb", "flower_yellowA.glb", "flower_redA.glb"]
const STUMP_PATHS := ["tree_blocks.glb", "tree_blocks_dark.glb"]
const GRASS_PATCH_PATHS := ["res://assets/models/survival/patch-grass.glb",
	"res://assets/models/survival/patch-grass-large.glb",
	"res://assets/models/survival/grass.glb",
	"res://assets/models/survival/grass-large.glb"]

# Farm playable area (XZ in metres). Boundary cliffs sit just outside this rect.
const FARM_X_MIN := -16.0
const FARM_X_MAX :=  16.0
const FARM_Z_MIN := -14.0
const FARM_Z_MAX :=  16.0

const COTTAGE_POS := Vector3(-9.0, 0.0, -3.0)
const COTTAGE_FOOTPRINT := Vector3(4.4, 3.0, 3.6)

# ────────────────────────────────────────────────────────────────────────────

func _ready() -> void:
	_build_ground()
	_build_path()
	_build_cottage(COTTAGE_POS)
	_build_well(Vector3(-4.5, 0, -7.0))
	_build_mailbox(Vector3(-4.5, 0, 5.5))
	_place_collidable_kenney(SURVIVAL + "signpost.glb", Vector3(8.0, 0, 1.0), 1.6, 0.0, 0.25, 1.6)
	_place_collidable_kenney(SURVIVAL + "chest.glb",   Vector3(-7.6, 0, -1.2), 1.6, deg_to_rad(-25), 0.5, 0.5)
	_place_collidable_kenney(SURVIVAL + "barrel.glb",  Vector3(-6.6, 0, -0.8), 1.4, 0.0, 0.4, 1.0)
	_place_collidable_kenney(NATURE + "log_stackLarge.glb", Vector3(-11.5, 0, 0.0), 1.4, deg_to_rad(20), 0.8, 0.6)
	# (Fence + farm grid removed — those come via the storm + first-harvest quests.)
	_build_perimeter_walls()
	_scatter_trees()
	_scatter_rocks()
	_scatter_stumps()
	_scatter_logs()
	_scatter_grass_patches()
	_scatter_flowers()
	_scatter_grass_tufts()
	_build_cottage_door()
	_build_town_gate()

# ────────────────────────────────────────────────────────────────────────────
# Helpers

func _mat(color: Color, rough: float = 0.9) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	return m

func _box(_p: Node, pos: Vector3, size: Vector3, color: Color, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.position = pos
	mi.rotation = rot
	mi.material_override = _mat(color)
	add_child(mi)
	return mi

func _cyl(_p: Node, pos: Vector3, radius: float, height: float, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = radius
	cm.bottom_radius = radius
	cm.height = height
	cm.radial_segments = 14
	mi.mesh = cm
	mi.position = pos
	mi.material_override = _mat(color)
	add_child(mi)
	return mi

func _sphere(_p: Node, pos: Vector3, radius: float, color: Color, scale: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0
	sm.radial_segments = 12
	sm.rings = 6
	mi.mesh = sm
	mi.position = pos
	mi.scale = scale
	mi.material_override = _mat(color)
	add_child(mi)
	return mi

func _prism(pos: Vector3, size: Vector3, color: Color, rot_y: float = 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var pm := PrismMesh.new()
	pm.size = size
	pm.left_to_right = 0.5
	mi.mesh = pm
	mi.position = pos
	mi.rotation.y = rot_y
	mi.material_override = _mat(color)
	add_child(mi)
	return mi

# Place a Kenney glb. If collision_radius>0, wrap in StaticBody3D + cylinder.
func _place_collidable_kenney(path: String, pos: Vector3, scale: float, rot_y: float,
		collision_radius: float = 0.0, collision_height: float = 0.0) -> Node3D:
	var packed: PackedScene = load(path)
	if packed == null:
		push_warning("Missing model: %s" % path)
		return null
	if collision_radius > 0.0:
		var body := StaticBody3D.new()
		body.position = pos
		body.rotation.y = rot_y
		add_child(body)
		var inst: Node3D = packed.instantiate()
		inst.scale = Vector3(scale, scale, scale)
		body.add_child(inst)
		var col := CollisionShape3D.new()
		var shape := CylinderShape3D.new()
		shape.radius = collision_radius
		shape.height = collision_height
		col.shape = shape
		col.position = Vector3(0, collision_height * 0.5, 0)
		body.add_child(col)
		return body
	var inst2: Node3D = packed.instantiate()
	inst2.position = pos
	inst2.scale = Vector3(scale, scale, scale)
	inst2.rotation.y = rot_y
	add_child(inst2)
	return inst2

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
# Ground + path

func _build_ground() -> void:
	# Two-tone grass: a darker base + a lighter mottled overlay made from many
	# big translucent quads. Cheaper than a custom shader, looks less flat.
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(80, 80)
	ground.mesh = pm
	ground.material_override = _mat(GRASS_DARK, 0.95)
	add_child(ground)
	# Mottle: ~60 large irregular grass-tone discs for visible variation
	var rng := RandomNumberGenerator.new()
	rng.seed = 17
	for i in range(60):
		var p := Vector3(
			rng.randf_range(FARM_X_MIN, FARM_X_MAX),
			0.02,
			rng.randf_range(FARM_Z_MIN, FARM_Z_MAX),
		)
		var sx := rng.randf_range(2.0, 4.5)
		var sz := rng.randf_range(2.0, 4.5)
		var c := GRASS_LIGHT if rng.randf() < 0.6 else Color(0.20, 0.42, 0.20)
		var disc := MeshInstance3D.new()
		var dm := PlaneMesh.new()
		dm.size = Vector2(sx, sz)
		disc.mesh = dm
		disc.position = p
		var dmat := _mat(c, 0.95)
		dmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		dmat.albedo_color.a = 0.6
		disc.material_override = dmat
		add_child(disc)

func _build_path() -> void:
	var path_mat := _mat(PATH_DIRT, 0.95)
	var pts := [
		Vector3(-7.0, 0.04, 1.8),
		Vector3(-2.0, 0.04, 2.4),
		Vector3(3.0, 0.04, 1.8),
		Vector3(7.0, 0.04, 1.0),
		Vector3(15.0, 0.04, 0.5),  # extends to town gate
	]
	for i in range(pts.size() - 1):
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		var dist: float = a.distance_to(b)
		var steps: int = int(dist / 1.2) + 1
		for s in range(steps):
			var t: float = s / float(steps)
			var p: Vector3 = a.lerp(b, t)
			var seg := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(1.6, 0.06, 1.4)
			seg.mesh = bm
			seg.position = p
			seg.material_override = path_mat
			add_child(seg)

# ────────────────────────────────────────────────────────────────────────────
# Cottage (procedural) + collision

func _build_cottage(origin: Vector3) -> void:
	_add_collider(origin + Vector3(0, COTTAGE_FOOTPRINT.y * 0.5, 0), COTTAGE_FOOTPRINT)
	_box(self, origin + Vector3(0, 0.30, 0), Vector3(4.4, 0.60, 3.6), STONE)
	_box(self, origin + Vector3(0, 1.40, 0), Vector3(4.0, 1.60, 3.2), WOOD_WALL)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_box(self, origin + Vector3(sx * 1.92, 1.4, sz * 1.52), Vector3(0.16, 1.65, 0.16), WOOD_BEAM)
	_box(self, origin + Vector3(0, 1.0, 1.62), Vector3(0.7, 1.2, 0.05), DOOR)
	_box(self, origin + Vector3(0, 0.65, 1.78), Vector3(0.9, 0.10, 0.30), STONE)
	_box(self, origin + Vector3(-1.3, 1.55, 1.62), Vector3(0.55, 0.55, 0.04), WINDOW_GLASS)
	_box(self, origin + Vector3( 1.3, 1.55, 1.62), Vector3(0.55, 0.55, 0.04), WINDOW_GLASS)
	_box(self, origin + Vector3(-1.3, 1.55, 1.64), Vector3(0.05, 0.55, 0.06), WOOD_BEAM)
	_box(self, origin + Vector3( 1.3, 1.55, 1.64), Vector3(0.05, 0.55, 0.06), WOOD_BEAM)
	_box(self, origin + Vector3(-1.3, 1.55, 1.64), Vector3(0.55, 0.05, 0.06), WOOD_BEAM)
	_box(self, origin + Vector3( 1.3, 1.55, 1.64), Vector3(0.55, 0.05, 0.06), WOOD_BEAM)
	for sz_sign in [-1.0, 1.0]:
		var slope := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(4.6, 0.18, 2.2)
		slope.mesh = bm
		slope.position = origin + Vector3(0, 2.95, sz_sign * 0.8)
		slope.rotation = Vector3(deg_to_rad(40.0 * sz_sign), 0, 0)
		slope.material_override = _mat(ROOF_BLUE, 0.7)
		add_child(slope)
	_box(self, origin + Vector3(0, 3.55, 0), Vector3(4.7, 0.12, 0.16), ROOF_BLUE_D)
	_prism(origin + Vector3(0, 2.95, -1.6), Vector3(4.0, 1.2, 0.10), WOOD_WALL)
	_prism(origin + Vector3(0, 2.95,  1.6), Vector3(4.0, 1.2, 0.10), WOOD_WALL)
	_box(self, origin + Vector3(1.4, 3.6, -0.5), Vector3(0.5, 1.6, 0.5), CHIMNEY_BRICK)
	_box(self, origin + Vector3(1.4, 4.45, -0.5), Vector3(0.7, 0.18, 0.7), STONE_DARK)

func _build_cottage_door() -> void:
	var door := Area3D.new()
	door.position = COTTAGE_POS + Vector3(0, 0.6, 1.95)
	add_child(door)
	door.set_script(load("res://scripts/door.gd"))
	door.set("target_scene", "res://scenes/cottage_interior.tscn")
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.0, 1.4, 0.4)
	col.shape = shape
	door.add_child(col)
	# Glow marker on the door step
	var marker := MeshInstance3D.new()
	var mm := SphereMesh.new()
	mm.radius = 0.18
	mm.height = 0.36
	marker.mesh = mm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.85, 0.4)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.7, 0.2)
	mat.emission_energy_multiplier = 1.2
	marker.material_override = mat
	marker.position = Vector3(0, 0.6, 0)
	door.add_child(marker)

# ────────────────────────────────────────────────────────────────────────────
# Well + mailbox

func _build_well(origin: Vector3) -> void:
	_cyl(self, origin + Vector3(0, 0.45, 0), 0.9, 0.9, STONE)
	_cyl(self, origin + Vector3(0, 0.95, 0), 0.92, 0.10, STONE_DARK)
	_box(self, origin + Vector3(-0.7, 1.5, 0), Vector3(0.10, 1.1, 0.10), WOOD_BEAM)
	_box(self, origin + Vector3( 0.7, 1.5, 0), Vector3(0.10, 1.1, 0.10), WOOD_BEAM)
	for sx in [-1.0, 1.0]:
		var slope := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(1.2, 0.08, 1.4)
		slope.mesh = bm
		slope.position = origin + Vector3(sx * 0.45, 2.15, 0)
		slope.rotation = Vector3(0, 0, deg_to_rad(-35.0 * sx))
		slope.material_override = _mat(ROOF_BLUE)
		add_child(slope)
	var body := StaticBody3D.new()
	body.position = origin + Vector3(0, 0.5, 0)
	add_child(body)
	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.95
	shape.height = 1.0
	col.shape = shape
	body.add_child(col)

func _build_mailbox(origin: Vector3) -> void:
	_box(self, origin + Vector3(0, 0.55, 0), Vector3(0.10, 1.1, 0.10), WOOD_BEAM)
	_box(self, origin + Vector3(0, 1.20, 0), Vector3(0.40, 0.30, 0.55), Color(0.72, 0.30, 0.20))
	_box(self, origin + Vector3(0.22, 1.30, 0), Vector3(0.04, 0.18, 0.10), Color(0.85, 0.20, 0.15))
	_add_collider(origin + Vector3(0, 0.6, 0), Vector3(0.4, 1.2, 0.55))

# ────────────────────────────────────────────────────────────────────────────
# Picket fence with collision

func _build_fence_around_farm() -> void:
	var x_min: float = -6.4
	var x_max: float = 5.5
	var z_min: float = -7.5
	var z_max: float = 4.8
	var step: float = 1.0
	_fence_run_kenney(Vector3(x_min, 0, z_max), Vector3(x_max, 0, z_max), step, 0.0)
	_fence_run_kenney(Vector3(x_min, 0, z_min), Vector3(x_max, 0, z_min), step, 0.0)
	_fence_run_kenney(Vector3(x_min, 0, z_min), Vector3(x_min, 0, z_max), step, deg_to_rad(90))
	_fence_run_kenney(Vector3(x_max, 0, z_min), Vector3(x_max, 0, -0.5), step, deg_to_rad(90))
	_fence_run_kenney(Vector3(x_max, 0, 2.5), Vector3(x_max, 0, z_max), step, deg_to_rad(90))

func _fence_run_kenney(a: Vector3, b: Vector3, step: float, rot_y: float) -> void:
	var dist: float = a.distance_to(b)
	var dir: Vector3 = (b - a).normalized()
	var n: int = int(dist / step)
	for i in range(n):
		var p: Vector3 = a + dir * (i * step + step * 0.5)
		_place_collidable_kenney(NATURE + "fence_simple.glb", p, 1.0, rot_y, 0.15, 1.0)

# ────────────────────────────────────────────────────────────────────────────
# Perimeter cliff walls — visible boundary

func _build_perimeter_walls() -> void:
	var step: float = 2.0
	# North + south edges
	var x: float = FARM_X_MIN
	while x <= FARM_X_MAX:
		_place_collidable_kenney(NATURE + "cliff_block_rock.glb", Vector3(x, 0, FARM_Z_MIN - 1.0), 2.0, 0.0, 1.0, 2.0)
		_place_collidable_kenney(NATURE + "cliff_block_rock.glb", Vector3(x, 0, FARM_Z_MAX + 1.0), 2.0, 0.0, 1.0, 2.0)
		x += step
	# East + west edges (gap on east for the town gate around z=-3..3)
	var z: float = FARM_Z_MIN
	while z <= FARM_Z_MAX:
		_place_collidable_kenney(NATURE + "cliff_block_rock.glb", Vector3(FARM_X_MIN - 1.0, 0, z), 2.0, 0.0, 1.0, 2.0)
		if abs(z) > 3.0:
			_place_collidable_kenney(NATURE + "cliff_block_rock.glb", Vector3(FARM_X_MAX + 1.0, 0, z), 2.0, 0.0, 1.0, 2.0)
		z += step

func _build_town_gate() -> void:
	var gate := Area3D.new()
	gate.position = Vector3(FARM_X_MAX + 0.8, 0.6, 0.0)
	add_child(gate)
	gate.set_script(load("res://scripts/door.gd"))
	gate.set("target_scene", "res://scenes/town_centre.tscn")
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.0, 1.4, 4.0)
	col.shape = shape
	gate.add_child(col)
	# Gate posts + lintel
	_box(self, gate.position + Vector3(0, 1.0, -2.4), Vector3(0.16, 2.4, 0.16), WOOD_BEAM)
	_box(self, gate.position + Vector3(0, 1.0,  2.4), Vector3(0.16, 2.4, 0.16), WOOD_BEAM)
	_box(self, gate.position + Vector3(0, 2.3,  0.0), Vector3(0.16, 0.30, 5.0), WOOD_BEAM)
	# Glow marker
	var marker := MeshInstance3D.new()
	var mm := SphereMesh.new()
	mm.radius = 0.22
	mm.height = 0.44
	marker.mesh = mm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.85, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.3, 0.7, 1.0)
	mat.emission_energy_multiplier = 1.4
	marker.material_override = mat
	marker.position = Vector3(0, 1.0, 0)
	gate.add_child(marker)

# ────────────────────────────────────────────────────────────────────────────
# Trees / rocks / flowers / grass

func _scatter_trees() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	for i in range(28):
		var angle: float = (i / 28.0) * TAU + rng.randf_range(-0.05, 0.05)
		var radius: float = rng.randf_range(20.0, 28.0)
		var x: float = cos(angle) * radius
		var z: float = sin(angle) * radius * 0.75
		var tree_path: String = NATURE + TREE_PATHS[rng.randi() % TREE_PATHS.size()]
		var s: float = rng.randf_range(1.6, 2.4)
		var ry: float = rng.randf() * TAU
		_place_collidable_kenney(tree_path, Vector3(x, 0, z), s, ry)  # outside cliffs, decorative

	var inside := [
		Vector3(-13.5, 0, -10.0), Vector3(-12.5, 0, -7.0),
		Vector3(-14.5, 0, 8.0),   Vector3(13.0, 0, -10.0),
		Vector3(13.5, 0, 11.0),   Vector3(-13.0, 0, 12.0),
	]
	for p in inside:
		var tree_path: String = NATURE + TREE_PATHS[rng.randi() % TREE_PATHS.size()]
		var s: float = rng.randf_range(1.8, 2.4)
		var ry: float = rng.randf() * TAU
		_place_collidable_kenney(tree_path, p, s, ry, 0.45, 4.0)

func _scatter_rocks() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	for i in range(12):
		var angle: float = rng.randf() * TAU
		var radius: float = rng.randf_range(7.5, 14.0)
		var p := Vector3(cos(angle) * radius, 0.0, sin(angle) * radius * 0.75)
		var rock_path: String = NATURE + ROCK_PATHS[rng.randi() % ROCK_PATHS.size()]
		var s: float = rng.randf_range(1.0, 1.6)
		var ry: float = rng.randf() * TAU
		_place_collidable_kenney(rock_path, p, s, ry, 0.5, 0.6)

func _scatter_flowers() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 13
	for i in range(50):
		var angle: float = rng.randf() * TAU
		var radius: float = rng.randf_range(3.5, 13.0)
		var p := Vector3(cos(angle) * radius, 0.0, sin(angle) * radius * 0.85)
		if abs(p.x - COTTAGE_POS.x) < 3.0 and abs(p.z - COTTAGE_POS.z) < 3.0:
			continue
		var flower_path: String = NATURE + FLOWER_PATHS[rng.randi() % FLOWER_PATHS.size()]
		var s: float = rng.randf_range(0.8, 1.3)
		var ry: float = rng.randf() * TAU
		_place_collidable_kenney(flower_path, p, s, ry)

func _scatter_grass_tufts() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in range(280):
		var angle: float = rng.randf() * TAU
		var radius: float = rng.randf_range(2.5, 16.0)
		var p := Vector3(cos(angle) * radius, 0.04, sin(angle) * radius * 0.85)
		# Don't bury the cottage in tufts
		if abs(p.x - COTTAGE_POS.x) < 3.0 and abs(p.z - COTTAGE_POS.z) < 3.0:
			continue
		var s: float = rng.randf_range(0.10, 0.22)
		var c := GRASS_LIGHT if rng.randf() < 0.6 else Color(0.16, 0.36, 0.18)
		_sphere(self, p, s, c, Vector3(1.0, 0.35, 1.0))

# ────────────────────────────────────────────────────────────────────────────
# Tree stumps + cut logs scattered across the farm interior

func _scatter_stumps() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 31
	for i in range(8):
		var p := _random_inside(rng)
		var stump_path: String = NATURE + STUMP_PATHS[rng.randi() % STUMP_PATHS.size()]
		var s: float = rng.randf_range(0.8, 1.4)
		var ry: float = rng.randf() * TAU
		_place_collidable_kenney(stump_path, p, s, ry, 0.4, 0.6)

func _scatter_logs() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 71
	for i in range(5):
		var p := _random_inside(rng)
		var s: float = rng.randf_range(0.7, 1.1)
		var ry: float = rng.randf() * TAU
		_place_collidable_kenney(NATURE + "log_stackLarge.glb", p, s, ry, 0.5, 0.5)

# Scatter small grass patches (Kenney models) — gives the ground grain
func _scatter_grass_patches() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 53
	for i in range(60):
		var p := _random_inside(rng, 1.5, 14.0)
		var path: String = GRASS_PATCH_PATHS[rng.randi() % GRASS_PATCH_PATHS.size()]
		var s: float = rng.randf_range(1.0, 1.6)
		var ry: float = rng.randf() * TAU
		_place_collidable_kenney(path, p, s, ry)  # decorative only

# Random point inside the farm playable rect, biased away from cottage.
func _random_inside(rng: RandomNumberGenerator, min_radius: float = 2.0, max_radius: float = 14.0) -> Vector3:
	for _attempt in range(20):
		var x: float = rng.randf_range(FARM_X_MIN + 1.5, FARM_X_MAX - 1.5)
		var z: float = rng.randf_range(FARM_Z_MIN + 1.5, FARM_Z_MAX - 1.5)
		# Avoid spawning on top of cottage
		if abs(x - COTTAGE_POS.x) < 3.5 and abs(z - COTTAGE_POS.z) < 3.0:
			continue
		# Avoid the path corridor (rough)
		if abs(z) < 1.5 and x > -7 and x < 16:
			continue
		return Vector3(x, 0, z)
	return Vector3(0, 0, 5)  # fallback
