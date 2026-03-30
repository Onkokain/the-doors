extends HSlider
@onready var background: HSlider = $"."

var id

func _ready() -> void:
	id = AudioServer.get_bus_index('background')
	
	background.value = Global.background_music

func _on_value_changed(value: float) -> void:
	Global.background_music = value
	var db = linear_to_db(value)
	AudioServer.set_bus_volume_db(id, db)
