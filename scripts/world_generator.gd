extends Node3D

@export var room_scene: PackedScene = preload("res://scenes/room.tscn")
@export var player: CharacterBody3D

@export var spawn_distance: float = 100.0  
@export var max_rooms_on_screen: int = 20 

var active_rooms: Array = []

# --- NEW: Track the room numbers ---
var highest_room_spawned: int = 1
var lowest_room_spawned: int = 1

func _ready():
	var first_room = room_scene.instantiate()
	add_child(first_room)
	first_room.global_transform = Transform3D.IDENTITY
	
	# Assign the first room its number
	first_room.set_room_number(highest_room_spawned) 
	active_rooms.append(first_room)
	
	for i in range(max_rooms_on_screen - 1):
		_spawn_next_room(true)

func _process(_delta):
	if not player or active_rooms.is_empty(): return

	var front_room = active_rooms.back()
	var back_room = active_rooms.front()
	
	var front_marker_pos = front_room.get_node("ExitMarker").global_position
	var back_pos = back_room.global_position

	if player.global_position.distance_to(front_marker_pos) < spawn_distance:
		_spawn_next_room(true)
	
	if player.global_position.distance_to(back_pos) < spawn_distance:
		_spawn_next_room(false)

func _spawn_next_room(is_front: bool):
	var new_room = room_scene.instantiate()
	add_child(new_room)
	
	if is_front:
		# Increase the tracking number and assign it
		highest_room_spawned += 1
		new_room.set_room_number(highest_room_spawned)
		
		var last_room = active_rooms.back()
		var exit_marker = last_room.get_node("ExitMarker")
		new_room.global_transform = exit_marker.global_transform
		active_rooms.append(new_room)
	else:
		# Decrease the tracking number and assign it
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
