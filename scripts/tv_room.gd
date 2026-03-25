extends Area3D

# Use AudioStreamPlayer3D for 3D spatial sound
@onready var tv: AudioStreamPlayer3D = $AudioStreamPlayer3D



func _ready() -> void:
	# Ensure the clocks aren't ticking until the player enters
	tv.stop()
	
	# Connect the signals via code to ensure they are linked
	# This avoids "not working" issues if you forgot to click them in the editor
	

func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		if not tv.playing:
			tv.play()

func _on_body_exited(body: Node3D) -> void:
	if  body is CharacterBody3D:
		tv.stop()
