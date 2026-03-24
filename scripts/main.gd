extends Panel
var is_already_playing=false
var paused = false
@onready var panel: Panel = $"."


func _ready() -> void:
	
	panel.visible = false

func _input(event):
	if event.is_action_pressed("pause"):
		paused = !paused
		get_tree().paused = paused
		panel.visible = paused
		if !is_already_playing:
			Background.playing=true
			is_already_playing=true
		else:
			Background.playing=false
			is_already_playing=false
