extends Node
## Game entry point. Decides which scene to load based on save state.
## - New game (no save) → Town Centre with intro flag set, Mayor greets you.
## - Returning player (save loaded) → Farm.

func _ready() -> void:
	var target: String
	if GameState.is_new_game:
		GameState.set_meta("intro_pending", "town_mayor")
		# Seed the opening quest so the Quest Book has something to show.
		GameState.start_quest("wizard_letter")
		target = "res://scenes/town_centre.tscn"
	else:
		target = "res://scenes/main.tscn"
	call_deferred("_go", target)

func _go(target: String) -> void:
	get_tree().change_scene_to_file(target)
