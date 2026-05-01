extends Node3D
## Procedural farm decoration. Builds the cottage, trees, fence, rocks, mailbox,
## signpost — everything except the player + farm grid + sky.
## Styled after the concept-art gameplay mockup: blue-shingled cottage,
## picket fence around the garden plots, conifer trees, scattered rocks.

# ────────────────────────────────────────────────────────────────────────────
# Palette (matches concept art)

const STONE        := Color(0.55, 0.52, 0.48)
const STONE_DARK   := Color(0.38, 0.36, 0.34)
const WOOD_WALL    := Color(0.52, 0.36, 0.22)
const WOOD_BEAM    := Color(0.30, 0.20, 0.12)
const ROOF_BLUE    := Color(0.30, 0.42, 0.55)
const ROOF_BLUE_D  := Color(0.22, 0.32, 0.42)
const DOOR         := Color(0.32, 0.20, 0.12)
const WINDOW_GLASS := Color(0.78, 0.88, 0.92)
const CHIMNEY_BRICK:= Color(0.55, 0.30, 0.22)

const TREE_TRUNK   := Color(0.30, 0.20, 0.12)
const TREE_GREEN_1 := Color(0.20, 0.42, 0.22)
const TREE_GREEN_2 := Color(0.16, 0.36, 0.18)
const TREE_GREEN_3 := Color(0.12, 0.30, 0.14)

const ROCK_GRAY    := Color(0.55, 0.52, 0.50)
const FENCE_WOOD   := Color(0.78, 0.62, 0.42)
const PATH_DIRT    := Color(0.62, 0.48, 0.30)
const GRASS_DARK   := Color(0.30, 0.48, 0.22)
const GRASS_LIGHT  := Color(0.45, 0.62, 0.30)

# ────────────────────────────────────────────────────────────────────────────

func _ready() -> void:
	_build_ground()
	_build_path()
	_build_cottage(Vector3(-9.0, 0, -3.0))
	_build_well(Vector3(-4.5, 0, -7.0))
	_build_mailbox(Vector3(-4.5, 0, 5.5))
	_build_signpost(Vector3(8.0, 0, 1.0), "FOREST TRAIL")
	_build_fence_around_farm()
	_scatter_trees()
	_scatter_rocks()
	_scatter_grass_tufts()

# ────────────────────────────────────────────────────────────────────────────
# Mesh helpers

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

func _cone(parent: Node, pos: Vector3, radius_bot: float, height: float, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.0
	cm.bottom_radius = radius_bot
	cm.height = height
	cm.radial_segments = 14
	mi.mesh = cm
	mi.position = pos
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
# Ground (replaces the flat plane in main.tscn)

func _build_ground() -> void:
	# A larger darker grass disc with subtle variation
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
	# Dirt path running from in front of the cottage, past the mailbox, off to the forest
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
# Cottage — stone foundation, wood walls, blue shingled roof, chimney

func _build_cottage(origin: Vector3) -> void:
	# Stone foundation
	_box(self, origin + Vector3(0, 0.30, 0), Vector3(4.4, 0.60, 3.6), STONE)
	# Wood walls
	_box(self, origin + Vector3(0, 1.40, 0), Vector3(4.0, 1.60, 3.2), WOOD_WALL)
	# Corner posts (dark wood beams)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_box(self, origin + Vector3(sx * 1.92, 1.4, sz * 1.52), Vector3(0.16, 1.65, 0.16), WOOD_BEAM)
	# Door
	_box(self, origin + Vector3(0, 1.0, 1.62), Vector3(0.7, 1.2, 0.05), DOOR)
	# Door step
	_box(self, origin + Vector3(0, 0.65, 1.78), Vector3(0.9, 0.10, 0.30), STONE)
	# Windows
	_box(self, origin + Vector3(-1.3, 1.55, 1.62), Vector3(0.55, 0.55, 0.04), WINDOW_GLASS)
	_box(self, origin + Vector3( 1.3, 1.55, 1.62), Vector3(0.55, 0.55, 0.04), WINDOW_GLASS)
	# Window frames
	_box(self, origin + Vector3(-1.3, 1.55, 1.64), Vector3(0.05, 0.55, 0.06), WOOD_BEAM)
	_box(self, origin + Vector3( 1.3, 1.55, 1.64), Vector3(0.05, 0.55, 0.06), WOOD_BEAM)
	_box(self, origin + Vector3(-1.3, 1.55, 1.64), Vector3(0.55, 0.05, 0.06), WOOD_BEAM)
	_box(self, origin + Vector3( 1.3, 1.55, 1.64), Vector3(0.55, 0.05, 0.06), WOOD_BEAM)

	# Roof — gable, two sloped boxes
	for sz_sign in [-1.0, 1.0]:
		var slope := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(4.6, 0.18, 2.2)
		slope.mesh = bm
		slope.position = origin + Vector3(0, 2.95, sz_sign * 0.8)
		slope.rotation = Vector3(deg_to_rad(40.0 * sz_sign), 0, 0)
		slope.material_override = _mat(ROOF_BLUE, 0.7)
		add_child(slope)
	# Roof ridge
	_box(self, origin + Vector3(0, 3.55, 0), Vector3(4.7, 0.12, 0.16), ROOF_BLUE_D)
	# Gable end triangles (front + back)
	_prism(origin + Vector3(0, 2.95, -1.6), Vector3(4.0, 1.2, 0.10), WOOD_WALL)
	_prism(origin + Vector3(0, 2.95,  1.6), Vector3(4.0, 1.2, 0.10), WOOD_WALL)

	# Chimney
	_box(self, origin + Vector3(1.4, 3.6, -0.5), Vector3(0.5, 1.6, 0.5), CHIMNEY_BRICK)
	_box(self, origin + Vector3(1.4, 4.45, -0.5), Vector3(0.7, 0.18, 0.7), STONE_DARK)

# ────────────────────────────────────────────────────────────────────────────
# Well

func _build_well(origin: Vector3) -> void:
	_cyl(self, origin + Vector3(0, 0.45, 0), 0.9, 0.9, STONE)
	_cyl(self, origin + Vector3(0, 0.95, 0), 0.92, 0.10, STONE_DARK)
	# Posts holding roof
	_box(self, origin + Vector3(-0.7, 1.5, 0), Vector3(0.10, 1.1, 0.10), WOOD_BEAM)
	_box(self, origin + Vector3( 0.7, 1.5, 0), Vector3(0.10, 1.1, 0.10), WOOD_BEAM)
	# Tiny roof
	for sx in [-1.0, 1.0]:
		var slope := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(1.2, 0.08, 1.4)
		slope.mesh = bm
		slope.position = origin + Vector3(sx * 0.45, 2.15, 0)
		slope.rotation = Vector3(0, 0, deg_to_rad(-35.0 * sx))
		slope.material_override = _mat(ROOF_BLUE)
		add_child(slope)

# ────────────────────────────────────────────────────────────────────────────
# Mailbox

func _build_mailbox(origin: Vector3) -> void:
	_box(self, origin + Vector3(0, 0.55, 0), Vector3(0.10, 1.1, 0.10), WOOD_BEAM)
	_box(self, origin + Vector3(0, 1.20, 0), Vector3(0.40, 0.30, 0.55), Color(0.72, 0.30, 0.20))
	# Little flag
	_box(self, origin + Vector3(0.22, 1.30, 0), Vector3(0.04, 0.18, 0.10), Color(0.85, 0.20, 0.15))

# ────────────────────────────────────────────────────────────────────────────
# Signpost

func _build_signpost(origin: Vector3, _label: String) -> void:
	_box(self, origin + Vector3(0, 1.0, 0), Vector3(0.12, 2.0, 0.12), WOOD_BEAM)
	_box(self, origin + Vector3(0.30, 1.65, 0), Vector3(0.85, 0.30, 0.06), Color(0.72, 0.55, 0.35))

# ────────────────────────────────────────────────────────────────────────────
# Picket fence around the farm grid (which sits roughly x:[-5.6..4.5], z:[-6.7..4.0])

func _build_fence_around_farm() -> void:
	var x_min: float = -6.4
	var x_max: float = 5.5
	var z_min: float = -7.5
	var z_max: float = 4.8
	var step: float = 1.2
	var rail_h: float = 0.10
	# Bottom side
	_fence_run(Vector3(x_min, 0, z_max), Vector3(x_max, 0, z_max), step)
	# Top side
	_fence_run(Vector3(x_min, 0, z_min), Vector3(x_max, 0, z_min), step)
	# Left side
	_fence_run(Vector3(x_min, 0, z_min), Vector3(x_min, 0, z_max), step)
	# Right side (with a gap for the path exit)
	_fence_run(Vector3(x_max, 0, z_min), Vector3(x_max, 0, -0.5), step)
	_fence_run(Vector3(x_max, 0, 2.5), Vector3(x_max, 0, z_max), step)

func _fence_run(a: Vector3, b: Vector3, step: float) -> void:
	var dist: float = a.distance_to(b)
	var dir: Vector3 = (b - a).normalized()
	var n: int = int(dist / step)
	for i in range(n + 1):
		var p: Vector3 = a + dir * (i * step)
		# Post
		_box(self, p + Vector3(0, 0.45, 0), Vector3(0.10, 0.9, 0.10), FENCE_WOOD)
		# Tiny pointed cap
		_cone(self, p + Vector3(0, 0.95, 0), 0.10, 0.12, FENCE_WOOD)
	# Two horizontal rails between posts
	var mid: Vector3 = (a + b) * 0.5
	var size: Vector3
	if abs(dir.x) > abs(dir.z):
		size = Vector3(dist, 0.06, 0.04)
	else:
		size = Vector3(0.04, 0.06, dist)
	_box(self, mid + Vector3(0, 0.30, 0), size, FENCE_WOOD)
	_box(self, mid + Vector3(0, 0.65, 0), size, FENCE_WOOD)

# ────────────────────────────────────────────────────────────────────────────
# Trees (conifers — three stacked cones on a trunk, like the concept art)

func _scatter_trees() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var positions: Array = []
	# Ring of trees around the perimeter
	for i in range(28):
		var angle: float = (i / 28.0) * TAU + rng.randf_range(-0.05, 0.05)
		var radius: float = rng.randf_range(14.0, 22.0)
		var x: float = cos(angle) * radius
		var z: float = sin(angle) * radius * 0.7
		positions.append(Vector3(x, 0, z))
	# A few extra clumps near the cottage
	positions.append(Vector3(-13.0, 0, -8.0))
	positions.append(Vector3(-12.0, 0, -5.5))
	positions.append(Vector3(-14.0, 0, 2.0))
	for p in positions:
		_build_tree(p, rng.randf_range(0.85, 1.25))

func _build_tree(origin: Vector3, scale: float) -> void:
	var s: float = scale
	# Trunk
	_cyl(self, origin + Vector3(0, 0.4 * s, 0), 0.18 * s, 0.8 * s, TREE_TRUNK)
	# Foliage cones (stacked, darker as they go up to add depth)
	_cone(self, origin + Vector3(0, 1.0 * s, 0), 1.05 * s, 1.3 * s, TREE_GREEN_1)
	_cone(self, origin + Vector3(0, 1.85 * s, 0), 0.85 * s, 1.1 * s, TREE_GREEN_2)
	_cone(self, origin + Vector3(0, 2.6 * s, 0), 0.55 * s, 0.85 * s, TREE_GREEN_3)

# ────────────────────────────────────────────────────────────────────────────
# Rocks

func _scatter_rocks() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	for i in range(14):
		var angle: float = rng.randf() * TAU
		var radius: float = rng.randf_range(8.0, 18.0)
		var p := Vector3(cos(angle) * radius, 0.0, sin(angle) * radius * 0.7)
		var sz: float = rng.randf_range(0.5, 1.1)
		var r := _sphere(self, p + Vector3(0, sz * 0.25, 0), sz * 0.5, ROCK_GRAY, Vector3(1.0, 0.55, 1.0))
		r.rotation.y = rng.randf() * TAU

# ────────────────────────────────────────────────────────────────────────────
# Grass tufts (lots of tiny green spheres for life)

func _scatter_grass_tufts() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in range(120):
		var angle: float = rng.randf() * TAU
		var radius: float = rng.randf_range(7.0, 20.0)
		var p := Vector3(cos(angle) * radius, 0.04, sin(angle) * radius * 0.85)
		var s: float = rng.randf_range(0.10, 0.22)
		_sphere(self, p, s, GRASS_LIGHT if rng.randf() < 0.6 else TREE_GREEN_2, Vector3(1.0, 0.35, 1.0))
