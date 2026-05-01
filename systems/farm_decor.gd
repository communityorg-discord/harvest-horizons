extends Node3D
## Procedural farm decoration using Kenney CC0 nature/survival models for the
## natural elements (trees, rocks, fences, flowers, signpost, chest, log stack)
## and procedural primitives for the cottage / mailbox / well (no matching
## Kenney models in the packs we pulled).

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
# Kenney model paths (loaded once, instanced many times)

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

# ────────────────────────────────────────────────────────────────────────────

func _ready() -> void:
	_build_ground()
	_build_path()
	_build_cottage(Vector3(-9.0, 0, -3.0))
	_build_well(Vector3(-4.5, 0, -7.0))
	_build_mailbox(Vector3(-4.5, 0, 5.5))
	_place_kenney(SURVIVAL + "signpost.glb", Vector3(8.0, 0, 1.0), 1.6, 0.0)
	_place_kenney(SURVIVAL + "chest.glb",   Vector3(-7.6, 0, -1.2), 1.6, deg_to_rad(-25))
	_place_kenney(SURVIVAL + "barrel.glb",  Vector3(-6.6, 0, -0.8), 1.4, 0.0)
	_place_kenney(NATURE + "log_stackLarge.glb", Vector3(-11.5, 0, 0.0), 1.4, deg_to_rad(20))
	_build_fence_around_farm()
	_scatter_trees()
	_scatter_rocks()
	_scatter_flowers()
	_scatter_grass_tufts()

# ────────────────────────────────────────────────────────────────────────────
# Kenney model placement

func _place_kenney(path: String, pos: Vector3, scale: float = 1.0, rot_y: float = 0.0) -> Node3D:
	var packed: PackedScene = load(path)
	if packed == null:
		push_warning("Missing model: %s" % path)
		return null
	var node: Node3D = packed.instantiate()
	node.position = pos
	node.scale = Vector3(scale, scale, scale)
	node.rotation.y = rot_y
	add_child(node)
	return node

# ────────────────────────────────────────────────────────────────────────────
# Procedural primitive helpers (used for cottage etc.)

func _mat(color: Color, rough: float = 0.9) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	return m

func _box(parent: Node, pos: Vector3, size: Vector3, color: Color, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.position = pos
	mi.rotation = rot
	mi.material_override = _mat(color)
	add_child(mi)
	return mi

func _cyl(parent: Node, pos: Vector3, radius: float, height: float, color: Color) -> MeshInstance3D:
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

func _sphere(parent: Node, pos: Vector3, radius: float, color: Color, scale: Vector3 = Vector3.ONE) -> MeshInstance3D:
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

# ────────────────────────────────────────────────────────────────────────────
# Ground + path

func _build_ground() -> void:
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(80, 80)
	ground.mesh = pm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = GRASS_DARK
	mat.roughness = 0.95
	ground.material_override = mat
	ground.position = Vector3(0, 0, 0)
	add_child(ground)

func _build_path() -> void:
	var path_mat := _mat(PATH_DIRT, 0.95)
	for i in range(20):
		var t: float = i / 19.0
		var x: float = lerp(-6.0, 9.0, t)
		var z: float = lerp(-1.0, 1.5, t) + sin(t * 3.0) * 0.6
		var seg := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(1.6, 0.06, 1.4)
		seg.mesh = bm
		seg.position = Vector3(x, 0.04, z)
		seg.material_override = path_mat
		add_child(seg)

# ────────────────────────────────────────────────────────────────────────────
# Cottage (procedural — no matching Kenney model)

func _build_cottage(origin: Vector3) -> void:
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

# ────────────────────────────────────────────────────────────────────────────
# Well + mailbox (procedural)

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

func _build_mailbox(origin: Vector3) -> void:
	_box(self, origin + Vector3(0, 0.55, 0), Vector3(0.10, 1.1, 0.10), WOOD_BEAM)
	_box(self, origin + Vector3(0, 1.20, 0), Vector3(0.40, 0.30, 0.55), Color(0.72, 0.30, 0.20))
	_box(self, origin + Vector3(0.22, 1.30, 0), Vector3(0.04, 0.18, 0.10), Color(0.85, 0.20, 0.15))

# ────────────────────────────────────────────────────────────────────────────
# Picket fence — Kenney fence_simple instances along the perimeter

func _build_fence_around_farm() -> void:
	var x_min: float = -6.4
	var x_max: float = 5.5
	var z_min: float = -7.5
	var z_max: float = 4.8
	var step: float = 1.0
	# Bottom
	_fence_run_kenney(Vector3(x_min, 0, z_max), Vector3(x_max, 0, z_max), step, 0.0)
	# Top
	_fence_run_kenney(Vector3(x_min, 0, z_min), Vector3(x_max, 0, z_min), step, 0.0)
	# Left
	_fence_run_kenney(Vector3(x_min, 0, z_min), Vector3(x_min, 0, z_max), step, deg_to_rad(90))
	# Right (with gap for path)
	_fence_run_kenney(Vector3(x_max, 0, z_min), Vector3(x_max, 0, -0.5), step, deg_to_rad(90))
	_fence_run_kenney(Vector3(x_max, 0, 2.5), Vector3(x_max, 0, z_max), step, deg_to_rad(90))

func _fence_run_kenney(a: Vector3, b: Vector3, step: float, rot_y: float) -> void:
	var dist: float = a.distance_to(b)
	var dir: Vector3 = (b - a).normalized()
	var n: int = int(dist / step)
	for i in range(n):
		var p: Vector3 = a + dir * (i * step + step * 0.5)
		_place_kenney(NATURE + "fence_simple.glb", p, 1.0, rot_y)

# ────────────────────────────────────────────────────────────────────────────
# Trees — Kenney variety scattered around perimeter

func _scatter_trees() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var positions: Array = []
	for i in range(32):
		var angle: float = (i / 32.0) * TAU + rng.randf_range(-0.05, 0.05)
		var radius: float = rng.randf_range(13.0, 22.0)
		var x: float = cos(angle) * radius
		var z: float = sin(angle) * radius * 0.75
		positions.append(Vector3(x, 0, z))
	# Cottage-side cluster
	positions.append(Vector3(-13.0, 0, -8.0))
	positions.append(Vector3(-12.0, 0, -5.5))
	positions.append(Vector3(-14.0, 0, 2.0))
	positions.append(Vector3(-13.5, 0, 5.0))
	for p in positions:
		var tree_path: String = NATURE + TREE_PATHS[rng.randi() % TREE_PATHS.size()]
		var s: float = rng.randf_range(1.6, 2.4)
		var ry: float = rng.randf() * TAU
		_place_kenney(tree_path, p, s, ry)

# ────────────────────────────────────────────────────────────────────────────
# Rocks (Kenney)

func _scatter_rocks() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	for i in range(18):
		var angle: float = rng.randf() * TAU
		var radius: float = rng.randf_range(7.5, 18.0)
		var p := Vector3(cos(angle) * radius, 0.0, sin(angle) * radius * 0.75)
		var rock_path: String = NATURE + ROCK_PATHS[rng.randi() % ROCK_PATHS.size()]
		var s: float = rng.randf_range(1.0, 1.8)
		var ry: float = rng.randf() * TAU
		_place_kenney(rock_path, p, s, ry)

# ────────────────────────────────────────────────────────────────────────────
# Flowers (Kenney) — sprinkled near the cottage and along the fence inside

func _scatter_flowers() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 13
	for i in range(40):
		var angle: float = rng.randf() * TAU
		var radius: float = rng.randf_range(4.5, 12.0)
		var p := Vector3(cos(angle) * radius, 0.0, sin(angle) * radius * 0.85)
		var flower_path: String = NATURE + FLOWER_PATHS[rng.randi() % FLOWER_PATHS.size()]
		var s: float = rng.randf_range(0.8, 1.3)
		var ry: float = rng.randf() * TAU
		_place_kenney(flower_path, p, s, ry)

# ────────────────────────────────────────────────────────────────────────────
# Grass tufts (procedural — small and many, kept as primitives for performance)

func _scatter_grass_tufts() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in range(120):
		var angle: float = rng.randf() * TAU
		var radius: float = rng.randf_range(7.0, 20.0)
		var p := Vector3(cos(angle) * radius, 0.04, sin(angle) * radius * 0.85)
		var s: float = rng.randf_range(0.10, 0.22)
		var c := GRASS_LIGHT if rng.randf() < 0.6 else Color(0.16, 0.36, 0.18)
		_sphere(self, p, s, c, Vector3(1.0, 0.35, 1.0))
