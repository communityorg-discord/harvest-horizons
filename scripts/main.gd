extends Node3D
## Top-level orchestrator for the farm scene.
## - Drives the day/night sun rotation from GameState.
## - Spawns the Inn Master NPC for the on-arrival farm intro.
## - At 7 PM on day 1, spawns the Visitor NPC who triggers the Light the
##   Farm quest. Spawns the lantern pickups + sockets after that dialogue.

@onready var sun: DirectionalLight3D = $Sun
@onready var _player: CharacterBody3D = $Player
@onready var _world_env: WorldEnvironment = $WorldEnvironment

const SUNRISE := 6.0
const SUNSET := 20.0

# Sky palette — sky_top + sky_horizon at each time of day
const SKY_NIGHT := { "top": Color(0.06, 0.08, 0.18), "horizon": Color(0.10, 0.12, 0.22) }
const SKY_DAWN  := { "top": Color(0.55, 0.55, 0.78), "horizon": Color(1.00, 0.62, 0.42) }
const SKY_DAY   := { "top": Color(0.30, 0.52, 0.78), "horizon": Color(0.92, 0.78, 0.62) }
const SKY_DUSK  := { "top": Color(0.32, 0.22, 0.45), "horizon": Color(0.95, 0.42, 0.30) }

const SUN_COLOR_DAY  := Color(1.00, 0.95, 0.85)
const SUN_COLOR_DAWN := Color(1.00, 0.78, 0.55)
const SUN_COLOR_DUSK := Color(1.00, 0.55, 0.35)
const SUN_COLOR_NIGHT:= Color(0.40, 0.50, 0.78)
const VISITOR_HOUR := 19  # 7 PM trigger
const PICKUP_SCRIPT := preload("res://scripts/lantern_pickup.gd")
const SOCKET_SCRIPT := preload("res://scripts/lantern_socket.gd")
const MONSTER_SCRIPT := preload("res://scripts/monster.gd")
const NIGHT_MONSTER_CAP := 3
const SAFE_DIST_FROM_PLAYER := 8.0  # don't spawn in the player's face

# Predefined lantern pickup locations (3 of them, scattered)
const PICKUP_POSITIONS := [
	Vector3(-3.0, 0.0, 4.5),
	Vector3(6.5, 0.0, -5.0),
	Vector3(-12.0, 0.0, 6.5),
]

# Predefined lantern socket locations (3 sockets to fill)
const SOCKET_POSITIONS := [
	Vector3(-9.0, 0.0, 4.5),     # near cottage
	Vector3(5.5, 0.0, 4.5),      # near picnic
	Vector3(0.0, 0.0, -8.5),     # far north middle
]

var _placed_count: int = 0

func _ready() -> void:
	_handle_intro()
	GameState.time_changed.connect(_on_time_check)
	GameState.weather_changed.connect(_on_weather_changed)
	# If we loaded a save mid-quest, re-spawn the lights so they're still there.
	if "light_the_farm" in GameState.active_quests:
		call_deferred("_spawn_lighting_quest_objects")
	# Apply current weather visuals on load
	call_deferred("_on_weather_changed", GameState.weather)

func _process(delta: float) -> void:
	var t: float = float(GameState.hour) + float(GameState.minute) / 60.0

	var arc: float = (t - SUNRISE) / (SUNSET - SUNRISE)
	var pitch: float = lerp(-180.0, 0.0, clamp(arc, 0.0, 1.0))
	if t < SUNRISE or t > SUNSET:
		pitch = 10.0
	sun.rotation_degrees.x = pitch

	var energy: float = 0.05
	if t >= SUNRISE and t <= SUNSET:
		var day_progress: float = (t - SUNRISE) / (SUNSET - SUNRISE)
		energy = sin(day_progress * PI) * 1.3 + 0.1
	sun.light_energy = energy

	_update_sky_palette(t)

	# Move rain/snow with the player so it always covers the visible area
	if _player != null:
		var pp: Vector3 = _player.global_position
		if _rain != null and is_instance_valid(_rain):
			_rain.global_position = Vector3(pp.x, pp.y + 14, pp.z)
		if _snow != null and is_instance_valid(_snow):
			_snow.global_position = Vector3(pp.x, pp.y + 14, pp.z)

	# Lightning flashes during storms (random, 0.05s spike of bright sun energy)
	if _is_stormy:
		_lightning_t -= delta
		if _lightning_t <= 0.0:
			_lightning_t = randf_range(4.0, 12.0)
			_strike_lightning()

	# Monsters can spawn during the day during a storm (per design)
	_spawn_check_t -= delta
	if _spawn_check_t <= 0.0:
		_spawn_check_t = 1.5
		if _is_night() or _is_stormy:
			_spawn_monster()
		elif not _is_stormy:
			_despawn_monsters()

func _strike_lightning() -> void:
	if sun == null:
		return
	var orig_e: float = sun.light_energy
	var orig_c: Color = sun.light_color
	sun.light_energy = 5.0
	sun.light_color = Color(0.9, 0.95, 1.0)
	var tw := create_tween()
	tw.tween_property(sun, "light_energy", orig_e, 0.18)
	tw.parallel().tween_property(sun, "light_color", orig_c, 0.18)

func _update_sky_palette(t: float) -> void:
	# Build top + horizon + sun_color from a 24-hour cycle.
	var top: Color
	var horizon: Color
	var sun_col: Color
	if t < 5.0:
		top = SKY_NIGHT.top; horizon = SKY_NIGHT.horizon; sun_col = SUN_COLOR_NIGHT
	elif t < 7.0:
		var f := (t - 5.0) / 2.0
		top = SKY_NIGHT.top.lerp(SKY_DAWN.top, f)
		horizon = SKY_NIGHT.horizon.lerp(SKY_DAWN.horizon, f)
		sun_col = SUN_COLOR_NIGHT.lerp(SUN_COLOR_DAWN, f)
	elif t < 9.0:
		var f := (t - 7.0) / 2.0
		top = SKY_DAWN.top.lerp(SKY_DAY.top, f)
		horizon = SKY_DAWN.horizon.lerp(SKY_DAY.horizon, f)
		sun_col = SUN_COLOR_DAWN.lerp(SUN_COLOR_DAY, f)
	elif t < 17.0:
		top = SKY_DAY.top; horizon = SKY_DAY.horizon; sun_col = SUN_COLOR_DAY
	elif t < 20.0:
		var f := (t - 17.0) / 3.0
		top = SKY_DAY.top.lerp(SKY_DUSK.top, f)
		horizon = SKY_DAY.horizon.lerp(SKY_DUSK.horizon, f)
		sun_col = SUN_COLOR_DAY.lerp(SUN_COLOR_DUSK, f)
	elif t < 22.0:
		var f := (t - 20.0) / 2.0
		top = SKY_DUSK.top.lerp(SKY_NIGHT.top, f)
		horizon = SKY_DUSK.horizon.lerp(SKY_NIGHT.horizon, f)
		sun_col = SUN_COLOR_DUSK.lerp(SUN_COLOR_NIGHT, f)
	else:
		top = SKY_NIGHT.top; horizon = SKY_NIGHT.horizon; sun_col = SUN_COLOR_NIGHT

	if _world_env != null and _world_env.environment != null:
		var sky: Sky = _world_env.environment.sky
		if sky != null:
			var mat: ProceduralSkyMaterial = sky.sky_material as ProceduralSkyMaterial
			if mat != null:
				mat.sky_top_color = top
				mat.sky_horizon_color = horizon
		# Pull the ambient warmth toward the horizon colour
		_world_env.environment.ambient_light_color = horizon.lerp(top, 0.4)
	sun.light_color = sun_col

# ────────────────────────────────────────────────────────────────────────────
# Inn Master arrival intro

func _handle_intro() -> void:
	# Only on first arrival after the Mayor's blessing.
	if not GameState.has_completed("intro_mayor"):
		return
	if GameState.has_completed("intro_inn"):
		return
	# Position player a few steps inside from the town gate.
	if _player != null:
		_player.global_position = Vector3(13, 1, 0)
	var npc := NPC.new()
	npc.npc_name = "Lily (Inn Master)"
	npc.shirt_color = Color(0.85, 0.55, 0.62)  # rosy
	npc.hat_color   = Color(0.95, 0.92, 0.88)
	npc.hair_color  = Color(0.55, 0.30, 0.20)
	npc.position = Vector3(10, 0, 0)
	npc.lines = [
		{"speaker": "Lily", "text": "There you are!  Mayor Victor sent word.  I'm Lily — I run the Greenfield Inn.", "color": Color(0.85, 0.45, 0.55)},
		{"speaker": "Lily", "text": "This farm has sat abandoned since the great flood.  The fields, the fences, the lights — all gone or rotted away.", "color": Color(0.85, 0.45, 0.55)},
		{"speaker": "Lily", "text": "Don't worry, I'll be by to lend a hand whenever something new needs explaining.", "color": Color(0.85, 0.45, 0.55)},
		{"speaker": "Lily", "text": "Take this Quest Book — it's from the Wizard.  Complete what's inside and he'll meet you in person.", "color": Color(0.85, 0.45, 0.55)},
		{"speaker": "Lily", "text": "And here — basic farming tools.  They're rusted, but they'll hold up until Summer 1.  Replace them at the Blacksmith before then or they'll snap.", "color": Color(0.85, 0.45, 0.55)},
		{"speaker": "You", "text": "Thank you.  Where do I start?", "color": Color(0.20, 0.45, 0.65)},
		{"speaker": "Lily", "text": "Get your bearings.  Walk the farm.  When the sun starts to set… well, you'll find out soon enough.  Good luck, farmer.", "color": Color(0.85, 0.45, 0.55)},
	]
	add_child(npc)
	npc.dialogue_finished.connect(_on_inn_master_done)
	# Auto-fire the intro once the scene is fully built.
	call_deferred("_play_inn_intro", npc)

func _play_inn_intro(npc: NPC) -> void:
	var box := find_child("DialogueBox", true, false)
	if box == null or npc.lines.is_empty():
		return
	box.show_lines(npc.lines)
	if not box.finished.is_connected(npc._on_dialogue_finished):
		box.finished.connect(npc._on_dialogue_finished, CONNECT_ONE_SHOT)

func _on_inn_master_done() -> void:
	GameState.complete_quest("intro_inn")
	GameState.start_quest("first_harvest")
	GameState.save_game()

# ────────────────────────────────────────────────────────────────────────────
# 7 PM visitor trigger + Light-the-Farm quest

func _on_time_check(hour: int, _minute: int) -> void:
	if hour < VISITOR_HOUR:
		return
	if GameState.has_completed("intro_visitor"):
		return
	if not GameState.has_completed("intro_inn"):
		return  # don't fire before the player's met Lily
	# One-shot — disconnect so we don't re-enter
	GameState.complete_quest("intro_visitor")
	_spawn_visitor()

func _spawn_visitor() -> void:
	var npc := NPC.new()
	npc.npc_name = "Old Tobias"
	npc.shirt_color = Color(0.32, 0.42, 0.55)  # weathered slate
	npc.hat_color   = Color(0.55, 0.32, 0.22)  # muddy red cap
	npc.hair_color  = Color(0.78, 0.78, 0.72)  # grey
	npc.position = Vector3(8.0, 0, -1.0)
	npc.lines = [
		{"speaker": "Old Tobias", "text": "Oi!  OI!  Are you mental?!  You've got NO lights on this farm!", "color": Color(0.85, 0.55, 0.35)},
		{"speaker": "Old Tobias", "text": "An hour till sunset and you're standing here like a sitting duck!  You're going to be eaten ALIVE by them creatures.", "color": Color(0.85, 0.55, 0.35)},
		{"speaker": "You", "text": "Creatures…?", "color": Color(0.20, 0.45, 0.65)},
		{"speaker": "Old Tobias", "text": "AYE.  At night, anywhere there's no light, they crawl out.  Nasty things.  Even the wild animals know to clear off.", "color": Color(0.85, 0.55, 0.35)},
		{"speaker": "Old Tobias", "text": "Right — I dropped three lanterns around your farm before I came up.  Round 'em up and stick 'em in the empty sockets.  Three sockets, three lanterns.  Get to it!", "color": Color(0.85, 0.55, 0.35)},
		{"speaker": "Old Tobias", "text": "And take this — rusted sword.  After fifty animal kills it'll snap, mind you.  Blacksmith MIGHT sell better, but no one's gone in the mines since the flood swamped 'em.  Needs recoverin'.", "color": Color(0.85, 0.55, 0.35)},
		{"speaker": "You", "text": "Thank you, Tobias.  I'll get them placed.", "color": Color(0.20, 0.45, 0.65)},
		{"speaker": "Old Tobias", "text": "Don't dawdle.  Sun's setting.", "color": Color(0.85, 0.55, 0.35)},
	]
	add_child(npc)
	npc.dialogue_finished.connect(_on_visitor_done.bind(npc))
	# Auto-fire the dialogue
	call_deferred("_play_visitor", npc)

func _play_visitor(npc: NPC) -> void:
	var box := find_child("DialogueBox", true, false)
	if box == null or npc.lines.is_empty():
		return
	box.show_lines(npc.lines)
	if not box.finished.is_connected(npc._on_dialogue_finished):
		box.finished.connect(npc._on_dialogue_finished, CONNECT_ONE_SHOT)

func _on_visitor_done(npc: NPC) -> void:
	# Hand over the rusted sword + start the quest, then spawn objects
	GameState.add_item("rusted_sword", 1)
	GameState.start_quest("light_the_farm", SOCKET_POSITIONS.size())
	_spawn_lighting_quest_objects()
	GameState.save_game()
	# Tobias wanders off (just despawn him after a beat)
	await get_tree().create_timer(2.0).timeout
	if is_instance_valid(npc):
		npc.queue_free()

func _spawn_lighting_quest_objects() -> void:
	# Don't double-spawn if reloaded mid-quest
	if has_node("LightingQuest"):
		return
	var container := Node3D.new()
	container.name = "LightingQuest"
	add_child(container)
	# Pickups
	for p in PICKUP_POSITIONS:
		var pickup := Area3D.new()
		pickup.set_script(PICKUP_SCRIPT)
		pickup.position = p + Vector3(0, 0.1, 0)
		container.add_child(pickup)
	# Sockets
	for p in SOCKET_POSITIONS:
		var socket := Area3D.new()
		socket.set_script(SOCKET_SCRIPT)
		socket.position = p
		container.add_child(socket)
		socket.placed.connect(_on_lantern_placed)

func _on_lantern_placed() -> void:
	_placed_count += 1
	GameState.set_quest_progress("light_the_farm", _placed_count)
	GameState.save_game()

# ────────────────────────────────────────────────────────────────────────────
# Night monster spawning

var _spawn_check_t: float = 0.0
var _monsters_root: Node3D

func _ensure_monsters_root() -> Node3D:
	if _monsters_root == null or not is_instance_valid(_monsters_root):
		_monsters_root = Node3D.new()
		_monsters_root.name = "Monsters"
		add_child(_monsters_root)
	return _monsters_root

func _is_night() -> bool:
	var t: float = float(GameState.hour) + float(GameState.minute) / 60.0
	return t >= SUNSET or t < SUNRISE

func _spawn_monster() -> void:
	var root := _ensure_monsters_root()
	if root.get_child_count() >= NIGHT_MONSTER_CAP:
		return
	# Random position inside playable area, not too close to the player
	for _attempt in range(10):
		var x: float = randf_range(-14.0, 14.0)
		var z: float = randf_range(-12.0, 14.0)
		var p := Vector3(x, 0.5, z)
		if _player != null and p.distance_to(_player.global_position) < SAFE_DIST_FROM_PLAYER:
			continue
		var m := CharacterBody3D.new()
		m.set_script(MONSTER_SCRIPT)
		m.position = p
		root.add_child(m)
		return

func _despawn_monsters() -> void:
	if _monsters_root == null:
		return
	for child in _monsters_root.get_children():
		child.queue_free()

# ────────────────────────────────────────────────────────────────────────────
# Weather visuals — rain / snow particles + storm darkening + lightning

var _weather_root: Node3D
var _rain: GPUParticles3D
var _snow: GPUParticles3D
var _is_stormy: bool = false
var _lightning_t: float = 0.0
var _base_fog_density: float = 0.006

func _ensure_weather_root() -> Node3D:
	if _weather_root == null or not is_instance_valid(_weather_root):
		_weather_root = Node3D.new()
		_weather_root.name = "Weather"
		add_child(_weather_root)
	return _weather_root

func _on_weather_changed(w: int) -> void:
	# Clear previous effects
	var root := _ensure_weather_root()
	for child in root.get_children():
		child.queue_free()
	_rain = null
	_snow = null
	_is_stormy = false
	# Reset fog
	if _world_env != null and _world_env.environment != null:
		_world_env.environment.fog_density = _base_fog_density

	match w:
		GameState.Weather.RAINY:
			_rain = _make_rain(8.0)
			root.add_child(_rain)
		GameState.Weather.STORMY:
			_rain = _make_rain(14.0)
			root.add_child(_rain)
			_is_stormy = true
			if _world_env and _world_env.environment:
				_world_env.environment.fog_density = 0.012
		GameState.Weather.SNOWY:
			_snow = _make_snow(6.0)
			root.add_child(_snow)
		GameState.Weather.FOGGY:
			if _world_env and _world_env.environment:
				_world_env.environment.fog_density = 0.025

func _make_rain(speed: float) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = 800
	p.lifetime = 1.4
	p.preprocess = 1.0
	p.position = Vector3(0, 14, 0)  # follow player in _process
	var pm := ParticleProcessMaterial.new()
	pm.gravity = Vector3(0, -25 * (speed / 8.0), 0)
	pm.initial_velocity_min = speed * 0.5
	pm.initial_velocity_max = speed
	pm.direction = Vector3(0.1, -1, 0.1)
	pm.spread = 6.0
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(20, 0.5, 20)
	pm.scale_min = 0.5
	pm.scale_max = 0.8
	p.process_material = pm
	# Long thin droplet mesh
	var bm := BoxMesh.new()
	bm.size = Vector3(0.02, 0.45, 0.02)
	p.draw_pass_1 = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.65, 0.78, 0.95, 0.85)
	mat.emission_enabled = true
	mat.emission = Color(0.4, 0.55, 0.85)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bm.material = mat
	return p

func _make_snow(speed: float) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = 500
	p.lifetime = 6.0
	p.preprocess = 4.0
	p.position = Vector3(0, 14, 0)
	var pm := ParticleProcessMaterial.new()
	pm.gravity = Vector3(0.5, -1.2 * speed, 0.3)
	pm.initial_velocity_min = 0.2
	pm.initial_velocity_max = 0.6
	pm.direction = Vector3(0, -1, 0)
	pm.spread = 30.0
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(20, 0.5, 20)
	pm.scale_min = 0.6
	pm.scale_max = 1.2
	p.process_material = pm
	var sm := SphereMesh.new()
	sm.radius = 0.06
	sm.height = 0.12
	sm.radial_segments = 6
	sm.rings = 4
	p.draw_pass_1 = sm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 1.0, 1.0, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.85, 0.92, 1.0)
	mat.emission_energy_multiplier = 0.6
	sm.material = mat
	return p
