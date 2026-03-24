extends Node3D

@export var player: CharacterBody3D
@export var spawn_distance: float = 100.0
@export var max_rooms_on_screen: int = 20

var prev_room: int = -1

# 1. Update your room list to include weights. 
# Higher weight = more likely to spawn.
var room_data: Array[Dictionary] = [
	{"scene": preload("res://scenes/hallway.tscn"), "weight": 10.0},     # Very common
	{"scene": preload("res://scenes/hallway_long.tscn"), "weight": 1.0}, # Uncommon
	{"scene": preload("res://scenes/maze1.tscn"), "weight": 0.1},        # 
	{"scene": preload("res://scenes/newdesign_room.tscn"),"weight":20.0}
]

var active_rooms: Array = []

# Track room numbers
var highest_room_spawned: int = 1
var lowest_room_spawned: int = 1


func _ready():
	randomize()  # Ensure different rooms each run

	if player == null:
		player = get_parent().get_node_or_null("player") as CharacterBody3D
		if player == null:
			push_error("WorldGenerator could not find a player node.")
			return
	
	# Spawn first room
	var first_room = _get_random_room()
	add_child(first_room)
	first_room.global_transform = Transform3D.IDENTITY
	first_room.set_room_number(highest_room_spawned)
	active_rooms.append(first_room)
	
	# Spawn initial rooms to fill screen
	for i in range(max_rooms_on_screen - 1):
		_spawn_next_room(true)


func _process(_delta):
	if not player or active_rooms.is_empty(): 
		return

	var front_room = active_rooms.back()
	var back_room = active_rooms.front()
	
	var front_marker_pos = front_room.get_node("ExitMarker").global_position
	var back_pos = back_room.global_position

	if player.global_position.distance_to(front_marker_pos) < spawn_distance:
		_spawn_next_room(true)
	
	if player.global_position.distance_to(back_pos) < spawn_distance:
		_spawn_next_room(false)


# -----------------------------
# SPAWN RANDOM ROOM WITH WEIGHTS
# -----------------------------
func _get_random_room() -> Node3D:
	if room_data.is_empty():
		push_error("No room data assigned!")
		return Node3D.new()  # fallback

	var total_weight: float = 0.0
	var valid_indices: Array[int] = []

	# 1. Tally up the total weight of all VALID rooms (excluding prev_room)
	for i in range(room_data.size()):
		if i != prev_room or room_data.size() == 1:
			total_weight += room_data[i]["weight"]
			valid_indices.append(i)

	# 2. Pick a random number between 0 and our new total_weight
	var random_val: float = randf_range(0.0, total_weight)
	var cumulative_weight: float = 0.0
	var selected_index: int = 0

	# 3. Iterate through valid rooms to see where the random number landed
	for i in valid_indices:
		cumulative_weight += room_data[i]["weight"]
		if random_val <= cumulative_weight:
			selected_index = i
			break

	prev_room = selected_index  # update prev_room
	return room_data[selected_index]["scene"].instantiate()


func _spawn_next_room(is_front: bool):
	var new_room = _get_random_room()
	add_child(new_room)

	if is_front:
		highest_room_spawned += 1
		new_room.set_room_number(highest_room_spawned)
		
		var last_room = active_rooms.back()
		var exit_marker = last_room.get_node("ExitMarker")
		new_room.global_transform = exit_marker.global_transform
		active_rooms.append(new_room)
	else:
		lowest_room_spawned -= 1
		new_room.set_room_number(lowest_room_spawned)
		
		var first_room = active_rooms.front()
		var new_room_exit = new_room.get_node("ExitMarker")
		var offset = new_room_exit.transform.origin
		new_room.global_position = first_room.global_position - offset
		active_rooms.push_front(new_room)

	if active_rooms.size() > max_rooms_on_screen:
		var room_to_del = active_rooms.pop_front() if is_front else active_rooms.pop_back()
		room_to_del.queue_free()
