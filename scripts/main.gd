extends Node3D
## Top-level orchestrator. Drives the day/night sun rotation from GameState.

@onready var sun: DirectionalLight3D = $Sun

const SUNRISE := 6.0
const SUNSET := 20.0

func _process(_delta: float) -> void:
	var t: float = float(GameState.hour) + float(GameState.minute) / 60.0

	# Sun pitch arcs from -180 (sunrise) to 0 (noon) to 180 (sunset).
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
