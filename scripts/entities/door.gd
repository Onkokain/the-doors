extends StaticBody3D

var is_open := false

@onready var animation_player: AnimationPlayer = $"../../AnimationPlayer"
@onready var door_audio: AudioStreamPlayer3D = $"../../door_audio"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _on_interaction_area_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D and not is_open and !Global.door_locked:
		open_door_permanently()

func open_door_permanently() -> void:
	is_open = true
	
	Global.doors_opened += 1
	print("Doors opened total: ", Global.doors_opened)
	
	if door_audio != null:
		door_audio.play()
		await get_tree().create_timer(0.1).timeout
	
	if animation_player != null and animation_player.has_animation("door_openz"):
		animation_player.play("door_openz")
