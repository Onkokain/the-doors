extends Area3D
@onready var respawn: AudioStreamPlayer2D = $respawn

func _on_body_entered(_body: Node3D) -> void:
	print("You won!")
	respawn.play()
	await get_tree().create_timer(1).timeout
	get_tree().reload_current_scene()
