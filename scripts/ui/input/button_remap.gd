extends Button

# This matches the action name in your Project Settings -> Input Map
@export var action_name: String = ""

var is_remapping = false

func _ready():
	# 1. THE PRO SHORTCUT: This connects the button to its own function automatically
	pressed.connect(_on_pressed)
	
	# 2. Automatically sets the action name based on the Node name if left empty
	if action_name == "":
		action_name = name.to_lower()
	
	update_button_text()

func update_button_text():
	var events = InputMap.action_get_events(action_name)
	if events.size() > 0:
		# Cleaner way to remove " (Physical)" or " (Device 0)" suffixes
		text = events[0].as_text().trim_suffix(" - Physical")
	else:
		text = "Unbound"

func _on_pressed():
	is_remapping = true
	text = "..." # Visual feedback

func _input(event):
	if is_remapping:
		# Filter for keys or mouse clicks
		if event is InputEventKey or (event is InputEventMouseButton and event.pressed):
			# Stop the event from bubbling up (prevents clicking things behind the menu)
			get_viewport().set_input_as_handled()
			
			# Re-map the action
			InputMap.action_erase_events(action_name)
			InputMap.action_add_event(action_name, event)
			
			is_remapping = false
			update_button_text()
