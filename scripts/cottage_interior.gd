extends Node3D
## Cottage interior. A small wood-floored room with furniture. The exit door
## sits at the south wall and warps back to the main farm scene.

const SURVIVAL := "res://assets/models/survival/"

func _ready() -> void:
	_build_room()
	_furnish()
	_build_exit_door()

func _build_room() -> void:
	# Floor (planked wood)
	var floor := MeshInstance3D.new()
	var fm := PlaneMesh.new()
	fm.size = Vector2(10, 8)
	floor.mesh = fm
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = Color(0.50, 0.34, 0.20)
	fmat.roughness = 0.85
	floor.material_override = fmat
	add_child(floor)

	# Walls — 4 sides + collision
	_wall(Vector3(0, 1.5, -4), Vector3(10, 3, 0.2), Color(0.78, 0.66, 0.48))   # north
	_wall(Vector3(0, 1.5,  4), Vector3(10, 3, 0.2), Color(0.78, 0.66, 0.48))   # south (door wall)
	_wall(Vector3(-5, 1.5, 0), Vector3(0.2, 3, 8), Color(0.72, 0.60, 0.42))   # west
	_wall(Vector3( 5, 1.5, 0), Vector3(0.2, 3, 8), Color(0.72, 0.60, 0.42))   # east

	# Ceiling support beams (decorative, no collision needed)
	for x in [-3.0, 0.0, 3.0]:
		var beam := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.2, 0.2, 7.6)
		beam.mesh = bm
		beam.position = Vector3(x, 2.85, 0)
		var bmat := StandardMaterial3D.new()
		bmat.albedo_color = Color(0.32, 0.20, 0.12)
		beam.material_override = bmat
		add_child(beam)

	# Warm rug
	var rug := MeshInstance3D.new()
	var rm := PlaneMesh.new()
	rm.size = Vector2(3.4, 2.0)
	rug.mesh = rm
	rug.position = Vector3(0, 0.02, 0)
	var rmat := StandardMaterial3D.new()
	rmat.albedo_color = Color(0.58, 0.30, 0.25)
	rug.material_override = rmat
	add_child(rug)

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
	# Collision
	var body := StaticBody3D.new()
	body.position = pos
	add_child(body)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)

func _furnish() -> void:
	# Bed — north wall
	_box(Vector3(-3.5, 0.4, -3.0), Vector3(2.0, 0.5, 2.4), Color(0.82, 0.74, 0.58))
	_box(Vector3(-3.5, 0.85, -3.5), Vector3(2.0, 0.4, 1.4), Color(0.95, 0.88, 0.78))
	_box(Vector3(-3.5, 0.95, -3.95), Vector3(1.6, 0.25, 0.4), Color(0.55, 0.30, 0.30))
	# Table
	_box(Vector3(2.0, 0.45, -1.5), Vector3(2.0, 0.1, 1.2), Color(0.55, 0.36, 0.22))
	for sx in [-0.85, 0.85]:
		for sz in [-0.5, 0.5]:
			_box(Vector3(2.0 + sx, 0.22, -1.5 + sz), Vector3(0.12, 0.45, 0.12), Color(0.32, 0.20, 0.12))
	# Chair
	_box(Vector3(2.0, 0.25, -0.4), Vector3(0.6, 0.05, 0.6), Color(0.42, 0.28, 0.16))
	# Chest (Kenney)
	var packed: PackedScene = load(SURVIVAL + "chest.glb")
	if packed != null:
		var inst: Node3D = packed.instantiate()
		inst.position = Vector3(3.5, 0, 2.5)
		inst.scale = Vector3(1.4, 1.4, 1.4)
		inst.rotation.y = deg_to_rad(180)
		add_child(inst)
	# Barrel
	var packed2: PackedScene = load(SURVIVAL + "barrel.glb")
	if packed2 != null:
		var inst: Node3D = packed2.instantiate()
		inst.position = Vector3(-3.5, 0, 2.5)
		inst.scale = Vector3(1.4, 1.4, 1.4)
		add_child(inst)

func _box(pos: Vector3, size: Vector3, color: Color) -> void:
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

func _build_exit_door() -> void:
	var door := Area3D.new()
	door.position = Vector3(0, 0.6, 3.85)
	add_child(door)
	door.set_script(load("res://scripts/door.gd"))
	door.set("target_scene", "res://scenes/main.tscn")
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.4, 1.4, 0.4)
	col.shape = shape
	door.add_child(col)
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
	# Glow marker
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
	marker.position = Vector3(0, -0.2, 0)
	door.add_child(marker)
