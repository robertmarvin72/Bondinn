extends MeshInstance3D

@export var field_name: String = "Nyrðra tún"
@export var grass_level: int = 100
@export var fertility: int = 64
@export var harvested: bool = false

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
