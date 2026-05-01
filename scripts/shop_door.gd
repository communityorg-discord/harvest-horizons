extends Area3D
## Shop entrance: walk in, sets the next shop's type on GameState meta,
## then loads the shared shop_interior scene.

@export var shop_type: String = "general"
@export_file("*.tscn") var target_scene: String = "res://scenes/shop_interior.tscn"

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body is CharacterBody3D:
		GameState.set_meta("shop_type", shop_type)
		get_tree().change_scene_to_file(target_scene)
