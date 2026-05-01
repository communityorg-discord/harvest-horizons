extends Node3D
## Procedural grid of soil tiles. Holds tile state, draws ground + crop meshes,
## handles tool actions from the player.

@export var rows: int = 8
@export var cols: int = 8
@export var tile_size: float = 1.4
@export var origin_offset: Vector3 = Vector3(-5.6, 0.05, 4.0)

enum State { GRASS, TILLED, WATERED, PLANTED, GROWING, READY }

const COLORS := {
	State.GRASS:   Color(0.42, 0.62, 0.32),
	State.TILLED:  Color(0.55, 0.38, 0.22),
	State.WATERED: Color(0.32, 0.22, 0.13),
	State.PLANTED: Color(0.34, 0.24, 0.14),
	State.GROWING: Color(0.30, 0.22, 0.13),
	State.READY:   Color(0.28, 0.20, 0.12),
}

const CROP_COLORS := {
	State.PLANTED: Color(0.55, 0.78, 0.32),
	State.GROWING: Color(0.42, 0.68, 0.28),
	State.READY:   Color(0.92, 0.72, 0.22),
}

# Each entry: {state, growth_remaining, ground (MeshInstance3D), crop (MeshInstance3D)}
var _tiles: Array = []

func _ready() -> void:
	_tiles.resize(rows)
	for r in range(rows):
		_tiles[r] = []
		for c in range(cols):
			var t := _build_tile(r, c)
			_tiles[r].append(t)

func _process(delta: float) -> void:
	for r in range(rows):
		for c in range(cols):
			var t: Dictionary = _tiles[r][c]
			if t.state == State.PLANTED or t.state == State.GROWING:
				t.growth_remaining -= delta
				if t.growth_remaining <= 0.0:
					_advance(t)

func _build_tile(r: int, c: int) -> Dictionary:
	var pos := Vector3(c * tile_size, 0, -r * tile_size) + origin_offset

	var ground := MeshInstance3D.new()
	var gm := BoxMesh.new()
	gm.size = Vector3(tile_size * 0.95, 0.06, tile_size * 0.95)
	ground.mesh = gm
	ground.position = pos
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = COLORS[State.GRASS]
	gmat.roughness = 0.95
	ground.material_override = gmat
	add_child(ground)

	# Crop visual: a Node3D container that swaps Kenney corn-stage models in
	# as the plant grows.
	var crop := Node3D.new()
	crop.position = pos + Vector3(0, 0.06, 0)
	crop.visible = false
	add_child(crop)
	# We'll instance the right corn-stage model lazily in _refresh.

	return {
		"state": State.GRASS,
		"growth_remaining": 0.0,
		"ground": ground,
		"crop": crop,
		"row": r,
		"col": c,
	}

func _advance(t: Dictionary) -> void:
	if t.state == State.PLANTED:
		t.state = State.GROWING
		t.growth_remaining = 4.0
	elif t.state == State.GROWING:
		t.state = State.READY
		t.growth_remaining = 0.0
	_refresh(t)

const CROP_STAGE_MODELS := {
	State.PLANTED: "res://assets/models/nature/crops_cornStageA.glb",
	State.GROWING: "res://assets/models/nature/crops_cornStageB.glb",
	State.READY:   "res://assets/models/nature/crops_cornStageD.glb",
}

func _refresh(t: Dictionary) -> void:
	var gmat: StandardMaterial3D = t.ground.material_override
	gmat.albedo_color = COLORS[t.state]
	# Clear any existing crop visual children
	for child in t.crop.get_children():
		child.queue_free()
	if t.state >= State.PLANTED:
		t.crop.visible = true
		var path: String = CROP_STAGE_MODELS.get(t.state, CROP_STAGE_MODELS[State.PLANTED])
		var packed: PackedScene = load(path)
		if packed != null:
			var inst: Node3D = packed.instantiate()
			inst.scale = Vector3(0.95, 0.95, 0.95)
			t.crop.add_child(inst)
	else:
		t.crop.visible = false

# ────────────────────────────────────────────────────────────────────────────
# Player API

func tile_at(world_pos: Vector3) -> Dictionary:
	var local := world_pos - origin_offset
	var c: int = int(round(local.x / tile_size))
	var r: int = int(round(-local.z / tile_size))
	if r < 0 or r >= rows or c < 0 or c >= cols:
		return {}
	return _tiles[r][c]

# Tool indices match HUD.HOTBAR_TOOLS: 0=Hoe 1=Water 2=Axe 3=Pick 4=Sword 5=Seeds
func use_tool(tool_index: int, world_pos: Vector3) -> String:
	var t := tile_at(world_pos)
	if t.is_empty():
		return ""
	match tool_index:
		0: # Hoe
			if t.state == State.GRASS:
				t.state = State.TILLED
				_refresh(t)
				return "tilled"
		1: # Water
			if t.state == State.TILLED:
				t.state = State.WATERED
				_refresh(t)
				return "watered"
		5: # Seeds
			if t.state == State.WATERED:
				if GameState.remove_item("parsnip_seeds", 1):
					t.state = State.PLANTED
					t.growth_remaining = 4.0
					_refresh(t)
					return "planted"
				return "no_seeds"
	# Harvest is implicit when interacting with a READY tile, regardless of tool.
	if t.state == State.READY:
		GameState.add_item("parsnip", 1)
		t.state = State.TILLED
		_refresh(t)
		return "harvested"
	return ""
