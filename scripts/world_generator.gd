extends Node3D

@export var player: CharacterBody3D
@export var spawn_distance: float = 80.0
@export var max_rooms_on_screen: int = 15

# --- LOBBY SETUP ---
@export var lobby_scene: PackedScene = preload("res://scenes/lobby.tscn")

# --- FAILSAFE VARIABLES ---
var prev_room_type: String = "straight"
var straight_buffer: int = 0
var net_rotation: int = 0 

# --- ROOM DATA ---
var room_data: Array[Dictionary] = [
	{"scene": preload("res://scenes/newdesign_room.tscn"), "weight": 40.0, "type": "straight"},
	{"scene": preload("res://scenes/newdesign_hallway.tscn"), "weight": 5.0, "type": "straight"},
	{"scene": preload("res://scenes/rotate_left.tscn"), "weight": 15.0, "type": "left"},
	{"scene": preload("res://scenes/rotate_right.tscn"), "weight": 15.0, "type": "right"},
]

var active_rooms: Array = []
var offscreen_rooms: Array = [] # This keeps unloaded rooms in memory
var highest_room_spawned: int = 0

func _ready():
	randomize()
	if player == null:
		player = get_parent().get_node_or_null("player") as CharacterBody3D
	
	_spawn_next_room() 
	for i in range(max_rooms_on_screen - 1):
		_spawn_next_room()

func _process(_delta):
	if active_rooms.is_empty(): return
	
	var last_room = active_rooms.back()
	if not last_room.has_node("ExitMarker"): return
	
	var exit_marker = last_room.get_node("ExitMarker")
	if player.global_position.distance_to(exit_marker.global_position) < spawn_distance:
		_spawn_next_room()

# --- (Selection logic remains the same) ---
func _get_random_room() -> Node3D:
	var valid_indices: Array[int] = []
	var total_weight: float = 0.0

	for i in range(room_data.size()):
		var r_type = room_data[i]["type"]
		if straight_buffer > 0 and r_type != "straight": continue
		if prev_room_type == "right" and r_type == "left": continue
		if prev_room_type == "left" and r_type == "right": continue
		if net_rotation >= 1 and r_type == "right": continue
		if net_rotation <= -1 and r_type == "left": continue
		total_weight += room_data[i]["weight"]
		valid_indices.append(i)

	var random_val: float = randf_range(0.0, total_weight)
	var cumulative_weight: float = 0.0
	var selected_index: int = valid_indices[0]

	for i in valid_indices:
		cumulative_weight += room_data[i]["weight"]
		if random_val <= cumulative_weight:
			selected_index = i
			break

	var selected_type = room_data[selected_index]["type"]
	if selected_type == "straight":
		straight_buffer = max(0, straight_buffer - 1)
	else:
		straight_buffer = 3 
		net_rotation += (1 if selected_type == "right" else -1)
		net_rotation = clamp(net_rotation, -1, 1)

	prev_room_type = selected_type 
	return room_data[selected_index]["scene"].instantiate()

# -----------------------------
# SPAWNING & UNLOADING LOGIC
# -----------------------------
func _spawn_next_room():
	var new_room: Node3D
	
	if active_rooms.is_empty():
		new_room = lobby_scene.instantiate()
		prev_room_type = "straight"
	else:
		new_room = _get_random_room()
	
	add_child(new_room)
	
	highest_room_spawned += 1
	if new_room.has_method("set_room_number"):
		new_room.set_room_number(highest_room_spawned)

	if active_rooms.is_empty():
		new_room.global_transform = Transform3D.IDENTITY
	else:
		var last_room = active_rooms.back()
		if last_room.has_node("ExitMarker"):
			new_room.global_transform = last_room.get_node("ExitMarker").global_transform

	active_rooms.append(new_room)
	
	# --- UNLOAD LOGIC START ---
	if active_rooms.size() > max_rooms_on_screen:
		var room_to_unload = active_rooms.pop_front()
		
		# remove_child hides it and stops it from processing
		# but DOES NOT delete the data.
		remove_child(room_to_unload) 
		offscreen_rooms.append(room_to_unload)
	# --- UNLOAD LOGIC END ---
