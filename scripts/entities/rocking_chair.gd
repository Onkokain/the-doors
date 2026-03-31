extends StaticBody3D
@onready var rocking: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	rocking.play("rock")
