extends Node
## Global singleton: time, money, weather, HP/Energy, save/load, sleep system.
## Anything that needs to survive across scenes lives here.

enum Weather { SUNNY, RAINY, FOGGY, STORMY }
enum Rank { NEW_ARRIVAL, LOCAL_HELPER, TRUSTED_FARMER, TOWN_RESTORER, VALLEY_HERO, CHOSEN_GUARDIAN }

const RANK_NAMES := [
	"New Arrival", "Local Helper", "Trusted Farmer",
	"Town Restorer", "Valley Hero", "Chosen Guardian"
]

const MONTH_NAMES := [
	"", "January", "February", "March", "April", "May", "June",
	"July", "August", "September", "October", "November", "December"
]

const SAVE_PATH := "user://save.json"

# Sleep schedule (see docs/DESIGN.md)
const NORMAL_BED_CUTOFF := 23.0  # before 11 PM = wake at 5 AM
const PASS_OUT_HOUR := 3.0       # if you're still up at 3 AM, you collapse
const PASS_OUT_WAKE := 14.0      # collapse → wake at 2 PM
const NORMAL_WAKE := 5.0         # default wake time

# ─── State ─────────────────────────────────────────────────────────────────

var day: int = 12
var month: int = 3
var year: int = 2
var hour: float = 9.0
var minute: float = 30.0
var time_speed: float = 2.0  # game-minutes per real-second (1 day ≈ 12 real min)

var money: int = 1250
var weather: int = Weather.SUNNY
var rank: int = Rank.NEW_ARRIVAL
var quest_flags: Dictionary = {}
var current_tool: int = 0
var inventory: Dictionary = {"parsnip_seeds": 8, "parsnip": 0, "wood": 0, "stone": 0}

var max_hp: int = 100
var hp: int = 100
var max_energy: int = 100
var energy: int = 80

# Per-day flag: did the player make it to bed before 3 AM?
var has_slept_today: bool = true  # start "true" so the first day doesn't pass-out

# Where to spawn the player on next scene load. "" = default scene spawn.
# "bed_side" = next to the cottage bed marker (used after sleep + pass-out).
var next_spawn: String = ""

# ─── Signals ───────────────────────────────────────────────────────────────

signal time_changed(hour: int, minute: int)
signal day_changed(day: int, month: int, year: int)
signal money_changed(amount: int)
signal weather_changed(weather: int)
signal rank_changed(rank: int)
signal quest_completed(quest_id: String)
signal current_tool_changed(index: int)
signal inventory_changed(item_id: String, count: int)
signal hp_changed(hp: int, max_hp: int)
signal energy_changed(energy: int, max_energy: int)
signal slept(wake_hour: int)
signal passed_out()

# ─── Tick ──────────────────────────────────────────────────────────────────

func _ready() -> void:
	# Auto-load save on first launch (if present).
	if FileAccess.file_exists(SAVE_PATH):
		load_game()

func _process(delta: float) -> void:
	var prev_minute := int(minute)
	minute += delta * time_speed
	while minute >= 60.0:
		minute -= 60.0
		hour += 1.0
		if hour >= 24.0:
			hour = 0.0
			_advance_day()
	if int(minute) != prev_minute:
		time_changed.emit(int(hour), int(minute))
		# Check pass-out: if we've crossed into 3 AM and still haven't slept.
		if not has_slept_today and hour >= PASS_OUT_HOUR and hour < NORMAL_WAKE:
			pass_out()

func _advance_day() -> void:
	day += 1
	has_slept_today = false  # reset for the new day
	if day > 28:
		day = 1
		month += 1
		if month > 12:
			month = 1
			year += 1
	day_changed.emit(day, month, year)

# ─── Sleep / pass-out ──────────────────────────────────────────────────────

# Determine the wake hour for a given bedtime hour (24h float).
# Per design: any time up to 11 PM → 5 AM. Each hour after 11 PM pushes wake
# back by an hour, until 3 AM where you pass out.
func wake_hour_for(bedtime: float) -> float:
	if bedtime < NORMAL_BED_CUTOFF and bedtime >= NORMAL_WAKE:
		# Daytime nap or evening sleep: still wake next morning at 5 AM.
		return NORMAL_WAKE
	if bedtime >= NORMAL_BED_CUTOFF:
		# Late evening (23..24): wake_offset = bedtime - 23 hours after 5 AM.
		return NORMAL_WAKE + (bedtime - NORMAL_BED_CUTOFF)
	# Early-morning sleep (00..03): treat as 24..27 for the math.
	if bedtime < PASS_OUT_HOUR:
		return NORMAL_WAKE + (24.0 + bedtime - NORMAL_BED_CUTOFF)
	# Shouldn't get here — pass_out handles >= 3 AM.
	return PASS_OUT_WAKE

# Player walked into the bed and pressed interact. Advance time, restore
# stats, write a save file, mark spawn target so the wake-up positions the
# player at the bedside.
func sleep() -> void:
	var bedtime: float = hour + minute / 60.0
	var wake: float = wake_hour_for(bedtime)
	# Skip to wake time. If we're past midnight already, wake is "today".
	if bedtime >= NORMAL_BED_CUTOFF:
		# Sleeping in the late evening — wake is on the next calendar day.
		_advance_day()
	hour = floor(wake)
	minute = (wake - floor(wake)) * 60.0
	hp = max_hp
	energy = max_energy
	has_slept_today = true
	hp_changed.emit(hp, max_hp)
	energy_changed.emit(energy, max_energy)
	time_changed.emit(int(hour), int(minute))
	next_spawn = "bed_side"
	save_game()
	slept.emit(int(hour))

# Triggered when the clock reaches 3 AM and the player still hasn't slept.
# Skip to 2 PM the same day, halve HP and Energy, and force-respawn at the
# cottage bed (the player collapses, dragged home).
func pass_out() -> void:
	hour = PASS_OUT_WAKE
	minute = 0.0
	hp = int(max_hp * 0.5)
	energy = int(max_energy * 0.5)
	has_slept_today = true
	hp_changed.emit(hp, max_hp)
	energy_changed.emit(energy, max_energy)
	time_changed.emit(int(hour), int(minute))
	next_spawn = "bed_side"
	save_game()
	passed_out.emit()
	# Boot us into the cottage interior wherever we are right now.
	get_tree().change_scene_to_file("res://scenes/cottage_interior.tscn")

# ─── Save / load ───────────────────────────────────────────────────────────

func save_game() -> bool:
	var data := {
		"version": 1,
		"day": day, "month": month, "year": year,
		"hour": hour, "minute": minute,
		"money": money, "weather": weather, "rank": rank,
		"quest_flags": quest_flags, "current_tool": current_tool,
		"inventory": inventory,
		"hp": hp, "energy": energy, "max_hp": max_hp, "max_energy": max_energy,
		"has_slept_today": has_slept_today,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("save_game: could not open %s" % SAVE_PATH)
		return false
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
	return true

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	var raw: String = f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(raw)
	if not (parsed is Dictionary):
		push_warning("load_game: corrupt save")
		return false
	var d: Dictionary = parsed
	day = int(d.get("day", day))
	month = int(d.get("month", month))
	year = int(d.get("year", year))
	hour = float(d.get("hour", hour))
	minute = float(d.get("minute", minute))
	money = int(d.get("money", money))
	weather = int(d.get("weather", weather))
	rank = int(d.get("rank", rank))
	quest_flags = d.get("quest_flags", {}) as Dictionary
	current_tool = int(d.get("current_tool", current_tool))
	inventory = d.get("inventory", inventory) as Dictionary
	hp = int(d.get("hp", hp))
	max_hp = int(d.get("max_hp", max_hp))
	energy = int(d.get("energy", energy))
	max_energy = int(d.get("max_energy", max_energy))
	has_slept_today = bool(d.get("has_slept_today", has_slept_today))
	# Re-emit signals so any listeners refresh.
	time_changed.emit(int(hour), int(minute))
	day_changed.emit(day, month, year)
	money_changed.emit(money)
	weather_changed.emit(weather)
	rank_changed.emit(rank)
	hp_changed.emit(hp, max_hp)
	energy_changed.emit(energy, max_energy)
	for item_id in inventory:
		inventory_changed.emit(item_id, inventory[item_id])
	return true

func clear_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))

# ─── Existing helpers (unchanged) ──────────────────────────────────────────

func add_money(amount: int) -> void:
	money += amount
	money_changed.emit(money)

func set_weather(w: int) -> void:
	weather = w
	weather_changed.emit(weather)

func get_season() -> String:
	match month:
		1, 2, 12: return "Winter"
		3, 4, 5: return "Spring"
		6, 7, 8: return "Summer"
		9, 10, 11: return "Autumn"
	return "Spring"

func weather_name() -> String:
	return ["Sunny", "Rainy", "Foggy", "Stormy"][weather]

func rank_name() -> String:
	return RANK_NAMES[rank]

func promote_to(new_rank: int) -> void:
	if new_rank > rank:
		rank = new_rank
		rank_changed.emit(rank)

func complete_quest(quest_id: String) -> void:
	if quest_flags.has(quest_id):
		return
	quest_flags[quest_id] = true
	quest_completed.emit(quest_id)

func has_completed(quest_id: String) -> bool:
	return quest_flags.has(quest_id)

func set_current_tool(index: int) -> void:
	if index == current_tool:
		return
	current_tool = index
	current_tool_changed.emit(index)

func add_item(item_id: String, count: int = 1) -> void:
	inventory[item_id] = inventory.get(item_id, 0) + count
	inventory_changed.emit(item_id, inventory[item_id])

func remove_item(item_id: String, count: int = 1) -> bool:
	if inventory.get(item_id, 0) < count:
		return false
	inventory[item_id] -= count
	inventory_changed.emit(item_id, inventory[item_id])
	return true

func item_count(item_id: String) -> int:
	return inventory.get(item_id, 0)

# Damage and energy helpers (used by quests / future combat / tool use).

func damage(amount: int) -> void:
	hp = clampi(hp - amount, 0, max_hp)
	hp_changed.emit(hp, max_hp)

func heal(amount: int) -> void:
	hp = clampi(hp + amount, 0, max_hp)
	hp_changed.emit(hp, max_hp)

func spend_energy(amount: int) -> void:
	energy = clampi(energy - amount, 0, max_energy)
	energy_changed.emit(energy, max_energy)
