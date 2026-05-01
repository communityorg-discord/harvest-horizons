extends Node
## Game entry point. Decides which scene to load based on save state.
## - New game (no save) → Town Centre with intro flag set, Mayor greets you.
## - Returning player (save loaded) → Farm.

func _ready() -> void:
	# GameState autoload has already attempted load_game() in its own _ready,
	# so is_new_game is correctly populated by now.
	var target: String
	if GameState.is_new_game:
		GameState.set_meta("intro_pending", "town_mayor")
		target = "res://scenes/town_centre.tscn"
	else:
		target = "res://scenes/main.tscn"
	# Defer one frame so the autoload finishes its own setup cleanly.
	call_deferred("_go", target)

func _go(target: String) -> void:
	get_tree().change_scene_to_file(target)
