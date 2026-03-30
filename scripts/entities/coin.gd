extends Node3D

@onready var coin_audio: AudioStreamPlayer3D = $AudioStreamPlayer3D

@onready var label: Label3D = $Area3D/Label3D
var is_player_inside: bool = false

func _ready() -> void:
	label.visible = false

func _process(_delta: float) -> void:
	
	# Check if the player is within the area AND presses the key
	if is_player_inside and Input.is_action_just_pressed("interact"):
		collect_coin()

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		is_player_inside = true
		label.visible = true

func _on_area_3d_body_exited(body: Node3D) -> void:
	if body is CharacterBody3D:
		is_player_inside = false
		label.visible = false

func collect_coin() -> void:
	coin_audio.play()
	Global.coins+=[1,2,3].pick_random()
	await get_tree().create_timer(0.5).timeout
	# Add any score-keeping logic here!
	queue_free()
