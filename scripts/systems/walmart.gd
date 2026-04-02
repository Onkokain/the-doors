extends Node3D
@onready var narrator_1: AudioStreamPlayer2D = $Node2D/narrator_1
@onready var narrator_2: AudioStreamPlayer2D = $Node2D/narrator_2
@onready var narrator_3: AudioStreamPlayer2D = $Node2D/narrator_3
@onready var narrator_4: AudioStreamPlayer2D = $Node2D/narrator_4
@onready var narrator_5: AudioStreamPlayer2D = $Node2D/narrator_5
@onready var narrator_6: AudioStreamPlayer2D = $Node2D/narrator_6
@onready var wall_blocker: StaticBody3D = $"wall blocker"

@onready var player: CharacterBody3D = $player
@onready var teleport_location: CollisionShape3D = $teleport/CollisionShape3D

var audios=[]
var blocked=false

func _on_static_body_3d_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		Global.play_threats=false
	for x in audios:
		x.volume_db=0

func _ready() -> void:
	audios=[narrator_1,narrator_2,narrator_3,narrator_4,narrator_5,narrator_6]
	if Global.play_threats:
		await get_tree().create_timer(10).timeout
	if Global.play_threats:
		narrator_1.play()
		await get_tree().create_timer(10).timeout
	if Global.play_threats:
		narrator_2.play()
		await get_tree().create_timer(10).timeout
	if Global.play_threats:
		narrator_3.play()
		await get_tree().create_timer(10).timeout
	if Global.play_threats:
		narrator_4.play()
		await get_tree().create_timer(10).timeout
	if Global.play_threats:
		narrator_5.play()
		await get_tree().create_timer(10).timeout
	if Global.play_threats:
		narrator_6.play()
		await narrator_6.finished
		player.global_transform.origin=teleport_location.global_transform.origin
		wall_blocker.collision_layer=1
		wall_blocker.collision_mask=1


func _on_static_body_3d_body_exited(body: Node3D) -> void:
	if body is CharacterBody3D and !blocked:
		wall_blocker.collision_layer=1
		wall_blocker.collision_mask=1
		blocked=true
