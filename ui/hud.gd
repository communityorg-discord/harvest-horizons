extends CanvasLayer
## Cozy game HUD — sized to match the concept art proportions:
## small player card top-left, single combined stats pill top-centre,
## small circular minimap top-right, tight active-quests panel right side,
## hotbar bottom-centre, side-menu icon buttons bottom-right, event log
## bottom-left. Live-bound to GameState (hp/energy/money/time/weather/quests).

# ────────────────────────────────────────────────────────────────────────────
# Theme

const PARCHMENT       := Color(0.96, 0.92, 0.82, 0.95)
const DARK_PANEL      := Color(0.18, 0.14, 0.10, 0.92)
const INK             := Color(0.22, 0.16, 0.10)
const INK_SOFT        := Color(0.45, 0.35, 0.22)
const BORDER          := Color(0.55, 0.40, 0.25)
const GOLD            := Color(0.78, 0.62, 0.28)
const LEAF            := Color(0.40, 0.55, 0.22)
const BERRY           := Color(0.72, 0.32, 0.22)
const HP_GREEN        := Color(0.40, 0.74, 0.32)
const EN_BLUE         := Color(0.32, 0.62, 0.86)

const HOTBAR_TOOLS := [
	{"name": "Hoe",     "label": "H", "key": "1"},
	{"name": "Water",   "label": "W", "key": "2"},
	{"name": "Axe",     "label": "A", "key": "3"},
	{"name": "Pickaxe", "label": "P", "key": "4"},
	{"name": "Sword",   "label": "S", "key": "5"},
	{"name": "Seeds",   "label": "*", "key": "6"},
]

const SIDE_MENU := [
	{"label": "Inventory", "key": "I"},
	{"label": "Skills",    "key": "K"},
	{"label": "Journal",   "key": "U"},
	{"label": "People",    "key": "C"},
	{"label": "Map",       "key": "M"},
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
	_build_top_bar()
	_build_minimap()
	_build_quest_panel()
	_build_hotbar()
	_build_inventory_strip()
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
# Stylebox helpers

func _dark_box(corner: int = 8, padding: int = 6) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = DARK_PANEL
	sb.set_corner_radius_all(corner)
	sb.set_content_margin_all(padding)
	sb.border_width_left = 2
	sb.border_width_right = 2
	sb.border_width_top = 2
	sb.border_width_bottom = 2
	sb.border_color = GOLD
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
# Top-left: tight player card with HP/EN bars + money below

func _build_player_card() -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _dark_box(10, 6))
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.offset_left = 12
	panel.offset_top = 12
	panel.offset_right = 12 + 240
	panel.offset_bottom = 12 + 60
	add_child(panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)

	# Avatar circle (compact)
	var avatar := Panel.new()
	avatar.custom_minimum_size = Vector2(48, 48)
	var av_sb := StyleBoxFlat.new()
	av_sb.bg_color = LEAF
	av_sb.set_corner_radius_all(24)
	av_sb.border_width_left = 2
	av_sb.border_width_right = 2
	av_sb.border_width_top = 2
	av_sb.border_width_bottom = 2
	av_sb.border_color = GOLD
	avatar.add_theme_stylebox_override("panel", av_sb)
	row.add_child(avatar)
	_level_label = _label("1", 18, Color.WHITE, true)
	_level_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	avatar.add_child(_level_label)

	var bars := VBoxContainer.new()
	bars.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bars.add_theme_constant_override("separation", 4)
	row.add_child(bars)

	var hp_pair := _bar_with_label(HP_GREEN)
	bars.add_child(hp_pair[0])
	_hp_bar = hp_pair[1]
	_hp_text = hp_pair[2]

	var en_pair := _bar_with_label(EN_BLUE)
	bars.add_child(en_pair[0])
	_en_bar = en_pair[1]
	_en_text = en_pair[2]

func _bar_with_label(fill_color: Color) -> Array:
	var wrap := Control.new()
	wrap.custom_minimum_size = Vector2(0, 16)
	var bar := ProgressBar.new()
	bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	bar.show_percentage = false
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.6)
	bg.set_corner_radius_all(3)
	bg.border_width_left = 1
	bg.border_width_right = 1
	bg.border_width_top = 1
	bg.border_width_bottom = 1
	bg.border_color = Color(1, 1, 1, 0.18)
	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	fill.set_corner_radius_all(3)
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
# Top centre: ONE compact pill — weather · date · time, money on the left side

func _build_top_bar() -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _dark_box(10, 8))
	panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	panel.offset_left = -260
	panel.offset_right = 260
	panel.offset_top = 12
	panel.offset_bottom = 12 + 48
	add_child(panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(row)

	_money_label = _add_inline_stat(row, "🪙", "0g", GOLD)
	_add_divider(row)
	_weather_label = _add_inline_stat(row, "☀", "Sunny", Color.WHITE)
	_add_divider(row)
	_date_label = _add_inline_stat(row, "📅", "Spring 1, Y1", Color.WHITE)
	_add_divider(row)
	_time_label = _add_inline_stat(row, "🕐", "06:00 AM", Color.WHITE)

func _add_inline_stat(parent: Node, icon: String, value: String, value_color: Color) -> Label:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	parent.add_child(row)
	var i := _label(icon, 16, GOLD)
	row.add_child(i)
	var v := _label(value, 16, value_color)
	row.add_child(v)
	return v

func _add_divider(parent: Node) -> void:
	var d := ColorRect.new()
	d.color = Color(1, 1, 1, 0.15)
	d.custom_minimum_size = Vector2(1, 28)
	parent.add_child(d)

# ────────────────────────────────────────────────────────────────────────────
# Top-right: small minimap

func _build_minimap() -> void:
	var wrap := PanelContainer.new()
	wrap.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	wrap.offset_left = -148
	wrap.offset_top = 12
	wrap.offset_right = -12
	wrap.offset_bottom = 12 + 138
	wrap.add_theme_stylebox_override("panel", _dark_box(10, 6))
	add_child(wrap)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 3)
	wrap.add_child(col)

	col.add_child(_label("GREENFIELD", 9, GOLD, true))

	var map := Panel.new()
	map.custom_minimum_size = Vector2(120, 96)
	var mb := StyleBoxFlat.new()
	mb.bg_color = Color(0.20, 0.32, 0.18)
	mb.set_corner_radius_all(48)
	mb.border_width_left = 2
	mb.border_width_right = 2
	mb.border_width_top = 2
	mb.border_width_bottom = 2
	mb.border_color = GOLD
	map.add_theme_stylebox_override("panel", mb)
	col.add_child(map)

	var dot := Panel.new()
	dot.custom_minimum_size = Vector2(6, 6)
	dot.set_anchors_preset(Control.PRESET_CENTER)
	dot.offset_left = -3; dot.offset_top = -3
	dot.offset_right = 3; dot.offset_bottom = 3
	var dsb := StyleBoxFlat.new()
	dsb.bg_color = BERRY
	dsb.set_corner_radius_all(3)
	dot.add_theme_stylebox_override("panel", dsb)
	map.add_child(dot)

# ────────────────────────────────────────────────────────────────────────────
# Right side: active quests (data-driven from GameState)

func _build_quest_panel() -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	panel.offset_left = -228
	panel.offset_right = -12
	panel.offset_top = -90
	panel.offset_bottom = 90
	panel.add_theme_stylebox_override("panel", _dark_box(10, 8))
	add_child(panel)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	panel.add_child(col)

	col.add_child(_label("ACTIVE QUESTS", 10, GOLD, true))
	var sep := ColorRect.new()
	sep.color = Color(1, 1, 1, 0.2)
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
		_quest_list.add_child(_label("(none yet)", 11, Color(0.7, 0.6, 0.45)))
		return
	for quest_id in GameState.active_quests:
		var data: Dictionary = GameState.get_quest(quest_id)
		var title: String = data.get("title", quest_id)
		var desc: String = data.get("description", "")
		_add_quest_row(title, desc, GameState.quest_progress.get(quest_id, {}))

func _add_quest_row(title: String, desc: String, progress: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	_quest_list.add_child(row)
	row.add_child(_label("★", 14, GOLD))
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(col)
	var t := _label(title, 12, Color.WHITE)
	col.add_child(t)
	var d := _label(desc, 10, Color(0.85, 0.80, 0.68))
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(d)
	if not progress.is_empty():
		col.add_child(_label("%d / %d" % [int(progress.get("current",0)), int(progress.get("target",1))], 10, GOLD))

# ────────────────────────────────────────────────────────────────────────────
# Bottom centre: hotbar (compact)

func _build_hotbar() -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	var slot_w: int = 44
	var sep: int = 4
	var total_w: int = HOTBAR_TOOLS.size() * slot_w + (HOTBAR_TOOLS.size() - 1) * sep + 16
	panel.offset_left = -total_w / 2
	panel.offset_right = total_w / 2
	panel.offset_top = -64
	panel.offset_bottom = -16
	panel.add_theme_stylebox_override("panel", _dark_box(8, 4))
	add_child(panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", sep)
	panel.add_child(row)

	for i in range(HOTBAR_TOOLS.size()):
		var slot := PanelContainer.new()
		slot.custom_minimum_size = Vector2(slot_w, 44)
		slot.add_theme_stylebox_override("panel", _slot_box(false))
		row.add_child(slot)
		_hotbar_slots.append(slot)

		var inner := VBoxContainer.new()
		inner.alignment = BoxContainer.ALIGNMENT_CENTER
		inner.add_theme_constant_override("separation", 0)
		slot.add_child(inner)

		var icon := _label(HOTBAR_TOOLS[i].label, 16, INK, true)
		inner.add_child(icon)
		var name := _label(HOTBAR_TOOLS[i].name, 8, INK_SOFT, true)
		inner.add_child(name)

		var num := Label.new()
		num.text = HOTBAR_TOOLS[i].key
		num.add_theme_font_size_override("font_size", 9)
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

func _build_inventory_strip() -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	panel.offset_left = -160
	panel.offset_right = 160
	panel.offset_top = -94
	panel.offset_bottom = -68
	panel.add_theme_stylebox_override("panel", _dark_box(6, 4))
	add_child(panel)

	_inventory_label = Label.new()
	_inventory_label.add_theme_font_size_override("font_size", 11)
	_inventory_label.add_theme_color_override("font_color", Color.WHITE)
	_inventory_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(_inventory_label)
	_refresh_inventory_strip()

func _refresh_inventory_strip() -> void:
	if _inventory_label == null:
		return
	var parts: Array[String] = []
	for k in ["parsnip_seeds", "parsnip", "wood", "stone"]:
		var n: int = GameState.item_count(k)
		if n > 0:
			parts.append("%s ×%d" % [_pretty(k), n])
	_inventory_label.text = "  ·  ".join(parts) if parts.size() > 0 else "(empty)"

func _pretty(item_id: String) -> String:
	return item_id.capitalize().replace("_", " ")

func _slot_box(selected: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = PARCHMENT if not selected else Color(1.0, 0.94, 0.72)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(2)
	var bw: int = 2 if selected else 1
	sb.border_width_left = bw
	sb.border_width_right = bw
	sb.border_width_top = bw
	sb.border_width_bottom = bw
	sb.border_color = GOLD if selected else BORDER
	return sb

func _select_hotbar(i: int) -> void:
	if i < 0 or i >= _hotbar_slots.size(): return
	GameState.set_current_tool(i)
	for j in range(_hotbar_slots.size()):
		_hotbar_slots[j].add_theme_stylebox_override("panel", _slot_box(j == i))

# ────────────────────────────────────────────────────────────────────────────
# Bottom right: side menu (smaller)

func _build_side_menu() -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	var btn_w: int = 56
	var sep: int = 4
	var total_w: int = SIDE_MENU.size() * btn_w + (SIDE_MENU.size() - 1) * sep + 16
	panel.offset_left = -total_w
	panel.offset_right = -12
	panel.offset_top = -60
	panel.offset_bottom = -12
	panel.add_theme_stylebox_override("panel", _dark_box(8, 4))
	add_child(panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", sep)
	panel.add_child(row)

	for entry in SIDE_MENU:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(btn_w, 44)
		btn.add_theme_font_size_override("font_size", 10)
		btn.add_theme_color_override("font_color", INK)
		btn.add_theme_stylebox_override("normal", _slot_box(false))
		btn.add_theme_stylebox_override("hover", _slot_box(true))
		btn.add_theme_stylebox_override("pressed", _slot_box(true))
		btn.text = "%s\n[%s]" % [entry.label, entry.key]
		row.add_child(btn)

# ────────────────────────────────────────────────────────────────────────────
# Bottom left: small chat / event log

func _build_chat_log() -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	panel.offset_left = 12
	panel.offset_right = 12 + 240
	panel.offset_top = -116
	panel.offset_bottom = -12
	panel.add_theme_stylebox_override("panel", _dark_box(8, 6))
	add_child(panel)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 3)
	panel.add_child(col)
	col.add_child(_label("EVENT LOG", 9, GOLD))
	var sep := ColorRect.new()
	sep.color = Color(1, 1, 1, 0.15)
	sep.custom_minimum_size = Vector2(0, 1)
	col.add_child(sep)

	_add_log(col, "Wizard:", "Welcome to Greenfield Valley.", GOLD)
	_add_log(col, "Mayor:", "Find the Inn Master at the farm.", LEAF)
	_add_log(col, "Tip:", "Press 1-6 to switch tools, [E] to interact.", Color(0.8, 0.75, 0.6))

func _add_log(parent: Node, who: String, msg: String, who_color: Color) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	parent.add_child(row)
	row.add_child(_label(who, 10, who_color))
	var m := _label(msg, 10, Color(0.92, 0.88, 0.76))
	m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	m.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(m)

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
