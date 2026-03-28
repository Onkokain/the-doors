extends HSlider
@export var audio_bus_name: String
var id
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	id=AudioServer.get_bus_index('effects')



func _on_value_changed(value: float) -> void:
	var db=linear_to_db(value)
	AudioServer.set_bus_volume_db(id,db)
