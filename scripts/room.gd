extends CSGCombiner3D

@onready var label: Label3D = $Label3D

# This will hold this specific room's permanent number
var my_room_number: int = 1 

func _ready() -> void:
	# Update the text on the wall once when the room loads
	label.text = str(my_room_number)

# The spawner will call this right after instantiating the room
func set_room_number(num: int) -> void:
	my_room_number = num
	if is_node_ready():
		label.text = str(my_room_number)

# Assuming 'updator' is an Area3D near the entrance/middle of the room
func _on_updator_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		# Instead of math, just directly tell the Global script exactly where the player is
		Global.player_room = my_room_number
