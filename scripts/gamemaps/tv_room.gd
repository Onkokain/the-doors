extends Area3D

@onready var tv: AudioStreamPlayer3D = $AudioStreamPlayer3D



func _ready() -> void:
	tv.stop()
func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		if not tv.playing:
			tv.play()

func _on_body_exited(body: Node3D) -> void:
	if  body is CharacterBody3D:
		tv.stop()
