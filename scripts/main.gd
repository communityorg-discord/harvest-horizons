extends Node3D
## Top-level orchestrator for the farm scene.
## - Drives the day/night sun rotation from GameState.
## - Spawns the Inn Master NPC for the on-arrival farm intro
##   (only after the Mayor intro has played and only the first time here).

@onready var sun: DirectionalLight3D = $Sun
@onready var _player: CharacterBody3D = $Player

const SUNRISE := 6.0
const SUNSET := 20.0

func _ready() -> void:
	_handle_intro()

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
	GameState.save_game()
