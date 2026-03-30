extends Node3D

@onready var label: Label3D = $Area3D/Label3D
@onready var music: AudioStreamPlayer3D = $AudioStreamPlayer3D

# This tracks if the player is currently standing in the zone
var is_player_inside: bool = false

func _ready() -> void:
	label.visible = false

func _process(_delta: float) -> void:
	# Check both: Are they here? AND Did they press the key?
	if is_player_inside and Input.is_action_just_pressed("interact"):
		play_interaction_music()

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		is_player_inside = true
		label.visible = true

func _on_area_3d_body_exited(body: Node3D) -> void:
	if body is CharacterBody3D:
		is_player_inside = false
		label.visible = false

func play_interaction_music() -> void:
	if not music.playing:
		music.play()
		# Optional: Hide the label once they start the music
		label.visible = false
