extends Node2D
## Top-level orchestrator for the 2D farm scene. Tiles the grass background
## and procedurally places cottage, chicken house, fence, trees, flowers,
## bushes, rocks. Y-sorted so things below the player draw in front of it.

const SPR := "res://assets/sprites/"
const TILE := 16

# Visible world bounds, in world pixels
const WORLD_LEFT := -300
const WORLD_RIGHT := 300
const WORLD_TOP := -200
const WORLD_BOTTOM := 240

@onready var _bg: Node2D = $Background
@onready var _decor: Node2D = $World/Decor

func _ready() -> void:
	_paint_grass()
	_build_cottage(Vector2(-130, -50))
	_build_chicken_house(Vector2(110, -40))
	_build_fence_around_farm()
	_scatter_trees()
	_scatter_flowers()
	_scatter_rocks()

# ────────────────────────────────────────────────────────────────────────────
# Background grass — tile a single grass sprite across the whole visible world

func _paint_grass() -> void:
	var grass_tex: Texture2D = load(SPR + "tiles/grass.png")
	var grass_alt: Texture2D = load(SPR + "tiles/grass_alt.png")
	var grass_flowers: Texture2D = load(SPR + "tiles/grass_flowers.png")
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	var x := WORLD_LEFT
	while x < WORLD_RIGHT + TILE:
		var y := WORLD_TOP
		while y < WORLD_BOTTOM + TILE:
			var s := Sprite2D.new()
			var roll := rng.randf()
			if roll < 0.05:
				s.texture = grass_flowers
			elif roll < 0.18:
				s.texture = grass_alt
			else:
				s.texture = grass_tex
			s.centered = false
			s.position = Vector2(x, y)
			_bg.add_child(s)
			y += TILE
		x += TILE

# ────────────────────────────────────────────────────────────────────────────
# Sprite placement helper (adds to _decor so it's Y-sorted)

func _place(path: String, pos: Vector2, centered: bool = true) -> Sprite2D:
	var s := Sprite2D.new()
	var tex: Texture2D = load(path)
	if tex == null:
		push_warning("Missing sprite: %s" % path)
		return s
	s.texture = tex
	s.centered = centered
	s.position = pos
	_decor.add_child(s)
	return s

# ────────────────────────────────────────────────────────────────────────────
# Cottage — 112×80 sprite

func _build_cottage(pos: Vector2) -> void:
	var s := _place(SPR + "objects/cottage.png", pos, false)
	# anchor by approximate base of building so y-sort lines up
	s.offset = Vector2(-56, -64)

func _build_chicken_house(pos: Vector2) -> void:
	var s := _place(SPR + "objects/chicken_house.png", pos, false)
	s.offset = Vector2(-24, -32)

# ────────────────────────────────────────────────────────────────────────────
# Fence around the farm patch (rough rectangle, gap on the right for a path)

func _build_fence_around_farm() -> void:
	# Farm patch in pixel coords
	var x_min := -100
	var x_max := 80
	var y_min := 30
	var y_max := 200
	var step := TILE
	# Top + bottom
	var x := x_min
	while x <= x_max:
		_place(SPR + "tiles/fence_h.png", Vector2(x, y_min), false)
		_place(SPR + "tiles/fence_h.png", Vector2(x, y_max), false)
		x += step
	# Sides
	var y := y_min + step
	while y < y_max:
		_place(SPR + "tiles/fence_v.png", Vector2(x_min, y), false)
		# Skip a few rows on the right side to leave a path gap
		if y < 100 or y > 140:
			_place(SPR + "tiles/fence_v.png", Vector2(x_max, y), false)
		y += step

# ────────────────────────────────────────────────────────────────────────────
# Trees scattered around the perimeter

func _scatter_trees() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	for i in range(24):
		var p := _ring_position(rng, 180.0, 280.0)
		var idx: int = (rng.randi() % 2) + 1
		_place(SPR + "decor/tree_%d.png" % idx, p)
	# A few near the cottage cluster
	for p in [Vector2(-200, -100), Vector2(-220, -30), Vector2(-220, 60)]:
		_place(SPR + "decor/tree_1.png", p)
	for p in [Vector2(220, -120), Vector2(240, 30), Vector2(220, 130)]:
		_place(SPR + "decor/tree_2.png", p)

func _scatter_flowers() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 13
	for i in range(60):
		var p := _ring_position(rng, 110.0, 250.0)
		var idx: int = (rng.randi() % 3) + 1
		_place(SPR + "decor/flower_%d.png" % idx, p)

func _scatter_rocks() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	for i in range(14):
		var p := _ring_position(rng, 130.0, 240.0)
		var idx: int = (rng.randi() % 2) + 1
		_place(SPR + "decor/rock_%d.png" % idx, p)

func _ring_position(rng: RandomNumberGenerator, r_min: float, r_max: float) -> Vector2:
	var angle := rng.randf() * TAU
	var radius := rng.randf_range(r_min, r_max)
	return Vector2(cos(angle) * radius, sin(angle) * radius * 0.7)
