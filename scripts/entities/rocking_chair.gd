extends StaticBody3D
@onready var rocking: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	rocking.play("rock")


func _on_area_3d_body_entered(body: Node3D) -> void:
	pass # Replace with function body.
