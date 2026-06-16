extends Node3D

enum Weather { SUNNY, RAIN, WIND, STORM }

const SHEEP_BUY_PRICE = 25000
const SHEEP_SELL_PRICE = 20000

var barn_hay: int = 0
var barn_capacity: int = 1000
var day_count: int = 1
var year: int = 1
var season: String = "Vor"
var current_weather: Weather = Weather.SUNNY

var sheep_count: int = 50
var hay_per_sheep_per_day: float = 0.2
var lambing_completed: bool = false
var lambs_born_this_year: int = 0
var hay_shortage_days: int = 0

var money: int = 2500000
var daily_cost: int = 5000

var selected_field = null

@onready var field_info: Label = $UI/FieldPanel/FieldInfo
@onready var harvest_button: Button = $UI/FieldPanel/HarvestButton
@onready var hay_label: Label = $UI/FieldPanel/HayLabel
@onready var day_label: Label = $UI/FieldPanel/DayLabel
@onready var weather_label: Label = $UI/FieldPanel/WeatherLabel
@onready var next_day_button: Button = $UI/FieldPanel/NextDayButton
@onready var sheep_label: Label = $UI/FieldPanel/SheepLabel
@onready var money_label: Label = $UI/FieldPanel/MoneyLabel
@onready var warning_label: Label = $UI/FieldPanel/WarningLabel
@onready var buy_sheep_button: Button = $UI/FieldPanel/BuySheepButton
@onready var sell_sheep_button: Button = $UI/FieldPanel/SellSheepButton
@onready var year_label: Label = $UI/FieldPanel/YearLabel
@onready var season_label: Label = $UI/FieldPanel/SeasonLabel
@onready var lambs_label: Label = $UI/FieldPanel/LambsLabel
@onready var hay_forecast_label: Label = $UI/FieldPanel/HayForecastLabel
@onready var fertilize_button: Button = $UI/FieldPanel/FertilizeButton
@onready var camera: Camera3D = $Camera3D

func _get_effective_hay_rate() -> float:
	if season == "Vetur":
		return hay_per_sheep_per_day * 1.5
	return hay_per_sheep_per_day

func _process_hay_consumption() -> String:
	var consumed: int = int(sheep_count * _get_effective_hay_rate())
	if barn_hay < consumed:
		barn_hay = 0
	else:
		barn_hay -= consumed
	if barn_hay == 0 and consumed > 0:
		hay_shortage_days += 1
		return "Viðvörun: Heyið er búið!"
	hay_shortage_days = 0
	return ""

func _run_lambing() -> int:
	var lambs = 0
	for i in range(sheep_count):
		if randf() < 0.3:
			lambs += 1
	return lambs

func _get_season() -> String:
	if day_count <= 22:
		return "Vor"
	elif day_count <= 45:
		return "Sumar"
	elif day_count <= 68:
		return "Haust"
	else:
		return "Vetur"

func _weather_name() -> String:
	match current_weather:
		Weather.SUNNY: return "Sólskin"
		Weather.RAIN:  return "Rigning"
		Weather.WIND:  return "Vindur"
		Weather.STORM: return "Stormur"
	return ""

func _ready():
	harvest_button.pressed.connect(_on_harvest_pressed)
	harvest_button.disabled = true
	hay_label.text = "Hey í hlöðu: 0 / " + str(barn_capacity)
	next_day_button.pressed.connect(_on_next_day_pressed)
	day_label.text = "Dagur: " + str(day_count)
	weather_label.text = "Veður: " + _weather_name()
	sheep_label.text = "Kindur: " + str(sheep_count)
	money_label.text = "Peningar: " + str(money) + " kr."
	warning_label.text = ""
	year_label.text = "Ár: " + str(year)
	season_label.text = "Árstíð: " + season
	lambs_label.text = "Lömb fædd í ár: " + str(lambs_born_this_year)
	hay_forecast_label.text = "Hey endast í 0 daga."
	fertilize_button.pressed.connect(_on_fertilize_pressed)
	fertilize_button.disabled = true
	buy_sheep_button.pressed.connect(_on_buy_sheep_pressed)
	sell_sheep_button.pressed.connect(_on_sell_sheep_pressed)
	_update_sheep_buttons()

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var from = camera.project_ray_origin(event.position)
		var to = from + camera.project_ray_normal(event.position) * 1000.0

		var query = PhysicsRayQueryParameters3D.create(from, to)
		var result = get_world_3d().direct_space_state.intersect_ray(query)

		if result.is_empty():
			field_info.text = "Ekkert tún valið"
			selected_field = null
			harvest_button.disabled = true
			fertilize_button.disabled = true
			return

		var clicked = result.collider
		var field = clicked
		while field != null and not field.has_method("get_field_info"):
			field = field.get_parent()

		if field == null:
			field_info.text = "Engin tún gögn fundust"
			selected_field = null
			harvest_button.disabled = true
			fertilize_button.disabled = true
			return

		selected_field = field
		_update_panel()

func _on_harvest_pressed():
	if selected_field == null:
		return
	var hay = selected_field.harvest()
	match current_weather:
		Weather.SUNNY: hay = int(hay * 1.1)
		Weather.RAIN:  hay = int(hay * 0.7)
	barn_hay = min(barn_hay + hay, barn_capacity)
	_update_panel()

func _on_next_day_pressed():
	current_weather = randi() % 4 as Weather
	day_count += 1
	if day_count > 90:
		day_count = 1
		year += 1
		lambing_completed = false
		lambs_born_this_year = 0
		for child in get_children():
			if child.has_method("get_field_info"):
				child.fertilized_this_year = false
	season = _get_season()
	var lambing_message: String = ""
	if day_count == 1 and not lambing_completed:
		var lambs = _run_lambing()
		sheep_count += lambs
		lambs_born_this_year = lambs
		lambing_completed = true
		lambing_message = "Sauðburður: " + str(lambs) + " lömb fæddust."
	var growth = 5
	match current_weather:
		Weather.RAIN:  growth += 3
		Weather.STORM: growth -= 2
	if season == "Sumar":
		growth += 3
	elif season == "Vetur":
		growth = 0
	for child in get_children():
		if child.has_method("get_field_info"):
			child.grass_level = min(child.grass_level + growth, 100)
			if child.harvested and child.grass_level > 30:
				child.harvested = false
	var hay_warning = _process_hay_consumption()
	money -= daily_cost
	var daily_consumption = sheep_count * _get_effective_hay_rate()
	var forecast_days: int = int(floor(barn_hay / daily_consumption)) if daily_consumption > 0 else 9999
	var warnings: Array = []
	if lambing_message != "":
		warnings.append(lambing_message)
	if season == "Vetur":
		warnings.append("Ekki hægt að slá tún á veturna.")
	if hay_warning != "":
		warnings.append(hay_warning)
	if money < 0:
		warnings.append("Viðvörun: Búið er í skuld!")
	warning_label.text = "\n".join(warnings)
	day_label.text = "Dagur: " + str(day_count)
	weather_label.text = "Veður: " + _weather_name()
	hay_label.text = "Hey í hlöðu: " + str(barn_hay) + " / " + str(barn_capacity)
	hay_forecast_label.text = "Hey endast í " + str(forecast_days) + " daga."
	money_label.text = "Peningar: " + str(money) + " kr."
	sheep_label.text = "Kindur: " + str(sheep_count)
	year_label.text = "Ár: " + str(year)
	season_label.text = "Árstíð: " + season
	lambs_label.text = "Lömb fædd í ár: " + str(lambs_born_this_year)
	_update_sheep_buttons()
	if selected_field != null:
		_update_panel()

func _update_sheep_buttons() -> void:
	buy_sheep_button.disabled = money < 10 * SHEEP_BUY_PRICE
	sell_sheep_button.disabled = sheep_count < 10

func _on_buy_sheep_pressed() -> void:
	if money < 10 * SHEEP_BUY_PRICE:
		return
	money -= 10 * SHEEP_BUY_PRICE
	sheep_count += 10
	sheep_label.text = "Kindur: " + str(sheep_count)
	money_label.text = "Peningar: " + str(money) + " kr."
	_update_sheep_buttons()

func _on_sell_sheep_pressed() -> void:
	if sheep_count < 10:
		return
	sheep_count -= 10
	money += 10 * SHEEP_SELL_PRICE
	sheep_label.text = "Kindur: " + str(sheep_count)
	money_label.text = "Peningar: " + str(money) + " kr."
	_update_sheep_buttons()

func _on_fertilize_pressed() -> void:
	if selected_field == null:
		return
	if season == "Haust" or season == "Vetur":
		warning_label.text = "Ekki er hægt að bera á á þessum árstíma."
		return
	if not selected_field.fertilize():
		warning_label.text = "Þetta tún hefur þegar verið borið á í ár."
		return
	money -= 5000
	money_label.text = "Peningar: " + str(money) + " kr."
	_update_panel()

func _update_panel():
	field_info.text = selected_field.get_field_info()
	harvest_button.disabled = selected_field.harvested or current_weather == Weather.STORM or season == "Vetur"
	fertilize_button.disabled = selected_field.fertilized_this_year or season == "Haust" or season == "Vetur"
	hay_label.text = "Hey í hlöðu: " + str(barn_hay) + " / " + str(barn_capacity)
