extends StaticBody3D

var is_open := false

# Node references
@onready var animation_player: AnimationPlayer = $"../../AnimationPlayer"
@onready var door_audio: AudioStreamPlayer3D = $"../../door_audio"

func _ready() -> void:
	# Ensure the script keeps processing if the game is paused, 
	# matching your project's current setup.
	process_mode = Node.PROCESS_MODE_ALWAYS

func _on_interaction_area_body_entered(body: Node3D) -> void:
	# Check if the body is the player and the door isn't already open
	if body is CharacterBody3D and not is_open:
		open_door_permanently()

func open_door_permanently() -> void:
	is_open = true
	if door_audio != null:
		door_audio.play()
		await get_tree().create_timer(0.1).timeout
	# Play the opening animation
	if animation_player.has_animation("door_openz"):
		animation_player.play("door_openz")
	
	# Play sound if the node exists
	
	
	# Logic for 'open forever' is handled by simply never 
	# calling a close function or resetting 'is_open'
