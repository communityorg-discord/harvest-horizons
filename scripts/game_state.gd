extends Node
## Global singleton: time, money, weather. Anything that survives across scenes.

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

var day: int = 12
var month: int = 3
var year: int = 2
var hour: float = 9.0
var minute: float = 30.0
var time_speed: float = 2.0  # game-minutes per real-second (1 day ≈ 12 real min)

var money: int = 1250

var weather: int = Weather.SUNNY

var rank: int = Rank.NEW_ARRIVAL
# Set of completed quest ids. Areas/dialog gate on these.
var quest_flags: Dictionary = {}

signal time_changed(hour: int, minute: int)
signal day_changed(day: int, month: int, year: int)
signal money_changed(amount: int)
signal weather_changed(weather: int)
signal rank_changed(rank: int)
signal quest_completed(quest_id: String)

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

func _advance_day() -> void:
	day += 1
	if day > 28:
		day = 1
		month += 1
		if month > 12:
			month = 1
			year += 1
	day_changed.emit(day, month, year)

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
