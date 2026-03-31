extends Node3D
@onready var coins: Node3D = $coins

@onready var label: Label3D = $coins/Label3D
var is_player_inside: bool = false

func _ready() -> void:
	label.visible = false

func _process(_delta: float) -> void:
	if is_player_inside:
		if Input.is_action_just_pressed("interact"):
			trapchest()

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		is_player_inside = true
		label.visible = true

func _on_area_3d_body_exited(body: Node3D) -> void:
	if body is CharacterBody3D:
		is_player_inside = false
		label.visible = false

func trapchest():
	print("You died to a trapped chest boo hoo")
	coins.free()
	
