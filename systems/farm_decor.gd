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
	_build_stepping_stones()
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
	_scatter_mushrooms()
	_scatter_grass_tufts()
	# Distinct landmarks
	_build_pond(Vector3(8.5, 0, -8.5), 4.0, 2.5)
	_build_scarecrow(Vector3(2.0, 0, 6.0))
	_build_stone_circle(Vector3(-13.0, 0, 8.0), 2.2)
	_build_picnic_area(Vector3(-2.5, 0, -1.0))
	_build_lantern(Vector3(-4.5, 0, 1.5))
	_build_lantern(Vector3(2.5, 0, -2.5))
	_build_lantern(Vector3(11.0, 0, 0.5))
	_build_dead_tree(Vector3(12.0, 0, 8.0))
	_build_cart(Vector3(-10.0, 0, 4.0))
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
	# Bigger opaque ground plane so the camera never sees the sky past it.
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(160, 160)
	ground.mesh = pm
	ground.material_override = _mat(GRASS_DARK, 0.95)
	add_child(ground)
	# Mottle: opaque (no alpha) — was causing blue-sky bleed through earlier.
	# Discs sit just above the ground and blend visually because they share
	# a similar palette, no transparency required.
	var rng := RandomNumberGenerator.new()
	rng.seed = 17
	for i in range(60):
		var p := Vector3(
			rng.randf_range(FARM_X_MIN, FARM_X_MAX),
			0.015,
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
		disc.material_override = _mat(c, 0.95)  # opaque — no alpha sorting issue
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
	door.set_script(load("res://scripts/door.gd"))  # set BEFORE add_child so _ready() fires
	door.set("target_scene", "res://scenes/cottage_interior.tscn")
	door.position = COTTAGE_POS + Vector3(0, 0.6, 1.95)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.6, 1.8, 1.2)
	col.shape = shape
	door.add_child(col)
	add_child(door)
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
# Perimeter — dense forest of trees + invisible collision walls
# (replaces the old cliff-wall ring; the player can't cross but it looks
# natural rather than walled-in)

func _build_perimeter_walls() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 555
	# Two layers of trees — outer big pines, inner small filler — so the
	# transition feels like a thickening wood edge.
	var perimeter_padding: float = 1.5
	var step: float = 1.6
	var x: float = FARM_X_MIN - perimeter_padding
	while x <= FARM_X_MAX + perimeter_padding:
		_perimeter_tree_pair(rng, Vector3(x, 0, FARM_Z_MIN - perimeter_padding))
		_perimeter_tree_pair(rng, Vector3(x, 0, FARM_Z_MAX + perimeter_padding))
		x += step
	var z: float = FARM_Z_MIN - perimeter_padding
	while z <= FARM_Z_MAX + perimeter_padding:
		_perimeter_tree_pair(rng, Vector3(FARM_X_MIN - perimeter_padding, 0, z))
		# East side: leave a gap for the town gate
		if abs(z) > 3.5:
			_perimeter_tree_pair(rng, Vector3(FARM_X_MAX + perimeter_padding, 0, z))
		z += step
	# Invisible solid walls so the player physically can't cross
	var wall_h: float = 4.0
	var wall_t: float = 1.0
	# North + south
	_add_collider(Vector3(0, wall_h * 0.5, FARM_Z_MIN - 0.5), Vector3(FARM_X_MAX - FARM_X_MIN + 4.0, wall_h, wall_t))
	_add_collider(Vector3(0, wall_h * 0.5, FARM_Z_MAX + 0.5), Vector3(FARM_X_MAX - FARM_X_MIN + 4.0, wall_h, wall_t))
	# West (full)
	_add_collider(Vector3(FARM_X_MIN - 0.5, wall_h * 0.5, 0), Vector3(wall_t, wall_h, FARM_Z_MAX - FARM_Z_MIN + 4.0))
	# East — split into two walls leaving a gap from z=-3.5 to z=3.5 for the town gate
	var gap_top := -3.5
	var gap_bot := 3.5
	var east_top_len: float = gap_top - FARM_Z_MIN + 2.0
	var east_bot_len: float = FARM_Z_MAX - gap_bot + 2.0
	_add_collider(Vector3(FARM_X_MAX + 0.5, wall_h * 0.5, (FARM_Z_MIN + gap_top) * 0.5 - 1.0), Vector3(wall_t, wall_h, east_top_len))
	_add_collider(Vector3(FARM_X_MAX + 0.5, wall_h * 0.5, (gap_bot + FARM_Z_MAX) * 0.5 + 1.0), Vector3(wall_t, wall_h, east_bot_len))

func _perimeter_tree_pair(rng: RandomNumberGenerator, base: Vector3) -> void:
	# 1 large pine + 50% chance of a smaller pine alongside, jittered slightly.
	var tall_path: String = NATURE + ["tree_pineTallA.glb", "tree_pineDefaultA.glb", "tree_pineDefaultB.glb"][rng.randi() % 3]
	var jitter := Vector3(rng.randf_range(-0.4, 0.4), 0, rng.randf_range(-0.4, 0.4))
	var s := rng.randf_range(2.2, 3.0)
	_place_collidable_kenney(tall_path, base + jitter, s, rng.randf() * TAU)  # decorative — invisible walls do collision
	if rng.randf() < 0.5:
		var small_path: String = NATURE + ["tree_pineSmallA.glb", "tree_pineSmallB.glb"][rng.randi() % 2]
		var j2 := Vector3(rng.randf_range(-0.7, 0.7), 0, rng.randf_range(-0.7, 0.7))
		var s2 := rng.randf_range(1.4, 2.0)
		_place_collidable_kenney(small_path, base + jitter + j2, s2, rng.randf() * TAU)

func _build_town_gate() -> void:
	var gate := Area3D.new()
	gate.set_script(load("res://scripts/door.gd"))
	gate.set("target_scene", "res://scenes/town_centre.tscn")
	gate.position = Vector3(FARM_X_MAX + 0.8, 0.6, 0.0)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.0, 1.8, 4.0)
	col.shape = shape
	gate.add_child(col)
	add_child(gate)
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

# ────────────────────────────────────────────────────────────────────────────
# Distinct landmarks — pond, scarecrow, stone circle, picnic, lanterns, etc.

# Stepping stones along the dirt path edge
func _build_stepping_stones() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 121
	var stone_mat := _mat(Color(0.55, 0.52, 0.48), 0.95)
	var pts := [
		Vector3(-7.0, 0.07, -1.2),
		Vector3(-3.0, 0.07, -1.0),
		Vector3(1.0, 0.07, -1.4),
		Vector3(5.0, 0.07, -2.0),
		Vector3(10.0, 0.07, -2.0),
	]
	for p in pts:
		var s := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.7, 0.10, 0.55)
		s.mesh = bm
		s.position = p + Vector3(rng.randf_range(-0.2, 0.2), 0, rng.randf_range(-0.2, 0.2))
		s.rotation.y = rng.randf() * TAU
		s.material_override = stone_mat
		add_child(s)

# Round pond with a stone rim and a still water surface
func _build_pond(center: Vector3, radius_x: float, radius_z: float) -> void:
	# Water surface (flat ellipse)
	var water := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(radius_x * 2.0, radius_z * 2.0)
	water.mesh = pm
	water.position = center + Vector3(0, 0.04, 0)
	var wmat := StandardMaterial3D.new()
	wmat.albedo_color = Color(0.18, 0.45, 0.65, 0.95)
	wmat.metallic = 0.45
	wmat.roughness = 0.15
	wmat.emission_enabled = true
	wmat.emission = Color(0.05, 0.15, 0.25)
	wmat.emission_energy_multiplier = 0.3
	water.material_override = wmat
	add_child(water)
	# Stone rim around the pond — many small rocks placed in an ellipse
	var rng := RandomNumberGenerator.new()
	rng.seed = 333
	var n: int = 24
	for i in range(n):
		var t: float = (i / float(n)) * TAU
		var p := center + Vector3(cos(t) * radius_x * 1.05, 0.0, sin(t) * radius_z * 1.05)
		var rock_path: String = NATURE + ROCK_PATHS[rng.randi() % ROCK_PATHS.size()]
		_place_collidable_kenney(rock_path, p, rng.randf_range(0.7, 1.1), rng.randf() * TAU, 0.3, 0.4)
	# A few lily pads (small green discs)
	for i in range(4):
		var t: float = rng.randf_range(0, TAU)
		var r: float = rng.randf_range(0.0, min(radius_x, radius_z) * 0.6)
		var lily := MeshInstance3D.new()
		var lpm := PlaneMesh.new()
		lpm.size = Vector2(0.5, 0.4)
		lily.mesh = lpm
		lily.position = center + Vector3(cos(t) * r, 0.06, sin(t) * r)
		lily.rotation.y = rng.randf() * TAU
		lily.material_override = _mat(Color(0.22, 0.55, 0.22, 0.95))
		add_child(lily)

# A scarecrow — cross of poles, sphere head with hat, cloth flaps
func _build_scarecrow(origin: Vector3) -> void:
	# Vertical pole
	_box(self, origin + Vector3(0, 1.0, 0), Vector3(0.10, 2.0, 0.10), WOOD_BEAM)
	# Horizontal arms
	_box(self, origin + Vector3(0, 1.55, 0), Vector3(1.4, 0.08, 0.08), WOOD_BEAM)
	# Body cloth (hanging shirt)
	_box(self, origin + Vector3(0, 1.25, 0), Vector3(0.7, 0.7, 0.05), Color(0.55, 0.30, 0.25))
	# Sleeves
	_box(self, origin + Vector3(-0.55, 1.55, 0), Vector3(0.30, 0.10, 0.10), Color(0.55, 0.30, 0.25))
	_box(self, origin + Vector3( 0.55, 1.55, 0), Vector3(0.30, 0.10, 0.10), Color(0.55, 0.30, 0.25))
	# Head — straw sphere
	_sphere(self, origin + Vector3(0, 2.10, 0), 0.22, Color(0.92, 0.80, 0.42))
	# Hat brim + cone
	_cyl(self, origin + Vector3(0, 2.32, 0), 0.40, 0.04, Color(0.30, 0.20, 0.12))
	var hat_top := MeshInstance3D.new()
	var hm := CylinderMesh.new()
	hm.top_radius = 0.0
	hm.bottom_radius = 0.22
	hm.height = 0.30
	hat_top.mesh = hm
	hat_top.position = origin + Vector3(0, 2.50, 0)
	hat_top.material_override = _mat(Color(0.30, 0.20, 0.12))
	add_child(hat_top)
	# Eyes (×)
	_sphere(self, origin + Vector3(-0.08, 2.12, 0.18), 0.030, Color.BLACK)
	_sphere(self, origin + Vector3( 0.08, 2.12, 0.18), 0.030, Color.BLACK)
	# Solid collider
	var body := StaticBody3D.new()
	body.position = origin + Vector3(0, 1.0, 0)
	add_child(body)
	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.25
	shape.height = 2.5
	col.shape = shape
	body.add_child(col)

# Stone circle — 6 standing stones in a ring
func _build_stone_circle(center: Vector3, radius: float) -> void:
	var n: int = 6
	for i in range(n):
		var t: float = (i / float(n)) * TAU
		var p := center + Vector3(cos(t) * radius, 0, sin(t) * radius)
		var stone := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.45, 1.6 + (i % 2) * 0.4, 0.40)
		stone.mesh = bm
		stone.position = p + Vector3(0, bm.size.y * 0.5, 0)
		stone.rotation.y = t + randf_range(-0.2, 0.2)
		stone.material_override = _mat(Color(0.45, 0.42, 0.38))
		add_child(stone)
		# Collision
		var body := StaticBody3D.new()
		body.position = stone.position
		add_child(body)
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = bm.size
		col.shape = shape
		body.add_child(col)

# Picnic table + 2 benches
func _build_picnic_area(origin: Vector3) -> void:
	# Tabletop
	_box(self, origin + Vector3(0, 0.65, 0), Vector3(2.4, 0.10, 1.0), Color(0.55, 0.36, 0.22))
	# Legs
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_box(self, origin + Vector3(sx * 1.0, 0.32, sz * 0.4), Vector3(0.10, 0.65, 0.10), Color(0.32, 0.20, 0.12))
	# Benches
	_box(self, origin + Vector3(0, 0.40,  0.85), Vector3(2.4, 0.08, 0.30), Color(0.62, 0.42, 0.26))
	_box(self, origin + Vector3(0, 0.40, -0.85), Vector3(2.4, 0.08, 0.30), Color(0.62, 0.42, 0.26))
	for sx in [-1.0, 1.0]:
		_box(self, origin + Vector3(sx * 1.0, 0.20,  0.85), Vector3(0.08, 0.40, 0.08), Color(0.32, 0.20, 0.12))
		_box(self, origin + Vector3(sx * 1.0, 0.20, -0.85), Vector3(0.08, 0.40, 0.08), Color(0.32, 0.20, 0.12))
	# Table collider only
	_add_collider(origin + Vector3(0, 0.5, 0), Vector3(2.4, 1.0, 1.0))

# Wooden lantern post with a glowing top (and a real OmniLight3D)
func _build_lantern(origin: Vector3) -> void:
	_box(self, origin + Vector3(0, 0.85, 0), Vector3(0.08, 1.7, 0.08), Color(0.30, 0.20, 0.12))
	# Lantern box
	_box(self, origin + Vector3(0, 1.85, 0), Vector3(0.28, 0.30, 0.28), Color(0.28, 0.20, 0.12))
	# Glow sphere inside
	var glow := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.10
	sm.height = 0.20
	glow.mesh = sm
	glow.position = origin + Vector3(0, 1.85, 0)
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color(1.0, 0.9, 0.55)
	gmat.emission_enabled = true
	gmat.emission = Color(1.0, 0.78, 0.38)
	gmat.emission_energy_multiplier = 2.0
	glow.material_override = gmat
	add_child(glow)
	# Real light
	var light := OmniLight3D.new()
	light.position = origin + Vector3(0, 1.85, 0)
	light.light_color = Color(1.0, 0.85, 0.55)
	light.light_energy = 1.4
	light.omni_range = 6.0
	add_child(light)
	# Slim collider
	_add_collider(origin + Vector3(0, 0.85, 0), Vector3(0.2, 1.7, 0.2))

# Big dead tree — twisted dark trunk with branchy silhouette, no leaves
func _build_dead_tree(origin: Vector3) -> void:
	# Trunk
	_cyl(self, origin + Vector3(0, 1.6, 0), 0.32, 3.2, Color(0.18, 0.12, 0.08))
	# Branches (4 angled boxes)
	var branches := [
		[Vector3(0.4, 2.6, 0.0), Vector3(1.2, 0.18, 0.18), Vector3(0, 0, deg_to_rad(-25))],
		[Vector3(-0.4, 2.4, 0.0), Vector3(1.2, 0.18, 0.18), Vector3(0, 0, deg_to_rad(25))],
		[Vector3(0.0, 3.0, 0.4),  Vector3(0.18, 0.18, 1.2), Vector3(deg_to_rad(-25), 0, 0)],
		[Vector3(0.0, 2.7, -0.4), Vector3(0.18, 0.18, 1.0), Vector3(deg_to_rad(25), 0, 0)],
	]
	for b in branches:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = b[1]
		mi.mesh = bm
		mi.position = origin + b[0]
		mi.rotation = b[2]
		mi.material_override = _mat(Color(0.16, 0.10, 0.06))
		add_child(mi)
	# Cylinder collider
	var body := StaticBody3D.new()
	body.position = origin + Vector3(0, 1.6, 0)
	add_child(body)
	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.4
	shape.height = 3.2
	col.shape = shape
	body.add_child(col)

# Wooden cart — bed with 2 wheels, abandoned look
func _build_cart(origin: Vector3) -> void:
	# Bed
	_box(self, origin + Vector3(0, 0.55, 0), Vector3(1.6, 0.12, 0.9), Color(0.55, 0.36, 0.22))
	# Side rails
	_box(self, origin + Vector3(0, 0.85, -0.42), Vector3(1.6, 0.36, 0.06), Color(0.45, 0.30, 0.18))
	_box(self, origin + Vector3(0, 0.85,  0.42), Vector3(1.6, 0.36, 0.06), Color(0.45, 0.30, 0.18))
	_box(self, origin + Vector3(0.78, 0.85, 0), Vector3(0.06, 0.36, 0.9), Color(0.45, 0.30, 0.18))
	# Wheels
	for sx in [-0.5, 0.5]:
		var w := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.32
		cm.bottom_radius = 0.32
		cm.height = 0.10
		w.mesh = cm
		w.position = origin + Vector3(sx, 0.32, 0.55)
		w.rotation = Vector3(deg_to_rad(90), 0, 0)
		w.material_override = _mat(Color(0.30, 0.20, 0.12))
		add_child(w)
		# Hub
		_sphere(self, origin + Vector3(sx, 0.32, 0.55), 0.06, Color(0.18, 0.12, 0.08))
	# Tongue
	_box(self, origin + Vector3(1.2, 0.55, 0), Vector3(1.0, 0.06, 0.06), Color(0.32, 0.20, 0.12))
	# Collider
	_add_collider(origin + Vector3(0, 0.5, 0), Vector3(1.8, 1.0, 1.0))

# Mushroom clusters — tiny coloured caps grouped together
func _scatter_mushrooms() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 88
	var cap_colors := [Color(0.78, 0.22, 0.20), Color(0.85, 0.55, 0.18), Color(0.62, 0.45, 0.85)]
	for c in range(8):  # 8 clusters
		var origin := _random_inside(rng, 3.0, 13.0)
		var n := rng.randi_range(3, 6)
		for i in range(n):
			var p := origin + Vector3(rng.randf_range(-0.4, 0.4), 0.0, rng.randf_range(-0.4, 0.4))
			# Stem
			_cyl(self, p + Vector3(0, 0.08, 0), 0.04, 0.16, Color(0.95, 0.92, 0.80))
			# Cap
			var cap_color: Color = cap_colors[rng.randi() % cap_colors.size()]
			_sphere(self, p + Vector3(0, 0.18, 0), 0.10, cap_color, Vector3(1.0, 0.6, 1.0))
