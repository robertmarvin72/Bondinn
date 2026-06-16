extends Node3D

enum Weather { SUNNY, RAIN, WIND, STORM }

const SHEEP_BUY_PRICE = 25000
const SHEEP_SELL_PRICE = 20000
const TRACTOR_PRICE = 2500000
const TRACTOR_DAILY_COST = 3000
const FERTILIZER_SPREADER_PRICE = 500000
const MOWER_PRICE = 750000
const TEDDER_PRICE = 600000
const TEDDER_HAY_BONUS = 0.25
const BALER_PRICE = 1200000
const FERTILIZER_COST_PER_FIELD = 5000
const FERTILITY_INCREASE = 10

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
var has_tractor: bool = false
var has_fertilizer_spreader: bool = false
var has_mower: bool = false
var has_tedder: bool = false
var has_baler: bool = false
var loose_hay: int = 0

var selected_field = null

@onready var field_info: Label = $UI/FieldPanel/ScrollContainer/VBoxContainer/FieldInfo
@onready var harvest_button: Button = $UI/FieldPanel/ScrollContainer/VBoxContainer/HarvestButton
@onready var hay_label: Label = $UI/FieldPanel/ScrollContainer/VBoxContainer/HayLabel
@onready var day_label: Label = $UI/FieldPanel/ScrollContainer/VBoxContainer/DayLabel
@onready var weather_label: Label = $UI/FieldPanel/ScrollContainer/VBoxContainer/WeatherLabel
@onready var next_day_button: Button = $UI/FieldPanel/ScrollContainer/VBoxContainer/NextDayButton
@onready var sheep_label: Label = $UI/FieldPanel/ScrollContainer/VBoxContainer/SheepLabel
@onready var money_label: Label = $UI/FieldPanel/ScrollContainer/VBoxContainer/MoneyLabel
@onready var warning_label: Label = $UI/FieldPanel/ScrollContainer/VBoxContainer/WarningLabel
@onready var buy_sheep_button: Button = $UI/FieldPanel/ScrollContainer/VBoxContainer/BuySheepButton
@onready var sell_sheep_button: Button = $UI/FieldPanel/ScrollContainer/VBoxContainer/SellSheepButton
@onready var year_label: Label = $UI/FieldPanel/ScrollContainer/VBoxContainer/YearLabel
@onready var season_label: Label = $UI/FieldPanel/ScrollContainer/VBoxContainer/SeasonLabel
@onready var lambs_label: Label = $UI/FieldPanel/ScrollContainer/VBoxContainer/LambsLabel
@onready var hay_forecast_label: Label = $UI/FieldPanel/ScrollContainer/VBoxContainer/HayForecastLabel
@onready var fertilize_button: Button = $UI/FieldPanel/ScrollContainer/VBoxContainer/FertilizeButton
@onready var tractor_label: Label = $UI/FieldPanel/ScrollContainer/VBoxContainer/TractorLabel
@onready var buy_tractor_button: Button = $UI/FieldPanel/ScrollContainer/VBoxContainer/BuyTractorButton
@onready var spreader_label: Label = $UI/FieldPanel/ScrollContainer/VBoxContainer/SpreaderLabel
@onready var buy_spreader_button: Button = $UI/FieldPanel/ScrollContainer/VBoxContainer/BuySpreaderButton
@onready var mower_label: Label = $UI/FieldPanel/ScrollContainer/VBoxContainer/MowerLabel
@onready var buy_mower_button: Button = $UI/FieldPanel/ScrollContainer/VBoxContainer/BuyMowerButton
@onready var tedder_label: Label = $UI/FieldPanel/ScrollContainer/VBoxContainer/TedderLabel
@onready var buy_tedder_button: Button = $UI/FieldPanel/ScrollContainer/VBoxContainer/BuyTedderButton
@onready var baler_label: Label = $UI/FieldPanel/ScrollContainer/VBoxContainer/BalerLabel
@onready var buy_baler_button: Button = $UI/FieldPanel/ScrollContainer/VBoxContainer/BuyBalerButton
@onready var loose_hay_label: Label = $UI/FieldPanel/ScrollContainer/VBoxContainer/LooseHayLabel
@onready var bale_button: Button = $UI/FieldPanel/ScrollContainer/VBoxContainer/BaleButton
@onready var camera: Camera3D = $Camera3D

func has_required_machinery(machine_name: String) -> bool:
	match machine_name:
		"spreader", "mower", "tedder":
			return has_tractor
		"baler":
			return has_tractor and has_tedder
		"harvest":
			return has_tractor and has_mower
	return true

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
	tractor_label.text = "Dráttarvél: Nei"
	buy_tractor_button.pressed.connect(_on_buy_tractor_pressed)
	spreader_label.text = "Áburðardreifari: Nei"
	buy_spreader_button.pressed.connect(_on_buy_spreader_pressed)
	mower_label.text = "Sláttuvél: Nei"
	buy_mower_button.pressed.connect(_on_buy_mower_pressed)
	tedder_label.text = "Snúningsvél: Nei"
	buy_tedder_button.pressed.connect(_on_buy_tedder_pressed)
	baler_label.text = "Rúlluvél: Nei"
	buy_baler_button.pressed.connect(_on_buy_baler_pressed)
	loose_hay_label.text = "Ópressað hey: 0"
	bale_button.disabled = true
	bale_button.pressed.connect(_on_bale_pressed)
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
	if not has_required_machinery("harvest"):
		warning_label.text = "Þú þarft sláttuvél til að slá tún."
		return
	var hay = selected_field.harvest()
	if has_tedder:
		hay = int(hay * (1.0 + TEDDER_HAY_BONUS))
	match current_weather:
		Weather.SUNNY: hay = int(hay * 1.1)
		Weather.RAIN:  hay = int(hay * 0.7)
	loose_hay += hay
	loose_hay_label.text = "Ópressað hey: " + str(loose_hay)
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
	if has_tractor:
		money -= TRACTOR_DAILY_COST
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

func _on_buy_tractor_pressed() -> void:
	if has_tractor:
		warning_label.text = "Þú átt nú þegar dráttarvél."
		return
	if money < TRACTOR_PRICE:
		warning_label.text = "Ekki nóg peningar til að kaupa dráttarvél."
		return
	money -= TRACTOR_PRICE
	has_tractor = true
	buy_tractor_button.visible = false
	tractor_label.text = "Dráttarvél: Já"
	money_label.text = "Peningar: " + str(money) + " kr."
	warning_label.text = "Dráttarvél keypt!"
	_update_sheep_buttons()

func _on_buy_spreader_pressed() -> void:
	if not has_tractor:
		warning_label.text = "Þú þarft dráttarvél áður en þú getur keypt áburðardreifara."
		return
	if has_fertilizer_spreader:
		warning_label.text = "Þú átt nú þegar áburðardreifara."
		return
	if money < FERTILIZER_SPREADER_PRICE:
		warning_label.text = "Ekki nóg peningar til að kaupa áburðardreifara."
		return
	money -= FERTILIZER_SPREADER_PRICE
	has_fertilizer_spreader = true
	buy_spreader_button.visible = false
	spreader_label.text = "Áburðardreifari: Já"
	money_label.text = "Peningar: " + str(money) + " kr."
	warning_label.text = "Áburðardreifari keyptur!"
	_update_sheep_buttons()
	if selected_field != null:
		_update_panel()

func _on_bale_pressed() -> void:
	if not has_baler:
		warning_label.text = "Þú þarft rúlluvél til að rúlla hey."
		return
	if loose_hay == 0:
		warning_label.text = "Ekkert laustt hey til að rúlla."
		return
	var amount = min(loose_hay, barn_capacity - barn_hay)
	barn_hay += amount
	loose_hay = 0
	hay_label.text = "Hey í hlöðu: " + str(barn_hay) + " / " + str(barn_capacity)
	loose_hay_label.text = "Ópressað hey: " + str(loose_hay)
	warning_label.text = ""

func _on_buy_baler_pressed() -> void:
	if not has_tractor:
		warning_label.text = "Þú þarft dráttarvél áður en þú getur keypt rúlluvél."
		return
	if not has_tedder:
		warning_label.text = "Þú þarft snúningsvél áður en þú getur keypt rúlluvél."
		return
	if has_baler:
		warning_label.text = "Þú átt nú þegar rúlluvél."
		return
	if money < BALER_PRICE:
		warning_label.text = "Ekki nóg peningar til að kaupa rúlluvél."
		return
	money -= BALER_PRICE
	has_baler = true
	buy_baler_button.visible = false
	baler_label.text = "Rúlluvél: Já"
	bale_button.disabled = false
	money_label.text = "Peningar: " + str(money) + " kr."
	warning_label.text = "Rúlluvél keypt!"

func _on_buy_tedder_pressed() -> void:
	if not has_tractor:
		warning_label.text = "Þú þarft dráttarvél áður en þú getur keypt snúningsvél."
		return
	if has_tedder:
		warning_label.text = "Þú átt nú þegar snúningsvél."
		return
	if money < TEDDER_PRICE:
		warning_label.text = "Ekki nóg peningar til að kaupa snúningsvél."
		return
	money -= TEDDER_PRICE
	has_tedder = true
	buy_tedder_button.visible = false
	tedder_label.text = "Snúningsvél: Já"
	money_label.text = "Peningar: " + str(money) + " kr."
	warning_label.text = "Snúningsvél keypt!"

func _on_buy_mower_pressed() -> void:
	if not has_tractor:
		warning_label.text = "Þú þarft dráttarvél áður en þú getur keypt sláttuvél."
		return
	if has_mower:
		warning_label.text = "Þú átt nú þegar sláttuvél."
		return
	if money < MOWER_PRICE:
		warning_label.text = "Ekki nóg peningar til að kaupa sláttuvél."
		return
	money -= MOWER_PRICE
	has_mower = true
	buy_mower_button.visible = false
	mower_label.text = "Sláttuvél: Já"
	money_label.text = "Peningar: " + str(money) + " kr."
	warning_label.text = "Sláttuvél keypt!"

func _on_fertilize_pressed() -> void:
	if selected_field == null:
		return
	if not has_fertilizer_spreader:
		warning_label.text = "Þú þarft áburðardreifara til að bera á tún."
		return
	if season == "Haust" or season == "Vetur":
		warning_label.text = "Ekki er hægt að bera á á þessum árstíma."
		return
	if not selected_field.fertilize():
		warning_label.text = "Þetta tún hefur þegar verið borið á í ár."
		return
	money -= FERTILIZER_COST_PER_FIELD
	money_label.text = "Peningar: " + str(money) + " kr."
	_update_panel()

func _update_panel():
	field_info.text = selected_field.get_field_info()
	harvest_button.disabled = selected_field.harvested or current_weather == Weather.STORM or season == "Vetur"
	fertilize_button.disabled = not has_fertilizer_spreader or selected_field.fertilized_this_year or season == "Haust" or season == "Vetur"
	hay_label.text = "Hey í hlöðu: " + str(barn_hay) + " / " + str(barn_capacity)
