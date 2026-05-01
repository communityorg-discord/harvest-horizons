extends Area3D
## Walk-into-it portal. When a CharacterBody3D enters, switch to target_scene.

@export_file("*.tscn") var target_scene: String = ""

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if target_scene == "":
		return
	if body is CharacterBody3D:
		get_tree().change_scene_to_file(target_scene)
