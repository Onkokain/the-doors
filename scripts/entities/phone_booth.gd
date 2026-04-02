extends Area3D

@onready var label_3d: Label3D = $"../Label3D"
@onready var call_ring: AudioStreamPlayer2D = $"../../AudioStreamPlayer3D"
@onready var call_audio: AudioStreamPlayer2D = $"../../AudioStreamPlayer3D2"

var main_scene: PackedScene
var is_loaded := false

var is_interacting := false
var player_inside := false
var call_ring_played := false

func _ready() -> void:
	label_3d.visible = false
	set_process(true)

	ResourceLoader.load_threaded_request("res://scenes/core/main.tscn")

func _process(_delta: float) -> void:
	if not is_loaded:
		var status = ResourceLoader.load_threaded_get_status("res://scenes/core/main.tscn")
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			main_scene = ResourceLoader.load_threaded_get("res://scenes/core/main.tscn")
			is_loaded = true
			print("Scene loaded in background")

	# your original logic
	if player_inside and not is_interacting:
		label_3d.visible = true
		if Input.is_action_just_pressed("interact"):
			call_ring.stop()
			call_ring_played = true
			start_interaction()
	else:
		label_3d.visible = false

func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		player_inside = true
		if !call_ring_played:
			call_ring.play()

func _on_body_exited(body: Node3D) -> void:
	if body is CharacterBody3D:
		call_ring.stop()
		player_inside = false
		label_3d.visible = false

func start_interaction() -> void:
	if is_interacting:
		return

	is_interacting = true
	label_3d.visible = false

	await get_tree().create_timer(1.0).timeout

	call_audio.play()
	await call_audio.finished

	
	get_tree().change_scene_to_packed(main_scene)
