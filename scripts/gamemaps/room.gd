extends CSGCombiner3D

@onready var label: Label3D = $Label3D

var room_type_name: String = "unknown"
var my_room_number: int = 1
var has_been_registered: bool = false

func _ready() -> void:
	if label:
		label.text = str(my_room_number)
	
	var area = get_node_or_null("updator")
	if area:
		if not area.body_entered.is_connected(_on_updator_body_entered):
			area.body_entered.connect(_on_updator_body_entered)

func set_room_info(num: int, type_name: String) -> void:
	my_room_number = num
	room_type_name = type_name
	if is_node_ready() and label:
		label.text = str(my_room_number)

func _on_updator_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		Global.player_room = my_room_number
		
		if not has_been_registered:
			Global.register_discovery(room_type_name)
			has_been_registered = true
