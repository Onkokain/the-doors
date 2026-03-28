extends Node

var player_room = 0 # players current room-1
var doors_opened=0 # number of doors player has opened 
var coins=0
var unique_room_visited: int = 0
var discovered_rooms: Array[String] = [] 

func register_discovery(room_type: String):
	if not discovered_rooms.has(room_type):
		discovered_rooms.append(room_type)
		unique_room_visited = discovered_rooms.size()
		print("New room discovered: ", room_type)
		print("Total unique rooms: ", unique_room_visited)
var is_conversio=false
var is_flickering=true

var player_reset_button = false
