extends CanvasLayer
## Reusable dialogue box. Show a queue of lines like:
##   [{"speaker": "Mayor", "text": "...", "color": Color.GOLD}, ...]
## Click / Space / E advances. Emits `finished` when the queue is empty.

signal finished

const PARCHMENT  := Color(0.96, 0.92, 0.82, 0.97)
const INK        := Color(0.18, 0.12, 0.06)
const INK_SOFT   := Color(0.45, 0.32, 0.18)
const BORDER     := Color(0.55, 0.40, 0.25)
const SHADOW     := Color(0, 0, 0, 0.5)

var _queue: Array = []
var _box: PanelContainer
var _speaker_label: Label
var _body_label: Label
var _hint_label: Label
var _portrait: Panel
var _shown: bool = false

func _ready() -> void:
	layer = 50  # above the regular HUD
	_build()
	visible = false

func _build() -> void:
	# Dim background overlay
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.35)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	_box = PanelContainer.new()
	_box.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_box.offset_left = 60
	_box.offset_right = -60
	_box.offset_top = -220
	_box.offset_bottom = -40
	var sb := StyleBoxFlat.new()
	sb.bg_color = PARCHMENT
	sb.set_corner_radius_all(12)
	sb.set_content_margin_all(20)
	sb.border_width_left = 3
	sb.border_width_right = 3
	sb.border_width_top = 3
	sb.border_width_bottom = 3
	sb.border_color = BORDER
	sb.shadow_color = SHADOW
	sb.shadow_size = 12
	sb.shadow_offset = Vector2(0, 4)
	_box.add_theme_stylebox_override("panel", sb)
	add_child(_box)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	_box.add_child(row)

	# Portrait placeholder (colored circle)
	_portrait = Panel.new()
	_portrait.custom_minimum_size = Vector2(120, 120)
	var psb := StyleBoxFlat.new()
	psb.bg_color = Color(0.78, 0.62, 0.42)
	psb.set_corner_radius_all(60)
	psb.border_width_left = 4
	psb.border_width_right = 4
	psb.border_width_top = 4
	psb.border_width_bottom = 4
	psb.border_color = BORDER
	_portrait.add_theme_stylebox_override("panel", psb)
	row.add_child(_portrait)

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 8)
	row.add_child(col)

	_speaker_label = Label.new()
	_speaker_label.add_theme_font_size_override("font_size", 24)
	_speaker_label.add_theme_color_override("font_color", INK)
	col.add_child(_speaker_label)

	_body_label = Label.new()
	_body_label.add_theme_font_size_override("font_size", 18)
	_body_label.add_theme_color_override("font_color", INK_SOFT)
	_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(_body_label)

	_hint_label = Label.new()
	_hint_label.text = "▼  click or [E] to continue"
	_hint_label.add_theme_font_size_override("font_size", 13)
	_hint_label.add_theme_color_override("font_color", Color(0.55, 0.40, 0.25))
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	col.add_child(_hint_label)

func show_lines(lines: Array) -> void:
	_queue = lines.duplicate()
	visible = true
	_shown = true
	_advance()

func _advance() -> void:
	if _queue.is_empty():
		visible = false
		_shown = false
		finished.emit()
		return
	var line: Dictionary = _queue.pop_front()
	_speaker_label.text = str(line.get("speaker", ""))
	_body_label.text = str(line.get("text", ""))
	var sc: Color = line.get("color", Color(0.18, 0.12, 0.06))
	_speaker_label.add_theme_color_override("font_color", sc)
	# Tint the portrait to match the speaker
	var psb: StyleBoxFlat = _portrait.get_theme_stylebox("panel") as StyleBoxFlat
	if psb != null:
		psb.bg_color = sc.lerp(Color(0.78, 0.62, 0.42), 0.5)

func _unhandled_input(event: InputEvent) -> void:
	if not _shown:
		return
	if event.is_action_pressed("use_tool") or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		get_viewport().set_input_as_handled()
		_advance()
