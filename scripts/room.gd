extends CSGCombiner3D

@onready var label: Label3D = $Label3D

# This will be filled automatically by the World Generator
var room_type_name: String = "unknown"
var my_room_number: int = 1
var has_been_registered: bool = false

func _ready() -> void:
	# Set the room number on the wall
	if label:
		label.text = str(my_room_number)
	
	# Automatically connect the area signal so you don't have to do it in the editor
	var area = get_node_or_null("updator")
	if area:
		area.body_entered.connect(_on_updator_body_entered)
	else:
		print("Error: No Area3D named 'updator' found in ", name)

# Called by the World Generator immediately after spawning
func set_room_info(num: int, type_name: String) -> void:
	my_room_number = num
	room_type_name = type_name
	if is_node_ready() and label:
		label.text = str(my_room_number)

func _on_updator_body_entered(body: Node3D) -> void:
	# Ensure the player has a CharacterBody3D node
	if body is CharacterBody3D:
		# Update the global player position
		Global.player_room = my_room_number
		
		# Register this room type if it's the first time seeing it
		if not has_been_registered:
			Global.register_discovery(room_type_name)
			has_been_registered = true


func _on_area_3d_body_entered(body: Node3D) -> void:
	pass # Replace with function body.
