extends Node3D
## Top-level orchestrator for the farm scene.
## - Drives the day/night sun rotation from GameState.
## - Spawns the Inn Master NPC for the on-arrival farm intro.
## - At 7 PM on day 1, spawns the Visitor NPC who triggers the Light the
##   Farm quest. Spawns the lantern pickups + sockets after that dialogue.

@onready var sun: DirectionalLight3D = $Sun
@onready var _player: CharacterBody3D = $Player

const SUNRISE := 6.0
const SUNSET := 20.0
const VISITOR_HOUR := 19  # 7 PM trigger
const PICKUP_SCRIPT := preload("res://scripts/lantern_pickup.gd")
const SOCKET_SCRIPT := preload("res://scripts/lantern_socket.gd")

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
	# If we loaded a save mid-quest, re-spawn the lights so they're still there.
	if "light_the_farm" in GameState.active_quests:
		call_deferred("_spawn_lighting_quest_objects")

func _process(_delta: float) -> void:
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
