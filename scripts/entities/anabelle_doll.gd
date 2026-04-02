extends Area3D
@onready var audio_stream_player_3d: AudioStreamPlayer3D = $AudioStreamPlayer3D
@onready var door_wall_cutout_2: CSGBox3D = $"../walls/door wall cutout2"
@onready var door_wall_cutout: CSGBox3D = $"../walls/door wall cutout"
@onready var door: Node3D = $"../door"

var has_entered=false

func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D and !has_entered:
		door_wall_cutout_2.visible=false
		door_wall_cutout.visible=false
		door.visible=false
		audio_stream_player_3d.play()
		has_entered=true
		Global.door_locked=true
		await audio_stream_player_3d.finished
		door_wall_cutout_2.visible=true
		door_wall_cutout.visible=true
		door.visible=true
		has_entered=false
		Global.door_locked=false
