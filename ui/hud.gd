extends CanvasLayer
## Cozy game HUD — designed to FLOAT in the screen the way the concept art
## does, not sit in heavy framed boxes. Key visual moves:
##   - Avatar circle protrudes out of the player bars (sticks up + left)
##   - All panels use a dark translucent rounded pill with a gold hairline,
##     no thick borders, soft drop shadow only
##   - Side-menu buttons are round icon coins, not text rectangles
##   - Spacing is tight; everything sized to ~60% of the previous footprint
## Live-bound to GameState (hp/energy/money/time/weather/quests).

# ────────────────────────────────────────────────────────────────────────────
# Theme

const PANEL_BG       := Color(0.12, 0.09, 0.06, 0.78)   # translucent dark
const PANEL_BORDER   := Color(0.78, 0.62, 0.28, 0.55)   # gold hairline
const PARCHMENT      := Color(0.96, 0.92, 0.82, 0.95)
const INK            := Color(0.22, 0.16, 0.10)
const INK_SOFT       := Color(0.45, 0.35, 0.22)
const GOLD           := Color(0.92, 0.78, 0.36)
const LEAF           := Color(0.45, 0.62, 0.25)
const BERRY          := Color(0.82, 0.36, 0.26)
const HP_GREEN       := Color(0.42, 0.78, 0.32)
const EN_BLUE        := Color(0.32, 0.62, 0.86)
const TEXT_LIGHT     := Color(0.96, 0.92, 0.82)
const TEXT_DIM       := Color(0.85, 0.78, 0.62)
const SHADOW         := Color(0, 0, 0, 0.45)

const HOTBAR_TOOLS := [
	{"name": "Hoe",     "icon": "🪓", "label": "H", "key": "1"},
	{"name": "Water",   "icon": "💧", "label": "W", "key": "2"},
	{"name": "Axe",     "icon": "🪓", "label": "A", "key": "3"},
	{"name": "Pickaxe", "icon": "⛏",  "label": "P", "key": "4"},
	{"name": "Sword",   "icon": "⚔",  "label": "S", "key": "5"},
	{"name": "Seeds",   "icon": "🌱", "label": "*", "key": "6"},
]

const SIDE_MENU := [
	{"label": "Bag",     "icon": "🎒", "key": "I"},
	{"label": "Skills",  "icon": "★",  "key": "K"},
	{"label": "Journal", "icon": "📖", "key": "U"},
	{"label": "People",  "icon": "👥", "key": "C"},
	{"label": "Map",     "icon": "🗺", "key": "M"},
]

# ────────────────────────────────────────────────────────────────────────────

var _money_label: Label
var _weather_label: Label
var _date_label: Label
var _time_label: Label
var _hp_bar: ProgressBar
var _hp_text: Label
var _en_bar: ProgressBar
var _en_text: Label
var _level_label: Label
var _hotbar_slots: Array[PanelContainer] = []
var _hotbar_count_labels: Array[Label] = []
var _quest_list: VBoxContainer
var _inventory_label: Label

func _ready() -> void:
	_build_player_card()
	_build_top_pill()
	_build_minimap()
	_build_quest_panel()
	_build_hotbar()
	_build_side_menu()
	_build_chat_log()

	GameState.money_changed.connect(_on_money)
	GameState.time_changed.connect(_on_time)
	GameState.day_changed.connect(_on_day)
	GameState.weather_changed.connect(_on_weather)
	GameState.rank_changed.connect(_on_rank)
	GameState.inventory_changed.connect(_on_inventory)
	GameState.hp_changed.connect(_on_hp)
	GameState.energy_changed.connect(_on_energy)
	GameState.quest_started.connect(_refresh_quests)
	GameState.quest_completed.connect(_refresh_quests)
	GameState.quest_progress_changed.connect(_refresh_quests)
	_refresh_all()
	_select_hotbar(0)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("hotbar_1"): _select_hotbar(0)
	elif event.is_action_pressed("hotbar_2"): _select_hotbar(1)
	elif event.is_action_pressed("hotbar_3"): _select_hotbar(2)
	elif event.is_action_pressed("hotbar_4"): _select_hotbar(3)
	elif event.is_action_pressed("hotbar_5"): _select_hotbar(4)
	elif event.is_action_pressed("hotbar_6"): _select_hotbar(5)

# ────────────────────────────────────────────────────────────────────────────
# Stylebox helpers — all panels use the same floating dark pill

func _floating_pill(corner: int = 14, padding: int = 8) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = PANEL_BG
	sb.set_corner_radius_all(corner)
	sb.set_content_margin_all(padding)
	sb.border_width_left = 1
	sb.border_width_right = 1
	sb.border_width_top = 1
	sb.border_width_bottom = 1
	sb.border_color = PANEL_BORDER
	sb.shadow_color = SHADOW
	sb.shadow_size = 8
	sb.shadow_offset = Vector2(0, 3)
	return sb

func _label(text: String, size: int, color: Color, align_center: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if align_center:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

# ────────────────────────────────────────────────────────────────────────────
# Top-left: bars pill with avatar circle PROTRUDING out the left side

func _build_player_card() -> void:
	# Container Control to pin everything in the top-left
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_TOP_LEFT)
	root.offset_left = 14
	root.offset_top = 14
	root.offset_right = 14 + 220
	root.offset_bottom = 14 + 64
	add_child(root)

	# Bars pill — sits behind, indented from the left to leave room for avatar
	var pill := PanelContainer.new()
	pill.add_theme_stylebox_override("panel", _floating_pill(18, 6))
	pill.set_anchors_preset(Control.PRESET_FULL_RECT)
	pill.offset_left = 32  # leave space on the left for the avatar to stick out
	pill.offset_right = 0
	pill.offset_top = 8
	pill.offset_bottom = -4
	root.add_child(pill)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	pill.add_child(col)

	var hp_pair := _bar_with_label(HP_GREEN)
	col.add_child(hp_pair[0])
	_hp_bar = hp_pair[1]
	_hp_text = hp_pair[2]

	var en_pair := _bar_with_label(EN_BLUE)
	col.add_child(en_pair[0])
	_en_bar = en_pair[1]
	_en_text = en_pair[2]

	# Avatar circle on TOP of the pill, overflowing left + up
	var avatar := Panel.new()
	avatar.set_anchors_preset(Control.PRESET_TOP_LEFT)
	avatar.offset_left = 0
	avatar.offset_top = 0
	avatar.offset_right = 64
	avatar.offset_bottom = 64
	var av_sb := StyleBoxFlat.new()
	av_sb.bg_color = LEAF
	av_sb.set_corner_radius_all(32)
	av_sb.border_width_left = 3
	av_sb.border_width_right = 3
	av_sb.border_width_top = 3
	av_sb.border_width_bottom = 3
	av_sb.border_color = GOLD
	av_sb.shadow_color = SHADOW
	av_sb.shadow_size = 6
	av_sb.shadow_offset = Vector2(0, 2)
	avatar.add_theme_stylebox_override("panel", av_sb)
	root.add_child(avatar)

	_level_label = _label("1", 22, Color.WHITE, true)
	_level_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_level_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_level_label.add_theme_constant_override("outline_size", 3)
	avatar.add_child(_level_label)

func _bar_with_label(fill_color: Color) -> Array:
	var wrap := Control.new()
	wrap.custom_minimum_size = Vector2(0, 16)
	var bar := ProgressBar.new()
	bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	bar.show_percentage = false
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.55)
	bg.set_corner_radius_all(8)
	bg.border_width_left = 1
	bg.border_width_right = 1
	bg.border_width_top = 1
	bg.border_width_bottom = 1
	bg.border_color = Color(1, 1, 1, 0.15)
	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	fill.set_corner_radius_all(8)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)
	wrap.add_child(bar)

	var l := Label.new()
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 10)
	l.add_theme_color_override("font_color", Color.WHITE)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 2)
	l.text = "0 / 0"
	wrap.add_child(l)
	return [wrap, bar, l]

# ────────────────────────────────────────────────────────────────────────────
# Top-centre: a single floating pill with money / weather / date / time

func _build_top_pill() -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _floating_pill(20, 8))
	panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	panel.offset_left = -240
	panel.offset_right = 240
	panel.offset_top = 14
	panel.offset_bottom = 14 + 40
	add_child(panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(row)

	_money_label = _add_inline_stat(row, "🪙", "0g", GOLD)
	_add_divider(row)
	_weather_label = _add_inline_stat(row, "☀", "Sunny", TEXT_LIGHT)
	_add_divider(row)
	_date_label = _add_inline_stat(row, "📅", "Spring 1, Y1", TEXT_LIGHT)
	_add_divider(row)
	_time_label = _add_inline_stat(row, "🕐", "06:00 AM", TEXT_LIGHT)

func _add_inline_stat(parent: Node, icon: String, value: String, value_color: Color) -> Label:
	var inner := HBoxContainer.new()
	inner.add_theme_constant_override("separation", 4)
	parent.add_child(inner)
	inner.add_child(_label(icon, 14, GOLD))
	var v := _label(value, 14, value_color)
	inner.add_child(v)
	return v

func _add_divider(parent: Node) -> void:
	var d := ColorRect.new()
	d.color = Color(1, 1, 1, 0.12)
	d.custom_minimum_size = Vector2(1, 22)
	parent.add_child(d)

# ────────────────────────────────────────────────────────────────────────────
# Top-right: round minimap + 3 small round icon buttons stacked beside

func _build_minimap() -> void:
	# Minimap circle (no panel container — just a styled Panel for the disc)
	var map_size: int = 110
	var map := Panel.new()
	map.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	map.offset_left = -14 - map_size - 38  # leave room for the side icons
	map.offset_top = 14
	map.offset_right = -14 - 38
	map.offset_bottom = 14 + map_size
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.20, 0.32, 0.18, 0.92)
	sb.set_corner_radius_all(map_size / 2)
	sb.border_width_left = 3
	sb.border_width_right = 3
	sb.border_width_top = 3
	sb.border_width_bottom = 3
	sb.border_color = GOLD
	sb.shadow_color = SHADOW
	sb.shadow_size = 8
	sb.shadow_offset = Vector2(0, 3)
	map.add_theme_stylebox_override("panel", sb)
	add_child(map)

	# Player dot
	var dot := Panel.new()
	dot.set_anchors_preset(Control.PRESET_CENTER)
	dot.offset_left = -3; dot.offset_top = -3
	dot.offset_right = 3; dot.offset_bottom = 3
	var dsb := StyleBoxFlat.new()
	dsb.bg_color = BERRY
	dsb.set_corner_radius_all(3)
	dot.add_theme_stylebox_override("panel", dsb)
	map.add_child(dot)

	# 3 round side icons (Map / Quests / Bag) stacked to the right of the map
	var icons := [
		{"icon": "🗺", "label": "Map"},
		{"icon": "❗", "label": "Quests"},
		{"icon": "🎒", "label": "Bag"},
	]
	for i in range(icons.size()):
		var btn := _round_icon_button(icons[i].icon)
		btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		btn.offset_right = -14
		btn.offset_left = btn.offset_right - 30
		btn.offset_top = 14 + i * 36
		btn.offset_bottom = btn.offset_top + 30
		add_child(btn)

func _round_icon_button(icon: String) -> Panel:
	var b := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = PANEL_BG
	sb.set_corner_radius_all(15)
	sb.border_width_left = 1
	sb.border_width_right = 1
	sb.border_width_top = 1
	sb.border_width_bottom = 1
	sb.border_color = PANEL_BORDER
	sb.shadow_color = SHADOW
	sb.shadow_size = 4
	sb.shadow_offset = Vector2(0, 2)
	b.add_theme_stylebox_override("panel", sb)
	var l := _label(icon, 14, GOLD, true)
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	b.add_child(l)
	return b

# ────────────────────────────────────────────────────────────────────────────
# Right side: active quests (data-driven, lighter chrome)

func _build_quest_panel() -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	panel.offset_left = -224
	panel.offset_right = -14
	panel.offset_top = -84
	panel.offset_bottom = 84
	panel.add_theme_stylebox_override("panel", _floating_pill(14, 10))
	add_child(panel)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	panel.add_child(col)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 6)
	col.add_child(header)
	header.add_child(_label("❗", 11, GOLD))
	header.add_child(_label("ACTIVE QUESTS", 10, GOLD))
	var sep := ColorRect.new()
	sep.color = Color(1, 1, 1, 0.15)
	sep.custom_minimum_size = Vector2(0, 1)
	col.add_child(sep)

	_quest_list = VBoxContainer.new()
	_quest_list.add_theme_constant_override("separation", 6)
	col.add_child(_quest_list)

func _refresh_quests(_a = null, _b = null, _c = null) -> void:
	if _quest_list == null:
		return
	for child in _quest_list.get_children():
		child.queue_free()
	if GameState.active_quests.is_empty():
		_quest_list.add_child(_label("(none yet)", 10, TEXT_DIM))
		return
	for quest_id in GameState.active_quests:
		var data: Dictionary = GameState.get_quest(quest_id)
		var title: String = data.get("title", quest_id)
		var desc: String = data.get("description", "")
		_add_quest_row(title, desc, GameState.quest_progress.get(quest_id, {}))

func _add_quest_row(title: String, desc: String, progress: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	_quest_list.add_child(row)
	row.add_child(_label("★", 12, GOLD))
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 1)
	row.add_child(col)
	col.add_child(_label(title, 11, TEXT_LIGHT))
	var d := _label(desc, 9, TEXT_DIM)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(d)
	if not progress.is_empty():
		col.add_child(_label("%d / %d" % [int(progress.get("current",0)), int(progress.get("target",1))], 9, GOLD))

# ────────────────────────────────────────────────────────────────────────────
# Bottom centre: hotbar (single floating strip)

func _build_hotbar() -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	var slot_w: int = 40
	var sep: int = 3
	var total_w: int = HOTBAR_TOOLS.size() * slot_w + (HOTBAR_TOOLS.size() - 1) * sep + 12
	panel.offset_left = -total_w / 2
	panel.offset_right = total_w / 2
	panel.offset_top = -56
	panel.offset_bottom = -14
	panel.add_theme_stylebox_override("panel", _floating_pill(12, 4))
	add_child(panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", sep)
	panel.add_child(row)

	for i in range(HOTBAR_TOOLS.size()):
		var slot := PanelContainer.new()
		slot.custom_minimum_size = Vector2(slot_w, 40)
		slot.add_theme_stylebox_override("panel", _slot_box(false))
		row.add_child(slot)
		_hotbar_slots.append(slot)

		var icon := _label(HOTBAR_TOOLS[i].label, 14, INK, true)
		icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		slot.add_child(icon)

		var num := Label.new()
		num.text = HOTBAR_TOOLS[i].key
		num.add_theme_font_size_override("font_size", 8)
		num.add_theme_color_override("font_color", BERRY)
		num.position = Vector2(3, 1)
		slot.add_child(num)

		var count := Label.new()
		count.add_theme_font_size_override("font_size", 9)
		count.add_theme_color_override("font_color", INK)
		count.add_theme_color_override("font_outline_color", PARCHMENT)
		count.add_theme_constant_override("outline_size", 1)
		count.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		count.offset_left = -16; count.offset_top = -12
		count.offset_right = -2; count.offset_bottom = -1
		count.text = ""
		slot.add_child(count)
		_hotbar_count_labels.append(count)

func _slot_box(selected: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = PARCHMENT if not selected else Color(1.0, 0.94, 0.72)
	sb.set_corner_radius_all(7)
	sb.set_content_margin_all(2)
	var bw: int = 2 if selected else 1
	sb.border_width_left = bw
	sb.border_width_right = bw
	sb.border_width_top = bw
	sb.border_width_bottom = bw
	sb.border_color = GOLD if selected else Color(0.55, 0.40, 0.25, 0.5)
	return sb

func _select_hotbar(i: int) -> void:
	if i < 0 or i >= _hotbar_slots.size(): return
	GameState.set_current_tool(i)
	for j in range(_hotbar_slots.size()):
		_hotbar_slots[j].add_theme_stylebox_override("panel", _slot_box(j == i))

# ────────────────────────────────────────────────────────────────────────────
# Bottom right: 5 round icon buttons (no big container)

func _build_side_menu() -> void:
	var btn_d: int = 44
	var sep: int = 6
	var n: int = SIDE_MENU.size()
	for i in range(n):
		var btn := PanelContainer.new()
		btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		btn.offset_right = -14 - (n - 1 - i) * (btn_d + sep)
		btn.offset_left = btn.offset_right - btn_d
		btn.offset_bottom = -16
		btn.offset_top = btn.offset_bottom - btn_d
		var sb := StyleBoxFlat.new()
		sb.bg_color = PANEL_BG
		sb.set_corner_radius_all(btn_d / 2)
		sb.border_width_left = 1
		sb.border_width_right = 1
		sb.border_width_top = 1
		sb.border_width_bottom = 1
		sb.border_color = PANEL_BORDER
		sb.shadow_color = SHADOW
		sb.shadow_size = 6
		sb.shadow_offset = Vector2(0, 2)
		btn.add_theme_stylebox_override("panel", sb)
		add_child(btn)

		var icon := _label(SIDE_MENU[i].icon, 18, GOLD, true)
		icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		icon.offset_top = -4
		btn.add_child(icon)

		# Tiny key hint below the icon
		var key := _label("[%s]" % SIDE_MENU[i].key, 8, TEXT_DIM, true)
		key.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		key.offset_top = -10
		key.offset_bottom = -2
		btn.add_child(key)

# ────────────────────────────────────────────────────────────────────────────
# Bottom left: small chat / event log (lighter chrome)

func _build_chat_log() -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	panel.offset_left = 14
	panel.offset_right = 14 + 240
	panel.offset_top = -110
	panel.offset_bottom = -14
	panel.add_theme_stylebox_override("panel", _floating_pill(12, 8))
	add_child(panel)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 3)
	panel.add_child(col)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 4)
	col.add_child(header)
	header.add_child(_label("📜", 10, GOLD))
	header.add_child(_label("EVENT LOG", 9, GOLD))
	var sep := ColorRect.new()
	sep.color = Color(1, 1, 1, 0.12)
	sep.custom_minimum_size = Vector2(0, 1)
	col.add_child(sep)

	_add_log(col, "Wizard:", "Welcome to Greenfield Valley.", GOLD)
	_add_log(col, "Mayor:", "Find the Inn Master at the farm.", LEAF)
	_add_log(col, "Tip:", "1-6 switch tools, [E] interact.", TEXT_DIM)

	# Inventory mini-strip lives at the bottom of the log
	_inventory_label = Label.new()
	_inventory_label.add_theme_font_size_override("font_size", 9)
	_inventory_label.add_theme_color_override("font_color", TEXT_DIM)
	_inventory_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_inventory_label)
	_refresh_inventory_strip()

func _add_log(parent: Node, who: String, msg: String, who_color: Color) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	parent.add_child(row)
	row.add_child(_label(who, 10, who_color))
	var m := _label(msg, 10, TEXT_LIGHT)
	m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	m.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(m)

func _refresh_inventory_strip() -> void:
	if _inventory_label == null:
		return
	var parts: Array[String] = []
	for k in ["parsnip_seeds", "parsnip", "wood", "stone"]:
		var n: int = GameState.item_count(k)
		if n > 0:
			parts.append("%s ×%d" % [_pretty(k), n])
	_inventory_label.text = "🎒 " + ("  ·  ".join(parts) if parts.size() > 0 else "(empty)")

func _pretty(item_id: String) -> String:
	return item_id.capitalize().replace("_", " ")

# ────────────────────────────────────────────────────────────────────────────
# Signal handlers

func _on_money(amount: int) -> void:
	_money_label.text = "%dg" % amount

func _on_time(hour: int, minute: int) -> void:
	var ampm: String = "AM" if hour < 12 else "PM"
	var h12: int = hour % 12
	if h12 == 0:
		h12 = 12
	_time_label.text = "%02d:%02d %s" % [h12, minute, ampm]

func _on_day(day: int, _month: int, year: int) -> void:
	_date_label.text = "%s %d, Y%d" % [GameState.get_season(), day, year]

func _on_weather(_w: int) -> void:
	_weather_label.text = GameState.weather_name()

func _on_rank(_r: int) -> void:
	pass

func _on_inventory(item_id: String, count: int) -> void:
	_refresh_inventory_strip()
	if item_id == "parsnip_seeds" and _hotbar_count_labels.size() > 5:
		_hotbar_count_labels[5].text = str(count) if count > 0 else ""

func _on_hp(value: int, max_val: int) -> void:
	_hp_bar.max_value = max_val
	_hp_bar.value = value
	_hp_text.text = "%d / %d" % [value, max_val]

func _on_energy(value: int, max_val: int) -> void:
	_en_bar.max_value = max_val
	_en_bar.value = value
	_en_text.text = "%d / %d" % [value, max_val]

func _refresh_all() -> void:
	_on_money(GameState.money)
	_on_time(int(GameState.hour), int(GameState.minute))
	_on_day(GameState.day, GameState.month, GameState.year)
	_on_weather(GameState.weather)
	_on_hp(GameState.hp, GameState.max_hp)
	_on_energy(GameState.energy, GameState.max_energy)
	_refresh_inventory_strip()
	_refresh_quests()
	if _hotbar_count_labels.size() > 5:
		var seeds: int = GameState.item_count("parsnip_seeds")
		_hotbar_count_labels[5].text = str(seeds) if seeds > 0 else ""
