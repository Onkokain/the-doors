extends Panel

var paused = false
@onready var panel: Panel = $"."


func _ready() -> void:
	
	panel.visible = false

func _input(event):
	if event.is_action_pressed("pause"):
		paused = !paused
		get_tree().paused = paused
		panel.visible = paused
		Background.playing=true
