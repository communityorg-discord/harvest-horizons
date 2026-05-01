extends Label3D
## Spawn at a world position, float upward, fade out, free.
## Usage:
##   var n := DamageNumber.spawn(get_tree().current_scene, world_pos, "20", Color.WHITE)

class_name DamageNumber

const LIFETIME := 0.9
const RISE := 1.6

var _t: float = 0.0

static func spawn(parent: Node, pos: Vector3, text: String, color: Color = Color.WHITE) -> DamageNumber:
	var n := DamageNumber.new()
	n.text = text
	n.font_size = 56
	n.outline_size = 8
	n.modulate = color
	n.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	n.no_depth_test = true
	n.position = pos
	parent.add_child(n)
	return n

func _process(delta: float) -> void:
	_t += delta
	position.y += RISE * delta * (1.0 - _t / LIFETIME)
	var f: float = clamp(1.0 - (_t / LIFETIME), 0.0, 1.0)
	modulate.a = f
	if _t >= LIFETIME:
		queue_free()
