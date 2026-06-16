extends Node3D

enum Weather { SUNNY, RAIN, WIND, STORM }

var barn_hay: int = 0
var barn_capacity: int = 1000
var day_count: int = 1
var current_weather: Weather = Weather.SUNNY

var sheep_count: int = 50
var hay_per_sheep_per_day: float = 0.2

var selected_field = null

@onready var field_info: Label = $UI/FieldPanel/FieldInfo
@onready var harvest_button: Button = $UI/FieldPanel/HarvestButton
@onready var hay_label: Label = $UI/FieldPanel/HayLabel
@onready var day_label: Label = $UI/FieldPanel/DayLabel
@onready var weather_label: Label = $UI/FieldPanel/WeatherLabel
@onready var next_day_button: Button = $UI/FieldPanel/NextDayButton
@onready var sheep_label: Label = $UI/FieldPanel/SheepLabel
@onready var warning_label: Label = $UI/FieldPanel/WarningLabel
@onready var camera: Camera3D = $Camera3D

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
	warning_label.text = ""

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
			return

		var clicked = result.collider
		var field = clicked
		while field != null and not field.has_method("get_field_info"):
			field = field.get_parent()

		if field == null:
			field_info.text = "Engin tún gögn fundust"
			selected_field = null
			harvest_button.disabled = true
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
	var growth = 5
	match current_weather:
		Weather.RAIN:  growth += 3
		Weather.STORM: growth -= 2
	for child in get_children():
		if child.has_method("get_field_info"):
			child.grass_level = min(child.grass_level + growth, 100)
			if child.harvested and child.grass_level > 30:
				child.harvested = false
	var consumed: int = int(sheep_count * hay_per_sheep_per_day)
	if barn_hay < consumed:
		barn_hay = 0
		warning_label.text = "Viðvörun: Ekki nóg hey fyrir kindurnar!"
	else:
		barn_hay -= consumed
		warning_label.text = ""
	day_label.text = "Dagur: " + str(day_count)
	weather_label.text = "Veður: " + _weather_name()
	hay_label.text = "Hey í hlöðu: " + str(barn_hay) + " / " + str(barn_capacity)
	if selected_field != null:
		_update_panel()

func _update_panel():
	field_info.text = selected_field.get_field_info()
	harvest_button.disabled = selected_field.harvested or current_weather == Weather.STORM
	hay_label.text = "Hey í hlöðu: " + str(barn_hay) + " / " + str(barn_capacity)
