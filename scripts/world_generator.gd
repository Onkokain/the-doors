extends Node3D

@export var player: CharacterBody3D
@export var max_rooms_on_screen: int = 3

@export var lobby_scene: PackedScene = preload("res://scenes/lobby.tscn")
@export var end_room_scene: PackedScene = preload("res://scenes/endroom.tscn")

var generation_finished: bool = false
const END_ROOM_INDEX: int = 25

# --- THE CACHE (The Backstage) ---
var room_cache: Dictionary = {} 
var current_room_index: int = 0

# --- DISTANCE OPTIMIZATIONS ---
var check_timer: float = 0.0
const CHECK_INTERVAL: float = 0.2 # Runs distance logic 5 times a second instead of every frame

# --- GENERATION STATE ---
var prev_room_type: String = "straight"
var straight_buffer: int = 3
var net_rotation: int = 0

@export var room_data: Array[Dictionary] = [
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

func _ready():
	randomize()
	if player == null:
		player = get_parent().get_node_or_null("player") as CharacterBody3D
	
	# Jumpstart the window
	_refresh_window()

func _process(delta: float) -> void:
	if generation_finished or room_cache.is_empty(): 
		return
		
	# OPTIMIZATION: Only check distances periodically
	check_timer += delta
	if check_timer < CHECK_INTERVAL: 
		return
	check_timer = 0.0
	
	var closest_dist = INF
	var closest_idx = current_room_index
	
	# Auto-detect which room the player is currently standing inside
	for idx in room_cache.keys():
		var room = room_cache[idx]
		if is_instance_valid(room) and room.is_inside_tree():
			
			var target_pos = room.global_position
			var exit = room.get_node_or_null("ExitMarker")
			
			# If the room has an exit, calculate the exact center of the room
			if exit:
				target_pos = (room.global_position + exit.global_position) / 2.0
				
			var dist = player.global_position.distance_squared_to(target_pos)
			if dist < closest_dist:
				closest_dist = dist
				closest_idx = idx
				
	# If the player walked into a new room, shift the window
	if closest_idx != current_room_index:
		current_room_index = closest_idx
		_refresh_window()

# --- CORE WINDOW LOGIC ---

func _refresh_window():
	var target_indices = []
	
	# Keep 1 room behind you, the current room, and spawn up to max_rooms_on_screen ahead
	# Example: If current is 1, and max is 3, it targets [0, 1, 2, 3]
	for i in range(-1, max_rooms_on_screen + 1):
		target_indices.append(current_room_index + i)

	# 0. DEEP CLEAN: If a room is 8 doors behind you, queue_free it to prevent WebGL crash
	var keys_to_delete = []
	for idx in room_cache.keys():
		if idx < current_room_index - 8: 
			keys_to_delete.append(idx)
			
	for idx in keys_to_delete:
		var old_room = room_cache[idx]
		if is_instance_valid(old_room):
			old_room.queue_free()
		room_cache.erase(idx)

	# 1. DETACH (Backstage): Use remove_child on rooms that left our target window
	for idx in room_cache.keys():
		if idx not in target_indices:
			var room_node = room_cache[idx]
			if is_instance_valid(room_node) and room_node.get_parent() == self:
				remove_child(room_node) 

	# 2. ATTACH/GENERATE: Bring rooms back from cache or make new ones
	for idx in target_indices:
		if idx < 0: continue # No negative rooms
		
		if room_cache.has(idx):
			var room_node = room_cache[idx]
			if is_instance_valid(room_node) and room_node.get_parent() == null:
				add_child(room_node) 
		else:
			_generate_new_room(idx)

func _generate_new_room(index: int):
	var scene_to_use: PackedScene
	
	if index == 0:
		scene_to_use = lobby_scene
	elif index == END_ROOM_INDEX:
		scene_to_use = end_room_scene
		generation_finished = true
	else:
		scene_to_use = _pick_random_scene()

	var new_room = scene_to_use.instantiate()
	
	# Positioning Logic: Snap to previous room's ExitMarker
	if index == 0:
		new_room.global_transform = Transform3D.IDENTITY
	else:
		var prev_room = room_cache.get(index - 1)
		if prev_room and is_instance_valid(prev_room):
			var exit = prev_room.get_node_or_null("ExitMarker")
			if exit:
				new_room.global_transform = exit.global_transform
	
	if new_room.has_method("set_room_info"):
		var type_id = "lobby" if index == 0 else ("end_room" if index == END_ROOM_INDEX else "room")
		new_room.set_room_info(index, type_id)

	# Save to Cache and Add to Scene
	room_cache[index] = new_room
	add_child(new_room)

func _pick_random_scene() -> PackedScene:
	var valid_indices: Array[int] = []
	var total_weight: float = 0.0
	
	for i in range(room_data.size()):
		var data = room_data[i]
		if straight_buffer <= 0 and data["type"] == "straight": continue
		if prev_room_type == "right" and data["type"] == "left": continue
		if prev_room_type == "left" and data["type"] == "right": continue
		if net_rotation >= 1 and data["type"] == "right": continue
		if net_rotation <= -1 and data["type"] == "left": continue
		
		total_weight += data["weight"]
		valid_indices.append(i)
	
	if valid_indices.is_empty():
		for i in range(room_data.size()):
			if room_data[i]["type"] == "straight":
				valid_indices.append(i)
				total_weight += room_data[i]["weight"]
	
	var random_val = randf_range(0.0, total_weight)
	var cum_weight = 0.0
	for i in valid_indices:
		cum_weight += room_data[i]["weight"]
		if random_val <= cum_weight:
			var selected = room_data[i]
			if selected["type"] == "straight": straight_buffer -= 1
			else: 
				straight_buffer = 3
				net_rotation = clamp(net_rotation + (1 if selected["type"] == "right" else -1), -1, 1)
			prev_room_type = selected["type"]
			return selected["scene"]
	
	return room_data[0]["scene"]
