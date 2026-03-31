extends HSlider
@onready var effects: HSlider = $"."

@export var audio_bus_name: String
var id
func _ready() -> void:
	id=AudioServer.get_bus_index('effects')
	effects.value = Global.effects_music



func _on_value_changed(value: float) -> void:
	Global.effects_music = value
	var db = linear_to_db(value)
	AudioServer.set_bus_volume_db(id, db)
