extends Node3D

@export var player: CharacterBody3D
@export var max_rooms_on_screen: int = 3

@export var lobby_scene: PackedScene = preload("res://scenes/gamemaps/lobby.tscn")
@export var end_room_scene: PackedScene = preload("res://scenes/gamemaps/endroom.tscn")

var generation_finished: bool = false
const END_ROOM_INDEX: int = 25

# --- THE CACHE ---
var room_cache: Dictionary = {} 
var current_room_index: int = 0

# --- DISTANCE OPTIMIZATIONS ---
var check_timer: float = 0.0
const CHECK_INTERVAL: float = 0.2 

# --- GENERATION STATE ---
var prev_room_type: String = "straight"
var straight_buffer: int = 3
var net_rotation: int = 0

@export var room_data: Array[Dictionary] = [
	{"name": "hallway", "scene": preload("res://scenes/gamemaps/hallway.tscn"), "weight": 30.0, "type": "straight"},
	{"name": "library_broken", "scene": preload("res://scenes/gamemaps/library_broken.tscn"), "weight": 20.0, "type": "straight"},
	{"name": "library", "scene": preload("res://scenes/gamemaps/library.tscn"), "weight": 35.0, "type": "straight"},
	{"name": "piano_room", "scene": preload("res://scenes/gamemaps/piano_room.tscn"), "weight": 35.0, "type": "straight"},
	{"name": "clock_room", "scene": preload("res://scenes/gamemaps/clock_room.tscn"), "weight": 20.0, "type": "straight"},
	{"name": "rotate_left", "scene": preload("res://scenes/gamemaps/rotate_left.tscn"), "weight": 20.0, "type": "left"},
	{"name": "rotate_right", "scene": preload("res://scenes/gamemaps/rotate_right.tscn"), "weight": 20.0, "type": "right"},
	{"name": "closet_room", "scene": preload("res://scenes/gamemaps/closet_room.tscn"), "weight": 20.0, "type": "straight"},
	{"name": "tv_room", "scene": preload("res://scenes/gamemaps/tv_room.tscn"), "weight": 20.0, "type": "straight"},
	{"name": "tv_room", "scene": preload("res://scenes/gamemaps/rocking_chair_room.tscn"), "weight": 20.0, "type": "straight"},
	{"name": "tv_room", "scene": preload("res://scenes/gamemaps/bar.tscn"), "weight": 20.0, "type": "straight"},


]

func _ready():
	randomize()
	if player == null:
		player = get_parent().get_node_or_null("player") as CharacterBody3D
	_refresh_window()

func _process(delta: float) -> void:
	if generation_finished or room_cache.is_empty(): 
		return
		
	check_timer += delta
	if check_timer < CHECK_INTERVAL: 
		return
	check_timer = 0.0
	
	var closest_dist = INF
	var closest_idx = current_room_index
	
	for idx in room_cache.keys():
		var room = room_cache[idx]
		if is_instance_valid(room) and room.is_inside_tree():
			var target_pos = room.global_position
			var exit = room.get_node_or_null("ExitMarker")
			if exit:
				target_pos = (room.global_position + exit.global_position) / 2.0
				
			var dist = player.global_position.distance_squared_to(target_pos)
			if dist < closest_dist:
				closest_dist = dist
				closest_idx = idx
				
	if closest_idx != current_room_index:
		current_room_index = closest_idx
		_refresh_window()

func _refresh_window():
	var target_indices = []
	for i in range(-1, max_rooms_on_screen + 1):
		target_indices.append(current_room_index + i)

	var keys_to_delete = []
	for idx in room_cache.keys():
		if idx < current_room_index - 8: 
			keys_to_delete.append(idx)
			
	for idx in keys_to_delete:
		var old_room = room_cache[idx]
		if is_instance_valid(old_room):
			old_room.queue_free()
		room_cache.erase(idx)

	for idx in room_cache.keys():
		if idx not in target_indices:
			var room_node = room_cache[idx]
			if is_instance_valid(room_node) and room_node.get_parent() == self:
				remove_child(room_node) 

	for idx in target_indices:
		if idx < 0: continue
		if room_cache.has(idx):
			var room_node = room_cache[idx]
			if is_instance_valid(room_node) and room_node.get_parent() == null:
				add_child(room_node) 
		else:
			_generate_new_room(idx)

func _generate_new_room(index: int):
	var selected_data: Dictionary # Now storing the whole dictionary
	
	if index == 0:
		selected_data = {"name": "lobby", "scene": lobby_scene}
	elif index == END_ROOM_INDEX:
		selected_data = {"name": "end_room", "scene": end_room_scene}
		generation_finished = true
	else:
		selected_data = _pick_random_room_data()

	var new_room = selected_data["scene"].instantiate()
	
	if index == 0:
		new_room.global_transform = Transform3D.IDENTITY
	else:
		var prev_room = room_cache.get(index - 1)
		if prev_room and is_instance_valid(prev_room):
			var exit = prev_room.get_node_or_null("ExitMarker")
			if exit:
				new_room.global_transform = exit.global_transform
	
	if new_room.has_method("set_room_info"):
		# FIX: Pass the real name (e.g., "piano_room") instead of the hardcoded "room"
		new_room.set_room_info(index, selected_data["name"])

	room_cache[index] = new_room
	add_child(new_room)

# UPDATED: This now returns the whole Dictionary, not just the Scene
func _pick_random_room_data() -> Dictionary:
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
			return selected
	
	return room_data[0]
