extends CSGCombiner3D
@onready var doors_opened: Label3D = $"doors opened"
@onready var rooms_visited: Label3D = $"rooms visited"
@onready var coins_collected: Label3D = $"coins collected"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	doors_opened.text=str(Global.doors_opened)
	rooms_visited.text=str(Global.unique_room_visited)+"/10"
	coins_collected.text=str(Global.coins)
