extends Node3D

@export var player: CharacterBody3D
@export var spawn_distance: float = 80.0
@export var max_rooms_on_screen: int = 15

# --- FAILSAFE VARIABLES ---
var prev_room_index: int = -1
var straight_buffer: int = 0  # How many straight rooms we MUST spawn
var net_rotation: int = 0    # Tracks overall direction (0=straight, 1=right, -1=left)

# Indices: 0 = Straight, 1 = Left, 2 = Right
var room_data: Array[Dictionary] = [
	{"scene": preload("res://scenes/newdesign_room.tscn"), "weight": 10.0}, # Index 0
	{"scene": preload("res://scenes/rotate_left.tscn"), "weight": 30.0},   # Index 1
	{"scene": preload("res://scenes/rotate_right.tscn"), "weight": 30.0},  # Index 2
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
	if active_rooms.is_empty(): return
	var last_room = active_rooms.back()
	var exit_marker = last_room.get_node("ExitMarker")
	
	if player.global_position.distance_to(exit_marker.global_position) < spawn_distance:
		_spawn_next_room()

func _get_random_room() -> Node3D:
	var valid_indices: Array[int] = []
	var total_weight: float = 0.0

	# --- FAILSAFE LOGIC ---
	for i in range(room_data.size()):
		# 1. If buffer > 0, ONLY allow the straight room (Index 0)
		if straight_buffer > 0 and i != 0:
			continue
		
		# 2. Prevent U-Turns: Don't turn Left if we just turned Right (and vice versa)
		if prev_room_index == 1 and i == 2: continue
		if prev_room_index == 2 and i == 1: continue

		# 3. Prevent Circles: If we've turned 90 deg right, don't allow another right yet
		if net_rotation >= 1 and i == 2: continue
		if net_rotation <= -1 and i == 1: continue

		total_weight += room_data[i]["weight"]
		valid_indices.append(i)

	# Pick a room based on the filtered list
	var random_val: float = randf_range(0.0, total_weight)
	var cumulative_weight: float = 0.0
	var selected_index: int = 0

	for i in valid_indices:
		cumulative_weight += room_data[i]["weight"]
		if random_val <= cumulative_weight:
			selected_index = i
			break

	# --- UPDATE FAILSAFE STATE ---
	if selected_index == 0:
		straight_buffer = max(0, straight_buffer - 1)
	else:
		# If it's a turn (1 or 2), set a buffer of 3 straight rooms
		straight_buffer = 3 
		# Update net rotation: Left is -1, Right is +1
		net_rotation += (1 if selected_index == 2 else -1)
		
		# Allow net_rotation to "reset" towards zero as we explore
		# This keeps the maze from being too straight but prevents loops
		if net_rotation > 1: net_rotation = 1
		if net_rotation < -1: net_rotation = -1

	prev_room_index = selected_index 
	return room_data[selected_index]["scene"].instantiate()

func _spawn_next_room():
	var new_room = _get_random_room()
	add_child(new_room)
	highest_room_spawned += 1
	new_room.set_room_number(highest_room_spawned)

	if active_rooms.is_empty():
		new_room.global_transform = Transform3D.IDENTITY
	else:
		var last_room = active_rooms.back()
		new_room.global_transform = last_room.get_node("ExitMarker").global_transform

	active_rooms.append(new_room)
	if active_rooms.size() > max_rooms_on_screen:
		var room_to_del = active_rooms.pop_front()
		room_to_del.queue_free()
