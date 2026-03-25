extends Area3D

# Use AudioStreamPlayer3D for 3D spatial sound
@onready var clocks: AudioStreamPlayer3D = $AudioStreamPlayer3D


func _ready() -> void:
	# Ensure the clocks aren't ticking until the player enters
	clocks.stop()
	
	# Connect the signals via code to ensure they are linked
	# This avoids "not working" issues if you forgot to click them in the editor
	

func _on_body_entered(body: Node3D) -> void:
	# Check if the body is the player (adjust "Player" to your character's name)
	if body.name == "Player" or body is CharacterBody3D:
		if not clocks.playing:
			clocks.play()

func _on_body_exited(body: Node3D) -> void:
	if body.name == "Player" or body is CharacterBody3D:
		clocks.stop()
