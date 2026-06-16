extends MeshInstance3D

@export var field_name: String = "Mýrin"
@export var grass_level: int = 85
@export var fertility: int = 60
@export var harvested: bool = false
@export var fertilized_this_year: bool = false

func fertilize() -> bool:
	if fertilized_this_year:
		return false
	fertility = min(fertility + 10, 100)
	fertilized_this_year = true
	return true

func get_field_info() -> String:
	return field_name + "\nGras: " + str(grass_level) + "%\nFrjósemi: " + str(fertility) + "%"

func harvest():
	if harvested:
		return 0

	harvested = true
	var hay = int(grass_level * fertility / 100.0)
	grass_level = 0

	print(field_name + " gaf " + str(hay) + " heyeiningar")

	return hay
