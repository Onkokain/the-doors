extends Node3D

@export var player: CharacterBody3D
@export var spawn_distance: float = 80.0
@export var max_rooms_on_screen: int = 15

@export var lobby_scene: PackedScene = preload("res://scenes/lobby.tscn")
# Added the end room scene
@export var end_room_scene: PackedScene = preload("res://scenes/endroom.tscn")

var prev_room_type: String = "straight"
var straight_buffer: int = 3 
var net_rotation: int = 0 

# Flag to stop generation after the end room spawns
var generation_finished: bool = false
const END_ROOM_INDEX: int = 25

# Room Data List
var room_data: Array[Dictionary] = [
	{"name": "hallway", "scene": preload("res://scenes/hallway.tscn"), "weight": 30.0, "type": "straight"},
	{"name": "library_broken", "scene": preload("res://scenes/library_broken.tscn"), "weight": 20.0, "type": "straight"},
	{"name": "library", "scene": preload("res://scenes/library.tscn"), "weight": 35.0, "type": "straight"},
	{"name": "piano_room", "scene": preload("res://scenes/piano_room.tscn"), "weight": 35.0, "type": "straight"},
	{"name": "clock_room", "scene": preload("res://scenes/clock_room.tscn"), "weight": 20.0, "type": "straight"},
	{"name": "rotate_left", "scene": preload("res://scenes/rotate_left.tscn"), "weight": 20.0, "type": "left"},
	{"name": "rotate_right", "scene": preload("res://scenes/rotate_right.tscn"), "weight": 20.0, "type": "right"},
	{"name": "closet_room", "scene": preload("res://scenes/closet_room.tscn"), "weight": 20.0, "type": "straight"},
	{"name": "tv_room", "scene": preload("res://scenes/tv_room.tscn"), "weight": 20.0, "type": "straight"},
]

var active_rooms: Array = []
var highest_room_spawned: int = 0

func _ready():
	randomize()
	if player == null:
		player = get_parent().get_node_or_null("player") as CharacterBody3D
	
	_spawn_next_room() 
	for i in range(max_rooms_on_screen - 1):
		_spawn_next_room()

func _process(_delta):
	# Stop checking if we have already spawned the end room
	if generation_finished or active_rooms.is_empty(): 
		return
		
	var last_room = active_rooms.back()
	if not last_room.has_node("ExitMarker"): 
		return
	
	var exit_marker = last_room.get_node("ExitMarker")
	if player.global_position.distance_to(exit_marker.global_position) < spawn_distance:
		_spawn_next_room()

func _spawn_next_room():
	# Safety check
	if generation_finished:
		return

	var new_room: Node3D
	var type_id: String = "room"
	
	# Increment count early to track room number
	highest_room_spawned += 1

	# 1. LOBBY LOGIC (First Room)
	if active_rooms.is_empty():
		new_room = lobby_scene.instantiate()
		type_id = "lobby"
		prev_room_type = "straight"
		straight_buffer = 3
		
	# 2. END ROOM LOGIC (25th Room)
	elif highest_room_spawned == END_ROOM_INDEX:
		new_room = end_room_scene.instantiate()
		type_id = "end_room"
		generation_finished = true # This prevents further calls to _spawn_next_room
		
	# 3. RANDOM GENERATION LOGIC
	else:
		var valid_indices: Array[int] = []
		var total_weight: float = 0.0
		var force_turn: bool = (straight_buffer <= 0)
		var chance_to_turn: bool = (straight_buffer == 1 and randf() < 0.5)

		for i in range(room_data.size()):
			var r_type = room_data[i]["type"]
			if (force_turn or chance_to_turn) and r_type == "straight": continue
			if (!force_turn and !chance_to_turn) and r_type != "straight": continue
			if prev_room_type == "right" and r_type == "left": continue
			if prev_room_type == "left" and r_type == "right": continue
			if net_rotation >= 1 and r_type == "right": continue
			if net_rotation <= -1 and r_type == "left": continue
			total_weight += room_data[i]["weight"]
			valid_indices.append(i)

		if valid_indices.is_empty():
			for i in range(room_data.size()):
				if room_data[i]["type"] == "straight":
					valid_indices.append(i)
					total_weight += room_data[i]["weight"]

		var random_val: float = randf_range(0.0, total_weight)
		var cumulative_weight: float = 0.0
		var selected_index: int = valid_indices[0]

		for i in valid_indices:
			cumulative_weight += room_data[i]["weight"]
			if random_val <= cumulative_weight:
				selected_index = i
				break

		var data = room_data[selected_index]
		new_room = data["scene"].instantiate()
		type_id = data["name"]
		
		# Update Buffer/Rotation
		var s_type = data["type"]
		if s_type == "straight":
			straight_buffer -= 1
		else:
			straight_buffer = 3
			net_rotation += (1 if s_type == "right" else -1)
			net_rotation = clamp(net_rotation, -1, 1)
		prev_room_type = s_type

	add_child(new_room)
	
	# Pass data to the room script
	if new_room.has_method("set_room_info"):
		new_room.set_room_info(highest_room_spawned, type_id)

	# Positioning
	if active_rooms.is_empty():
		new_room.global_transform = Transform3D.IDENTITY
	else:
		var last_room = active_rooms.back()
		if last_room.has_node("ExitMarker"):
			new_room.global_transform = last_room.get_node("ExitMarker").global_transform

	active_rooms.append(new_room)
	
	# Unload old rooms, but DON'T unload if there aren't many left 
	# (usually keep max_rooms_on_screen logic as is)
	if active_rooms.size() > max_rooms_on_screen:
		var room_to_unload = active_rooms.pop_front()
		room_to_unload.queue_free()
