extends CanvasLayer
## Top-bar HUD: money, weather, date, time. Builds itself in code so the .tscn
## stays a one-line stub. Reactive to GameState signals.

const PANEL_BG := Color(0.96, 0.92, 0.82, 0.95)
const TITLE_COLOR := Color(0.35, 0.25, 0.15)
const VALUE_COLOR := Color(0.15, 0.1, 0.05)

var _money_label: Label
var _date_label: Label
var _time_label: Label
var _weather_label: Label

func _ready() -> void:
	var bar := HBoxContainer.new()
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.offset_left = 16
	bar.offset_top = 16
	bar.offset_right = -16
	bar.offset_bottom = 100
	bar.alignment = BoxContainer.ALIGNMENT_END
	bar.add_theme_constant_override("separation", 12)
	add_child(bar)

	_money_label = _make_panel(bar, "MONEY", "0g")
	_weather_label = _make_panel(bar, "WEATHER", "Sunny")
	_date_label = _make_panel(bar, "DATE", "Spring 1, Y1")
	_time_label = _make_panel(bar, "TIME", "09:00 AM")

	GameState.money_changed.connect(_on_money)
	GameState.time_changed.connect(_on_time)
	GameState.day_changed.connect(_on_day)
	GameState.weather_changed.connect(_on_weather)
	_refresh_all()

func _make_panel(parent: Node, title: String, value: String) -> Label:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(150, 0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = PANEL_BG
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(10)
	sb.border_width_left = 2
	sb.border_width_right = 2
	sb.border_width_top = 2
	sb.border_width_bottom = 2
	sb.border_color = Color(0.55, 0.4, 0.25)
	panel.add_theme_stylebox_override("panel", sb)
	parent.add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 2)
	panel.add_child(vb)

	var t := Label.new()
	t.text = title
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 12)
	t.add_theme_color_override("font_color", TITLE_COLOR)
	vb.add_child(t)

	var v := Label.new()
	v.text = value
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_theme_font_size_override("font_size", 22)
	v.add_theme_color_override("font_color", VALUE_COLOR)
	vb.add_child(v)
	return v

func _on_money(amount: int) -> void:
	_money_label.text = "%dg" % amount

func _on_time(hour: int, minute: int) -> void:
	var ampm := "AM" if hour < 12 else "PM"
	var h12 := hour % 12
	if h12 == 0:
		h12 = 12
	_time_label.text = "%02d:%02d %s" % [h12, minute, ampm]

func _on_day(day: int, _month: int, year: int) -> void:
	_date_label.text = "%s %d, Y%d" % [GameState.get_season(), day, year]

func _on_weather(_w: int) -> void:
	_weather_label.text = GameState.weather_name()

func _refresh_all() -> void:
	_on_money(GameState.money)
	_on_time(int(GameState.hour), int(GameState.minute))
	_on_day(GameState.day, GameState.month, GameState.year)
	_on_weather(GameState.weather)
