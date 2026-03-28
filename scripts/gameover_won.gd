extends Area3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass



func _on_body_entered(_body: Node3D) -> void:
	print("You won!")
	get_tree().reload_current_scene()
