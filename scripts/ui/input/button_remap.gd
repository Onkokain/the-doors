# Script for remapping keys 
extends Button

@export var action_name: String = ""

var is_remapping = false

func _ready():
	pressed.connect(_on_pressed)
	
	if action_name == "":
		action_name = name.to_lower()
	
	update_button_text()

func update_button_text():
	var events = InputMap.action_get_events(action_name)
	if events.size() > 0:
		text = events[0].as_text().trim_suffix(" - Physical")
	else:
		text = "Unbound"

func _on_pressed():
	is_remapping = true
	text = "..." 

func _input(event):
	if is_remapping:
		if event is InputEventKey or (event is InputEventMouseButton and event.pressed):
			get_viewport().set_input_as_handled()
			
			InputMap.action_erase_events(action_name)
			InputMap.action_add_event(action_name, event)
			
			is_remapping = false
			update_button_text()
