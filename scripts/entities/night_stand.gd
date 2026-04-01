extends Area3D

@onready var label: Label3D = $Label3D
@onready var animation_player: AnimationPlayer = $"../AnimationPlayer"

var is_open = false
var is_interactable = true
var player_inside = false

func _ready() -> void:
	label.visible = false

func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		label.visible = true
		player_inside = true

func _on_body_exited(body: Node3D) -> void:
	if body is CharacterBody3D:
		label.visible = false
		player_inside = false

func _process(_delta: float) -> void:
	if player_inside and Input.is_action_just_pressed("interact") and is_interactable:
		
		is_interactable = false
		
		if !is_open:
			animation_player.play("open")
			await animation_player.animation_finished
			is_open = true
		else:
			animation_player.play("close")
			await animation_player.animation_finished
			is_open = false
		
		is_interactable = true
