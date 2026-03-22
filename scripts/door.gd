extends StaticBody3D

var interactable := true
var is_player_in_range := false
var is_open := false

# Correcting paths based on your scene tree image
@onready var animation_player: AnimationPlayer = $"../../AnimationPlayer"
@onready var door_audio: AudioStreamPlayer3D = $"../../door_audio"
@onready var prompt: Label3D = $"../../InteractionArea/Prompt"
@onready var prompt_2: Label3D = $"../../InteractionArea/Prompt2"
@onready var prompt_3: Label3D = $"../../InteractionArea/Prompt3"


func _ready() -> void:
	_update_prompts()


func _unhandled_input(event: InputEvent) -> void:
	# Check if player presses 'E' while standing in the zone
	if event.is_action_pressed("interact") and is_player_in_range and interactable:
		interact()


func interact() -> void:
	if not interactable:
		return

	interactable = false
	_update_prompts()

	if is_open:
		animation_player.play("door_close")
	else:
		animation_player.play("door_openz")

	if door_audio != null:
		door_audio.play()

	await animation_player.animation_finished

	is_open = not is_open
	interactable = true
	_update_prompts()


func _update_prompts() -> void:
	var can_show_prompt := is_player_in_range and interactable
	prompt.visible = can_show_prompt and not is_open
	prompt_2.visible = can_show_prompt and not is_open
	prompt_3.visible = can_show_prompt and is_open


# --- Signal Connections ---

func _on_interaction_area_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		is_player_in_range = true
		_update_prompts()


func _on_interaction_area_body_exited(body: Node3D) -> void:
	if body is CharacterBody3D:
		is_player_in_range = false
		_update_prompts()
