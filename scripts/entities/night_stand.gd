extends Area3D
@onready var coin: Node3D = $"../coin"
@onready var coin_2: Node3D = $"../coin2"

@onready var animation_player: AnimationPlayer = $"../AnimationPlayer"
@onready var label: Label3D = $"../Nightstand/Nightstand drawer/Label3D"

var is_open = false
var is_interactable = true
var player_inside = false

func _ready() -> void:
	label.visible = false

func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D and is_interactable:
		label.visible = true
		player_inside = true

func _on_body_exited(body: Node3D) -> void:
	if body is CharacterBody3D:
		label.visible = false
		player_inside = false

func _process(_delta: float) -> void:
	if player_inside and Input.is_action_just_pressed("interact") and is_interactable:
		if !is_open:
			label.visible=false
			animation_player.play("open")
			await animation_player.animation_finished
			is_open = true
			is_interactable=false
		
