extends Node3D
@onready var label: Label3D = $coins/Label3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	label.visible=false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass



func _on_area_3d_body_entered(body: Node3D) -> void:
	label.visible=true
	trapchest()

func _on_area_3d_body_exited(body: Node3D) -> void:
	label.visible=false
	
	
func trapchest():
	print("You died to a trapped chest boo hoo")
