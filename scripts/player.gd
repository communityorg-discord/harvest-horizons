extends CharacterBody2D
## 2D pixel-art farmer. WASD movement, plays directional walk/idle animations
## from the Sprout Lands character spritesheet (4 dirs × 4 frames each).

@export var speed: float = 80.0  # pixels per second (in world space, before camera zoom)
@export var farm_grid_path: NodePath

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _farm_grid: Node = get_node_or_null(farm_grid_path)

const CHAR := "res://assets/sprites/character/"
const DIRS := ["DOWN", "LEFT", "RIGHT", "UP"]

var _facing: String = "DOWN"

func _ready() -> void:
	_sprite.sprite_frames = _build_sprite_frames()
	_sprite.play("idle_DOWN")

func _build_sprite_frames() -> SpriteFrames:
	var sf := SpriteFrames.new()
	for dir in DIRS:
		var walk_anim := "walk_%s" % dir
		var idle_anim := "idle_%s" % dir
		sf.add_animation(walk_anim)
		sf.add_animation(idle_anim)
		sf.set_animation_speed(walk_anim, 8.0)
		sf.set_animation_speed(idle_anim, 2.0)
		sf.set_animation_loop(walk_anim, true)
		sf.set_animation_loop(idle_anim, true)
		for i in range(1, 5):
			var path := "%sBasic_Charakter_Spritesheet_%s_%d.png" % [CHAR, dir, i]
			var tex: Texture2D = load(path)
			if tex == null:
				push_warning("Missing character frame: %s" % path)
				continue
			sf.add_frame(walk_anim, tex)
		# Idle uses just frame 1 of each direction (a still pose).
		var idle_tex: Texture2D = load("%sBasic_Charakter_Spritesheet_%s_1.png" % [CHAR, dir])
		if idle_tex != null:
			sf.add_frame(idle_anim, idle_tex)
	# Remove the default empty animation
	if sf.has_animation("default"):
		sf.remove_animation("default")
	return sf

func _physics_process(_delta: float) -> void:
	var input := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	if input.length() > 1.0:
		input = input.normalized()
	velocity = input * speed
	move_and_slide()

	# Pick facing from input (prefer last-moved axis)
	if abs(input.x) > abs(input.y) and input.x != 0:
		_facing = "RIGHT" if input.x > 0 else "LEFT"
	elif input.y != 0:
		_facing = "DOWN" if input.y > 0 else "UP"

	# Animation
	var anim: String
	if input.length_squared() > 0.01:
		anim = "walk_%s" % _facing
	else:
		anim = "idle_%s" % _facing
	if _sprite.animation != anim:
		_sprite.play(anim)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("use_tool"):
		_use_tool()

func _use_tool() -> void:
	if _farm_grid == null or not _farm_grid.has_method("use_tool"):
		return
	var probe: Vector2 = global_position + _facing_vector() * 16.0
	_farm_grid.use_tool(GameState.current_tool, probe)

func _facing_vector() -> Vector2:
	match _facing:
		"DOWN":  return Vector2(0, 1)
		"UP":    return Vector2(0, -1)
		"LEFT":  return Vector2(-1, 0)
		"RIGHT": return Vector2(1, 0)
	return Vector2.DOWN
