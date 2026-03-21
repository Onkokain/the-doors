extends StaticBody3D

var interactable = true
var is_player_in_range = false


# Correcting paths based on your scene tree image
@onready var animation_player: AnimationPlayer = $"../../AnimationPlayer"
@onready var door_audio: AudioStreamPlayer3D = $"../../door_audio"
@onready var prompt: Label3D = $"../../InteractionArea/Prompt"
@onready var prompt_2: Label3D = $"../../InteractionArea/Prompt2"




func _ready():
	prompt.hide() 
	prompt_2.hide() # Start with the "E" hidden

func _unhandled_input(event: InputEvent):
	# Check if player presses 'E' while standing in the zone
	if event.is_action_pressed("interact") and is_player_in_range and interactable:
		interact()

func interact():
		if interactable:
			interactable = false
			prompt.hide()
			prompt_2.hide() # Hide prompt while the door is moving
			
			animation_player.play("door_openz")
			if door_audio != null:
				door_audio.play()
				
			await get_tree().create_timer(5.0, false).timeout
			
			animation_player.play("door_close")
			if door_audio != null:
				door_audio.play()
				
			await get_tree().create_timer(2.0, false).timeout
			
			interactable = true
			# Show prompt again if they are still standing there
			if is_player_in_range:
				prompt.show()
				prompt_2.show()

# --- Signal Connections ---

func _on_interaction_area_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D: # Assuming your player is a CharacterBody3D
		is_player_in_range = true
		if interactable:
			prompt.show()
			prompt_2.show()


func _on_interaction_area_body_exited(body: Node3D) -> void:
	if body is CharacterBody3D:
		is_player_in_range = false
		prompt.hide()
		prompt_2.hide()
