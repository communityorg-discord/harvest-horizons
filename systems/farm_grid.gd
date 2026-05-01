extends Node2D
## 2D farm grid. Manages a rectangle of soil tiles using Sprite2D nodes for
## ground state and crop visuals. Tools (hoe, water, seeds) progress each
## tile through GRASS → TILLED → WATERED → PLANTED → GROWING → READY.

@export var rows: int = 6
@export var cols: int = 8
@export var origin_offset: Vector2 = Vector2(-90, 50)

const TILE := 16
const SPR := "res://assets/sprites/"

enum State { GRASS, TILLED, WATERED, PLANTED, GROWING, READY }

const _GROUND_TEX := {
	State.GRASS:   "tiles/grass.png",
	State.TILLED:  "tiles/tilled.png",
	State.WATERED: "tiles/tilled_wet.png",
	State.PLANTED: "tiles/tilled_wet.png",
	State.GROWING: "tiles/tilled_wet.png",
	State.READY:   "tiles/tilled_wet.png",
}

const _CROP_TEX := {
	State.PLANTED: "crops/stage_1.png",
	State.GROWING: "crops/stage_2.png",
	State.READY:   "crops/stage_3.png",
}

var _tiles: Array = []  # 2D array of {state, growth_remaining, ground, crop}

func _ready() -> void:
	_tiles.resize(rows)
	for r in range(rows):
		_tiles[r] = []
		for c in range(cols):
			_tiles[r].append(_build_tile(r, c))

func _process(delta: float) -> void:
	for r in range(rows):
		for c in range(cols):
			var t: Dictionary = _tiles[r][c]
			if t.state == State.PLANTED or t.state == State.GROWING:
				t.growth_remaining -= delta
				if t.growth_remaining <= 0.0:
					_advance(t)

func _build_tile(r: int, c: int) -> Dictionary:
	var pos := origin_offset + Vector2(c * TILE, r * TILE)

	var ground := Sprite2D.new()
	ground.texture = load(SPR + _GROUND_TEX[State.GRASS])
	ground.centered = false
	ground.position = pos
	add_child(ground)

	var crop := Sprite2D.new()
	crop.centered = false
	crop.position = pos
	crop.visible = false
	add_child(crop)

	return {
		"state": State.GRASS,
		"growth_remaining": 0.0,
		"ground": ground,
		"crop": crop,
		"row": r,
		"col": c,
		"pos": pos,
	}

func _advance(t: Dictionary) -> void:
	if t.state == State.PLANTED:
		t.state = State.GROWING
		t.growth_remaining = 4.0
	elif t.state == State.GROWING:
		t.state = State.READY
	_refresh(t)

func _refresh(t: Dictionary) -> void:
	t.ground.texture = load(SPR + _GROUND_TEX[t.state])
	if t.state >= State.PLANTED:
		t.crop.visible = true
		t.crop.texture = load(SPR + _CROP_TEX[t.state])
	else:
		t.crop.visible = false

# ────────────────────────────────────────────────────────────────────────────
# Player API

func tile_at(world_pos: Vector2) -> Dictionary:
	var local := world_pos - origin_offset
	var c: int = int(floor(local.x / TILE))
	var r: int = int(floor(local.y / TILE))
	if r < 0 or r >= rows or c < 0 or c >= cols:
		return {}
	return _tiles[r][c]

# Tool indices match HUD.HOTBAR_TOOLS: 0=Hoe 1=Water 2=Axe 3=Pick 4=Sword 5=Seeds
func use_tool(tool_index: int, world_pos: Vector2) -> String:
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
	if t.state == State.READY:
		GameState.add_item("parsnip", 1)
		t.state = State.TILLED
		_refresh(t)
		return "harvested"
	return ""
