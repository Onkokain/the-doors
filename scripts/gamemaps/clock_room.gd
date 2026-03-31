extends Area3D

@onready var clocks: AudioStreamPlayer3D = $AudioStreamPlayer3D


func _ready() -> void:
	clocks.stop()
	
	

func _on_body_entered(body: Node3D) -> void:
	if body.name == "Player" or body is CharacterBody3D:
		if not clocks.playing:
			clocks.play()

func _on_body_exited(body: Node3D) -> void:
	if body.name == "Player" or body is CharacterBody3D:
		clocks.stop()
